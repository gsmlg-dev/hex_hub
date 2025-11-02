defmodule HexHubWeb.API.PackageController do
  use HexHubWeb, :controller

  alias HexHubWeb.Plugs.HexFormat

  plug HexFormat

  def list(conn, params) do
    start_time = System.monotonic_time()
    search = params["search"]
    page = String.to_integer(params["page"] || "1")
    per_page = String.to_integer(params["per_page"] || "50")

    case HexHub.Packages.list_packages(
           search: search,
           page: page,
           per_page: per_page
         ) do
      {:ok, packages, total} ->
        response = %{
          packages: Enum.map(packages, &format_package_for_list/1),
          total: total,
          page: page,
          per_page: per_page,
          pages: ceil(total / per_page)
        }

        duration_ms =
          (System.monotonic_time() - start_time)
          |> System.convert_time_unit(:native, :millisecond)

        HexHub.Telemetry.track_api_request("packages.list", duration_ms, 200)

        json(conn, response)

      {:error, reason} ->
        duration_ms =
          (System.monotonic_time() - start_time)
          |> System.convert_time_unit(:native, :millisecond)

        HexHub.Telemetry.track_api_request("packages.list", duration_ms, 500, "error")

        conn
        |> put_status(:internal_server_error)
        |> json(%{message: reason})
    end
  end

  @doc """
  Handle dependency resolution requests for Mix (HEX_MIRROR support).
  This endpoint returns package installation information based on requirements.
  """
  def installs(conn, %{"elixir_version" => elixir_version, "requirements" => requirements_encoded}) do
    start_time = System.monotonic_time()

    # Decode requirements (base64 encoded JSON)
    case decode_requirements(requirements_encoded) do
      {:ok, requirements} ->
        # Process each requirement and find matching packages
        case resolve_dependencies(requirements, elixir_version) do
          {:ok, result} ->
            duration_ms =
              (System.monotonic_time() - start_time)
              |> System.convert_time_unit(:native, :millisecond)

            HexHub.Telemetry.track_api_request("packages.installs", duration_ms, 200)

            conn
            |> put_resp_content_type("application/vnd.hex+erlang")
            |> text(format_installs_result(result))
        end

      {:error, reason} ->
        duration_ms =
          (System.monotonic_time() - start_time)
          |> System.convert_time_unit(:native, :millisecond)

        HexHub.Telemetry.track_api_request("packages.installs", duration_ms, 400, "decode_error")

        conn
        |> put_status(:bad_request)
        |> json(%{message: "Invalid requirements format: #{reason}"})
    end
  end

  def show(conn, %{"name" => name}) do
    start_time = System.monotonic_time()

    # For Hex clients (ETF format), always proxy to upstream to get proper protobuf format
    # This is a temporary solution until we implement protobuf encoding locally
    if conn.assigns[:hex_format] == :etf and HexHub.Upstream.enabled?() do
      proxy_upstream_package(conn, name, start_time)
    else
      # For non-Hex clients (JSON), serve from local database
      case HexHub.Packages.get_package(name) do
        {:ok, package} ->
          duration_ms =
            (System.monotonic_time() - start_time)
            |> System.convert_time_unit(:native, :millisecond)

          HexHub.Telemetry.track_api_request("packages.show", duration_ms, 200)

          data = format_package_for_show(package)
          json(conn, data)

        {:error, :not_found} ->
          duration_ms =
            (System.monotonic_time() - start_time)
            |> System.convert_time_unit(:native, :millisecond)

          HexHub.Telemetry.track_api_request("packages.show", duration_ms, 404, "not_found")

          conn
          |> put_status(:not_found)
          |> json(%{message: "Package not found"})
      end
    end
  end

  defp proxy_upstream_package(conn, name, start_time) do
    upstream_config = HexHub.Upstream.config()
    url = "#{upstream_config.api_url}/api/packages/#{name}"

    # Forward the request to upstream and return raw response
    headers = build_upstream_headers(conn, upstream_config)

    req_opts = [
      receive_timeout: upstream_config.timeout,
      headers: headers,
      # Disable automatic decompression to get raw gzipped response
      compressed: false,
      # Disable automatic decoding of response body
      decode_body: false
    ]

    case Req.get(url, req_opts) do
      {:ok, %{status: 200, body: body, headers: resp_headers}} when is_binary(body) ->
        duration_ms =
          (System.monotonic_time() - start_time)
          |> System.convert_time_unit(:native, :millisecond)

        HexHub.Telemetry.track_api_request("packages.show", duration_ms, 200, "upstream_proxy")

        # Forward the upstream response as-is
        conn = put_resp_content_type(conn, "application/vnd.hex+erlang")

        # Copy relevant headers from upstream
        conn =
          Enum.reduce(resp_headers, conn, fn {key, value}, acc ->
            # Normalize value to string (Req can return lists)
            header_value = normalize_header_value(value)

            case String.downcase(key) do
              "cache-control" -> put_resp_header(acc, "cache-control", header_value)
              "etag" -> put_resp_header(acc, "etag", header_value)
              _ -> acc
            end
          end)

        send_resp(conn, 200, body)

      {:ok, %{status: status}} ->
        duration_ms =
          (System.monotonic_time() - start_time)
          |> System.convert_time_unit(:native, :millisecond)

        HexHub.Telemetry.track_api_request(
          "packages.show",
          duration_ms,
          status,
          "upstream_error"
        )

        conn
        |> put_status(status)
        |> json(%{message: "Upstream error: #{status}"})

      {:error, reason} ->
        duration_ms =
          (System.monotonic_time() - start_time)
          |> System.convert_time_unit(:native, :millisecond)

        HexHub.Telemetry.track_api_request(
          "packages.show",
          duration_ms,
          502,
          "upstream_connection_error"
        )

        conn
        |> put_status(:bad_gateway)
        |> json(%{message: "Failed to connect to upstream: #{inspect(reason)}"})
    end
  end

  defp build_upstream_headers(conn, upstream_config) do
    base_headers = [
      {"user-agent", "HexHub/0.1.0 (Proxy-Mode)"},
      {"accept", "application/vnd.hex+erlang"}
    ]

    # Forward accept-encoding if present
    headers =
      case get_req_header(conn, "accept-encoding") do
        [] -> base_headers
        [encoding | _] -> [{"accept-encoding", encoding} | base_headers]
      end

    # Add API key if configured
    case upstream_config.api_key do
      nil -> headers
      api_key -> [{"authorization", "Bearer #{api_key}"} | headers]
    end
  end

  defp normalize_header_value(value) when is_binary(value), do: value
  defp normalize_header_value([value | _]) when is_binary(value), do: value
  defp normalize_header_value(value), do: to_string(value)

  defp format_package_for_list(package) do
    %{
      name: package.name,
      repository: package.repository_name,
      private: package.private,
      meta: package.meta,
      downloads: %{all: package.downloads, week: 0, day: 0},
      inserted_at: package.inserted_at,
      updated_at: package.updated_at,
      url: package.html_url,
      html_url: package.html_url,
      docs_html_url: package.docs_html_url
    }
  end

  defp format_package_for_show(package) do
    # Get releases for this package
    {:ok, releases} = HexHub.Packages.list_releases(package.name)

    releases =
      Enum.map(releases, fn release ->
        %{
          version: release.version,
          url: release.url,
          has_docs: release.has_docs,
          inserted_at: release.inserted_at,
          updated_at: release.updated_at,
          # Add fields that Mix expects for HEX_MIRROR compatibility
          requirements: Map.get(release, :requirements, %{}),
          checksum: Map.get(release, :checksum, ""),
          build_tools: Map.get(release.meta, "build_tools", ["mix"])
        }
      end)

    %{
      name: package.name,
      repository: package.repository_name,
      private: package.private,
      meta: package.meta,
      downloads: %{all: package.downloads, week: 0, day: 0},
      releases: releases,
      inserted_at: package.inserted_at,
      updated_at: package.updated_at,
      url: package.html_url,
      html_url: package.html_url,
      docs_html_url: package.docs_html_url
    }
  end

  # Private helper functions for installs endpoint

  defp decode_requirements(requirements_encoded) do
    try do
      # Try to decode base64
      case Base.decode64(requirements_encoded) do
        {:ok, json_string} ->
          # Parse JSON
          case Jason.decode(json_string) do
            {:ok, requirements} when is_map(requirements) ->
              {:ok, requirements}

            {:ok, _} ->
              {:error, "Requirements must be a map"}

            {:error, reason} ->
              {:error, "Invalid JSON: #{reason}"}
          end

        :error ->
          {:error, "Invalid base64 encoding"}
      end
    rescue
      _ ->
        {:error, "Failed to decode requirements"}
    end
  end

  defp resolve_dependencies(requirements, _elixir_version) do
    # For now, return a simple result that indicates the packages should be fetched from upstream
    # This is a simplified implementation - in a full hex server, this would do actual
    # dependency resolution and return package information

    packages =
      Enum.map(requirements, fn {name, requirement} ->
        %{
          name: name,
          requirement: requirement,
          repository: "hexpm",
          optional: false,
          app: String.to_atom(String.replace(name, "-", "_"))
        }
      end)

    {:ok, %{packages: packages}}
  end

  defp format_installs_result(_result) do
    # Format the result as Erlang terms that Mix can understand
    # Return a simple success tuple that indicates packages can be fetched from upstream
    "{:ok, %{packages: [], checksums: %{}}}"
  end
end

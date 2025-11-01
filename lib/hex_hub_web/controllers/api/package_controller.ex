defmodule HexHubWeb.API.PackageController do
  use HexHubWeb, :controller

  alias HexHub.RegistryFormat
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

    case HexHub.Packages.get_package(name) do
      {:ok, package} ->
        duration_ms =
          (System.monotonic_time() - start_time)
          |> System.convert_time_unit(:native, :millisecond)

        HexHub.Telemetry.track_api_request("packages.show", duration_ms, 200)

        # Format response based on client type (Hex client vs browser/API)
        data =
          case conn.assigns[:hex_format] do
            :etf ->
              RegistryFormat.format_package_for_registry(package)

            _ ->
              format_package_for_show(package)
          end

        HexFormat.send_hex_response(conn, data)

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

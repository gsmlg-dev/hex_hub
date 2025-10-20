defmodule HexHubWeb.API.ReleaseController do
  use HexHubWeb, :controller
  alias HexHub.Packages

  action_fallback HexHubWeb.FallbackController

  def show(conn, %{"name" => name, "version" => version}) do
    start_time = System.monotonic_time()

    case Packages.get_release(name, version) do
      {:ok, release} ->
        response = %{
          name: release.package_name,
          version: release.version,
          checksum: generate_checksum(release),
          inner_checksum: generate_inner_checksum(release),
          has_docs: release.has_docs,
          meta: release.meta,
          requirements: release.requirements,
          retired: if(release.retired, do: %{}, else: nil),
          downloads: release.downloads,
          inserted_at: release.inserted_at,
          updated_at: release.updated_at,
          url: release.url,
          package_url: "/api/packages/#{name}/releases/#{version}/download",
          html_url: release.html_url,
          docs_html_url: release.docs_html_url,
          docs_url: "/api/packages/#{name}/releases/#{version}/docs/download"
        }

        duration_ms =
          (System.monotonic_time() - start_time)
          |> System.convert_time_unit(:native, :millisecond)

        HexHub.Telemetry.track_api_request("releases.show", duration_ms, 200)

        json(conn, response)

      {:error, :not_found} ->
        duration_ms =
          (System.monotonic_time() - start_time)
          |> System.convert_time_unit(:native, :millisecond)

        HexHub.Telemetry.track_api_request("releases.show", duration_ms, 404, "not_found")

        conn
        |> put_status(:not_found)
        |> json(%{message: "Package not found"})
    end
  end

  def publish(conn, %{"name" => package_name, "version" => version}) do
    start_time = System.monotonic_time()

    with {:ok, body, conn} <- Plug.Conn.read_body(conn),
         {:ok, meta} <- parse_meta_from_tarball(body),
         {:ok, requirements} <- parse_requirements_from_tarball(body),
         {:ok, release} <-
           Packages.create_release(package_name, version, meta, requirements, body) do
      response = %{
        version: release.version,
        has_docs: release.has_docs,
        meta: release.meta,
        requirements: release.requirements,
        retired: if(release.retired, do: %{}, else: nil),
        downloads: release.downloads,
        inserted_at: release.inserted_at,
        updated_at: release.updated_at,
        url: release.url,
        package_url: release.package_url,
        html_url: release.html_url,
        docs_html_url: release.docs_html_url
      }

      duration_ms =
        (System.monotonic_time() - start_time) |> System.convert_time_unit(:native, :millisecond)

      HexHub.Telemetry.track_api_request("releases.publish", duration_ms, 201)
      HexHub.Telemetry.track_package_published("hexpm")

      conn
      |> put_status(:created)
      |> json(response)
    else
      {:error, "Package not found"} ->
        duration_ms =
          (System.monotonic_time() - start_time)
          |> System.convert_time_unit(:native, :millisecond)

        HexHub.Telemetry.track_api_request("releases.publish", duration_ms, 404, "not_found")

        conn
        |> put_status(:not_found)
        |> json(%{message: "Package not found"})

      {:error, reason} ->
        duration_ms =
          (System.monotonic_time() - start_time)
          |> System.convert_time_unit(:native, :millisecond)

        HexHub.Telemetry.track_api_request("releases.publish", duration_ms, 422, "error")

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{message: reason})
    end
  end

  def retire(conn, %{"name" => name, "version" => version}) do
    start_time = System.monotonic_time()

    with {:ok, _release} <- Packages.get_release(name, version),
         {:ok, _} <- Packages.retire_release(name, version) do
      duration_ms =
        (System.monotonic_time() - start_time) |> System.convert_time_unit(:native, :millisecond)

      HexHub.Telemetry.track_api_request("releases.retire", duration_ms, 204)

      send_resp(conn, 204, "")
    else
      {:error, :not_found} ->
        duration_ms =
          (System.monotonic_time() - start_time)
          |> System.convert_time_unit(:native, :millisecond)

        HexHub.Telemetry.track_api_request("releases.retire", duration_ms, 404, "not_found")

        conn
        |> put_status(:not_found)
        |> json(%{message: "Package not found"})

      {:error, reason} ->
        duration_ms =
          (System.monotonic_time() - start_time)
          |> System.convert_time_unit(:native, :millisecond)

        HexHub.Telemetry.track_api_request("releases.retire", duration_ms, 422, "error")

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{message: reason})
    end
  end

  def unretire(conn, %{"name" => name, "version" => version}) do
    start_time = System.monotonic_time()

    with {:ok, _release} <- Packages.get_release(name, version),
         {:ok, _} <- Packages.unretire_release(name, version) do
      duration_ms =
        (System.monotonic_time() - start_time) |> System.convert_time_unit(:native, :millisecond)

      HexHub.Telemetry.track_api_request("releases.unretire", duration_ms, 204)

      send_resp(conn, 204, "")
    else
      {:error, :not_found} ->
        duration_ms =
          (System.monotonic_time() - start_time)
          |> System.convert_time_unit(:native, :millisecond)

        HexHub.Telemetry.track_api_request("releases.unretire", duration_ms, 404, "not_found")

        conn
        |> put_status(:not_found)
        |> json(%{message: "Package not found"})

      {:error, reason} ->
        duration_ms =
          (System.monotonic_time() - start_time)
          |> System.convert_time_unit(:native, :millisecond)

        HexHub.Telemetry.track_api_request("releases.unretire", duration_ms, 422, "error")

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{message: reason})
    end
  end

  defp generate_checksum(release) do
    # Generate a mock checksum for now
    # In real implementation, this would be the SHA256 of the package contents
    :crypto.hash(:sha256, "#{release.package_name}-#{release.version}")
    |> Base.encode16()
    |> String.downcase()
  end

  defp generate_inner_checksum(release) do
    # Generate a mock inner checksum for now
    # In real implementation, this would be the SHA256 of the inner package contents
    :crypto.hash(:sha256, "inner-#{release.package_name}-#{release.version}")
    |> Base.encode16()
    |> String.downcase()
  end

  defp parse_meta_from_tarball(_tarball) do
    # For now, extract basic metadata
    # In real implementation, this would parse metadata from the tarball
    {:ok, %{build_tools: ["mix"]}}
  end

  defp parse_requirements_from_tarball(_tarball) do
    # For now, return empty requirements
    # In real implementation, this would parse dependencies from mix.exs
    {:ok, %{}}
  end
end

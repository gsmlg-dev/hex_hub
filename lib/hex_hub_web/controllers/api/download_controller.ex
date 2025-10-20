defmodule HexHubWeb.API.DownloadController do
  use HexHubWeb, :controller

  alias HexHub.Packages

  action_fallback HexHubWeb.FallbackController

  @doc """
  Download package tarball with upstream fallback.
  """
  def package(conn, %{"name" => name, "version" => version}) do
    start_time = System.monotonic_time()

    case Packages.download_package_with_upstream(name, version) do
      {:ok, tarball} ->
        duration_ms =
          (System.monotonic_time() - start_time)
          |> System.convert_time_unit(:native, :millisecond)

        HexHub.Telemetry.track_api_request("downloads.package", duration_ms, 200)

        conn
        |> put_resp_content_type("application/octet-stream")
        |> put_resp_header(
          "content-disposition",
          "attachment; filename=\"#{name}-#{version}.tar\""
        )
        # 1 year cache
        |> put_resp_header("cache-control", "public, max-age=31536000")
        |> send_resp(200, tarball)

      {:error, _reason} ->
        duration_ms =
          (System.monotonic_time() - start_time)
          |> System.convert_time_unit(:native, :millisecond)

        HexHub.Telemetry.track_api_request("downloads.package", duration_ms, 404, "not_found")

        conn
        |> put_status(:not_found)
        |> json(%{message: "Package not found"})
    end
  end

  @doc """
  Download documentation tarball with upstream fallback.
  """
  def docs(conn, %{"name" => name, "version" => version}) do
    start_time = System.monotonic_time()

    case Packages.download_docs_with_upstream(name, version) do
      {:ok, docs_tarball} ->
        duration_ms =
          (System.monotonic_time() - start_time)
          |> System.convert_time_unit(:native, :millisecond)

        HexHub.Telemetry.track_api_request("downloads.docs", duration_ms, 200)

        conn
        |> put_resp_content_type("application/octet-stream")
        |> put_resp_header(
          "content-disposition",
          "attachment; filename=\"#{name}-#{version}-docs.tar\""
        )
        # 1 year cache
        |> put_resp_header("cache-control", "public, max-age=31536000")
        |> send_resp(200, docs_tarball)

      {:error, _reason} ->
        duration_ms =
          (System.monotonic_time() - start_time)
          |> System.convert_time_unit(:native, :millisecond)

        HexHub.Telemetry.track_api_request("downloads.docs", duration_ms, 404, "not_found")

        conn
        |> put_status(:not_found)
        |> json(%{message: "Documentation not found"})
    end
  end
end

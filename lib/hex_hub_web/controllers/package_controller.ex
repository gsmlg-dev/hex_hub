defmodule HexHubWeb.PackageController do
  use HexHubWeb, :controller
  alias HexHub.Packages

  def index(conn, params) do
    page = String.to_integer(params["page"] || "1")
    per_page = String.to_integer(params["per_page"] || "20")
    search = params["search"]

    {packages, total_count} =
      case search do
        nil ->
          case Packages.list_packages(page: page, per_page: per_page) do
            {:ok, pkgs, total} -> {pkgs, total}
            _ -> {[], 0}
          end

        search_term ->
          case Packages.search_packages(search_term, page: page, per_page: per_page) do
            {:ok, pkgs, total} -> {pkgs, total}
            _ -> {[], 0}
          end
      end

    render(conn, :index,
      packages: packages,
      page: page,
      per_page: per_page,
      total_count: total_count,
      search: search
    )
  end

  def show(conn, %{"name" => name}) do
    case Packages.get_package(name) do
      {:ok, package} ->
        releases = Packages.list_releases(name)
        render(conn, :show, package: package, releases: releases)

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> put_view(HexHubWeb.ErrorHTML)
        |> render(404)
    end
  end

  def docs(conn, %{"name" => name, "version" => version}) do
    case Packages.get_release(name, version) do
      {:ok, release} when release.has_docs ->
        render(conn, :docs, package: release.package_name, version: release.version)

      {:ok, _release} ->
        conn
        |> put_status(:not_found)
        |> put_view(HexHubWeb.ErrorHTML)
        |> render(404, message: "Documentation not found")

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> put_view(HexHubWeb.ErrorHTML)
        |> render(404)
    end
  end
end

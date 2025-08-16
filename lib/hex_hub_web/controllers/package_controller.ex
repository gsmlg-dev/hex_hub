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
            {:ok, pkgs, total} ->
              enriched_packages = Enum.map(pkgs, &enrich_package_with_latest_version/1)
              {enriched_packages, total}

            _ ->
              {[], 0}
          end

        search_term ->
          case Packages.search_packages(search_term, page: page, per_page: per_page) do
            {:ok, pkgs, total} ->
              enriched_packages = Enum.map(pkgs, &enrich_package_with_latest_version/1)
              {enriched_packages, total}

            _ ->
              {[], 0}
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
        case Packages.list_releases(name) do
          {:ok, releases} ->
            enriched_package = enrich_package_with_latest_version(package)
            render(conn, :show, package: enriched_package, releases: releases)

          {:error, _reason} ->
            enriched_package = enrich_package_with_latest_version(package)
            render(conn, :show, package: enriched_package, releases: [])
        end

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

  defp enrich_package_with_latest_version(package) do
    case Packages.list_releases(package.name) do
      {:ok, releases} ->
        latest_version =
          case releases do
            [] ->
              "0.0.0"

            releases ->
              releases
              |> Enum.map(& &1.version)
              |> Enum.sort_by(& &1, &>=/2)
              |> List.first()
          end

        Map.put(package, :latest_version, latest_version)

      {:error, _reason} ->
        Map.put(package, :latest_version, "0.0.0")
    end
  end
end

defmodule HexHubWeb.API.PackageController do
  use HexHubWeb, :controller

  def list(conn, params) do
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

        json(conn, response)

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{message: reason})
    end
  end

  def show(conn, %{"name" => name}) do
    case HexHub.Packages.get_package(name) do
      {:ok, package} ->
        json(conn, format_package_for_show(package))

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{message: "Package not found"})

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{message: reason})
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
    releases =
      case HexHub.Packages.list_releases(package.name) do
        {:ok, releases} ->
          Enum.map(releases, fn release ->
            %{
              version: release.version,
              url: release.url,
              has_docs: release.has_docs,
              inserted_at: release.inserted_at,
              updated_at: release.updated_at
            }
          end)

        _ ->
          []
      end

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
end

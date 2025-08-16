defmodule HexHubAdminWeb.PackageController do
  use HexHubAdminWeb, :controller

  alias HexHub.Packages

  def index(conn, params) do
    page = String.to_integer(params["page"] || "1")
    per_page = 20
    
    {:ok, packages, total} = Packages.list_packages(page: page, per_page: per_page)
    total_pages = max(ceil(total / per_page), 1)
    
    render(conn, :index,
      packages: packages,
      page: page,
      total_pages: total_pages,
      total_count: total
    )
  end

  def show(conn, %{"name" => name}) do
    case Packages.get_package(name) do
      {:ok, package} ->
        {:ok, releases} = Packages.list_releases(name)
        render(conn, :show, 
          package: package, 
          releases: releases
        )
    
      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Package not found")
        |> redirect(to: ~p"/packages")
    end
  end

  def delete(conn, %{"name" => name}) do
    # Check if package exists
    case Packages.get_package(name) do
      {:ok, _package} ->
        # For now, show not implemented message since package deletion
        # might require additional considerations like dependency checks
        conn
        |> put_flash(:error, "Package deletion is not implemented yet")
        |> redirect(to: ~p"/packages")

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Package not found")
        |> redirect(to: ~p"/packages")
    end
  end
end
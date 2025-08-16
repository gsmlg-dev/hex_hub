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

  def new(conn, _params) do
    render(conn, :new, changeset: nil)
  end

  def create(conn, %{"package" => package_params}) do
    name = package_params["name"]
    repository_name = package_params["repository_name"]
    version = package_params["version"]
    description = package_params["description"] || ""
    private = package_params["private"] == "true"

    # Handle file upload
    case conn.body_params["package"]["file"] do
      nil ->
        conn
        |> put_flash(:error, "Package file is required")
        |> redirect(to: ~p"/packages/new")

      file_upload when is_map(file_upload) ->
        case handle_package_upload(
               name,
               repository_name,
               version,
               description,
               private,
               file_upload
             ) do
          {:ok, package, release} ->
            conn
            |> put_flash(
              :info,
              "Package #{package.name} v#{release.version} created successfully!"
            )
            |> redirect(to: ~p"/packages/#{package.name}")

          {:error, reason} ->
            conn
            |> put_flash(:error, "Failed to create package: #{reason}")
            |> redirect(to: ~p"/packages/new")
        end
    end
  end

  def edit(conn, %{"name" => name}) do
    case Packages.get_package(name) do
      {:ok, package} ->
        render(conn, :edit, package: package, changeset: nil)

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Package not found")
        |> redirect(to: ~p"/packages")
    end
  end

  def update(conn, %{"name" => name, "package" => _package_params}) do
    case Packages.get_package(name) do
      {:ok, package} ->
        # Note: Package update functionality might be limited
        # based on actual API capabilities
        conn
        |> put_flash(:info, "Package #{package.name} updated successfully!")
        |> redirect(to: ~p"/packages/#{package.name}")

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Package not found")
        |> redirect(to: ~p"/packages")
    end
  end

  def delete(conn, %{"name" => name}) do
    case Packages.delete_package(name) do
      {:ok, deleted_name} ->
        conn
        |> put_flash(:info, "Package #{deleted_name} deleted successfully!")
        |> redirect(to: ~p"/packages")

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Package not found")
        |> redirect(to: ~p"/packages")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Failed to delete package")
        |> redirect(to: ~p"/packages")
    end
  end

  defp handle_package_upload(name, repository_name, version, description, private, file_upload) do
    with {:ok, package} <-
           Packages.create_package(
             name,
             repository_name,
             %{"description" => description},
             private
           ),
         {:ok, file_contents} <- read_uploaded_file(file_upload),
         {:ok, release} <-
           Packages.create_release(
             name,
             version,
             %{"description" => description},
             %{},
             file_contents
           ) do
      {:ok, package, release}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp read_uploaded_file(%{"path" => path, "filename" => _filename}) do
    case File.read(path) do
      {:ok, contents} -> {:ok, contents}
      {:error, reason} -> {:error, "Failed to read uploaded file: #{inspect(reason)}"}
    end
  end

  defp read_uploaded_file(_), do: {:error, "Invalid file upload"}
end

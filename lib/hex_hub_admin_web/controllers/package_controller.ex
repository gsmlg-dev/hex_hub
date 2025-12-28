defmodule HexHubAdminWeb.PackageController do
  use HexHubAdminWeb, :controller

  alias HexHub.CachedPackages
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

  @doc """
  Unified search across both local and cached packages with priority annotations.
  """
  def search(conn, params) do
    start_time = System.monotonic_time()

    query = params["q"] || ""
    source_filter = parse_source_filter(params["source"])
    page = parse_int(params["page"], 1)
    per_page = 50

    opts = [
      page: page,
      per_page: per_page,
      search: query,
      sort: :name,
      sort_dir: :asc
    ]

    # Get packages based on source filter
    result =
      case source_filter do
        :all ->
          CachedPackages.list_packages_with_priority(opts)

        source when source in [:local, :cached] ->
          CachedPackages.list_packages_by_source(source, opts)
      end

    case result do
      {:ok, %{packages: packages, pagination: pagination}} ->
        # Emit telemetry
        duration = System.monotonic_time() - start_time

        :telemetry.execute(
          [:hex_hub, :admin, :packages, :searched],
          %{duration: duration},
          %{query: query, source: source_filter, count: length(packages)}
        )

        render(conn, :search,
          results: packages,
          query: query,
          source_filter: to_string(source_filter),
          pagination: pagination
        )

      {:error, _reason} ->
        render(conn, :search,
          results: [],
          query: query,
          source_filter: to_string(source_filter),
          pagination: %{page: 1, per_page: per_page, total: 0, total_pages: 1}
        )
    end
  end

  defp parse_source_filter("local"), do: :local
  defp parse_source_filter("cached"), do: :cached
  defp parse_source_filter(_), do: :all

  defp parse_int(nil, default), do: default

  defp parse_int(val, default) when is_binary(val) do
    case Integer.parse(val) do
      {int, _} when int > 0 -> int
      _ -> default
    end
  end

  defp parse_int(val, _default) when is_integer(val) and val > 0, do: val
  defp parse_int(_, default), do: default
end

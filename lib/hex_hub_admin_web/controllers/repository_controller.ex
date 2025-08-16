defmodule HexHubAdminWeb.RepositoryController do
  use HexHubAdminWeb, :controller

  alias HexHub.Packages

  def index(conn, params) do
    page = String.to_integer(params["page"] || "1")
    per_page = 20

    repositories = Packages.list_repositories()
    total_count = length(repositories)

    # Simple pagination
    offset = (page - 1) * per_page
    paginated_repos = Enum.slice(repositories, offset, per_page)

    total_pages = ceil(total_count / per_page)

    render(conn, :index,
      repositories: paginated_repos,
      page: page,
      total_pages: total_pages,
      total_count: total_count
    )
  end

  def new(conn, _params) do
    render(conn, :new, changeset: nil)
  end

  def create(conn, %{"repository" => repository_params}) do
    case Packages.create_repository(repository_params) do
      {:ok, repository} ->
        conn
        |> put_flash(:info, "Repository #{repository.name} created successfully!")
        |> redirect(to: ~p"/repositories")

      {:error, changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def edit(conn, %{"name" => name}) do
    case Packages.get_repository(name) do
      {:ok, repository} ->
        render(conn, :edit, repository: repository, changeset: nil)

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Repository not found")
        |> redirect(to: ~p"/repositories")
    end
  end

  def update(conn, %{"name" => name, "repository" => repository_params}) do
    case Packages.get_repository(name) do
      {:ok, repository} ->
        case Packages.update_repository(name, repository_params) do
          {:ok, updated_repository} ->
            conn
            |> put_flash(:info, "Repository #{updated_repository.name} updated successfully!")
            |> redirect(to: ~p"/repositories")

          {:error, changeset} ->
            render(conn, :edit, repository: repository, changeset: changeset)
        end

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Repository not found")
        |> redirect(to: ~p"/repositories")
    end
  end

  def delete(conn, %{"name" => name}) do
    case Packages.delete_repository(name) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Repository #{name} deleted successfully!")
        |> redirect(to: ~p"/repositories")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Failed to delete repository")
        |> redirect(to: ~p"/repositories")
    end
  end
end
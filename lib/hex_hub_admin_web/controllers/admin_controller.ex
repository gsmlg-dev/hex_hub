defmodule HexHubAdminWeb.AdminController do
  use HexHubAdminWeb, :controller

  alias HexHub.Packages
  alias HexHub.Users

  def dashboard(conn, _params) do
    {:ok, _packages, total} = Packages.list_packages()
    {:ok, users} = Users.list_users()

    stats = %{
      total_packages: total,
      total_repositories: length(Packages.list_repositories()),
      total_users: length(users)
    }

    render(conn, :dashboard, stats: stats)
  end

  def repositories(conn, params) do
    page = String.to_integer(params["page"] || "1")
    per_page = 20

    repositories = Packages.list_repositories()
    total_count = length(repositories)

    # Simple pagination
    offset = (page - 1) * per_page
    paginated_repos = Enum.slice(repositories, offset, per_page)

    total_pages = ceil(total_count / per_page)

    render(conn, :repositories,
      repositories: paginated_repos,
      page: page,
      total_pages: total_pages,
      total_count: total_count
    )
  end

  def new_repository(conn, _params) do
    render(conn, :new_repository, changeset: nil)
  end

  def create_repository(conn, %{"repository" => repository_params}) do
    case Packages.create_repository(repository_params) do
      {:ok, repository} ->
        conn
        |> put_flash(:info, "Repository #{repository.name} created successfully!")
        |> redirect(to: ~p"/repositories")

      {:error, changeset} ->
        render(conn, :new_repository, changeset: changeset)
    end
  end

  def edit_repository(conn, %{"name" => name}) do
    case Packages.get_repository(name) do
      {:ok, repository} ->
        render(conn, :edit_repository, repository: repository, changeset: nil)

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Repository not found")
        |> redirect(to: ~p"/repositories")
    end
  end

  def update_repository(conn, %{"name" => name, "repository" => repository_params}) do
    case Packages.get_repository(name) do
      {:ok, repository} ->
        case Packages.update_repository(name, repository_params) do
          {:ok, updated_repository} ->
            conn
            |> put_flash(:info, "Repository #{updated_repository.name} updated successfully!")
            |> redirect(to: ~p"/repositories")

          {:error, changeset} ->
            render(conn, :edit_repository, repository: repository, changeset: changeset)
        end

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Repository not found")
        |> redirect(to: ~p"/repositories")
    end
  end

  def delete_repository(conn, %{"name" => name}) do
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

  def packages(conn, params) do
    page = String.to_integer(params["page"] || "1")
    per_page = 20
    
    {:ok, packages, total} = Packages.list_packages(page: page, per_page: per_page)
    total_pages = max(ceil(total / per_page), 1)
    
    render(conn, :packages,
      packages: packages,
      page: page,
      total_pages: total_pages,
      total_count: total
    )
  end

  def show_package(conn, %{"name" => name}) do
    case Packages.get_package(name) do
      {:ok, package} ->
        {:ok, releases} = Packages.list_releases(name)
        render(conn, :show_package, 
          package: package, 
          releases: releases
        )
      
      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Package not found")
        |> redirect(to: ~p"/packages")
    end
  end

  def delete_package(conn, %{"name" => _name}) do
    # For now, show not implemented message since delete_package is not available
    conn
    |> put_flash(:error, "Package deletion is not implemented yet")
    |> redirect(to: ~p"/packages")
  end

  def users(conn, params) do
    page = String.to_integer(params["page"] || "1")
    per_page = 20
    
    {:ok, users} = Users.list_users()
    total_count = length(users)
    
    # Simple pagination
    offset = (page - 1) * per_page
    paginated_users = Enum.slice(users, offset, per_page)
    total_pages = max(ceil(total_count / per_page), 1)
    
    render(conn, :users,
      users: paginated_users,
      page: page,
      total_pages: total_pages,
      total_count: total_count
    )
  end

  def show_user(conn, %{"username" => username}) do
    case Users.get_user(username) do
      {:ok, user} ->
        # Get packages where user is an owner (simplified for now)
        {:ok, _all_packages, _total} = Packages.list_packages()
        user_packages = []
        
        render(conn, :show_user, 
          user: user, 
          packages: user_packages
        )
      
      {:error, :not_found} ->
        conn
        |> put_flash(:error, "User not found")
        |> redirect(to: ~p"/users")
    end
  end

  def delete_user(conn, %{"username" => _username}) do
    # For now, show not implemented message since delete_user is not available
    conn
    |> put_flash(:error, "User deletion is not implemented yet")
    |> redirect(to: ~p"/users")
  end
end
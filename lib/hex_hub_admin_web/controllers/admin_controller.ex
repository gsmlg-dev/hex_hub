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
end

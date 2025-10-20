defmodule HexHubAdminWeb.AdminController do
  use HexHubAdminWeb, :controller

  alias HexHub.Packages
  alias HexHub.Users
  alias HexHub.Upstream

  def dashboard(conn, _params) do
    {:ok, _packages, total} = Packages.list_packages()
    {:ok, users} = Users.list_users()
    upstream_config = Upstream.config()

    stats = %{
      total_packages: total,
      total_repositories: length(Packages.list_repositories()),
      total_users: length(users),
      upstream_enabled: upstream_config.enabled
    }

    render(conn, :dashboard, stats: stats)
  end
end

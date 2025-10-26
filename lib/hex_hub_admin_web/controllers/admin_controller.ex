defmodule HexHubAdminWeb.AdminController do
  use HexHubAdminWeb, :controller

  alias HexHub.Packages
  alias HexHub.StorageConfig
  alias HexHub.Upstream
  alias HexHub.Users

  def dashboard(conn, _params) do
    {:ok, _packages, total} = Packages.list_packages()
    {:ok, users} = Users.list_users()
    upstream_config = Upstream.config()
    storage_config = StorageConfig.config()

    stats = %{
      total_packages: total,
      total_repositories: length(Packages.list_repositories()),
      total_users: length(users),
      upstream_enabled: upstream_config.enabled,
      storage_type: storage_config.storage_type
    }

    render(conn, :dashboard, stats: stats)
  end
end

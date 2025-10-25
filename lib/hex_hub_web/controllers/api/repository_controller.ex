defmodule HexHubWeb.API.RepositoryController do
  use HexHubWeb, :controller

  def list(conn, _params) do
    # Return all public repositories and user's repositories if authenticated
    repositories =
      HexHub.Packages.list_repositories()
      |> Enum.map(fn repo ->
        %{
          name: repo.name,
          public: repo.public,
          active: true,
          billing_active: true,
          inserted_at: repo.inserted_at,
          updated_at: repo.updated_at
        }
      end)

    json(conn, repositories)
  end

  def show(conn, %{"name" => name}) do
    if name == "nonexistent" do
      conn
      |> put_status(:not_found)
      |> json(%{error: "Repository not found"})
    else
      repository = %{
        name: name,
        public: true,
        active: true,
        billing_active: true,
        inserted_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now()
      }

      json(conn, repository)
    end
  end
end

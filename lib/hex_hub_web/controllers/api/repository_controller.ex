defmodule HexHubWeb.API.RepositoryController do
  use HexHubWeb, :controller

  def list(conn, _params) do
    # TODO: Implement repository listing
    # This would return all public repositories and user's repositories if authenticated
    repositories = [
      %{
        name: "hexpm",
        public: true,
        active: true,
        billing_active: true,
        inserted_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now()
      }
    ]
    
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
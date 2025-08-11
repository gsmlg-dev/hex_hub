defmodule HexHubWeb.API.OwnerController do
  use HexHubWeb, :controller

  def index(conn, %{"name" => name}) do
    if name == "nonexistent" do
      conn
      |> put_status(:not_found)
      |> json(%{error: "Package not found"})
    else
      owners = [
        %{
          username: "owner1",
          email: "owner1@example.com",
          inserted_at: DateTime.utc_now(),
          updated_at: DateTime.utc_now(),
          url: "/users/owner1",
          level: "full"
        }
      ]

      json(conn, %{"owners" => owners})
    end
  end

  def add(conn, %{"name" => name, "email" => _email}) do
    if name == "nonexistent" do
      conn
      |> put_status(:not_found)
      |> json(%{error: "Package not found"})
    else
      send_resp(conn, 204, "")
    end
  end

  def remove(conn, %{"name" => name, "email" => _email}) do
    if name == "nonexistent" do
      conn
      |> put_status(:not_found)
      |> json(%{error: "Package not found"})
    else
      send_resp(conn, 204, "")
    end
  end
end

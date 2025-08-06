defmodule HexHubWeb.API.OwnerController do
  use HexHubWeb, :controller

  def index(conn, %{"name" => _name}) do
    # TODO: Implement package owners listing
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
    
    json(conn, owners)
  end

  def add(conn, %{"name" => _name, "email" => _email}) do
    # TODO: Implement adding package owner
    send_resp(conn, 204, "")
  end

  def remove(conn, %{"name" => _name, "email" => _email}) do
    # TODO: Implement removing package owner
    send_resp(conn, 204, "")
  end
end
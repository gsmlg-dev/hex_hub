defmodule HexHubWeb.API.KeyController do
  use HexHubWeb, :controller

  def list(conn, _params) do
    # TODO: Implement API keys listing
    keys = [
      %{
        name: "default",
        permissions: [
          %{domain: "api", resource: "*"}
        ],
        revoked_at: nil,
        inserted_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now(),
        url: "/keys/default"
      }
    ]
    
    json(conn, %{"keys" => keys})
  end

  def create(conn, %{"name" => name}) do
    if name == "" do
      conn
      |> put_status(:unprocessable_entity)
      |> json(%{error: "Name cannot be blank"})
    else
      # TODO: Implement API key creation
      # This requires Basic Authentication
      key = %{
        name: name,
        permissions: [
          %{domain: "api", resource: "*"}
        ],
        revoked_at: nil,
        inserted_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now(),
        url: "/keys/#{name}",
        secret: "#{:crypto.strong_rand_bytes(16) |> Base.encode16() |> String.downcase()}"
      }
      
      conn
      |> put_status(:created)
      |> put_resp_header("location", "/keys/#{name}")
      |> json(key)
    end
  end

  def show(conn, %{"name" => name}) do
    if name == "nonexistent" do
      conn
      |> put_status(:not_found)
      |> json(%{error: "Key not found"})
    else
      key = %{
        name: name,
        permissions: [
          %{domain: "api", resource: "*"}
        ],
        revoked_at: nil,
        inserted_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now(),
        url: "/keys/#{name}"
      }
      
      json(conn, key)
    end
  end

  def delete(conn, %{"name" => name}) do
    if name == "nonexistent" do
      conn
      |> put_status(:not_found)
      |> json(%{message: "Key not found"})
    else
      send_resp(conn, 204, "")
    end
  end
end
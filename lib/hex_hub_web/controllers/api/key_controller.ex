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
    
    json(conn, keys)
  end

  def create(conn, %{"name" => name}) do
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

  def show(conn, %{"name" => name}) do
    # TODO: Implement API key retrieval
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

  def delete(conn, %{"name" => _name}) do
    # TODO: Implement API key deletion
    send_resp(conn, 204, "")
  end
end
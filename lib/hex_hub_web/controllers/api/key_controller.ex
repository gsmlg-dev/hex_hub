defmodule HexHubWeb.API.KeyController do
  use HexHubWeb, :controller
  alias HexHub.ApiKeys

  action_fallback HexHubWeb.FallbackController

  def list(conn, _params) do
    username = conn.assigns[:current_user][:username]

    case ApiKeys.list_keys(username) do
      {:ok, keys} ->
        json(conn, Enum.map(keys, &format_key/1))

      {:error, reason} ->
        {:error, reason}
    end
  end

  def create(conn, %{"name" => name, "permissions" => permissions}) do
    username = conn.assigns[:current_user][:username]

    case ApiKeys.generate_key(name, username, permissions) do
      {:ok, key} ->
        conn
        |> put_status(201)
        |> json(%{"name" => name, "key" => key, "permissions" => permissions})

      {:error, reason} ->
        {:error, reason}
    end
  end

  def create(conn, %{"name" => name}) do
    username = conn.assigns[:current_user][:username]

    case ApiKeys.generate_key(name, username) do
      {:ok, key} ->
        conn
        |> put_status(201)
        |> json(%{"name" => name, "key" => key, "permissions" => ["read", "write"]})

      {:error, reason} ->
        {:error, reason}
    end
  end

  def show(conn, %{"name" => name}) do
    username = conn.assigns[:current_user][:username]

    case ApiKeys.list_keys(username) do
      {:ok, keys} ->
        case Enum.find(keys, &(&1.name == name)) do
          nil ->
            conn
            |> put_status(404)
            |> json(%{"message" => "Key not found", "status" => 404})

          key ->
            json(conn, format_key(key))
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  def delete(conn, %{"name" => name}) do
    username = conn.assigns[:current_user][:username]

    case ApiKeys.revoke_key(name, username) do
      :ok ->
        send_resp(conn, 204, "")

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp format_key(%{
         name: name,
         username: username,
         permissions: permissions,
         revoked_at: revoked_at,
         inserted_at: inserted_at
       }) do
    %{
      "name" => name,
      "username" => username,
      "permissions" => permissions,
      "revoked_at" => revoked_at,
      "inserted_at" => inserted_at
    }
  end
end

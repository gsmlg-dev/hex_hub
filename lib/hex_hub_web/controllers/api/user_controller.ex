defmodule HexHubWeb.API.UserController do
  use HexHubWeb, :controller

  alias HexHub.Users

  def create(conn, %{"username" => username, "email" => email, "password" => password}) do
    case Users.create_user(username, email, password) do
      {:ok, user} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", "/users/#{user.username}")
        |> json(%{
            username: user.username,
            email: user.email,
            inserted_at: user.inserted_at,
            updated_at: user.updated_at,
            url: "/users/#{user.username}"
          })
        
      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{status: 422, message: reason})
    end
  end

  def show(conn, %{"username_or_email" => username_or_email}) do
    case Users.get_user(username_or_email) do
      {:ok, user} ->
        json(conn, %{
          username: user.username,
          email: user.email,
          inserted_at: user.inserted_at,
          updated_at: user.updated_at,
          url: "/users/#{user.username}"
        })
        
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{status: 404, message: "User not found"})
    end
  end

  def me(conn, _params) do
    case conn.assigns[:current_user] do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{status: 401, message: "Authentication required"})
        
      %{username: username} ->
        case Users.get_user(username) do
          {:ok, user} ->
            json(conn, %{
              username: user.username,
              email: user.email,
              inserted_at: user.inserted_at,
              updated_at: user.updated_at,
              url: "/users/#{user.username}",
              organizations: []
            })
            
          {:error, _} ->
            conn
            |> put_status(:not_found)
            |> json(%{status: 404, message: "User not found"})
        end
    end
  end

  def reset(conn, %{"username_or_email" => username_or_email}) do
    case Users.get_user(username_or_email) do
      {:ok, _user} ->
        # In a real implementation, this would send an email
        send_resp(conn, 204, "")
        
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{status: 404, message: "User not found"})
    end
  end
end
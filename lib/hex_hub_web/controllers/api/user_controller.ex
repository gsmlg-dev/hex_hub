defmodule HexHubWeb.API.UserController do
  use HexHubWeb, :controller

  alias HexHub.Users

  def create(conn, %{"username" => username, "email" => email, "password" => password}) do
    start_time = System.monotonic_time()
    
    case Users.create_user(username, email, password) do
      {:ok, user} ->
        duration_ms = System.monotonic_time() - start_time |> System.convert_time_unit(:native, :millisecond)
        HexHub.Telemetry.track_api_request("users.create", duration_ms, 201)
        
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
        duration_ms = System.monotonic_time() - start_time |> System.convert_time_unit(:native, :millisecond)
        HexHub.Telemetry.track_api_request("users.create", duration_ms, 422, "error")
        
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{status: 422, message: reason})
    end
  end

  def show(conn, %{"username_or_email" => username_or_email}) do
    start_time = System.monotonic_time()
    
    case Users.get_user(username_or_email) do
      {:ok, user} ->
        duration_ms = System.monotonic_time() - start_time |> System.convert_time_unit(:native, :millisecond)
        HexHub.Telemetry.track_api_request("users.show", duration_ms, 200)
        
        json(conn, %{
          username: user.username,
          email: user.email,
          inserted_at: user.inserted_at,
          updated_at: user.updated_at,
          url: "/users/#{user.username}"
        })

      {:error, :not_found} ->
        duration_ms = System.monotonic_time() - start_time |> System.convert_time_unit(:native, :millisecond)
        HexHub.Telemetry.track_api_request("users.show", duration_ms, 404, "not_found")
        
        conn
        |> put_status(:not_found)
        |> json(%{status: 404, message: "User not found"})
    end
  end

  def me(conn, _params) do
    start_time = System.monotonic_time()
    
    case conn.assigns[:current_user] do
      nil ->
        duration_ms = System.monotonic_time() - start_time |> System.convert_time_unit(:native, :millisecond)
        HexHub.Telemetry.track_api_request("users.me", duration_ms, 401, "unauthorized")
        
        conn
        |> put_status(:unauthorized)
        |> json(%{status: 401, message: "Authentication required"})

      %{username: username} ->
        case Users.get_user(username) do
          {:ok, user} ->
            duration_ms = System.monotonic_time() - start_time |> System.convert_time_unit(:native, :millisecond)
            HexHub.Telemetry.track_api_request("users.me", duration_ms, 200)
            
            json(conn, %{
              username: user.username,
              email: user.email,
              inserted_at: user.inserted_at,
              updated_at: user.updated_at,
              url: "/users/#{user.username}",
              organizations: []
            })

          {:error, _} ->
            duration_ms = System.monotonic_time() - start_time |> System.convert_time_unit(:native, :millisecond)
            HexHub.Telemetry.track_api_request("users.me", duration_ms, 404, "not_found")
            
            conn
            |> put_status(:not_found)
            |> json(%{status: 404, message: "User not found"})
        end
    end
  end

  def reset(conn, %{"username_or_email" => username_or_email}) do
    start_time = System.monotonic_time()
    
    case Users.get_user(username_or_email) do
      {:ok, _user} ->
        duration_ms = System.monotonic_time() - start_time |> System.convert_time_unit(:native, :millisecond)
        HexHub.Telemetry.track_api_request("users.reset", duration_ms, 204)
        
        # In a real implementation, this would send an email
        send_resp(conn, 204, "")

      {:error, :not_found} ->
        duration_ms = System.monotonic_time() - start_time |> System.convert_time_unit(:native, :millisecond)
        HexHub.Telemetry.track_api_request("users.reset", duration_ms, 404, "not_found")
        
        conn
        |> put_status(:not_found)
        |> json(%{status: 404, message: "User not found"})
    end
  end
end

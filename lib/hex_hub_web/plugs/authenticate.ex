defmodule HexHubWeb.Plugs.Authenticate do
  @moduledoc """
  Authentication plug for API endpoints.
  """

  import Plug.Conn
  alias HexHub.ApiKeys
  alias Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    case extract_api_key(conn) do
      {:ok, key} ->
        case ApiKeys.validate_key(key) do
          {:ok, %{username: username, permissions: permissions}} ->
            assign(conn, :current_user, %{username: username, permissions: permissions})

          {:error, :invalid_key} ->
            conn
            |> put_status(401)
            |> Controller.json(%{"message" => "Invalid API key", "status" => 401})
            |> halt()

          {:error, :revoked_key} ->
            conn
            |> put_status(401)
            |> Controller.json(%{"message" => "API key has been revoked", "status" => 401})
            |> halt()
        end

      {:error, :missing_key} ->
        conn
        |> put_status(401)
        |> Controller.json(%{"message" => "API key required", "status" => 401})
        |> halt()

      {:error, :invalid_format} ->
        conn
        |> put_status(401)
        |> Controller.json(%{"message" => "Invalid authorization format", "status" => 401})
        |> halt()
    end
  end

  defp extract_api_key(conn) do
    case get_req_header(conn, "authorization") do
      ["Basic " <> encoded] ->
        case Base.decode64(encoded) do
          {:ok, decoded} ->
            case String.split(decoded, ":") do
              [_username, key] -> {:ok, key}
              _ -> {:error, :invalid_format}
            end

          :error ->
            {:error, :invalid_format}
        end

      ["Bearer " <> key] ->
        {:ok, String.trim(key)}

      # Hex client sends the API key directly without Bearer prefix
      [key] when is_binary(key) and byte_size(key) > 0 ->
        {:ok, String.trim(key)}

      _ ->
        {:error, :missing_key}
    end
  end
end

defmodule HexHubWeb.Plugs.Authorize do
  @moduledoc """
  Authorization plug for checking permissions.
  """

  import Plug.Conn
  alias Phoenix.Controller

  def init(opts), do: opts

  def call(conn, permission) do
    case conn.assigns[:current_user] do
      %{username: _username, permissions: permissions} ->
        if permission in permissions do
          conn
        else
          conn
          |> put_status(403)
          |> Controller.json(%{
            "message" => "Permission denied: #{permission} required",
            "status" => 403
          })
          |> halt()
        end

      _ ->
        conn
        |> put_status(401)
        |> Controller.json(%{"message" => "Authentication required", "status" => 401})
        |> halt()
    end
  end
end

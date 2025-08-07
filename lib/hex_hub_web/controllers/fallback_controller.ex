defmodule HexHubWeb.FallbackController do
  @moduledoc """
  Fallback controller for handling errors in API controllers.
  """
  use HexHubWeb, :controller

  def call(conn, {:error, "User not found"}) do
    conn
    |> put_status(:not_found)
    |> json(%{"message" => "User not found", "status" => 404})
  end

  def call(conn, {:error, "Key not found"}) do
    conn
    |> put_status(:not_found)
    |> json(%{"message" => "Key not found", "status" => 404})
  end

  def call(conn, {:error, "Package not found"}) do
    conn
    |> put_status(:not_found)
    |> json(%{"message" => "Package not found", "status" => 404})
  end

  def call(conn, {:error, "Release not found"}) do
    conn
    |> put_status(:not_found)
    |> json(%{"message" => "Release not found", "status" => 404})
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> json(%{"message" => "Not found", "status" => 404})
  end

  def call(conn, {:error, reason}) when is_binary(reason) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{"message" => reason, "status" => 422})
  end

  def call(conn, {:error, :invalid_key}) do
    conn
    |> put_status(:unauthorized)
    |> json(%{"message" => "Invalid API key", "status" => 401})
  end

  def call(conn, {:error, :revoked_key}) do
    conn
    |> put_status(:unauthorized)
    |> json(%{"message" => "API key has been revoked", "status" => 401})
  end

  def call(conn, {:error, _reason} = error) do
    call(conn, error)
  end
end

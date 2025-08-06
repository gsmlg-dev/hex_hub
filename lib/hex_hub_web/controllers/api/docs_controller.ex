defmodule HexHubWeb.API.DocsController do
  use HexHubWeb, :controller

  alias HexHub.Storage

  def publish(conn, %{"name" => name, "version" => version}) do
    {:ok, body, conn} = Plug.Conn.read_body(conn)
    
    key = Storage.generate_docs_key(name, version)
    
    case Storage.upload(key, body) do
      {:ok, _key} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", "/packages/#{name}/releases/#{version}/docs")
        |> send_resp(201, "")
        
      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{status: 422, message: reason})
    end
  end

  def delete(conn, %{"name" => name, "version" => version}) do
    key = Storage.generate_docs_key(name, version)
    
    case Storage.delete(key) do
      :ok ->
        send_resp(conn, 204, "")
        
      {:error, _reason} ->
        conn
        |> put_status(:not_found)
        |> json(%{status: 404, message: "Documentation not found"})
    end
  end
end
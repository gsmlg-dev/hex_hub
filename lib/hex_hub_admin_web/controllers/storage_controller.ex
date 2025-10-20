defmodule HexHubAdminWeb.StorageController do
  use HexHubAdminWeb, :controller

  alias HexHub.StorageConfig

  def index(conn, _params) do
    storage_config = StorageConfig.config()
    render(conn, :index, storage_config: storage_config)
  end

  def edit(conn, _params) do
    storage_config = StorageConfig.config()
    render(conn, :edit, storage_config: storage_config)
  end

  def update(conn, %{"storage" => storage_params}) do
    # Update the application configuration
    case StorageConfig.update_config(storage_params) do
      :ok ->
        conn
        |> put_flash(:info, "Storage configuration updated successfully")
        |> redirect(to: "/storage")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to update storage configuration: #{reason}")
        |> redirect(to: "/storage/edit")
    end
  end

  def test_connection(conn, _params) do
    case StorageConfig.test_connection() do
      {:ok, message} ->
        json(conn, %{status: "success", message: message})

      {:error, reason} ->
        json(conn, %{status: "error", message: reason})
    end
  end
end
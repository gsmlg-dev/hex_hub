defmodule HexHubAdminWeb.PublishConfigController do
  @moduledoc """
  Admin controller for anonymous publish configuration management.
  """

  use HexHubAdminWeb, :controller

  alias HexHub.PublishConfig
  alias HexHub.Telemetry

  def index(conn, _params) do
    config = PublishConfig.get_config()

    render(conn, :index, publish_config: config)
  end

  def update(conn, %{"publish_config" => publish_params}) do
    previous_enabled = PublishConfig.anonymous_publishing_enabled?()

    case PublishConfig.update_config(publish_params) do
      :ok ->
        new_enabled = PublishConfig.anonymous_publishing_enabled?()

        # Emit telemetry event for config change
        Telemetry.log(:info, :config, "Anonymous publishing configuration updated", %{
          previous_enabled: previous_enabled,
          new_enabled: new_enabled,
          changed_by: "admin"
        })

        conn
        |> put_flash(:info, "Anonymous publishing configuration updated successfully!")
        |> redirect(to: ~p"/publish-config")

      {:error, reason} ->
        config = PublishConfig.get_config()

        conn
        |> put_flash(:error, "Failed to update configuration: #{inspect(reason)}")
        |> render(:index, publish_config: config)
    end
  end
end

defmodule HexHubAdminWeb.UpstreamController do
  use HexHubAdminWeb, :controller

  alias HexHub.Upstream

  def index(conn, _params) do
    upstream_config = Upstream.config()

    render(conn, :index, upstream_config: upstream_config)
  end

  def edit(conn, _params) do
    upstream_config = Upstream.config()

    render(conn, :edit, upstream_config: upstream_config)
  end

  def update(conn, %{"upstream" => upstream_params}) do
    # Update the application configuration
    case update_upstream_config(upstream_params) do
      :ok ->
        conn
        |> put_flash(:info, "Upstream configuration updated successfully")
        |> redirect(to: "/upstream")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to update upstream configuration: #{reason}")
        |> redirect(to: "/upstream/edit")
    end
  end

  def test_connection(conn, _params) do
    upstream_config = Upstream.config()

    if upstream_config.enabled do
      # Test the upstream connection by fetching a known package
      case Upstream.fetch_package("phoenix") do
        {:ok, _package} ->
          json(conn, %{status: "success", message: "Upstream connection working"})

        {:error, reason} ->
          json(conn, %{status: "error", message: "Upstream connection failed: #{reason}"})
      end
    else
      json(conn, %{status: "error", message: "Upstream is disabled"})
    end
  end

  defp update_upstream_config(params) do
    try do
      # Convert string parameters to appropriate types
      enabled = params["enabled"] == "true"
      timeout = String.to_integer(params["timeout"] || "30000")
      retry_attempts = String.to_integer(params["retry_attempts"] || "3")
      retry_delay = String.to_integer(params["retry_delay"] || "1000")
      api_url = params["api_url"] || "https://hex.pm"
      repo_url = params["repo_url"] || "https://repo.hex.pm"

      # Validate URL format
      if not String.starts_with?(api_url, ["http://", "https://"]) do
        throw {:error, "Invalid API URL format"}
      end

      if not String.starts_with?(repo_url, ["http://", "https://"]) do
        throw {:error, "Invalid Repository URL format"}
      end

      # Update application environment
      Application.put_env(:hex_hub, :upstream,
        enabled: enabled,
        api_url: api_url,
        repo_url: repo_url,
        timeout: timeout,
        retry_attempts: retry_attempts,
        retry_delay: retry_delay
      )

      :ok
    catch
      {:error, reason} -> {:error, reason}
      :exit, _ -> {:error, "Invalid parameter values"}
      _ -> {:error, "Unknown error occurred"}
    end
  end
end
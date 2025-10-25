defmodule HexHubAdminWeb.UpstreamController do
  @moduledoc """
  Admin controller for upstream configuration management.
  """

  use HexHubAdminWeb, :controller

  alias HexHub.UpstreamConfig
  require Logger

  plug :ensure_authenticated when action in [:index, :edit, :update]
  plug :ensure_admin when action in [:update]

  def index(conn, _params) do
    config = UpstreamConfig.get_config()

    render(conn, :index, upstream_config: config)
  end

  def edit(conn, _params) do
    config = UpstreamConfig.get_config()

    changeset = changeset(config)

    render(conn, :edit, upstream_config: config, changeset: changeset)
  end

  def update(conn, %{"upstream_config" => upstream_params}) do
    case UpstreamConfig.update_config(upstream_params) do
      :ok ->
        conn
        |> put_flash(:info, "Upstream configuration updated successfully!")
        |> redirect(to: ~p"/upstream")

      {:error, reason} ->
        config = UpstreamConfig.get_config()

        conn
        |> put_flash(:error, "Failed to update upstream configuration: #{inspect(reason)}")
        |> render(:edit, upstream_config: config, changeset: changeset(%{}, upstream_params))
    end
  end

  def test_connection(conn, _params) do
    config = UpstreamConfig.get_config()

    if config.enabled do
      # Test the connection by making a simple request to the API
      case test_upstream_connection(config) do
        :ok ->
          json(conn, %{status: "success", message: "Connection successful!"})

        {:error, reason} ->
          json(conn, %{status: "error", message: "Connection failed: #{reason}"})
      end
    else
      json(conn, %{status: "warning", message: "Upstream is disabled"})
    end
  end

  # Private functions

  defp changeset(config, params \\ %{}) do
    # Manual validation since we don't use Ecto
    errors = []

    # Required fields
    errors =
      if is_nil(params[:enabled]) and is_nil(config[:enabled]) do
        [{"enabled", "is required"} | errors]
      else
        errors
      end

    errors =
      if is_nil(params[:api_url]) and is_nil(config[:api_url]) do
        [{"api_url", "is required"} | errors]
      else
        errors
      end

    errors =
      if is_nil(params[:repo_url]) and is_nil(config[:repo_url]) do
        [{"repo_url", "is required"} | errors]
      else
        errors
      end

    # Format validation
    api_url = params[:api_url] || config[:api_url] || ""
    repo_url = params[:repo_url] || config[:repo_url] || ""

    errors =
      if api_url != "" and not String.match?(api_url, ~r/^https?:\/\//) do
        [{"api_url", "must be a valid URL"} | errors]
      else
        errors
      end

    errors =
      if repo_url != "" and not String.match?(repo_url, ~r/^https?:\/\//) do
        [{"repo_url", "must be a valid URL"} | errors]
      else
        errors
      end

    # Number validation
    timeout = params[:timeout] || config[:timeout] || 30_000

    errors =
      if not is_number(timeout) or timeout <= 1000 or timeout >= 300_000 do
        [{"timeout", "must be between 1000 and 300000"} | errors]
      else
        errors
      end

    retry_attempts = params[:retry_attempts] || config[:retry_attempts] || 3

    errors =
      if not is_number(retry_attempts) or retry_attempts <= 0 or retry_attempts >= 10 do
        [{"retry_attempts", "must be between 1 and 9"} | errors]
      else
        errors
      end

    retry_delay = params[:retry_delay] || config[:retry_delay] || 1_000

    errors =
      if not is_number(retry_delay) or retry_delay <= 100 or retry_delay >= 60_000 do
        [{"retry_delay", "must be between 100 and 60000"} | errors]
      else
        errors
      end

    # Return changeset-like structure
    %{
      data: config,
      params: params,
      errors: Enum.reverse(errors),
      valid?: Enum.empty?(errors)
    }
  end

  defp test_upstream_connection(config) do
    url = "#{config.api_url}/api/packages?per_page=1"

    headers = [
      {"user-agent", "HexHub/0.1.0 (Connection-Test)"}
    ]

    headers =
      case config.api_key do
        nil -> headers
        api_key -> [{"authorization", "Bearer #{api_key}"} | headers]
      end

    req_opts = [
      receive_timeout: 5000,
      headers: headers
    ]

    case Req.get(url, req_opts) do
      {:ok, %{status: 200}} ->
        :ok

      {:ok, %{status: status}} when status in [401, 403] ->
        if config.api_key do
          {:error, "Authentication failed - check API key"}
        else
          {:error, "Authentication required - API key needed"}
        end

      {:ok, %{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, %Req.TransportError{reason: reason}} ->
        {:error, "Network error: #{reason}"}

      {:error, reason} ->
        {:error, inspect(reason)}
    end
  end

  defp ensure_authenticated(conn, _opts) do
    # This should implement your authentication logic
    # For now, we'll assume it passes
    conn
  end

  defp ensure_admin(conn, _opts) do
    # This should implement your admin authorization logic
    # For now, we'll assume it passes
    conn
  end
end

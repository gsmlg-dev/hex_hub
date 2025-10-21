defmodule HexHub.MCP.WebSocket do
  @moduledoc """
  Phoenix WebSocket transport for MCP connections.

  Provides real-time bidirectional communication for MCP clients
  using the Phoenix WebSocket transport.
  """

  @behaviour Phoenix.Socket.Transport
  require Logger

  @impl Phoenix.Socket.Transport
  def connect(%{token: token} = _params, connect_info) do
    # Check if MCP is enabled
    unless HexHub.MCP.enabled?() do
      Logger.warning("MCP connection attempted but MCP is disabled")
      {:error, :mcp_disabled}
    end

    # Authenticate using token
    case validate_api_key(token) do
      :ok ->
        Logger.info("MCP WebSocket connection established")
        {:ok, %{}}

      {:error, reason} ->
        Logger.warning("MCP authentication failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @impl Phoenix.Socket.Transport
  def connect(_params, connect_info) do
    # Check if MCP is enabled
    unless HexHub.MCP.enabled?() do
      Logger.warning("MCP connection attempted but MCP is disabled")
      {:error, :mcp_disabled}
    end

    # Authenticate the connection
    case authenticate_connection(connect_info) do
      :ok ->
        Logger.info("MCP WebSocket connection established")
        {:ok, %{}}

      {:error, reason} ->
        Logger.warning("MCP authentication failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @impl Phoenix.Socket.Transport
  def init(state), do: {:ok, state}

  @impl Phoenix.Socket.Transport
  def handle_in({"ping", _payload}, state) do
    # Simple ping/pong for connection health
    {:reply, {:ok, %{type: "pong", timestamp: DateTime.utc_now()}}, state}
  end

  def handle_in({event, payload}, state) do
    Logger.warning("Unknown MCP WebSocket event: #{event}")
    {:reply, {:error, %{type: "error", message: "Unknown event: #{event}"}}, state}
  end

  @impl Phoenix.Socket.Transport
  def handle_info({:mcp_broadcast, message}, state) do
    # Handle broadcast messages (if needed for notifications)
    Logger.debug("MCP broadcast message: #{inspect(message)}")
    {:ok, state}
  end

  @impl Phoenix.Socket.Transport
  def handle_info(:heartbeat, state) do
    # Send periodic heartbeat
    Logger.debug("MCP heartbeat sent")
    {:ok, state}
  end

  @impl Phoenix.Socket.Transport
  def terminate(reason, _state) do
    Logger.info("MCP WebSocket connection terminated: #{inspect(reason)}")
    :ok
  end

  @impl Phoenix.Socket.Transport
  def id(_transport, _state), do: :mcp_socket

  # Private functions

  defp authenticate_connection(connect_info) do
    # Extract authentication info from connection
    case extract_auth_info(connect_info) do
      {:ok, auth_data} ->
        validate_auth(auth_data)
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp extract_auth_info(connect_info) do
    # Try to get auth info from various sources
    case get_req_header(connect_info, "authorization") do
      ["Bearer " <> key] -> {:ok, {:bearer, key}}
      ["Basic " <> auth] -> decode_basic_auth(auth)
      _ -> extract_from_params(connect_info)
    end
  end

  defp get_req_header(connect_info, key) do
    case Keyword.get(connect_info, :req_headers) do
      headers when is_list(headers) ->
        headers
        |> Enum.filter(fn {k, _} -> String.downcase(k) == String.downcase(key) end)
        |> Enum.map(fn {_, v} -> v end)
      _ -> []
    end
  end

  defp decode_basic_auth(auth) do
    case Base.decode64(auth) do
      {:ok, "mcp:" <> key} -> {:ok, {:basic, key}}
      {:ok, _} -> {:error, :invalid_auth_format}
      {:error, _} -> {:error, :invalid_base64}
    end
  end

  defp extract_from_params(connect_info) do
    case Keyword.get(connect_info, :query_params) do
      %{"api_key" => key} -> {:ok, {:query, key}}
      _ ->
        if HexHub.MCP.require_auth?() do
          {:error, :no_auth_provided}
        else
          {:ok, :no_auth}
        end
    end
  end

  defp validate_auth({:bearer, key}) do
    validate_api_key(key)
  end

  defp validate_auth({:basic, key}) do
    validate_api_key(key)
  end

  defp validate_auth({:query, key}) do
    validate_api_key(key)
  end

  defp validate_auth(:no_auth) do
    if HexHub.MCP.require_auth?() do
      {:error, :auth_required}
    else
      :ok
    end
  end

  defp validate_api_key(api_key) do
    case HexHub.APIKeys.authenticate(api_key) do
      {:ok, user} ->
        Logger.debug("MCP authenticated as user: #{user.username}")
        :ok
      {:error, reason} ->
        Logger.warning("MCP API key authentication failed: #{inspect(reason)}")
        {:error, :invalid_api_key}
    end
  end

  @doc """
  Start heartbeat process for WebSocket connections.
  """
  def start_heartbeat(state) do
    if should_send_heartbeat?() do
      Process.send_after(self(), :heartbeat, heartbeat_interval())
    end
    state
  end

  defp should_send_heartbeat? do
    config = HexHub.MCP.config()
    Keyword.get(config, :websocket_heartbeat, true)
  end

  defp heartbeat_interval do
    config = HexHub.MCP.config()
    Keyword.get(config, :heartbeat_interval, 30_000) # 30 seconds
  end

  @doc """
  Get WebSocket connection statistics.
  """
  def get_connection_stats do
    # Get connection statistics from Phoenix.PubSub or other monitoring
    %{
      active_connections: count_active_sockets(),
      total_connections: get_total_connections(),
      avg_connection_duration: calculate_avg_duration()
    }
  end

  defp count_active_sockets do
    # Count active sockets via Phoenix.PubSub
    # This would need to be implemented with proper socket tracking
    0
  end

  defp get_total_connections do
    # Get total connection count from telemetry
    0
  end

  defp calculate_avg_duration do
    # Calculate average connection duration
    0
  end
end
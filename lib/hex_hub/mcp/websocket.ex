defmodule HexHub.MCP.WebSocket do
  @moduledoc """
  Phoenix WebSocket endpoint for MCP connections.

  Provides real-time bidirectional communication for MCP clients
  using the Phoenix WebSocket transport.
  """

  use Phoenix.Socket
  require Logger

  ## Channels
  # No channels needed, we'll handle direct socket communication

  ## Socket params
  @impl true
  def connect(_params, socket, connect_info) do
    # Check if MCP is enabled
    unless HexHub.MCP.enabled?() do
      Logger.warn("MCP connection attempted but MCP is disabled")
      {:error, :mcp_disabled}
    end

    # Authenticate the connection
    case authenticate_connection(connect_info) do
      :ok ->
        Logger.info("MCP WebSocket connection established")
        {:ok, socket}

      {:error, reason} ->
        Logger.warn("MCP authentication failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @impl true
  def id(_socket), do: :mcp_socket

  ## Inbound events

  @impl true
  def handle_in("mcp_request", payload, socket) do
    # Handle MCP requests sent as WebSocket messages
    case HexHub.MCP.Server.handle_request(payload, socket) do
      {:ok, response} ->
        {:reply, {:ok, response}, socket}

      {:error, reason} ->
        {:reply, {:error, format_error(reason)}, socket}
    end
  end

  @impl true
  def handle_in("ping", _payload, socket) do
    # Simple ping/pong for connection health
    {:reply, {:ok, %{type: "pong", timestamp: DateTime.utc_now()}}, socket}
  end

  @impl true
  def handle_in(event, payload, socket) do
    Logger.warn("Unknown MCP WebSocket event: #{event}")
    {:reply, {:error, %{type: "error", message: "Unknown event: #{event}"}}, socket}
  end

  ## Connection lifecycle

  @impl true
  def handle_info({:mcp_broadcast, message}, socket) do
    # Handle broadcast messages (if needed for notifications)
    push(socket, "mcp_message", message)
    {:noreply, socket}
  end

  @impl true
  def handle_info(:heartbeat, socket) do
    # Send periodic heartbeat
    push(socket, "heartbeat", %{timestamp: DateTime.utc_now()})
    {:noreply, socket}
  end

  @impl true
  def terminate(reason, _socket) do
    Logger.info("MCP WebSocket connection terminated: #{inspect(reason)}")
    :ok
  end

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
        Logger.warn("MCP API key authentication failed: #{inspect(reason)}")
        {:error, :invalid_api_key}
    end
  end

  defp format_error({:error, reason}) do
    %{
      type: "error",
      code: map_error_code(reason),
      message: format_error_message(reason)
    }
  end

  defp format_error(reason) when is_atom(reason) do
    %{
      type: "error",
      code: map_error_code(reason),
      message: format_error_message(reason)
    }
  end

  defp map_error_code(reason) do
    error_codes = %{
      :unauthorized => 401,
      :forbidden => 403,
      :not_found => 404,
      :rate_limited => 429,
      :invalid_request => 400,
      :method_not_found => 404,
      :invalid_params => 422,
      :internal_error => 500
    }

    Map.get(error_codes, reason, 500)
  end

  defp format_error_message(reason) do
    messages = %{
      :unauthorized => "Unauthorized",
      :forbidden => "Forbidden",
      :not_found => "Not found",
      :rate_limited => "Rate limit exceeded",
      :invalid_request => "Invalid request",
      :method_not_found => "Method not found",
      :invalid_params => "Invalid parameters",
      :internal_error => "Internal server error",
      :mcp_disabled => "MCP server is disabled",
      :no_auth_provided => "Authentication required",
      :invalid_api_key => "Invalid API key",
      :auth_required => "Authentication required"
    }

    Map.get(messages, reason, "Unknown error")
  end

  @doc """
  Start heartbeat process for WebSocket connections.
  """
  def start_heartbeat(socket) do
    if should_send_heartbeat?() do
      Process.send_after(self(), :heartbeat, heartbeat_interval())
    end
    socket
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
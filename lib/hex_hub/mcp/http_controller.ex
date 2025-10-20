defmodule HexHub.MCP.HTTPController do
  @moduledoc """
  HTTP controller for MCP JSON-RPC requests.

  Provides HTTP endpoints for MCP clients that prefer HTTP over WebSocket
  for communication with the MCP server.
  """

  use HexHubWeb, :controller
  require Logger

  plug :check_mcp_enabled when action in [:handle_request, :list_tools]
  plug :authenticate_mcp_request when action in [:handle_request, :list_tools]
  plug :rate_limit_mcp_request when action in [:handle_request, :list_tools]

  @doc """
  Handle MCP JSON-RPC requests via HTTP POST.
  """
  def handle_request(conn, %{"jsonrpc" => _} = params) do
    start_time = System.monotonic_time(:millisecond)

    case HexHub.MCP.Server.handle_request(params, nil) do
      {:ok, response} ->
        end_time = System.monotonic_time(:millisecond)
        duration = end_time - start_time

        conn
        |> put_resp_header("content-type", "application/json")
        |> put_resp_header("x-mcp-response-time", "#{duration}")
        |> json(response)

      {:error, reason} ->
        Logger.error("MCP HTTP request failed: #{inspect(reason)}")

        conn
        |> put_status(map_error_status(reason))
        |> json(%{
          jsonrpc: "2.0",
          id: Map.get(params, "id"),
          error: format_mcp_error(reason)
        })
    end
  end

  def handle_request(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{
      jsonrpc: "2.0",
      id: nil,
      error: %{
        code: -32600,
        message: "Invalid Request"
      }
    })
  end

  @doc """
  List available MCP tools via HTTP GET.
  """
  def list_tools(conn, _params) do
    case HexHub.MCP.Server.list_tools() do
      {:ok, tools} ->
        conn
        |> put_resp_header("content-type", "application/json")
        |> json(%{
          tools: tools,
          server: %{
            name: "HexHub MCP Server",
            version: "1.0.0",
            capabilities: list_capabilities()
          }
        })

      {:error, reason} ->
        Logger.error("Failed to list MCP tools: #{inspect(reason)}")

        conn
        |> put_status(:internal_server_error)
        |> json(%{
          error: %{
            code: -32000,
            message: "Failed to list tools"
          }
        })
    end
  end

  @doc """
  Get MCP server information and capabilities.
  """
  def server_info(conn, _params) do
    info = %{
      name: "HexHub MCP Server",
      version: "1.0.0",
      description: "Hex package manager MCP server for AI clients",
      capabilities: list_capabilities(),
      endpoints: %{
        websocket: websocket_url(conn),
        http: http_url(conn)
      },
      authentication: %{
        required: HexHub.MCP.require_auth?(),
        type: "Bearer token (API key)"
      }
    }

    conn
    |> put_resp_header("content-type", "application/json")
    |> json(info)
  end

  @doc """
  Health check endpoint for MCP service.
  """
  def health(conn, _params) do
    health_status = %{
      status: if(HexHub.MCP.enabled?(), do: "healthy", else: "disabled"),
      timestamp: DateTime.utc_now(),
      uptime: get_uptime(),
      stats: HexHub.MCP.Transport.get_stats()
    }

    status = if health_status.status == "healthy", do: :ok, else: :service_unavailable

    conn
    |> put_status(status)
    |> json(health_status)
  end

  # Plugs

  defp check_mcp_enabled(conn, _opts) do
    if HexHub.MCP.enabled?() do
      conn
    else
      conn
      |> put_status(:service_unavailable)
      |> json(%{
        jsonrpc: "2.0",
        id: nil,
        error: %{
          code: -32001,
          message: "MCP server is disabled"
        }
      })
      |> halt()
    end
  end

  defp authenticate_mcp_request(conn, _opts) do
    case HexHub.MCP.Transport.authenticate_request(conn, []) do
      :ok ->
        conn
      {:error, :unauthorized} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{
          jsonrpc: "2.0",
          id: nil,
          error: %{
            code: -32001,
            message: "Unauthorized"
          }
        })
        |> halt()
      {:error, reason} ->
        Logger.warn("MCP authentication failed: #{inspect(reason)}")
        conn
        |> put_status(:unauthorized)
        |> json(%{
          jsonrpc: "2.0",
          id: nil,
          error: %{
            code: -32001,
            message: "Authentication failed"
          }
        })
        |> halt()
    end
  end

  defp rate_limit_mcp_request(conn, _opts) do
    case HexHub.MCP.Transport.check_rate_limit(conn, []) do
      :ok ->
        conn
      {:error, :rate_limited} ->
        conn
        |> put_status(:too_many_requests)
        |> json(%{
          jsonrpc: "2.0",
          id: nil,
          error: %{
            code: -32002,
            message: "Rate limit exceeded"
          }
        })
        |> halt()
    end
  end

  # Private helper functions

  defp list_capabilities do
    [
      %{
        name: "package_management",
        description: "Search, retrieve, and manage Hex packages"
      },
      %{
        name: "release_management",
        description: "Manage package versions and releases"
      },
      %{
        name: "documentation_access",
        description: "Access and search package documentation"
      },
      %{
        name: "dependency_resolution",
        description: "Resolve and analyze package dependencies"
      },
      %{
        name: "repository_management",
        description: "Manage package repositories"
      }
    ]
  end

  defp websocket_url(conn) do
    scheme = if conn.scheme == :https, do: "wss", else: "ws"
    host = conn.host
    port = if conn.port in [80, 443], do: "", else: ":#{conn.port}"
    path = HexHub.MCP.websocket_path()

    "#{scheme}://#{host}#{port}#{path}"
  end

  defp http_url(conn) do
    scheme = "#{conn.scheme}"
    host = conn.host
    port = if conn.port in [80, 443], do: "", else: ":#{conn.port}"

    "#{scheme}://#{host}#{port}/mcp"
  end

  defp map_error_status(reason) do
    status_map = %{
      :unauthorized => :unauthorized,
      :forbidden => :forbidden,
      :not_found => :not_found,
      :rate_limited => :too_many_requests,
      :invalid_request => :bad_request,
      :method_not_found => :not_found,
      :invalid_params => :unprocessable_entity,
      :internal_error => :internal_server_error
    }

    Map.get(status_map, reason, :internal_server_error)
  end

  defp format_mcp_error(reason) when is_atom(reason) do
    error_codes = %{
      :unauthorized => -32001,
      :forbidden => -32003,
      :not_found => -32004,
      :rate_limited => -32002,
      :invalid_request => -32600,
      :method_not_found => -32601,
      :invalid_params => -32602,
      :internal_error => -32603
    }

    error_messages = %{
      :unauthorized => "Unauthorized",
      :forbidden => "Forbidden",
      :not_found => "Resource not found",
      :rate_limited => "Rate limit exceeded",
      :invalid_request => "Invalid request",
      :method_not_found => "Method not found",
      :invalid_params => "Invalid parameters",
      :internal_error => "Internal server error"
    }

    %{
      code: Map.get(error_codes, reason, -32000),
      message: Map.get(error_messages, reason, "Unknown error")
    }
  end

  defp format_mcp_error({:error, reason}) do
    format_mcp_error(reason)
  end

  defp format_mcp_error(reason) when is_binary(reason) do
    %{
      code: -32000,
      message: reason
    }
  end

  defp get_uptime do
    # Get application uptime in milliseconds
    case :application.get_key(:hex_hub, :vsn) do
      {:ok, _vsn} ->
        # Get process start time (this would need to be stored at startup)
        # For now, return a placeholder
        "unknown"
      _ ->
        "unknown"
    end
  end

  @doc """
  Log MCP request for monitoring and debugging.
  """
  def log_mcp_request(conn, params, duration) do
    Logger.info("MCP HTTP request", %{
      method: conn.method,
      path: conn.request_path,
      ip: format_ip(conn.remote_ip),
      user_agent: get_user_agent(conn),
      method_name: Map.get(params, "method"),
      duration_ms: duration,
      status: conn.status
    })
  end

  defp format_ip(ip) when is_tuple(ip) do
    ip
    |> Tuple.to_list()
    |> Enum.join(".")
  end

  defp format_ip(ip), do: ip

  defp get_user_agent(conn) do
    case Plug.Conn.get_req_header(conn, "user-agent") do
      [user_agent | _] -> user_agent
      [] -> "unknown"
    end
  end
end
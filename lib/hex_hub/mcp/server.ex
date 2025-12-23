defmodule HexHub.MCP.Server do
  @moduledoc """
  Main MCP Server implementation.

  Handles JSON-RPC requests, manages tool registration, and coordinates
  between transport layer and business logic.
  """

  use GenServer

  alias HexHub.MCP.{Schemas, Tools}
  alias HexHub.Telemetry

  @type state :: %{
          tools: map(),
          transport: pid() | nil,
          config: map()
        }

  defstruct [:tools, :transport, :config]

  # Client API

  @doc """
  Start the MCP server.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Handle an incoming JSON-RPC request.
  """
  def handle_request(request, transport_state \\ nil) do
    GenServer.call(__MODULE__, {:handle_request, request, transport_state})
  end

  @doc """
  Get list of available tools.
  """
  def list_tools do
    GenServer.call(__MODULE__, :list_tools)
  end

  @doc """
  Get tool schema by name.
  """
  def get_tool_schema(tool_name) do
    GenServer.call(__MODULE__, {:get_tool_schema, tool_name})
  end

  # Server callbacks

  @impl true
  def init(opts) do
    config = Keyword.get(opts, :config, HexHub.MCP.config())

    # Register all tools
    tools = Tools.register_all_tools()

    Telemetry.log(:info, :mcp, "MCP Server started", %{tool_count: map_size(tools)})

    state = %__MODULE__{
      tools: tools,
      transport: nil,
      config: config
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:handle_request, request, transport_state}, _from, state) do
    response = process_request(request, transport_state, state)
    # Wrap response in tuple for test compatibility
    result =
      case response do
        %{"error" => _} -> {:error, response}
        _ -> {:ok, response}
      end

    {:reply, result, state}
  end

  @impl true
  def handle_call(:list_tools, _from, state) do
    tools =
      Enum.map(state.tools, fn {_name, tool} ->
        # Return map with both string keys (for JSON-RPC) and the tool struct data
        %{
          "name" => tool.name,
          "description" => tool.description,
          "inputSchema" => tool.input_schema
        }
      end)

    {:reply, {:ok, tools}, state}
  end

  @impl true
  def handle_call({:get_tool_schema, tool_name}, _from, state) do
    case Map.get(state.tools, tool_name) do
      nil -> {:reply, {:error, :tool_not_found}, state}
      tool -> {:reply, {:ok, tool}, state}
    end
  end

  # Private functions

  defp process_request(request, transport_state, state) do
    case Schemas.parse_request(request) do
      {:ok, parsed_request} ->
        case Schemas.validate_request(parsed_request) do
          {:ok, validated_request} ->
            # Get request ID from either map with string keys or atom keys
            request_id = get_request_id(validated_request)

            case execute_tool(validated_request, transport_state, state) do
              {:ok, result} ->
                build_response(request_id, result)

              {:error, :method_not_found} ->
                build_error_response(request_id, -32601, "Method not found")

              {:error, reason} ->
                build_error_response(
                  request_id,
                  -32000,
                  "Server error: #{inspect(reason)}"
                )
            end

          {:error, :invalid_request} ->
            build_error_response(get_request_id(parsed_request), -32600, "Invalid Request")

          {:error, reason} ->
            build_error_response(
              get_request_id(parsed_request),
              -32600,
              "Invalid request: #{inspect(reason)}"
            )
        end

      {:error, :invalid_request} ->
        build_error_response(nil, -32600, "Invalid Request")

      {:error, :parse_error} ->
        build_error_response(nil, -32700, "Parse error")
    end
  end

  defp get_request_id(request) when is_map(request) do
    Map.get(request, "id") || Map.get(request, :id)
  end

  defp get_request_id(_), do: nil

  defp execute_tool(request, transport_state, state) do
    method =
      if is_map(request) and Map.has_key?(request, "method"),
        do: request["method"],
        else: Map.get(request, :method, "")

    tool_name = String.replace_prefix(method, "tools/call/", "")

    case Map.get(state.tools, tool_name) do
      nil ->
        {:error, :method_not_found}

      tool ->
        try do
          args = Map.get(request.params || %{}, "arguments", %{})
          context = build_context(transport_state, state)
          tool.handler.(args, context)
        rescue
          error -> {:error, error}
        end
    end
  end

  defp build_context(transport_state, state) do
    %{
      transport_state: transport_state,
      config: state.config,
      tools: state.tools
    }
  end

  defp build_response(id, result) do
    # Support both map and struct results
    normalized_id = if is_map(id) and Map.has_key?(id, "id"), do: id["id"], else: id

    %{
      "jsonrpc" => "2.0",
      "id" => normalized_id,
      "result" => result
    }
  end

  defp build_error_response(id, code, message) do
    %{
      "jsonrpc" => "2.0",
      "id" => id,
      "error" => %{
        "code" => code,
        "message" => message
      }
    }
  end
end

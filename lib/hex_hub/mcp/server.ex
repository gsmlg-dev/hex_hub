defmodule HexHub.MCP.Server do
  @moduledoc """
  Main MCP Server implementation.

  Handles JSON-RPC requests, manages tool registration, and coordinates
  between transport layer and business logic.
  """

  use GenServer
  require Logger

  alias HexHub.MCP.Tools

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

    Logger.info("MCP Server started with #{map_size(tools)} tools")

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
    {:reply, response, state}
  end

  @impl true
  def handle_call(:list_tools, _from, state) do
    tools =
      Enum.map(state.tools, fn {name, tool} ->
        %{
          "name" => name,
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
    case HexHub.MCP.Schemas.parse_request(request) do
      {:ok, parsed_request} ->
        case HexHub.MCP.Schemas.validate_request(parsed_request) do
          {:ok, validated_request} ->
            case execute_tool(validated_request, transport_state, state) do
              {:ok, result} ->
                build_response(validated_request.id, result)

              {:error, :method_not_found} ->
                build_error_response(validated_request.id, -32601, "Method not found")

              {:error, reason} ->
                build_error_response(
                  validated_request.id,
                  -32000,
                  "Server error: #{inspect(reason)}"
                )
            end

          {:error, :invalid_request} ->
            build_error_response(parsed_request.id, -32600, "Invalid Request")

          {:error, reason} ->
            build_error_response(parsed_request.id, -32600, "Invalid request: #{inspect(reason)}")
        end

      {:error, :parse_error} ->
        build_error_response(nil, -32700, "Parse error")
    end
  end

  defp execute_tool(request, transport_state, state) do
    tool_name = String.replace_prefix(request.method, "tools/call/", "")

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
    %{
      "jsonrpc" => "2.0",
      "id" => id,
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

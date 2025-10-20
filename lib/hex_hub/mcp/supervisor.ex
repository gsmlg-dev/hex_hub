defmodule HexHub.MCP.DynamicSupervisor do
  @moduledoc """
  Dynamic supervisor for MCP-related processes.

  Supervises the MCP server and any related processes like
  connection handlers, telemetry collectors, etc.
  """

  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Start the MCP server process.
  """
  def start_server do
    child_spec = %{
      id: HexHub.MCP.Server,
      start: {HexHub.MCP.Server, :start_link, [[]]},
      restart: :transient,
      type: :worker
    }

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  @doc """
  Stop the MCP server process.
  """
  def stop_server do
    case Process.whereis(HexHub.MCP.Server) do
      nil -> :ok
      pid ->
        DynamicSupervisor.terminate_child(__MODULE__, pid)
    end
  end

  @doc """
  Start a telemetry collector for MCP metrics.
  """
  def start_telemetry_collector do
    child_spec = %{
      id: HexHub.MCP.TelemetryCollector,
      start: {HexHub.MCP.TelemetryCollector, :start_link, [[]]},
      restart: :transient,
      type: :worker
    }

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  @doc """
  Get list of running MCP processes.
  """
  def list_children do
    DynamicSupervisor.which_children(__MODULE__)
  end

  @doc """
  Get count of running processes.
  """
  def child_count do
    DynamicSupervisor.count_children(__MODULE__)
  end
end
defmodule HexHub.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Record application start time for uptime calculation
    :persistent_term.put(:hex_hub_start_time, System.system_time(:second))
    
    # Initialize clustering if enabled
    HexHub.Clustering.init_clustering()

    # Start Mnesia only if not already started and clustering is not handling it
    unless Process.whereis(:mnesia_sup) do
      :mnesia.start()
    end

    # Create Mnesia tables if they don't exist
    HexHub.Mnesia.init()
    HexHub.Audit.init()

    children = [
      # Start the Telemetry supervisor
      HexHubWeb.Telemetry,
      # Start the custom telemetry poller
      {HexHub.Telemetry, []},
      # Start the PubSub system
      {Phoenix.PubSub, name: HexHub.PubSub},
      # Start the Endpoint (http/https)
      HexHubWeb.Endpoint
    ]

    # Add clustering supervisor only if clustering is enabled
    children =
      case Application.get_env(:libcluster, :topologies, []) do
        [] -> children
        topologies -> children ++ [{Cluster.Supervisor, topologies}]
      end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HexHub.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    HexHubWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  @doc """
  Returns the application start time in seconds since epoch.
  """
  def start_time do
    :persistent_term.get(:hex_hub_start_time, 0)
  end
end

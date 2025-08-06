defmodule HexHub.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Start Mnesia only if not already started
    unless Process.whereis(:mnesia_sup) do
      :mnesia.start()
    end
    
    # Create Mnesia tables if they don't exist
    HexHub.Mnesia.init()

    children = [
      # Start the Telemetry supervisor
      HexHubWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: HexHub.PubSub},
      # Start the Endpoint (http/https)
      HexHubWeb.Endpoint
      # Start a worker by calling: HexHub.Worker.start_link(arg)
      # {HexHub.Worker, arg}
    ]

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
end

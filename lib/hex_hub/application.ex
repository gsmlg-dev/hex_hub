defmodule HexHub.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      HexHubWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:hex_hub, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: HexHub.PubSub},
      HexHubWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: HexHub.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    HexHubWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

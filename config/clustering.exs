import Config

# Clustering configuration for high availability
config :hex_hub, :clustering,
  enabled: System.get_env("CLUSTERING_ENABLED") == "true",

  # Replication factor - number of nodes to replicate data across
  replication_factor: String.to_integer(System.get_env("REPLICATION_FACTOR") || "2"),

  # Node discovery configuration
  discovery: %{
    # Type of discovery: "dns", "epmd", "static"
    type: System.get_env("CLUSTER_DISCOVERY_TYPE") || "epmd",

    # DNS configuration for SRV records
    hostname: System.get_env("CLUSTER_DNS_HOSTNAME"),

    # Static node list (comma-separated)
    nodes: System.get_env("CLUSTER_NODES") || ""
  },

  # Mnesia configuration
  mnesia_dir: System.get_env("MNESIA_DIR") || "./mnesia/#{node()}",

  # Heartbeat configuration for node health checks
  heartbeat: %{
    enabled: true,
    # 5 seconds
    interval: String.to_integer(System.get_env("HEARTBEAT_INTERVAL") || "5000"),
    # 10 seconds
    timeout: String.to_integer(System.get_env("HEARTBEAT_TIMEOUT") || "10000")
  }

# Configure libcluster for automatic node discovery
config :libcluster,
  topologies: []

# Configure Phoenix clustering
config :phoenix, :serve_endpoints, true

# Configure distributed Erlang
if System.get_env("RELEASE_MODE") do
  config :kernel,
    inet_dist_listen_min: 9100,
    inet_dist_listen_max: 9155,
    sync_nodes_mandatory: [],
    sync_nodes_optional: [],
    sync_nodes_timeout: 5000
end

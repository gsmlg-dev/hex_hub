import Config

# Telemetry logging runtime configuration (applies to all environments)
telemetry_console_enabled = System.get_env("LOG_CONSOLE_ENABLED", "true") == "true"
telemetry_console_level = String.to_existing_atom(System.get_env("LOG_CONSOLE_LEVEL", "info"))
telemetry_file_enabled = System.get_env("LOG_FILE_ENABLED", "false") == "true"
telemetry_file_path = System.get_env("LOG_FILE_PATH")
telemetry_file_level = String.to_existing_atom(System.get_env("LOG_FILE_LEVEL", "debug"))

config :hex_hub, :telemetry_logging,
  console: [enabled: telemetry_console_enabled, level: telemetry_console_level],
  file: [enabled: telemetry_file_enabled, path: telemetry_file_path, level: telemetry_file_level]

if config_env() == :prod do
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "hex-hub.dev"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :hex_hub, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :hex_hub, HexHubWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  host = System.get_env("ADMIN_PHX_HOST") || "admin.hex-hub.dev"
  port = String.to_integer(System.get_env("ADMIN_PORT") || "4001")

  config :hex_hub, HexHubAdminWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  config :hex_hub,
    storage_type: :local,
    storage_path: System.get_env("STORAGE_PATH", "priv/storage"),
    mnesia_dir: System.get_env("MNESIA_DIR", "mnesia")
end

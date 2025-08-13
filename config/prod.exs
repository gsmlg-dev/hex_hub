import Config

config :hex_hub, HexHubWeb.Endpoint, cache_static_manifest: "priv/static/cache_manifest.json"
config :hex_hub, HexHubAdminWeb.Endpoint, cache_static_manifest: "priv/static/cache_manifest.json"

# Configures Swoosh API Client
config :swoosh, api_client: Swoosh.ApiClient.Req

# Disable Swoosh Local Memory Storage
config :swoosh, local: false

# Do not print debug messages in production
config :logger, level: :info

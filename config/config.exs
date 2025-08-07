import Config

config :hex_hub,
  generators: [timestamp_type: :utc_datetime]

config :hex_hub, HexHubWeb.Endpoint,
  server: true,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: HexHubWeb.ErrorHTML, json: HexHubWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: HexHub.PubSub,
  live_view: [signing_salt: "y6PnerOV"]

config :hex_hub, HexHub.Mailer, adapter: Swoosh.Adapters.Local

config :bun,
  version: "1.2.16",
  hex_hub: [
    args: ~w(build assets/js/app.js --outdir=priv/static/assets),
    cd: Path.expand("..", __DIR__),
    env: %{"NODE_PATH" => "#{Path.expand("../deps", __DIR__)}"}
  ]

config :tailwind,
  version: "4.1.7",
  hex_hub: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"

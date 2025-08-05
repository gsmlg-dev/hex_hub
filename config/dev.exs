import Config

config :hex_hub, HexHubWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT") || "4000")],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "SKnshuH0YE4iQNwz3qDeTKhOSwsnZV6W2h0PFf6prJjLQMQ3Ht+P4J4SoF0VGAHB",
  watchers: [
    bun: {Bun, :install_and_run, [:hex_hub, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:hex_hub, ~w(--watch)]}
  ]

config :hex_hub, HexHubWeb.Endpoint,
  live_reload: [
    web_console_logger: true,
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/hex_hub_web/(?:controllers|live|components|router)/?.*\.(ex|heex)$"
    ]
  ]

config :hex_hub, dev_routes: true

config :logger, :default_formatter, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20

config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  debug_heex_annotations: true,
  debug_tags_location: true,
  enable_expensive_runtime_checks: true

config :swoosh, :api_client, false

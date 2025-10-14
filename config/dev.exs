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

config :hex_hub, HexHubAdminWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("ADMIN_PORT") || "4001")],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "SKnshuH0YE4iQNwz3qDeTKhOSwsnZV6W2h0PFf6prJjLQMQ3Ht+P4J4SoF0VGAHB",
  watchers: [
    bun: {Bun, :install_and_run, [:hex_hub_admin, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:hex_hub_admin, ~w(--watch)]}
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

config :hex_hub, HexHubAdminWeb.Endpoint,
  live_reload: [
    web_console_logger: true,
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/hex_hub_admin_web/(?:controllers|live|components|router)/?.*\.(ex|heex)$"
    ]
  ]

config :hex_hub, dev_routes: true

config :hex_hub,
  storage_type: :local,
  storage_path: "priv/storage",
  s3_bucket: System.get_env("S3_BUCKET"),
  s3_region: System.get_env("AWS_REGION", "us-east-1")

# S3 Configuration for development
config :ex_aws,
  access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
  secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY"),
  region: System.get_env("AWS_REGION", "us-east-1")

config :ex_aws, :s3,
  scheme: System.get_env("AWS_S3_SCHEME", "https://"),
  host: System.get_env("AWS_S3_HOST"),
  port: if(port = System.get_env("AWS_S3_PORT"), do: String.to_integer(port), else: 443),
  path_style: System.get_env("AWS_S3_PATH_STYLE", "false") == "true"

config :logger, :default_formatter, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20

config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  debug_heex_annotations: true,
  debug_tags_location: true,
  enable_expensive_runtime_checks: true

config :swoosh, :api_client, false

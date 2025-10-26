defmodule HexHubWeb.Router do
  use HexHubWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {HexHubWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :api_cached do
    plug :accepts, ["json"]
    plug HexHubWeb.Plugs.ETag
  end

  pipeline :api_auth do
    plug :accepts, ["json"]
    plug HexHubWeb.Plugs.Authenticate
    plug HexHubWeb.Plugs.RateLimit
  end

  pipeline :require_write do
    plug HexHubWeb.Plugs.Authorize, "write"
  end

  # API routes at root level for HEX_MIRROR compatibility (no /api prefix)
  # These must come before browser routes to avoid conflicts
  scope "/", HexHubWeb.API do
    pipe_through :api_cached

    # Public endpoints for Mix/HEX_MIRROR support (with caching)
    get "/packages", PackageController, :list
    get "/packages/:name", PackageController, :show
    get "/packages/:name/releases/:version", ReleaseController, :show
    get "/repos", RepositoryController, :list
    get "/repos/:name", RepositoryController, :show

    # Download endpoints (public, with upstream fallback)
    get "/packages/:name/releases/:version/download", DownloadController, :package
    get "/packages/:name/releases/:version/docs/download", DownloadController, :docs
    # Tarballs endpoint for Mix compatibility (HEX_MIRROR support)
    get "/tarballs/:tarball", DownloadController, :tarball
    # Installs endpoint for Mix dependency resolution
    get "/installs/:elixir_version/:requirements", PackageController, :installs
  end

  scope "/", HexHubWeb.API do
    pipe_through :api

    # Non-cached endpoints
    post "/users", UserController, :create
    get "/users/:username_or_email", UserController, :show
  end

  scope "/", HexHubWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/browse", PackageController, :index
    get "/package/:name", PackageController, :show
    get "/package/:name/docs", PackageController, :docs
  end

  # Health check endpoints for monitoring
  scope "/health", HexHubWeb do
    pipe_through :api

    get "/", HealthController, :index
    get "/ready", HealthController, :readiness
    get "/live", HealthController, :liveness
  end

  # Cluster management endpoints
  scope "/api", HexHubWeb do
    pipe_through :api

    get "/cluster/status", ClusterController, :status
    post "/cluster/join", ClusterController, :join
    post "/cluster/leave", ClusterController, :leave
  end

  # MCP (Model Context Protocol) endpoints
  # Routes are always defined, but controllers check if MCP is enabled at runtime
  scope "/mcp", HexHubWeb do
    pipe_through :api

    # MCP HTTP endpoints
    post "/", MCPController, :handle_request
    get "/tools", MCPController, :list_tools
    get "/server-info", MCPController, :server_info
    get "/health", MCPController, :health
  end

  # MCP WebSocket endpoint
  scope "/" do
    pipe_through :api

    # Commented out WebSocket for now - needs proper Phoenix.Socket setup
    # if function_exported?(Phoenix.Endpoint, :socket, 3) do
    #   socket "/mcp/ws", HexHub.MCP.WebSocket,
    #     websocket: [
    #       connect_info: [:req_headers, :query_params, :peer_data],
    #       timeout: 60_000
    #     ]
    # end
  end

  # API routes matching hex-api.yaml specification (with /api prefix)
  scope "/api", HexHubWeb.API do
    pipe_through :api_cached

    # Public endpoints (with caching)
    get "/packages", PackageController, :list
    get "/packages/:name", PackageController, :show
    get "/packages/:name/releases/:version", ReleaseController, :show
    get "/repos", RepositoryController, :list
    get "/repos/:name", RepositoryController, :show

    # Search endpoints
    get "/packages/search", SearchController, :search
    get "/packages/suggest", SearchController, :suggest
    get "/packages/search/by/:field", SearchController, :search_by_field

    # Download endpoints (public, with upstream fallback)
    get "/packages/:name/releases/:version/download", DownloadController, :package
    get "/packages/:name/releases/:version/docs/download", DownloadController, :docs
    # Tarballs endpoint for Mix compatibility (HEX_MIRROR support)
    get "/tarballs/:tarball", DownloadController, :tarball
    # Installs endpoint for Mix dependency resolution
    get "/installs/:elixir_version/:requirements", PackageController, :installs
  end

  scope "/api", HexHubWeb.API do
    pipe_through :api

    # Non-cached endpoints
    post "/users", UserController, :create
    get "/users/:username_or_email", UserController, :show
  end

  # Authenticated API routes
  scope "/api", HexHubWeb.API do
    pipe_through [:api_auth]

    # Authenticated users endpoints
    get "/users/me", UserController, :me
    post "/users/:username_or_email/reset", UserController, :reset

    # Authenticated package management (read operations)
    get "/packages/:name/owners", OwnerController, :index

    # API Keys endpoints (read operations)
    get "/keys", KeyController, :list
    get "/keys/:name", KeyController, :show

    # Two-Factor Authentication endpoints
    get "/auth/totp", TwoFactorController, :setup
    post "/auth/totp", TwoFactorController, :enable
    delete "/auth/totp", TwoFactorController, :disable
    post "/auth/totp/verify", TwoFactorController, :verify
    post "/auth/totp/recovery", TwoFactorController, :verify_recovery
    post "/auth/totp/recovery/regenerate", TwoFactorController, :regenerate_recovery_codes

    # Retirement info endpoints (read operations)
    get "/packages/:name/releases/:version/retire", RetirementController, :show
    get "/packages/:name/retired", RetirementController, :index
  end

  # Authenticated API routes requiring write permissions
  scope "/api", HexHubWeb.API do
    pipe_through [:api_auth, :require_write]

    # Authenticated package management (write operations)
    post "/publish", ReleaseController, :publish
    post "/packages/:name/releases/:version/retire", RetirementController, :retire
    delete "/packages/:name/releases/:version/retire", RetirementController, :unretire

    # Authenticated documentation endpoints (write operations)
    post "/packages/:name/releases/:version/docs", DocsController, :publish
    delete "/packages/:name/releases/:version/docs", DocsController, :delete

    # Authenticated ownership endpoints (write operations)
    put "/packages/:name/owners/:email", OwnerController, :add
    delete "/packages/:name/owners/:email", OwnerController, :remove

    # API Keys endpoints (write operations)
    post "/keys", KeyController, :create
    delete "/keys/:name", KeyController, :delete

    # Admin endpoints
    post "/packages/search/reindex", SearchController, :reindex
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:hex_hub, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: HexHubWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end

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

  scope "/", HexHubWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # API routes matching hex-api.yaml specification
  scope "/api", HexHubWeb.API do
    pipe_through :api

    # Users endpoints
    post "/users", UserController, :create
    get "/users/:username_or_email", UserController, :show
    get "/users/me", UserController, :me
    post "/users/:username_or_email/reset", UserController, :reset

    # Repositories endpoints
    get "/repos", RepositoryController, :list
    get "/repos/:name", RepositoryController, :show

    # Packages endpoints
    get "/packages", PackageController, :list
    get "/packages/:name", PackageController, :show

    # Package releases endpoints
    get "/packages/:name/releases/:version", ReleaseController, :show
    post "/publish", ReleaseController, :publish
    post "/packages/:name/releases/:version/retire", ReleaseController, :retire
    delete "/packages/:name/releases/:version/retire", ReleaseController, :unretire

    # Package documentation endpoints
    post "/packages/:name/releases/:version/docs", DocsController, :publish
    delete "/packages/:name/releases/:version/docs", DocsController, :delete

    # Package ownership endpoints
    get "/packages/:name/owners", OwnerController, :index
    put "/packages/:name/owners/:email", OwnerController, :add
    delete "/packages/:name/owners/:email", OwnerController, :remove

    # API Keys endpoints
    get "/keys", KeyController, :list
    post "/keys", KeyController, :create
    get "/keys/:name", KeyController, :show
    delete "/keys/:name", KeyController, :delete
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

defmodule HexHubAdminWeb.Router do
  use HexHubAdminWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {HexHubAdminWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Admin dashboard routes
  scope "/", HexHubAdminWeb do
    pipe_through :browser

    get "/", AdminController, :dashboard
    get "/repositories", AdminController, :repositories
    get "/repositories/new", AdminController, :new_repository
    post "/repositories", AdminController, :create_repository
    get "/repositories/:name/edit", AdminController, :edit_repository
    put "/repositories/:name", AdminController, :update_repository
    delete "/repositories/:name", AdminController, :delete_repository
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:hex_hub, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: HexHubAdminWeb.Telemetry
    end
  end
end

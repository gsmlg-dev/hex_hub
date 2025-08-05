defmodule HexHubWeb.PageController do
  use HexHubWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end

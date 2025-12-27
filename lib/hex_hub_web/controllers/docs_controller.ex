defmodule HexHubWeb.DocsController do
  @moduledoc """
  Controller for documentation pages.

  Handles rendering of Getting Started, Publishing, and API Reference documentation.
  """
  use HexHubWeb, :controller

  def index(conn, _params) do
    emit_page_view_telemetry(:index)
    render(conn, :index, page_title: "Documentation", current_page: :index)
  end

  def getting_started(conn, _params) do
    emit_page_view_telemetry(:getting_started)

    render(conn, :getting_started,
      page_title: "Getting Started",
      current_page: :getting_started,
      hex_hub_url: HexHubWeb.PageHTML.hex_hub_url(conn)
    )
  end

  def publishing(conn, _params) do
    emit_page_view_telemetry(:publishing)

    render(conn, :publishing,
      page_title: "Publishing Packages",
      current_page: :publishing,
      hex_hub_api_url: HexHubWeb.PageHTML.hex_hub_api_url(conn)
    )
  end

  def api_reference(conn, _params) do
    emit_page_view_telemetry(:api_reference)

    render(conn, :api_reference,
      page_title: "API Reference",
      current_page: :api_reference,
      endpoints_by_tag: HexHubWeb.DocsHTML.paths_by_tag(),
      api_info: HexHubWeb.DocsHTML.api_info()
    )
  end

  # Emit telemetry event for documentation page views (Constitution Principle VII)
  defp emit_page_view_telemetry(page) do
    :telemetry.execute(
      [:hex_hub, :docs, :page_view],
      %{count: 1},
      %{page: page}
    )
  end
end

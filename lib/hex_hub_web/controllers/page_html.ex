defmodule HexHubWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use HexHubWeb, :html

  embed_templates "page_html/*"

  @doc """
  Returns the base URL for the HexHub service based on endpoint configuration.
  """
  def hex_hub_url(conn) do
    scheme = if conn.scheme == :https, do: "https", else: "http"
    port = if conn.port in [80, 443], do: "", else: ":#{conn.port}"
    host = conn.host

    "#{scheme}://#{host}#{port}"
  end
end

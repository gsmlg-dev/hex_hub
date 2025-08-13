defmodule HexHubWeb.PackageHTML do
  use HexHubWeb, :html

  embed_templates "package_html/*"

  def format_date(datetime) do
    datetime
    |> NaiveDateTime.to_date()
    |> Date.to_string()
  end

  def format_description(description) do
    if String.length(description) > 120 do
      String.slice(description, 0, 117) <> "..."
    else
      description
    end
  end

  def pagination_link(_conn, page, search, text) do
    query_params = %{page: page}
    query_params = if search, do: Map.put(query_params, :search, search), else: query_params

    path = "/packages?" <> URI.encode_query(query_params)
    "<a href=\"#{path}\" class=\"btn btn-sm\">#{text}</a>"
  end

  def package_badge(%{latest_version: version}) do
    "<span class=\"badge badge-primary badge-sm\">v#{version}</span>"
  end

  def download_count_badge(count) do
    formatted_count =
      cond do
        count >= 1_000_000 -> "#{Float.round(count / 1_000_000, 1)}M"
        count >= 1_000 -> "#{Float.round(count / 1_000, 1)}K"
        true -> to_string(count)
      end

    "<span class=\"badge badge-ghost badge-sm\">📥 #{formatted_count}</span>"
  end
end

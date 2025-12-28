defmodule HexHubAdminWeb.PackageHTML do
  use HexHubAdminWeb, :html

  embed_templates "package_html/*"

  @doc """
  Returns the badge class for package status.
  """
  def status_badge_class(:active), do: "badge badge-success"
  def status_badge_class(:shadowed), do: "badge badge-warning"
  def status_badge_class(_), do: "badge badge-ghost"

  @doc """
  Builds query parameters for search pagination.
  """
  def build_query_params(query, source_filter, page) do
    params = [page: page]
    params = if source_filter != "all", do: [{:source, source_filter} | params], else: params
    params = if query != "", do: [{:q, query} | params], else: params
    URI.encode_query(params)
  end
end

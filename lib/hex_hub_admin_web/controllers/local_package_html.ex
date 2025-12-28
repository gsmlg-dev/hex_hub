defmodule HexHubAdminWeb.LocalPackageHTML do
  use HexHubAdminWeb, :html

  embed_templates "local_package_html/*"

  @doc """
  Formats a timestamp (integer Unix time or DateTime) to a readable string.
  """
  def format_timestamp(timestamp) when is_integer(timestamp) do
    timestamp
    |> DateTime.from_unix!()
    |> Calendar.strftime("%Y-%m-%d %H:%M")
  end

  def format_timestamp(%DateTime{} = dt) do
    Calendar.strftime(dt, "%Y-%m-%d %H:%M")
  end

  def format_timestamp(_), do: "Unknown"

  @doc """
  Builds query parameters for pagination links.
  """
  def build_query_params(search, sort, sort_dir, page) do
    params = [page: page, sort: sort, sort_dir: sort_dir]
    params = if search != "", do: [{:search, search} | params], else: params
    URI.encode_query(params)
  end
end

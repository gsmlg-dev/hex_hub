defmodule HexHubWeb.API.SearchController do
  use HexHubWeb, :controller

  alias HexHub.PackageSearch
  alias HexHubWeb.Plugs.ETag

  @doc """
  GET /api/packages/search
  Search for packages by query.
  """
  def search(conn, params) do
    query = params["q"] || params["query"] || ""

    # Parse search options
    opts = [
      limit: parse_int(params["limit"], 20),
      offset: parse_int(params["offset"], 0),
      include_deprecated: params["include_deprecated"] == "true"
    ]

    {:ok, results} = PackageSearch.search(query, opts)

    # Generate ETag for search results
    etag = ETag.generate_etag(Jason.encode!(results))

    conn
    |> ETag.set_etag(etag)
    |> json(%{
      query: query,
      total: length(results),
      packages: results
    })
  end

  @doc """
  GET /api/packages/suggest
  Get search suggestions for autocomplete.
  """
  def suggest(conn, %{"q" => query}) do
    opts = [
      limit: parse_int(conn.params["limit"], 10)
    ]

    suggestions = PackageSearch.suggest(query, opts)

    json(conn, %{
      query: query,
      suggestions: suggestions
    })
  end

  def suggest(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Missing query parameter 'q'"})
  end

  @doc """
  GET /api/packages/search/by/:field
  Search packages by specific field.
  """
  def search_by_field(conn, %{"field" => field, "q" => query}) do
    field_atom = try do
      String.to_existing_atom(field)
    rescue
      ArgumentError -> :name
    end

    opts = [
      limit: parse_int(conn.params["limit"], 20)
    ]

    case PackageSearch.search_by_field(query, field_atom, opts) do
      {:ok, results} ->
        json(conn, %{
          field: field,
          query: query,
          total: length(results),
          packages: results
        })

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: reason})
    end
  end

  def search_by_field(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Missing required parameters"})
  end

  @doc """
  POST /api/packages/search/reindex
  Rebuild the search index (admin only).
  """
  def reindex(conn, _params) do
    # Check if user is admin or service account
    unless is_admin?(conn) do
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Admin access required"})
    else
      case PackageSearch.rebuild_index() do
        {:ok, count} ->
          # Invalidate registry cache after reindexing
          HexHubWeb.Plugs.RegistryCache.increment_registry_version()

          json(conn, %{
            message: "Search index rebuilt successfully",
            packages_indexed: count
          })

        {:error, reason} ->
          conn
          |> put_status(:internal_server_error)
          |> json(%{error: reason})
      end
    end
  end

  # Private functions

  defp parse_int(nil, default), do: default
  defp parse_int(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> default
    end
  end
  defp parse_int(value, _default) when is_integer(value), do: value
  defp parse_int(_value, default), do: default

  defp is_admin?(conn) do
    case conn.assigns[:current_user] do
      %{username: username} ->
        # Check if user is admin or service account
        HexHub.Users.is_service_account?(username) ||
        username in ["admin", "root"]  # Add your admin usernames

      _ ->
        false
    end
  end
end
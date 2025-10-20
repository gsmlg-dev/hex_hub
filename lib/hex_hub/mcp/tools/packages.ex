defmodule HexHub.MCP.Tools.Packages do
  @moduledoc """
  MCP tools for package search and information retrieval.

  Provides tools for searching packages, getting package details,
  listing packages, and accessing package metadata.
  """

  require Logger

  alias HexHub.{Packages, Repositories}
  alias HexHub.MCP.Schemas

  @doc """
  Search for packages by name, description, or metadata.
  """
  def search_packages(%{"query" => query} = args) do
    limit = Map.get(args, "limit", 20)
    filters = Map.get(args, "filters", %{})

    Logger.debug("MCP searching packages with query: #{query}")

    case Packages.search_packages(query, [limit: limit] ++ build_search_opts(filters)) do
      {:ok, packages} ->
        result = %{
          packages: Enum.map(packages, &format_package/1),
          total: length(packages),
          query: query,
          filters: filters
        }
        {:ok, result}

      {:error, reason} ->
        Logger.error("MCP package search failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def search_packages(_args) do
    {:error, :missing_query_parameter}
  end

  @doc """
  Get detailed information about a specific package.
  """
  def get_package(%{"name" => name} = args) do
    repository = Map.get(args, "repository")

    Logger.debug("MCP getting package info for: #{name}")

    case Packages.get_package(name, repository) do
      {:ok, package} ->
        # Get additional metadata
        releases = Packages.list_releases(name)
        formatted_package = format_package(package)
        formatted_releases = Enum.map(releases, &format_release/1)

        result = %{
          package: formatted_package,
          releases: formatted_releases,
          total_releases: length(releases),
          latest_version: get_latest_version(releases),
          repository: get_repository_info(package.repository)
        }

        {:ok, result}

      {:error, reason} ->
        Logger.error("MCP get package failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def get_package(_args) do
    {:error, :missing_package_name}
  end

  @doc """
  List packages with pagination and optional filtering.
  """
  def list_packages(args \\ %{}) do
    page = Map.get(args, "page", 1)
    per_page = Map.get(args, "per_page", 20)
    sort = Map.get(args, "sort", "name")
    order = Map.get(args, "order", "asc")

    Logger.debug("MCP listing packages: page=#{page}, per_page=#{per_page}")

    opts = [
      page: page,
      per_page: per_page,
      sort: String.to_atom(sort),
      order: String.to_atom(order)
    ]

    case Packages.list_packages(opts) do
      {:ok, packages} ->
        result = %{
          packages: Enum.map(packages, &format_package/1),
          pagination: %{
            page: page,
            per_page: per_page,
            total_packages: length(packages) # Would need actual count from database
          },
          sort: sort,
          order: order
        }

        {:ok, result}

      {:error, reason} ->
        Logger.error("MCP list packages failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Get package metadata including requirements and dependencies.
  """
  def get_package_metadata(%{"name" => name} = args) do
    version = Map.get(args, "version")

    Logger.debug("MCP getting package metadata for: #{name}#{if version, do: " v#{version}"}")

    case Packages.get_release(name, version) do
      {:ok, release} ->
        metadata = Jason.decode!(release.metadata || "{}")

        result = %{
          name: name,
          version: release.version,
          metadata: metadata,
          requirements: parse_requirements(release.requirements),
          has_docs: release.has_docs,
          retirement_info: get_retirement_info(release)
        }

        {:ok, result}

      {:error, reason} ->
        Logger.error("MCP get package metadata failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def get_package_metadata(_args) do
    {:error, :missing_package_name}
  end

  # Private helper functions

  defp build_search_opts(filters) when is_map(filters) do
    Enum.reduce(filters, [], fn {key, value}, acc ->
      case key do
        "repository" -> [{:repository, value} | acc]
        "license" -> [{:license, value} | acc]
        "elixir_version" -> [{:elixir_version, value} | acc]
        "downloads_min" -> [{:downloads_min, String.to_integer(value)} | acc]
        "private" -> [{:private, String.to_existing_atom(value)} | acc]
        _ -> acc
      end
    end)
  end

  defp build_search_opts(_), do: []

  defp format_package(package) do
    %{
      name: package.name,
      repository: package.repository,
      description: get_meta_field(package.meta, "description"),
      licenses: get_meta_field(package.meta, "licenses", []),
      links: get_meta_field(package.meta, "links", %{}),
      downloads: package.downloads,
      inserted_at: package.inserted_at,
      updated_at: package.updated_at,
      url: build_package_url(package),
      html_url: build_package_html_url(package)
    }
  end

  defp format_release(release) do
    %{
      version: release.version,
      has_docs: release.has_docs,
      inserted_at: release.inserted_at,
      retirement_info: get_retirement_info(release),
      url: build_release_url(release),
      html_url: build_release_html_url(release)
    }
  end

  defp get_meta_field(meta, field, default \\ nil) do
    case Jason.decode(meta || "{}") do
      {:ok, decoded} -> Map.get(decoded, field, default)
      {:error, _} -> default
    end
  end

  defp get_latest_version([]), do: nil
  defp get_latest_version(releases) do
    releases
    |> Enum.map(& &1.version)
    |> Enum.sort_by(&Version.compare/2, :desc)
    |> List.first()
  end

  defp get_repository_info(repository_name) do
    case Repositories.get_repository(repository_name) do
      {:ok, repo} ->
        %{
          name: repo.name,
          url: repo.url,
          public: repo.public
        }
      {:error, _} ->
        %{
          name: repository_name,
          url: nil,
          public: true
        }
    end
  end

  defp parse_requirements(nil), do: %{}
  defp parse_requirements(requirements) do
    case Jason.decode(requirements || "{}") do
      {:ok, reqs} -> reqs
      {:error, _} -> %{}
    end
  end

  defp get_retirement_info(release) do
    case release.retirement do
      nil -> nil
      retirement ->
        %{
          reason: retirement.reason,
          message: retirement.message
        }
    end
  end

  # URL builders

  defp build_package_url(package) do
    "/api/packages/#{package.name}"
  end

  defp build_package_html_url(package) do
    "/packages/#{package.name}"
  end

  defp build_release_url(release) do
    "/api/packages/#{release.package_name}/releases/#{release.version}"
  end

  defp build_release_html_url(release) do
    "/packages/#{release.package_name}/releases/#{release.version}"
  end

  @doc """
  Validate package search arguments.
  """
  def validate_search_args(args) do
    required_fields = ["query"]
    optional_fields = ["limit", "filters"]

    case validate_fields(args, required_fields, optional_fields) do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Validate get package arguments.
  """
  def validate_get_package_args(args) do
    required_fields = ["name"]
    optional_fields = ["repository"]

    case validate_fields(args, required_fields, optional_fields) do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Validate package metadata arguments.
  """
  def validate_metadata_args(args) do
    required_fields = ["name"]
    optional_fields = ["version"]

    case validate_fields(args, required_fields, optional_fields) do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  # Generic field validation

  defp validate_fields(args, required, optional) do
    # Check required fields
    missing_required = Enum.filter(required, fn field ->
      not Map.has_key?(args, field) or is_nil(Map.get(args, field))
    end)

    if length(missing_required) > 0 do
      {:error, {:missing_required_fields, missing_required}}
    else
      # Check for unknown fields
      known_fields = required ++ optional
      unknown_fields = Enum.filter(Map.keys(args), fn field ->
        field not in known_fields
      end)

      if length(unknown_fields) > 0 do
        Logger.warn("Unknown fields in args: #{inspect(unknown_fields)}")
        # Don't error on unknown fields, just warn
      end

      :ok
    end
  end

  @doc """
  Get package statistics for monitoring.
  """
  def get_package_stats do
    # This would query the database for package statistics
    %{
      total_packages: get_total_packages_count(),
      total_releases: get_total_releases_count(),
      total_downloads: get_total_downloads(),
      recent_packages: get_recent_packages_count(),
      packages_with_docs: get_packages_with_docs_count()
    }
  end

  defp get_total_packages_count do
    # Query database for total package count
    :mnesia.table_info(:packages, :size)
  end

  defp get_total_releases_count do
    # Query database for total release count
    :mnesia.table_info(:package_releases, :size)
  end

  defp get_total_downloads do
    # Query database for total downloads
    # This would need to sum downloads across all packages
    0
  end

  defp get_recent_packages_count do
    # Count packages added in the last 30 days
    # This would require a more complex query
    0
  end

  defp get_packages_with_docs_count do
    # Count packages that have documentation
    # This would require joining packages and releases
    0
  end

  @doc """
  Log package operation for telemetry.
  """
  def log_package_operation(operation, package_name, metadata \\ %{}) do
    :telemetry.execute([:hex_hub, :mcp, :packages], %{
      operation: operation,
      package_name: package_name
    }, metadata)
  end
end
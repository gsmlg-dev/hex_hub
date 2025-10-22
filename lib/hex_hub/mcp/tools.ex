defmodule HexHub.MCP.Tools do
  @moduledoc """
  MCP Tools registration and management system.

  This module provides a centralized way to register and manage MCP tools
  that expose HexHub functionality to AI clients.
  """

  require Logger

  defstruct [:name, :description, :input_schema, :handler]

  @type t :: %__MODULE__{
          name: String.t(),
          description: String.t(),
          input_schema: map(),
          handler: (map(), map() -> {:ok, any()} | {:error, any()})
        }

  @doc """
  Register all available MCP tools.
  """
  def register_all_tools do
    tools = %{
      # Package management tools
      "search_packages" => register_tool("search_packages", &search_packages_handler/2),
      "get_package" => register_tool("get_package", &get_package_handler/2),
      "list_packages" => register_tool("list_packages", &list_packages_handler/2),
      "get_package_metadata" =>
        register_tool("get_package_metadata", &get_package_metadata_handler/2),

      # Release management tools
      "list_releases" => register_tool("list_releases", &list_releases_handler/2),
      "get_release" => register_tool("get_release", &get_release_handler/2),
      "download_release" => register_tool("download_release", &download_release_handler/2),
      "compare_releases" => register_tool("compare_releases", &compare_releases_handler/2),

      # Documentation tools
      "get_documentation" => register_tool("get_documentation", &get_documentation_handler/2),
      "list_documentation_versions" =>
        register_tool("list_documentation_versions", &list_documentation_versions_handler/2),
      "search_documentation" =>
        register_tool("search_documentation", &search_documentation_handler/2),

      # Dependency resolution tools
      "resolve_dependencies" =>
        register_tool("resolve_dependencies", &resolve_dependencies_handler/2),
      "get_dependency_tree" =>
        register_tool("get_dependency_tree", &get_dependency_tree_handler/2),
      "check_compatibility" =>
        register_tool("check_compatibility", &check_compatibility_handler/2),

      # Repository management tools
      "list_repositories" => register_tool("list_repositories", &list_repositories_handler/2),
      "get_repository_info" =>
        register_tool("get_repository_info", &get_repository_info_handler/2),
      "toggle_package_visibility" =>
        register_tool("toggle_package_visibility", &toggle_package_visibility_handler/2)
    }

    Logger.info("Registered #{map_size(tools)} MCP tools")
    tools
  end

  @doc """
  Register a single tool with its handler.
  """
  def register_tool(name, handler_fn) do
    {description, schema} = get_tool_spec(name)

    %__MODULE__{
      name: name,
      description: description,
      input_schema: schema,
      handler: handler_fn
    }
  end

  # Tool specifications and handlers

  defp get_tool_spec("search_packages") do
    {
      "Search for packages by name, description, or metadata",
      HexHub.MCP.Schemas.build_tool_schema(
        query: [type: :string, required: true, description: "Search query"],
        limit: [type: :integer, required: false, description: "Maximum number of results"],
        filters: [type: :object, required: false, description: "Additional filters"]
      )
    }
  end

  defp get_tool_spec("get_package") do
    {
      "Get detailed information about a specific package",
      HexHub.MCP.Schemas.build_tool_schema(
        name: [type: :string, required: true, description: "Package name"],
        repository: [type: :string, required: false, description: "Repository name"]
      )
    }
  end

  defp get_tool_spec("list_packages") do
    {
      "List packages with pagination and optional filtering",
      HexHub.MCP.Schemas.build_tool_schema(
        page: [type: :integer, required: false, description: "Page number"],
        per_page: [type: :integer, required: false, description: "Items per page"],
        sort: [type: :string, required: false, description: "Sort field"],
        order: [type: :string, required: false, description: "Sort order (asc/desc)"]
      )
    }
  end

  defp get_tool_spec("get_package_metadata") do
    {
      "Get package metadata including requirements and dependencies",
      HexHub.MCP.Schemas.build_tool_schema(
        name: [type: :string, required: true, description: "Package name"],
        version: [type: :string, required: false, description: "Specific version"]
      )
    }
  end

  defp get_tool_spec("list_releases") do
    {
      "List all releases/versions for a package",
      HexHub.MCP.Schemas.build_tool_schema(
        name: [type: :string, required: true, description: "Package name"],
        include_retired: [
          type: :boolean,
          required: false,
          description: "Include retired versions"
        ]
      )
    }
  end

  defp get_tool_spec("get_release") do
    {
      "Get detailed information about a specific package release",
      HexHub.MCP.Schemas.build_tool_schema(
        name: [type: :string, required: true, description: "Package name"],
        version: [type: :string, required: true, description: "Package version"]
      )
    }
  end

  defp get_tool_spec("download_release") do
    {
      "Download a package release tarball",
      HexHub.MCP.Schemas.build_tool_schema(
        name: [type: :string, required: true, description: "Package name"],
        version: [type: :string, required: true, description: "Package version"]
      )
    }
  end

  defp get_tool_spec("compare_releases") do
    {
      "Compare two different releases of a package",
      HexHub.MCP.Schemas.build_tool_schema(
        name: [type: :string, required: true, description: "Package name"],
        version1: [type: :string, required: true, description: "First version"],
        version2: [type: :string, required: true, description: "Second version"]
      )
    }
  end

  defp get_tool_spec("get_documentation") do
    {
      "Get documentation for a package",
      HexHub.MCP.Schemas.build_tool_schema(
        name: [type: :string, required: true, description: "Package name"],
        version: [type: :string, required: false, description: "Package version"],
        page: [type: :string, required: false, description: "Specific documentation page"]
      )
    }
  end

  defp get_tool_spec("list_documentation_versions") do
    {
      "List available documentation versions for a package",
      HexHub.MCP.Schemas.build_tool_schema(
        name: [type: :string, required: true, description: "Package name"]
      )
    }
  end

  defp get_tool_spec("search_documentation") do
    {
      "Search within package documentation",
      HexHub.MCP.Schemas.build_tool_schema(
        name: [type: :string, required: true, description: "Package name"],
        query: [type: :string, required: true, description: "Search query"],
        version: [type: :string, required: false, description: "Package version"]
      )
    }
  end

  defp get_tool_spec("resolve_dependencies") do
    {
      "Resolve Mix-style dependencies for a project",
      HexHub.MCP.Schemas.build_tool_schema(
        requirements: [type: :object, required: true, description: "Dependency requirements"],
        elixir_version: [type: :string, required: false, description: "Target Elixir version"]
      )
    }
  end

  defp get_tool_spec("get_dependency_tree") do
    {
      "Build dependency tree for a package",
      HexHub.MCP.Schemas.build_tool_schema(
        name: [type: :string, required: true, description: "Package name"],
        version: [type: :string, required: true, description: "Package version"],
        depth: [type: :integer, required: false, description: "Maximum tree depth"]
      )
    }
  end

  defp get_tool_spec("check_compatibility") do
    {
      "Check version compatibility between packages",
      HexHub.MCP.Schemas.build_tool_schema(
        packages: [type: :array, required: true, description: "List of packages with versions"],
        elixir_version: [type: :string, required: false, description: "Target Elixir version"]
      )
    }
  end

  defp get_tool_spec("list_repositories") do
    {
      "List all available repositories",
      HexHub.MCP.Schemas.build_tool_schema(
        include_private: [
          type: :boolean,
          required: false,
          description: "Include private repositories"
        ]
      )
    }
  end

  defp get_tool_spec("get_repository_info") do
    {
      "Get detailed information about a repository",
      HexHub.MCP.Schemas.build_tool_schema(
        name: [type: :string, required: true, description: "Repository name"]
      )
    }
  end

  defp get_tool_spec("toggle_package_visibility") do
    {
      "Toggle package visibility between public and private",
      HexHub.MCP.Schemas.build_tool_schema(
        name: [type: :string, required: true, description: "Package name"],
        private: [type: :boolean, required: true, description: "Set as private"]
      )
    }
  end

  # Tool handlers (will be implemented in separate modules)

  defp search_packages_handler(args, _context),
    do: HexHub.MCP.Tools.Packages.search_packages(args)

  defp get_package_handler(args, _context), do: HexHub.MCP.Tools.Packages.get_package(args)
  defp list_packages_handler(args, _context), do: HexHub.MCP.Tools.Packages.list_packages(args)

  defp get_package_metadata_handler(args, _context),
    do: HexHub.MCP.Tools.Packages.get_package_metadata(args)

  defp list_releases_handler(args, _context), do: HexHub.MCP.Tools.Releases.list_releases(args)
  defp get_release_handler(args, _context), do: HexHub.MCP.Tools.Releases.get_release(args)

  defp download_release_handler(args, _context),
    do: HexHub.MCP.Tools.Releases.download_release(args)

  defp compare_releases_handler(args, _context),
    do: HexHub.MCP.Tools.Releases.compare_releases(args)

  defp get_documentation_handler(args, _context),
    do: HexHub.MCP.Tools.Documentation.get_documentation(args)

  defp list_documentation_versions_handler(args, _context),
    do: HexHub.MCP.Tools.Documentation.list_documentation_versions(args)

  defp search_documentation_handler(args, _context),
    do: HexHub.MCP.Tools.Documentation.search_documentation(args)

  defp resolve_dependencies_handler(args, _context),
    do: HexHub.MCP.Tools.Dependencies.resolve_dependencies(args)

  defp get_dependency_tree_handler(args, _context),
    do: HexHub.MCP.Tools.Dependencies.get_dependency_tree(args)

  defp check_compatibility_handler(args, _context),
    do: HexHub.MCP.Tools.Dependencies.check_compatibility(args)

  defp list_repositories_handler(args, _context),
    do: HexHub.MCP.Tools.Repositories.list_repositories(args)

  defp get_repository_info_handler(args, _context),
    do: HexHub.MCP.Tools.Repositories.get_repository_info(args)

  defp toggle_package_visibility_handler(args, _context),
    do: HexHub.MCP.Tools.Repositories.toggle_package_visibility(args)
end

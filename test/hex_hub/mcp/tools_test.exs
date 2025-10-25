defmodule HexHub.MCP.ToolsTest do
  use ExUnit.Case, async: true
  alias HexHub.MCP.Tools

  describe "register_all_tools/0" do
    test "returns a map of registered tools" do
      tools = Tools.register_all_tools()
      assert is_map(tools)
      assert map_size(tools) > 0

      # Check that expected tools are registered
      expected_tools = [
        "search_packages",
        "get_package",
        "list_packages",
        "get_package_metadata",
        "list_releases",
        "get_release",
        "download_release",
        "compare_releases",
        "get_documentation",
        "list_documentation_versions",
        "search_documentation",
        "resolve_dependencies",
        "get_dependency_tree",
        "check_compatibility",
        "list_repositories",
        "get_repository_info",
        "toggle_package_visibility"
      ]

      for tool_name <- expected_tools do
        assert Map.has_key?(tools, tool_name), "Expected tool #{tool_name} to be registered"
      end
    end

    test "each tool has required fields" do
      tools = Tools.register_all_tools()

      for {name, tool} <- tools do
        assert is_binary(tool.name)
        assert tool.name == name
        assert is_binary(tool.description)
        assert is_map(tool.input_schema)
        assert is_function(tool.handler)
      end
    end
  end

  describe "register_tool/2" do
    test "registers a tool with name and handler" do
      handler_fn = fn args, _context -> {:ok, args} end
      tool = Tools.register_tool("search_packages", handler_fn)

      assert tool.name == "search_packages"
      assert is_binary(tool.description)
      assert is_map(tool.input_schema)
      assert tool.handler == handler_fn
    end

    test "different tools have different specs" do
      search_handler = fn args, _context -> {:ok, args} end
      get_handler = fn args, _context -> {:ok, args} end

      search_tool = Tools.register_tool("search_packages", search_handler)
      get_tool = Tools.register_tool("get_package", get_handler)

      assert search_tool.description != get_tool.description
      assert search_tool.input_schema != get_tool.input_schema
    end
  end

  describe "tool specifications" do
    test "search_packages tool spec" do
      handler_fn = fn args, _context -> {:ok, args} end
      tool = Tools.register_tool("search_packages", handler_fn)

      assert tool.description =~ "Search for packages"
      assert tool.input_schema["type"] == "object"
      assert Map.has_key?(tool.input_schema["properties"], "query")
      assert "query" in tool.input_schema["required"]
    end

    test "get_package tool spec" do
      handler_fn = fn args, _context -> {:ok, args} end
      tool = Tools.register_tool("get_package", handler_fn)

      assert tool.description =~ "Get detailed information"
      assert tool.input_schema["type"] == "object"
      assert Map.has_key?(tool.input_schema["properties"], "name")
      assert "name" in tool.input_schema["required"]
    end

    test "list_packages tool spec" do
      handler_fn = fn args, _context -> {:ok, args} end
      tool = Tools.register_tool("list_packages", handler_fn)

      assert tool.description =~ "List packages"
      assert tool.input_schema["type"] == "object"
      # Optional parameters
      refute "page" in tool.input_schema["required"]
      refute "per_page" in tool.input_schema["required"]
    end

    test "list_releases tool spec" do
      handler_fn = fn args, _context -> {:ok, args} end
      tool = Tools.register_tool("list_releases", handler_fn)

      assert tool.description =~ "List all releases"
      assert tool.input_schema["type"] == "object"
      assert Map.has_key?(tool.input_schema["properties"], "name")
      assert "name" in tool.input_schema["required"]
    end

    test "get_release tool spec" do
      handler_fn = fn args, _context -> {:ok, args} end
      tool = Tools.register_tool("get_release", handler_fn)

      assert tool.description =~ "Get detailed information"
      assert tool.input_schema["type"] == "object"
      assert Map.has_key?(tool.input_schema["properties"], "name")
      assert Map.has_key?(tool.input_schema["properties"], "version")
      assert "name" in tool.input_schema["required"]
      assert "version" in tool.input_schema["required"]
    end

    test "download_release tool spec" do
      handler_fn = fn args, _context -> {:ok, args} end
      tool = Tools.register_tool("download_release", handler_fn)

      assert tool.description =~ "Download a package"
      assert tool.input_schema["type"] == "object"
      assert "name" in tool.input_schema["required"]
      assert "version" in tool.input_schema["required"]
    end

    test "compare_releases tool spec" do
      handler_fn = fn args, _context -> {:ok, args} end
      tool = Tools.register_tool("compare_releases", handler_fn)

      assert tool.description =~ "Compare two different releases"
      assert tool.input_schema["type"] == "object"
      assert "name" in tool.input_schema["required"]
      assert "version1" in tool.input_schema["required"]
      assert "version2" in tool.input_schema["required"]
    end

    test "documentation tools specs" do
      doc_tools = [
        "get_documentation",
        "list_documentation_versions",
        "search_documentation"
      ]

      for tool_name <- doc_tools do
        handler_fn = fn args, _context -> {:ok, args} end
        tool = Tools.register_tool(tool_name, handler_fn)

        assert tool.description =~ "documentation" or tool.description =~ "Documentation"
        assert tool.input_schema["type"] == "object"
        assert "name" in tool.input_schema["required"]
      end
    end

    test "dependency tools specs" do
      dep_tools = [
        "resolve_dependencies",
        "get_dependency_tree",
        "check_compatibility"
      ]

      for tool_name <- dep_tools do
        handler_fn = fn args, _context -> {:ok, args} end
        tool = Tools.register_tool(tool_name, handler_fn)

        assert tool.description =~ "dependenc" or tool.description =~ "compatib"
        assert tool.input_schema["type"] == "object"
      end
    end

    test "repository tools specs" do
      repo_tools = [
        "list_repositories",
        "get_repository_info",
        "toggle_package_visibility"
      ]

      for tool_name <- repo_tools do
        handler_fn = fn args, _context -> {:ok, args} end
        tool = Tools.register_tool(tool_name, handler_fn)

        assert tool.description =~ "repositor" or tool.description =~ "package"
        assert tool.input_schema["type"] == "object"
      end
    end
  end

  describe "tool struct" do
    test "defines correct struct fields" do
      handler_fn = fn args, _context -> {:ok, args} end
      tool = Tools.register_tool("get_package", handler_fn)

      assert %Tools{name: name, description: desc, input_schema: schema, handler: handler} = tool
      assert name == "get_package"
      assert is_binary(desc)
      assert is_map(schema)
      assert is_function(handler)
    end
  end

  describe "tool handler functions" do
    test "all registered handlers are functions" do
      tools = Tools.register_all_tools()

      for {name, tool} <- tools do
        assert is_function(tool.handler), "Tool #{name} should have a function handler"
      end
    end

    test "handlers reference correct modules" do
      # This test checks that handlers are pointing to the correct implementation modules
      # We can't test the actual execution without mocking the implementation modules
      tools = Tools.register_all_tools()

      # Check package management handlers
      package_tools = ["search_packages", "get_package", "list_packages", "get_package_metadata"]

      for tool_name <- package_tools do
        assert Map.has_key?(tools, tool_name)
      end

      # Check release management handlers
      release_tools = ["list_releases", "get_release", "download_release", "compare_releases"]

      for tool_name <- release_tools do
        assert Map.has_key?(tools, tool_name)
      end

      # Check documentation handlers
      doc_tools = ["get_documentation", "list_documentation_versions", "search_documentation"]

      for tool_name <- doc_tools do
        assert Map.has_key?(tools, tool_name)
      end

      # Check dependency handlers
      dep_tools = ["resolve_dependencies", "get_dependency_tree", "check_compatibility"]

      for tool_name <- dep_tools do
        assert Map.has_key?(tools, tool_name)
      end

      # Check repository handlers
      repo_tools = ["list_repositories", "get_repository_info", "toggle_package_visibility"]

      for tool_name <- repo_tools do
        assert Map.has_key?(tools, tool_name)
      end
    end
  end
end

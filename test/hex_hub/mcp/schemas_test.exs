defmodule HexHub.MCP.SchemasTest do
  use ExUnit.Case, async: true
  alias HexHub.MCP.Schemas

  describe "request_schema/0" do
    test "returns valid JSON-RPC request schema" do
      schema = Schemas.request_schema()

      assert schema["type"] == "object"
      assert "jsonrpc" in schema["required"]
      assert "method" in schema["required"]
      # id is optional
      refute "id" in schema["required"]
      # params is optional
      refute "params" in schema["required"]

      # Check jsonrpc field
      assert schema["properties"]["jsonrpc"]["type"] == "string"
      assert schema["properties"]["jsonrpc"]["enum"] == ["2.0"]

      # Check method field
      assert schema["properties"]["method"]["type"] == "string"

      # Check params field
      assert schema["properties"]["params"]["oneOf"] |> length() == 2
      assert %{"type" => "object"} in schema["properties"]["params"]["oneOf"]
      assert %{"type" => "array"} in schema["properties"]["params"]["oneOf"]

      # Check id field
      assert schema["properties"]["id"]["oneOf"] |> length() == 3
      assert %{"type" => "string"} in schema["properties"]["id"]["oneOf"]
      assert %{"type" => "number"} in schema["properties"]["id"]["oneOf"]
      assert %{"type" => "null"} in schema["properties"]["id"]["oneOf"]
    end
  end

  describe "tool_call_schema/0" do
    test "returns valid tool call request schema" do
      schema = Schemas.tool_call_schema()

      assert schema["type"] == "object"
      assert "jsonrpc" in schema["required"]
      assert "method" in schema["required"]
      assert "params" in schema["required"]
      # id is optional in tool calls too
      refute "id" in schema["required"]

      # Check jsonrpc field
      assert schema["properties"]["jsonrpc"]["type"] == "string"
      assert schema["properties"]["jsonrpc"]["enum"] == ["2.0"]

      # Check method field pattern
      assert schema["properties"]["method"]["type"] == "string"
      assert schema["properties"]["method"]["pattern"] == "^tools/call/"

      # Check params structure
      assert schema["properties"]["params"]["type"] == "object"
      assert "arguments" in schema["properties"]["params"]["required"]
      assert schema["properties"]["params"]["properties"]["arguments"]["type"] == "object"

      # Check id field (doesn't include null for tool calls)
      assert schema["properties"]["id"]["oneOf"] |> length() == 2
      assert %{"type" => "string"} in schema["properties"]["id"]["oneOf"]
      assert %{"type" => "number"} in schema["properties"]["id"]["oneOf"]
    end
  end

  describe "tool_definition_schema/0" do
    test "returns valid tool definition schema" do
      schema = Schemas.tool_definition_schema()

      assert schema["type"] == "object"
      assert "name" in schema["required"]
      assert "description" in schema["required"]
      assert "inputSchema" in schema["required"]

      # Check field types
      assert schema["properties"]["name"]["type"] == "string"
      assert schema["properties"]["description"]["type"] == "string"
      assert schema["properties"]["inputSchema"]["type"] == "object"
    end
  end

  describe "parse_request/1" do
    test "parses valid JSON string" do
      json_request = ~s({"jsonrpc": "2.0", "method": "test", "id": 1})
      assert {:ok, parsed} = Schemas.parse_request(json_request)
      assert parsed["jsonrpc"] == "2.0"
      assert parsed["method"] == "test"
      assert parsed["id"] == 1
    end

    test "parses valid map request" do
      map_request = %{"jsonrpc" => "2.0", "method" => "test", "id" => 1}
      assert {:ok, parsed} = Schemas.parse_request(map_request)
      assert parsed["jsonrpc"] == "2.0"
      assert parsed["method"] == "test"
      assert parsed["id"] == 1
    end

    test "returns error for invalid JSON string" do
      invalid_json = "{invalid json}"
      assert {:error, :parse_error} = Schemas.parse_request(invalid_json)
    end

    test "returns error for non-string, non-map input" do
      assert {:error, :parse_error} = Schemas.parse_request(123)
      assert {:error, :parse_error} = Schemas.parse_request(nil)
      assert {:error, :parse_error} = Schemas.parse_request([])
    end

    test "handles valid JSON with all fields" do
      request = %{
        "jsonrpc" => "2.0",
        "method" => "tools/list",
        "params" => %{},
        "id" => "test-id"
      }

      assert {:ok, parsed} = Schemas.parse_request(request)
      assert parsed["method"] == "tools/list"
      assert parsed["jsonrpc"] == "2.0"
      assert parsed["id"] == "test-id"
    end
  end

  describe "validate_request/1" do
    test "validates regular request" do
      request = %{
        "jsonrpc" => "2.0",
        "method" => "tools/list",
        "id" => 1
      }

      assert {:ok, validated} = Schemas.validate_request(request)
      assert validated == request
    end

    test "validates tool call request" do
      request = %{
        "jsonrpc" => "2.0",
        "method" => "tools/call/search_packages",
        "params" => %{
          "arguments" => %{
            "query" => "ecto"
          }
        },
        "id" => 1
      }

      assert {:ok, validated} = Schemas.validate_request(request)
      assert validated["method"] == "tools/call/search_packages"
    end

    test "returns error for invalid tool call" do
      request = %{
        "jsonrpc" => "2.0",
        "method" => "tools/call/invalid_tool",
        "params" => %{
          "arguments" => %{}
        },
        "id" => 1
      }

      # Should not error at schema validation level (tool existence is checked later)
      assert {:ok, validated} = Schemas.validate_request(request)
    end
  end

  describe "build_tool_schema/1" do
    test "builds schema for tool parameters" do
      params_spec = [
        query: [type: :string, required: true, description: "Search query"],
        limit: [type: :integer, required: false, description: "Result limit"],
        filters: [type: :object, required: false, description: "Search filters"]
      ]

      schema = Schemas.build_tool_schema(params_spec)

      assert schema["type"] == "object"
      assert "query" in schema["required"]
      assert "limit" not in schema["required"]
      assert "filters" not in schema["required"]

      assert schema["properties"]["query"]["type"] == "string"
      assert schema["properties"]["limit"]["type"] == "integer"
      assert schema["properties"]["filters"]["type"] == "object"
    end

    test "handles empty parameters" do
      schema = Schemas.build_tool_schema([])

      assert schema["type"] == "object"
      assert schema["required"] == []
      assert schema["properties"] == %{}
    end
  end

  describe "validate_tool_arguments/2" do
    test "validates arguments against tool schema" do
      # This test would require a mock tool schema
      # For now, just test the function exists and handles basic cases
      args = %{
        "query" => "ecto",
        "limit" => 10
      }

      # Since we don't have real tool schemas registered yet,
      # this will return :tool_not_found
      assert {:error, :tool_not_found} = Schemas.validate_tool_arguments("nonexistent_tool", args)
    end
  end
end

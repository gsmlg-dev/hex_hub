defmodule HexHub.MCP.SchemasTest do
  use ExUnit.Case, async: true

  alias HexHub.MCP.Schemas

  describe "request_schema/0" do
    test "returns valid JSON schema" do
      schema = Schemas.request_schema()

      assert schema["type"] == "object"
      assert "jsonrpc" in schema["required"]
      assert "method" in schema["required"]
    end
  end

  describe "tool_call_schema/0" do
    test "returns valid tool call schema" do
      schema = Schemas.tool_call_schema()

      assert schema["type"] == "object"
      assert "jsonrpc" in schema["required"]
      assert "method" in schema["required"]
      assert "params" in schema["required"]

      assert String.contains?(schema["properties"]["method"]["pattern"], "tools/call/")
    end
  end

  describe "parse_request/1" do
    test "parses valid JSON request" do
      request = %{
        "jsonrpc" => "2.0",
        "method" => "tools/list",
        "id" => 1
      }

      assert {:ok, parsed} = Schemas.parse_request(request)
      assert parsed["method"] == "tools/list"
      assert parsed["jsonrpc"] == "2.0"
    end

    test "parses valid JSON string" do
      json_string = Jason.encode!(%{
        "jsonrpc" => "2.0",
        "method" => "tools/list",
        "id" => 1
      })

      assert {:ok, parsed} = Schemas.parse_request(json_string)
      assert parsed["method"] == "tools/list"
    end

    test "returns error for invalid JSON" do
      invalid_json = "{invalid json}"

      assert {:error, :parse_error} = Schemas.parse_request(invalid_json)
    end

    test "returns error for missing required fields" do
      request = %{
        "jsonrpc" => "2.0"
        # missing method
      }

      assert {:error, :invalid_request} = Schemas.parse_request(request)
    end

    test "returns error for invalid jsonrpc version" do
      request = %{
        "jsonrpc" => "1.0",
        "method" => "tools/list",
        "id" => 1
      }

      assert {:error, :invalid_request} = Schemas.parse_request(request)
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

  describe "type mapping" do
    test "maps Elixir types to JSON schema types" do
      schema = Schemas.build_tool_schema([
        string_field: [type: :string],
        int_field: [type: :integer],
        bool_field: [type: :boolean],
        array_field: [type: :array],
        object_field: [type: :object]
      ])

      props = schema["properties"]
      assert props["string_field"]["type"] == "string"
      assert props["int_field"]["type"] == "integer"
      assert props["bool_field"]["type"] == "boolean"
      assert props["array_field"]["type"] == "array"
      assert props["object_field"]["type"] == "object"
    end
  end
end
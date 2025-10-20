defmodule HexHub.MCP.ServerTest do
  use ExUnit.Case, async: true

  alias HexHub.MCP.Server

  # Mock the tools module for testing
  defmodule MockTools do
    def register_all_tools do
      %{
        "test_tool" => %{
          name: "test_tool",
          description: "A test tool",
          input_schema: %{
            "type" => "object",
            "properties" => %{
              "message" => %{"type" => "string"}
            },
            "required" => ["message"]
          },
          handler: fn args, _context ->
            {:ok, %{echo: args["message"]}}
          end
        }
      }
    end
  end

  setup do
    # Start the server with mock tools
    Mox.stub_with(HexHub.MCP.ToolsMock, MockTools)
    {:ok, pid} = Server.start_link(config: [enabled: true])
    %{pid: pid}
  end

  describe "handle_request/3" do
    test "handles tools/list request" do
      request = %{
        "jsonrpc" => "2.0",
        "method" => "tools/list",
        "id" => 1
      }

      assert {:ok, response} = Server.handle_request(request, nil)

      assert response["jsonrpc"] == "2.0"
      assert response["id"] == 1
      assert %{"tools" => tools} = response["result"]
      assert length(tools) == 1
      assert hd(tools)["name"] == "test_tool"
    end

    test "handles tools/call request" do
      request = %{
        "jsonrpc" => "2.0",
        "method" => "tools/call/test_tool",
        "params" => %{
          "arguments" => %{
            "message" => "Hello, MCP!"
          }
        },
        "id" => 2
      }

      assert {:ok, response} = Server.handle_request(request, nil)

      assert response["jsonrpc"] == "2.0"
      assert response["id"] == 2
      assert %{"echo" => "Hello, MCP!"} = response["result"]
    end

    test "handles initialize request" do
      request = %{
        "jsonrpc" => "2.0",
        "method" => "initialize",
        "params" => %{
          "protocolVersion" => "2024-11-05",
          "capabilities" => %{},
          "clientInfo" => %{
            "name" => "Test Client",
            "version" => "1.0.0"
          }
        },
        "id" => 3
      }

      assert {:ok, response} = Server.handle_request(request, nil)

      assert response["jsonrpc"] == "2.0"
      assert response["id"] == 3
      assert %{
        "protocolVersion" => "2024-11-05",
        "capabilities" => _,
        "serverInfo" => %{
          "name" => "HexHub MCP Server",
          "version" => "1.0.0"
        }
      } = response["result"]
    end

    test "returns error for unknown method" do
      request = %{
        "jsonrpc" => "2.0",
        "method" => "unknown_method",
        "id" => 4
      }

      assert {:ok, response} = Server.handle_request(request, nil)

      assert response["jsonrpc"] == "2.0"
      assert response["id"] == 4
      assert %{
        "code" => -32601,
        "message" => "Method not found"
      } = response["error"]
    end

    test "returns error for invalid JSON" do
      invalid_request = "invalid json"

      assert {:error, response} = Server.handle_request(invalid_request, nil)

      assert response["jsonrpc"] == "2.0"
      assert response["id"] == nil
      assert %{
        "code" => -32700,
        "message" => "Parse error"
      } = response["error"]
    end

    test "returns error for missing required fields" do
      request = %{
        "jsonrpc" => "2.0"
        # missing method
      }

      assert {:error, response} = Server.handle_request(request, nil)

      assert response["jsonrpc"] == "2.0"
      assert response["id"] == nil
      assert %{
        "code" => -32600,
        "message" => "Invalid Request"
      } = response["error"]
    end

    test "returns error for invalid tool call parameters" do
      request = %{
        "jsonrpc" => "2.0",
        "method" => "tools/call/test_tool",
        "params" => %{
          "arguments" => %{
            # missing required "message" field
          }
        },
        "id" => 5
      }

      assert {:error, response} = Server.handle_request(request, nil)

      assert response["jsonrpc"] == "2.0"
      assert response["id"] == 5
      assert response["error"]["code"] == -32602  # Invalid params
    end
  end

  describe "list_tools/0" do
    test "returns list of available tools" do
      assert {:ok, tools} = Server.list_tools()
      assert length(tools) == 1

      tool = hd(tools)
      assert tool["name"] == "test_tool"
      assert tool["description"] == "A test tool"
      assert is_map(tool["inputSchema"])
    end
  end

  describe "get_tool_schema/1" do
    test "returns tool schema for valid tool" do
      assert {:ok, tool} = Server.get_tool_schema("test_tool")
      assert tool.name == "test_tool"
      assert tool.description == "A test tool"
      assert is_function(tool.handler)
    end

    test "returns error for unknown tool" do
      assert {:error, :tool_not_found} = Server.get_tool_schema("unknown_tool")
    end
  end

  describe "tool execution" do
    test "executes tool with valid arguments" do
      # This is tested indirectly through handle_request/3
      request = %{
        "jsonrpc" => "2.0",
        "method" => "tools/call/test_tool",
        "params" => %{
          "arguments" => %{
            "message" => "Test message"
          }
        },
        "id" => 6
      }

      assert {:ok, response} = Server.handle_request(request, nil)
      assert %{"echo" => "Test message"} = response["result"]
    end

    test "handles tool execution errors" do
      defmodule FailingMockTools do
        def register_all_tools do
          %{
            "failing_tool" => %{
              name: "failing_tool",
              description: "A tool that fails",
              input_schema: %{
                "type" => "object",
                "properties" => %{},
                "required" => []
              },
              handler: fn _args, _context ->
                raise "Tool execution error"
              end
            }
          }
        end
      end

      Mox.stub_with(HexHub.MCP.ToolsMock, FailingMockTools)

      # Restart server with failing tool
      GenServer.stop(Server)
      {:ok, _pid} = Server.start_link(config: [enabled: true])

      request = %{
        "jsonrpc" => "2.0",
        "method" => "tools/call/failing_tool",
        "params" => %{
          "arguments" => %{}
        },
        "id" => 7
      }

      assert {:error, response} = Server.handle_request(request, nil)
      assert response["error"]["code"] == -32000  # Server error
    end
  end

  describe "request context" do
    test "passes transport state to tool handlers" do
      defmodule ContextMockTools do
        def register_all_tools do
          %{
            "context_tool" => %{
              name: "context_tool",
              description: "A tool that uses context",
              input_schema: %{
                "type" => "object",
                "properties" => %{},
                "required" => []
              },
              handler: fn _args, context ->
                {:ok, %{has_transport_state: Map.has_key?(context, :transport_state)}}
              end
            }
          }
        end
      end

      Mox.stub_with(HexHub.MCP.ToolsMock, ContextMockTools)

      # Restart server with context tool
      GenServer.stop(Server)
      {:ok, _pid} = Server.start_link(config: [enabled: true])

      request = %{
        "jsonrpc" => "2.0",
        "method" => "tools/call/context_tool",
        "params" => %{
          "arguments" => %{}
        },
        "id" => 8
      }

      assert {:ok, response} = Server.handle_request(request, %{test: "state"})
      assert response["result"]["has_transport_state"] == true
    end
  end

  describe "server lifecycle" do
    test "starts and stops gracefully" do
      {:ok, pid} = Server.start_link([])

      assert Process.alive?(pid)
      assert :ok = GenServer.stop(pid)
    end

    test "handles concurrent requests" do
      # Test concurrent request handling
      tasks = for i <- 1..10 do
        Task.async(fn ->
          request = %{
            "jsonrpc" => "2.0",
            "method" => "tools/list",
            "id" => i
          }

          Server.handle_request(request, nil)
        end)
      end

      results = Task.await_many(tasks, 5000)
      assert length(results) == 10

      # All should be successful responses
      for result <- results do
        assert {:ok, response} = result
        assert response["jsonrpc"] == "2.0"
        assert %{"tools" => _} = response["result"]
      end
    end
  end
end
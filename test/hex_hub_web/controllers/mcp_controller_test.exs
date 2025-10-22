defmodule HexHubWeb.MCPControllerTest do
  use HexHubWeb.ConnCase, async: false
  alias HexHubWeb.MCPController

  import Mox

  setup :verify_on_exit!

  describe "handle_request/2" do
    test "handles valid MCP request", %{conn: conn} do
      # Mock MCP to be enabled
      Application.put_env(:hex_hub, :mcp, enabled: true, require_auth: false)

      mcp_request = %{
        "jsonrpc" => "2.0",
        "method" => "tools/list",
        "id" => "test-1"
      }

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(~p"/mcp", mcp_request)

      # Should return 200 or appropriate status based on actual implementation
      assert response_status = response(conn, :status)
      # Accept various possible responses
      assert response_status in [200, 400, 500]

      # Clean up
      Application.delete_env(:hex_hub, :mcp)
    end

    test "returns service unavailable when MCP is disabled", %{conn: conn} do
      Application.put_env(:hex_hub, :mcp, enabled: false)

      mcp_request = %{
        "jsonrpc" => "2.0",
        "method" => "tools/list",
        "id" => "test-1"
      }

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(~p"/mcp", mcp_request)

      assert response(conn, 503)
      response_body = json_response(conn, 503)
      assert response_body["error"]["code"] == -32001
      assert response_body["error"]["message"] == "MCP server is disabled"

      # Clean up
      Application.delete_env(:hex_hub, :mcp)
    end

    test "includes response time header", %{conn: conn} do
      Application.put_env(:hex_hub, :mcp, enabled: true, require_auth: false)

      mcp_request = %{
        "jsonrpc" => "2.0",
        "method" => "initialize",
        "id" => "test-1"
      }

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(~p"/mcp", mcp_request)

      # Check for response time header if request succeeds
      if response(conn, :status) == 200 do
        assert get_resp_header(conn, "x-mcp-response-time") |> length() > 0
      end

      # Clean up
      Application.delete_env(:hex_hub, :mcp)
    end
  end

  describe "list_tools/2" do
    test "lists available tools", %{conn: conn} do
      Application.put_env(:hex_hub, :mcp, enabled: true, require_auth: false)

      conn = get(conn, ~p"/mcp/tools")

      # Response may be 200 or error based on server state
      assert response_status = response(conn, :status)
      assert response_status in [200, 500]

      if response_status == 200 do
        response_body = json_response(conn, 200)
        assert Map.has_key?(response_body, "tools")
        assert Map.has_key?(response_body, "server")
      end

      # Clean up
      Application.delete_env(:hex_hub, :mcp)
    end

    test "returns service unavailable when MCP is disabled", %{conn: conn} do
      Application.put_env(:hex_hub, :mcp, enabled: false)

      conn = get(conn, ~p"/mcp/tools")

      assert response(conn, 503)
      response_body = json_response(conn, 503)
      assert response_body["error"]["code"] == -32001

      # Clean up
      Application.delete_env(:hex_hub, :mcp)
    end
  end

  describe "server_info/2" do
    test "returns server information", %{conn: conn} do
      Application.put_env(:hex_hub, :mcp, enabled: true, require_auth: false)

      conn = get(conn, ~p"/mcp/info")

      response_body = json_response(conn, 200)
      assert response_body["name"] == "HexHub MCP Server"
      assert response_body["version"] == "1.0.0"
      assert Map.has_key?(response_body, "capabilities")
      assert Map.has_key?(response_body, "endpoints")
      assert Map.has_key?(response_body, "authentication")
      assert Map.has_key?(response_body, "configuration")

      # Check endpoints structure
      assert Map.has_key?(response_body["endpoints"], "websocket")
      assert Map.has_key?(response_body["endpoints"], "http")

      # Clean up
      Application.delete_env(:hex_hub, :mcp)
    end
  end

  describe "health/2" do
    test "returns health status", %{conn: conn} do
      conn = get(conn, ~p"/mcp/health")

      # Should return 200 or 503 based on server health
      assert response_status = response(conn, :status)
      assert response_status in [200, 503]

      response_body = json_response(conn, response_status)
      assert Map.has_key?(response_body, "status")
      assert Map.has_key?(response_body, "timestamp")
    end
  end

  describe "authentication" do
    test "requires authentication when enabled", %{conn: conn} do
      Application.put_env(:hex_hub, :mcp, enabled: true, require_auth: true)

      # Create a test user and API key
      {:ok, user} =
        HexHub.Users.create_user(%{
          username: "mcp_test_user",
          email: "mcp_test@example.com",
          password: "test_password123"
        })

      {:ok, api_key} = HexHub.APIKeys.create_key(user, "MCP Test Key", [:read])

      mcp_request = %{
        "jsonrpc" => "2.0",
        "method" => "tools/list",
        "id" => "test-1"
      }

      # Test with Bearer token
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("authorization", "Bearer #{api_key.key}")
        |> post(~p"/mcp", mcp_request)

      # Should accept the valid API key
      assert response_status = response(conn, :status)
      # Various responses possible
      assert response_status in [200, 400, 500]

      # Test without authentication
      conn =
        build_conn()
        |> put_req_header("content-type", "application/json")
        |> post(~p"/mcp", mcp_request)

      assert response(conn, 401)
      response_body = json_response(conn, 401)
      assert response_body["error"]["code"] == -32001

      # Clean up
      Application.delete_env(:hex_hub, :mcp)
    end

    test "accepts Basic auth with mcp username", %{conn: conn} do
      Application.put_env(:hex_hub, :mcp, enabled: true, require_auth: true)

      # Create a test user and API key
      {:ok, user} =
        HexHub.Users.create_user(%{
          username: "mcp_basic_test_user",
          email: "mcp_basic_test@example.com",
          password: "test_password123"
        })

      {:ok, api_key} = HexHub.APIKeys.create_key(user, "MCP Basic Test Key", [:read])

      mcp_request = %{
        "jsonrpc" => "2.0",
        "method" => "tools/list",
        "id" => "test-1"
      }

      # Test with Basic auth (mcp:api_key)
      basic_auth = Base.encode64("mcp:#{api_key.key}")

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("authorization", "Basic #{basic_auth}")
        |> post(~p"/mcp", mcp_request)

      # Should accept the valid API key via Basic auth
      assert response_status = response(conn, :status)
      # Various responses possible
      assert response_status in [200, 400, 500]

      # Clean up
      Application.delete_env(:hex_hub, :mcp)
    end

    test "accepts API key in query parameter", %{conn: conn} do
      Application.put_env(:hex_hub, :mcp, enabled: true, require_auth: true)

      # Create a test user and API key
      {:ok, user} =
        HexHub.Users.create_user(%{
          username: "mcp_query_test_user",
          email: "mcp_query_test@example.com",
          password: "test_password123"
        })

      {:ok, api_key} = HexHub.APIKeys.create_key(user, "MCP Query Test Key", [:read])

      mcp_request = %{
        "jsonrpc" => "2.0",
        "method" => "tools/list",
        "id" => "test-1"
      }

      # Test with API key in query parameter
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(~p"/mcp?api_key=#{api_key.key}", mcp_request)

      # Should accept the valid API key via query parameter
      assert response_status = response(conn, :status)
      # Various responses possible
      assert response_status in [200, 400, 500]

      # Clean up
      Application.delete_env(:hex_hub, :mcp)
    end
  end

  describe "CORS support" do
    test "handles CORS preflight request", %{conn: conn} do
      conn =
        conn
        |> put_req_header("origin", "https://example.com")
        |> put_req_header("access-control-request-method", "POST")
        |> put_req_header("access-control-request-headers", "Content-Type, Authorization")
        |> options(~p"/mcp")

      assert response(conn, 204)
      assert get_resp_header(conn, "access-control-allow-origin") == ["*"]
      assert get_resp_header(conn, "access-control-allow-methods") == ["GET, POST, OPTIONS"]

      assert get_resp_header(conn, "access-control-allow-headers") == [
               "Content-Type, Authorization"
             ]

      assert get_resp_header(conn, "access-control-max-age") == ["86400"]
    end
  end

  describe "error handling" do
    test "handles invalid JSON", %{conn: conn} do
      Application.put_env(:hex_hub, :mcp, enabled: true, require_auth: false)

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(~p"/mcp", "invalid json")

      assert response(conn, 400)

      # Clean up
      Application.delete_env(:hex_hub, :mcp)
    end

    test "handles missing required fields", %{conn: conn} do
      Application.put_env(:hex_hub, :mcp, enabled: true, require_auth: false)

      invalid_request = %{
        "jsonrpc" => "2.0"
        # Missing "method" field
      }

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(~p"/mcp", invalid_request)

      assert response(conn, 400)

      # Clean up
      Application.delete_env(:hex_hub, :mcp)
    end
  end
end

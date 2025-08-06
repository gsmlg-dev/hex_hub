defmodule HexHubWeb.API.KeyControllerTest do
  use HexHubWeb.ConnCase

  describe "GET /api/keys" do
    test "lists all API keys", %{conn: conn} do
      conn = get(conn, ~p"/api/keys")
      
      assert %{
               "keys" => keys
             } = json_response(conn, 200)
      
      assert is_list(keys)
    end
  end

  describe "POST /api/keys" do
    test "creates new API key with valid params", %{conn: conn} do
      params = %{
        "name" => "test-key",
        "permissions" => [
          %{
            "domain" => "api",
            "resource" => "*"
          }
        ]
      }

      conn = post(conn, ~p"/api/keys", params)
      
      assert %{
               "name" => "test-key",
               "secret" => secret
             } = json_response(conn, 201)
      
      assert is_binary(secret)
      assert String.length(secret) > 0
    end

    test "returns 422 with invalid params", %{conn: conn} do
      params = %{
        "name" => ""
      }

      conn = post(conn, ~p"/api/keys", params)
      assert json_response(conn, 422)
    end
  end

  describe "GET /api/keys/:name" do
    test "returns key details", %{conn: conn} do
      key_name = "test-key"

      conn = get(conn, ~p"/api/keys/#{key_name}")
      
      assert %{
               "name" => "test-key",
               "permissions" => permissions
             } = json_response(conn, 200)
      
      assert is_list(permissions)
    end

    test "returns 404 for non-existent key", %{conn: conn} do
      conn = get(conn, ~p"/api/keys/nonexistent")
      assert response(conn, 404)
    end
  end

  describe "DELETE /api/keys/:name" do
    test "deletes API key", %{conn: conn} do
      key_name = "test-key"

      conn = delete(conn, ~p"/api/keys/#{key_name}")
      assert response(conn, 204)
    end

    test "returns 404 for non-existent key", %{conn: conn} do
      conn = delete(conn, ~p"/api/keys/nonexistent")
      assert response(conn, 404)
    end
  end
end
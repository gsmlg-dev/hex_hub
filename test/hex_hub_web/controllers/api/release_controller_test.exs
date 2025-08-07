defmodule HexHubWeb.API.ReleaseControllerTest do
  use HexHubWeb.ConnCase

  setup %{conn: conn} do
    %{api_key: api_key} = setup_authenticated_user()
    {:ok, conn: authenticated_conn(conn, api_key)}
  end

  describe "GET /api/packages/:name/releases/:version" do
    test "returns release details", %{conn: conn} do
      conn = get(conn, ~p"/api/packages/phoenix/releases/1.7.0")

      assert %{
               "name" => "phoenix",
               "version" => "1.7.0",
               "checksum" => _,
               "requirements" => requirements,
               "inner_checksum" => _
             } = json_response(conn, 200)

      assert is_map(requirements)
    end

    test "returns 404 for non-existent release", %{conn: conn} do
      conn = get(conn, ~p"/api/packages/phoenix/releases/99.99.99")
      assert response(conn, 404)
    end

    test "returns 404 for non-existent package", %{conn: conn} do
      conn = get(conn, ~p"/api/packages/nonexistent/releases/1.0.0")
      assert response(conn, 404)
    end
  end

  describe "POST /api/publish" do
    test "publishes new package release", %{conn: conn} do
      params = %{
        "name" => "test_package",
        "version" => "1.0.0",
        "requirements" => %{},
        "meta" => %{
          "app" => "test_package",
          "description" => "Test package",
          "version" => "1.0.0"
        }
      }

      conn = post(conn, ~p"/api/publish", params)

      assert %{
               "url" => url
             } = json_response(conn, 201)

      assert url == "/packages/test_package/releases/1.0.0"
    end

    test "returns 422 with invalid package data", %{conn: conn} do
      params = %{
        "name" => "",
        "version" => "invalid",
        "requirements" => %{}
      }

      conn = post(conn, ~p"/api/publish", params)
      assert json_response(conn, 422)
    end
  end

  describe "POST /api/packages/:name/releases/:version/retire" do
    test "retires a package release", %{conn: conn} do
      params = %{
        "reason" => "other",
        "message" => "This version has security vulnerabilities"
      }

      conn = post(conn, ~p"/api/packages/phoenix/releases/1.7.0/retire", params)
      assert response(conn, 204)
    end

    test "returns 404 for non-existent release", %{conn: conn} do
      conn = post(conn, ~p"/api/packages/phoenix/releases/99.99.99/retire", %{})
      assert response(conn, 404)
    end
  end

  describe "DELETE /api/packages/:name/releases/:version/retire" do
    test "unretires a package release", %{conn: conn} do
      conn = delete(conn, ~p"/api/packages/phoenix/releases/1.7.0/retire")
      assert response(conn, 204)
    end

    test "returns 404 for non-existent release", %{conn: conn} do
      conn = delete(conn, ~p"/api/packages/phoenix/releases/99.99.99/retire")
      assert response(conn, 404)
    end
  end
end

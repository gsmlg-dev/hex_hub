defmodule HexHubWeb.API.OwnerControllerTest do
  use HexHubWeb.ConnCase

  describe "GET /api/packages/:name/owners" do
    test "lists package owners", %{conn: conn} do
      package_name = "test_package"

      conn = get(conn, ~p"/api/packages/#{package_name}/owners")
      
      assert %{
               "owners" => owners
             } = json_response(conn, 200)
      
      assert is_list(owners)
    end

    test "returns 404 for non-existent package", %{conn: conn} do
      conn = get(conn, ~p"/api/packages/nonexistent/owners")
      assert response(conn, 404)
    end
  end

  describe "PUT /api/packages/:name/owners/:email" do
    test "adds owner to package", %{conn: conn} do
      package_name = "test_package"
      owner_email = "newowner@example.com"

      conn = put(conn, ~p"/api/packages/#{package_name}/owners/#{owner_email}")
      assert response(conn, 204)
    end

    test "returns 404 for non-existent package", %{conn: conn} do
      conn = put(conn, ~p"/api/packages/nonexistent/owners/owner@example.com")
      assert response(conn, 404)
    end
  end

  describe "DELETE /api/packages/:name/owners/:email" do
    test "removes owner from package", %{conn: conn} do
      package_name = "test_package"
      owner_email = "owner@example.com"

      conn = delete(conn, ~p"/api/packages/#{package_name}/owners/#{owner_email}")
      assert response(conn, 204)
    end

    test "returns 404 for non-existent package", %{conn: conn} do
      conn = delete(conn, ~p"/api/packages/nonexistent/owners/owner@example.com")
      assert response(conn, 404)
    end
  end
end
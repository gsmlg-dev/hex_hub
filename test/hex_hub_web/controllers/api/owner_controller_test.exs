defmodule HexHubWeb.API.OwnerControllerTest do
  use HexHubWeb.ConnCase

  setup %{conn: conn} do
    %{api_key: api_key} = setup_authenticated_user()
    {:ok, conn: authenticated_conn(conn, api_key)}
  end

  describe "GET /api/packages/:name/owners" do
    test "lists package owners", %{conn: conn} do
      # Create a package first
      package = create_package(%{name: "test_package_owners"})

      conn = get(conn, ~p"/api/packages/#{package.name}/owners")

      assert %{
               "owners" => owners
             } = json_response(conn, 200)

      assert is_list(owners)
    end

    test "returns 404 for non-existent package", %{conn: conn} do
      conn = get(conn, ~p"/api/packages/nonexistent_pkg_xyz/owners")
      assert response(conn, 404)
    end
  end

  describe "PUT /api/packages/:name/owners/:email" do
    setup %{conn: conn} do
      %{api_key: api_key} =
        setup_authenticated_user(%{username: "testuser", permissions: ["read", "write"]})

      {:ok, conn: authenticated_conn(conn, api_key)}
    end

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
    setup %{conn: conn} do
      %{api_key: api_key} =
        setup_authenticated_user(%{username: "testuser", permissions: ["read", "write"]})

      {:ok, conn: authenticated_conn(conn, api_key)}
    end

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

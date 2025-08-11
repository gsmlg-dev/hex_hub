defmodule HexHubWeb.API.PackageControllerTest do
  use HexHubWeb.ConnCase

  describe "GET /api/packages" do
    test "lists all packages", %{conn: conn} do
      conn = get(conn, ~p"/api/packages")

      assert %{
               "packages" => packages
             } = json_response(conn, 200)

      assert is_list(packages)
    end

    test "supports pagination parameters", %{conn: conn} do
      conn = get(conn, ~p"/api/packages?page=1&per_page=10")

      assert %{
               "packages" => packages
             } = json_response(conn, 200)

      assert is_list(packages)
    end

    test "supports search parameter", %{conn: conn} do
      conn = get(conn, ~p"/api/packages?search=phoenix")

      assert %{
               "packages" => packages
             } = json_response(conn, 200)

      assert is_list(packages)
    end
  end

  describe "GET /api/packages/:name" do
    test "returns package details", %{conn: conn} do
      # Create a test package first
      package_name = "test_package_#{System.unique_integer([:positive])}"

      {:ok, _} =
        HexHub.Packages.create_package(package_name, "hexpm", %{"description" => "Test package"})

      conn = get(conn, ~p"/api/packages/#{package_name}")

      assert %{
               "name" => ^package_name,
               "repository" => "hexpm",
               "releases" => releases
             } = json_response(conn, 200)

      assert is_list(releases)
    end

    test "returns 404 for non-existent package", %{conn: conn} do
      conn = get(conn, ~p"/api/packages/nonexistent")
      assert response(conn, 404)
    end
  end
end

defmodule HexHubWeb.API.RepositoryControllerTest do
  use HexHubWeb.ConnCase

  describe "GET /api/repos" do
    test "lists all repositories", %{conn: conn} do
      conn = get(conn, ~p"/api/repos")

      repositories = json_response(conn, 200)
      assert is_list(repositories)
    end
  end

  describe "GET /api/repos/:name" do
    test "returns repository details", %{conn: conn} do
      conn = get(conn, ~p"/api/repos/hexpm")

      assert %{
               "name" => "hexpm",
               "public" => true,
               "active" => true,
               "billing_active" => true
             } = json_response(conn, 200)
    end

    test "returns 404 for non-existent repository", %{conn: conn} do
      conn = get(conn, ~p"/api/repos/nonexistent")
      assert response(conn, 404)
    end
  end
end

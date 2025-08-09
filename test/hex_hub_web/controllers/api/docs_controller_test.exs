defmodule HexHubWeb.API.DocsControllerTest do
  use HexHubWeb.ConnCase

  setup %{conn: conn} do
    %{api_key: api_key} = setup_authenticated_user()
    {:ok, conn: authenticated_conn(conn, api_key)}
  end

  describe "POST /api/packages/:name/releases/:version/docs" do
    test "uploads documentation tarball", %{conn: conn} do
      package_name = "test_package"
      version = "1.0.0"

      # Create package and release first
      {:ok, _package} =
        HexHub.Packages.create_package(package_name, "hexpm", %{description: "Test package"})

      {:ok, _release} =
        HexHub.Packages.create_release(package_name, version, %{}, %{}, "mock tarball")

      # Create a simple tarball content for testing
      docs_content = "mock documentation tarball content"

      conn =
        conn
        |> put_req_header("content-type", "application/octet-stream")
        |> post(~p"/api/packages/#{package_name}/releases/#{version}/docs", docs_content)

      assert response(conn, 201)
    end

    test "returns 404 for non-existent package", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/octet-stream")
        |> post(~p"/api/packages/nonexistent/releases/1.0.0/docs", "content")

      assert response(conn, 404)
    end
  end

  describe "DELETE /api/packages/:name/releases/:version/docs" do
    test "deletes documentation tarball", %{conn: conn} do
      package_name = "test_package"
      version = "1.0.0"

      # Create package and release first
      {:ok, _package} =
        HexHub.Packages.create_package(package_name, "hexpm", %{description: "Test package"})

      {:ok, _release} =
        HexHub.Packages.create_release(package_name, version, %{}, %{}, "mock tarball")

      # Upload docs first
      {:ok, _release} = HexHub.Packages.upload_docs(package_name, version, "mock docs")

      conn = delete(conn, ~p"/api/packages/#{package_name}/releases/#{version}/docs")
      assert response(conn, 204)
    end

    test "returns 404 for non-existent package", %{conn: conn} do
      conn = delete(conn, ~p"/api/packages/nonexistent/releases/1.0.0/docs")
      assert response(conn, 404)
    end
  end
end

defmodule HexHubAdminWeb.PackageControllerTest do
  use HexHubAdminWeb.ConnCase

  alias HexHub.Packages

  describe "search/2" do
    test "shows search form", %{conn: conn} do
      conn = get(conn, ~p"/packages/search")

      response = html_response(conn, 200)
      assert response =~ "Package Search"
      assert response =~ "Enter a search term"
    end

    test "searches across all sources", %{conn: conn} do
      {:ok, _} =
        Packages.create_package(
          "local_phoenix",
          "hexpm",
          %{"description" => "Local Phoenix"},
          false,
          :local
        )

      {:ok, _} =
        Packages.create_package(
          "cached_phoenix",
          "hexpm",
          %{"description" => "Cached Phoenix"},
          false,
          :cached
        )

      conn = get(conn, ~p"/packages/search?q=phoenix")

      response = html_response(conn, 200)
      assert response =~ "local_phoenix"
      assert response =~ "cached_phoenix"
      assert response =~ "Found 2"
    end

    test "filters by local source", %{conn: conn} do
      {:ok, _} = Packages.create_package("local_pkg", "hexpm", %{}, false, :local)
      {:ok, _} = Packages.create_package("cached_pkg", "hexpm", %{}, false, :cached)

      conn = get(conn, ~p"/packages/search?q=pkg&source=local")

      response = html_response(conn, 200)
      assert response =~ "local_pkg"
      refute response =~ ">cached_pkg<"
    end

    test "filters by cached source", %{conn: conn} do
      {:ok, _} = Packages.create_package("local_pkg", "hexpm", %{}, false, :local)
      {:ok, _} = Packages.create_package("cached_pkg", "hexpm", %{}, false, :cached)

      conn = get(conn, ~p"/packages/search?q=pkg&source=cached")

      response = html_response(conn, 200)
      assert response =~ "cached_pkg"
      refute response =~ ">local_pkg<"
    end

    test "shows priority annotations", %{conn: conn} do
      {:ok, _} = Packages.create_package("local_active", "hexpm", %{}, false, :local)
      {:ok, _} = Packages.create_package("cached_active", "hexpm", %{}, false, :cached)

      conn = get(conn, ~p"/packages/search?q=active")

      response = html_response(conn, 200)
      assert response =~ "Active"
      assert response =~ "Local"
      assert response =~ "Cached"
    end

    test "shows no results message when no matches", %{conn: conn} do
      conn = get(conn, ~p"/packages/search?q=nonexistent_package_xyz")

      response = html_response(conn, 200)
      assert response =~ "No packages found"
    end
  end
end

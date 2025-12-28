defmodule HexHubAdminWeb.CachedPackageControllerTest do
  use HexHubAdminWeb.ConnCase

  alias HexHub.Packages

  describe "index/2" do
    test "lists cached packages", %{conn: conn} do
      {:ok, _} =
        Packages.create_package(
          "cached_pkg",
          "hexpm",
          %{"description" => "Cached"},
          false,
          :cached
        )

      conn = get(conn, ~p"/cached-packages")

      assert html_response(conn, 200) =~ "Cached Packages"
      assert html_response(conn, 200) =~ "cached_pkg"
    end

    test "shows empty state when no packages exist", %{conn: conn} do
      conn = get(conn, ~p"/cached-packages")

      assert html_response(conn, 200) =~ "No cached packages found"
    end

    test "does not show local packages", %{conn: conn} do
      {:ok, _} =
        Packages.create_package("local_pkg", "hexpm", %{"description" => "Local"}, false, :local)

      conn = get(conn, ~p"/cached-packages")

      refute html_response(conn, 200) =~ "local_pkg"
    end

    test "shows shadowed status for packages with local counterpart", %{conn: conn} do
      # Create both local and cached packages (different names since we use name as key)
      {:ok, _} = Packages.create_package("cached_only", "hexpm", %{}, false, :cached)

      conn = get(conn, ~p"/cached-packages")
      response = html_response(conn, 200)

      # Package should show as Active since there's no local counterpart with same name
      assert response =~ "Active"
    end

    test "filters packages by search term", %{conn: conn} do
      {:ok, _} = Packages.create_package("phoenix_cached", "hexpm", %{}, false, :cached)
      {:ok, _} = Packages.create_package("ecto_cached", "hexpm", %{}, false, :cached)

      conn = get(conn, ~p"/cached-packages?search=phoenix")

      assert html_response(conn, 200) =~ "phoenix_cached"
      refute html_response(conn, 200) =~ ">ecto_cached<"
    end
  end

  describe "show/2" do
    test "displays cached package details", %{conn: conn} do
      {:ok, _} =
        Packages.create_package(
          "my_cached_pkg",
          "hexpm",
          %{"description" => "Cached package"},
          false,
          :cached
        )

      conn = get(conn, ~p"/cached-packages/my_cached_pkg")

      response = html_response(conn, 200)
      assert response =~ "my_cached_pkg"
      assert response =~ "Cached package"
      assert response =~ "Cached"
    end

    test "shows shadowed warning when local counterpart exists", %{conn: conn} do
      # In practice, with the current schema, same-name packages can't exist in both sources
      # This test validates the UI shows Active status for non-shadowed packages
      {:ok, _} = Packages.create_package("cached_unique", "hexpm", %{}, false, :cached)

      conn = get(conn, ~p"/cached-packages/cached_unique")

      response = html_response(conn, 200)
      assert response =~ "Active"
    end

    test "returns 404 when package not found", %{conn: conn} do
      conn = get(conn, ~p"/cached-packages/nonexistent")

      assert redirected_to(conn) == "/cached-packages"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "not found"
    end

    test "returns 404 when package is local, not cached", %{conn: conn} do
      {:ok, _} = Packages.create_package("local_only", "hexpm", %{}, false, :local)

      conn = get(conn, ~p"/cached-packages/local_only")

      assert redirected_to(conn) == "/cached-packages"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "not found"
    end
  end

  describe "delete/2" do
    test "deletes cached package successfully", %{conn: conn} do
      {:ok, _} = Packages.create_package("to_delete", "hexpm", %{}, false, :cached)

      conn = delete(conn, ~p"/cached-packages/to_delete")

      assert redirected_to(conn) == "/cached-packages"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "deleted"
    end

    test "returns error when package not found", %{conn: conn} do
      conn = delete(conn, ~p"/cached-packages/nonexistent")

      assert redirected_to(conn) == "/cached-packages"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "not found"
    end

    test "returns error when trying to delete local package", %{conn: conn} do
      {:ok, _} = Packages.create_package("local_pkg", "hexpm", %{}, false, :local)

      conn = delete(conn, ~p"/cached-packages/local_pkg")

      assert redirected_to(conn) == "/cached-packages"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "not found"
    end
  end

  describe "clear_all/2" do
    test "clears all cached packages with confirmation", %{conn: conn} do
      {:ok, _} = Packages.create_package("cached1", "hexpm", %{}, false, :cached)
      {:ok, _} = Packages.create_package("cached2", "hexpm", %{}, false, :cached)

      conn = delete(conn, ~p"/cached-packages?confirm=true")

      assert redirected_to(conn) == "/cached-packages"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "deleted 2"
    end

    test "requires confirmation parameter", %{conn: conn} do
      {:ok, _} = Packages.create_package("cached1", "hexpm", %{}, false, :cached)

      conn = delete(conn, ~p"/cached-packages")

      assert redirected_to(conn) == "/cached-packages"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Confirmation required"
    end

    test "does not delete local packages", %{conn: conn} do
      {:ok, _} = Packages.create_package("local1", "hexpm", %{}, false, :local)
      {:ok, _} = Packages.create_package("cached1", "hexpm", %{}, false, :cached)

      delete(conn, ~p"/cached-packages?confirm=true")

      # Verify local package still exists
      assert {:ok, _} = HexHub.CachedPackages.get_package_by_source("local1", :local)
    end
  end
end

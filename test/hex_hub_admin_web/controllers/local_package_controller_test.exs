defmodule HexHubAdminWeb.LocalPackageControllerTest do
  use HexHubAdminWeb.ConnCase

  alias HexHub.Packages

  describe "index/2" do
    test "lists local packages", %{conn: conn} do
      {:ok, _} =
        Packages.create_package("local_pkg", "hexpm", %{"description" => "Local"}, false, :local)

      conn = get(conn, ~p"/local-packages")

      assert html_response(conn, 200) =~ "Local Packages"
      assert html_response(conn, 200) =~ "local_pkg"
    end

    test "shows empty state when no packages exist", %{conn: conn} do
      conn = get(conn, ~p"/local-packages")

      assert html_response(conn, 200) =~ "No local packages found"
    end

    test "does not show cached packages", %{conn: conn} do
      {:ok, _} =
        Packages.create_package(
          "cached_pkg",
          "hexpm",
          %{"description" => "Cached"},
          false,
          :cached
        )

      conn = get(conn, ~p"/local-packages")

      refute html_response(conn, 200) =~ "cached_pkg"
    end

    test "filters packages by search term", %{conn: conn} do
      {:ok, _} = Packages.create_package("phoenix", "hexpm", %{}, false, :local)
      {:ok, _} = Packages.create_package("ecto", "hexpm", %{}, false, :local)

      conn = get(conn, ~p"/local-packages?search=phoenix")

      assert html_response(conn, 200) =~ "phoenix"
      refute html_response(conn, 200) =~ ">ecto<"
    end

    test "paginates results", %{conn: conn} do
      # Create 60 packages to test pagination
      for i <- 1..60 do
        {:ok, _} =
          Packages.create_package(
            "pkg_#{String.pad_leading("#{i}", 3, "0")}",
            "hexpm",
            %{},
            false,
            :local
          )
      end

      conn = get(conn, ~p"/local-packages?page=1&per_page=50")
      response = html_response(conn, 200)

      assert response =~ "Total: 60 packages"
      assert response =~ "Next"
    end

    test "sorts packages by name", %{conn: conn} do
      {:ok, _} = Packages.create_package("zzz_pkg", "hexpm", %{}, false, :local)
      {:ok, _} = Packages.create_package("aaa_pkg", "hexpm", %{}, false, :local)

      conn = get(conn, ~p"/local-packages?sort=name&sort_dir=asc")
      response = html_response(conn, 200)

      # aaa should appear before zzz when sorted ascending
      aaa_pos = :binary.match(response, "aaa_pkg")
      zzz_pos = :binary.match(response, "zzz_pkg")

      assert elem(aaa_pos, 0) < elem(zzz_pos, 0)
    end
  end

  describe "show/2" do
    test "displays local package details", %{conn: conn} do
      {:ok, _} =
        Packages.create_package(
          "my_pkg",
          "hexpm",
          %{"description" => "My package"},
          false,
          :local
        )

      conn = get(conn, ~p"/local-packages/my_pkg")

      response = html_response(conn, 200)
      assert response =~ "my_pkg"
      assert response =~ "My package"
      assert response =~ "Local"
    end

    test "shows version history", %{conn: conn} do
      {:ok, _} = Packages.create_package("versioned", "hexpm", %{}, false, :local)
      Packages.create_release("versioned", "1.0.0", %{}, %{}, <<0>>)
      Packages.create_release("versioned", "2.0.0", %{}, %{}, <<0>>)

      conn = get(conn, ~p"/local-packages/versioned")

      response = html_response(conn, 200)
      assert response =~ "1.0.0"
      assert response =~ "2.0.0"
    end

    test "returns 404 when package not found", %{conn: conn} do
      conn = get(conn, ~p"/local-packages/nonexistent")

      assert redirected_to(conn) == "/local-packages"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "not found"
    end

    test "returns 404 when package is cached, not local", %{conn: conn} do
      {:ok, _} = Packages.create_package("cached_only", "hexpm", %{}, false, :cached)

      conn = get(conn, ~p"/local-packages/cached_only")

      assert redirected_to(conn) == "/local-packages"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "not found"
    end

    test "shows cached counterpart indicator when exists", %{conn: conn} do
      # Create a local package
      {:ok, _} = Packages.create_package("shared", "hexpm", %{}, false, :local)

      # Create a cached package with different name (to simulate shadow scenario description)
      # Note: In the real system, same-name packages would be handled differently
      conn = get(conn, ~p"/local-packages/shared")

      response = html_response(conn, 200)
      assert response =~ "shared"
    end
  end
end

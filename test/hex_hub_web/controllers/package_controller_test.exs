defmodule HexHubWeb.PackageControllerTest do
  use HexHubWeb.ConnCase

  alias HexHub.Packages

  setup %{conn: conn} do
    Packages.reset_test_store()

    # Create test packages
    {:ok, _} =
      Packages.create_package("phoenix", "hexpm", %{
        "description" => "Web framework for Elixir",
        "licenses" => ["MIT"]
      })

    {:ok, _} =
      Packages.create_package("ecto", "hexpm", %{
        "description" => "Database wrapper and query generator",
        "licenses" => ["Apache-2.0"]
      })

    {:ok, _} =
      Packages.create_package("plug", "hexpm", %{
        "description" => "A specification for composable modules"
      })

    # Set Accept header for HTML to match browser routes
    {:ok, conn: put_req_header(conn, "accept", "text/html")}
  end

  describe "GET /packages" do
    test "lists packages with default sort", %{conn: conn} do
      conn = get(conn, ~p"/packages")
      assert html_response(conn, 200) =~ "Packages"
      assert html_response(conn, 200) =~ "phoenix"
      assert html_response(conn, 200) =~ "ecto"
    end

    test "filters by search term", %{conn: conn} do
      conn = get(conn, ~p"/packages?search=phoenix")
      response = html_response(conn, 200)
      assert response =~ "phoenix"
      # When searching, count is displayed with "packages matching" format
      assert response =~ ~r/>1<\/span>\s*packages matching/
    end

    test "filters by search term in description", %{conn: conn} do
      conn = get(conn, ~p"/packages?search=database")
      response = html_response(conn, 200)
      assert response =~ "ecto"
    end

    test "sorts by name", %{conn: conn} do
      conn = get(conn, ~p"/packages?sort=name")
      response = html_response(conn, 200)
      assert response =~ "Name (A-Z)"
    end

    test "filters by letter", %{conn: conn} do
      conn = get(conn, ~p"/packages?letter=P")
      response = html_response(conn, 200)
      assert response =~ "phoenix"
      assert response =~ "plug"
      # The main package list should not contain ecto (starts with E, not P)
      # Note: ecto might still appear in trend sections, so we check specifically
      # that the filtered count is 2 (phoenix and plug)
      assert response =~ ">2</span> packages"
    end

    test "paginates results", %{conn: conn} do
      # Create more packages for pagination
      for i <- 1..35 do
        Packages.create_package("pkg#{i}", "hexpm", %{"description" => "Package #{i}"})
      end

      conn = get(conn, ~p"/packages?page=2")
      assert html_response(conn, 200) =~ "Packages"
    end

    test "shows empty state when no packages match", %{conn: conn} do
      conn = get(conn, ~p"/packages?search=nonexistent_package_xyz")
      response = html_response(conn, 200)
      assert response =~ "No packages found"
    end

    test "displays trend sections", %{conn: conn} do
      conn = get(conn, ~p"/packages")
      response = html_response(conn, 200)
      assert response =~ "Most Downloaded"
      assert response =~ "Recently Updated"
      assert response =~ "New Packages"
    end
  end

  describe "GET /packages/:name" do
    test "shows package details", %{conn: conn} do
      conn = get(conn, ~p"/packages/phoenix")
      response = html_response(conn, 200)
      assert response =~ "phoenix"
      assert response =~ "Web framework for Elixir"
      assert response =~ "Installation"
    end

    test "shows versions list", %{conn: conn} do
      # Add a release
      Packages.create_release("phoenix", "1.7.0", %{"app" => "phoenix"}, %{}, "tarball")

      conn = get(conn, ~p"/packages/phoenix")
      response = html_response(conn, 200)
      assert response =~ "Versions"
      assert response =~ "1.7.0"
    end

    test "shows dependencies section", %{conn: conn} do
      # Add a release with dependencies
      requirements = %{
        "plug" => %{"requirement" => "~> 1.14", "optional" => false}
      }

      Packages.create_release("phoenix", "1.7.0", %{"app" => "phoenix"}, requirements, "tarball")

      conn = get(conn, ~p"/packages/phoenix")
      response = html_response(conn, 200)
      assert response =~ "Dependencies"
      assert response =~ "plug"
    end

    test "returns 404 for non-existent package", %{conn: conn} do
      conn = get(conn, ~p"/packages/nonexistent_package_xyz")
      response = html_response(conn, 404)
      assert response =~ "Package Not Found"
      assert response =~ "nonexistent_package_xyz"
    end
  end

  describe "legacy redirects" do
    test "GET /browse redirects to /packages", %{conn: conn} do
      conn = get(conn, "/browse")
      assert redirected_to(conn) == "/packages"
    end

    test "GET /package/:name redirects to /packages/:name", %{conn: conn} do
      conn = get(conn, "/package/phoenix")
      assert redirected_to(conn) == "/packages/phoenix"
    end
  end
end

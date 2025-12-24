defmodule HexHub.PackagesTest do
  use ExUnit.Case, async: false

  alias HexHub.Packages

  setup do
    Packages.reset_test_store()

    # Ensure storage directories exist for docs upload tests
    File.mkdir_p!("priv/test_storage/packages")
    File.mkdir_p!("priv/test_storage/docs")

    # Ensure storage is configured correctly
    Application.put_env(:hex_hub, :storage_type, :local)
    Application.put_env(:hex_hub, :storage_path, "priv/test_storage")

    :ok
  end

  describe "package management" do
    test "create_package/4 creates a new package" do
      name = "test_package"
      repository_name = "hexpm"
      meta = %{"description" => "A test package", "licenses" => ["MIT"]}

      assert {:ok, package} = Packages.create_package(name, repository_name, meta)
      assert package.name == name
      assert package.repository_name == repository_name
      assert package.meta == meta
      assert package.private == false
      assert package.downloads == 0
    end

    test "get_package/1 retrieves package by name" do
      name = "test_package"
      repository_name = "hexpm"
      meta = %{"description" => "A test package"}

      {:ok, created} = Packages.create_package(name, repository_name, meta)

      assert {:ok, package} = Packages.get_package(name)
      assert package.name == created.name
      assert package.repository_name == created.repository_name
    end

    test "get_package/1 returns error for non-existent package" do
      assert {:error, :not_found} = Packages.get_package("nonexistent")
    end

    test "list_packages/0 returns all packages" do
      {:ok, _} = Packages.create_package("package1", "hexpm", %{"description" => "Package 1"})
      {:ok, _} = Packages.create_package("package2", "hexpm", %{"description" => "Package 2"})

      assert {:ok, packages, _total} = Packages.list_packages()
      assert length(packages) == 2
    end

    test "list_packages/1 with :sort option sorts correctly" do
      {:ok, _} = Packages.create_package("alpha", "hexpm", %{"description" => "Alpha"})
      Process.sleep(10)
      {:ok, _} = Packages.create_package("zebra", "hexpm", %{"description" => "Zebra"})

      # Sort by name
      assert {:ok, packages, _total} = Packages.list_packages(sort: :name)
      assert hd(packages).name == "alpha"

      # Sort by recently created (newest first)
      assert {:ok, packages, _total} = Packages.list_packages(sort: :recently_created)
      assert hd(packages).name == "zebra"
    end

    test "list_packages/1 with :letter option filters by first letter" do
      {:ok, _} = Packages.create_package("alpha", "hexpm", %{"description" => "Alpha"})
      {:ok, _} = Packages.create_package("beta", "hexpm", %{"description" => "Beta"})
      {:ok, _} = Packages.create_package("another", "hexpm", %{"description" => "Another"})

      # Filter by letter A
      assert {:ok, packages, total} = Packages.list_packages(letter: "A")
      assert total == 2
      assert Enum.all?(packages, fn p -> String.starts_with?(p.name, "a") end)

      # Filter by letter B
      assert {:ok, packages, total} = Packages.list_packages(letter: "B")
      assert total == 1
      assert hd(packages).name == "beta"
    end

    test "list_packages/1 with :search option filters by name/description" do
      {:ok, _} = Packages.create_package("phoenix", "hexpm", %{"description" => "Web framework"})
      {:ok, _} = Packages.create_package("ecto", "hexpm", %{"description" => "Database wrapper"})

      # Search by name
      assert {:ok, packages, total} = Packages.list_packages(search: "phoenix")
      assert total == 1
      assert hd(packages).name == "phoenix"

      # Search by description
      assert {:ok, packages, total} = Packages.list_packages(search: "database")
      assert total == 1
      assert hd(packages).name == "ecto"
    end

    test "list_packages/1 with pagination" do
      for i <- 1..5 do
        {:ok, _} = Packages.create_package("pkg#{i}", "hexpm", %{"description" => "Package #{i}"})
      end

      assert {:ok, packages, total} = Packages.list_packages(page: 1, per_page: 2)
      assert length(packages) == 2
      assert total == 5

      assert {:ok, packages, _total} = Packages.list_packages(page: 3, per_page: 2)
      assert length(packages) == 1
    end

    test "create_package/4 validates package name format" do
      assert {:error, _reason} = Packages.create_package("", "hexpm", %{"description" => "Test"})

      assert {:error, _reason} =
               Packages.create_package("Invalid", "hexpm", %{"description" => "Test"})

      assert {:error, _reason} =
               Packages.create_package("123invalid", "hexpm", %{"description" => "Test"})
    end
  end

  describe "trend queries" do
    test "list_most_downloaded/1 returns top packages by downloads" do
      # Create packages (downloads default to 0, but ordering should work)
      {:ok, _} = Packages.create_package("popular", "hexpm", %{"description" => "Popular package"})
      {:ok, _} = Packages.create_package("less_popular", "hexpm", %{"description" => "Less popular"})

      packages = Packages.list_most_downloaded(5)
      assert is_list(packages)
    end

    test "list_recently_updated/1 returns recently updated packages" do
      {:ok, _} = Packages.create_package("old_pkg", "hexpm", %{"description" => "Old"})
      Process.sleep(10)
      {:ok, _} = Packages.create_package("new_pkg", "hexpm", %{"description" => "New"})

      packages = Packages.list_recently_updated(5)
      assert is_list(packages)
      assert length(packages) == 2
      # Newest should be first
      assert hd(packages).name == "new_pkg"
    end

    test "list_new_packages/1 returns newest packages by creation date" do
      {:ok, _} = Packages.create_package("first", "hexpm", %{"description" => "First"})
      Process.sleep(10)
      {:ok, _} = Packages.create_package("second", "hexpm", %{"description" => "Second"})

      packages = Packages.list_new_packages(5)
      assert is_list(packages)
      assert length(packages) == 2
      # Newest should be first
      assert hd(packages).name == "second"
    end

    test "list_most_downloaded/1 respects limit" do
      for i <- 1..10 do
        {:ok, _} = Packages.create_package("pkg#{i}", "hexpm", %{"description" => "Package #{i}"})
      end

      packages = Packages.list_most_downloaded(3)
      assert length(packages) == 3
    end
  end

  describe "release management" do
    test "create_release/5 creates a new release" do
      package_name = "test_package"
      version = "1.0.0"
      meta = %{"app" => "test_package", "description" => "Test package"}
      requirements = %{}
      tarball = "fake_tarball_content"

      # Create package first
      {:ok, _} = Packages.create_package(package_name, "hexpm", %{"description" => "Test"})

      assert {:ok, release} =
               Packages.create_release(package_name, version, meta, requirements, tarball)

      assert release.package_name == package_name
      assert release.version == version
      assert release.has_docs == false
      assert release.downloads == 0
    end

    test "get_release/2 retrieves release" do
      package_name = "test_package"
      version = "1.0.0"
      meta = %{"app" => "test_package"}
      requirements = %{}
      tarball = "fake_tarball_content"

      {:ok, _} = Packages.create_package(package_name, "hexpm", %{"description" => "Test"})
      {:ok, created} = Packages.create_release(package_name, version, meta, requirements, tarball)

      assert {:ok, release} = Packages.get_release(package_name, version)
      assert release.package_name == created.package_name
      assert release.version == created.version
    end

    test "list_releases/1 returns all releases for a package" do
      package_name = "test_package_#{System.unique_integer([:positive])}"
      {:ok, _} = Packages.create_package(package_name, "hexpm", %{"description" => "Test"})

      {:ok, _} =
        Packages.create_release(
          package_name,
          "1.0.0",
          %{"app" => "test_package"},
          %{},
          "tarball1"
        )

      {:ok, _} =
        Packages.create_release(
          package_name,
          "1.1.0",
          %{"app" => "test_package"},
          %{},
          "tarball2"
        )

      assert {:ok, releases} = Packages.list_releases(package_name)
      assert length(releases) == 2
    end

    test "create_release/5 validates version format" do
      package_name = "test_package"
      {:ok, _} = Packages.create_package(package_name, "hexpm", %{"description" => "Test"})

      assert {:error, _reason} =
               Packages.create_release(package_name, "invalid", %{}, %{}, "tarball")
    end

    test "upload_docs/3 and delete_docs/2 work correctly" do
      package_name = "test_package"
      version = "1.0.0"
      {:ok, _} = Packages.create_package(package_name, "hexpm", %{"description" => "Test"})

      {:ok, _} =
        Packages.create_release(package_name, version, %{"app" => "test_package"}, %{}, "tarball")

      # Upload docs
      assert {:ok, _release} = Packages.upload_docs(package_name, version, "docs_tarball")
      assert {:ok, updated} = Packages.get_release(package_name, version)
      assert updated.has_docs == true

      # Delete docs
      assert {:ok, release} = Packages.delete_docs(package_name, version)
      assert release.has_docs == false
      assert {:ok, updated} = Packages.get_release(package_name, version)
      assert updated.has_docs == false
    end
  end
end

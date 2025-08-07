defmodule HexHub.PackagesTest do
  use ExUnit.Case

  alias HexHub.Packages

  setup do
    Packages.reset_test_store()
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

      assert {:ok, packages} = Packages.list_packages()
      assert length(packages) == 2
    end

    test "create_package/4 validates package name format" do
      assert {:error, _reason} = Packages.create_package("", "hexpm", %{"description" => "Test"})

      assert {:error, _reason} =
               Packages.create_package("Invalid", "hexpm", %{"description" => "Test"})

      assert {:error, _reason} =
               Packages.create_package("123invalid", "hexpm", %{"description" => "Test"})
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
      assert {:ok, release} = Packages.upload_docs(package_name, version, "docs_tarball")
      assert release.has_docs == true
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

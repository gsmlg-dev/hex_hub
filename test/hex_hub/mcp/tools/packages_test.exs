defmodule HexHub.MCP.Tools.PackagesTest do
  use ExUnit.Case, async: true

  alias HexHub.MCP.Tools.Packages

  # Mock the HexHub.Packages module for testing
  defmodule MockPackages do
    def search_packages(query, opts) do
      {:ok, [
        %{
          name: "ecto",
          repository: "hexpm",
          meta: ~s({"description": "Database wrapper for Elixir"}),
          downloads: 1000000,
          inserted_at: DateTime.utc_now(),
          updated_at: DateTime.utc_now()
        }
      ]}
    end

    def get_package(name, repository \\ nil) do
      {:ok, %{
        name: name,
        repository: repository || "hexpm",
        meta: ~s({"description": "A test package"}),
        downloads: 1000,
        inserted_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now()
      }}
    end

    def list_packages(opts) do
      {:ok, [
        %{
          name: "package1",
          repository: "hexpm",
          meta: ~s({"description": "First package"}),
          downloads: 500,
          inserted_at: DateTime.utc_now(),
          updated_at: DateTime.utc_now()
        }
      ]}
    end

    def list_releases(name) do
      {:ok, [
        %{
          package_name: name,
          version: "1.0.0",
          has_docs: true,
          inserted_at: DateTime.utc_now(),
          retirement: nil
        }
      ]}
    end

    def get_release(name, version) do
      {:ok, %{
        package_name: name,
        version: version,
        metadata: ~s({"elixir": "~> 1.12"}),
        requirements: ~s({"jason": "~> 1.0"}),
        has_docs: true,
        inserted_at: DateTime.utc_now(),
        retirement: nil
      }}
    end
  end

  # Override the real module with mock for testing
  import ExUnit.CaptureLog
  import Mox

  setup :set_mox_global

  setup do
    Mox.stub_with(HexHub.PackagesMock, MockPackages)
    :ok
  end

  describe "search_packages/1" do
    test "searches packages with query" do
      args = %{"query" => "ecto"}

      assert {:ok, result} = Packages.search_packages(args)

      assert %{
        "packages" => packages,
        "total" => total,
        "query" => query,
        "filters" => filters
      } = result

      assert length(packages) == 1
      assert total == 1
      assert query == "ecto"
      assert filters == %{}

      package = hd(packages)
      assert package["name"] == "ecto"
      assert package["repository"] == "hexpm"
      assert is_map(package["description"])
      assert package["downloads"] == 1000000
    end

    test "searches packages with limit and filters" do
      args = %{
        "query" => "ecto",
        "limit" => 5,
        "filters" => %{"repository" => "hexpm"}
      }

      assert {:ok, result} = Packages.search_packages(args)
      assert result["limit"] == nil  # Not implemented in mock
      assert result["filters"] == %{"repository" => "hexpm"}
    end

    test "returns error for missing query" do
      args = %{}

      assert {:error, :missing_query_parameter} = Packages.search_packages(args)
    end
  end

  describe "get_package/1" do
    test "gets package information" do
      args = %{"name" => "ecto"}

      assert {:ok, result} = Packages.get_package(args)

      assert %{
        "package" => package,
        "releases" => releases,
        "total_releases" => total_releases,
        "latest_version" => latest_version,
        "repository" => repository
      } = result

      assert package["name"] == "ecto"
      assert length(releases) == 1
      assert total_releases == 1
      assert latest_version == "1.0.0"
      assert repository["name"] == "hexpm"
    end

    test "gets package with specific repository" do
      args = %{
        "name" => "ecto",
        "repository" => "private_repo"
      }

      assert {:ok, result} = Packages.get_package(args)
      assert result["package"]["name"] == "ecto"
    end

    test "returns error for missing package name" do
      args = %{}

      assert {:error, :missing_package_name} = Packages.get_package(args)
    end
  end

  describe "list_packages/1" do
    test "lists packages with default options" do
      args = %{}

      assert {:ok, result} = Packages.list_packages(args)

      assert %{
        "packages" => packages,
        "pagination" => pagination,
        "sort" => sort,
        "order" => order
      } = result

      assert length(packages) == 1
      assert pagination["page"] == 1
      assert pagination["per_page"] == 20
      assert sort == "name"
      assert order == "asc"
    end

    test "lists packages with custom options" do
      args = %{
        "page" => 2,
        "per_page" => 10,
        "sort" => "downloads",
        "order" => "desc"
      }

      assert {:ok, result} = Packages.list_packages(args)

      assert result["pagination"]["page"] == 2
      assert result["pagination"]["per_page"] == 10
      assert result["sort"] == "downloads"
      assert result["order"] == "desc"
    end
  end

  describe "get_package_metadata/1" do
    test "gets package metadata" do
      args = %{
        "name" => "ecto",
        "version" => "1.0.0"
      }

      assert {:ok, result} = Packages.get_package_metadata(args)

      assert %{
        "name" => name,
        "version" => version,
        "metadata" => metadata,
        "requirements" => requirements,
        "has_docs" => has_docs,
        "retirement_info" => retirement_info
      } = result

      assert name == "ecto"
      assert version == "1.0.0"
      assert metadata["elixir"] == "~> 1.12"
      assert requirements["jason"] == "~> 1.0"
      assert has_docs == true
      assert retirement_info == nil
    end

    test "gets package metadata for latest version" do
      args = %{"name" => "ecto"}

      assert {:ok, result} = Packages.get_package_metadata(args)
      assert result["name"] == "ecto"
      assert result["version"] == "1.0.0"
    end

    test "returns error for missing package name" do
      args = %{}

      assert {:error, :missing_package_name} = Packages.get_package_metadata(args)
    end
  end

  describe "validation functions" do
    test "validate_search_args/1" do
      valid_args = %{"query" => "ecto", "limit" => 10}
      assert :ok = Packages.validate_search_args(valid_args)

      invalid_args = %{"limit" => 10}
      assert {:error, {:missing_required_fields, ["query"]}} = Packages.validate_search_args(invalid_args)
    end

    test "validate_get_package_args/1" do
      valid_args = %{"name" => "ecto", "repository" => "hexpm"}
      assert :ok = Packages.validate_get_package_args(valid_args)

      invalid_args = %{"repository" => "hexpm"}
      assert {:error, {:missing_required_fields, ["name"]}} = Packages.validate_get_package_args(invalid_args)
    end

    test "validate_metadata_args/1" do
      valid_args = %{"name" => "ecto", "version" => "1.0.0"}
      assert :ok = Packages.validate_metadata_args(valid_args)

      invalid_args = %{"version" => "1.0.0"}
      assert {:error, {:missing_required_fields, ["name"]}} = Packages.validate_metadata_args(invalid_args)
    end
  end

  describe "statistics and monitoring" do
    test "get_package_stats/0 returns statistics" do
      stats = Packages.get_package_stats()

      assert %{
        total_packages: _,
        total_releases: _,
        total_downloads: _,
        recent_packages: _,
        packages_with_docs: _
      } = stats

      assert is_number(stats.total_packages)
      assert is_number(stats.total_releases)
    end

    test "log_package_operation/3 logs telemetry event" do
      # This would test telemetry event emission
      # For now, just ensure the function doesn't crash
      assert :ok = Packages.log_package_operation("search", "ecto", %{})
    end
  end

  describe "error handling" do
    test "handles mock errors gracefully" do
      # Test with a failing mock
      defmodule FailingMockPackages do
        def search_packages(_query, _opts), do: {:error, :database_error}
      end

      Mox.stub_with(HexHub.PackagesMock, FailingMockPackages)

      args = %{"query" => "ecto"}

      assert capture_log(fn ->
        assert {:error, :database_error} = Packages.search_packages(args)
      end) =~ "MCP package search failed"
    end
  end
end
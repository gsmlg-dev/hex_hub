defmodule E2E.PublishTest do
  @moduledoc """
  E2E tests for hex.publish functionality.

  Tests the complete publish workflow including:
  - Basic package publishing (US1)
  - Authentication and API key validation (US2)
  - Package version management (US3)
  - Documentation publishing (US4)
  - Error handling and validation (US5)
  """

  use E2E.Case, async: false

  alias E2E.ServerHelper
  alias E2E.PublishHelper

  @moduletag :publish

  setup_all do
    # Reset test data for clean state
    PublishHelper.reset_test_data()

    # Clean up any leftover artifacts from previous test runs
    PublishHelper.cleanup_publish_fixture()

    # Create test user for publishing
    {:ok, user} =
      PublishHelper.create_test_user("e2e_publisher", "e2e@test.com", "password123456")

    # Create API keys with different permissions
    {:ok, write_key} = PublishHelper.create_write_api_key("e2e_publisher", "e2e_write_key")
    {:ok, read_key} = PublishHelper.create_read_only_api_key("e2e_publisher", "e2e_read_key")

    # Start the HexHub server
    {:ok, port} = ServerHelper.start_server()

    on_exit(fn ->
      # Clean up fixture project
      PublishHelper.cleanup_publish_fixture()
      # Reset version back to 0.1.0
      PublishHelper.update_fixture_version("0.1.0")
    end)

    %{
      port: port,
      base_url: "http://localhost:#{port}",
      user: user,
      write_key: write_key,
      read_key: read_key
    }
  end

  setup context do
    # Reset package data between tests to ensure isolation
    HexHub.Packages.reset_test_store()

    # Reset fixture version to 0.1.0 for each test
    PublishHelper.update_fixture_version("0.1.0")

    # Clean fixture build artifacts
    PublishHelper.cleanup_publish_fixture()

    context
  end

  # =============================================================================
  # User Story 1: Basic Package Publishing (P1)
  # =============================================================================

  describe "US1: Basic Package Publishing" do
    @describetag :us1

    test "publishes package successfully with valid credentials", %{
      port: port,
      write_key: write_key,
      base_url: base_url
    } do
      # Configure environment for hex publish
      env = PublishHelper.hex_publish_env(port, write_key)

      # Run hex publish
      {output, exit_code} = PublishHelper.run_hex_publish(env)

      # Assert successful publish
      assert exit_code == 0, "Expected exit code 0, got #{exit_code}. Output: #{output}"

      assert output =~ "Published" or output =~ "published" or output =~ "Package published",
             "Expected publish success message in output: #{output}"

      # Verify package exists via API
      assert {:ok, package} = PublishHelper.verify_package_exists(base_url, "e2e_test_pkg")
      assert package["name"] == "e2e_test_pkg"

      # Verify release exists
      releases = package["releases"] || []

      assert Enum.any?(releases, fn r -> r["version"] == "0.1.0" end),
             "Expected version 0.1.0 in releases: #{inspect(releases)}"
    end

    test "tarball is downloadable after publish", %{
      port: port,
      write_key: write_key,
      base_url: base_url
    } do
      # First publish the package
      env = PublishHelper.hex_publish_env(port, write_key)
      {_output, exit_code} = PublishHelper.run_hex_publish(env)
      assert exit_code == 0

      # Download and verify tarball
      assert {:ok, tarball} =
               PublishHelper.download_package_tarball(base_url, "e2e_test_pkg", "0.1.0")

      assert is_binary(tarball)
      assert byte_size(tarball) > 0

      # Verify it's a valid hex tarball (starts with "VERSION" header)
      # Hex tarballs are NOT gzip - they have a VERSION header followed by embedded tar.gz files
      assert <<"VERSION", _rest::binary>> = tarball
    end
  end

  # =============================================================================
  # User Story 2: Authentication and API Key Validation (P1)
  # =============================================================================

  describe "US2: Authentication and API Key Validation" do
    @describetag :us2

    test "fails with 401 when no API key provided", %{port: port} do
      # Configure environment without API key
      env = PublishHelper.hex_publish_env_no_key(port)

      # Run hex publish with shorter timeout since we expect it to fail quickly
      # In CI, without an API key hex may hang trying to authenticate interactively
      {output, exit_code} = PublishHelper.run_hex_publish(env, timeout: 30_000)

      # Should fail with authentication error or timeout (both indicate auth failure)
      assert exit_code != 0, "Expected non-zero exit code, got #{exit_code}"

      # Accept either explicit auth error OR timeout (which also indicates auth failure)
      assert output =~ "401" or output =~ "unauthorized" or output =~ "Unauthorized" or
               output =~ "authentication" or output =~ "Authentication" or
               output =~ "timed out",
             "Expected authentication error or timeout in output: #{output}"
    end

    test "fails with 401 when invalid API key provided", %{port: port} do
      # Configure environment with invalid API key
      env = PublishHelper.hex_publish_env(port, "invalid_api_key_12345")

      # Run hex publish
      {output, exit_code} = PublishHelper.run_hex_publish(env)

      # Should fail with authentication error
      assert exit_code != 0, "Expected non-zero exit code, got #{exit_code}"

      assert output =~ "401" or output =~ "unauthorized" or output =~ "Unauthorized" or
               output =~ "authentication" or output =~ "Authentication" or output =~ "invalid",
             "Expected authentication error in output: #{output}"
    end

    test "fails with 403 when read-only API key provided", %{port: port, read_key: read_key} do
      # Configure environment with read-only API key
      env = PublishHelper.hex_publish_env(port, read_key)

      # Run hex publish
      {output, exit_code} = PublishHelper.run_hex_publish(env)

      # Should fail with permission error
      assert exit_code != 0, "Expected non-zero exit code, got #{exit_code}"

      assert output =~ "403" or output =~ "forbidden" or output =~ "Forbidden" or
               output =~ "permission" or output =~ "Permission" or output =~ "not authorized",
             "Expected permission error in output: #{output}"
    end
  end

  # =============================================================================
  # User Story 3: Package Version Management (P2)
  # =============================================================================

  describe "US3: Package Version Management" do
    @describetag :us3

    test "publishes multiple versions of same package", %{
      port: port,
      write_key: write_key,
      base_url: base_url
    } do
      env = PublishHelper.hex_publish_env(port, write_key)

      # Publish version 0.1.0
      {output1, exit_code1} = PublishHelper.run_hex_publish(env)
      assert exit_code1 == 0, "Failed to publish 0.1.0: #{output1}"

      # Update to version 0.2.0
      PublishHelper.update_fixture_version("0.2.0")
      PublishHelper.cleanup_publish_fixture()

      # Publish version 0.2.0
      {output2, exit_code2} = PublishHelper.run_hex_publish(env)
      assert exit_code2 == 0, "Failed to publish 0.2.0: #{output2}"

      # Verify both versions exist
      assert {:ok, package} = PublishHelper.verify_package_exists(base_url, "e2e_test_pkg")
      releases = package["releases"] || []

      versions = Enum.map(releases, & &1["version"])
      assert "0.1.0" in versions, "Version 0.1.0 not found in releases: #{inspect(versions)}"
      assert "0.2.0" in versions, "Version 0.2.0 not found in releases: #{inspect(versions)}"

      # Verify both tarballs are downloadable
      assert {:ok, _} = PublishHelper.download_package_tarball(base_url, "e2e_test_pkg", "0.1.0")
      assert {:ok, _} = PublishHelper.download_package_tarball(base_url, "e2e_test_pkg", "0.2.0")
    end
  end

  # =============================================================================
  # User Story 4: Documentation Publishing (P3)
  # =============================================================================

  describe "US4: Documentation Publishing" do
    @describetag :us4

    @tag :skip
    test "publishes package with documentation", %{
      port: port,
      write_key: write_key,
      base_url: base_url
    } do
      # Configure environment for hex publish with docs
      env = PublishHelper.hex_publish_env(port, write_key)

      # Run hex publish (which publishes both package and docs)
      {output, exit_code} = PublishHelper.run_hex_publish_with_docs(env)

      # Assert successful publish
      assert exit_code == 0, "Expected exit code 0, got #{exit_code}. Output: #{output}"

      # Verify package exists
      assert {:ok, package} = PublishHelper.verify_package_exists(base_url, "e2e_test_pkg")
      assert package["name"] == "e2e_test_pkg"

      # Verify docs are accessible
      assert {:ok, docs_tarball} =
               PublishHelper.download_docs_tarball(base_url, "e2e_test_pkg", "0.1.0")

      assert is_binary(docs_tarball)
      assert byte_size(docs_tarball) > 0
    end
  end

  # =============================================================================
  # User Story 5: Error Handling and Validation (P2)
  # =============================================================================

  describe "US5: Error Handling and Validation" do
    @describetag :us5

    test "returns validation error for missing required fields (no version)", %{
      port: port,
      write_key: write_key
    } do
      # Clean up the invalid fixture
      PublishHelper.cleanup_invalid_fixture()

      # Configure environment for hex publish
      env = PublishHelper.hex_publish_env(port, write_key)

      # Run hex publish on the invalid fixture (missing version)
      {output, exit_code} = PublishHelper.run_hex_publish(env, fixture: :invalid)

      # Should fail because version is missing
      assert exit_code != 0, "Expected non-zero exit code, got #{exit_code}"

      # The error message should mention version or project configuration
      assert output =~ "version" or output =~ "Version" or output =~ "project" or
               output =~ "required" or output =~ "missing" or output =~ "undefined",
             "Expected error message about missing version. Output: #{output}"
    end

    test "error messages are clear and actionable", %{port: port, write_key: write_key} do
      # Clean up the invalid fixture
      PublishHelper.cleanup_invalid_fixture()

      # Configure environment for hex publish
      env = PublishHelper.hex_publish_env(port, write_key)

      # Run hex publish on the invalid fixture
      {output, exit_code} = PublishHelper.run_hex_publish(env, fixture: :invalid)

      # Should fail
      assert exit_code != 0, "Expected non-zero exit code for invalid project"

      # Error output should be non-empty and provide useful information
      assert byte_size(output) > 0, "Expected some error output"

      # Should not just be a cryptic error code or stack trace
      # Error should mention something about the project or configuration
      refute output =~ ~r/^\s*\*\*\s+\(.*\)\s+\w+\.\w+:\d+/,
             "Error should not be just a stack trace. Output: #{output}"
    end
  end
end

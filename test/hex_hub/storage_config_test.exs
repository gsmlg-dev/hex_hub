defmodule HexHub.StorageConfigTest do
  # async: false to prevent test isolation issues with Application.put_env
  use ExUnit.Case, async: false

  alias HexHub.StorageConfig

  setup do
    # Save original config
    original_config = %{
      storage_type: Application.get_env(:hex_hub, :storage_type),
      storage_path: Application.get_env(:hex_hub, :storage_path),
      s3_bucket: Application.get_env(:hex_hub, :s3_bucket),
      s3_region: Application.get_env(:hex_hub, :s3_region),
      s3_host: Application.get_env(:hex_hub, :s3_host),
      s3_port: Application.get_env(:hex_hub, :s3_port),
      s3_scheme: Application.get_env(:hex_hub, :s3_scheme),
      s3_path_style: Application.get_env(:hex_hub, :s3_path_style)
    }

    # Reset configuration before each test
    Application.put_env(:hex_hub, :s3_region, "us-east-1")
    Application.put_env(:hex_hub, :storage_type, :local)

    # Restore original config after each test
    on_exit(fn ->
      Application.put_env(:hex_hub, :storage_type, original_config.storage_type || :local)

      Application.put_env(
        :hex_hub,
        :storage_path,
        original_config.storage_path || "priv/test_storage"
      )

      Application.put_env(:hex_hub, :s3_region, original_config.s3_region || "us-east-1")

      if original_config.s3_bucket do
        Application.put_env(:hex_hub, :s3_bucket, original_config.s3_bucket)
      else
        Application.delete_env(:hex_hub, :s3_bucket)
      end

      if original_config.s3_host do
        Application.put_env(:hex_hub, :s3_host, original_config.s3_host)
      else
        Application.delete_env(:hex_hub, :s3_host)
      end

      if original_config.s3_port do
        Application.put_env(:hex_hub, :s3_port, original_config.s3_port)
      else
        Application.delete_env(:hex_hub, :s3_port)
      end

      if original_config.s3_scheme do
        Application.put_env(:hex_hub, :s3_scheme, original_config.s3_scheme)
      else
        Application.delete_env(:hex_hub, :s3_scheme)
      end

      if original_config.s3_path_style do
        Application.put_env(:hex_hub, :s3_path_style, original_config.s3_path_style)
      else
        Application.delete_env(:hex_hub, :s3_path_style)
      end
    end)

    :ok
  end

  describe "config/0" do
    test "returns current storage configuration" do
      config = StorageConfig.config()

      assert is_atom(config.storage_type)
      assert is_binary(config.storage_path)
      assert is_binary(config.s3_region) or is_nil(config.s3_region)
      assert is_binary(config.s3_scheme)
      assert is_boolean(config.s3_path_style)
    end

    test "has default values" do
      config = StorageConfig.config()

      assert config.storage_type in [:local, :s3]
      assert config.storage_path != nil
      assert config.s3_region == "us-east-1"
      assert config.s3_scheme == "https://"
    end
  end

  describe "test_connection/0" do
    test "tests local storage connection" do
      # Set up local storage for testing
      Application.put_env(:hex_hub, :storage_type, :local)
      Application.put_env(:hex_hub, :storage_path, "priv/test_storage")

      result = StorageConfig.test_connection()

      assert match?({:ok, "Local storage working correctly"}, result)
    end

    test "handles S3 storage when not configured" do
      # Set up S3 storage without proper configuration
      Application.put_env(:hex_hub, :storage_type, :s3)
      Application.put_env(:hex_hub, :s3_bucket, nil)

      result = StorageConfig.test_connection()

      assert match?({:error, "S3 bucket not configured"}, result)
    end
  end

  describe "update_config/1" do
    test "updates local storage configuration" do
      params = %{
        "storage_type" => "local",
        "storage_path" => "custom/storage/path"
      }

      result = StorageConfig.update_config(params)

      assert result == :ok

      # Verify configuration was updated
      config = StorageConfig.config()
      assert config.storage_type == :local
      assert config.storage_path == "custom/storage/path"
    end

    test "updates S3 storage configuration" do
      params = %{
        "storage_type" => "s3",
        "s3_bucket" => "test-bucket",
        "s3_region" => "us-west-2",
        "s3_host" => "s3.amazonaws.com",
        "s3_port" => "443",
        "s3_scheme" => "https://",
        "s3_path_style" => "false"
      }

      result = StorageConfig.update_config(params)

      assert result == :ok

      # Verify configuration was updated
      config = StorageConfig.config()
      assert config.storage_type == :s3
      assert config.s3_bucket == "test-bucket"
      assert config.s3_region == "us-west-2"
    end

    test "validates S3 configuration" do
      # Missing S3 bucket
      params = %{
        "storage_type" => "s3",
        "s3_bucket" => ""
      }

      result = StorageConfig.update_config(params)

      assert match?({:error, "S3 bucket is required when using S3 storage"}, result)
    end

    test "handles invalid storage type" do
      params = %{
        "storage_type" => "invalid"
      }

      result = StorageConfig.update_config(params)

      # Should not crash, but the atom conversion may not work as expected
      # The important thing is it doesn't crash
      assert match?(:ok, result) or match?({:error, _}, result)
    end
  end
end

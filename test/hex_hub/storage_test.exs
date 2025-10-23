defmodule HexHub.StorageTest do
  use ExUnit.Case

  setup do
    # Ensure we start with local storage for each test
    Application.put_env(:hex_hub, :storage_type, :local)
    Application.put_env(:hex_hub, :storage_path, "priv/test_storage")

    # Create necessary subdirectories
    File.mkdir_p!("priv/test_storage/packages")
    File.mkdir_p!("priv/test_storage/docs")

    :ok
  end

  describe "local storage" do
    test "upload/3 stores package tarball" do
      key = "packages/test_package-1.0.0.tar.gz"
      content = "test package content"

      assert {:ok, ^key} = HexHub.Storage.upload(key, content)

      stored_path = Path.join(["priv/test_storage", key])
      assert File.exists?(stored_path)
      assert File.read!(stored_path) == content
    end

    test "upload/3 stores documentation tarball" do
      key = "docs/test_package-1.0.0.tar.gz"
      content = "test docs content"

      assert {:ok, ^key} = HexHub.Storage.upload(key, content)

      stored_path = Path.join(["priv/test_storage", key])
      assert File.exists?(stored_path)
      assert File.read!(stored_path) == content
    end

    test "download/1 retrieves package tarball" do
      key = "packages/test_package-1.0.0.tar.gz"
      content = "test package content"

      {:ok, ^key} = HexHub.Storage.upload(key, content)

      assert {:ok, ^content} = HexHub.Storage.download(key)
    end

    test "download/1 retrieves documentation tarball" do
      key = "docs/test_package-1.0.0.tar.gz"
      content = "test docs content"

      {:ok, ^key} = HexHub.Storage.upload(key, content)

      assert {:ok, ^content} = HexHub.Storage.download(key)
    end

    test "delete/1 removes package tarball" do
      key = "packages/test_package-1.0.0.tar.gz"
      content = "test package content"

      {:ok, ^key} = HexHub.Storage.upload(key, content)
      assert :ok = HexHub.Storage.delete(key)

      stored_path = Path.join(["priv/test_storage", key])
      refute File.exists?(stored_path)
    end

    test "delete/1 removes documentation tarball" do
      key = "docs/test_package-1.0.0.tar.gz"
      content = "test docs content"

      {:ok, ^key} = HexHub.Storage.upload(key, content)
      assert :ok = HexHub.Storage.delete(key)

      stored_path = Path.join(["priv/test_storage", key])
      refute File.exists?(stored_path)
    end

    test "returns error for non-existent file" do
      assert {:error, "File not found"} = HexHub.Storage.download("nonexistent/file.tar.gz")
    end

    test "generate_package_key/2 creates correct key" do
      assert "packages/phoenix-1.7.0.tar.gz" =
               HexHub.Storage.generate_package_key("phoenix", "1.7.0")
    end

    test "generate_docs_key/2 creates correct key" do
      assert "docs/phoenix-1.7.0.tar.gz" = HexHub.Storage.generate_docs_key("phoenix", "1.7.0")
    end
  end

  describe "S3 storage configuration" do
    test "returns error when bucket not configured" do
      # Temporarily remove bucket configuration
      Application.put_env(:hex_hub, :storage_type, :s3)
      Application.delete_env(:hex_hub, :s3_bucket)

      key = "packages/test_package-1.0.0.tar.gz"
      content = "test package content"

      assert {:error, "S3 bucket not configured"} = HexHub.Storage.upload(key, content)

      # Restore configuration
      Application.put_env(:hex_hub, :storage_type, :local)
    end

    test "builds S3 upload options correctly" do
      # Test the private function through the public interface
      Application.put_env(:hex_hub, :storage_type, :s3)
      Application.put_env(:hex_hub, :s3_bucket, "test-bucket")

      # This will fail due to no real S3, but we can check the error format
      key = "packages/test_package-1.0.0.tar.gz"
      content = "test package content"

      result = HexHub.Storage.upload(key, content)

      # Should get an S3 error, not a configuration error
      assert {:error, reason} = result
      assert String.contains?(reason, "S3 error")

      # Restore configuration
      Application.put_env(:hex_hub, :storage_type, :local)
      Application.delete_env(:hex_hub, :s3_bucket)
    end

    test "signed_url/2 returns error for local storage" do
      key = "packages/test_package-1.0.0.tar.gz"

      assert {:error, "Signed URLs not supported for local storage"} =
               HexHub.Storage.signed_url(key)
    end

    test "signed_url/2 returns error when bucket not configured" do
      Application.put_env(:hex_hub, :storage_type, :s3)
      Application.delete_env(:hex_hub, :s3_bucket)

      key = "packages/test_package-1.0.0.tar.gz"

      assert {:error, "S3 bucket not configured"} = HexHub.Storage.signed_url(key)

      # Restore configuration
      Application.put_env(:hex_hub, :storage_type, :local)
    end

    test "signed_url/2 generates URL for S3 storage" do
      Application.put_env(:hex_hub, :storage_type, :s3)
      Application.put_env(:hex_hub, :s3_bucket, "test-bucket")

      key = "packages/test_package-1.0.0.tar.gz"

      result = HexHub.Storage.signed_url(key)

      # Should get a signed URL (even with invalid credentials, the URL generation works)
      assert {:ok, url} = result
      assert String.contains?(url, "test-bucket")
      assert String.contains?(url, key)
      assert String.contains?(url, "X-Amz-Signature")

      # Restore configuration
      Application.put_env(:hex_hub, :storage_type, :local)
      Application.delete_env(:hex_hub, :s3_bucket)
    end
  end
end

defmodule HexHub.StorageTest do
  use ExUnit.Case

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
      assert "packages/phoenix-1.7.0.tar.gz" = HexHub.Storage.generate_package_key("phoenix", "1.7.0")
    end

    test "generate_docs_key/2 creates correct key" do
      assert "docs/phoenix-1.7.0.tar.gz" = HexHub.Storage.generate_docs_key("phoenix", "1.7.0")
    end
  end
end
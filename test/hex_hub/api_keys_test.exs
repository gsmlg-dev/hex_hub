defmodule HexHub.ApiKeysTest do
  use ExUnit.Case

  alias HexHub.{ApiKeys, Users}

  setup do
    ApiKeys.reset_test_store()
    Users.reset_test_store()
    # Create a test user
    case HexHub.Users.create_user("testuser", "test@example.com", "password123") do
      {:ok, _} -> :ok
      {:error, "Username already taken"} -> :ok
    end
    :ok
  end

  describe "API key management" do
    test "generate_key/3 creates a new API key" do
      assert {:ok, key} = ApiKeys.generate_key("test-key", "testuser", ["read", "write"])
      assert is_binary(key)
      assert String.length(key) == 64
    end

    test "generate_key/3 with default permissions" do
      assert {:ok, key} = ApiKeys.generate_key("test-key", "testuser")
      assert is_binary(key)
    end

    test "generate_key/3 returns error for non-existent user" do
      assert {:error, "User not found"} = ApiKeys.generate_key("test-key", "nonexistent", ["read"])
    end

    test "validate_key/1 validates correct key" do
      {:ok, key} = ApiKeys.generate_key("test-key", "testuser", ["read", "write"])
      assert {:ok, %{username: "testuser", permissions: ["read", "write"]}} = ApiKeys.validate_key(key)
    end

    test "validate_key/1 rejects invalid key" do
      assert {:error, :invalid_key} = ApiKeys.validate_key("invalid-key")
    end

    test "revoke_key/2 revokes an API key" do
      {:ok, key} = ApiKeys.generate_key("test-key", "testuser")
      assert :ok = ApiKeys.revoke_key("test-key", "testuser")
      assert {:error, :revoked_key} = ApiKeys.validate_key(key)
    end

    test "revoke_key/2 returns error for non-existent key" do
      assert {:error, "Key not found"} = ApiKeys.revoke_key("nonexistent", "testuser")
    end

    test "list_keys/1 lists all keys for a user" do
      {:ok, _} = ApiKeys.generate_key("key1", "testuser", ["read"])
      {:ok, _} = ApiKeys.generate_key("key2", "testuser", ["write"])
      
      assert {:ok, keys} = ApiKeys.list_keys("testuser")
      assert length(keys) == 2
    end

    test "has_permission?/3 checks permissions correctly" do
      {:ok, key} = ApiKeys.generate_key("test-key", "testuser", ["read", "write"])
      assert ApiKeys.has_permission?(key, "testuser", "read")
      refute ApiKeys.has_permission?(key, "testuser", "admin")
    end
  end
end
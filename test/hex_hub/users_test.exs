defmodule HexHub.UsersTest do
  use ExUnit.Case

  alias HexHub.Users

  setup do
    Users.reset_test_store()
    :ok
  end

  describe "user management" do
    test "create_user/3 creates a new user" do
      username = "testuser_#{System.unique_integer([:positive])}"
      email = "test#{System.unique_integer([:positive])}@example.com"
      password = "password123"

      assert {:ok, user} = Users.create_user(username, email, password)
      assert user.username == username
      assert user.email == email
      assert is_binary(user.password_hash)
    end

    test "create_user/3 validates username format" do
      _username = "testuser_#{System.unique_integer([:positive])}"
      email = "test#{System.unique_integer([:positive])}@example.com"
      assert {:error, _reason} = Users.create_user("a", email, "password123")
    end

    test "create_user/3 validates email format" do
      username = "testuser_#{System.unique_integer([:positive])}"
      assert {:error, _reason} = Users.create_user(username, "invalid", "password123")
    end

    test "create_user/3 validates password length" do
      username = "testuser_#{System.unique_integer([:positive])}"
      email = "test#{System.unique_integer([:positive])}@example.com"
      assert {:error, _reason} = Users.create_user(username, email, "123")
    end

    test "create_user/3 validates unique username" do
      username = "testuser_#{System.unique_integer([:positive])}"
      email1 = "test#{System.unique_integer([:positive])}@example.com"
      email2 = "test#{System.unique_integer([:positive])}@example.com"
      
      {:ok, _} = Users.create_user(username, email1, "password123")
      assert {:error, _reason} = Users.create_user(username, email2, "password123")
    end

    test "create_user/3 validates unique email" do
      username1 = "testuser_#{System.unique_integer([:positive])}"
      username2 = "testuser_#{System.unique_integer([:positive])}"
      email = "test#{System.unique_integer([:positive])}@example.com"
      
      {:ok, _} = Users.create_user(username1, email, "password123")
      assert {:error, _reason} = Users.create_user(username2, email, "password123")
    end

    test "get_user/1 retrieves user by username" do
      username = "testuser_#{System.unique_integer([:positive])}"
      email = "test#{System.unique_integer([:positive])}@example.com"
      password = "password123"

      {:ok, created_user} = Users.create_user(username, email, password)
      
      assert {:ok, user} = Users.get_user(username)
      assert user.username == created_user.username
      assert user.email == created_user.email
    end

    test "get_user/1 retrieves user by email" do
      username = "testuser_#{System.unique_integer([:positive])}"
      email = "test#{System.unique_integer([:positive])}@example.com"
      password = "password123"

      {:ok, created_user} = Users.create_user(username, email, password)
      
      assert {:ok, user} = Users.get_user(email)
      assert user.username == created_user.username
      assert user.email == created_user.email
    end

    test "get_user/1 returns error for non-existent user" do
      assert {:error, :not_found} = Users.get_user("nonexistent_#{System.unique_integer([:positive])}")
    end

    test "authenticate/2 returns user for valid credentials" do
      username = "testuser_#{System.unique_integer([:positive])}"
      email = "test#{System.unique_integer([:positive])}@example.com"
      password = "password123"

      {:ok, _} = Users.create_user(username, email, password)
      
      assert {:ok, user} = Users.authenticate(username, password)
      assert user.username == username
    end

    test "authenticate/2 returns error for invalid password" do
      username = "testuser_#{System.unique_integer([:positive])}"
      email = "test#{System.unique_integer([:positive])}@example.com"
      password = "password123"

      {:ok, _} = Users.create_user(username, email, password)
      
      assert {:error, :invalid_credentials} = Users.authenticate(username, "wrongpassword")
    end

    test "authenticate/2 returns error for non-existent user" do
      assert {:error, :invalid_credentials} = Users.authenticate("nonexistent_#{System.unique_integer([:positive])}", "password123")
    end

    test "update_password/2 updates user password" do
      username = "testuser_#{System.unique_integer([:positive])}"
      email = "test#{System.unique_integer([:positive])}@example.com"
      password = "password123"

      {:ok, user} = Users.create_user(username, email, password)
      assert {:ok, updated} = Users.update_password(username, "newpassword")
      assert updated.username == user.username
    end

    test "update_email/2 updates user email" do
      username = "testuser_#{System.unique_integer([:positive])}"
      email = "test#{System.unique_integer([:positive])}@example.com"
      password = "password123"

      {:ok, user} = Users.create_user(username, email, password)
      assert {:ok, updated} = Users.update_email(username, "new#{System.unique_integer([:positive])}@example.com")
      assert updated.username == user.username
    end
  end
end
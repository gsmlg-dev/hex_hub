defmodule HexHub.TestHelpers do
  @moduledoc """
  Helper functions for setting up test data.
  """

  alias HexHub.Users

  def create_user(attrs \\ %{}) do
    username = Map.get(attrs, :username) || "testuser#{System.unique_integer([:positive])}"
    email = Map.get(attrs, :email) || "test#{System.unique_integer([:positive])}@example.com"
    password = Map.get(attrs, :password) || "password123"
    
    {:ok, user} = Users.create_user(username, email, password)
    user
  end

  def create_package(attrs \\ %{}) do
    default_attrs = %{
      name: "test_package#{System.unique_integer([:positive])}",
      repository: "hexpm",
      description: "Test package",
      meta: %{
        app: "test_package",
        description: "Test package",
        version: "1.0.0"
      }
    }

    Map.merge(default_attrs, attrs)
  end

  def create_release(attrs \\ %{}) do
    default_attrs = %{
      name: "test_package",
      version: "1.0.0",
      requirements: %{},
      meta: %{
        app: "test_package",
        description: "Test package",
        version: "1.0.0"
      }
    }

    Map.merge(default_attrs, attrs)
  end
end
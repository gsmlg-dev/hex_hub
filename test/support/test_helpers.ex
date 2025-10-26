defmodule HexHub.TestHelpers do
  @moduledoc """
  Helper functions for setting up test data.
  """

  alias HexHub.{ApiKeys, Users}

  def create_user(attrs \\ %{}) do
    username = Map.get(attrs, :username) || "testuser#{System.unique_integer([:positive])}"
    email = Map.get(attrs, :email) || "test#{System.unique_integer([:positive])}@example.com"
    password = Map.get(attrs, :password) || "password123"

    case Users.create_user(username, email, password) do
      {:ok, user} ->
        user

      {:error, "Username already taken"} ->
        {:ok, user} = Users.get_user(username)
        user
    end
  end

  def setup_authenticated_user(attrs \\ %{}) do
    user = create_user(attrs)
    {:ok, api_key} = ApiKeys.generate_key("test-key", user.username)
    %{user: user, api_key: api_key}
  end

  def authenticated_conn(conn, api_key) do
    conn
    |> Plug.Conn.put_req_header("authorization", "Bearer #{api_key}")
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

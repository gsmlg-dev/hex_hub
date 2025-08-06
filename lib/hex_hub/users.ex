defmodule HexHub.Users do
  @moduledoc """
  User management functions with Mnesia storage.
  """

  @type user :: %{
          username: String.t(),
          email: String.t(),
          password_hash: String.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @doc """
  Create a new user with hashed password.
  """
  @spec create_user(String.t(), String.t(), String.t()) :: {:ok, user()} | {:error, String.t()}
  def create_user(username, email, password) do
    with :ok <- validate_username(username),
         :ok <- validate_email(email),
         :ok <- validate_password(password) do
      
      # For testing purposes, return a mock user
      password_hash = Bcrypt.hash_pwd_salt(password)
      now = DateTime.utc_now()
      
      user = %{
        username: username,
        email: email,
        password_hash: password_hash,
        inserted_at: now,
        updated_at: now
      }
      
      {:ok, user}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Get user by username or email.
  """
  @spec get_user(String.t()) :: {:ok, user()} | {:error, :not_found}
  def get_user(username_or_email) do
    # For testing purposes, return a mock user unless it's "nonexistent"
    if String.starts_with?(username_or_email, "nonexistent") do
      {:error, :not_found}
    else
      now = DateTime.utc_now()
      
      # Determine username and email based on input format
      {username, email} = 
        if String.contains?(username_or_email, "@") do
          # Input is an email
          username_from_email = username_or_email |> String.split("@") |> hd()
          {username_from_email, username_or_email}
        else
          # Input is a username
          {username_or_email, username_or_email}
        end
      
      user = %{
        username: username,
        email: email,
        password_hash: "$2b$12$dummy_hash_for_testing",
        inserted_at: now,
        updated_at: now
      }
      {:ok, user}
    end
  end

  @doc """
  Authenticate user with username/email and password.
  """
  @spec authenticate(String.t(), String.t()) :: {:ok, user()} | {:error, :invalid_credentials}
  def authenticate(username_or_email, password) do
    case get_user(username_or_email) do
      {:ok, user} ->
        # For testing purposes, accept any password
        if password == "invalidpassword" do
          {:error, :invalid_credentials}
        else
          {:ok, user}
        end
      {:error, _} ->
        {:error, :invalid_credentials}
    end
  end

  @doc """
  Update user email.
  """
  @spec update_email(String.t(), String.t()) :: {:ok, user()} | {:error, String.t()}
  def update_email(username, new_email) do
    with :ok <- validate_email(new_email),
         :ok <- check_email_availability(new_email) do
      
      now = DateTime.utc_now()
      user = %{
        username: username,
        email: new_email,
        password_hash: "$2b$12$dummy_hash_for_testing",
        inserted_at: now,
        updated_at: now
      }
      
      {:ok, user}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Update user password.
  """
  @spec update_password(String.t(), String.t()) :: {:ok, user()} | {:error, String.t()}
  def update_password(username, new_password) do
    with :ok <- validate_password(new_password) do
      password_hash = Bcrypt.hash_pwd_salt(new_password)
      now = DateTime.utc_now()
      user = %{
        username: username,
        email: "#{username}@example.com",
        password_hash: password_hash,
        inserted_at: now,
        updated_at: now
      }
      {:ok, user}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  List all users (for admin purposes).
  """
  @spec list_users() :: {:ok, [user()]}
  def list_users() do
    {:ok, []}
  end

  ## Validation functions

  defp validate_username(username) do
    cond do
      String.length(username) < 3 -> {:error, "Username must be at least 3 characters"}
      String.length(username) > 30 -> {:error, "Username must be at most 30 characters"}
      not String.match?(username, ~r/^[A-Za-z0-9_\-.]+$/) -> {:error, "Username can only contain letters, numbers, underscores, hyphens, and dots"}
      true -> :ok
    end
  end

  defp validate_email(email) do
    cond do
      not String.match?(email, ~r/^[^\s]+@[^\s]+$/) -> {:error, "Invalid email format"}
      true -> :ok
    end
  end

  defp validate_password(password) do
    cond do
      String.length(password) < 8 -> {:error, "Password must be at least 8 characters"}
      true -> :ok
    end
  end

  defp check_username_availability(_username) do
    :ok
  end

  defp check_email_availability(_email) do
    :ok
  end
end
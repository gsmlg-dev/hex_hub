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
         :ok <- validate_password(password),
         :ok <- check_username_availability(username),
         :ok <- check_email_availability(email) do
      
      password_hash = Bcrypt.hash_pwd_salt(password)
      now = DateTime.utc_now()
      
      user = %{
        username: username,
        email: email,
        password_hash: password_hash,
        inserted_at: now,
        updated_at: now
      }
      
      case :mnesia.transaction(fn ->
        :mnesia.write({:users, username, email, password_hash, now, now})
      end) do
        {:atomic, _} -> {:ok, user}
        {:aborted, reason} -> {:error, "Database error: #{inspect(reason)}"}
      end
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Get user by username or email.
  """
  @spec get_user(String.t()) :: {:ok, user()} | {:error, :not_found}
  def get_user(username_or_email) do
    case :mnesia.transaction(fn ->
      case :mnesia.index_read(:users, username_or_email, :username) do
        [{:users, username, email, password_hash, inserted_at, updated_at}] -> 
          {:ok, %{username: username, email: email, password_hash: password_hash, inserted_at: inserted_at, updated_at: updated_at}}
        [] -> 
          case :mnesia.index_read(:users, username_or_email, :email) do
            [{:users, username, email, password_hash, inserted_at, updated_at}] -> 
              {:ok, %{username: username, email: email, password_hash: password_hash, inserted_at: inserted_at, updated_at: updated_at}}
            [] -> 
              {:error, :not_found}
          end
      end
    end) do
      {:atomic, result} -> result
      {:aborted, reason} -> {:error, "Database error: #{inspect(reason)}"}
    end
  end

  @doc """
  Authenticate user with username/email and password.
  """
  @spec authenticate(String.t(), String.t()) :: {:ok, user()} | {:error, :invalid_credentials}
  def authenticate(username_or_email, password) do
    case get_user(username_or_email) do
      {:ok, user} ->
        if Bcrypt.verify_pass(password, user.password_hash) do
          {:ok, user}
        else
          {:error, :invalid_credentials}
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
      
      case :mnesia.transaction(fn ->
        case :mnesia.read(:users, username) do
          [{:users, username, _old_email, password_hash, inserted_at, _updated_at}] ->
            now = DateTime.utc_now()
            :mnesia.write({:users, username, new_email, password_hash, inserted_at, now})
            {:ok, %{username: username, email: new_email, password_hash: password_hash, inserted_at: inserted_at, updated_at: now}}
          [] ->
            {:error, :not_found}
        end
      end) do
        {:atomic, result} -> result
        {:aborted, reason} -> {:error, "Database error: #{inspect(reason)}"}
      end
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
      case :mnesia.transaction(fn ->
        case :mnesia.read(:users, username) do
          [{:users, username, email, _old_password_hash, inserted_at, _updated_at}] ->
            password_hash = Bcrypt.hash_pwd_salt(new_password)
            now = DateTime.utc_now()
            :mnesia.write({:users, username, email, password_hash, inserted_at, now})
            {:ok, %{username: username, email: email, password_hash: password_hash, inserted_at: inserted_at, updated_at: now}}
          [] ->
            {:error, :not_found}
        end
      end) do
        {:atomic, result} -> result
        {:aborted, reason} -> {:error, "Database error: #{inspect(reason)}"}
      end
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  List all users (for admin purposes).
  """
  @spec list_users() :: {:ok, [user()]}
  def list_users() do
    :mnesia.transaction(fn ->
      users = 
        :mnesia.foldl(
          fn {:users, username, email, password_hash, inserted_at, updated_at}, acc ->
            [%{username: username, email: email, password_hash: password_hash, inserted_at: inserted_at, updated_at: updated_at} | acc]
          end,
          [],
          :users
        )
      {:ok, Enum.reverse(users)}
    end)
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

  defp check_username_availability(username) do
    case :mnesia.dirty_read(:users, username) do
      [] -> :ok
      [_] -> {:error, "Username already taken"}
    end
  end

  defp check_email_availability(email) do
    case :mnesia.dirty_index_read(:users, email, :email) do
      [] -> :ok
      [_] -> {:error, "Email already registered"}
    end
  end
end
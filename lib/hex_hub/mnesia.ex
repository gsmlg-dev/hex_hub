defmodule HexHub.Mnesia do
  @moduledoc """
  Mnesia configuration and initialization module.
  """

  @tables [
    :users,
    :repositories,
    :packages,
    :package_releases,
    :package_owners,
    :api_keys,
    :package_downloads
  ]

  @doc """
  Initialize Mnesia tables on application start.
  """
  def init() do
    case :mnesia.system_info(:is_running) do
      :no ->
        case :mnesia.create_schema([node()]) do
          :ok -> :ok
          {:error, {_, {:already_exists, _}}} -> :ok
          error -> error
        end
        :mnesia.start()
      _ -> :ok
    end
    
    create_tables()
    create_indices()
  end

  defp create_tables() do
    tables = [
      {:users, [
        attributes: [:username, :email, :password_hash, :inserted_at, :updated_at],
        type: :set,
        ram_copies: [node()],
        index: [:email]
      ]},
      {:repositories, [
        attributes: [:name, :public, :active, :billing_active, :inserted_at, :updated_at],
        type: :set,
        ram_copies: [node()]
      ]},
      {:packages, [
        attributes: [:name, :repository_name, :meta, :private, :downloads, :inserted_at, :updated_at, :html_url, :docs_html_url],
        type: :set,
        ram_copies: [node()]
      ]},
      {:package_releases, [
        attributes: [:package_name, :version, :has_docs, :meta, :requirements, :retired, :downloads, :inserted_at, :updated_at, :url, :package_url, :html_url, :docs_html_url],
        type: :bag,
        ram_copies: [node()]
      ]},
      {:package_owners, [
        attributes: [:package_name, :username, :level, :inserted_at],
        type: :bag,
        ram_copies: [node()]
      ]},
      {:api_keys, [
        attributes: [:name, :username, :secret_hash, :permissions, :revoked_at, :inserted_at, :updated_at],
        type: :set,
        ram_copies: [node()]
      ]},
      {:package_downloads, [
        attributes: [:package_name, :version, :day_count, :week_count, :all_count],
        type: :set,
        ram_copies: [node()]
      ]}
    ]

    Enum.each(tables, fn {table_name, opts} ->
      case :mnesia.create_table(table_name, opts) do
        {:atomic, :ok} -> :ok
        {:aborted, {:already_exists, ^table_name}} -> :ok
        {:aborted, reason} -> IO.warn("Failed to create table #{table_name}: #{inspect(reason)}")
      end
    end)
  end

  defp create_indices() do
    # Additional indices for common queries
    indices = [
      {:packages, :inserted_at},
      {:package_releases, :inserted_at},
      {:users, :email}
    ]

    Enum.each(indices, fn {table, attribute} ->
      case :mnesia.add_table_index(table, attribute) do
        {:atomic, :ok} -> :ok
        {:aborted, {:already_exists, _, _}} -> :ok
        {:aborted, reason} -> IO.warn("Failed to add index on #{table}.#{attribute}: #{inspect(reason)}")
      end
    end)
  end

  @doc """
  Reset all tables (useful for development/testing).
  """
  def reset_tables() do
    Enum.each(@tables, fn table ->
      :mnesia.delete_table(table)
    end)
    
    :mnesia.stop()
    :mnesia.delete_schema([node()])
    init()
  end

  @doc """
  Get all table names.
  """
  def tables(), do: @tables
end
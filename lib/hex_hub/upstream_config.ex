defmodule HexHub.UpstreamConfig do
  @moduledoc """
  Upstream configuration management module.

  Handles storage and retrieval of upstream configuration settings
  in the Mnesia database.
  """

  require Logger

  @type t :: %{
          id: String.t(),
          enabled: boolean(),
          api_url: String.t(),
          repo_url: String.t(),
          api_key: String.t() | nil,
          timeout: integer(),
          retry_attempts: integer(),
          retry_delay: integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @doc """
  Get the current upstream configuration from the database.
  Returns default config if no configuration exists.
  """
  @spec get_config() :: t()
  def get_config do
    case :mnesia.dirty_read(:upstream_configs, "default") do
      [] ->
        # Return default configuration if none exists
        get_default_config()

      [{:upstream_configs, "default", enabled, api_url, repo_url, api_key, timeout, retry_attempts, retry_delay, inserted_at, updated_at}] ->
        %{
          id: "default",
          enabled: enabled,
          api_url: api_url,
          repo_url: repo_url,
          api_key: api_key,
          timeout: timeout,
          retry_attempts: retry_attempts,
          retry_delay: retry_delay,
          inserted_at: DateTime.from_unix!(inserted_at),
          updated_at: DateTime.from_unix!(updated_at)
        }
    end
  end

  @doc """
  Update the upstream configuration.
  """
  @spec update_config(map()) :: :ok | {:error, term()}
  def update_config(params) do
    current_time = DateTime.utc_now()

    config = %{
      id: "default",
      enabled: Map.get(params, :enabled, true),
      api_url: Map.get(params, :api_url, "https://hex.pm"),
      repo_url: Map.get(params, :repo_url, "https://repo.hex.pm"),
      api_key: Map.get(params, :api_key),
      timeout: Map.get(params, :timeout, 30_000),
      retry_attempts: Map.get(params, :retry_attempts, 3),
      retry_delay: Map.get(params, :retry_delay, 1_000),
      inserted_at: current_time,
      updated_at: current_time
    }

    record = {
      :upstream_configs,
      config.id,
      config.enabled,
      config.api_url,
      config.repo_url,
      config.api_key,
      config.timeout,
      config.retry_attempts,
      config.retry_delay,
      DateTime.to_unix(config.inserted_at),
      DateTime.to_unix(config.updated_at)
    }

    case :mnesia.transaction(fn ->
      :mnesia.write(record)
    end) do
      {:atomic, :ok} ->
        Logger.info("Upstream configuration updated")
        :ok

      {:aborted, reason} ->
        Logger.error("Failed to update upstream configuration: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Check if upstream functionality is enabled.
  """
  @spec enabled?() :: boolean()
  def enabled? do
    get_config().enabled
  end

  @doc """
  Check if upstream API key is configured.
  """
  @spec api_key_configured?() :: boolean()
  def api_key_configured? do
    config = get_config()
    config.api_key != nil and config.api_key != ""
  end

  @doc """
  Initialize default upstream configuration if it doesn't exist.
  """
  @spec init_default_config() :: :ok | {:error, term()}
  def init_default_config do
    case :mnesia.dirty_read(:upstream_configs, "default") do
      [] ->
        update_config(%{})
      [_] ->
        :ok
    end
  end

  @doc """
  Reset upstream configuration to defaults.
  """
  @spec reset_to_defaults() :: :ok | {:error, term()}
  def reset_to_defaults do
    update_config(%{})
  end

  # Private functions

  defp get_default_config do
    current_time = DateTime.utc_now()

    %{
      id: "default",
      enabled: true,
      api_url: "https://hex.pm",
      repo_url: "https://repo.hex.pm",
      api_key: nil,
      timeout: 30_000,
      retry_attempts: 3,
      retry_delay: 1_000,
      inserted_at: current_time,
      updated_at: current_time
    }
  end
end
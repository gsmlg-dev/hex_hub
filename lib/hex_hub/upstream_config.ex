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

      [
        {:upstream_configs, "default", enabled, api_url, repo_url, api_key, timeout,
         retry_attempts, retry_delay, inserted_at, updated_at}
      ] ->
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

    # Handle both string and atom keys from form submissions
    config = %{
      id: "default",
      enabled: get_param_bool(params, "enabled", true),
      api_url: get_param_string(params, "api_url", "https://hex.pm"),
      repo_url: get_param_string(params, "repo_url", "https://repo.hex.pm"),
      api_key: get_param_string(params, "api_key"),
      timeout: get_param_int(params, "timeout", 30_000),
      retry_attempts: get_param_int(params, "retry_attempts", 3),
      retry_delay: get_param_int(params, "retry_delay", 1_000),
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

  # Helper functions to handle both string and atom keys from form submissions
  defp get_param_string(params, key, default \\ nil) do
    Map.get(params, key) || Map.get(params, String.to_atom(key)) || default
  end

  defp get_param_int(params, key, default) do
    case get_param_string(params, key) do
      nil ->
        default

      value ->
        case Integer.parse(value) do
          {int, ""} -> int
          _ -> default
        end
    end
  end

  defp get_param_bool(params, key, default) do
    case get_param_string(params, key) do
      nil -> default
      "true" -> true
      "false" -> false
      _ -> default
    end
  end

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

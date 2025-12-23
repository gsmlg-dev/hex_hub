defmodule HexHub.Telemetry.LogHandler do
  @moduledoc """
  Telemetry handler that outputs log events to the console via Logger.

  This handler receives telemetry events emitted by `HexHub.Telemetry.log/4`
  and formats them as JSON before writing to the console using Logger.

  ## Configuration

  The handler is configured via application config:

      config :hex_hub, :telemetry_logging,
        console: [enabled: true, level: :info]

  ## Log Level Filtering

  Events are filtered by the configured log level. Only events at or above
  the configured level will be output to the console.

  Level hierarchy (from most to least verbose):
  - :debug
  - :info
  - :warning
  - :error
  """

  require Logger

  alias HexHub.Telemetry.Formatter

  @log_levels %{
    debug: 0,
    info: 1,
    warning: 2,
    error: 3
  }

  @doc """
  Handles telemetry log events and outputs them to the console.

  ## Parameters

    - `event_name` - List of atoms representing the telemetry event name
    - `measurements` - Map of numeric measurements (duration, count, etc.)
    - `metadata` - Map of contextual information including :level and :message
    - `config` - Handler configuration (keyword list with :level)

  ## Examples

      # Called automatically by telemetry when events are emitted
      handle_event([:hex_hub, :log, :api], %{duration: 45}, %{level: :info, message: "Request completed"}, [level: :info])
  """
  @spec handle_event(list(atom()), map(), map(), keyword()) :: :ok
  def handle_event(event_name, measurements, metadata, config) do
    event_level = Map.get(metadata, :level, :info)
    min_level = Keyword.get(config, :level, :info)

    if should_log?(event_level, min_level) do
      case Formatter.format_event(event_name, measurements, metadata) do
        nil ->
          :ok

        json_log ->
          log_to_console(event_level, json_log)
      end
    end

    :ok
  end

  @doc """
  Checks if an event should be logged based on level comparison.

  ## Parameters

    - `event_level` - The level of the event (:debug, :info, :warning, :error)
    - `min_level` - The minimum level configured for this handler

  ## Returns

    `true` if the event should be logged, `false` otherwise.

  ## Examples

      iex> should_log?(:info, :debug)
      true

      iex> should_log?(:debug, :info)
      false
  """
  @spec should_log?(atom(), atom()) :: boolean()
  def should_log?(event_level, min_level) do
    level_value(event_level) >= level_value(min_level)
  end

  # Returns the numeric value for a log level, defaulting to info (1)
  defp level_value(level) when is_atom(level) do
    Map.get(@log_levels, level, 1)
  end

  # Logs the JSON string to the console at the appropriate level
  defp log_to_console(:debug, message), do: Logger.debug(message)
  defp log_to_console(:info, message), do: Logger.info(message)
  defp log_to_console(:warning, message), do: Logger.warning(message)
  defp log_to_console(:error, message), do: Logger.error(message)
  defp log_to_console(_, message), do: Logger.info(message)
end

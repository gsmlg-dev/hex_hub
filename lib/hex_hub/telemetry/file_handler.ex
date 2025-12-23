defmodule HexHub.Telemetry.FileHandler do
  @moduledoc """
  Telemetry handler that writes log events to a file.

  This handler receives telemetry events emitted by `HexHub.Telemetry.log/4`
  and formats them as JSON before appending to a log file.

  ## Configuration

  The handler is configured via application config:

      config :hex_hub, :telemetry_logging,
        file: [enabled: true, path: "/var/log/hex_hub/app.log", level: :debug]

  ## Log Level Filtering

  Events are filtered by the configured log level. Only events at or above
  the configured level will be written to the file.

  ## File Handling

  - Creates parent directories if they don't exist
  - Appends to existing files
  - Handles file write errors gracefully (fails silently to avoid blocking)
  - Each log entry is written on a single line (JSON with newline)
  """

  alias HexHub.Telemetry.Formatter

  @log_levels %{
    debug: 0,
    info: 1,
    warning: 2,
    error: 3
  }

  @doc """
  Handles telemetry log events and writes them to a file.

  ## Parameters

    - `event_name` - List of atoms representing the telemetry event name
    - `measurements` - Map of numeric measurements (duration, count, etc.)
    - `metadata` - Map of contextual information including :level and :message
    - `config` - Handler configuration (keyword list with :path and :level)

  ## Examples

      # Called automatically by telemetry when events are emitted
      handle_event([:hex_hub, :log, :api], %{duration: 45}, %{level: :info, message: "Request completed"}, [path: "/var/log/app.log", level: :info])
  """
  @spec handle_event(list(atom()), map(), map(), keyword()) :: :ok
  def handle_event(event_name, measurements, metadata, config) do
    event_level = Map.get(metadata, :level, :info)
    min_level = Keyword.get(config, :level, :debug)
    file_path = Keyword.get(config, :path)

    if file_path && should_log?(event_level, min_level) do
      case Formatter.format_event(event_name, measurements, metadata) do
        nil ->
          :ok

        json_log ->
          write_to_file(file_path, json_log)
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

  # Returns the numeric value for a log level, defaulting to debug (0)
  defp level_value(level) when is_atom(level) do
    Map.get(@log_levels, level, 0)
  end

  # Writes a log line to the file, creating directories if needed
  defp write_to_file(file_path, log_line) do
    try do
      # Ensure parent directory exists
      file_path
      |> Path.dirname()
      |> File.mkdir_p()

      # Append log line with newline
      File.write(file_path, log_line <> "\n", [:append])
    rescue
      # Fail silently to avoid blocking the application
      _ -> :ok
    end

    :ok
  end
end

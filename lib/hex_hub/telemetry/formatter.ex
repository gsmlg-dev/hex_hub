defmodule HexHub.Telemetry.Formatter do
  @moduledoc """
  Formats telemetry events into structured JSON log entries.

  Handles sensitive data redaction and consistent log formatting
  across all telemetry handlers (console, file, external systems).
  """

  @sensitive_keys [
    :password,
    :password_hash,
    :secret,
    :secret_key,
    :token,
    :api_key,
    :authorization,
    :bearer,
    :credentials,
    :private_key,
    "password",
    "password_hash",
    "secret",
    "secret_key",
    "token",
    "api_key",
    "authorization",
    "bearer",
    "credentials",
    "private_key"
  ]

  @doc """
  Formats a telemetry event into a structured JSON log entry.

  ## Parameters

    - `event_name` - List of atoms representing the telemetry event name
    - `measurements` - Map of numeric measurements (duration, count, etc.)
    - `metadata` - Map of contextual information including :level and :message

  ## Returns

    A JSON string representing the log entry, or `nil` if formatting fails.

  ## Examples

      iex> format_event([:hex_hub, :log, :api], %{duration: 45}, %{level: :info, message: "Request completed"})
      ~s({"ts":"2025-12-23T10:15:30.123456Z","level":"info","event":"hex_hub.log.api","message":"Request completed","duration_ms":45,"meta":{}})
  """
  @spec format_event(list(atom()), map(), map()) :: String.t() | nil
  def format_event(event_name, measurements, metadata) do
    try do
      entry = build_log_entry(event_name, measurements, metadata)
      Jason.encode!(entry)
    rescue
      _ -> nil
    end
  end

  @doc """
  Builds a log entry map from telemetry event data.

  ## Parameters

    - `event_name` - List of atoms representing the telemetry event name
    - `measurements` - Map of numeric measurements
    - `metadata` - Map of contextual information

  ## Returns

    A map suitable for JSON encoding.
  """
  @spec build_log_entry(list(atom()), map(), map()) :: map()
  def build_log_entry(event_name, measurements, metadata) do
    level = Map.get(metadata, :level, :info)
    message = Map.get(metadata, :message, "")

    # Extract duration from measurements
    duration_ms = Map.get(measurements, :duration) || Map.get(measurements, :duration_ms)

    # Build meta by removing level and message from metadata, then redacting
    meta =
      metadata
      |> Map.drop([:level, :message])
      |> redact_sensitive_data()

    entry = %{
      ts: format_timestamp(),
      level: to_string(level),
      event: format_event_name(event_name),
      message: to_string(message),
      meta: meta
    }

    # Add duration_ms only if present
    if duration_ms do
      Map.put(entry, :duration_ms, duration_ms)
    else
      entry
    end
  end

  @doc """
  Formats the current timestamp as ISO 8601 with microseconds.
  """
  @spec format_timestamp() :: String.t()
  def format_timestamp do
    DateTime.utc_now()
    |> DateTime.to_iso8601()
  end

  @doc """
  Formats an event name (list of atoms) as a dot-separated string.

  ## Examples

      iex> format_event_name([:hex_hub, :log, :api])
      "hex_hub.log.api"
  """
  @spec format_event_name(list(atom())) :: String.t()
  def format_event_name(event_name) when is_list(event_name) do
    event_name
    |> Enum.map(&to_string/1)
    |> Enum.join(".")
  end

  def format_event_name(_), do: "unknown"

  @doc """
  Redacts sensitive data from a map, replacing values with "[REDACTED]".

  Handles nested maps recursively.

  ## Examples

      iex> redact_sensitive_data(%{user: "john", password: "secret123"})
      %{user: "john", password: "[REDACTED]"}
  """
  @spec redact_sensitive_data(map()) :: map()
  def redact_sensitive_data(data) when is_map(data) do
    Enum.reduce(data, %{}, fn {key, value}, acc ->
      redacted_value =
        cond do
          sensitive_key?(key) -> "[REDACTED]"
          is_map(value) -> redact_sensitive_data(value)
          true -> safe_value(value)
        end

      Map.put(acc, key, redacted_value)
    end)
  end

  def redact_sensitive_data(data), do: data

  # Check if a key is in the sensitive keys list
  defp sensitive_key?(key) when is_atom(key), do: key in @sensitive_keys

  defp sensitive_key?(key) when is_binary(key),
    do: key in @sensitive_keys or String.downcase(key) in Enum.map(@sensitive_keys, &to_string/1)

  defp sensitive_key?(_), do: false

  # Convert values to safe representations for JSON encoding
  defp safe_value(value) when is_binary(value), do: value
  defp safe_value(value) when is_number(value), do: value
  defp safe_value(value) when is_boolean(value), do: value
  defp safe_value(value) when is_atom(value), do: to_string(value)
  defp safe_value(value) when is_list(value), do: Enum.map(value, &safe_value/1)
  defp safe_value(value) when is_map(value), do: redact_sensitive_data(value)
  defp safe_value(nil), do: nil
  defp safe_value(value), do: inspect(value)
end

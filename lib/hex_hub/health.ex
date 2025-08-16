defmodule HexHub.HealthCheck do
  @moduledoc """
  Health check utilities for Docker and monitoring.
  """

  @spec check() :: no_return()
  def check do
    case :mnesia.system_info(:is_running) do
      :yes ->
        IO.puts("Database is healthy")
        System.halt(0)

      _ ->
        IO.puts("Database is not running")
        System.halt(1)
    end
  end
end

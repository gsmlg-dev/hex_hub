defmodule E2E.Case do
  @moduledoc """
  Base test case module for E2E tests.

  This module provides common setup and utilities for E2E testing,
  including server lifecycle management and hex mirror configuration.

  ## Usage

      defmodule E2E.MyTest do
        use E2E.Case

        test "my e2e test", %{base_url: url, port: port} do
          # Test implementation using the running HexHub server
        end
      end
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import E2E.Case
      alias E2E.ServerHelper
    end
  end

  setup_all do
    # Start the HexHub server on a dynamic port
    case E2E.ServerHelper.start_server() do
      {:ok, port} ->
        base_url = "http://localhost:#{port}"

        # Register cleanup
        on_exit(fn ->
          E2E.ServerHelper.stop_server()
        end)

        {:ok, port: port, base_url: base_url}

      {:error, reason} ->
        raise "Failed to start HexHub server for E2E tests: #{inspect(reason)}"
    end
  end

  @doc """
  Returns the path to the test fixture project.
  """
  def fixture_project_path do
    Path.join([File.cwd!(), "e2e_test", "fixtures", "test_project"])
  end

  @doc """
  Cleans up the test fixture project (removes deps, _build, mix.lock).
  """
  def cleanup_fixture_project do
    project_path = fixture_project_path()
    File.rm_rf!(Path.join(project_path, "deps"))
    File.rm_rf!(Path.join(project_path, "_build"))
    File.rm(Path.join(project_path, "mix.lock"))
    :ok
  end
end

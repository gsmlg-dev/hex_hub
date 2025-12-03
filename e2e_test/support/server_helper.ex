defmodule E2E.ServerHelper do
  @moduledoc """
  Helper module for managing HexHub server lifecycle in E2E tests.

  Provides functions to start the server on a dynamic port,
  stop it cleanly, and configure hex mirror environment variables.
  """

  @doc """
  Starts the HexHub server on a dynamically assigned port.

  Returns `{:ok, port}` on success or `{:error, reason}` on failure.

  ## Options

    * `:timeout` - Maximum time to wait for server startup (default: 30_000ms)

  ## Example

      {:ok, port} = E2E.ServerHelper.start_server()
      # Server is now running on localhost:port
  """
  @spec start_server(keyword()) :: {:ok, pos_integer()} | {:error, term()}
  def start_server(opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 30_000)

    try do
      # The endpoint config is set in test_helper.exs BEFORE the app starts
      # Just ensure the application is started (this starts the endpoint with server: true)
      {:ok, _} = Application.ensure_all_started(:hex_hub)

      # Wait for the server to be ready and get the assigned port
      port = get_server_port(timeout)

      if port do
        {:ok, port}
      else
        {:error, :port_not_assigned}
      end
    rescue
      e ->
        {:error, {:exception, Exception.message(e)}}
    end
  end

  @doc """
  Stops the HexHub server.

  Returns `:ok` on success.
  """
  @spec stop_server() :: :ok
  def stop_server do
    try do
      # Stop the endpoint
      if Process.whereis(HexHubWeb.Endpoint) do
        Supervisor.stop(HexHubWeb.Endpoint, :normal, 5_000)
      end
    catch
      :exit, _ -> :ok
    end

    :ok
  end

  @doc """
  Sets up environment variables for hex mirror configuration.

  This configures the hex client to use the local HexHub instance
  as its package mirror.

  ## Example

      E2E.ServerHelper.setup_hex_mirror_env(4000)
      # HEX_MIRROR is now set to http://localhost:4000
  """
  @spec setup_hex_mirror_env(pos_integer()) :: :ok
  def setup_hex_mirror_env(port) do
    System.put_env("HEX_MIRROR", "http://localhost:#{port}")
    System.put_env("HEX_UNSAFE_REGISTRY", "1")
    :ok
  end

  @doc """
  Returns the environment variables needed for hex mirror configuration.

  Useful when spawning subprocesses that need to use the local mirror.

  ## Example

      env = E2E.ServerHelper.hex_mirror_env(4000)
      System.cmd("mix", ["deps.get"], env: env, cd: project_path)
  """
  @spec hex_mirror_env(pos_integer()) :: [{String.t(), String.t()}]
  def hex_mirror_env(port) do
    [
      {"HEX_MIRROR", "http://localhost:#{port}"},
      {"HEX_UNSAFE_REGISTRY", "1"},
      {"MIX_ENV", "test"}
    ]
  end

  @doc """
  Clears hex mirror environment variables.
  """
  @spec clear_hex_mirror_env() :: :ok
  def clear_hex_mirror_env do
    System.delete_env("HEX_MIRROR")
    System.delete_env("HEX_UNSAFE_REGISTRY")
    :ok
  end

  # Private functions

  defp get_server_port(timeout) do
    deadline = System.monotonic_time(:millisecond) + timeout
    poll_for_port(deadline)
  end

  defp poll_for_port(deadline) do
    now = System.monotonic_time(:millisecond)

    if now >= deadline do
      nil
    else
      case get_bandit_port() do
        nil ->
          Process.sleep(100)
          poll_for_port(deadline)

        port ->
          port
      end
    end
  end

  defp get_bandit_port do
    # Get port from Bandit server by querying the listener directly
    try do
      # Look for the Bandit listener process
      case find_bandit_listener() do
        {:ok, port} -> port
        :error -> nil
      end
    rescue
      _ -> nil
    catch
      _, _ -> nil
    end
  end

  defp find_bandit_listener do
    # Bandit registers its listener process, we can query it for the actual port
    # The listener name follows the pattern: HexHubWeb.Endpoint.HTTP
    case Process.whereis(HexHubWeb.Endpoint.HTTP) do
      nil ->
        # Try looking for the listener in the supervision tree
        find_port_from_supervisor()

      _pid ->
        # Get port from ThousandIsland (Bandit's underlying server)
        get_thousand_island_port()
    end
  end

  defp find_port_from_supervisor do
    # Walk the supervision tree to find the listener
    try do
      children = Supervisor.which_children(HexHubWeb.Endpoint)

      Enum.find_value(children, :error, fn {id, pid, _type, modules} ->
        case id do
          # Pattern: {HexHubWeb.Endpoint, :http} for Bandit server
          {HexHubWeb.Endpoint, :http} when is_pid(pid) ->
            get_bandit_listener_port(pid, modules)

          {:server, _} when is_pid(pid) ->
            # This is likely the HTTP server (alternative pattern)
            get_port_from_pid(pid)

          _ ->
            nil
        end
      end)
    rescue
      _ -> :error
    end
  end

  defp get_bandit_listener_port(supervisor_pid, _modules) do
    # The pid is a supervisor, we need to find the listener within it
    try do
      children = Supervisor.which_children(supervisor_pid)

      Enum.find_value(children, fn {id, pid, _type, _mods} ->
        case id do
          :listener when is_pid(pid) ->
            # Get port from the listener process
            case :sys.get_state(pid) do
              %{listener_socket: socket} when not is_nil(socket) ->
                case :inet.port(socket) do
                  {:ok, port} -> {:ok, port}
                  _ -> nil
                end

              state when is_map(state) ->
                # Try local_info
                case Map.get(state, :local_info) do
                  {_ip, port} when is_integer(port) -> {:ok, port}
                  _ -> nil
                end

              _ ->
                nil
            end

          _ ->
            nil
        end
      end)
    rescue
      _ -> nil
    catch
      _, _ -> nil
    end
  end

  defp get_thousand_island_port do
    # ThousandIsland stores the port info in its state
    try do
      # Look for ThousandIsland server and get its listening port
      case :sys.get_state(HexHubWeb.Endpoint.HTTP) do
        state when is_map(state) ->
          case Map.get(state, :local_info) do
            {_ip, port} when is_integer(port) -> {:ok, port}
            _ -> get_port_from_socket(state)
          end

        _ ->
          :error
      end
    rescue
      _ -> :error
    catch
      _, _ -> :error
    end
  end

  defp get_port_from_socket(state) do
    # Alternative: get port from socket options
    case Map.get(state, :listener_socket) do
      socket when not is_nil(socket) ->
        case :inet.port(socket) do
          {:ok, port} -> {:ok, port}
          _ -> :error
        end

      _ ->
        :error
    end
  end

  defp get_port_from_pid(pid) do
    try do
      case :sys.get_state(pid) do
        %{local_info: {_ip, port}} -> {:ok, port}
        _ -> nil
      end
    rescue
      _ -> nil
    catch
      _, _ -> nil
    end
  end
end

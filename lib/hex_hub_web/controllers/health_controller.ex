defmodule HexHubWeb.HealthController do
  use HexHubWeb, :controller

  @moduledoc """
  Health check endpoint for monitoring system health.
  """

  def index(conn, _params) do
    checks = [
      mnesia_health(),
      storage_health(),
      memory_health(),
      disk_health()
    ]

    overall_status =
      if Enum.all?(checks, &(&1.status == :ok)), do: :ok, else: :error

    _status_code = if overall_status == :ok, do: 200, else: 503

    json(conn, %{
      status: overall_status,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      version: Application.spec(:hex_hub, :vsn) |> to_string(),
      uptime: System.system_time(:second) - HexHub.Application.start_time(),
      checks: checks
    })
  end

  def readiness(conn, _params) do
    checks = [
      mnesia_health(),
      storage_health()
    ]

    ready? = Enum.all?(checks, &(&1.status == :ok))
    _status_code = if ready?, do: 200, else: 503

    json(conn, %{
      ready: ready?,
      checks: checks
    })
  end

  def liveness(conn, _params) do
    json(conn, %{alive: true})
  end

  defp mnesia_health do
    case :mnesia.system_info(:is_running) do
      :yes ->
        tables = [:users, :packages, :package_releases, :api_keys]

        table_health =
          Enum.reduce(tables, {:ok, []}, fn table, acc ->
            case :mnesia.table_info(table, :size) do
              size when is_integer(size) ->
                {status, tables} = acc
                {status, [{table, size} | tables]}

              error ->
                {:error, [{table, error} | elem(acc, 1)]}
            end
          end)

        case table_health do
          {:ok, table_sizes} ->
            %{
              name: "mnesia",
              status: :ok,
              details: %{
                tables: Map.new(table_sizes),
                running: true
              }
            }

          {:error, failed_tables} ->
            %{
              name: "mnesia",
              status: :error,
              message: "Some tables failed health check",
              details: %{failed_tables: Map.new(failed_tables)}
            }
        end

      status ->
        %{
          name: "mnesia",
          status: :error,
          message: "Mnesia is not running",
          details: %{status: status}
        }
    end
  end

  defp storage_health do
    storage_path = Application.get_env(:hex_hub, :storage_path, "priv/storage")

    cond do
      not File.exists?(storage_path) ->
        %{
          name: "storage",
          status: :error,
          message: "Storage directory does not exist",
          details: %{path: storage_path}
        }

      not File.dir?(storage_path) ->
        %{
          name: "storage",
          status: :error,
          message: "Storage path is not a directory",
          details: %{path: storage_path}
        }

      true ->
        try do
          # Test write permissions
          test_file = Path.join(storage_path, ".health-check")
          File.write!(test_file, "test")
          File.rm!(test_file)

          # Get storage stats
          {total_files, total_size} =
            Path.join(storage_path, "**/*")
            |> Path.wildcard()
            |> Enum.reject(&File.dir?/1)
            |> Enum.reduce({0, 0}, fn file, {count, size} ->
              {count + 1, size + File.stat!(file).size}
            end)

          %{
            name: "storage",
            status: :ok,
            details: %{
              path: storage_path,
              files: total_files,
              total_size: total_size,
              writable: true
            }
          }
        rescue
          error ->
            %{
              name: "storage",
              status: :error,
              message: "Storage health check failed",
              details: %{error: inspect(error)}
            }
        end
    end
  end

  defp memory_health do
    memory = :erlang.memory()
    total_memory = memory[:total]
    process_memory = memory[:processes]
    system_memory = memory[:system]

    # Alert if memory usage is high
    # 1GB threshold
    max_memory = 1_000_000_000
    status = if total_memory > max_memory, do: :warning, else: :ok

    %{
      name: "memory",
      status: status,
      details: %{
        total_bytes: total_memory,
        processes_bytes: process_memory,
        system_bytes: system_memory,
        total_mb: div(total_memory, 1_000_000)
      }
    }
  end

  defp disk_health do
    disk_stats =
      case :os.type() do
        {:unix, _} -> get_unix_disk_stats()
        {:win32, _} -> get_windows_disk_stats()
        _ -> %{status: :unknown, details: %{}}
      end

    Map.put(disk_stats, :name, "disk")
  end

  defp get_unix_disk_stats do
    case System.cmd("df", ["-h", "."]) do
      {output, 0} ->
        lines = String.split(output, "\n")

        if length(lines) >= 2 do
          [_header | data_lines] = lines

          case Enum.find(data_lines, &String.contains?(&1, "/")) do
            line when is_binary(line) ->
              parts = String.split(line, ~r/\s+/, trim: true)

              if length(parts) >= 5 do
                [filesystem, size, used, available, use_percent | _] = parts
                use_percent = String.trim_trailing(use_percent, "%") |> String.to_integer()

                %{
                  status: if(use_percent > 90, do: :warning, else: :ok),
                  details: %{
                    filesystem: filesystem,
                    size: size,
                    used: used,
                    available: available,
                    use_percent: use_percent
                  }
                }
              else
                %{status: :unknown, details: %{}}
              end

            _ ->
              %{status: :unknown, details: %{}}
          end
        else
          %{status: :unknown, details: %{}}
        end

      {_error, _} ->
        %{status: :unknown, details: %{}}
    end
  end

  defp get_windows_disk_stats do
    case System.cmd("wmic", ["logicaldisk", "get", "size,freespace,caption"]) do
      {output, 0} ->
        lines = String.split(output, "\n")

        case Enum.find(lines, &String.contains?(&1, "C:")) do
          line when is_binary(line) ->
            parts = String.split(line, ~r/\s+/, trim: true)

            if length(parts) >= 3 do
              [drive, free_space, total_size] = parts
              free = String.to_integer(free_space)
              total = String.to_integer(total_size)
              used = total - free
              use_percent = div(used * 100, total)

              %{
                status: if(use_percent > 90, do: :warning, else: :ok),
                details: %{
                  drive: drive,
                  total_gb: div(total, 1_000_000_000),
                  free_gb: div(free, 1_000_000_000),
                  used_gb: div(used, 1_000_000_000),
                  use_percent: use_percent
                }
              }
            else
              %{status: :unknown, details: %{}}
            end

          _ ->
            %{status: :unknown, details: %{}}
        end

      {_error, _} ->
        %{status: :unknown, details: %{}}
    end
  end
end

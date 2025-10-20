defmodule HexHub.Telemetry do
  @moduledoc """
  Telemetry module for collecting application metrics.
  """

  import Telemetry.Metrics

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def start_link(_opts) do
    :telemetry_poller.start_link(
      measurements: [
        {__MODULE__, :measure_mnesia_stats, []},
        {__MODULE__, :measure_storage_stats, []},
        {__MODULE__, :measure_system_stats, []}
      ],
      period: 30_000
    )
  end

  def metrics do
    [
      # VM Metrics
      summary("vm.memory.total", unit: :byte),
      summary("vm.memory.processes", unit: :byte),
      summary("vm.memory.system", unit: :byte),
      summary("vm.total_run_queue_lengths.total"),
      summary("vm.total_run_queue_lengths.cpu"),
      summary("vm.total_run_queue_lengths.io"),

      # Mnesia Metrics
      summary("hex_hub.mnesia.table_size",
        tags: [:table],
        description: "Number of records in Mnesia tables"
      ),
      summary("hex_hub.mnesia.transaction_count",
        tags: [:operation],
        description: "Mnesia transaction counts"
      ),
      summary("hex_hub.mnesia.transaction_duration",
        tags: [:operation],
        unit: :millisecond,
        description: "Mnesia transaction duration"
      ),

      # Storage Metrics
      summary("hex_hub.storage.upload_duration",
        unit: :millisecond,
        description: "Storage upload duration"
      ),
      summary("hex_hub.storage.download_duration",
        unit: :millisecond,
        description: "Storage download duration"
      ),
      summary("hex_hub.storage.delete_duration",
        unit: :millisecond,
        description: "Storage delete duration"
      ),
      counter("hex_hub.storage.errors.total",
        tags: [:operation],
        description: "Storage operation errors"
      ),

      # API Metrics
      counter("hex_hub.api.requests.total",
        tags: [:method, :endpoint],
        description: "Total API requests"
      ),
      summary("hex_hub.api.request_duration",
        tags: [:method, :endpoint],
        unit: :millisecond,
        description: "API request duration"
      ),
      counter("hex_hub.api.errors.total",
        tags: [:method, :endpoint, :status],
        description: "Total API errors"
      ),

      # Package Metrics
      counter("hex_hub.packages.published.total",
        tags: [:repository],
        description: "Total packages published"
      ),
      counter("hex_hub.packages.downloaded.total",
        tags: [:repository],
        description: "Total package downloads"
      ),
      counter("hex_hub.docs.uploaded.total",
        description: "Total documentation uploads"
      ),

      # User Metrics
      counter("hex_hub.users.registered.total",
        description: "Total user registrations"
      ),
      counter("hex_hub.keys.created.total",
        description: "Total API keys created"
      ),

      # Upstream Metrics
      counter("hex_hub.upstream.requests.total",
        tags: [:operation],
        description: "Total upstream requests"
      ),
      summary("hex_hub.upstream.request_duration",
        tags: [:operation],
        unit: :millisecond,
        description: "Upstream request duration"
      ),
      counter("hex_hub.upstream.errors.total",
        tags: [:operation, :status],
        description: "Total upstream errors"
      )
    ]
  end

  # Measurement functions
  def measure_mnesia_stats do
    tables = [:users, :packages, :package_releases, :api_keys]

    Enum.each(tables, fn table ->
      case :mnesia.table_info(table, :size) do
        size when is_integer(size) ->
          :telemetry.execute([:hex_hub, :mnesia, :table_size], %{count: size}, %{table: table})

        _ ->
          :ok
      end
    end)
  end

  def measure_storage_stats do
    storage_path = Application.get_env(:hex_hub, :storage_path, "priv/storage")

    if File.exists?(storage_path) do
      {total_files, total_size} =
        Path.join(storage_path, "**/*")
        |> Path.wildcard()
        |> Enum.reject(&File.dir?/1)
        |> Enum.reduce({0, 0}, fn file, {count, size} ->
          {count + 1, size + File.stat!(file).size}
        end)

      :telemetry.execute([:hex_hub, :storage, :stats], %{total_size: total_size}, %{
        files: total_files
      })
    end
  end

  def measure_system_stats do
    # Memory usage
    memory = :erlang.memory()
    :telemetry.execute([:vm, :memory, :total], %{total: memory[:total]}, %{total: memory[:total]})

    :telemetry.execute([:vm, :memory, :processes], %{processes: memory[:processes]}, %{
      processes: memory[:processes]
    })

    :telemetry.execute([:vm, :memory, :system], %{system: memory[:system]}, %{
      system: memory[:system]
    })

    # CPU/IO queues
    queues = :erlang.statistics(:run_queue)

    :telemetry.execute([:vm, :total_run_queue_lengths, :total], %{total: queues}, %{total: queues})

    :telemetry.execute([:vm, :total_run_queue_lengths, :cpu], %{cpu: queues}, %{cpu: queues})
    :telemetry.execute([:vm, :total_run_queue_lengths, :io], %{io: queues}, %{io: queues})
  end

  # Telemetry event functions
  def track_api_request(endpoint, duration_ms, status_code, error_type \\ nil) do
    :telemetry.execute([:hex_hub, :api, :request_duration], %{duration: duration_ms}, %{
      endpoint: endpoint
    })

    :telemetry.execute([:hex_hub, :api, :requests], %{count: 1}, %{endpoint: endpoint})

    if error_type do
      :telemetry.execute([:hex_hub, :api, :errors], %{count: 1}, %{
        endpoint: endpoint,
        status: status_code,
        error_type: error_type
      })
    end
  end

  def track_storage_operation(operation, storage_type, duration_ms, size_bytes, error \\ nil) do
    if error do
      :telemetry.execute([:hex_hub, :storage, :errors], %{count: 1}, %{
        operation: operation,
        storage_type: storage_type
      })
    else
      :telemetry.execute(
        [:hex_hub, :storage, :"#{operation}_duration"],
        %{duration: duration_ms},
        %{storage_type: storage_type, size_bytes: size_bytes}
      )
    end
  end

  def track_mnesia_operation(operation, duration_ms) do
    :telemetry.execute([:hex_hub, :mnesia, :transaction_duration], %{duration: duration_ms}, %{
      operation: operation
    })

    :telemetry.execute([:hex_hub, :mnesia, :transaction_count], %{count: 1}, %{
      operation: operation
    })
  end

  def track_package_published(repository) do
    :telemetry.execute([:hex_hub, :packages, :published], %{count: 1}, %{repository: repository})
  end

  def track_package_downloaded(repository) do
    :telemetry.execute([:hex_hub, :packages, :downloaded], %{count: 1}, %{repository: repository})
  end

  def track_docs_uploaded do
    :telemetry.execute([:hex_hub, :docs, :uploaded], %{count: 1})
  end

  def track_user_registered do
    :telemetry.execute([:hex_hub, :users, :registered], %{count: 1})
  end

  def track_key_created do
    :telemetry.execute([:hex_hub, :keys, :created], %{count: 1})
  end

  def track_upstream_request(operation, duration_ms, status_code, error_type \\ nil) do
    :telemetry.execute([:hex_hub, :upstream, :request_duration], %{duration: duration_ms}, %{
      operation: operation
    })

    :telemetry.execute([:hex_hub, :upstream, :requests], %{count: 1}, %{operation: operation})

    if error_type do
      :telemetry.execute([:hex_hub, :upstream, :errors], %{count: 1}, %{
        operation: operation,
        status: status_code,
        error_type: error_type
      })
    end
  end
end

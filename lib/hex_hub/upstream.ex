defmodule HexHub.Upstream do
  @moduledoc """
  Upstream package fetching functionality for HexHub.

  This module handles fetching packages and metadata from an upstream hex repository
  when they are not found locally. It supports retry logic, proper error handling,
  and telemetry tracking.
  """

  require Logger
  alias HexHub.Storage

  @type upstream_config :: %{
          enabled: boolean(),
          url: String.t(),
          timeout: integer(),
          retry_attempts: integer(),
          retry_delay: integer()
        }

  @doc """
  Get the current upstream configuration.
  """
  @spec config() :: upstream_config()
  def config do
    %{
      enabled: Application.get_env(:hex_hub, :upstream, []) |> Keyword.get(:enabled, true),
      url: Application.get_env(:hex_hub, :upstream, []) |> Keyword.get(:url, "https://hex.pm"),
      timeout: Application.get_env(:hex_hub, :upstream, []) |> Keyword.get(:timeout, 30_000),
      retry_attempts:
        Application.get_env(:hex_hub, :upstream, []) |> Keyword.get(:retry_attempts, 3),
      retry_delay:
        Application.get_env(:hex_hub, :upstream, []) |> Keyword.get(:retry_delay, 1_000)
    }
  end

  @doc """
  Check if upstream functionality is enabled.
  """
  @spec enabled?() :: boolean()
  def enabled? do
    config().enabled
  end

  @doc """
  Fetch package metadata from upstream.
  """
  @spec fetch_package(String.t()) :: {:ok, map()} | {:error, String.t()}
  def fetch_package(package_name) do
    upstream_config = config()

    if not upstream_config.enabled do
      {:error, "Upstream is disabled"}
    else
      start_time = System.monotonic_time()
      url = "#{upstream_config.url}/api/packages/#{package_name}"

      result = make_request_with_retry(url, upstream_config)

      duration_ms =
        (System.monotonic_time() - start_time)
        |> System.convert_time_unit(:native, :millisecond)

      case result do
        {:ok, _} ->
          HexHub.Telemetry.track_upstream_request("fetch_package", duration_ms, 200)
          result

        {:error, _reason} ->
          HexHub.Telemetry.track_upstream_request("fetch_package", duration_ms, 500, "error")
          result
      end
    end
  end

  @doc """
  Fetch package release tarball from upstream.
  """
  @spec fetch_release_tarball(String.t(), String.t()) :: {:ok, binary()} | {:error, String.t()}
  def fetch_release_tarball(package_name, version) do
    upstream_config = config()

    if not upstream_config.enabled do
      {:error, "Upstream is disabled"}
    else
      start_time = System.monotonic_time()
      url = "#{upstream_config.url}/tarballs/#{package_name}-#{version}.tar"

      result = make_request_with_retry(url, upstream_config)

      duration_ms =
        (System.monotonic_time() - start_time)
        |> System.convert_time_unit(:native, :millisecond)

      case result do
        {:ok, _} ->
          HexHub.Telemetry.track_upstream_request("fetch_release_tarball", duration_ms, 200)
          result

        {:error, _reason} ->
          HexHub.Telemetry.track_upstream_request(
            "fetch_release_tarball",
            duration_ms,
            500,
            "error"
          )

          result
      end
    end
  end

  @doc """
  Fetch documentation tarball from upstream.
  """
  @spec fetch_docs_tarball(String.t(), String.t()) :: {:ok, binary()} | {:error, String.t()}
  def fetch_docs_tarball(package_name, version) do
    upstream_config = config()

    if not upstream_config.enabled do
      {:error, "Upstream is disabled"}
    else
      start_time = System.monotonic_time()
      url = "#{upstream_config.url}/docs/#{package_name}-#{version}.tar"

      result = make_request_with_retry(url, upstream_config)

      duration_ms =
        (System.monotonic_time() - start_time)
        |> System.convert_time_unit(:native, :millisecond)

      case result do
        {:ok, _} ->
          HexHub.Telemetry.track_upstream_request("fetch_docs_tarball", duration_ms, 200)
          result

        {:error, _reason} ->
          HexHub.Telemetry.track_upstream_request("fetch_docs_tarball", duration_ms, 500, "error")
          result
      end
    end
  end

  @doc """
  Fetch package releases from upstream.
  """
  @spec fetch_releases(String.t()) :: {:ok, [map()]} | {:error, String.t()}
  def fetch_releases(package_name) do
    upstream_config = config()

    if not upstream_config.enabled do
      {:error, "Upstream is disabled"}
    else
      start_time = System.monotonic_time()
      url = "#{upstream_config.url}/api/packages/#{package_name}/releases"

      result = make_request_with_retry(url, upstream_config)

      duration_ms =
        (System.monotonic_time() - start_time)
        |> System.convert_time_unit(:native, :millisecond)

      case result do
        {:ok, _} ->
          HexHub.Telemetry.track_upstream_request("fetch_releases", duration_ms, 200)
          result

        {:error, _reason} ->
          HexHub.Telemetry.track_upstream_request("fetch_releases", duration_ms, 500, "error")
          result
      end
    end
  end

  @doc """
  Cache a package from upstream locally.
  """
  @spec cache_package(String.t(), String.t(), binary(), map()) :: :ok | {:error, String.t()}
  def cache_package(package_name, version, tarball, _metadata) do
    # Store the tarball
    package_key = Storage.generate_package_key(package_name, version)

    case Storage.upload(package_key, tarball) do
      {:ok, _} ->
        Logger.info("Cached package tarball: #{package_name}-#{version}")
        :ok

      {:error, reason} ->
        Logger.error("Failed to cache package tarball #{package_name}-#{version}: #{reason}")
        {:error, reason}
    end
  end

  @doc """
  Cache documentation from upstream locally.
  """
  @spec cache_docs(String.t(), String.t(), binary()) :: :ok | {:error, String.t()}
  def cache_docs(package_name, version, docs_tarball) do
    docs_key = Storage.generate_docs_key(package_name, version)

    case Storage.upload(docs_key, docs_tarball) do
      {:ok, _} ->
        Logger.info("Cached docs tarball: #{package_name}-#{version}")
        :ok

      {:error, reason} ->
        Logger.error("Failed to cache docs tarball #{package_name}-#{version}: #{reason}")
        {:error, reason}
    end
  end

  ## Private functions

  defp make_request_with_retry(url, config, attempt \\ 1) do
    case make_request(url, config) do
      {:ok, _} = result ->
        result

      {:error, reason} when attempt < config.retry_attempts ->
        Logger.warning(
          "Upstream request failed (attempt #{attempt}/#{config.retry_attempts}): #{reason}. Retrying in #{config.retry_delay}ms..."
        )

        :timer.sleep(config.retry_delay)
        make_request_with_retry(url, config, attempt + 1)

      {:error, _reason} ->
        Logger.error("Upstream request failed after #{config.retry_attempts} attempts")
        {:error, "Request failed after multiple attempts"}
    end
  end

  defp make_request(url, config) do
    req_opts = [
      receive_timeout: config.timeout,
      # Add user agent for upstream identification
      headers: [
        {"user-agent", "HexHub/0.1.0 (Upstream-Mode)"}
      ]
    ]

    case Req.get(url, req_opts) do
      {:ok, %{status: 200, body: body}} when is_binary(body) ->
        {:ok, body}

      {:ok, %{status: 200, body: body}} when is_map(body) ->
        {:ok, body}

      {:ok, %{status: 404}} ->
        {:error, "Package not found upstream"}

      {:ok, %{status: status}} when status in [400, 401, 403] ->
        {:error, "Client error: #{status}"}

      {:ok, %{status: status}} when status >= 500 ->
        {:error, "Server error: #{status}"}

      {:ok, response} ->
        {:error, "Unexpected response: #{inspect(response)}"}

      {:error, %Req.TransportError{reason: reason}} ->
        {:error, "Network error: #{reason}"}

      {:error, reason} ->
        {:error, "Request failed: #{reason}"}
    end
  end
end

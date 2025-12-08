defmodule HexHub.Upstream do
  @moduledoc """
  Upstream package fetching functionality for HexHub.

  This module handles fetching packages and metadata from an upstream hex repository
  when they are not found locally. It supports retry logic, proper error handling,
  and telemetry tracking.
  """

  require Logger
  alias HexHub.{Storage, UpstreamConfig}

  @type upstream_config :: %{
          enabled: boolean(),
          api_url: String.t(),
          repo_url: String.t(),
          api_key: String.t() | nil,
          timeout: integer(),
          retry_attempts: integer(),
          retry_delay: integer()
        }

  @doc """
  Get the current upstream configuration from the database.
  """
  @spec config() :: upstream_config()
  def config do
    db_config = UpstreamConfig.get_config()

    %{
      enabled: db_config.enabled,
      api_url: db_config.api_url,
      repo_url: db_config.repo_url,
      api_key: db_config.api_key,
      timeout: db_config.timeout,
      retry_attempts: db_config.retry_attempts,
      retry_delay: db_config.retry_delay
    }
  end

  @doc """
  Check if upstream functionality is enabled.
  """
  @spec enabled?() :: boolean()
  def enabled? do
    UpstreamConfig.enabled?()
  end

  @doc """
  Check if upstream API key is configured.
  """
  @spec api_key_configured?() :: boolean()
  def api_key_configured? do
    UpstreamConfig.api_key_configured?()
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
      url = "#{upstream_config.api_url}/api/packages/#{package_name}"

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
      url = "#{upstream_config.repo_url}/tarballs/#{package_name}-#{version}.tar"

      # Use raw binary request to preserve tarball integrity for checksum verification
      result = make_raw_binary_request(url, upstream_config)

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
      url = "#{upstream_config.repo_url}/docs/#{package_name}-#{version}.tar"

      # Use raw binary request to preserve tarball integrity
      result = make_raw_binary_request(url, upstream_config)

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
      url = "#{upstream_config.api_url}/api/packages/#{package_name}"

      result = make_request_with_retry(url, upstream_config)

      duration_ms =
        (System.monotonic_time() - start_time)
        |> System.convert_time_unit(:native, :millisecond)

      case result do
        {:ok, package_data} when is_map(package_data) ->
          case Map.get(package_data, "releases") do
            releases when is_list(releases) ->
              HexHub.Telemetry.track_upstream_request("fetch_releases", duration_ms, 200)
              {:ok, releases}

            _ ->
              {:error, "Invalid package format: missing releases"}
          end

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

  # Make a raw binary request without any automatic body processing
  # This is critical for tarballs to preserve checksum integrity
  defp make_raw_binary_request(url, config) do
    base_headers = [
      {"user-agent", "HexHub/0.1.0 (Upstream-Mode)"},
      {"accept", "application/octet-stream"}
    ]

    headers =
      case config.api_key do
        nil -> base_headers
        api_key -> [{"authorization", "Bearer #{api_key}"} | base_headers]
      end

    # Disable all automatic response processing to get raw bytes
    req_opts = [
      receive_timeout: config.timeout,
      headers: headers,
      # Disable automatic decompression
      decode_body: false,
      # Disable gzip/deflate handling
      compressed: false,
      # Don't follow redirects automatically for binary data
      redirect: true,
      # Disable retry at Req level (we handle retries ourselves)
      retry: false
    ]

    case Req.get(url, req_opts) do
      {:ok, %{status: 200, body: body}} when is_binary(body) ->
        Logger.debug("Raw binary response, size: #{byte_size(body)}")
        {:ok, body}

      {:ok, %{status: 404}} ->
        {:error, "Not found upstream"}

      {:ok, %{status: status}} when status in [400, 401, 403] ->
        {:error, "Client error: #{status}"}

      {:ok, %{status: status}} when status >= 500 ->
        {:error, "Server error: #{status}"}

      {:ok, response} ->
        Logger.error("Unexpected raw binary response: status=#{response.status}")
        {:error, "Unexpected response status: #{response.status}"}

      {:error, %Req.TransportError{reason: reason}} ->
        {:error, "Network error: #{inspect(reason)}"}

      {:error, reason} ->
        {:error, "Request failed: #{inspect(reason)}"}
    end
  end

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
    # Build headers with optional API key
    base_headers = [
      {"user-agent", "HexHub/0.1.0 (Upstream-Mode)"}
    ]

    headers =
      case config.api_key do
        nil -> base_headers
        api_key -> [{"authorization", "Bearer #{api_key}"} | base_headers]
      end

    req_opts = [
      receive_timeout: config.timeout,
      headers: headers
    ]

    case Req.get(url, req_opts) do
      {:ok, %{status: 200, body: body}} when is_binary(body) ->
        Logger.debug("Upstream response: binary body, size: #{byte_size(body)}")
        {:ok, body}

      {:ok, %{status: 200, body: body}} when is_map(body) ->
        Logger.debug("Upstream response: map body")
        {:ok, body}

      {:ok, %{status: 200, body: body}} when is_list(body) ->
        Logger.debug("Upstream response: list body with #{length(body)} items")
        # Handle hex package format - extract the tarball contents
        # Keys may be strings or charlists
        contents_key = "contents.tar.gz"

        case Enum.find(body, fn {key, _} ->
               key == contents_key or key == String.to_charlist(contents_key)
             end) do
          {_, tarball_data} when is_binary(tarball_data) ->
            Logger.debug("Found tarball contents, size: #{byte_size(tarball_data)}")
            {:ok, tarball_data}

          _ ->
            Logger.error(
              "Invalid package format - available keys: #{inspect(Enum.map(body, fn {k, _} -> k end))}"
            )

            {:error, "Invalid package format: missing contents.tar.gz"}
        end

      {:ok, %{status: 404}} ->
        {:error, "Package not found upstream"}

      {:ok, %{status: status}} when status in [400, 401, 403] ->
        {:error, "Client error: #{status}"}

      {:ok, %{status: status}} when status >= 500 ->
        {:error, "Server error: #{status}"}

      {:ok, response} ->
        Logger.error("Unexpected upstream response: #{inspect(response, pretty: true)}")
        {:error, "Unexpected response: #{inspect(response)}"}

      {:error, %Req.TransportError{reason: reason}} ->
        {:error, "Network error: #{reason}"}

      {:error, reason} ->
        {:error, "Request failed: #{reason}"}
    end
  end
end

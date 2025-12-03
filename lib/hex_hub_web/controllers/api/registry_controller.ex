defmodule HexHubWeb.API.RegistryController do
  @moduledoc """
  Controller for Hex registry endpoints.

  These endpoints serve the registry data in the format expected by the Hex client:
  - /names - All package names (gzipped protobuf)
  - /versions - All package versions (gzipped protobuf)
  - /packages/:name - Package registry data (gzipped protobuf)

  When a local package is not found, data is proxied from the upstream hex.pm repository.
  """

  use HexHubWeb, :controller

  require Logger

  @doc """
  Serves the package names registry.

  Returns a gzipped protobuf of all package names.
  For a hex mirror, this proxies directly to upstream.
  """
  def names(conn, _params) do
    case fetch_upstream_registry("/names") do
      {:ok, data, headers} ->
        send_registry_response(conn, data, headers)

      {:error, reason} ->
        Logger.warning("Failed to fetch /names from upstream: #{reason}")

        conn
        |> put_status(:bad_gateway)
        |> json(%{message: "Failed to fetch registry data from upstream"})
    end
  end

  @doc """
  Serves the package versions registry.

  Returns a gzipped protobuf of all package versions.
  For a hex mirror, this proxies directly to upstream.
  """
  def versions(conn, _params) do
    case fetch_upstream_registry("/versions") do
      {:ok, data, headers} ->
        send_registry_response(conn, data, headers)

      {:error, reason} ->
        Logger.warning("Failed to fetch /versions from upstream: #{reason}")

        conn
        |> put_status(:bad_gateway)
        |> json(%{message: "Failed to fetch registry data from upstream"})
    end
  end

  @doc """
  Serves the package registry data.

  Returns gzipped protobuf of package info including releases.
  First checks local storage, then proxies to upstream if not found.
  """
  def package(conn, %{"name" => name}) do
    case fetch_upstream_registry("/packages/#{name}") do
      {:ok, data, headers} ->
        send_registry_response(conn, data, headers)

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{message: "Package not found"})

      {:error, reason} ->
        Logger.warning("Failed to fetch /packages/#{name} from upstream: #{reason}")

        conn
        |> put_status(:bad_gateway)
        |> json(%{message: "Failed to fetch registry data from upstream"})
    end
  end

  # Private functions

  defp fetch_upstream_registry(path) do
    config = HexHub.Upstream.config()

    if not config.enabled do
      {:error, "Upstream is disabled"}
    else
      # Use the repo_url for registry endpoints (not api_url)
      url = "#{config.repo_url}#{path}"

      headers = [
        {"user-agent", "HexHub/0.1.0 (Registry-Proxy)"},
        {"accept", "application/octet-stream"}
      ]

      req_opts = [
        receive_timeout: config.timeout,
        headers: headers,
        # Disable automatic decompression - we want the raw gzipped data
        decode_body: false,
        compressed: false
      ]

      case Req.get(url, req_opts) do
        {:ok, %{status: 200, body: body, headers: resp_headers}} ->
          # Extract relevant headers for proxying
          relevant_headers = extract_relevant_headers(resp_headers)
          {:ok, body, relevant_headers}

        {:ok, %{status: 404}} ->
          {:error, :not_found}

        {:ok, %{status: status}} ->
          {:error, "Upstream returned status #{status}"}

        {:error, %Req.TransportError{reason: reason}} ->
          {:error, "Network error: #{inspect(reason)}"}

        {:error, reason} ->
          {:error, "Request failed: #{inspect(reason)}"}
      end
    end
  end

  defp extract_relevant_headers(headers) do
    # Extract headers that should be proxied
    headers
    |> Enum.filter(fn {name, _value} ->
      String.downcase(name) in [
        "content-type",
        "content-encoding",
        "etag",
        "cache-control",
        "last-modified"
      ]
    end)
    |> Enum.map(fn {name, value} ->
      # Normalize header names to lowercase
      {String.downcase(name), value}
    end)
  end

  defp send_registry_response(conn, data, headers) do
    # Apply proxied headers
    conn =
      Enum.reduce(headers, conn, fn {name, value}, acc ->
        # Handle list values (Req returns headers as lists)
        header_value =
          case value do
            [v | _] -> v
            v when is_binary(v) -> v
            v -> to_string(v)
          end

        put_resp_header(acc, name, header_value)
      end)

    # Ensure we have proper content-type if not set
    conn =
      if get_resp_header(conn, "content-type") == [] do
        put_resp_content_type(conn, "application/octet-stream")
      else
        conn
      end

    send_resp(conn, 200, data)
  end
end

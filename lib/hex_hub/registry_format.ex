defmodule HexHub.RegistryFormat do
  @moduledoc """
  Handles encoding/decoding of Hex registry formats.

  Supports both JSON and Erlang Term Format (ETF) with optional gzip compression.
  """

  @doc """
  Encode data to Erlang term format and optionally compress.
  """
  def encode_etf(data, compress \\ true) do
    erlang_term = :erlang.term_to_binary(data)

    if compress do
      :zlib.gzip(erlang_term)
    else
      erlang_term
    end
  end

  @doc """
  Decode Erlang term format data, handling optional gzip compression.
  """
  def decode_etf(data) do
    uncompressed =
      try do
        :zlib.gunzip(data)
      rescue
        _ -> data
      end

    :erlang.binary_to_term(uncompressed, [:safe])
  end

  @doc """
  Convert package data to Hex registry format.

  Returns a map/keyword list compatible with Hex client expectations.
  """
  def format_package_for_registry(package) do
    %{
      name: package.name,
      repository: package.repository_name || "hexpm",
      releases: format_releases_for_registry(package),
      meta: decode_meta(package.meta),
      downloads: %{
        all: package.downloads || 0,
        week: 0,
        day: 0
      },
      inserted_at: format_datetime(package.inserted_at),
      updated_at: format_datetime(package.updated_at)
    }
  end

  @doc """
  Format release data for registry.
  """
  def format_release_for_registry(release) do
    %{
      version: release.version,
      checksum: release.checksum,
      has_docs: release.has_docs || false,
      requirements: decode_requirements(release.requirements),
      retirement: format_retirement(release.retirement),
      inserted_at: format_datetime(release.inserted_at),
      updated_at: format_datetime(release.updated_at)
    }
  end

  # Private helpers

  defp format_releases_for_registry(package) do
    case HexHub.Packages.list_releases(package.name) do
      {:ok, releases} ->
        Enum.map(releases, &format_release_for_registry/1)

      _ ->
        []
    end
  end

  defp decode_meta(meta) when is_binary(meta) do
    case Jason.decode(meta) do
      {:ok, decoded} -> decoded
      {:error, _} -> %{}
    end
  end

  defp decode_meta(meta) when is_map(meta), do: meta
  defp decode_meta(_), do: %{}

  defp decode_requirements(requirements) when is_binary(requirements) do
    case Jason.decode(requirements) do
      {:ok, decoded} -> decoded
      {:error, _} -> %{}
    end
  end

  defp decode_requirements(requirements) when is_map(requirements), do: requirements
  defp decode_requirements(_), do: %{}

  defp format_retirement(nil), do: nil

  defp format_retirement(retirement) do
    %{
      reason: retirement.reason || "other",
      message: retirement.message
    }
  end

  defp format_datetime(%DateTime{} = dt) do
    DateTime.to_iso8601(dt)
  end

  defp format_datetime(_), do: nil

  @doc """
  Check if the request is from a Hex client based on headers.
  """
  def hex_client?(conn) do
    user_agent = Plug.Conn.get_req_header(conn, "user-agent") |> List.first() || ""
    accept = Plug.Conn.get_req_header(conn, "accept") |> List.first() || ""

    String.contains?(user_agent, "Hex/") or
      String.contains?(user_agent, "hex_core") or
      String.contains?(accept, "application/vnd.hex+erlang")
  end

  @doc """
  Determine the response format based on request headers and client.

  Returns :etf for Hex clients, :json otherwise.
  """
  def response_format(conn) do
    if hex_client?(conn) do
      :etf
    else
      :json
    end
  end
end

defmodule HexHubWeb.Parsers.TarballParser do
  @moduledoc """
  A parser that reads binary bodies (tarballs) and stores them in the connection.

  This handles the `application/octet-stream` and `application/vnd.hex+erlang`
  content types used by the hex client for publishing packages.
  """

  @behaviour Plug.Parsers

  @impl true
  def init(opts), do: opts

  @impl true
  def parse(conn, type, subtype, _headers, opts) do
    do_parse_by_type(conn, type, subtype, opts)
  end

  defp do_parse_by_type(conn, "application", "octet-stream", opts) do
    do_parse(conn, opts)
  end

  defp do_parse_by_type(conn, "application", "vnd.hex+erlang", opts) do
    do_parse(conn, opts)
  end

  defp do_parse_by_type(conn, _type, _subtype, _opts) do
    {:next, conn}
  end

  defp do_parse(conn, opts) do
    # Use increased limits for package tarballs
    opts =
      opts
      |> Keyword.put_new(:length, 100_000_000)
      |> Keyword.put_new(:read_length, 1_000_000)
      |> Keyword.put_new(:read_timeout, 120_000)

    case read_full_body(conn, opts, <<>>) do
      {:ok, body, conn} ->
        # Store the raw body in the connection's private storage
        conn = Plug.Conn.put_private(conn, :raw_body, body)
        # Return empty params since the body is binary, not form data
        {:ok, %{}, conn}

      {:error, _reason} ->
        {:error, :timeout}
    end
  end

  # Read the full body, accumulating chunks
  defp read_full_body(conn, opts, acc) do
    case Plug.Conn.read_body(conn, opts) do
      {:ok, body, conn} ->
        {:ok, acc <> body, conn}

      {:more, partial, conn} ->
        read_full_body(conn, opts, acc <> partial)

      {:error, reason} ->
        {:error, reason}
    end
  end
end

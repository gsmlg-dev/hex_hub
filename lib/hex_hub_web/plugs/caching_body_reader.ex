defmodule HexHubWeb.CachingBodyReader do
  @moduledoc """
  A body reader that caches the raw body for later access.

  This is needed for endpoints that need to access the raw body
  after Plug.Parsers has processed it (e.g., hex publish endpoint).
  """

  require Logger

  @doc """
  Read the body and cache it in the connection's private storage.
  """
  def read_body(conn, opts) do
    case Plug.Conn.read_body(conn, opts) do
      {:ok, body, conn} ->
        # Cache the raw body
        Logger.debug("CachingBodyReader: read #{byte_size(body)} bytes (complete)")
        conn = Plug.Conn.put_private(conn, :raw_body, body)
        {:ok, body, conn}

      {:more, body, conn} ->
        # For chunked bodies, accumulate
        existing = conn.private[:raw_body] || ""
        Logger.debug("CachingBodyReader: read #{byte_size(body)} bytes (more)")
        conn = Plug.Conn.put_private(conn, :raw_body, existing <> body)
        {:more, body, conn}

      {:error, reason} ->
        Logger.debug("CachingBodyReader: error #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Get the cached raw body from the connection.
  """
  def get_raw_body(conn) do
    body = conn.private[:raw_body]

    if body do
      Logger.debug("CachingBodyReader: returning cached body of #{byte_size(body)} bytes")
    else
      Logger.debug("CachingBodyReader: no cached body found")
    end

    body
  end
end

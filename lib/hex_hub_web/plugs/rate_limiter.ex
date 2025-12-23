defmodule HexHubWeb.Plugs.RateLimiter do
  @moduledoc """
  Rate limiting plug for API endpoints.
  """

  import Plug.Conn

  @behaviour Plug

  @default_limit 100
  # 1 minute
  @default_window 60_000

  @impl Plug
  def init(opts) do
    limit = Keyword.get(opts, :limit, @default_limit)
    window = Keyword.get(opts, :window, @default_window)
    key = Keyword.get(opts, :key, :ip)

    %{limit: limit, window: window, key: key}
  end

  @impl Plug
  def call(conn, %{limit: limit, window: window, key: key}) do
    key_value = get_key(conn, key)
    bucket_key = "rate_limit:#{key_value}"

    case check_rate(bucket_key, limit, window) do
      {:allow, count} ->
        conn
        |> put_resp_header("x-rate-limit-limit", to_string(limit))
        |> put_resp_header("x-rate-limit-remaining", to_string(limit - count))

      {:deny, _count} ->
        conn
        |> put_resp_header("x-rate-limit-limit", to_string(limit))
        |> put_resp_header("x-rate-limit-remaining", "0")
        |> put_resp_header("retry-after", to_string(div(window, 1000)))
        |> send_resp(429, "Rate limit exceeded")
        |> halt()
    end
  end

  defp get_key(conn, :ip) do
    conn.remote_ip
    |> :inet_parse.ntoa()
    |> to_string()
  end

  defp get_key(conn, :user) do
    (conn.assigns[:current_user] && conn.assigns.current_user.username) || get_key(conn, :ip)
  end

  defp check_rate(key, limit, window) do
    now = System.system_time(:millisecond)
    bucket_start = div(now, window) * window
    key_with_time = "#{key}:#{bucket_start}"

    case :mnesia.dirty_read(:rate_limit, key_with_time) do
      [{:rate_limit, ^key_with_time, count}] when count >= limit ->
        {:deny, count}

      [{:rate_limit, ^key_with_time, count}] ->
        :mnesia.dirty_write({:rate_limit, key_with_time, count + 1})
        {:allow, count + 1}

      [] ->
        # Clean old entries
        cleanup_old_entries(key, bucket_start - window)
        :mnesia.dirty_write({:rate_limit, key_with_time, 1})
        {:allow, 1}
    end
  end

  defp cleanup_old_entries(key, older_than) do
    pattern = {:rate_limit, "#{key}:#{older_than}", :_}

    case :mnesia.dirty_match_object(pattern) do
      [] -> :ok
      entries -> Enum.each(entries, &:mnesia.dirty_delete_object/1)
    end
  end
end

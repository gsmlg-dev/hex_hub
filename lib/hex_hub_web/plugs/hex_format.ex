defmodule HexHubWeb.Plugs.HexFormat do
  @moduledoc """
  Plug to detect Hex client and set appropriate response format.

  Stores the format in conn.assigns for use by controllers.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    format = HexHub.RegistryFormat.response_format(conn)
    assign(conn, :hex_format, format)
  end

  @doc """
  Send response in the appropriate format (JSON or ETF).
  """
  def send_hex_response(conn, data) do
    case conn.assigns[:hex_format] do
      :etf ->
        send_etf_response(conn, data)

      _ ->
        send_json_response(conn, data)
    end
  end

  defp send_etf_response(conn, data) do
    encoded = HexHub.RegistryFormat.encode_etf(data, true)

    conn
    |> put_resp_content_type("application/vnd.hex+erlang")
    |> send_resp(200, encoded)
  end

  defp send_json_response(conn, data) do
    Phoenix.Controller.json(conn, data)
  end
end

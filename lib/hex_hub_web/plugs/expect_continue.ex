defmodule HexHubWeb.Plugs.ExpectContinue do
  @moduledoc """
  A plug that handles the Expect: 100-continue header.

  When a client sends this header, they expect a 100 Continue response
  before sending the request body. This is commonly used by the hex client
  when publishing packages.
  """

  @behaviour Plug

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    case Plug.Conn.get_req_header(conn, "expect") do
      ["100-continue"] ->
        # Send 100 Continue to tell the client to proceed with the body
        Plug.Conn.inform(conn, 100, [])

      _ ->
        conn
    end
  end
end

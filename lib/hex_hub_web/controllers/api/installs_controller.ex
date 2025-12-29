defmodule HexHubWeb.API.InstallsController do
  @moduledoc """
  Controller for Hex client install/update metadata endpoints.

  The Hex client checks `/installs/hex-1.x.csv` to determine if there's a newer
  version of the Hex client available. For a private Hex server, we can either:

  1. Return an empty CSV (client won't try to update from this server)
  2. Proxy to the official builds.hex.pm
  3. Return the current version info

  This implementation returns an empty CSV since Hex client updates should
  come from the official hex.pm repository, not from private servers.
  """

  use HexHubWeb, :controller

  @doc """
  Returns the hex-1.x.csv file for Hex client version checks.

  This endpoint is called by the Hex client to check for updates.
  For private servers, we return an empty CSV to indicate no updates
  are available from this source (users should update from hex.pm).
  """
  def hex_csv(conn, _params) do
    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("cache-control", "public, max-age=3600")
    |> send_resp(200, "")
  end

  @doc """
  Returns the hex-1.x.csv.signed file for Hex client version checks.

  The signed version includes a cryptographic signature for verification.
  For private servers without signing keys, we return an empty response.
  """
  def hex_csv_signed(conn, _params) do
    conn
    |> put_resp_content_type("text/plain")
    |> put_resp_header("cache-control", "public, max-age=3600")
    |> send_resp(200, "")
  end
end

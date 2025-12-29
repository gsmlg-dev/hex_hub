defmodule HexHubWeb.API.InstallsControllerTest do
  use HexHubWeb.ConnCase

  describe "hex_csv/2" do
    test "returns empty CSV for hex-1.x.csv", %{conn: conn} do
      conn = get(conn, ~p"/installs/hex-1.x.csv")

      assert response(conn, 200) == ""
      assert get_resp_header(conn, "content-type") == ["text/csv; charset=utf-8"]
      assert get_resp_header(conn, "cache-control") == ["public, max-age=3600"]
    end
  end

  describe "hex_csv_signed/2" do
    test "returns empty response for hex-1.x.csv.signed", %{conn: conn} do
      conn = get(conn, ~p"/installs/hex-1.x.csv.signed")

      assert response(conn, 200) == ""
      assert get_resp_header(conn, "content-type") == ["text/plain; charset=utf-8"]
      assert get_resp_header(conn, "cache-control") == ["public, max-age=3600"]
    end
  end
end

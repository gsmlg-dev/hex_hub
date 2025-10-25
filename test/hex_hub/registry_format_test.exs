defmodule HexHub.RegistryFormatTest do
  use ExUnit.Case, async: true

  alias HexHub.RegistryFormat

  describe "encode_etf/2" do
    test "encodes data to Erlang term format" do
      data = %{name: "test", version: "1.0.0"}
      encoded = RegistryFormat.encode_etf(data, false)

      assert is_binary(encoded)
      assert :erlang.binary_to_term(encoded) == data
    end

    test "encodes and compresses data with gzip" do
      data = %{name: "test", version: "1.0.0"}
      encoded = RegistryFormat.encode_etf(data, true)

      assert is_binary(encoded)

      # Should be gzipped
      decompressed = :zlib.gunzip(encoded)
      assert :erlang.binary_to_term(decompressed) == data
    end
  end

  describe "decode_etf/1" do
    test "decodes uncompressed Erlang term format" do
      data = %{name: "test", version: "1.0.0"}
      encoded = :erlang.term_to_binary(data)

      assert RegistryFormat.decode_etf(encoded) == data
    end

    test "decodes compressed Erlang term format" do
      data = %{name: "test", version: "1.0.0"}
      encoded = :erlang.term_to_binary(data) |> :zlib.gzip()

      assert RegistryFormat.decode_etf(encoded) == data
    end
  end

  describe "hex_client?/1" do
    test "detects Hex client from user-agent" do
      conn =
        Phoenix.ConnTest.build_conn(:get, "/")
        |> Plug.Conn.put_req_header("user-agent", "Hex/0.20.0 (Elixir/1.12.0) (OTP/24.0)")

      assert RegistryFormat.hex_client?(conn) == true
    end

    test "detects hex_core client from user-agent" do
      conn =
        Phoenix.ConnTest.build_conn(:get, "/")
        |> Plug.Conn.put_req_header("user-agent", "hex_core/0.8.0")

      assert RegistryFormat.hex_client?(conn) == true
    end

    test "detects Hex client from accept header" do
      conn =
        Phoenix.ConnTest.build_conn(:get, "/")
        |> Plug.Conn.put_req_header("accept", "application/vnd.hex+erlang")

      assert RegistryFormat.hex_client?(conn) == true
    end

    test "returns false for non-Hex clients" do
      conn =
        Phoenix.ConnTest.build_conn(:get, "/")
        |> Plug.Conn.put_req_header("user-agent", "Mozilla/5.0")

      assert RegistryFormat.hex_client?(conn) == false
    end
  end

  describe "response_format/1" do
    test "returns :etf for Hex clients" do
      conn =
        Phoenix.ConnTest.build_conn(:get, "/")
        |> Plug.Conn.put_req_header("user-agent", "Hex/0.20.0")

      assert RegistryFormat.response_format(conn) == :etf
    end

    test "returns :json for non-Hex clients" do
      conn =
        Phoenix.ConnTest.build_conn(:get, "/")
        |> Plug.Conn.put_req_header("user-agent", "Mozilla/5.0")

      assert RegistryFormat.response_format(conn) == :json
    end
  end
end

defmodule HexHubWeb.API.ReleaseController do
  use HexHubWeb, :controller

  def show(conn, %{"name" => name, "version" => version}) do
    # TODO: Implement release retrieval
    release = %{
      version: version,
      has_docs: true,
      meta: %{
        build_tools: ["mix"]
      },
      requirements: %{},
      retired: nil,
      downloads: 100,
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now(),
      url: "/packages/#{name}/releases/#{version}",
      package_url: "/packages/#{name}",
      html_url: "https://hex.pm/packages/#{name}/#{version}",
      docs_html_url: "https://hexdocs.pm/#{name}/#{version}"
    }
    
    json(conn, release)
  end

  def publish(conn, _params) do
    # TODO: Implement package publishing
    # This would handle the /publish endpoint for uploading packages
    {:ok, _body, conn} = Plug.Conn.read_body(conn)
    
    # For now, return a mock response
    release = %{
      version: "1.0.0",
      has_docs: false,
      meta: %{build_tools: ["mix"]},
      requirements: %{},
      retired: nil,
      downloads: 0,
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now(),
      url: "/packages/example/releases/1.0.0",
      package_url: "/packages/example",
      html_url: "https://hex.pm/packages/example/1.0.0",
      docs_html_url: "https://hexdocs.pm/example/1.0.0"
    }
    
    conn
    |> put_status(:created)
    |> json(release)
  end

  def retire(conn, %{"name" => _name, "version" => _version}) do
    # TODO: Implement release retirement
    send_resp(conn, 204, "")
  end

  def unretire(conn, %{"name" => _name, "version" => _version}) do
    # TODO: Implement release unretirement
    send_resp(conn, 204, "")
  end
end
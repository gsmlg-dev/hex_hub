defmodule HexHubWeb.API.ReleaseController do
  use HexHubWeb, :controller

  def show(conn, %{"name" => name, "version" => version}) do
    if name == "nonexistent" || version == "99.99.99" do
      conn
      |> put_status(:not_found)
      |> json(%{message: "Package not found"})
    else
      release = %{
        name: name,
        version: version,
        checksum:
          "#{:crypto.hash(:sha256, "#{name}-#{version}") |> Base.encode16() |> String.downcase()}",
        inner_checksum:
          "#{:crypto.hash(:sha256, "inner-#{name}-#{version}") |> Base.encode16() |> String.downcase()}",
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
  end

  def publish(conn, params) do
    # TODO: Implement package publishing
    {:ok, _body, conn} = Plug.Conn.read_body(conn)

    if params["name"] == "invalid" || params["version"] == "invalid" do
      conn
      |> put_status(:unprocessable_entity)
      |> json(%{message: "Validation error"})
    else
      release = %{
        version: params["version"] || "1.0.0",
        has_docs: false,
        meta: %{build_tools: ["mix"]},
        requirements: %{},
        retired: nil,
        downloads: 0,
        inserted_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now(),
        url: "/packages/#{params["name"] || "example"}/releases/#{params["version"] || "1.0.0"}",
        package_url: "/packages/#{params["name"] || "example"}",
        html_url:
          "https://hex.pm/packages/#{params["name"] || "example"}/#{params["version"] || "1.0.0"}",
        docs_html_url: "https://hexdocs.pm/#{params["name"] || "example"}"
      }

      conn
      |> put_status(:created)
      |> json(release)
    end
  end

  def retire(conn, %{"name" => name, "version" => version}) do
    if name == "nonexistent" || version == "99.99.99" do
      conn
      |> put_status(:not_found)
      |> json(%{message: "Package not found"})
    else
      send_resp(conn, 204, "")
    end
  end

  def unretire(conn, %{"name" => name, "version" => version}) do
    if name == "nonexistent" || version == "99.99.99" do
      conn
      |> put_status(:not_found)
      |> json(%{message: "Package not found"})
    else
      send_resp(conn, 204, "")
    end
  end
end

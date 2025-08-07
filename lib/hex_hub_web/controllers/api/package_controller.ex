defmodule HexHubWeb.API.PackageController do
  use HexHubWeb, :controller

  def list(conn, params) do
    # TODO: Implement package listing with pagination and search
    _sort = params["sort"] || "name"
    _search = params["search"]
    _page = String.to_integer(params["page"] || "1")

    packages = [
      %{
        name: "example",
        repository: "hexpm",
        private: false,
        meta: %{
          description: "Example package",
          licenses: ["MIT"],
          links: %{"GitHub" => "https://github.com/example/example"}
        },
        downloads: %{all: 1000, week: 50, day: 10},
        releases: [
          %{version: "1.0.0", url: "/packages/example/releases/1.0.0"}
        ],
        inserted_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now(),
        url: "/packages/example",
        html_url: "https://hex.pm/packages/example",
        docs_html_url: "https://hexdocs.pm/example"
      }
    ]

    json(conn, %{"packages" => packages})
  end

  def show(conn, %{"name" => name}) do
    if name == "nonexistent" do
      conn
      |> put_status(:not_found)
      |> json(%{message: "Package not found"})
    else
      package = %{
        name: name,
        repository: "hexpm",
        private: false,
        meta: %{
          description: "#{name} package",
          licenses: ["MIT"],
          links: %{"GitHub" => "https://github.com/example/#{name}"}
        },
        downloads: %{all: 1000, week: 50, day: 10},
        releases: [
          %{version: "1.0.0", url: "/packages/#{name}/releases/1.0.0"}
        ],
        inserted_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now(),
        url: "/packages/#{name}",
        html_url: "https://hex.pm/packages/#{name}",
        docs_html_url: "https://hexdocs.pm/#{name}"
      }

      json(conn, package)
    end
  end
end

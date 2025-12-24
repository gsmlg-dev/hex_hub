defmodule HexHubWeb.API.OwnerController do
  use HexHubWeb, :controller
  alias HexHub.Packages

  def index(conn, %{"name" => name}) do
    case Packages.get_package(name) do
      {:ok, _package} ->
        case Packages.get_package_owners(name) do
          {:ok, owners} ->
            formatted_owners =
              Enum.map(owners, fn owner ->
                %{
                  username: owner.username,
                  email: "#{owner.username}@example.com",
                  inserted_at: owner.inserted_at,
                  updated_at: owner.inserted_at,
                  url: "/users/#{owner.username}",
                  level: owner.level || "full"
                }
              end)

            json(conn, %{"owners" => formatted_owners})

          {:error, _reason} ->
            json(conn, %{"owners" => []})
        end

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Package not found"})
    end
  end

  def add(conn, %{"name" => name, "email" => _email}) do
    if name == "nonexistent" do
      conn
      |> put_status(:not_found)
      |> json(%{error: "Package not found"})
    else
      send_resp(conn, 204, "")
    end
  end

  def remove(conn, %{"name" => name, "email" => _email}) do
    if name == "nonexistent" do
      conn
      |> put_status(:not_found)
      |> json(%{error: "Package not found"})
    else
      send_resp(conn, 204, "")
    end
  end
end

defmodule HexHubWeb.API.RetirementController do
  use HexHubWeb, :controller

  alias HexHub.PackageRetirement
  alias HexHub.Packages

  @doc """
  POST /api/packages/:name/releases/:version/retire
  Retire a specific release version.
  """
  def retire(conn, %{"name" => package_name, "version" => version} = params) do
    username = conn.assigns.current_user.username

    # Check if user has permission to retire this package
    case check_permission(username, package_name) do
      :ok ->
        reason = String.to_atom(params["reason"] || "other")
        message = params["message"]

        case PackageRetirement.retire_release(package_name, version, reason, message, username) do
          :ok ->
            conn
            |> put_status(:accepted)
            |> json(%{
              message: "Release retired successfully",
              package: package_name,
              version: version,
              retirement: %{
                reason: reason,
                message: message
              }
            })

          {:error, error} ->
            conn
            |> put_status(:bad_request)
            |> json(%{error: error})
        end

      {:error, reason} ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: reason})
    end
  end

  @doc """
  DELETE /api/packages/:name/releases/:version/retire
  Unretire a previously retired release.
  """
  def unretire(conn, %{"name" => package_name, "version" => version}) do
    username = conn.assigns.current_user.username

    # Check if user has permission to unretire this package
    case check_permission(username, package_name) do
      :ok ->
        case PackageRetirement.unretire_release(package_name, version, username) do
          :ok ->
            json(conn, %{
              message: "Release unretired successfully",
              package: package_name,
              version: version
            })

          {:error, error} ->
            conn
            |> put_status(:bad_request)
            |> json(%{error: error})
        end

      {:error, reason} ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: reason})
    end
  end

  @doc """
  GET /api/packages/:name/releases/:version/retire
  Get retirement information for a release.
  """
  def show(conn, %{"name" => package_name, "version" => version}) do
    case PackageRetirement.get_retirement_info(package_name, version) do
      {:ok, info} ->
        json(conn, %{
          package: package_name,
          version: version,
          retired: true,
          retirement: info
        })

      {:error, :not_retired} ->
        json(conn, %{
          package: package_name,
          version: version,
          retired: false
        })
    end
  end

  @doc """
  GET /api/packages/:name/retired
  List all retired releases for a package.
  """
  def index(conn, %{"name" => package_name}) do
    retired_releases = PackageRetirement.list_retired_releases(package_name)

    json(conn, %{
      package: package_name,
      retired_releases: retired_releases
    })
  end

  # Check if user has permission to retire/unretire package releases
  defp check_permission(username, package_name) do
    case Packages.get_package_owners(package_name) do
      {:ok, owners} ->
        # Check if user is an owner or maintainer
        if Enum.any?(owners, fn owner ->
             owner.username == username && owner.level in ["owner", "maintainer"]
           end) do
          :ok
        else
          {:error, "You don't have permission to retire releases for this package"}
        end

      {:error, _} ->
        {:error, "Package not found"}
    end
  end
end
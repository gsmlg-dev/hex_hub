defmodule HexHubAdminWeb.LocalPackageController do
  @moduledoc """
  Controller for managing locally published packages in the admin interface.
  """
  use HexHubAdminWeb, :controller

  alias HexHub.CachedPackages
  alias HexHub.Packages

  @doc """
  Lists all locally published packages with pagination, search, and sorting.
  """
  def index(conn, params) do
    start_time = System.monotonic_time()

    opts = [
      page: parse_int(params["page"], 1),
      per_page: parse_int(params["per_page"], 50) |> min(100),
      search: params["search"],
      sort: parse_sort(params["sort"]),
      sort_dir: parse_sort_dir(params["sort_dir"])
    ]

    case CachedPackages.list_packages_by_source(:local, opts) do
      {:ok, %{packages: packages, pagination: pagination}} ->
        # Emit telemetry event
        duration = System.monotonic_time() - start_time

        :telemetry.execute(
          [:hex_hub, :admin, :local_packages, :listed],
          %{duration: duration},
          %{page: opts[:page], count: length(packages), search: opts[:search]}
        )

        render(conn, :index,
          packages: packages,
          pagination: pagination,
          search: params["search"] || "",
          sort: to_string(opts[:sort]),
          sort_dir: to_string(opts[:sort_dir])
        )

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Failed to load packages")
        |> render(:index,
          packages: [],
          pagination: %{page: 1, per_page: 50, total: 0, total_pages: 1},
          search: "",
          sort: "updated_at",
          sort_dir: "desc"
        )
    end
  end

  @doc """
  Shows details for a specific local package.
  """
  @dialyzer {:nowarn_function, show: 2}
  def show(conn, %{"id" => name}) do
    case CachedPackages.get_package_by_source(name, :local) do
      {:ok, package} ->
        {:ok, releases} = Packages.list_releases(name)
        has_cached = CachedPackages.has_cached_counterpart?(name)

        render(conn, :show,
          package: package,
          releases: releases,
          has_cached_counterpart: has_cached
        )

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Package not found or not a local package")
        |> redirect(to: ~p"/local-packages")
    end
  end

  # Private helpers

  defp parse_int(nil, default), do: default

  defp parse_int(val, default) when is_binary(val) do
    case Integer.parse(val) do
      {int, _} when int > 0 -> int
      _ -> default
    end
  end

  defp parse_int(val, _default) when is_integer(val) and val > 0, do: val
  defp parse_int(_, default), do: default

  defp parse_sort("name"), do: :name
  defp parse_sort("downloads"), do: :downloads
  defp parse_sort("updated_at"), do: :updated_at
  defp parse_sort(_), do: :updated_at

  defp parse_sort_dir("asc"), do: :asc
  defp parse_sort_dir("desc"), do: :desc
  defp parse_sort_dir(_), do: :desc
end

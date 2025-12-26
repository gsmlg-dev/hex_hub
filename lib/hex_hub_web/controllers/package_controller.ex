defmodule HexHubWeb.PackageController do
  use HexHubWeb, :controller
  alias HexHub.Packages

  @per_page 30
  @valid_sorts ~w(recent_downloads total_downloads name recently_updated recently_created)

  def index(conn, params) do
    page = parse_int(params["page"], 1)
    search = params["search"]
    sort = parse_sort(params["sort"])
    letter = parse_letter(params["letter"])

    opts = [
      page: page,
      per_page: @per_page,
      search: search,
      sort: sort,
      letter: letter
    ]

    {packages, total_count} =
      case Packages.list_packages(opts) do
        {:ok, pkgs, total} ->
          enriched_packages = Enum.map(pkgs, &enrich_package_with_latest_version/1)
          {enriched_packages, total}

        _ ->
          {[], 0}
      end

    total_pages = max(1, ceil(total_count / @per_page))

    # Fetch trend data
    most_downloaded =
      Packages.list_most_downloaded(5) |> Enum.map(&enrich_package_with_latest_version/1)

    recently_updated =
      Packages.list_recently_updated(5) |> Enum.map(&enrich_package_with_latest_version/1)

    new_packages =
      Packages.list_new_packages(5) |> Enum.map(&enrich_package_with_latest_version/1)

    render(conn, :index,
      packages: packages,
      page: page,
      per_page: @per_page,
      total_count: total_count,
      total_pages: total_pages,
      search: search,
      sort: sort,
      letter: letter,
      most_downloaded: most_downloaded,
      recently_updated: recently_updated,
      new_packages: new_packages
    )
  end

  defp parse_int(nil, default), do: default

  defp parse_int(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} when int > 0 -> int
      _ -> default
    end
  end

  defp parse_sort(nil), do: :recent_downloads

  defp parse_sort(sort) when sort in @valid_sorts do
    String.to_existing_atom(sort)
  end

  defp parse_sort(_), do: :recent_downloads

  defp parse_letter(nil), do: nil
  defp parse_letter(""), do: nil

  defp parse_letter(letter) when is_binary(letter) do
    letter = String.upcase(String.first(letter))
    if letter =~ ~r/^[A-Z]$/, do: letter, else: nil
  end

  def show(conn, %{"name" => name}) do
    start_time = System.monotonic_time()

    case Packages.get_package(name) do
      {:ok, package} ->
        {:ok, releases} = Packages.list_releases(name)
        enriched_package = enrich_package_with_latest_version(package)

        # Sort releases by version descending
        sorted_releases = Enum.sort_by(releases, & &1.version, {:desc, Version})

        latest_version = get_latest_version(sorted_releases)
        dependencies = get_dependencies(sorted_releases)
        download_stats = get_download_stats(package, sorted_releases)

        duration_ms =
          (System.monotonic_time() - start_time)
          |> System.convert_time_unit(:native, :millisecond)

        :telemetry.execute(
          [:hex_hub, :packages, :view],
          %{duration: duration_ms},
          %{package: name}
        )

        render(conn, :show,
          package: enriched_package,
          releases: sorted_releases,
          latest_version: latest_version,
          dependencies: dependencies,
          download_stats: download_stats
        )

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> assign(:name, name)
        |> render(:not_found)
    end
  end

  defp get_latest_version([]), do: "0.0.0"
  defp get_latest_version([release | _]), do: release.version

  defp get_dependencies([]), do: %{}

  defp get_dependencies([latest_release | _]) do
    case latest_release.requirements do
      reqs when is_map(reqs) -> reqs
      _ -> %{}
    end
  end

  defp get_download_stats(package, releases) do
    total = package.downloads
    # Sum up release downloads for "recent" approximation
    recent = Enum.reduce(releases, 0, fn r, acc -> acc + r.downloads end)

    %{
      total: total,
      recent: recent,
      # Would need additional tracking for accurate weekly stats
      weekly: nil
    }
  end

  def docs(conn, %{"name" => name, "version" => version}) do
    case Packages.get_release(name, version) do
      {:ok, release} when release.has_docs ->
        render(conn, :docs, package: release.package_name, version: release.version)

      {:ok, _release} ->
        conn
        |> put_status(:not_found)
        |> put_view(HexHubWeb.ErrorHTML)
        |> render(:"404", message: "Documentation not found")

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> put_view(HexHubWeb.ErrorHTML)
        |> render(:"404")
    end
  end

  def redirect_to_packages(conn, _params) do
    redirect(conn, to: ~p"/packages")
  end

  def redirect_to_package(conn, %{"name" => name}) do
    redirect(conn, to: ~p"/packages/#{name}")
  end

  defp enrich_package_with_latest_version(package) do
    {:ok, releases} = Packages.list_releases(package.name)

    latest_version =
      case releases do
        [] ->
          "0.0.0"

        releases ->
          releases
          |> Enum.map(& &1.version)
          |> Enum.sort_by(& &1, &>=/2)
          |> List.first()
      end

    Map.put(package, :latest_version, latest_version)
  end
end

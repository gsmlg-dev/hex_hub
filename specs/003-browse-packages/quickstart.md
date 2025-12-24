# Quickstart: Browse Packages Feature

**Feature**: 003-browse-packages
**Date**: 2025-12-25

## Overview

This document provides a quick reference for implementing the Browse Packages feature. It summarizes the key changes needed across the codebase.

---

## Implementation Order

1. **Context Layer** - Extend `HexHub.Packages` with sorting/filtering
2. **Routes** - Add `/packages` and `/packages/:name` routes
3. **Controller** - Implement `PackageController` actions
4. **Templates** - Create list and detail page templates
5. **Tests** - Add context and controller tests
6. **Home Page** - Update link to point to `/packages`

---

## 1. Context: lib/hex_hub/packages.ex

### New/Modified Functions

```elixir
# Extend list_packages with sorting options
def list_packages(opts \\ []) do
  search = Keyword.get(opts, :search)
  sort = Keyword.get(opts, :sort, :recent_downloads)
  letter = Keyword.get(opts, :letter)
  page = Keyword.get(opts, :page, 1)
  per_page = Keyword.get(opts, :per_page, 30)

  # Implementation: fetch all, filter, sort, paginate
end

# Trend query functions
def list_most_downloaded(limit \\ 5)
def list_recently_updated(limit \\ 5)
def list_new_packages(limit \\ 5)
```

### Sort Options

| Atom | Ordering |
|------|----------|
| `:recent_downloads` | downloads DESC |
| `:total_downloads` | downloads DESC |
| `:name` | name ASC |
| `:recently_updated` | updated_at DESC |
| `:recently_created` | inserted_at DESC |

---

## 2. Router: lib/hex_hub_web/router.ex

```elixir
scope "/", HexHubWeb do
  pipe_through :browser

  get "/", PageController, :home

  # Add these routes
  get "/packages", PackageController, :index
  get "/packages/:name", PackageController, :show
end
```

---

## 3. Controller: lib/hex_hub_web/controllers/package_controller.ex

```elixir
defmodule HexHubWeb.PackageController do
  use HexHubWeb, :controller

  alias HexHub.Packages

  def index(conn, params) do
    opts = [
      search: params["search"],
      sort: parse_sort(params["sort"]),
      letter: params["letter"],
      page: parse_int(params["page"], 1),
      per_page: 30
    ]

    {:ok, packages, total} = Packages.list_packages(opts)

    conn
    |> assign(:packages, packages)
    |> assign(:total_count, total)
    |> assign(:page, opts[:page])
    |> assign(:per_page, 30)
    |> assign(:total_pages, ceil(total / 30))
    |> assign(:search, opts[:search])
    |> assign(:sort, opts[:sort])
    |> assign(:letter, opts[:letter])
    |> assign(:most_downloaded, Packages.list_most_downloaded(5))
    |> assign(:recently_updated, Packages.list_recently_updated(5))
    |> assign(:new_packages, Packages.list_new_packages(5))
    |> render(:index)
  end

  def show(conn, %{"name" => name}) do
    case Packages.get_package(name) do
      {:ok, package} ->
        {:ok, releases} = Packages.list_releases(name)

        conn
        |> assign(:package, package)
        |> assign(:releases, releases)
        |> assign(:latest_version, get_latest_version(releases))
        |> assign(:dependencies, get_dependencies(releases))
        |> assign(:download_stats, get_download_stats(package, releases))
        |> render(:show)

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> assign(:name, name)
        |> render(:not_found)
    end
  end

  # Private helpers...
end
```

---

## 4. Templates

### lib/hex_hub_web/controllers/package_html/index.html.heex

Key sections:
- Search form with submit button
- Sort dropdown
- A-Z letter filter bar
- Trend tabs (Most Downloaded, Recently Updated, New)
- Package grid (responsive: 1/2/3 columns)
- Pagination controls
- Empty state

### lib/hex_hub_web/controllers/package_html/show.html.heex

Key sections:
- Package header with name, version, description
- Download statistics (stats component)
- External links (docs, GitHub, changelog)
- Installation snippet (mockup-code)
- Versions table
- Dependencies table

### lib/hex_hub_web/controllers/package_html/not_found.html.heex

- 404 error message
- Link back to /packages

---

## 5. View Helpers: lib/hex_hub_web/controllers/package_html.ex

```elixir
defmodule HexHubWeb.PackageHTML do
  use HexHubWeb, :html

  embed_templates "package_html/*"

  def format_downloads(n)
  def format_relative_time(datetime)
  def page_range(current, total, window \\ 2)
  def license_name(package)
  def preserve_params(conn, updates)
end
```

---

## 6. Tests

### test/hex_hub/packages_test.exs

```elixir
describe "list_packages/1 with sorting" do
  test "sorts by name ascending"
  test "sorts by downloads descending"
  test "sorts by recently_updated"
  test "sorts by recently_created"
  test "filters by letter"
  test "combines search with sort"
end

describe "trend queries" do
  test "list_most_downloaded/1 returns top packages"
  test "list_recently_updated/1 returns recent releases"
  test "list_new_packages/1 returns newest packages"
end
```

### test/hex_hub_web/controllers/package_controller_test.exs

```elixir
describe "GET /packages" do
  test "lists packages with default sort"
  test "filters by search term"
  test "sorts by different options"
  test "filters by letter"
  test "paginates results"
  test "shows empty state when no packages"
end

describe "GET /packages/:name" do
  test "shows package details"
  test "shows versions list"
  test "shows dependencies"
  test "returns 404 for non-existent package"
end
```

---

## 7. Home Page Update

Update `lib/hex_hub_web/controllers/page_html/home.html.heex`:

```diff
- <a href="/browse" class="btn btn-primary btn-lg">
+ <a href="/packages" class="btn btn-primary btn-lg">
    Browse Packages
```

---

## Telemetry Events

Add to context functions:

```elixir
:telemetry.execute(
  [:hex_hub, :packages, :browse],
  %{duration: duration_ms},
  %{page: page, sort: sort, search: search, results: total}
)

:telemetry.execute(
  [:hex_hub, :packages, :view],
  %{duration: duration_ms},
  %{package: name}
)
```

---

## DaisyUI Components Used

| Component | Usage |
|-----------|-------|
| `card` | Package entries |
| `badge` | Version, downloads, license |
| `input` | Search field |
| `select` | Sort dropdown |
| `btn` | Pagination, filters, actions |
| `tabs` | Trend sections |
| `stats` | Download statistics |
| `table` | Versions, dependencies |
| `mockup-code` | Installation snippet |
| `hero` | 404 page |

---

## Checklist

- [x] Extend `HexHub.Packages` with sort/filter options
- [x] Add trend query functions
- [x] Add routes to router.ex
- [x] Implement `PackageController.index/2`
- [x] Implement `PackageController.show/2`
- [x] Create index.html.heex template
- [x] Create show.html.heex template
- [x] Create not_found.html.heex template
- [x] Add view helper functions
- [x] Add context tests
- [x] Add controller tests
- [x] Update home page link
- [x] Add telemetry events
- [ ] Verify with `mix test`
- [ ] Verify with `mix format`
- [ ] Verify with `mix credo`

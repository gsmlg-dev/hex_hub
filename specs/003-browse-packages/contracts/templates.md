# Template Contracts: Browse Packages

**Feature**: 003-browse-packages
**Date**: 2025-12-25

## Package List Template (index.html.heex)

### Layout Structure

```
┌─────────────────────────────────────────────────────────────┐
│  Header: "Packages" + Search Bar                            │
├─────────────────────────────────────────────────────────────┤
│  Trend Sections (collapsible tabs)                          │
│  ┌─────────────┬─────────────────┬────────────────┐         │
│  │ Most        │ Recently        │ New            │         │
│  │ Downloaded  │ Updated         │ Packages       │         │
│  └─────────────┴─────────────────┴────────────────┘         │
├─────────────────────────────────────────────────────────────┤
│  Filters Bar                                                │
│  [Sort: ▼ Recent Downloads] [A-Z filter letters...]         │
├─────────────────────────────────────────────────────────────┤
│  Results: "X packages found"                                │
├─────────────────────────────────────────────────────────────┤
│  Package List (grid)                                        │
│  ┌─────────────────────┐ ┌─────────────────────┐            │
│  │ package_name        │ │ another_package     │            │
│  │ v1.2.3  ▼ 10.5K    │ │ v0.1.0  ▼ 500      │            │
│  │ Description...      │ │ Description...      │            │
│  │ Updated: 2 days ago │ │ Updated: 1 week ago │            │
│  └─────────────────────┘ └─────────────────────┘            │
│  ... (30 packages)                                          │
├─────────────────────────────────────────────────────────────┤
│  Pagination                                                 │
│  [← Prev] [1] [2] [3] ... [10] [Next →]                     │
└─────────────────────────────────────────────────────────────┘
```

### Components

#### Search Form
```html
<form action="/packages" method="get" class="join">
  <input type="text" name="search" placeholder="Search packages..."
         value={@search} class="input input-bordered join-item" />
  <button type="submit" class="btn btn-primary join-item">Search</button>
</form>
```

#### Sort Dropdown
```html
<select name="sort" class="select select-bordered" onchange="this.form.submit()">
  <option value="recent_downloads">Recent Downloads</option>
  <option value="total_downloads">Total Downloads</option>
  <option value="name">Name (A-Z)</option>
  <option value="recently_updated">Recently Updated</option>
  <option value="recently_created">Recently Created</option>
</select>
```

#### A-Z Filter
```html
<div class="flex flex-wrap gap-1">
  <a href="?letter=" class="btn btn-sm {if @letter == nil, 'btn-primary'}">All</a>
  <%= for letter <- ?A..?Z do %>
    <a href="?letter=<%= <<letter>> %>"
       class="btn btn-sm {if @letter == <<letter>>, 'btn-primary'}">
      <%= <<letter>> %>
    </a>
  <% end %>
</div>
```

#### Package Card
```html
<div class="card bg-base-100 shadow-md hover:shadow-lg transition-shadow">
  <div class="card-body p-4">
    <h3 class="card-title text-lg">
      <a href="/packages/{name}" class="link link-hover">{name}</a>
    </h3>
    <div class="flex gap-2 my-2">
      <span class="badge badge-primary">{latest_version}</span>
      <span class="badge badge-ghost">▼ {format_downloads(downloads)}</span>
    </div>
    <p class="text-sm text-base-content/70 line-clamp-2">{description}</p>
    <div class="text-xs text-base-content/50 mt-2">
      Updated {format_relative_time(updated_at)}
    </div>
  </div>
</div>
```

#### Trend Section Tab
```html
<div class="tabs tabs-boxed mb-4">
  <a class="tab tab-active">Most Downloaded</a>
  <a class="tab">Recently Updated</a>
  <a class="tab">New Packages</a>
</div>
<div class="grid grid-cols-1 md:grid-cols-5 gap-4">
  <!-- Compact package cards for trends -->
</div>
```

#### Pagination
```html
<div class="join">
  <a href="?page={@page - 1}" class="join-item btn" disabled={@page == 1}>«</a>
  <%= for page_num <- page_range(@page, @total_pages) do %>
    <a href="?page={page_num}"
       class="join-item btn {if page_num == @page, 'btn-active'}">{page_num}</a>
  <% end %>
  <a href="?page={@page + 1}" class="join-item btn" disabled={@page == @total_pages}>»</a>
</div>
```

#### Empty State
```html
<div class="text-center py-12">
  <div class="text-6xl mb-4">📦</div>
  <h3 class="text-xl font-semibold mb-2">No packages found</h3>
  <p class="text-base-content/70">
    <%= if @search do %>
      No packages match "<%= @search %>". Try a different search term.
    <% else %>
      No packages have been published yet.
    <% end %>
  </p>
</div>
```

---

## Package Detail Template (show.html.heex)

### Layout Structure

```
┌─────────────────────────────────────────────────────────────┐
│  Breadcrumb: Packages > package_name                        │
├─────────────────────────────────────────────────────────────┤
│  Header                                                     │
│  ┌─────────────────────────────────────┬───────────────────┐│
│  │ package_name                        │  Downloads Stats  ││
│  │ Latest version badge                │  ┌─────┬─────┐   ││
│  │ Description                         │  │Total│Weekly│   ││
│  │ License: MIT                        │  │145M │139K │   ││
│  │ [Docs] [GitHub] [Changelog]         │  └─────┴─────┘   ││
│  └─────────────────────────────────────┴───────────────────┘│
├─────────────────────────────────────────────────────────────┤
│  Installation                                               │
│  ┌─────────────────────────────────────────────────────────┐│
│  │ # mix.exs                                               ││
│  │ {:package_name, "~> 1.2"}                               ││
│  └─────────────────────────────────────────────────────────┘│
├─────────────────────────────────────────────────────────────┤
│  Versions                                                   │
│  ┌──────────┬────────────────┬──────────────────┐          │
│  │ Version  │ Released       │ Actions          │          │
│  ├──────────┼────────────────┼──────────────────┤          │
│  │ 1.2.0    │ 2 days ago     │ [Docs] [Diff]    │          │
│  │ 1.1.0    │ 1 month ago    │ [Docs] [Diff]    │          │
│  │ 1.0.0    │ 3 months ago   │ [Docs]           │          │
│  └──────────┴────────────────┴──────────────────┘          │
├─────────────────────────────────────────────────────────────┤
│  Dependencies                                               │
│  ┌──────────────────┬────────────────┬─────────────┐       │
│  │ Package          │ Version        │ Optional    │       │
│  ├──────────────────┼────────────────┼─────────────┤       │
│  │ phoenix          │ ~> 1.7         │ No          │       │
│  │ jason            │ ~> 1.0         │ Yes         │       │
│  └──────────────────┴────────────────┴─────────────┘       │
└─────────────────────────────────────────────────────────────┘
```

### Components

#### Header Section
```html
<div class="flex flex-col lg:flex-row justify-between gap-6 mb-8">
  <div>
    <h1 class="text-3xl font-bold mb-2">{@package.name}</h1>
    <span class="badge badge-lg badge-primary">{@latest_version}</span>
    <p class="text-lg mt-4">{@package.meta["description"]}</p>
    <div class="flex gap-4 mt-4">
      <span class="badge badge-outline">{license}</span>
      <!-- External links -->
      <%= if @package.docs_html_url do %>
        <a href={@package.docs_html_url} class="link">Documentation</a>
      <% end %>
      <%= for {name, url} <- @package.meta["links"] || %{} do %>
        <a href={url} class="link">{name}</a>
      <% end %>
    </div>
  </div>

  <!-- Stats -->
  <div class="stats shadow">
    <div class="stat">
      <div class="stat-title">Total Downloads</div>
      <div class="stat-value text-primary">{format_downloads(@download_stats.total)}</div>
    </div>
    <div class="stat">
      <div class="stat-title">This Week</div>
      <div class="stat-value">{format_downloads(@download_stats.weekly)}</div>
    </div>
  </div>
</div>
```

#### Installation Code Block
```html
<div class="mockup-code mb-8">
  <pre data-prefix="#"><code>mix.exs</code></pre>
  <pre data-prefix=""><code>{:<%=@package.name%>, "~> <%=@latest_version%>"}</code></pre>
</div>
```

#### Versions Table
```html
<div class="overflow-x-auto">
  <table class="table">
    <thead>
      <tr>
        <th>Version</th>
        <th>Released</th>
        <th>Actions</th>
      </tr>
    </thead>
    <tbody>
      <%= for release <- @releases do %>
        <tr class={if release.retired, "opacity-50"}>
          <td>
            {release.version}
            <%= if release.retired do %>
              <span class="badge badge-warning badge-sm">Retired</span>
            <% end %>
          </td>
          <td>{format_relative_time(release.inserted_at)}</td>
          <td>
            <%= if release.has_docs do %>
              <a href={release.docs_html_url} class="btn btn-xs">Docs</a>
            <% end %>
          </td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
```

#### Dependencies Table
```html
<div class="overflow-x-auto">
  <table class="table">
    <thead>
      <tr>
        <th>Package</th>
        <th>Version Requirement</th>
        <th>Optional</th>
      </tr>
    </thead>
    <tbody>
      <%= for {name, req} <- @dependencies do %>
        <tr>
          <td>
            <a href="/packages/{name}" class="link">{name}</a>
          </td>
          <td><code>{req["requirement"]}</code></td>
          <td>{if req["optional"], "Yes", "No"}</td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
```

#### 404 Error Page
```html
<div class="hero min-h-[50vh]">
  <div class="hero-content text-center">
    <div>
      <h1 class="text-5xl font-bold">Package Not Found</h1>
      <p class="py-6">The package "{@name}" does not exist in this registry.</p>
      <a href="/packages" class="btn btn-primary">Browse All Packages</a>
    </div>
  </div>
</div>
```

---

## Helper Functions (package_html.ex)

```elixir
defmodule HexHubWeb.PackageHTML do
  use HexHubWeb, :html

  embed_templates "package_html/*"

  def format_downloads(nil), do: "N/A"
  def format_downloads(n) when n >= 1_000_000, do: "#{Float.round(n / 1_000_000, 1)}M"
  def format_downloads(n) when n >= 1_000, do: "#{Float.round(n / 1_000, 1)}K"
  def format_downloads(n), do: to_string(n)

  def format_relative_time(datetime) do
    # Returns "2 days ago", "1 month ago", etc.
  end

  def page_range(current, total, window \\ 2) do
    # Returns list of page numbers to display
  end

  def license_name(package) do
    case package.meta["licenses"] do
      [license | _] -> license
      _ -> "Unknown"
    end
  end
end
```

# Routes Contract: Browse Packages

**Feature**: 003-browse-packages
**Date**: 2025-12-25

## Browser Routes

All routes use the `:browser` pipeline (HTML responses with session handling).

---

### GET /packages

**Controller**: `HexHubWeb.PackageController.index/2`

**Query Parameters**:
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `search` | String | nil | Search term for name/description |
| `sort` | String | "recent_downloads" | Sort order |
| `letter` | String | nil | A-Z filter (single letter) |
| `page` | Integer | 1 | Page number |

**Sort Options**:
- `recent_downloads` - By recent download count (default)
- `total_downloads` - By all-time download count
- `name` - Alphabetically A-Z
- `recently_updated` - By last release date
- `recently_created` - By package creation date

**Response**: HTML page with:
- Package list (30 per page)
- Search form
- Sort dropdown
- A-Z filter bar
- Trend sections (Most Downloaded, Recently Updated, New Packages)
- Pagination controls
- Result count

**Assigns**:
```elixir
%{
  packages: [package],           # List of packages for current page
  total_count: integer,          # Total matching packages
  page: integer,                 # Current page
  per_page: 30,                  # Items per page
  total_pages: integer,          # Total pages
  search: string | nil,          # Current search term
  sort: atom,                    # Current sort option
  letter: string | nil,          # Current letter filter
  most_downloaded: [package],    # Top 5 by downloads
  recently_updated: [package],   # Top 5 by recent release
  new_packages: [package]        # Top 5 newest
}
```

---

### GET /packages/:name

**Controller**: `HexHubWeb.PackageController.show/2`

**Path Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| `name` | String | Package name |

**Response (200)**: HTML page with:
- Package header (name, description, latest version)
- Download statistics (recent, weekly, total)
- External links (docs, repository, changelog)
- License information
- Versions list with release dates
- Dependencies table
- mix.exs installation snippet

**Response (404)**: Error page with:
- "Package not found" message
- Link back to /packages

**Assigns**:
```elixir
%{
  package: package,              # Package data
  releases: [release],           # All releases, newest first
  latest_version: string,        # Most recent version
  dependencies: [dependency],    # Parsed from latest release requirements
  download_stats: %{             # Aggregated statistics
    total: integer,
    recent: integer,
    weekly: integer | nil
  }
}
```

---

## Route Changes to router.ex

```elixir
scope "/", HexHubWeb do
  pipe_through :browser

  get "/", PageController, :home

  # Package browsing routes (new)
  get "/packages", PackageController, :index
  get "/packages/:name", PackageController, :show

  # Legacy redirect (optional)
  get "/browse", PackageController, :redirect_to_packages
end
```

**Note**: The existing `/browse` route should redirect to `/packages` for backward compatibility with any existing links.

---

## Template Structure

```
lib/hex_hub_web/controllers/package_html/
├── index.html.heex      # Package list page
└── show.html.heex       # Package detail page
```

---

## Error Handling

| Scenario | Response |
|----------|----------|
| Invalid page number | Redirect to page 1 |
| Invalid sort option | Use default (recent_downloads) |
| Invalid letter | Ignore filter |
| Package not found | Render 404 page |
| Mnesia error | Render 500 page with friendly message |

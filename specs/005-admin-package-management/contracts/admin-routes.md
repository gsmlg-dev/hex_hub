# Admin Routes Contract

**Date**: 2025-12-28
**Feature**: 005-admin-package-management

## Route Overview

All routes are within the `HexHubAdminWeb` scope and use the `:browser` pipeline.

## Local Packages Routes

### GET /local-packages

**Controller**: `LocalPackageController.index/2`

**Query Parameters**:
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| page | integer | 1 | Page number (1-indexed) |
| per_page | integer | 50 | Items per page (max 100) |
| search | string | nil | Package name search term |
| sort | string | "updated_at" | Sort field: name, downloads, updated_at |
| sort_dir | string | "desc" | Sort direction: asc, desc |

**Response**: Renders `index.html` with:
- `@packages` - List of local packages with metadata
- `@pagination` - Page info (current, total, per_page)
- `@search` - Current search term
- `@sort` - Current sort settings

### GET /local-packages/:name

**Controller**: `LocalPackageController.show/2`

**Path Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| name | string | Package name |

**Response**: Renders `show.html` with:
- `@package` - Package details
- `@releases` - List of all versions
- `@has_cached_counterpart` - Boolean if cached version exists

**Error**: 404 if package not found or not local

## Cached Packages Routes

### GET /cached-packages

**Controller**: `CachedPackageController.index/2`

**Query Parameters**:
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| page | integer | 1 | Page number (1-indexed) |
| per_page | integer | 50 | Items per page (max 100) |
| search | string | nil | Package name search term |
| sort | string | "updated_at" | Sort field: name, downloads, updated_at |
| sort_dir | string | "desc" | Sort direction: asc, desc |

**Response**: Renders `index.html` with:
- `@packages` - List of cached packages with status annotation
- `@pagination` - Page info
- `@search` - Current search term
- `@sort` - Current sort settings
- `@total_cache_size` - Aggregate storage used (optional)

### GET /cached-packages/:name

**Controller**: `CachedPackageController.show/2`

**Path Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| name | string | Package name |

**Response**: Renders `show.html` with:
- `@package` - Package details with status
- `@releases` - List of cached versions
- `@is_shadowed` - Boolean if local version exists
- `@local_package` - Local package details if shadowed

**Error**: 404 if package not found or not cached

### DELETE /cached-packages/:name

**Controller**: `CachedPackageController.delete/2`

**Path Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| name | string | Package name to delete |

**Response**:
- Success: Redirect to `/cached-packages` with flash message
- Error: Redirect with error flash

**Side Effects**:
- Deletes package record from Mnesia
- Deletes all version releases from Mnesia
- Deletes tarballs from storage
- Emits telemetry event

### DELETE /cached-packages

**Controller**: `CachedPackageController.clear_all/2`

**Query Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| confirm | boolean | Must be "true" to proceed |

**Response**:
- Success: Redirect to `/cached-packages` with count in flash
- Error: Redirect with error flash if confirm not true

**Side Effects**:
- Deletes all cached packages and releases
- Deletes all cached tarballs from storage
- Emits telemetry event with count

## Unified Search Route

### GET /packages/search

**Controller**: `PackageController.search/2` (existing controller extended)

**Query Parameters**:
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| q | string | required | Search query |
| source | string | "all" | Filter: all, local, cached |
| page | integer | 1 | Page number |

**Response**: Renders `search.html` with:
- `@results` - Combined list with source and status annotations
- `@query` - Current search term
- `@source_filter` - Current source filter
- `@pagination` - Page info

## Router Definition

```elixir
# In lib/hex_hub_admin_web/router.ex

scope "/", HexHubAdminWeb do
  pipe_through :browser

  # Existing routes...

  # New routes for package management
  resources "/local-packages", LocalPackageController, only: [:index, :show]

  resources "/cached-packages", CachedPackageController, only: [:index, :show, :delete]
  delete "/cached-packages", CachedPackageController, :clear_all

  # Extended search (add to existing package controller)
  get "/packages/search", PackageController, :search
end
```

## Authentication

Per clarification: No additional authentication required beyond basic admin access.

All routes protected by existing admin authentication pipeline (when implemented).

## Telemetry Events

| Event | Measurements | Metadata |
|-------|--------------|----------|
| `[:hex_hub, :admin, :local_packages, :listed]` | duration | page, count, search |
| `[:hex_hub, :admin, :cached_packages, :listed]` | duration | page, count, search |
| `[:hex_hub, :admin, :cached_package, :deleted]` | duration | package_name |
| `[:hex_hub, :admin, :cache, :cleared]` | duration | count |

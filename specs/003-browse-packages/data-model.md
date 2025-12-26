# Data Model: Browse Packages Feature

**Feature**: 003-browse-packages
**Date**: 2025-12-25

## Overview

This feature uses existing Mnesia tables. No schema changes required. This document describes the data structures as used by the browse functionality.

---

## Entities

### Package

**Table**: `:packages` (Mnesia set table)
**Primary Key**: `name`

| Field | Type | Description | Used By |
|-------|------|-------------|---------|
| `name` | String | Unique package identifier | List, detail, search |
| `repository_name` | String | Repository ("hexpm") | List display |
| `meta` | Map | Package metadata | See meta fields below |
| `private` | Boolean | Private package flag | Filtering (future) |
| `downloads` | Integer | Total download count | List sorting, detail stats |
| `inserted_at` | DateTime | Creation timestamp | "Recently Created" sort |
| `updated_at` | DateTime | Last update timestamp | "Recently Updated" sort |
| `html_url` | String | Web URL for package | External links |
| `docs_html_url` | String | Documentation URL | External links |

**Meta fields** (within `meta` map):
| Field | Type | Description |
|-------|------|-------------|
| `description` | String | Package description |
| `licenses` | List[String] | License identifiers (e.g., ["MIT"]) |
| `links` | Map | External links (GitHub, docs, etc.) |
| `maintainers` | List[String] | Maintainer names |
| `extra` | Map | Additional metadata |

---

### Release

**Table**: `:package_releases` (Mnesia bag table)
**Primary Key**: `{package_name, version}`

| Field | Type | Description | Used By |
|-------|------|-------------|---------|
| `package_name` | String | Parent package name | Association |
| `version` | String | Semantic version string | Version list, detail |
| `has_docs` | Boolean | Documentation published | Doc links |
| `meta` | Map | Release metadata | Build tools, extra |
| `requirements` | Map | Dependency specifications | Dependencies section |
| `retired` | Boolean | Retirement status | Version display |
| `downloads` | Integer | Version-specific downloads | Statistics |
| `inserted_at` | DateTime | Release publish date | Version list, sorting |
| `updated_at` | DateTime | Last update | - |
| `url` | String | Tarball URL | - |
| `package_url` | String | Package API URL | - |
| `html_url` | String | Release web URL | - |
| `docs_html_url` | String | Version docs URL | Doc links |

**Requirements format** (within `requirements` map):
```elixir
%{
  "phoenix" => %{
    "requirement" => "~> 1.7",
    "optional" => false,
    "app" => "phoenix",
    "repository" => "hexpm"
  }
}
```

---

### Download Statistics (Optional)

**Table**: `:package_downloads` (Mnesia set table)
**Primary Key**: `{package_name, version}`

| Field | Type | Description | Used By |
|-------|------|-------------|---------|
| `package_name` | String | Package name | Statistics lookup |
| `version` | String | Version string | Per-version stats |
| `day_count` | Integer | Downloads today | Daily stats |
| `week_count` | Integer | Downloads this week | Weekly stats |
| `all_count` | Integer | All-time downloads | Total stats |

**Note**: This table may not be populated. Fallback to `package.downloads` and `release.downloads` when unavailable.

---

## Query Patterns

### List Packages with Sorting

```elixir
# Options: search, sort, letter, page, per_page
def list_packages(opts \\ [])

# Sort options:
# :recent_downloads - downloads desc (default)
# :total_downloads  - downloads desc
# :name             - name asc (A-Z)
# :recently_updated - updated_at desc
# :recently_created - inserted_at desc
```

### Search Packages

```elixir
# Case-insensitive substring match on name and description
def search_packages(query, opts \\ [])
```

### Letter Filter

```elixir
# Filter packages starting with specific letter
def list_packages(letter: "P", ...)
```

### Trend Queries

```elixir
# Top packages by downloads
def list_most_downloaded(limit \\ 5)

# Most recently released
def list_recently_updated(limit \\ 5)

# Newest packages
def list_new_packages(limit \\ 5)
```

### Get Package with Releases

```elixir
# Get package and all its releases
def get_package(name)
def list_releases(package_name)
```

---

## Relationships

```
Package (1) ──────── (N) Release
   │                      │
   │                      └── requirements (Map of dependencies)
   │
   └── meta.links (external URLs)
```

---

## Validation Rules

| Entity | Field | Validation |
|--------|-------|------------|
| Package | name | Required, unique, lowercase alphanumeric + underscore |
| Package | downloads | Non-negative integer |
| Release | version | Valid semver format |
| Release | requirements | Valid dependency format |

---

## State Transitions

### Package Lifecycle
```
Created → Published → Updated → (optionally) Deprecated
```

### Release Lifecycle
```
Published → (optionally) Retired
```

**Note**: This feature is read-only; no state transitions occur through browse functionality.

---

## Indexes

**Existing indexes** (from Mnesia schema):
- `:packages` indexed on `inserted_at`
- `:package_releases` indexed on `inserted_at`

**Recommended future indexes** (for large registries):
- `:packages` index on `downloads` for efficient sorting
- `:packages` index on first letter of `name` for A-Z filter

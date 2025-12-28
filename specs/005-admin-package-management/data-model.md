# Data Model: Admin Package Management

**Date**: 2025-12-28
**Feature**: 005-admin-package-management

## Entity Changes

### Package (Modified)

**Current Mnesia Record** (`:packages` table, 10 fields):
```
{:packages, name, repository_name, meta, private, downloads, inserted_at, updated_at, html_url, docs_html_url}
```

**New Mnesia Record** (`:packages` table, 11 fields):
```
{:packages, name, repository_name, meta, private, downloads, inserted_at, updated_at, html_url, docs_html_url, source}
```

| Field | Type | Description |
|-------|------|-------------|
| name | String | Unique package identifier (primary key) |
| repository_name | String | Repository this package belongs to |
| meta | Map | Package metadata (description, licenses, links, maintainers) |
| private | Boolean | Whether package is private |
| downloads | Integer | Total download count |
| inserted_at | Integer | Unix timestamp of creation |
| updated_at | Integer | Unix timestamp of last update |
| html_url | String | URL to package page |
| docs_html_url | String | URL to documentation |
| **source** | Atom | **NEW**: `:local` (published directly) or `:cached` (fetched from upstream) |

**Migration**: Existing records default to `source: :local`

### Package Release (Unchanged)

No changes required. Releases inherit source from their parent package.

```
{:package_releases, package_name, version, has_docs, meta, requirements, retired, downloads, inserted_at, updated_at, url, package_url, html_url, docs_html_url}
```

## Derived Types (Runtime Only)

### AnnotatedPackage

Used in admin views to show resolution priority. Not persisted.

```elixir
%{
  name: String.t(),
  repository_name: String.t(),
  meta: map(),
  private: boolean(),
  downloads: integer(),
  inserted_at: DateTime.t(),
  updated_at: DateTime.t(),
  source: :local | :cached,
  status: :active | :shadowed,  # Computed at query time
  versions: [String.t()],       # Aggregated from releases
  latest_version: String.t()    # Most recent version
}
```

**Status Logic**:
- `:active` - This package will be served to clients
- `:shadowed` - A local package with the same name takes precedence

## Relationships

```
Package (1) ─────── (*) PackageRelease
    │                      │
    └── source: :local     └── (inherits source from package)
    └── source: :cached
```

## Validation Rules

### Package Source

- **Required**: Every package MUST have a source field
- **Immutable**: Source cannot be changed after creation
- **Values**: Only `:local` or `:cached` are valid

### Package Name Uniqueness

- Names are unique within a source (existing behavior)
- Names CAN overlap between sources (local + cached with same name)
- When overlapping: local takes precedence for serving

## State Transitions

### Cached Package Lifecycle

```
[Does Not Exist] ──fetch from upstream──> [Cached (Active)]
                                                │
    ┌───────────────────────────────────────────┘
    │
    ▼
[Cached (Active)] ──local package published──> [Cached (Shadowed)]
    │                                                │
    │                                                │
    ▼                                                ▼
[Deleted] <───admin delete────────────────────[Cached (Shadowed)]
    │                                                │
    │                                                ▼
    │         [Cached (Active)] <──local package deleted──┘
    │
    ▼
[Refetched from Upstream] ──> [Cached (Active)]
```

### Local Package Lifecycle

```
[Does Not Exist] ──publish──> [Local (Active)]
                                    │
                                    ▼
                            [Local (Active)]
                                    │
                                    ▼
                              [Deleted]
```

## Query Patterns

### List Local Packages

```elixir
:mnesia.select(:packages, [
  {{:packages, :"$1", :"$2", :"$3", :"$4", :"$5", :"$6", :"$7", :"$8", :"$9", :local},
   [],
   [:"$$"]}
])
```

### List Cached Packages

```elixir
:mnesia.select(:packages, [
  {{:packages, :"$1", :"$2", :"$3", :"$4", :"$5", :"$6", :"$7", :"$8", :"$9", :cached},
   [],
   [:"$$"]}
])
```

### Find Shadowed Packages

```elixir
# Get all cached packages
cached = list_packages_by_source(:cached)

# Get local package names
local_names =
  list_packages_by_source(:local)
  |> Enum.map(& &1.name)
  |> MapSet.new()

# Filter cached packages that have local counterparts
Enum.filter(cached, fn pkg -> MapSet.member?(local_names, pkg.name) end)
```

## Data Volume Assumptions

| Metric | Expected | Design Consideration |
|--------|----------|---------------------|
| Local packages | 10-100 | Primary use case |
| Cached packages | 100-1000 | Depends on upstream usage |
| Total packages | 1000 max | Pagination at 50/page |
| Versions per package | 1-20 | Version history display |
| Package names length | 1-50 chars | Search indexing |

## Index Recommendations

### Existing Indices (Keep)

- Primary: `name` (set type)
- Secondary: `repository_name`

### New Index (Add)

- Secondary: `source` - for efficient source filtering

```elixir
:mnesia.add_table_index(:packages, :source)
```

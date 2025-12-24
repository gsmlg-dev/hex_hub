# Research: Browse Packages Feature

**Feature**: 003-browse-packages
**Date**: 2025-12-25

## Research Summary

No critical unknowns requiring external research. The existing HexHub codebase provides all necessary infrastructure for implementing the browse packages feature.

---

## 1. Existing Infrastructure Analysis

### Decision: Extend existing `HexHub.Packages` context
**Rationale**: The context already provides `list_packages/1`, `get_package/1`, `search_packages/2`, and `list_releases/1` functions. These can be extended with additional sorting and filtering options.

**Alternatives considered**:
- Create new context module → Rejected: Would violate DRY principle and create duplicate data access patterns
- Use Ecto for queries → Rejected: Project uses Mnesia, not Ecto; would violate Constitution Principle III

### Current Capabilities (from codebase exploration):

| Function | Location | Current Behavior |
|----------|----------|------------------|
| `list_packages/1` | `packages.ex:146-193` | Pagination, search, sorts by downloads desc |
| `get_package/1` | `packages.ex:112-141` | Get single package with upstream fallback |
| `list_releases/1` | `packages.ex:327-341` | Get all releases for a package |
| `search_packages/2` | `packages.ex:198-205` | Search by name/description |

### Required Extensions:

1. **Sorting options**: Add `:sort` option to `list_packages/1`
   - `:recent_downloads` (default), `:total_downloads`, `:name`, `:recently_updated`, `:recently_created`

2. **Letter filter**: Add `:letter` option for A-Z filtering

3. **Trend queries**: Add functions for curated sections
   - `list_most_downloaded/1` - Top packages by total downloads
   - `list_recently_updated/1` - Most recent releases
   - `list_new_packages/1` - Newest packages

---

## 2. Mnesia Query Patterns

### Decision: Use QLC (Query List Comprehensions) for complex queries
**Rationale**: Mnesia's QLC provides SQL-like query capabilities with sorting and filtering. Already used in existing codebase.

**Current pattern** (from `packages.ex`):
```elixir
:mnesia.transaction(fn ->
  :qlc.eval(:qlc.q([pkg || pkg <- :mnesia.table(:packages)]))
end)
```

### Sorting Implementation Strategy:
- Mnesia doesn't have native ORDER BY; sort in Elixir after fetching
- For large datasets, consider cursor-based pagination (future optimization)
- Current approach: Fetch all, filter, sort, then paginate in memory

---

## 3. Route Structure

### Decision: Use `/packages` instead of existing `/browse`
**Rationale**: Matches hex.pm URL structure; more intuitive for users.

**Routes to implement**:
| Route | Controller Action | Description |
|-------|-------------------|-------------|
| `GET /packages` | `PackageController.index/2` | Package list with search/sort/filter |
| `GET /packages/:name` | `PackageController.show/2` | Package detail page |

**Note**: Existing `/browse` route can redirect to `/packages` for backward compatibility.

---

## 4. Template Patterns

### Decision: Use DaisyUI components with Tailwind
**Rationale**: Constitution mandates Tailwind CSS + DaisyUI for consistent styling.

**Components to use**:
- `card` - Package entries in list view
- `badge` - Version, download counts, license
- `input` - Search field
- `select` - Sort dropdown
- `btn` - Filter buttons, pagination
- `tabs` - Trend sections navigation
- `stat` - Download statistics on detail page
- `table` - Versions and dependencies lists

---

## 5. Telemetry Events

### Decision: Emit telemetry for page views and searches
**Rationale**: Constitution Principle VII mandates telemetry-first observability.

**Events to emit**:
| Event | Measurements | Metadata |
|-------|--------------|----------|
| `[:hex_hub, :packages, :browse]` | `%{duration: ms}` | `%{page: n, sort: atom, search: term}` |
| `[:hex_hub, :packages, :search]` | `%{duration: ms, results: count}` | `%{query: term}` |
| `[:hex_hub, :packages, :view]` | `%{duration: ms}` | `%{package: name}` |

---

## 6. Download Statistics

### Decision: Use existing `:downloads` field on packages and releases
**Rationale**: Package downloads are already tracked as aggregate counts.

**Current data model**:
- `package.downloads` - Total downloads for all versions
- `release.downloads` - Downloads per version

**Statistics display**:
- Recent downloads: Use `release.downloads` from recent releases (approximation)
- Weekly downloads: Calculate from `:package_downloads` table if populated, else N/A
- Total downloads: Use `package.downloads` directly

**Note**: The `:package_downloads` table exists for detailed analytics but may not be populated. Graceful fallback to package-level counts.

---

## 7. Pagination Strategy

### Decision: Offset-based pagination with 30 items per page
**Rationale**: Matches hex.pm behavior; simple implementation; sufficient for expected scale.

**Implementation**:
```elixir
def list_packages(opts \\ []) do
  page = Keyword.get(opts, :page, 1)
  per_page = Keyword.get(opts, :per_page, 30)

  # Fetch, filter, sort, then slice
  packages
  |> Enum.drop((page - 1) * per_page)
  |> Enum.take(per_page)
end
```

**Future consideration**: For 10k+ packages, implement cursor-based pagination or Mnesia indexes.

---

## 8. Search Implementation

### Decision: Case-insensitive substring match on name and description
**Rationale**: Simple, effective, matches user expectations.

**Implementation**:
```elixir
defp matches_search?(package, query) do
  query = String.downcase(query)
  name = String.downcase(package.name)
  desc = String.downcase(package.meta["description"] || "")

  String.contains?(name, query) or String.contains?(desc, query)
end
```

**Note**: No full-text search or ranking. Simple substring matching is sufficient for private registries with moderate package counts.

---

## Conclusion

All technical decisions resolved using existing infrastructure and patterns. No external research required. Ready to proceed with Phase 1 design artifacts.

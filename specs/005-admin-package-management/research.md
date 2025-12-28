# Research: Admin Package Management

**Date**: 2025-12-28
**Feature**: 005-admin-package-management

## Research Tasks

### 1. Package Source Tracking Strategy

**Decision**: Add `source` field to `:packages` Mnesia table

**Rationale**:
- Currently, packages fetched from upstream are indistinguishable from locally published packages once stored
- The existing code uses telemetry events with `source: :local` or `source: :upstream` at query time, but this is not persisted
- Adding a `source` field (:local | :cached) to the package record enables filtering and priority display

**Alternatives Considered**:
1. **Separate `:cached_packages` table**: Rejected - would require duplicating all package queries and joining results
2. **Infer from metadata differences**: Rejected - unreliable and complex to maintain
3. **Track in separate lookup table**: Rejected - adds complexity without benefit over inline field

**Implementation Notes**:
- Modify `lib/hex_hub/mnesia.ex` to add `source` field (position 10 after `docs_html_url`)
- Default value for existing packages: `:local` (backwards compatible)
- Update `Packages.create_package/4` to set `source: :local`
- Update `Packages.create_package_from_upstream/2` to set `source: :cached`

### 2. Package Resolution Priority Logic

**Decision**: Query both sources, mark cached packages with same name as "shadowed"

**Rationale**:
- Spec requires showing both local and cached packages with priority indicators
- Local packages always take precedence (per existing upstream proxy behavior)
- Admin needs visibility into shadowed cached packages for troubleshooting

**Implementation Pattern**:
```elixir
def list_packages_with_priority(opts \\ []) do
  local_packages = list_packages_by_source(:local, opts)
  cached_packages = list_packages_by_source(:cached, opts)

  local_names = MapSet.new(local_packages, & &1.name)

  annotated = Enum.map(cached_packages, fn pkg ->
    if MapSet.member?(local_names, pkg.name) do
      Map.put(pkg, :status, :shadowed)
    else
      Map.put(pkg, :status, :active)
    end
  end)

  {local_packages, annotated}
end
```

### 3. Cache Deletion Strategy

**Decision**: Delete from both Mnesia and Storage, emit telemetry

**Rationale**:
- Cached packages consist of: Mnesia record + tarball in storage
- Must delete both atomically (or handle partial failures gracefully)
- Constitution requires telemetry for all significant operations

**Implementation Pattern**:
```elixir
def delete_cached_package(package_name) do
  start_time = System.monotonic_time()

  :mnesia.transaction(fn ->
    # Get all releases for the package
    releases = :mnesia.match_object({:package_releases, package_name, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_})

    # Delete each release tarball from storage
    Enum.each(releases, fn release ->
      key = Storage.generate_package_key(package_name, elem(release, 2))
      Storage.delete(key)
      docs_key = Storage.generate_docs_key(package_name, elem(release, 2))
      Storage.delete(docs_key)
    end)

    # Delete Mnesia records
    Enum.each(releases, &:mnesia.delete_object/1)
    :mnesia.delete({:packages, package_name})
  end)

  duration = System.monotonic_time() - start_time
  :telemetry.execute([:hex_hub, :cache, :deleted], %{duration: duration}, %{package: package_name})
end
```

### 4. Existing Admin Patterns

**Decision**: Follow existing controller/view patterns in `hex_hub_admin_web`

**Findings from codebase exploration**:
- Controllers use `render(conn, :template_name, assigns)` pattern
- Templates use `PhoenixDuskmoon.Component` with DaisyUI classes
- Pagination implemented via `page` and `per_page` params
- No authentication currently enforced (stubs exist)
- CRUD pattern: index, show, new, create, edit, update, delete actions

**Template Pattern**:
```heex
<div class="prose max-w-none">
  <h1>Page Title</h1>
</div>

<div class="overflow-x-auto">
  <table class="table table-zebra w-full">
    <thead>
      <tr>
        <th>Column</th>
      </tr>
    </thead>
    <tbody>
      <%= for item <- @items do %>
        <tr>
          <td><%= item.field %></td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
```

### 5. Mnesia Migration Strategy

**Decision**: Schema migration via application startup check

**Rationale**:
- Mnesia doesn't have formal migrations like Ecto
- Existing pattern in codebase: `ensure_tables/0` creates tables if missing
- Need to handle existing data that lacks `source` field

**Implementation Pattern**:
```elixir
def migrate_package_source_field do
  # Check if any packages exist without source field
  :mnesia.transaction(fn ->
    packages = :mnesia.match_object({:packages, :_, :_, :_, :_, :_, :_, :_, :_, :_})
    Enum.each(packages, fn pkg when tuple_size(pkg) == 10 ->
      # Old record format, add source: :local as default
      new_pkg = Tuple.append(pkg, :local)
      :mnesia.delete_object(pkg)
      :mnesia.write(new_pkg)
    end)
  end)
end
```

### 6. Search Implementation

**Decision**: Extend existing search with source filter

**Rationale**:
- `Packages.list_packages/1` already supports search, sort, pagination
- Add optional `source` filter parameter
- Unified search searches both sources and merges results

**Implementation**:
- Add `source: :local | :cached | :all` option to `list_packages/1`
- For unified search, query both and annotate with priority status

## Resolved Clarifications

All technical unknowns have been resolved:

1. ✅ Package source tracking: Add `source` field to Mnesia schema
2. ✅ Priority logic: Runtime annotation based on name matching
3. ✅ Cache deletion: Atomic Mnesia + Storage deletion with telemetry
4. ✅ Admin patterns: Follow existing controller/template structure
5. ✅ Migration: Application startup migration for existing data
6. ✅ Search: Extend existing search with source filtering

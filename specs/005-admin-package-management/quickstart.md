# Quickstart: Admin Package Management

**Date**: 2025-12-28
**Feature**: 005-admin-package-management

## Prerequisites

- Elixir 1.15+ installed
- HexHub development environment set up
- `mix deps.get` completed

## Development Setup

### 1. Start the Server

```bash
mix phx.server
```

Admin dashboard available at: `http://localhost:4000/admin`

### 2. Create Test Data

In IEx console:

```elixir
# Create a local package
{:ok, pkg} = HexHub.Packages.create_package("my_local_pkg", "hexpm", %{
  description: "A local package",
  licenses: ["MIT"]
})

# Simulate a cached package (from upstream)
HexHub.Packages.create_package_from_upstream(%{
  name: "phoenix",
  repository: "hexpm",
  meta: %{description: "Phoenix Framework"}
})
```

### 3. Test Package Resolution

```elixir
# Publish local package with same name as cached
{:ok, _} = HexHub.Packages.create_package("phoenix", "hexpm", %{
  description: "Local override of Phoenix"
})

# Check priority
{local, cached} = HexHub.CachedPackages.list_packages_with_priority()
# cached "phoenix" should have status: :shadowed
```

## Key Admin Routes

| Route | Description |
|-------|-------------|
| `/admin/local-packages` | View all locally published packages |
| `/admin/cached-packages` | View all cached packages from upstream |
| `/admin/packages/search?q=term` | Search both sources |

## Testing

### Run All Tests

```bash
mix test
```

### Run Feature-Specific Tests

```bash
mix test test/hex_hub/cached_packages_test.exs
mix test test/hex_hub_admin_web/controllers/local_package_controller_test.exs
mix test test/hex_hub_admin_web/controllers/cached_package_controller_test.exs
```

### Manual Testing Checklist

1. **Local Packages View**
   - [ ] Navigate to `/admin/local-packages`
   - [ ] Verify pagination works
   - [ ] Test search functionality
   - [ ] Click package to view details

2. **Cached Packages View**
   - [ ] Navigate to `/admin/cached-packages`
   - [ ] Verify shadowed packages show indicator
   - [ ] Delete single cached package
   - [ ] Clear all cached packages

3. **Priority Resolution**
   - [ ] Create local + cached packages with same name
   - [ ] Verify local shows as "Active"
   - [ ] Verify cached shows as "Shadowed"
   - [ ] Delete local, verify cached becomes "Active"

## Telemetry Verification

Monitor telemetry events in IEx:

```elixir
:telemetry.attach(
  "debug-admin",
  [:hex_hub, :admin, :cached_package, :deleted],
  fn event, measurements, metadata, _config ->
    IO.inspect({event, measurements, metadata})
  end,
  nil
)
```

## Common Issues

### Mnesia Schema Mismatch

If you see errors about missing `source` field:

```bash
# Reset Mnesia data (development only!)
rm -rf Mnesia.*
mix phx.server
```

### Package Not Found

Ensure package was created with correct source:

```elixir
# Check package source
HexHub.Packages.get_package("package_name")
|> elem(1)
|> Map.get(:source)
```

## Related Documentation

- [Spec](./spec.md) - Feature requirements
- [Data Model](./data-model.md) - Entity definitions
- [Admin Routes](./contracts/admin-routes.md) - Route contracts

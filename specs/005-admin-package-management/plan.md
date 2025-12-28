# Implementation Plan: Admin Package Management

**Branch**: `005-admin-package-management` | **Date**: 2025-12-28 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/005-admin-package-management/spec.md`

## Summary

Implement admin dashboard views to display and manage local packages (published directly to HexHub) and cached packages (fetched from upstream). The key requirement is that when packages with the same name exist in both sources, local packages take precedence and cached packages show as "shadowed". This requires extending the Mnesia schema to track package origin, adding new admin controllers/views, and implementing cache management operations.

## Technical Context

**Language/Version**: Elixir 1.15+ / OTP 26+
**Primary Dependencies**: Phoenix 1.8+, Mnesia (built-in), DaisyUI/Tailwind CSS
**Storage**: Mnesia (`:packages`, `:package_releases` tables) + HexHub.Storage abstraction for tarballs
**Testing**: ExUnit with Mnesia test isolation
**Target Platform**: Web application (admin dashboard)
**Project Type**: Phoenix web application with dual interfaces (public + admin)
**Performance Goals**: Package lists load within 2 seconds for up to 1000 packages
**Constraints**: <1s search response time, 50 items per page pagination
**Scale/Scope**: Supports 1000+ packages with efficient pagination

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Hex.pm API Compatibility | ✅ Pass | Admin views do not affect public API |
| II. Upstream Proxy First | ✅ Pass | Feature enhances visibility of cached packages |
| III. Zero External Database | ✅ Pass | Using Mnesia exclusively |
| IV. Dual Interface Architecture | ✅ Pass | Changes in `hex_hub_admin_web` only |
| V. Storage Abstraction | ✅ Pass | Using `HexHub.Storage` for cache deletion |
| VI. Test Coverage Requirements | ✅ Pass | Will add tests for all new endpoints |
| VII. Observability and Audit | ✅ Pass | Will emit telemetry events for all operations |
| VII.a Telemetry-First Logging | ✅ Pass | Will use `:telemetry.execute/3` for logging |

**Gate Result**: PASS - No violations requiring justification.

## Project Structure

### Documentation (this feature)

```text
specs/005-admin-package-management/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (internal admin routes)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
lib/
├── hex_hub/                          # Core business logic
│   ├── packages.ex                   # MODIFY: Add source filtering, cache queries
│   ├── cached_packages.ex            # NEW: Cache-specific operations
│   └── mnesia.ex                     # MODIFY: Add source field to packages table
├── hex_hub_admin_web/
│   ├── router.ex                     # MODIFY: Add new routes
│   └── controllers/
│       ├── local_package_controller.ex     # NEW: Local packages view
│       ├── cached_package_controller.ex    # NEW: Cached packages view + deletion
│       └── local_package_html/             # NEW: Templates
│       └── cached_package_html/            # NEW: Templates

test/
├── hex_hub/
│   └── cached_packages_test.exs      # NEW: Context tests
└── hex_hub_admin_web/controllers/
    ├── local_package_controller_test.exs   # NEW
    └── cached_package_controller_test.exs  # NEW
```

**Structure Decision**: Extends existing Phoenix admin web structure with new controllers following the established pattern. Core logic added to `hex_hub` context module per Principle IV.

## Complexity Tracking

> No violations requiring justification.

## Post-Design Constitution Re-Check

*Re-evaluated after Phase 1 design completion.*

| Principle | Status | Design Verification |
|-----------|--------|---------------------|
| I. Hex.pm API Compatibility | ✅ Pass | No public API changes in design |
| II. Upstream Proxy First | ✅ Pass | Design adds visibility to upstream/cached packages |
| III. Zero External Database | ✅ Pass | Only Mnesia schema modification |
| IV. Dual Interface Architecture | ✅ Pass | New controllers in `hex_hub_admin_web`, logic in `hex_hub` |
| V. Storage Abstraction | ✅ Pass | Cache deletion uses `HexHub.Storage.delete/1` |
| VI. Test Coverage Requirements | ✅ Pass | Test files defined for all new modules |
| VII. Observability and Audit | ✅ Pass | Telemetry events defined in contracts |
| VII.a Telemetry-First Logging | ✅ Pass | All operations use `:telemetry.execute/3` |

**Final Gate Result**: PASS - Design adheres to all constitution principles.

## Generated Artifacts

| Artifact | Path | Status |
|----------|------|--------|
| Research | `research.md` | ✅ Complete |
| Data Model | `data-model.md` | ✅ Complete |
| Admin Routes Contract | `contracts/admin-routes.md` | ✅ Complete |
| Quickstart Guide | `quickstart.md` | ✅ Complete |
| Agent Context | `CLAUDE.md` | ✅ Updated |

## Next Steps

Run `/speckit.tasks` to generate implementation tasks from this plan.

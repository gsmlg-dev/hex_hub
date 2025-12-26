# Implementation Plan: Browse Packages

**Branch**: `003-browse-packages` | **Date**: 2025-12-25 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-browse-packages/spec.md`

## Summary

Implement a comprehensive package browsing experience at `/packages` that allows users to discover, search, and view detailed information about packages in the HexHub registry. The feature includes paginated package listing, submit-based search, multiple sorting options, trend sections, alphabetical filtering, and detailed package view pages. Implementation leverages existing `HexHub.Packages` context functions and Mnesia data model, extending with new query capabilities for sorting and filtering.

## Technical Context

**Language/Version**: Elixir 1.15+ / OTP 26+
**Primary Dependencies**: Phoenix 1.8+, Mnesia (built-in), DaisyUI/Tailwind CSS
**Storage**: Mnesia (`:packages`, `:package_releases`, `:package_downloads` tables)
**Testing**: ExUnit with async: false for Mnesia isolation
**Target Platform**: Web browser (server-rendered Phoenix templates)
**Project Type**: Phoenix web application
**Performance Goals**: Page load <2s, search results <1s
**Constraints**: No external database, telemetry-first logging, Hex.pm API compatibility
**Scale/Scope**: Support browsing thousands of packages with pagination (30/page)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Hex.pm API Compatibility | PASS | Browser routes don't affect API; existing `/api/packages` unchanged |
| II. Upstream Proxy First | PASS | `HexHub.Packages.get_package/1` already handles upstream fallback |
| III. Zero External Database | PASS | Uses Mnesia exclusively via existing context |
| IV. Dual Interface Architecture | PASS | Browser UI in `hex_hub_web`, business logic in `hex_hub` context |
| V. Storage Abstraction | PASS | No direct storage access; uses `HexHub.Packages` context |
| VI. Test Coverage Requirements | PASS | Will add controller and context tests for new functionality |
| VII. Observability and Audit | PASS | Will use telemetry events for page views and searches |

**Gate Status**: PASSED - No violations requiring justification.

## Project Structure

### Documentation (this feature)

```text
specs/003-browse-packages/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (routes/templates)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
lib/
├── hex_hub/
│   └── packages.ex              # Extended with sorting/filtering functions
├── hex_hub_web/
│   ├── router.ex                # Updated routes: /packages, /packages/:name
│   ├── controllers/
│   │   ├── package_controller.ex    # Browser controller (index, show)
│   │   └── package_html.ex          # View helpers
│   └── controllers/package_html/
│       ├── index.html.heex          # Package list template
│       └── show.html.heex           # Package detail template

test/
├── hex_hub/
│   └── packages_test.exs            # Extended context tests
└── hex_hub_web/controllers/
    └── package_controller_test.exs  # Browser controller tests
```

**Structure Decision**: Extends existing Phoenix web application structure. New routes and templates added to `hex_hub_web`, business logic extended in `hex_hub/packages.ex` context. Follows established dual interface architecture.

## Complexity Tracking

No Constitution violations requiring justification. Implementation uses existing patterns and infrastructure.

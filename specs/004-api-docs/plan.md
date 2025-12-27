# Implementation Plan: API Documentation Page

**Branch**: `004-api-docs` | **Date**: 2025-12-26 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/004-api-docs/spec.md`

## Summary

Implement a multi-page documentation system for HexHub accessible at `/docs/*` routes. The documentation will cover: (1) Getting Started guide with mix configuration, (2) Publishing Packages workflow, (3) API Reference rendered from `hex-api.yaml` as styled HTML sections, and (4) downloadable OpenAPI 3.0 specification. The home page "API Documentation" link will be updated to point to the new documentation root.

## Technical Context

**Language/Version**: Elixir 1.15+ / OTP 26+
**Primary Dependencies**: Phoenix 1.8+, Tailwind CSS, DaisyUI, YamlElixir (for OpenAPI parsing)
**Storage**: N/A (static documentation content rendered from templates and hex-api.yaml)
**Testing**: ExUnit
**Target Platform**: Web (Phoenix application, browser-based documentation)
**Project Type**: Web application (single Phoenix app with `hex_hub_web`)
**Performance Goals**: Documentation page loads within 3 seconds (per SC-002)
**Constraints**: Must maintain DaisyUI/Tailwind CSS styling consistency; server-side YAML parsing
**Scale/Scope**: 4 documentation pages, 1 OpenAPI YAML file (~2000 lines)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Hex.pm API Compatibility | ✅ PASS | N/A - documentation pages don't affect API endpoints |
| II. Upstream Proxy First | ✅ PASS | N/A - no upstream dependency for documentation |
| III. Zero External Database | ✅ PASS | No database needed - static content from templates |
| IV. Dual Interface Architecture | ✅ PASS | Documentation in `hex_hub_web` (public-facing) |
| V. Storage Abstraction | ✅ PASS | N/A - no package/documentation storage operations |
| VI. Test Coverage Requirements | ✅ PASS | Tests required for new routes and controllers |
| VII. Observability and Audit | ✅ PASS | Telemetry events for documentation page views |

**Gate Result**: PASS - All principles satisfied, no violations.

## Project Structure

### Documentation (this feature)

```text
specs/004-api-docs/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
lib/
├── hex_hub_web/
│   ├── controllers/
│   │   └── docs_controller.ex           # New controller for documentation pages
│   ├── controllers/
│   │   └── docs_html/
│   │       ├── index.html.heex          # Documentation landing/overview
│   │       ├── getting_started.html.heex # Mix configuration guide
│   │       ├── publishing.html.heex     # Publishing workflow guide
│   │       └── api_reference.html.heex  # API reference from OpenAPI
│   └── router.ex                        # New /docs routes

priv/
└── static/
    └── openapi/
        └── hex-api.yaml                 # Served as downloadable file

test/
└── hex_hub_web/
    └── controllers/
        └── docs_controller_test.exs     # Tests for documentation pages
```

**Structure Decision**: Single Phoenix web application structure. Documentation is a public-facing feature belonging to `hex_hub_web`. No separate frontend/backend separation needed as Phoenix templates handle server-side rendering.

## Complexity Tracking

> **No violations requiring justification** - All constitution principles are satisfied.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| N/A | N/A | N/A |

---

## Phase 0: Research (COMPLETE)

*Output: [research.md](./research.md)*

Research completed:
1. ✅ OpenAPI YAML parsing libraries - Selected `yaml_elixir` (~> 2.11)
2. ✅ Phoenix documentation patterns - Standard controller/view/template pattern
3. ✅ Syntax highlighting - DaisyUI `mockup-code` component with CSS classes
4. ✅ Navigation patterns - DaisyUI drawer + menu for sidebar navigation

---

## Phase 1: Design (COMPLETE)

*Outputs: [data-model.md](./data-model.md), [contracts/](./contracts/), [quickstart.md](./quickstart.md)*

Design completed:
1. ✅ DocsController with 4 actions (index, getting_started, publishing, api_reference)
2. ✅ OpenAPI YAML parsing at compile time with `paths_by_tag/0` grouping
3. ✅ Navigation component using DaisyUI drawer with active state
4. ✅ Code snippets using existing `mockup-code` pattern from home page

**Agent Context Updated**: CLAUDE.md updated with new dependencies

---

## Constitution Re-Check (Post-Design)

| Principle | Status | Post-Design Notes |
|-----------|--------|-------------------|
| I. Hex.pm API Compatibility | ✅ PASS | No API changes - docs only |
| II. Upstream Proxy First | ✅ PASS | N/A |
| III. Zero External Database | ✅ PASS | Compile-time YAML parsing, no runtime DB |
| IV. Dual Interface Architecture | ✅ PASS | DocsController in `hex_hub_web` (public) |
| V. Storage Abstraction | ✅ PASS | Static file serving via Phoenix |
| VI. Test Coverage Requirements | ✅ PASS | Test contract defined |
| VII. Observability and Audit | ✅ PASS | Telemetry event defined for page views |

**Post-Design Gate Result**: PASS - Design adheres to all constitution principles.

---

## Phase 2: Tasks (SEPARATE COMMAND)

*Output: tasks.md via `/speckit.tasks` command*

Run `/speckit.tasks` to generate implementation tasks from this plan.

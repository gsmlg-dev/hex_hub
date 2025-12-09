# Implementation Plan: E2E Test Infrastructure for Hex Package Proxy

**Branch**: `001-e2e-test-setup` | **Date**: 2025-11-26 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-e2e-test-setup/spec.md`

## Summary

Create a separate E2E test infrastructure that validates HexHub's hex package proxy functionality by starting the server on a random port, configuring hex to use it as a mirror, and verifying package fetching works correctly. This includes a new `mix test.e2e` command and GitHub Actions workflow.

## Technical Context

**Language/Version**: Elixir 1.15+ / OTP 27+
**Primary Dependencies**: Phoenix 1.8, ExUnit, Mix (for custom task)
**Storage**: Mnesia (existing), local filesystem for test isolation
**Testing**: ExUnit with custom Mix task for E2E isolation
**Target Platform**: Linux server (GitHub Actions ubuntu-latest)
**Project Type**: Umbrella-style Phoenix application (hex_hub, hex_hub_web, hex_hub_admin_web)
**Performance Goals**: E2E tests complete within 5 minutes
**Constraints**: Network access to hex.pm required; dynamic port allocation
**Scale/Scope**: Single concurrent test run; small stable packages (jason, decimal)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Hex.pm API Compatibility | ✅ PASS | E2E tests validate this compatibility |
| II. Upstream Proxy First | ✅ PASS | E2E tests verify proxy behavior |
| III. Zero External Database | ✅ PASS | Uses Mnesia, no new dependencies |
| IV. Dual Interface Architecture | ✅ PASS | Tests target hex_hub_web public API |
| V. Storage Abstraction | ✅ PASS | Uses existing HexHub.Storage |
| VI. Test Coverage Requirements | ✅ PASS | Adding new E2E test category |
| VII. Observability and Audit | ✅ PASS | No changes to observability |

**Code Quality Gates**:
- `mix format --check-formatted` - Will apply to new e2e_test files
- `mix credo --strict` - Will apply to new Mix task
- `mix dialyzer` - No new types introduced
- `mix test` - E2E tests isolated, won't run with unit tests

## Project Structure

### Documentation (this feature)

```text
specs/001-e2e-test-setup/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output (minimal - test infra only)
├── quickstart.md        # Phase 1 output
└── contracts/           # Phase 1 output (N/A - no new APIs)
```

### Source Code (repository root)

```text
# E2E Test Infrastructure
e2e_test/
├── support/
│   ├── e2e_case.ex           # Base test case module
│   └── server_helper.ex      # HexHub server start/stop helpers
├── test_helper.exs           # E2E-specific test helper
└── proxy_test.exs            # Main proxy validation tests

# Mix Task
lib/mix/tasks/
└── test.e2e.ex               # Custom mix task for E2E tests

# GitHub Actions
.github/workflows/
└── e2e.yml                   # E2E test workflow

# Existing structure (for reference)
lib/
├── hex_hub/                  # Core business logic (no changes)
├── hex_hub_web/              # Public API (target of E2E tests)
└── hex_hub_admin_web/        # Admin dashboard (not tested in E2E)

test/                         # Existing unit tests (unchanged)
```

**Structure Decision**: New `e2e_test/` directory at project root, parallel to existing `test/` directory. This provides clean isolation and follows Elixir conventions for separating test types.

## Complexity Tracking

No constitution violations. Simple addition of test infrastructure without architectural changes.

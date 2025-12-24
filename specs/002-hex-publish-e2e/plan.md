# Implementation Plan: E2E Test Suite for hex.publish

**Branch**: `002-hex-publish-e2e` | **Date**: 2025-12-23 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-hex-publish-e2e/spec.md`

## Summary

This feature implements an E2E test suite for verifying that HexHub's `mix hex.publish` command works correctly as a drop-in replacement for hex.pm. The tests will extend the existing E2E infrastructure (`mix test.e2e`, `E2E.Case`, `E2E.ServerHelper`) to validate package publishing with API key authentication, version management, and error handling.

## Technical Context

**Language/Version**: Elixir 1.15+ (matching project requirements)
**Primary Dependencies**: ExUnit, Hex client (mix hex.publish), existing E2E infrastructure
**Storage**: Mnesia (via existing HexHub.Storage abstraction) for test data
**Testing**: ExUnit via `mix test.e2e` task (isolated from unit tests)
**Target Platform**: Linux server (development/CI environment)
**Project Type**: Phoenix web application with E2E test extension
**Performance Goals**: <60 seconds per test case
**Constraints**: Tests must be isolated, non-flaky (3 consecutive pass requirement)
**Scale/Scope**: 5+ distinct publishing scenarios covering P1-P3 user stories

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Hex.pm API Compatibility | PASS | Tests verify HexHub works with standard `mix hex.publish` |
| II. Upstream Proxy First | N/A | Tests focus on local publishing, not upstream proxy |
| III. Zero External Database | PASS | Uses existing Mnesia infrastructure |
| IV. Dual Interface Architecture | PASS | Tests interact via public API, not admin |
| V. Storage Abstraction | PASS | Tests use existing Storage layer |
| VI. Test Coverage Requirements | PASS | Feature adds E2E test coverage for publishing |
| VII. Observability and Audit | PASS | Tests verify telemetry events are emitted during publish |

**Gate Status**: PASS - No violations. Proceed to Phase 0.

## Project Structure

### Documentation (this feature)

```text
specs/002-hex-publish-e2e/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (N/A for test suite)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
e2e_test/
├── support/
│   ├── e2e_case.ex           # Existing: Base test case module
│   ├── server_helper.ex      # Existing: Server lifecycle management
│   └── publish_helper.ex     # NEW: Publishing-specific test helpers
├── fixtures/
│   ├── test_project/         # Existing: Basic fixture for deps.get tests
│   └── publish_project/      # NEW: Publishing fixture with full mix.exs
├── test_helper.exs           # Existing: ExUnit configuration
├── proxy_test.exs            # Existing: Proxy functionality tests
└── publish_test.exs          # NEW: Package publishing E2E tests
```

**Structure Decision**: Extends existing `e2e_test/` structure with new test file (`publish_test.exs`), fixture project (`publish_project/`), and helper module (`publish_helper.ex`).

## Complexity Tracking

> No violations requiring justification.

---

## Post-Design Constitution Re-Check

*Re-evaluated after Phase 1 design completion*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Hex.pm API Compatibility | PASS | E2E tests validate `mix hex.publish` compatibility |
| II. Upstream Proxy First | N/A | Feature focuses on local publishing |
| III. Zero External Database | PASS | Uses Mnesia, no new database dependencies |
| IV. Dual Interface Architecture | PASS | Tests use public API only |
| V. Storage Abstraction | PASS | Package storage via existing abstraction |
| VI. Test Coverage Requirements | PASS | Adds comprehensive E2E coverage for publishing |
| VII. Observability and Audit | PASS | Tests can verify telemetry events if needed |

**Post-Design Gate Status**: PASS - Design complies with all applicable principles.

---

## Generated Artifacts

| Artifact | Path | Description |
|----------|------|-------------|
| Research | [research.md](./research.md) | Hex client config, API keys, test isolation |
| Data Model | [data-model.md](./data-model.md) | Test fixtures, entities, API contracts |
| Quickstart | [quickstart.md](./quickstart.md) | Verification steps, troubleshooting |

**Note**: No `/contracts/` directory created as this is a test suite feature (no new API contracts introduced).

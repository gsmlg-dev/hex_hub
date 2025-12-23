# Implementation Plan: Telemetry-Based Logging System

**Branch**: `001-telemetry-logging` | **Date**: 2025-12-23 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-telemetry-logging/spec.md`

## Summary

Implement a telemetry-first logging architecture where all operational events are emitted via `:telemetry.execute/3` instead of direct `Logger` calls. Telemetry handlers will route events to console (via Logger) and optionally to files, with configurable log levels per destination. This aligns with Constitution Principle VII (Telemetry-First Logging).

## Technical Context

**Language/Version**: Elixir 1.15+ / OTP 26+
**Primary Dependencies**: `:telemetry` (already in project), `Logger` (Elixir stdlib)
**Storage**: N/A (logging to console/files, not database)
**Testing**: ExUnit with `mix test`
**Target Platform**: Linux server (Docker/Kubernetes compatible)
**Project Type**: Phoenix web application (umbrella-style with hex_hub, hex_hub_web, hex_hub_admin_web)
**Performance Goals**: <100ms console logging latency, <1s file logging latency under normal load
**Constraints**: Must not break existing telemetry metrics (LiveDashboard, Prometheus)
**Scale/Scope**: 17 files currently using Logger directly need refactoring

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Hex.pm API Compatibility | ✅ Pass | No API changes - internal observability only |
| II. Upstream Proxy First | ✅ Pass | Upstream requests will emit telemetry events |
| III. Zero External Database | ✅ Pass | No database changes |
| IV. Dual Interface Architecture | ✅ Pass | Logging module in `hex_hub` core, handlers shared |
| V. Storage Abstraction | ✅ Pass | File logging uses standard File operations, not HexHub.Storage |
| VI. Test Coverage Requirements | ✅ Pass | Tests will verify handler behavior |
| VII. Observability and Audit | ✅ Pass | **Primary alignment** - implements Telemetry-First Logging |

**Gate Result**: PASS - No violations. This feature directly implements Constitution Principle VII.

## Project Structure

### Documentation (this feature)

```text
specs/001-telemetry-logging/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (N/A - no API contracts)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
lib/
├── hex_hub/
│   ├── telemetry.ex                 # Existing - add log event definitions
│   ├── telemetry/
│   │   ├── log_handler.ex           # NEW - Console logging handler
│   │   ├── file_handler.ex          # NEW - File logging handler
│   │   └── formatter.ex             # NEW - JSON log formatter
│   ├── packages.ex                  # MODIFY - replace Logger with telemetry
│   ├── upstream.ex                  # MODIFY - replace Logger with telemetry
│   ├── storage.ex                   # MODIFY - replace Logger with telemetry
│   ├── clustering.ex                # MODIFY - replace Logger with telemetry
│   └── ...                          # Other files with Logger calls
├── hex_hub_web/
│   └── controllers/api/
│       └── registry_controller.ex   # MODIFY - replace Logger with telemetry
└── hex_hub/mcp/
    └── *.ex                         # MODIFY - replace Logger with telemetry (7 files)

config/
├── config.exs                       # ADD - telemetry logging configuration
└── runtime.exs                      # ADD - runtime log level configuration

test/
└── hex_hub/
    └── telemetry/
        ├── log_handler_test.exs     # NEW - console handler tests
        ├── file_handler_test.exs    # NEW - file handler tests
        └── formatter_test.exs       # NEW - JSON formatter tests
```

**Structure Decision**: Elixir/Phoenix umbrella structure. New telemetry handlers in `lib/hex_hub/telemetry/` subdirectory to keep related modules together without cluttering main namespace.

## Complexity Tracking

> No Constitution Check violations - this section not applicable.

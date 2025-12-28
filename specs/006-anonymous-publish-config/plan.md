# Implementation Plan: Anonymous Publish Configuration

**Branch**: `006-anonymous-publish-config` | **Date**: 2025-12-28 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/006-anonymous-publish-config/spec.md`

## Summary

Add admin configuration to enable/disable anonymous package publishing. When enabled, packages can be published without API key authentication, attributed to a system "anonymous" user. Configuration stored in Mnesia with immediate effect (no restart required). Log IP address and timestamp for each anonymous publish.

## Technical Context

**Language/Version**: Elixir 1.15+ / OTP 26+
**Primary Dependencies**: Phoenix 1.8+, Mnesia (built-in), DaisyUI/Tailwind CSS
**Storage**: Mnesia (`:system_settings` or `:publish_configs` table for setting, existing `:users` table for anonymous user)
**Testing**: ExUnit with Mnesia test isolation
**Target Platform**: Linux server (Docker/Kubernetes deployment)
**Project Type**: Web application with dual interface architecture
**Performance Goals**: Setting toggle takes effect within 1 second (no restart)
**Constraints**: Must maintain Hex.pm API compatibility for publish endpoint
**Scale/Scope**: Single boolean setting, one system user, affects publish API endpoint

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Hex.pm API Compatibility | ✅ Pass | Publish endpoint behavior extended, not changed. Unauthenticated requests optionally allowed based on setting. |
| II. Upstream Proxy First | ✅ N/A | Feature is for local publishes only, does not affect upstream proxy |
| III. Zero External Database | ✅ Pass | All config stored in Mnesia |
| IV. Dual Interface Architecture | ✅ Pass | Config UI in hex_hub_admin_web, business logic in hex_hub context |
| V. Storage Abstraction | ✅ N/A | Uses HexHub.Storage for package storage (already in place) |
| VI. Test Coverage | ✅ Required | Tests for config toggle, anonymous publish, anonymous user visibility |
| VII. Observability | ✅ Required | Telemetry events for config changes, anonymous publishes with IP/timestamp |

## Project Structure

### Documentation (this feature)

```text
specs/006-anonymous-publish-config/
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
├── hex_hub/
│   ├── publish_config.ex          # New: Anonymous publish configuration (like UpstreamConfig)
│   ├── users.ex                   # Modified: Add anonymous user creation/protection
│   ├── packages.ex                # Modified: Check publish config, use anonymous user
│   └── mnesia.ex                  # Modified: Add publish_configs table
├── hex_hub_web/
│   └── controllers/api/
│       └── package_controller.ex  # Modified: Handle unauthenticated publish
├── hex_hub_admin_web/
│   ├── controllers/
│   │   └── publish_config_controller.ex  # New: Admin config CRUD
│   └── controllers/publish_config_html/
│       ├── index.html.heex        # New: Config form with toggle
│       └── show.html.heex         # New: Config display (if needed)

test/
├── hex_hub/
│   ├── publish_config_test.exs    # New: Config module tests
│   └── packages_test.exs          # Modified: Anonymous publish tests
├── hex_hub_web/controllers/api/
│   └── package_controller_test.exs # Modified: Unauthenticated publish tests
└── hex_hub_admin_web/controllers/
    └── publish_config_controller_test.exs  # New: Admin config tests
```

**Structure Decision**: Follows existing dual interface architecture pattern. New `PublishConfig` context follows `UpstreamConfig` pattern for Mnesia-based configuration. Admin controller follows existing admin patterns.

## Complexity Tracking

> **No Constitution violations - this section is empty**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| N/A | N/A | N/A |

<!--
SYNC IMPACT REPORT
==================
Version Change: 1.0.0 → 1.1.0 (Principle VII expansion for telemetry-based logging)
Modified Principles:
  - Principle VII: "Observability and Audit" → expanded to mandate telemetry-based logging architecture
Added Sections:
  - Telemetry-First Logging subsection under Principle VII
Removed Sections: N/A
Templates Requiring Updates:
  - .specify/templates/plan-template.md ✅ (no changes needed - generic template)
  - .specify/templates/spec-template.md ✅ (no changes needed - generic template)
  - .specify/templates/tasks-template.md ✅ (no changes needed - generic template)
Follow-up TODOs: None
-->

# HexHub Constitution

## Core Principles

### I. Hex.pm API Compatibility

HexHub MUST maintain full compatibility with the official Hex.pm API specification. All API
endpoints MUST accept and return data in formats expected by the Mix build tool and hex_core
library. Breaking compatibility with Hex clients is NOT acceptable. The primary purpose is to
serve as a drop-in replacement for hex.pm that can be used by setting `HEX_MIRROR` environment
variable.

**Rationale**: Users expect to use HexHub without modifying their existing Elixir/Erlang
projects. Any deviation from hex.pm behavior creates friction and defeats the project's purpose.

### II. Upstream Proxy First

When a package or release is not found locally, HexHub MUST transparently proxy requests to the
configured upstream repository (hex.pm by default). Packages fetched from upstream MUST be
cached locally for subsequent requests. The proxy behavior MUST be invisible to clients - they
should receive the same response as if requesting directly from hex.pm.

**Rationale**: This enables HexHub to function as both a private repository and a caching proxy,
reducing external dependencies and improving reliability for teams.

### III. Zero External Database Dependency

HexHub MUST use Mnesia for all persistent storage. No external database (PostgreSQL, MySQL,
Redis, etc.) is required for operation. This simplifies deployment and enables single-binary
distribution. All Mnesia operations MUST be wrapped in transactions for data consistency.

**Rationale**: Reducing operational complexity is critical for self-hosted deployments. Mnesia
provides built-in clustering, persistence, and replication without additional infrastructure.

### IV. Dual Interface Architecture

HexHub MUST maintain strict separation between:
- `hex_hub_web`: Public-facing web interface implementing hex.pm and hexdocs.pm functionality
- `hex_hub_admin_web`: Admin management console for users, packages, and system configuration
- `hex_hub`: Core business logic with no web dependencies

Controllers MUST NOT contain business logic; they orchestrate calls to context modules in
`hex_hub`. This separation enables independent scaling and security policies.

**Rationale**: Clear architectural boundaries prevent coupling and enable targeted security
hardening for administrative functions.

### V. Storage Abstraction

All package and documentation storage MUST go through `HexHub.Storage` abstraction. Direct
filesystem or S3 access from controllers or contexts is NOT permitted. The storage layer MUST
support both local filesystem (development) and S3-compatible backends (production) without
code changes.

**Rationale**: Storage abstraction enables flexible deployment options and simplifies testing
by allowing mock storage implementations.

### VI. Test Coverage Requirements

All API endpoints MUST have corresponding test coverage. Tests MUST verify:
- Successful operations with valid inputs
- Error handling with invalid inputs
- Authentication and authorization rules
- Edge cases documented in the Hex API specification

New features MUST NOT merge without passing tests. Test data MUST be isolated between test runs.

**Rationale**: HexHub is infrastructure software; bugs can break entire CI/CD pipelines for
dependent projects. High test coverage prevents regressions.

### VII. Observability and Audit

All significant operations MUST emit telemetry events. Authentication failures, package
publishes, upstream requests, and administrative actions MUST be observable through telemetry.
The system MUST expose health check endpoints compatible with Kubernetes liveness/readiness
probes.

#### Telemetry-First Logging

Application code MUST NOT use `Logger` directly for operational logging. Instead, all loggable
events MUST be emitted as telemetry events via `:telemetry.execute/3`. Logging output MUST be
handled by attaching telemetry handlers that route events to appropriate destinations:

- **Console output**: Attach a handler that uses `Logger` to print to console
- **File output**: Attach a handler that writes to log files
- **External systems**: Attach handlers for metrics services, log aggregators, etc.

This pattern MUST be followed:

```elixir
# CORRECT: Emit telemetry event
:telemetry.execute([:hex_hub, :package, :published], %{duration: duration_ms}, %{
  package: name,
  version: version,
  user: username
})

# INCORRECT: Direct Logger call for operational events
Logger.info("Package #{name} published")
```

Telemetry handlers MUST be registered in the application supervision tree. Default handlers
MUST provide:
- Console logging via `Logger` (configurable log level)
- Optional file logging (when configured via environment)

**Exceptions**: Direct `Logger` usage is permitted only for:
- Application startup/shutdown messages in `Application.start/2`
- Debugging during development (MUST be removed before merge)
- Error rescue blocks where telemetry might not be available

**Rationale**: Telemetry-first logging provides:
1. Decoupled event emission from output handling
2. Consistent event structure across the application
3. Easy integration with external observability systems
4. Ability to enable/disable specific log streams without code changes
5. Metrics and logging from the same event source

## Technology Stack

HexHub is built with the following technology choices that MUST be maintained:

| Layer | Technology | Notes |
|-------|------------|-------|
| Framework | Phoenix 1.8+ | LiveView for real-time features |
| Language | Elixir 1.15+ | OTP for reliability |
| Database | Mnesia | Built-in Erlang distributed database |
| HTTP Server | Bandit | High-performance HTTP/2 support |
| CSS Framework | Tailwind CSS + DaisyUI | Responsive, component-based styling |
| JS Bundler | Bun | Fast asset compilation |
| Storage | Local / S3 | Via `HexHub.Storage` abstraction |
| Clustering | Libcluster | Automatic node discovery |
| Observability | Telemetry | Via `:telemetry` for events and metrics |

**UI Constraints**:
- All user interfaces MUST use Tailwind CSS utility classes
- DaisyUI components MUST be used for consistent styling
- Custom CSS MUST be minimized and justified

## Development Workflow

### Code Quality Gates

All code changes MUST pass:
1. `mix format --check-formatted` - Code formatting
2. `mix credo --strict` - Static analysis
3. `mix dialyzer` - Type checking
4. `mix test` - Full test suite

### API Changes

Changes to API endpoints MUST:
1. Update `hex-api.yaml` OpenAPI specification
2. Maintain backward compatibility or document breaking changes
3. Include integration tests verifying Hex client compatibility
4. Update CLAUDE.md if new patterns are introduced

### Commit Standards

- Commits MUST follow conventional commit format: `type(scope): description`
- Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`
- Breaking changes MUST include `BREAKING CHANGE:` in commit body

## Governance

This constitution supersedes all other development practices for the HexHub project. Amendments
require:

1. Written proposal documenting the change and rationale
2. Review of impact on existing features and deployments
3. Update to this document with incremented version
4. Migration plan for any breaking principle changes

**Compliance**: All pull requests MUST verify adherence to these principles. Reviewers SHOULD
check the Constitution Check section in implementation plans.

**Versioning Policy**:
- MAJOR: Backward-incompatible principle changes or removals
- MINOR: New principles added or existing principles expanded
- PATCH: Clarifications, typo fixes, non-semantic refinements

**Version**: 1.1.0 | **Ratified**: 2025-11-25 | **Last Amended**: 2025-12-22

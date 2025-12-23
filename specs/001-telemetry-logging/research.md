# Research: Telemetry-Based Logging System

**Feature**: 001-telemetry-logging
**Date**: 2025-12-23

## Research Questions

### 1. Telemetry Handler Architecture in Elixir

**Decision**: Use `:telemetry.attach/4` to register handlers that subscribe to event prefixes.

**Rationale**:
- `:telemetry` is already a dependency in the project
- Handlers are simple functions that receive event name, measurements, metadata, and config
- Multiple handlers can subscribe to the same events (allowing both console and file output)
- Handlers are registered in the supervision tree for lifecycle management

**Alternatives Considered**:
- `Logger` backends: Rejected because it doesn't integrate with telemetry events
- External libraries (e.g., `telemetry_logger`): Rejected for simplicity; custom handler is straightforward

**Implementation Pattern**:
```elixir
:telemetry.attach(
  "hex-hub-log-handler",
  [:hex_hub, :log],
  &HexHub.Telemetry.LogHandler.handle_event/4,
  %{level: :info}
)
```

### 2. Telemetry Event Naming Conventions

**Decision**: Use hierarchical event names with `[:hex_hub, :log, <category>]` for loggable events.

**Rationale**:
- Consistent with existing HexHub telemetry events (e.g., `[:hex_hub, :packages, :published]`)
- Allows subscribing to all log events with prefix `[:hex_hub, :log]`
- Category allows filtering (e.g., `:api`, `:upstream`, `:storage`, `:auth`)

**Event Structure**:
```elixir
:telemetry.execute(
  [:hex_hub, :log, :api],           # Event name
  %{duration: 123},                  # Measurements (numeric)
  %{                                 # Metadata
    level: :info,
    message: "Request completed",
    request_id: "abc123",
    path: "/api/packages"
  }
)
```

### 3. Log Level Filtering Strategy

**Decision**: Filter by log level in the handler callback, not at event emission.

**Rationale**:
- Events are emitted once, handlers filter independently
- Allows different log levels per destination (console: info, file: debug)
- Minimal overhead - level comparison is O(1)

**Level Hierarchy** (standard Elixir Logger levels):
- `:debug` (0) - lowest, most verbose
- `:info` (1)
- `:warning` (2)
- `:error` (3) - highest, least verbose

### 4. File Logging Implementation

**Decision**: Use Elixir's `File.open/2` with `:append` mode and a dedicated GenServer for writes.

**Rationale**:
- GenServer serializes writes to prevent corruption from concurrent events
- Append mode ensures log entries are never overwritten
- File handle kept open for performance (avoid open/close per write)

**Alternatives Considered**:
- Direct `File.write!/3`: Rejected due to race conditions with concurrent writes
- Logger file backend: Rejected because we need JSON format and telemetry integration
- External log aggregator: Out of scope per spec (log rotation handled externally)

**Error Handling**:
- If file path not writable: Log error to console, disable file handler
- If disk full: Catch exception, log warning to console, continue

### 5. JSON Log Format

**Decision**: Use Jason for JSON encoding with a consistent schema.

**Rationale**:
- Jason is already a dependency in Phoenix projects
- Fast and battle-tested
- Consistent schema enables log aggregation and parsing

**Schema**:
```json
{
  "ts": "2025-12-23T10:15:30.123456Z",
  "level": "info",
  "event": "hex_hub.log.api",
  "message": "Request completed",
  "duration_ms": 123,
  "meta": {
    "request_id": "abc123",
    "path": "/api/packages"
  }
}
```

### 6. Sensitive Data Filtering

**Decision**: Implement a denylist of keys to redact from log output.

**Rationale**:
- Simple and maintainable
- Catches common sensitive fields automatically
- Operators can extend via configuration

**Denylist** (default):
- `password`, `password_hash`, `secret`, `token`, `api_key`, `authorization`, `bearer`

**Redaction**:
```elixir
%{password: "secret123"} → %{password: "[REDACTED]"}
```

### 7. Handler Registration Strategy

**Decision**: Register handlers in `HexHub.Application.start/2` after telemetry poller starts.

**Rationale**:
- Handlers must be attached before events are emitted
- Application start is the earliest reliable point
- Allows configuration-driven enable/disable

**Registration Order**:
1. Start telemetry poller (existing)
2. Attach console log handler (always enabled by default)
3. Attach file log handler (if configured)

### 8. Files Requiring Logger Refactoring

**Decision**: Refactor all 17 files using `Logger` to emit telemetry events instead.

**Files Identified**:
1. `lib/hex_hub_web/controllers/api/registry_controller.ex`
2. `lib/hex_hub/upstream.ex`
3. `lib/hex_hub/packages.ex`
4. `lib/hex_hub_web/controllers/mcp_controller.ex`
5. `lib/hex_hub/mcp/tools/packages.ex`
6. `lib/hex_hub/mcp/tools/releases.ex`
7. `lib/hex_hub/mcp/tools/repositories.ex`
8. `lib/hex_hub/mcp/tools/dependencies.ex`
9. `lib/hex_hub/mcp/tools/documentation.ex`
10. `lib/hex_hub/mcp/handler.ex`
11. `lib/hex_hub/mcp/http_controller.ex`
12. `lib/hex_hub/mcp/server.ex`
13. `lib/hex_hub/mcp/tools.ex`
14. `lib/hex_hub/clustering.ex`
15. `lib/hex_hub/upstream_config.ex`
16. `lib/hex_hub/storage.ex`
17. `lib/hex_hub/mcp/transport.ex`

**Refactoring Pattern**:
```elixir
# Before
Logger.info("Package published: #{name}")

# After
:telemetry.execute(
  [:hex_hub, :log, :package],
  %{},
  %{level: :info, message: "Package published", package: name}
)
```

## Configuration Design

**Environment Variables**:
```bash
# Console logging (enabled by default)
LOG_CONSOLE_ENABLED=true
LOG_CONSOLE_LEVEL=info

# File logging (disabled by default)
LOG_FILE_ENABLED=false
LOG_FILE_PATH=/var/log/hex_hub/app.log
LOG_FILE_LEVEL=debug
```

**Application Config**:
```elixir
config :hex_hub, :telemetry_logging,
  console: [enabled: true, level: :info],
  file: [enabled: false, path: nil, level: :debug]
```

## Dependencies

No new dependencies required. Uses existing:
- `:telemetry` - event system
- `Jason` - JSON encoding
- `Logger` - console output (via handler)
- `File` - file I/O (Elixir stdlib)

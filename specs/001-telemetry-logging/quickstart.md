# Quickstart: Telemetry-Based Logging System

**Feature**: 001-telemetry-logging
**Date**: 2025-12-23

## Prerequisites

- Elixir 1.15+ installed
- HexHub repository cloned
- Dependencies installed (`mix deps.get`)

## Quick Verification Steps

After implementation, verify the telemetry logging system works:

### 1. Start the Application with Default Config

```bash
# Console logging is enabled by default
mix phx.server
```

**Expected**: Console shows JSON-formatted log entries:
```json
{"ts":"2025-12-23T10:15:30.123Z","level":"info","event":"hex_hub.log.api","message":"Server started","meta":{}}
```

### 2. Test Console Logging

```bash
# In another terminal, trigger an API request
curl http://localhost:4000/api/packages/phoenix
```

**Expected**: Console shows request log:
```json
{"ts":"...","level":"info","event":"hex_hub.log.api","message":"Request completed","duration_ms":45,"meta":{"path":"/api/packages/phoenix","status":200}}
```

### 3. Enable File Logging

```bash
# Set environment variables
export LOG_FILE_ENABLED=true
export LOG_FILE_PATH=/tmp/hex_hub.log
export LOG_FILE_LEVEL=debug

# Restart server
mix phx.server
```

**Expected**: Log entries written to `/tmp/hex_hub.log`

### 4. Verify Log Level Filtering

```bash
# Set console to warning level only
export LOG_CONSOLE_LEVEL=warning

# Restart and make a request
mix phx.server
curl http://localhost:4000/api/packages/phoenix
```

**Expected**: Info-level request log does NOT appear in console (but appears in file if enabled with debug level)

### 5. Verify Sensitive Data Redaction

Trigger an authentication failure:

```bash
curl -H "Authorization: Bearer invalid_token" http://localhost:4000/api/packages
```

**Expected**: Log entry shows `[REDACTED]` for authorization header:
```json
{"ts":"...","level":"warning","event":"hex_hub.log.auth","message":"Authentication failed","meta":{"authorization":"[REDACTED]"}}
```

### 6. Run Tests

```bash
# Run telemetry logging tests
mix test test/hex_hub/telemetry/

# Run all tests to ensure no regressions
mix test
```

**Expected**: All tests pass

## Configuration Reference

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `LOG_CONSOLE_ENABLED` | `true` | Enable console logging |
| `LOG_CONSOLE_LEVEL` | `info` | Minimum level for console |
| `LOG_FILE_ENABLED` | `false` | Enable file logging |
| `LOG_FILE_PATH` | `nil` | Path to log file |
| `LOG_FILE_LEVEL` | `debug` | Minimum level for file |

### Application Config

```elixir
# config/config.exs
config :hex_hub, :telemetry_logging,
  console: [enabled: true, level: :info],
  file: [enabled: false, path: nil, level: :debug]
```

## Emitting Log Events (Developer Reference)

Replace direct `Logger` calls with telemetry events:

```elixir
# Before
Logger.info("Package published: #{name}")

# After
:telemetry.execute(
  [:hex_hub, :log, :package],
  %{},
  %{
    level: :info,
    message: "Package published",
    package: name
  }
)
```

### Helper Function (Recommended)

Use the helper in `HexHub.Telemetry`:

```elixir
# Instead of manual :telemetry.execute
HexHub.Telemetry.log(:info, :package, "Package published", %{package: name})
```

## Troubleshooting

### Logs Not Appearing in Console

1. Check `LOG_CONSOLE_ENABLED` is `true`
2. Check `LOG_CONSOLE_LEVEL` is not higher than event level
3. Verify handlers are attached: `iex> :telemetry.list_handlers([:hex_hub, :log])`

### File Logging Not Working

1. Check `LOG_FILE_ENABLED` is `true`
2. Verify `LOG_FILE_PATH` is set and writable
3. Check application logs for file handler errors

### Events Not Being Emitted

1. Ensure code uses `:telemetry.execute` not `Logger`
2. Check event name starts with `[:hex_hub, :log, ...]`
3. Verify metadata includes `:level` and `:message` keys

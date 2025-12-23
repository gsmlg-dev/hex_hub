# Data Model: Telemetry-Based Logging System

**Feature**: 001-telemetry-logging
**Date**: 2025-12-23

## Overview

This feature does not introduce persistent data storage. It defines in-memory data structures for telemetry events, log entries, and handler configuration.

## Entities

### 1. Telemetry Log Event

Represents a loggable event emitted via `:telemetry.execute/3`.

```elixir
# Event Name (list of atoms)
[:hex_hub, :log, category]
# where category ∈ {:api, :upstream, :storage, :auth, :package, :mcp, :cluster}

# Measurements (map with numeric values)
%{
  duration: integer() | nil,  # Duration in milliseconds (optional)
  count: integer() | nil      # Count metric (optional)
}

# Metadata (map with context)
%{
  level: :debug | :info | :warning | :error,  # Required
  message: String.t(),                         # Required - human-readable message
  # Additional context fields (optional, varies by category)
  request_id: String.t() | nil,
  path: String.t() | nil,
  package: String.t() | nil,
  version: String.t() | nil,
  user: String.t() | nil,
  error: String.t() | nil,
  node: atom() | nil
}
```

### 2. Log Entry (Output Format)

The JSON structure written to console or file.

```elixir
%{
  ts: String.t(),           # ISO 8601 timestamp with microseconds
  level: String.t(),        # "debug" | "info" | "warning" | "error"
  event: String.t(),        # Dot-separated event name (e.g., "hex_hub.log.api")
  message: String.t(),      # Human-readable message
  duration_ms: integer() | nil,  # Duration if present in measurements
  meta: map()               # All other metadata (sensitive fields redacted)
}
```

**Example Output**:
```json
{
  "ts": "2025-12-23T10:15:30.123456Z",
  "level": "info",
  "event": "hex_hub.log.api",
  "message": "Request completed",
  "duration_ms": 45,
  "meta": {
    "request_id": "abc123",
    "path": "/api/packages/phoenix",
    "status": 200
  }
}
```

### 3. Handler Configuration

Runtime configuration for each log handler.

```elixir
# Console Handler Config
%{
  enabled: boolean(),        # Whether handler is active
  level: atom(),             # Minimum log level (:debug | :info | :warning | :error)
  format: :json | :text      # Output format (default: :json)
}

# File Handler Config
%{
  enabled: boolean(),        # Whether handler is active
  level: atom(),             # Minimum log level
  path: String.t(),          # Absolute path to log file
  format: :json | :text      # Output format (default: :json)
}
```

### 4. Sensitive Data Denylist

Keys that trigger redaction in log output.

```elixir
@sensitive_keys [
  :password,
  :password_hash,
  :secret,
  :secret_key,
  :token,
  :api_key,
  :authorization,
  :bearer,
  :credentials,
  :private_key
]
```

## State Transitions

### Handler Lifecycle

```
┌─────────────┐
│  Disabled   │ ←─── Configuration: enabled: false
└─────────────┘
       │
       │ Application start with enabled: true
       ▼
┌─────────────┐
│  Attached   │ ←─── Handler registered via :telemetry.attach/4
└─────────────┘
       │
       │ Handler error / file not writable
       ▼
┌─────────────┐
│   Failed    │ ←─── Error logged, handler detached
└─────────────┘
       │
       │ Application restart
       ▼
     [Back to Disabled or Attached based on config]
```

### Log Level Filtering

```
Event emitted with level: X
         │
         ▼
┌─────────────────────────────┐
│ Handler configured level: Y │
└─────────────────────────────┘
         │
         ▼
    X >= Y ?
    /     \
  Yes      No
   │        │
   ▼        ▼
 Output   Discard
```

## Validation Rules

1. **Event Name**: Must be a list of atoms starting with `[:hex_hub, :log, ...]`
2. **Level**: Must be one of `:debug`, `:info`, `:warning`, `:error`
3. **Message**: Must be a non-empty string
4. **Timestamp**: Generated at format time, always UTC
5. **File Path**: Must be absolute path if file logging enabled
6. **Sensitive Keys**: Case-insensitive matching, nested keys checked recursively

## Relationships

```
┌──────────────────┐       ┌──────────────────┐
│  Telemetry Event │──────>│   Log Handler    │
│  (emitted)       │  1:N  │  (console/file)  │
└──────────────────┘       └──────────────────┘
                                   │
                                   │ formats to
                                   ▼
                           ┌──────────────────┐
                           │    Log Entry     │
                           │    (JSON)        │
                           └──────────────────┘
                                   │
                                   │ written to
                                   ▼
                           ┌──────────────────┐
                           │   Destination    │
                           │ (console/file)   │
                           └──────────────────┘
```

## No API Contracts

This feature does not expose external APIs. All interactions are internal:
- Events emitted via `:telemetry.execute/3`
- Handlers attached via `:telemetry.attach/4`
- Configuration read from `Application.get_env/3`

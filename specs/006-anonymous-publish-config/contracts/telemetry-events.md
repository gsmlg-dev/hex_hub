# Telemetry Events Contract: Anonymous Publishing

**Feature**: 006-anonymous-publish-config
**Date**: 2025-12-28

## Overview

Telemetry events for observability of anonymous publishing feature (Constitution Principle VII).

## New Events

### [:hex_hub, :publish_config, :updated]

Emitted when admin updates the publish configuration.

**Measurements**:
```elixir
%{}  # No measurements
```

**Metadata**:
```elixir
%{
  enabled: boolean(),       # New enabled state
  previous_enabled: boolean(), # Previous enabled state
  admin_ip: String.t()      # IP of admin making change
}
```

**Example**:
```elixir
:telemetry.execute(
  [:hex_hub, :publish_config, :updated],
  %{},
  %{
    enabled: true,
    previous_enabled: false,
    admin_ip: "192.168.1.50"
  }
)
```

---

### [:hex_hub, :package, :anonymous_publish]

Emitted when a package is published anonymously.

**Measurements**:
```elixir
%{
  duration: integer()  # Publish duration in milliseconds
}
```

**Metadata**:
```elixir
%{
  package: String.t(),      # Package name
  version: String.t(),      # Version published
  ip_address: String.t(),   # Publisher's IP address
  timestamp: DateTime.t(),  # Publish timestamp
  user_agent: String.t() | nil  # Client user agent
}
```

**Example**:
```elixir
:telemetry.execute(
  [:hex_hub, :package, :anonymous_publish],
  %{duration: 250},
  %{
    package: "my_package",
    version: "1.0.0",
    ip_address: "203.0.113.42",
    timestamp: ~U[2025-12-28 15:30:00Z],
    user_agent: "Mix/1.15.0 OTP/26"
  }
)
```

---

### [:hex_hub, :auth, :anonymous_publish_attempt]

Emitted when an anonymous publish is attempted (before actual publish).

**Measurements**:
```elixir
%{}  # No measurements
```

**Metadata**:
```elixir
%{
  ip_address: String.t(),   # Requester's IP address
  allowed: boolean()        # Whether anonymous publishing was allowed
}
```

**Example**:
```elixir
:telemetry.execute(
  [:hex_hub, :auth, :anonymous_publish_attempt],
  %{},
  %{
    ip_address: "203.0.113.42",
    allowed: true
  }
)
```

---

### [:hex_hub, :anonymous_user, :created]

Emitted when the anonymous system user is created at startup.

**Measurements**:
```elixir
%{}  # No measurements
```

**Metadata**:
```elixir
%{
  username: "anonymous"
}
```

---

## Modified Events

### [:hex_hub, :package, :published]

Existing event, add new metadata field:

**Additional Metadata**:
```elixir
%{
  ...,
  anonymous: boolean()  # Whether this was an anonymous publish
}
```

---

## Telemetry Handler Registration

Add handlers in `HexHub.Telemetry`:

```elixir
defmodule HexHub.Telemetry do
  # Existing handlers...

  # Anonymous publish logging
  def handle_event(
        [:hex_hub, :package, :anonymous_publish],
        measurements,
        metadata,
        _config
      ) do
    log(:info, :package, "Anonymous package publish", %{
      package: metadata.package,
      version: metadata.version,
      ip_address: metadata.ip_address,
      duration_ms: measurements.duration
    })
  end

  def handle_event(
        [:hex_hub, :publish_config, :updated],
        _measurements,
        metadata,
        _config
      ) do
    log(:info, :config, "Publish configuration updated", %{
      enabled: metadata.enabled,
      previous: metadata.previous_enabled
    })
  end
end
```

---

## Log Output Format

Example log entries:

```
[info] [package] Anonymous package publish package=my_package version=1.0.0 ip_address=203.0.113.42 duration_ms=250
[info] [config] Publish configuration updated enabled=true previous=false
[info] [auth] Anonymous publish attempt ip_address=203.0.113.42 allowed=true
```

---

## Metrics (Future)

For future Prometheus/StatsD integration:

| Metric | Type | Description |
|--------|------|-------------|
| `hex_hub.package.anonymous_publish.count` | Counter | Total anonymous publishes |
| `hex_hub.package.anonymous_publish.duration` | Histogram | Publish duration distribution |
| `hex_hub.auth.anonymous_attempt.count` | Counter | Anonymous publish attempts |

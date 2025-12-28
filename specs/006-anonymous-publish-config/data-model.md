# Data Model: Anonymous Publish Configuration

**Feature**: 006-anonymous-publish-config
**Date**: 2025-12-28

## Overview

This document defines the data structures for the anonymous publish configuration feature. The feature uses Mnesia for persistence following established patterns.

## Mnesia Tables

### New Table: `:publish_configs`

Configuration settings for package publishing behavior.

```elixir
@table_attrs [
  :id,           # String - always "default"
  :enabled,      # boolean - whether anonymous publishing is allowed
  :inserted_at,  # DateTime (Unix timestamp) - creation time
  :updated_at    # DateTime (Unix timestamp) - last modification time
]

# Table definition
:mnesia.create_table(:publish_configs,
  attributes: [:id, :enabled, :inserted_at, :updated_at],
  type: :set,
  disc_copies: [node()]
)
```

**Record Format**:
```elixir
{:publish_configs, "default", false, 1735344000, 1735344000}
#                   ^id        ^enabled ^inserted_at ^updated_at
```

**Default Values**:
- `id`: `"default"` (only one config record)
- `enabled`: `false` (anonymous publishing disabled by default - FR-003)
- `inserted_at`: Unix timestamp at creation
- `updated_at`: Unix timestamp at last update

## Modified Tables

### Existing Table: `:users`

No schema changes. The "anonymous" user uses existing schema:

```elixir
# Existing attributes (no changes):
[:username, :email, :password_hash, :totp_secret, :totp_enabled,
 :recovery_codes, :service_account, :deactivated_at, :inserted_at, :updated_at]
```

**Anonymous User Record**:
```elixir
{:users, "anonymous", "anonymous@hexhub.local", "<random_hash>",
 nil, false, [], true, nil, <timestamp>, <timestamp>}
#         ^email       ^password_hash  ^totp ^service_account
```

Key characteristics:
- `username`: `"anonymous"` (reserved)
- `email`: `"anonymous@hexhub.local"`
- `password_hash`: Random hash (never used for login)
- `service_account`: `true` (marks as system user)
- `deactivated_at`: `nil` (always active)

## Type Specifications

### PublishConfig Types

```elixir
@type config :: %{
  id: String.t(),
  enabled: boolean(),
  inserted_at: DateTime.t(),
  updated_at: DateTime.t()
}
```

### Anonymous Publish Log Entry (Telemetry Metadata)

```elixir
# Telemetry event metadata for anonymous publishes
@type anonymous_publish_metadata :: %{
  package: String.t(),
  version: String.t(),
  ip_address: String.t(),
  timestamp: DateTime.t(),
  user_agent: String.t() | nil
}
```

## Entity Relationships

```
+-------------------+       +------------------+
|  publish_configs  |       |      users       |
+-------------------+       +------------------+
| id: "default"     |       | username         |
| enabled: boolean  |       | email            |
| inserted_at       |       | service_account  |
| updated_at        |       | ...              |
+-------------------+       +------------------+
         |                          |
         |                          |
         v                          v
+--------------------------------------------------+
|              Package Publishing Flow             |
+--------------------------------------------------+
| If enabled=true AND no auth:                     |
|   - Use "anonymous" user as publisher            |
|   - Log IP + timestamp via telemetry             |
| If enabled=false AND no auth:                    |
|   - Reject with 401                              |
+--------------------------------------------------+
         |
         v
+------------------+
|    packages      |
+------------------+
| name             |
| repository       |
| owner (username) |-----> "anonymous" when published anonymously
| ...              |
+------------------+
```

## Data Migrations

### On Application Startup

1. **Ensure publish_configs table exists**:
   ```elixir
   def ensure_publish_config_table do
     case :mnesia.create_table(:publish_configs, [...]) do
       {:atomic, :ok} -> :ok
       {:aborted, {:already_exists, _}} -> :ok
     end
   end
   ```

2. **Ensure anonymous user exists** (FR-004):
   ```elixir
   def ensure_anonymous_user do
     case HexHub.Users.get_user("anonymous") do
       {:ok, _user} -> :ok
       {:error, :not_found} -> create_anonymous_user()
     end
   end

   defp create_anonymous_user do
     # Create as service account with random password
     HexHub.Users.create_service_account("anonymous", "System user for anonymous publishing")
   end
   ```

### No Migration Required

The feature uses new tables and does not modify existing data structures. Existing packages retain their original owner attribution.

## Validation Rules

### Username Validation (Modified)

```elixir
@reserved_usernames ["anonymous", "admin", "system", "hexhub"]

def validate_username(username) do
  cond do
    username in @reserved_usernames ->
      {:error, "Username is reserved"}
    # ... existing validations
  end
end
```

### Anonymous User Protection

```elixir
def delete_user("anonymous"), do: {:error, "Cannot delete system user"}
def update_user("anonymous", _), do: {:error, "Cannot modify system user"}
```

## Query Patterns

### Check if Anonymous Publishing Enabled

```elixir
def anonymous_publishing_enabled? do
  case :mnesia.dirty_read(:publish_configs, "default") do
    [] -> false  # Default to disabled
    [{:publish_configs, "default", enabled, _, _}] -> enabled
  end
end
```

### Get Anonymous User

```elixir
def get_anonymous_user do
  HexHub.Users.get_user("anonymous")
end
```

### Log Anonymous Publish (Telemetry)

```elixir
:telemetry.execute(
  [:hex_hub, :package, :anonymous_publish],
  %{duration: duration_ms},
  %{
    package: package_name,
    version: version,
    ip_address: conn.remote_ip |> :inet.ntoa() |> to_string(),
    timestamp: DateTime.utc_now()
  }
)
```

## Indexes

### publish_configs

No additional indexes needed. Single record accessed by primary key.

### users

Existing indexes sufficient:
- Primary key on `username`
- Secondary index on `email`
- Secondary index on `service_account` (for listing service accounts)

## Data Retention

- **Config data**: Persisted indefinitely, single record
- **Audit logs**: Telemetry events, retention based on log handler configuration
- **Anonymous user**: System user, never deleted

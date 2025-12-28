# Publish API Contract: Anonymous Publishing

**Feature**: 006-anonymous-publish-config
**Date**: 2025-12-28

## Overview

Modifications to the existing package publish API to support anonymous publishing when enabled.

## Affected Endpoints

### POST /publish (and POST /packages/:name/releases)

**Current Behavior**:
- Requires authentication via `api_auth` pipeline
- Rejects with 401 if no/invalid API key

**New Behavior** (when anonymous publishing enabled):

| Anonymous Publishing | Auth Header | Result |
|---------------------|-------------|--------|
| Disabled (default)  | None        | 401 Unauthorized |
| Disabled            | Valid       | Normal publish |
| Enabled             | None        | Publish as "anonymous" user |
| Enabled             | Invalid     | 401 Unauthorized |
| Enabled             | Valid       | Normal publish |

---

## Request/Response Examples

### Anonymous Publish (Enabled)

**Request**:
```http
POST /publish HTTP/1.1
Host: hexhub.example.com
Content-Type: application/octet-stream

<tarball binary>
```

**Response** (201 Created):
```json
{
  "version": "0.1.0",
  "has_docs": false,
  "meta": {
    "build_tools": ["mix"]
  },
  "requirements": {},
  "retired": null,
  "downloads": 0,
  "inserted_at": "2025-12-28T10:00:00Z",
  "updated_at": "2025-12-28T10:00:00Z",
  "url": "/api/packages/my_package/releases/0.1.0",
  "package_url": "/api/packages/my_package/releases/0.1.0/download",
  "html_url": "/packages/my_package/0.1.0",
  "docs_html_url": null
}
```

**Telemetry Event**:
```elixir
:telemetry.execute(
  [:hex_hub, :package, :anonymous_publish],
  %{duration: 150},
  %{
    package: "my_package",
    version: "0.1.0",
    ip_address: "192.168.1.100",
    timestamp: ~U[2025-12-28 10:00:00Z],
    user_agent: "Mix/1.15.0 OTP/26"
  }
)
```

---

### Anonymous Publish (Disabled - Default)

**Request**:
```http
POST /publish HTTP/1.1
Host: hexhub.example.com
Content-Type: application/octet-stream

<tarball binary>
```

**Response** (401 Unauthorized):
```json
{
  "message": "API key required",
  "status": 401
}
```

---

### Authenticated Publish (Both Settings)

**Request**:
```http
POST /publish HTTP/1.1
Host: hexhub.example.com
Authorization: Bearer abc123def456
Content-Type: application/octet-stream

<tarball binary>
```

**Response** (201 Created):
```json
{
  "version": "0.1.0",
  ...
}
```

---

## Package Ownership

### Anonymous Publish

- Package owner set to "anonymous" user
- Owner displayed in package listing and details
- Owner cannot be transferred/changed by anonymous user (no auth)

### Package Already Exists

| Existing Owner | Anonymous Publish | Result |
|---------------|-------------------|--------|
| "anonymous"   | Allowed           | New version added |
| Other user    | Allowed           | New version added, ownership unchanged |

**Rationale**: Anonymous publishing creates packages but doesn't claim ownership in a meaningful sense. Existing owners retain control.

---

## Error Codes

| Code | Condition |
|------|-----------|
| 201  | Package published successfully |
| 400  | Invalid tarball format |
| 401  | Authentication required (anon disabled) or invalid key |
| 422  | Validation error (version exists, etc.) |
| 500  | Internal server error |

---

## Implementation Notes

### Router Changes

Create conditional authentication for publish routes:

```elixir
# New pipeline
pipeline :api_auth_optional do
  plug :accepts, ["json", "hex+erlang"]
  plug HexHubWeb.Plugs.HexFormat
  plug HexHubWeb.Plugs.OptionalAuthenticate  # New plug
  plug HexHubWeb.Plugs.RateLimit
end

pipeline :require_write_or_anonymous do
  plug HexHubWeb.Plugs.AuthorizeOrAnonymous, "write"  # New plug
end
```

### OptionalAuthenticate Plug

```elixir
defmodule HexHubWeb.Plugs.OptionalAuthenticate do
  def call(conn, _opts) do
    case extract_api_key(conn) do
      {:ok, key} ->
        # Normal authentication flow
        authenticate_with_key(conn, key)

      {:error, :missing_key} ->
        # Check if anonymous publishing is enabled
        if HexHub.PublishConfig.anonymous_publishing_enabled?() do
          assign_anonymous_user(conn)
        else
          # Return 401 as before
          unauthorized(conn)
        end

      {:error, :invalid_format} ->
        unauthorized(conn)
    end
  end

  defp assign_anonymous_user(conn) do
    {:ok, anonymous_user} = HexHub.Users.get_user("anonymous")

    # Log the anonymous publish attempt
    :telemetry.execute(
      [:hex_hub, :auth, :anonymous_publish_attempt],
      %{},
      %{ip_address: format_ip(conn.remote_ip)}
    )

    assign(conn, :current_user, %{
      username: anonymous_user.username,
      permissions: ["write"]
    })
  end
end
```

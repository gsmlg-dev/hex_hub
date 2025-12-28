# Research: Anonymous Publish Configuration

**Feature**: 006-anonymous-publish-config
**Date**: 2025-12-28

## Executive Summary

This feature adds an admin-configurable setting to allow anonymous package publishing. When enabled, packages can be published without API key authentication, attributed to a system "anonymous" user. The implementation follows established patterns in the codebase for configuration management (UpstreamConfig) and system users (service accounts).

## Existing Patterns Analysis

### 1. Configuration Management Pattern (UpstreamConfig)

**Location**: `lib/hex_hub/upstream_config.ex`

The `UpstreamConfig` module provides the exact pattern to follow:

- Uses Mnesia `:upstream_configs` table for persistence
- Stores configuration with `"default"` key
- Provides `get_config/0`, `update_config/1`, `enabled?/0`, `init_default_config/0`
- Uses helper functions for parameter parsing: `get_param_bool`, `get_param_string`, `get_param_int`
- Emits telemetry events for config changes via `HexHub.Telemetry.log/4`
- Returns default config if none exists in database

**Recommendation**: Create `HexHub.PublishConfig` following this exact pattern.

### 2. User Management Pattern

**Location**: `lib/hex_hub/users.ex`

Key observations:
- User schema includes `service_account` boolean field
- `create_service_account/2` creates special users with random passwords
- Service accounts use special email format: `service+#{username}@hexhub.local`
- Users stored in Mnesia `:users` table with full CRUD operations
- `validate_username/1` validates username format

**Recommendation**: Create anonymous user as a service account during application startup. Add "anonymous" to reserved username list.

### 3. Authentication Pipeline

**Location**: `lib/hex_hub_web/plugs/authenticate.ex`

Current flow:
1. `Authenticate` plug extracts API key from Authorization header (Bearer/Basic/raw)
2. Validates key against `ApiKeys.validate_key/1`
3. Assigns `current_user` with username and permissions
4. Returns 401 if missing or invalid key

**Recommendation**: Create a new plug `OptionalAuthenticate` that:
- Attempts authentication normally
- If `PublishConfig.anonymous_publishing_enabled?()` is true and no key provided
- Assigns anonymous user to `current_user` instead of returning 401

### 4. Publish Endpoint Flow

**Location**: `lib/hex_hub_web/controllers/api/release_controller.ex`

Publish endpoint (`POST /publish`):
- Uses pipelines: `[:api_auth, :require_write]`
- `publish/2` action extracts tarball, creates package/release
- Calls `ensure_package_exists/3` which uses `Packages.create_package/4`
- `maybe_add_owner/2` adds current user as package owner

**Recommendation**:
1. Modify router to use conditional authentication for publish endpoints
2. Modify `maybe_add_owner/2` to handle anonymous user appropriately
3. Add IP logging for anonymous publishes

### 5. Admin Controller Pattern

**Location**: `lib/hex_hub_admin_web/controllers/upstream_controller.ex`

Pattern for config controllers:
- `index/2` shows current config in form
- `update/2` handles form submission
- Uses flash messages for success/error feedback
- Templates use DaisyUI form components

**Recommendation**: Create `PublishConfigController` following this pattern.

### 6. Mnesia Table Definition

**Location**: `lib/hex_hub/mnesia.ex`

Table definition pattern:
```elixir
:mnesia.create_table(:upstream_configs,
  attributes: [:id, :enabled, :api_url, ...],
  type: :set,
  disc_copies: [node()]
)
```

**Recommendation**: Add `:publish_configs` table with minimal schema:
- `id` (always "default")
- `enabled` (boolean, defaults to false)
- `inserted_at`, `updated_at` timestamps

## Technical Approach

### Phase 1: Schema & Config Module

1. **Add Mnesia table**: `:publish_configs` in `mnesia.ex`
2. **Create `HexHub.PublishConfig`**:
   - `get_config/0` - returns current config or defaults
   - `update_config/1` - updates config from form params
   - `anonymous_publishing_enabled?/0` - boolean check
   - `init_default_config/0` - called at startup

### Phase 2: Anonymous User

1. **Create anonymous user at startup** in `application.ex`:
   - Check if "anonymous" user exists
   - Create as service account if missing
   - Cannot be deleted/modified (protection in Users module)

2. **Reserve "anonymous" username**:
   - Add validation in `Users.validate_username/1`
   - Reject registration attempts for reserved names

### Phase 3: Authentication Bypass

1. **Create `Plugs.OptionalAuthenticate`**:
   - Check `PublishConfig.anonymous_publishing_enabled?/0`
   - If enabled and no auth header, assign anonymous user
   - Log IP address and timestamp via telemetry

2. **Update router**:
   - Create new pipeline for conditional auth
   - Apply to publish endpoints only

### Phase 4: Admin UI

1. **Create `PublishConfigController`**:
   - `index/2` - show config form
   - `update/2` - save config

2. **Create templates**:
   - Form with toggle switch for enabled/disabled
   - Confirmation dialog on change

3. **Add to admin navigation**:
   - Link in sidebar under Settings

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| Abuse via anonymous publishing | Admin can disable; spec says no rate limiting |
| Anonymous user deletion | Add protection flag, recreate on startup |
| Username collision | Reserve "anonymous" in validation |
| Breaking existing auth flow | New plug, not modifying existing Authenticate |

## Dependencies

- Existing: Phoenix 1.8+, Mnesia, DaisyUI/Tailwind
- No new dependencies required

## Testing Strategy

1. **Unit tests**:
   - PublishConfig module functions
   - Anonymous user creation/protection
   - Username reservation

2. **Integration tests**:
   - Publish with/without auth when setting enabled/disabled
   - Admin toggle persistence
   - IP logging for anonymous publishes

3. **E2E tests** (optional):
   - Full publish flow via mix hex.publish

## Open Questions (Resolved)

1. ~~Rate limiting for anonymous publishes~~ → No rate limiting per spec
2. ~~Audit logging~~ → Log IP + timestamp per clarification

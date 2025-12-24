# Research: E2E Test Suite for hex.publish

**Feature**: 002-hex-publish-e2e
**Date**: 2025-12-23

## Summary

This document captures research findings for implementing E2E tests for the `mix hex.publish` command against HexHub.

---

## Research Topic 1: Hex Client Environment Variables

**Question**: What environment variables are required to configure `mix hex.publish` to use a local HexHub instance?

**Decision**: Use `HEX_API_URL` and `HEX_API_KEY` environment variables

**Rationale**:
- `HEX_API_URL` - Points the hex client to the HexHub API endpoint (e.g., `http://localhost:4000/api`)
- `HEX_API_KEY` - Provides the API key for authentication (Bearer token format)
- `HEX_UNSAFE_REGISTRY=1` - May be needed to allow HTTP (non-HTTPS) connections in test environment

**Alternatives Considered**:
- Using `HEX_MIRROR` - Only affects package downloads, not publishing
- Modifying hex config globally - Would affect other projects

**Source**: Hex documentation and existing E2E test infrastructure in `e2e_test/support/server_helper.ex`

---

## Research Topic 2: Test Fixture Project Requirements

**Question**: What are the minimum requirements for a publishable Elixir project?

**Decision**: Create a minimal mix.exs with required hex publishing fields

**Required Fields**:
- `:app` - Application name (atom)
- `:version` - Semantic version string (e.g., "0.1.0")
- `:description` - Short description (required for hex)
- `:package` - Package metadata including:
  - `:name` - Package name (string, lowercase with underscores)
  - `:licenses` - List of license identifiers (e.g., ["MIT"])
  - `:links` - Map of URLs (can be empty)
  - `:files` - List of files to include (defaults work)

**Example mix.exs**:
```elixir
defmodule E2eTestPkg.MixProject do
  use Mix.Project

  def project do
    [
      app: :e2e_test_pkg,
      version: "0.1.0",
      elixir: "~> 1.15",
      description: "E2E test package for HexHub publish testing",
      package: package(),
      deps: deps()
    ]
  end

  defp package do
    [
      name: "e2e_test_pkg",
      licenses: ["MIT"],
      links: %{}
    ]
  end

  defp deps, do: []
end
```

**Rationale**: This is the minimum viable configuration that `mix hex.publish` will accept without errors.

---

## Research Topic 3: API Key Generation for Tests

**Question**: How should test API keys be generated and configured?

**Decision**: Use `HexHub.ApiKeys.generate_key/3` programmatically in test setup

**Implementation Approach**:
1. Create a test user via `HexHub.Users.create_user/4`
2. Generate API key with write permissions via `HexHub.ApiKeys.generate_key/3`
3. Set `HEX_API_KEY` environment variable for subprocess calls
4. Clean up user and keys in test teardown

**Key Permissions**:
- `["read"]` - For testing authentication failure on publish
- `["read", "write"]` - For successful publish tests

**Rationale**: The existing `HexHub.ApiKeys` module provides all necessary functionality. Programmatic generation ensures test isolation.

---

## Research Topic 4: Server Helper Environment Configuration

**Question**: How to configure hex client environment for publish operations?

**Decision**: Extend `E2E.ServerHelper.hex_mirror_env/1` with publish-specific variables

**Current Implementation** (from server_helper.ex):
```elixir
def hex_mirror_env(port) do
  [
    {"HEX_MIRROR", "http://localhost:#{port}"},
    {"HEX_UNSAFE_REGISTRY", "1"},
    {"MIX_ENV", "test"}
  ]
end
```

**New Function** for publish:
```elixir
def hex_publish_env(port, api_key) do
  [
    {"HEX_API_URL", "http://localhost:#{port}/api"},
    {"HEX_API_KEY", api_key},
    {"HEX_UNSAFE_REGISTRY", "1"},
    {"MIX_ENV", "dev"}  # Use dev for publishing
  ]
end
```

**Rationale**: Publish requires `HEX_API_URL` pointing to the API endpoint, while mirror uses `HEX_MIRROR` for the repo root.

---

## Research Topic 5: Test Isolation and Cleanup

**Question**: How to ensure test data doesn't persist between test runs?

**Decision**: Use existing reset functions and cleanup in test setup/teardown

**Cleanup Strategy**:
1. Call `HexHub.Packages.reset_test_store()` to clear packages and releases
2. Call `HexHub.Users.reset_test_store()` to clear test users
3. Call `HexHub.ApiKeys.reset_test_store()` to clear API keys
4. Remove fixture project artifacts (deps/, _build/, mix.lock)

**Test Setup Pattern**:
```elixir
setup_all do
  # Clear test data
  HexHub.Packages.reset_test_store()
  HexHub.Users.reset_test_store()
  HexHub.ApiKeys.reset_test_store()

  # Create test user and API key
  {:ok, _user} = HexHub.Users.create_user("e2e_publisher", "e2e@test.com", "password123")
  {:ok, api_key} = HexHub.ApiKeys.generate_key("e2e_test_key", "e2e_publisher", ["read", "write"])

  {:ok, api_key: api_key}
end
```

**Rationale**: Leverages existing reset functions for consistency with unit tests.

---

## Research Topic 6: Package Publish API Endpoint

**Question**: What is the exact API endpoint and format for package publishing?

**Decision**: Use `POST /api/publish` with tarball body and Bearer auth

**Endpoint Details** (from router.ex and release_controller.ex):
- **Route**: `POST /api/publish`
- **Authentication**: Bearer token via `Authorization` header
- **Content-Type**: `application/octet-stream` (tarball)
- **Request Body**: Package tarball (created by `mix hex.build`)

**Response Format**:
- Success (201): JSON with release metadata
- Auth failure (401): Unauthorized
- Permission denied (403): Forbidden
- Validation error (422): JSON with error message

**Rationale**: The existing `ReleaseController.publish/2` handles this endpoint.

---

## Research Topic 7: Hex Client Invocation Pattern

**Question**: How should `mix hex.publish` be invoked in tests?

**Decision**: Use `System.cmd/3` with environment variables and `--yes` flag

**Invocation Pattern**:
```elixir
{output, exit_code} = System.cmd(
  "mix",
  ["hex.publish", "--yes"],
  cd: fixture_project_path,
  env: hex_publish_env(port, api_key),
  stderr_to_stdout: true
)
```

**Important Flags**:
- `--yes` - Skip interactive confirmation
- `--replace` - Allow overwriting existing version (for replace tests)
- `--dry-run` - Validate without publishing (for validation tests)

**Rationale**: Matches existing pattern in proxy_test.exs for `mix deps.get`.

---

## Decisions Summary

| Area | Decision | Impact |
|------|----------|--------|
| Environment Config | `HEX_API_URL` + `HEX_API_KEY` | Required for all publish tests |
| Fixture Project | Minimal mix.exs with package metadata | Single fixture serves all tests |
| API Keys | Programmatic generation per test suite | Clean isolation |
| Cleanup | Reset functions + file cleanup | No test pollution |
| Invocation | `System.cmd` with `--yes` flag | Consistent with existing E2E |
| Assertions | Exit code + API verification | Validates end-to-end flow |

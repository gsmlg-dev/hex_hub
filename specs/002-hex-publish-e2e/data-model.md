# Data Model: E2E Test Suite for hex.publish

**Feature**: 002-hex-publish-e2e
**Date**: 2025-12-23

## Overview

This document defines the data entities and their relationships for the hex.publish E2E test suite. As this is a testing feature, the data model focuses on test fixtures, test configuration, and expected API contracts rather than new application entities.

---

## Entity: Test Project Fixture

A minimal Elixir project configured for publishing to HexHub.

### Structure

```
e2e_test/fixtures/publish_project/
├── mix.exs           # Project configuration with hex metadata
├── lib/
│   └── e2e_test_pkg.ex  # Minimal module
└── .gitignore        # Ignore build artifacts
```

### mix.exs Configuration

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| app | atom | Yes | Application name (`:e2e_test_pkg`) |
| version | string | Yes | Semantic version (default: "0.1.0") |
| elixir | string | Yes | Elixir version requirement |
| description | string | Yes | Package description for hex |
| package.name | string | Yes | Hex package name |
| package.licenses | list | Yes | License identifiers |
| package.links | map | No | Project URLs (can be empty) |
| deps | list | No | Dependencies (empty for test) |

### State Transitions

```
[Fixture Created] → [Version Updated] → [Build Clean]
                         ↑                    │
                         └────────────────────┘
```

---

## Entity: Test User

A user account created specifically for E2E publish testing.

### Attributes

| Field | Type | Value in Tests |
|-------|------|----------------|
| username | string | "e2e_publisher" |
| email | string | "e2e@test.com" |
| password | string | "password123456" |

### Relationships

- Has many: API Keys
- Owns: Published packages (during test)

---

## Entity: Test API Key

API key for authenticating publish operations.

### Attributes

| Field | Type | Description |
|-------|------|-------------|
| name | string | Key identifier (e.g., "e2e_write_key") |
| username | string | Owner username |
| permissions | list | `["read", "write"]` or `["read"]` |
| secret | string | Random 64-character hex string |

### Permission Scenarios

| Scenario | Permissions | Expected Result |
|----------|-------------|-----------------|
| Full access | `["read", "write"]` | Publish succeeds |
| Read only | `["read"]` | 403 Forbidden |
| No key | N/A | 401 Unauthorized |
| Invalid key | N/A | 401 Unauthorized |

---

## Entity: Published Package (Test Result)

Package created as a result of successful publish test.

### Attributes (from API response)

| Field | Type | Validation |
|-------|------|------------|
| name | string | Matches fixture package name |
| version | string | Matches fixture version |
| has_docs | boolean | false (no docs in test fixture) |
| meta | map | Contains build_tools |
| requirements | map | Empty for test fixture |

---

## Entity: Environment Configuration

Environment variables passed to `System.cmd/3` for hex client.

### Publish Environment

| Variable | Value | Purpose |
|----------|-------|---------|
| HEX_API_URL | `http://localhost:#{port}/api` | API endpoint |
| HEX_API_KEY | Test API key secret | Authentication |
| HEX_UNSAFE_REGISTRY | "1" | Allow HTTP |
| MIX_ENV | "dev" | Publishing environment |

### Mirror Environment (existing)

| Variable | Value | Purpose |
|----------|-------|---------|
| HEX_MIRROR | `http://localhost:#{port}` | Mirror endpoint |
| HEX_UNSAFE_REGISTRY | "1" | Allow HTTP |
| MIX_ENV | "test" | Testing environment |

---

## API Contract: POST /api/publish

### Request

```
POST /api/publish HTTP/1.1
Host: localhost:4000
Authorization: Bearer {api_key}
Content-Type: application/octet-stream

{tarball_binary}
```

### Success Response (201)

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
  "inserted_at": "2025-12-23T00:00:00Z",
  "updated_at": "2025-12-23T00:00:00Z",
  "url": "/packages/e2e_test_pkg/releases/0.1.0",
  "package_url": "/packages/e2e_test_pkg/releases/0.1.0/package",
  "html_url": "/packages/e2e_test_pkg/releases/0.1.0",
  "docs_html_url": "/packages/e2e_test_pkg/releases/0.1.0/docs"
}
```

### Error Responses

| Status | Scenario | Body |
|--------|----------|------|
| 401 | No/invalid API key | `{"message": "Unauthorized"}` |
| 403 | No write permission | `{"message": "Forbidden"}` |
| 404 | Package not found | `{"message": "Package not found"}` |
| 422 | Validation error | `{"message": "error details"}` |

---

## Test Data Lifecycle

```
┌─────────────────────────────────────────────────────────────┐
│                     TEST SETUP                              │
│  1. Reset Mnesia tables (packages, users, api_keys)         │
│  2. Create test user                                        │
│  3. Generate API keys (read-only and read-write)            │
│  4. Clean fixture project artifacts                         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     TEST EXECUTION                          │
│  1. Configure fixture version (if testing multiple)         │
│  2. Set environment variables                               │
│  3. Run `mix hex.publish --yes`                             │
│  4. Assert exit code                                        │
│  5. Verify via API (package exists, correct metadata)       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     TEST TEARDOWN                           │
│  1. Clean fixture artifacts (deps/, _build/, mix.lock)      │
│  2. Reset Mnesia tables (handled by setup_all on_exit)      │
└─────────────────────────────────────────────────────────────┘
```

---

## Validation Rules

### Package Name
- Must be lowercase
- Only letters, numbers, underscores allowed
- Must start with a letter
- Max 100 characters

### Version
- Must be semantic version format (X.Y.Z)
- Cannot reuse existing version (unless `--replace` within window)

### Tarball
- Max 8MB compressed
- Max 64MB uncompressed
- Must contain valid hex package structure

# Data Model: E2E Test Infrastructure

**Feature**: 001-e2e-test-setup
**Date**: 2025-11-26

## Overview

This feature is test infrastructure and does not introduce new persistent data entities. The E2E tests use existing HexHub data models (packages, releases, users) through the standard API.

## Test Fixtures

### Test Project Fixture

**Location**: `e2e_test/fixtures/test_project/`

**Purpose**: Minimal Mix project used to test `mix deps.get` through HexHub proxy

**Structure**:
```text
test_project/
├── mix.exs        # Project definition with test dependencies
├── lib/
│   └── test_project.ex  # Empty module
└── .gitignore     # Ignore _build, deps, mix.lock (regenerated during test)
```

**mix.exs Contents**:
```elixir
defmodule TestProject.MixProject do
  use Mix.Project

  def project do
    [
      app: :test_project,
      version: "0.1.0",
      elixir: "~> 1.15",
      deps: deps()
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"}
    ]
  end
end
```

## Runtime State

### Server State (Transient)

| State | Type | Lifecycle | Description |
|-------|------|-----------|-------------|
| Server PID | pid | Test run | Phoenix endpoint process |
| Assigned Port | integer | Test run | Dynamic port from OS |
| Mnesia Directory | path | Test run | Fresh directory per run |
| Test Storage | path | Test run | Isolated storage directory |

### Environment Variables (Test Scope)

| Variable | Value | Purpose |
|----------|-------|---------|
| `HEX_MIRROR` | `http://localhost:{port}` | Redirect hex to local HexHub |
| `HEX_UNSAFE_REGISTRY` | `1` | Allow non-HTTPS registry |
| `MIX_ENV` | `test` | Ensure test environment |

## Existing Entities Used

The E2E tests interact with existing HexHub entities through the API:

- **Packages**: Fetched from upstream (hex.pm) through proxy
- **Releases**: Downloaded as tarballs through proxy
- **Registries**: Hex registry files served by HexHub

No modifications to existing entity schemas required.

# Quickstart: E2E Test Infrastructure

**Feature**: 001-e2e-test-setup
**Date**: 2025-11-26

## Running E2E Tests

### Locally

```bash
# Run all E2E tests
mix test.e2e

# Run with verbose output
mix test.e2e --trace

# Run specific test file
mix test.e2e e2e_test/proxy_test.exs

# Run with specific seed
mix test.e2e --seed 12345
```

### In CI

E2E tests run automatically on:
- Pull requests targeting `main` or `develop` branches
- Pushes to `main` branch

View results in the GitHub Actions "E2E Tests" workflow.

## What Gets Tested

The E2E tests validate:

1. **Server Startup**: HexHub starts on a dynamic port
2. **Hex Configuration**: Local HexHub configured as mirror
3. **Package Fetch**: `jason` package fetched through proxy
4. **Upstream Proxy**: Packages retrieved from hex.pm and cached

## Test Structure

```text
e2e_test/
├── test_helper.exs       # E2E test configuration
├── support/
│   ├── e2e_case.ex       # Base test case
│   └── server_helper.ex  # Server lifecycle helpers
├── fixtures/
│   └── test_project/     # Minimal Mix project
└── proxy_test.exs        # Main proxy tests
```

## Requirements

- Network access to hex.pm
- Available ephemeral port (OS-assigned)
- Elixir 1.15+ and OTP 27+

## Troubleshooting

### Port Conflicts

If tests fail with port binding errors:
```bash
# Check for zombie HexHub processes
pgrep -f "hex_hub" | xargs kill -9
```

### Network Issues

If hex.pm is unreachable:
```bash
# Verify connectivity
curl -I https://hex.pm/api/packages/jason

# Tests will fail with timeout error if unreachable
```

### Mnesia Errors

If Mnesia initialization fails:
```bash
# Clean Mnesia directories
rm -rf Mnesia.*

# Re-run tests
mix test.e2e
```

## Adding New E2E Tests

1. Create new test file in `e2e_test/`
2. Use `E2E.Case` as base:
   ```elixir
   defmodule E2E.NewFeatureTest do
     use E2E.Case

     test "new feature works", %{base_url: url} do
       # Test implementation
     end
   end
   ```
3. Run: `mix test.e2e e2e_test/new_feature_test.exs`

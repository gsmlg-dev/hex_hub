# Quickstart: E2E Test Suite for hex.publish

**Feature**: 002-hex-publish-e2e
**Date**: 2025-12-23

## Prerequisites

- Elixir 1.15+ installed
- HexHub repository cloned
- Dependencies installed (`mix deps.get`)
- Hex package installed (`mix local.hex --force`)

## Quick Verification Steps

After implementation, verify the E2E publish tests work:

### 1. Run All E2E Tests

```bash
# Run the full E2E test suite (includes publish tests)
mix test.e2e
```

**Expected**: All tests pass, including new publish tests

### 2. Run Only Publish Tests

```bash
# Run just the publish-specific E2E tests
mix test.e2e e2e_test/publish_test.exs
```

**Expected**: Publish tests pass with output similar to:
```
Running ExUnit with seed: 12345, max_cases: 32

.....

Finished in 45.2 seconds
5 tests, 0 failures
```

### 3. Verify Test Isolation

```bash
# Run tests 3 times consecutively to check for flakiness
for i in 1 2 3; do echo "=== Run $i ==="; mix test.e2e e2e_test/publish_test.exs; done
```

**Expected**: All 3 runs pass without failures

### 4. Manual Publish Test

Start the HexHub server and test manually:

```bash
# Terminal 1: Start HexHub server
PORT=4361 mix phx.server

# Terminal 2: Create a test user and get API key (via IEx)
iex -S mix
> {:ok, _} = HexHub.Users.create_user("manual_test", "manual@test.com", "password123456")
> {:ok, api_key} = HexHub.ApiKeys.generate_key("manual_key", "manual_test", ["read", "write"])
> IO.puts("API Key: #{api_key}")
# Note the printed API key

# Terminal 3: Test publish from fixture project
cd e2e_test/fixtures/publish_project
HEX_API_URL=http://localhost:4361/api HEX_API_KEY=<your_api_key> HEX_UNSAFE_REGISTRY=1 mix hex.publish --yes
```

**Expected**: Package publishes successfully with output:
```
Building e2e_test_pkg 0.1.0
  Included files:
    ...
Publishing e2e_test_pkg 0.1.0

Package published successfully!
```

### 5. Verify Published Package

```bash
# Query the API to verify package was published
curl http://localhost:4361/api/packages/e2e_test_pkg
```

**Expected**: JSON response with package metadata

## Test Scenarios Covered

| Test | Description | Expected Result |
|------|-------------|-----------------|
| Basic publish | Publish with valid credentials | Exit code 0, package in API |
| No API key | Publish without authentication | Exit code != 0, 401 error |
| Invalid API key | Publish with wrong key | Exit code != 0, 401 error |
| Read-only key | Publish with no write permission | Exit code != 0, 403 error |
| Multiple versions | Publish 0.1.0 then 0.2.0 | Both versions accessible |

## Troubleshooting

### Test Fails with "Connection Refused"

1. Check if server started correctly on dynamic port
2. Verify `E2E.ServerHelper.start_server/1` returns `{:ok, port}`
3. Check for port conflicts

```bash
# Check what's using common ports
lsof -i :4000
```

### Test Fails with "Unauthorized"

1. Verify API key was generated with write permissions
2. Check `HEX_API_KEY` environment variable is set correctly
3. Ensure user exists in Mnesia

```elixir
# Debug in IEx
HexHub.Users.get_user("e2e_publisher")
HexHub.ApiKeys.list_keys("e2e_publisher")
```

### Test Fails with "Package Not Found"

1. Check if package needs to be created first (HexHub may require package to exist)
2. Verify fixture project has correct package name in mix.exs

### Tests Are Flaky

1. Increase timeouts in test configuration
2. Check for async test interference
3. Ensure cleanup is complete between tests

```elixir
# Add explicit cleanup in setup
HexHub.Packages.reset_test_store()
HexHub.Users.reset_test_store()
HexHub.ApiKeys.reset_test_store()
```

## Configuration Reference

### Environment Variables for Publishing

| Variable | Required | Description |
|----------|----------|-------------|
| `HEX_API_URL` | Yes | HexHub API endpoint (e.g., `http://localhost:4000/api`) |
| `HEX_API_KEY` | Yes | API key with write permission |
| `HEX_UNSAFE_REGISTRY` | Yes* | Set to "1" to allow HTTP connections |

*Required when using HTTP instead of HTTPS

### Test Configuration

```elixir
# e2e_test/test_helper.exs
ExUnit.start(
  timeout: 120_000,  # 2 minutes per test
  trace: false       # Set to true for verbose output
)
```

## File Structure After Implementation

```
e2e_test/
├── fixtures/
│   ├── test_project/        # Existing: for deps.get tests
│   └── publish_project/     # NEW: for publish tests
│       ├── mix.exs
│       ├── lib/
│       │   └── e2e_test_pkg.ex
│       └── .gitignore
├── support/
│   ├── e2e_case.ex          # Existing
│   ├── server_helper.ex     # Existing (extended)
│   └── publish_helper.ex    # NEW: publish-specific helpers
├── proxy_test.exs           # Existing
├── publish_test.exs         # NEW: publish E2E tests
└── test_helper.exs          # Existing
```

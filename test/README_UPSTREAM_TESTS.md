# Upstream Package Fetching Tests

This directory contains comprehensive tests for the upstream package fetching functionality in HexHub.

## Test Files

### Core Test Files

1. **`upstream_mock_test.exs`** - Mock-based tests that don't require network access
2. **`upstream_integration_test.exs`** - Real integration tests against hex.pm (requires environment variable)
3. **`upstream_functional_test.exs`** - End-to-end functional tests with helpers
4. **`upstream_download_controller_test.exs`** - API endpoint tests for upstream functionality
5. **`packages_upstream_test.exs`** - Tests for package operations with upstream fallback

### Helper Files

- **`support/upstream_test_helpers.exs`** - Common utilities and helpers for upstream testing

## Running Tests

### Mock-based Tests (Recommended for CI)

```bash
# Run all upstream mock tests
mix test test/hex_hub/upstream_mock_test.exs

# Run functional tests
mix test test/hex_hub/upstream_functional_test.exs

# Run controller tests
mix test test/hex_hub_web/controllers/api/upstream_download_controller_test.exs

# Run all package-related tests
mix test test/hex_hub/packages_upstream_test.exs
```

### Integration Tests (Real Network Access)

⚠️ **Warning**: These tests make real HTTP requests to hex.pm and may be slow.

```bash
# Enable integration tests and run them
HEX_HUB_INTEGRATION_TESTS=true mix test test/hex_hub/upstream_integration_test.exs

# Run all integration tests
HEX_HUB_INTEGRATION_TESTS=true mix test --only integration
```

### Running All Upstream Tests

```bash
# Run all mock-based tests (fast)
mix test --only upstream_mock

# Run all tests including integration (slow)
HEX_HUB_INTEGRATION_TESTS=true mix test --only upstream
```

## Test Categories

### 1. Configuration Tests
- Test upstream enable/disable functionality
- Test custom upstream URLs
- Test timeout and retry configurations

### 2. HTTP Client Tests
- Test successful package metadata fetching
- Test release tarball downloading
- Test documentation tarball downloading
- Test error handling (404, 500, network errors)
- Test retry logic with network failures

### 3. Package Operations Tests
- Test `get_package/1` with upstream fallback
- Test `get_release/2` with upstream fallback
- Test `download_package_with_upstream/2`
- Test `download_docs_with_upstream/2`
- Test caching behavior

### 4. API Endpoint Tests
- Test download endpoints with upstream fallback
- Test proper HTTP headers and caching
- Test error responses

### 5. Integration Tests
- Test against real hex.pm API
- Test complete workflow from upstream to cache
- Test with real package data

## Test Data

### Mock Package Structure
```elixir
%{
  "name" => "test_package",
  "repository" => "hexpm",
  "meta" => %{
    "description" => "Test package description",
    "licenses" => ["MIT"],
    "links" => %{"GitHub" => "https://github.com/test/package"},
    "maintainers" => ["Test User"]
  }
}
```

### Mock Release Structure
```elixir
%{
  "version" => "1.0.0",
  "meta" => %{
    "app" => "test_package",
    "build_tools" => ["mix"],
    "description" => "Test package v1.0.0",
    "licenses" => ["MIT"]
  },
  "requirements" => %{
    "ecto" => "~> 3.0"
  }
}
```

## Common Test Patterns

### Setting Up Mocks
```elixir
setup do
  # Mock upstream package response
  UpstreamHelpers.mock_upstream_package_response("test_package")

  # Mock storage operations
  UpstreamHelpers.setup_storage_mocks()

  # Track HTTP requests
  UpstreamHelpers.track_http_requests()
end
```

### Testing Upstream Fallback
```elixir
test "fetches from upstream when not local" do
  package_name = "upstream_package"

  # Ensure package doesn't exist locally
  assert {:error, :not_found} = Packages.get_package_direct(package_name)

  # Mock upstream response
  UpstreamHelpers.mock_upstream_package_response(package_name)

  # Should fetch from upstream
  {:ok, package} = Packages.get_package(package_name)
  assert package.name == package_name
end
```

### Testing Caching
```elixir
test "caches fetched packages" do
  package_name = "cache_test"

  # Mock upstream response
  UpstreamHelpers.mock_upstream_package_response(package_name)
  UpstreamHelpers.track_http_requests()

  # First request - hits upstream
  {:ok, _package1} = Packages.get_package(package_name)
  first_count = UpstreamHelpers.get_request_count()

  # Second request - should use cache
  {:ok, _package2} = Packages.get_package(package_name)
  second_count = UpstreamHelpers.get_request_count()

  # Verify cache behavior
  assert second_count == first_count  # No additional requests
end
```

## Debugging Tests

### Enable Verbose Logging
```bash
# Run with verbose output
mix test --trace

# Run with specific test and verbose output
mix test test/hex_hub/upstream_mock_test.exs --trace
```

### Check Mock Calls
```elixir
# In your test, you can inspect what was called
uploaded = UpstreamHelpers.get_storage_uploaded()
request_count = UpstreamHelpers.get_request_count()
```

### Inspect Process State
```elixir
# Check what's stored in process dictionary
Process.get(:upstream_mock_response)
Process.get(:storage_content)
```

## CI/CD Considerations

### For CI/CD pipelines, use mock-based tests:
```yaml
- name: Run Upstream Tests
  run: mix test --only upstream_mock
```

### For manual testing with real upstream:
```bash
# Set environment variable for real integration tests
export HEX_HUB_INTEGRATION_TESTS=true
mix test --only integration
```

## Troubleshooting

### Common Issues

1. **Mock not working**: Ensure you have `setup :set_mox_global` and `setup :verify_on_exit!`
2. **Tests timing out**: Increase timeout in mock responses
3. **Telemetry not firing**: Ensure telemetry is attached before making requests
4. **Storage mocks not working**: Check that `:meck.expect` is properly set up

### Debug Tips

- Use `IO.inspect/1` to check mock responses
- Check process dictionary with `Process.get/1`
- Verify mock setup with `:meck.history(HexHub.Upstream)`
- Use `mix test --trace` for detailed test output

## Adding New Tests

When adding new upstream functionality:

1. Add unit tests in `upstream_mock_test.exs`
2. Add integration tests in `upstream_integration_test.exs`
3. Add API tests in `upstream_download_controller_test.exs`
4. Add helpers to `upstream_test_helpers.exs` if needed
5. Update this README with new test patterns

Remember to:
- Test both success and failure scenarios
- Test edge cases (empty responses, malformed data)
- Test configuration changes
- Test caching behavior
- Add telemetry verification where appropriate
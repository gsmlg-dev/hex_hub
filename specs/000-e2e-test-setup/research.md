# Research: E2E Test Infrastructure

**Feature**: 001-e2e-test-setup
**Date**: 2025-11-26

## Research Topics

### 1. Mix Custom Task for Isolated Test Execution

**Decision**: Create `Mix.Tasks.Test.E2e` task that runs ExUnit with `e2e_test/` directory

**Rationale**:
- Mix tasks are the idiomatic way to extend Mix functionality in Elixir
- The task can configure ExUnit to use a separate test directory
- Allows passing standard ExUnit options (--trace, --seed, etc.)

**Alternatives Considered**:
- Shell script wrapper: Less idiomatic, harder to integrate with Mix ecosystem
- ExUnit tags: Would require running from `test/` directory, mixing concerns
- Separate Mix project: Overly complex for this use case

**Implementation Pattern**:
```elixir
defmodule Mix.Tasks.Test.E2e do
  use Mix.Task

  @shortdoc "Runs E2E tests from e2e_test directory"

  def run(args) do
    # Compile e2e_test support files
    # Start ExUnit with e2e_test directory
    # Run tests with provided args
  end
end
```

### 2. Dynamic Port Allocation for Phoenix Server

**Decision**: Use `:ranch.start_listener` with port 0 to get OS-assigned port, or use `Bandit` with `port: 0`

**Rationale**:
- Port 0 tells the OS to assign an available ephemeral port
- Phoenix/Bandit supports this via configuration
- Avoids port conflicts in parallel CI runs

**Alternatives Considered**:
- Fixed port with retry logic: More complex, still potential for conflicts
- Port range scanning: Unnecessary when OS can assign ports

**Implementation Pattern**:
```elixir
# Start endpoint with dynamic port
config = [
  http: [port: 0],
  server: true
]
{:ok, _} = HexHubWeb.Endpoint.start_link(config)

# Get assigned port
{:ok, port} = HexHubWeb.Endpoint.config(:http) |> Keyword.fetch(:port)
# Or use :ranch to query the actual port
```

### 3. Hex Mirror Configuration for Tests

**Decision**: Use `HEX_MIRROR` environment variable pointing to local HexHub instance

**Rationale**:
- Standard hex configuration method
- Works with `mix deps.get` without code changes
- Matches production use case (how users would configure their systems)

**Alternatives Considered**:
- Direct HTTP calls: Doesn't test real hex client behavior
- Mock hex client: Too artificial, doesn't validate actual compatibility

**Implementation Pattern**:
```elixir
# Set environment for test subprocess
System.put_env("HEX_MIRROR", "http://localhost:#{port}")
System.put_env("HEX_UNSAFE_REGISTRY", "1")  # For self-signed/local

# Run mix deps.get in test project
{output, exit_code} = System.cmd("mix", ["deps.get"],
  cd: test_project_path,
  env: [{"HEX_MIRROR", url}]
)
```

### 4. Test Project for Package Fetching

**Decision**: Create minimal Mix project fixture in `e2e_test/fixtures/` with dependency on `jason`

**Rationale**:
- Realistic test of actual Mix/Hex workflow
- `jason` is small, stable, widely used
- Fixture project can be version-controlled

**Alternatives Considered**:
- Dynamic project generation: More complex, harder to debug
- HTTP calls to tarball endpoints: Doesn't test hex client integration

**Implementation Pattern**:
```text
e2e_test/fixtures/test_project/
├── mix.exs           # deps: [{:jason, "~> 1.4"}]
├── mix.lock          # Empty initially, populated during test
└── lib/
    └── test_project.ex
```

### 5. Server Lifecycle Management in Tests

**Decision**: Start server in test setup, stop in teardown, use `on_exit` callback

**Rationale**:
- ExUnit's `on_exit` ensures cleanup even on test failure
- Single server per test module avoids port exhaustion
- Clear lifecycle management

**Alternatives Considered**:
- Shared server across all tests: Potential state leakage
- Server per test: Too slow, too many ports

**Implementation Pattern**:
```elixir
setup_all do
  {:ok, port} = E2E.ServerHelper.start_server()

  on_exit(fn ->
    E2E.ServerHelper.stop_server()
  end)

  {:ok, port: port, base_url: "http://localhost:#{port}"}
end
```

### 6. GitHub Actions Workflow Configuration

**Decision**: Separate workflow file `.github/workflows/e2e.yml` with triggers on PRs to main/develop and pushes to main

**Rationale**:
- Separate workflow allows independent failure tracking
- Matches clarified requirements from spec
- Can have different caching/timeout strategies than unit tests

**Alternatives Considered**:
- Add to existing ci.yml: Would couple E2E with unit tests
- Matrix strategy: Overkill for single E2E test type

**Implementation Pattern**:
```yaml
name: E2E Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main, develop]

jobs:
  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: erlef/setup-beam@v1
      - run: mix deps.get
      - run: mix test.e2e
```

### 7. Mnesia Isolation for E2E Tests

**Decision**: Use fresh Mnesia directory per E2E test run, similar to existing test setup

**Rationale**:
- Prevents state pollution between runs
- Follows existing pattern in `test/test_helper.exs`
- Ensures predictable test behavior

**Implementation Pattern**:
```elixir
# In e2e_test/test_helper.exs
:mnesia.stop()
File.rm_rf!("Mnesia.e2e_test_#{System.unique_integer()}")
:mnesia.create_schema([node()])
:mnesia.start()
HexHub.Mnesia.init()
```

## Dependencies

No new dependencies required. Uses existing:
- ExUnit (built-in)
- Mix (built-in)
- Phoenix (existing)
- Bandit (existing)

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Port conflicts in CI | Low | Medium | Use port 0 for OS assignment |
| hex.pm unreachable | Medium | High | Document as network test; skip if offline |
| Server startup timeout | Low | Medium | Configurable timeout with 60s default |
| Mnesia initialization race | Low | Medium | Synchronous init before test start |

## Summary

All technical questions resolved. No NEEDS CLARIFICATION remaining. Ready for Phase 1 design artifacts.

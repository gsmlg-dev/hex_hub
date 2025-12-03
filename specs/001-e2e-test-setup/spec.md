# Feature Specification: E2E Test Infrastructure for Hex Package Proxy

**Feature Branch**: `001-e2e-test-setup`
**Created**: 2025-11-25
**Status**: Draft
**Input**: User description: "Create e2e test for this project, we can run mix test.e2e, this must be a separate definition at e2e_test. We also need a github action to run this e2e test. This e2e test need to start service mix phx.server on a random port and set hex mirror to the service, then run mix deps.get to fetch packages proxy from hex.pm, make sure this process works."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Developer Validates Hex Proxy Functionality (Priority: P1)

As a developer maintaining HexHub, I want to run end-to-end tests that verify the complete package proxy workflow, so I can ensure that clients can successfully fetch packages through HexHub as a hex.pm mirror.

**Why this priority**: This is the core purpose of E2E testing - validating that the primary business function (proxying hex packages) works correctly in a realistic environment.

**Independent Test**: Can be fully tested by running `mix test.e2e` and observing that packages are successfully fetched through the local HexHub instance.

**Acceptance Scenarios**:

1. **Given** the E2E test infrastructure is configured, **When** a developer runs `mix test.e2e`, **Then** the HexHub server starts on an available port, configures hex to use it as a mirror, fetches a test package, and reports success or failure.

2. **Given** the HexHub server is running as a proxy, **When** the test requests a package from hex.pm through HexHub, **Then** the package is successfully downloaded and verified.

3. **Given** the E2E test completes, **When** the test process exits, **Then** the HexHub server is properly shut down and all temporary resources are cleaned up.

---

### User Story 2 - CI Pipeline Runs E2E Tests Automatically (Priority: P2)

As a developer contributing to HexHub, I want E2E tests to run automatically in the CI pipeline, so I can catch integration issues before merging code changes.

**Why this priority**: Automated testing in CI ensures consistent quality validation across all contributions and prevents regressions.

**Independent Test**: Can be tested by triggering a GitHub Actions workflow and verifying that E2E tests execute and report results correctly.

**Acceptance Scenarios**:

1. **Given** a pull request is opened or updated, **When** the CI pipeline runs, **Then** the E2E test workflow executes and reports pass/fail status.

2. **Given** the E2E tests fail in CI, **When** reviewing the workflow results, **Then** the failure reason and relevant logs are clearly visible.

3. **Given** the E2E tests pass in CI, **When** the workflow completes, **Then** the PR shows a green checkmark for the E2E test job.

---

### User Story 3 - Developer Runs E2E Tests Locally (Priority: P3)

As a developer working on HexHub locally, I want to easily run E2E tests in isolation from unit tests, so I can quickly validate proxy functionality during development.

**Why this priority**: Local development workflow support enables faster iteration and debugging.

**Independent Test**: Can be tested by running `mix test.e2e` in a local development environment and verifying the tests execute separately from regular unit tests.

**Acceptance Scenarios**:

1. **Given** a developer has the project cloned, **When** they run `mix test.e2e`, **Then** only E2E tests execute (not unit tests).

2. **Given** regular unit tests exist, **When** a developer runs `mix test`, **Then** E2E tests do not execute (they remain isolated).

---

### Edge Cases

- What happens when the randomly selected port is already in use?
  - System should retry with a different port or report a clear error.

- What happens when hex.pm is unreachable during E2E tests?
  - Tests should fail gracefully with a clear timeout error and diagnostic message.

- What happens when the HexHub server fails to start?
  - Tests should report the startup failure clearly rather than hanging indefinitely.

- What happens when running tests in parallel?
  - Each test run should use its own isolated port and configuration to avoid conflicts.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a separate test directory (`e2e_test/`) for E2E test files, isolated from unit tests in `test/`.

- **FR-002**: System MUST provide a command (`mix test.e2e`) to run only E2E tests without running unit tests.

- **FR-003**: E2E tests MUST start the HexHub server on a dynamically assigned available port before test execution.

- **FR-004**: E2E tests MUST configure the hex client to use the local HexHub instance as its package mirror.

- **FR-005**: E2E tests MUST validate that packages can be fetched through HexHub proxying from hex.pm, using small, stable test packages (e.g., `jason`, `decimal`) for fast, reliable validation.

- **FR-006**: E2E tests MUST clean up all resources (server process, temporary files, port bindings) after test completion.

- **FR-007**: System MUST include a GitHub Actions workflow that runs E2E tests on pull requests targeting main/develop branches and on pushes to main.

- **FR-008**: The E2E test timeout MUST be configurable, with a reasonable default (60 seconds per test scenario).

- **FR-009**: E2E test failures MUST produce clear, actionable error messages indicating what failed and why.

- **FR-010**: Running `mix test` MUST NOT execute E2E tests (they should remain separate).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Developers can run E2E tests with a single command (`mix test.e2e`) that completes within 5 minutes for the basic proxy validation test.

- **SC-002**: E2E tests successfully validate the package proxy workflow 100% of the time when hex.pm is reachable.

- **SC-003**: CI pipeline executes E2E tests on every pull request, with results visible within 10 minutes of triggering.

- **SC-004**: Test isolation is complete - running `mix test` executes 0 E2E tests, and `mix test.e2e` executes 0 unit tests.

- **SC-005**: Failed E2E tests provide diagnostic output that enables developers to identify the root cause without additional debugging in 90% of failure cases.

## Clarifications

### Session 2025-11-26

- Q: Which package(s) should E2E tests use for validation? → A: Small, stable packages like `jason` or `decimal` (well-maintained, fast download)
- Q: Which branches should trigger E2E tests in CI? → A: PRs to main/develop + pushes to main only

## Assumptions

- hex.pm is available and accessible during E2E test execution (network dependency is acceptable for integration tests).
- The development environment has sufficient permissions to bind to random high ports.
- GitHub Actions runners have network access to hex.pm for E2E test execution.
- Test packages fetched are small enough that tests complete within reasonable timeframes.
- If HexHub has bugs preventing E2E tests from passing, those bugs will be addressed in separate tasks; this specification covers only the test infrastructure creation.

## Out of Scope

- Fixing existing HexHub bugs that may cause E2E tests to fail (will be separate tasks).
- Performance benchmarking or load testing of the proxy functionality.
- Testing against multiple concurrent clients or high-volume scenarios.
- Testing private repository authentication flows (focus is on public hex.pm proxy).

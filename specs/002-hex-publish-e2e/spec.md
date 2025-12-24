# Feature Specification: E2E Test Suite for hex.publish

**Feature Branch**: `002-hex-publish-e2e`
**Created**: 2025-12-23
**Status**: Draft
**Input**: User description: "add e2e test case suite of hex.publish, research for the hex.publish action, here is what is need to run success to publish package: HEX_API_URL=http://localhost:4000/api mix hex.publish --yes"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Basic Package Publishing (Priority: P1)

As a package maintainer, I want to verify that I can publish a new package to HexHub using the standard `mix hex.publish` command, so that I can confirm HexHub is a fully compatible drop-in replacement for hex.pm.

**Why this priority**: This is the core functionality - if package publishing doesn't work, HexHub cannot serve as a private package registry. This is the most critical path that must work for HexHub to be useful.

**Independent Test**: Can be fully tested by running `HEX_API_URL=http://localhost:4000/api mix hex.publish --yes` against a running HexHub instance with a valid test project and API key, and verifying the package appears in the registry.

**Acceptance Scenarios**:

1. **Given** a valid Elixir project with proper mix.exs configuration (name, version, description), **When** the maintainer runs `HEX_API_URL=http://localhost:4000/api mix hex.publish --yes`, **Then** the package is successfully published and returns a success response
2. **Given** a published package, **When** querying the package metadata via `/api/packages/:name`, **Then** the package information is returned with correct version and metadata
3. **Given** a published package, **When** downloading the tarball via `/api/packages/:name/releases/:version/download`, **Then** the package tarball is retrieved successfully

---

### User Story 2 - Authentication and API Key Validation (Priority: P1)

As a package maintainer, I want the publishing process to require valid API key authentication, so that only authorized users can publish packages.

**Why this priority**: Security is fundamental - publishing without proper authentication would allow anyone to publish packages under any name, which is a critical security flaw.

**Independent Test**: Can be tested by attempting to publish with invalid/missing API keys and verifying appropriate error responses.

**Acceptance Scenarios**:

1. **Given** a valid project but no API key configured, **When** the maintainer runs `mix hex.publish --yes`, **Then** the publish fails with an authentication error (401 Unauthorized)
2. **Given** a valid project with an invalid API key, **When** the maintainer runs `mix hex.publish --yes`, **Then** the publish fails with an authentication error (401 Unauthorized)
3. **Given** a valid project with a read-only API key (no write permission), **When** the maintainer runs `mix hex.publish --yes`, **Then** the publish fails with a permission error (403 Forbidden)
4. **Given** a valid project with a write-enabled API key, **When** the maintainer runs `mix hex.publish --yes`, **Then** the publish succeeds

---

### User Story 3 - Package Version Management (Priority: P2)

As a package maintainer, I want to publish multiple versions of the same package and manage them, so that I can release updates and handle version lifecycle.

**Why this priority**: After basic publishing works, version management is the next most common operation package maintainers need.

**Independent Test**: Can be tested by publishing v0.1.0, then v0.2.0 of the same package and verifying both versions are accessible.

**Acceptance Scenarios**:

1. **Given** a package with version 0.1.0 already published, **When** the maintainer publishes version 0.2.0, **Then** both versions are available and the release list shows both versions
2. **Given** a package with multiple versions, **When** querying `/api/packages/:name`, **Then** the response includes all published versions
3. **Given** a freshly published version (within allowed window), **When** the maintainer attempts to replace it, **Then** the replacement succeeds

---

### User Story 4 - Documentation Publishing (Priority: P3)

As a package maintainer, I want to publish documentation along with my package, so that users can access docs via HexHub.

**Why this priority**: Documentation is important for package usability but is secondary to core publishing functionality.

**Independent Test**: Can be tested by publishing a package with docs using `mix hex.publish` and verifying docs are accessible.

**Acceptance Scenarios**:

1. **Given** a valid project with ExDoc configured, **When** the maintainer runs `mix hex.publish --yes`, **Then** both package and documentation are published
2. **Given** a published package with docs, **When** accessing `/api/packages/:name/releases/:version/docs/download`, **Then** the documentation tarball is retrieved
3. **Given** a published package, **When** the maintainer runs `mix hex.publish docs`, **Then** only documentation is updated without changing the package

---

### User Story 5 - Error Handling and Validation (Priority: P2)

As a package maintainer, I want clear error messages when publishing fails, so that I can understand and fix issues.

**Why this priority**: Good error handling improves developer experience and reduces support burden.

**Independent Test**: Can be tested by attempting to publish with various invalid configurations and verifying appropriate error messages.

**Acceptance Scenarios**:

1. **Given** a project with missing required fields (no version), **When** the maintainer runs `mix hex.publish --yes`, **Then** a clear validation error is returned
2. **Given** a project with invalid version format, **When** the maintainer runs `mix hex.publish --yes`, **Then** a clear validation error about version format is returned
3. **Given** a package that exceeds size limits, **When** the maintainer runs `mix hex.publish --yes`, **Then** a clear error about size limits is returned

---

### Edge Cases

- What happens when publishing a package name that already exists (owned by another user)?
- How does the system handle concurrent publish attempts for the same package version?
- What happens when the tarball is corrupted or malformed?
- How does the system handle packages with special characters in metadata fields?
- What happens when network connection is interrupted during upload?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: E2E test suite MUST start a local HexHub server instance on a dynamic port
- **FR-002**: E2E test suite MUST create and configure test API keys with appropriate permissions
- **FR-003**: E2E test suite MUST include a valid test project fixture with proper mix.exs configuration
- **FR-004**: E2E test suite MUST configure the hex client to use the local HexHub instance via `HEX_API_URL` environment variable
- **FR-005**: E2E test suite MUST verify successful package publishing via `mix hex.publish --yes`
- **FR-006**: E2E test suite MUST verify published packages are retrievable via the API
- **FR-007**: E2E test suite MUST verify authentication is required for publishing
- **FR-008**: E2E test suite MUST verify API key permissions are enforced (write permission required)
- **FR-009**: E2E test suite MUST clean up test data between test runs to ensure isolation
- **FR-010**: E2E test suite MUST run independently from unit tests via `mix test.e2e`

### Key Entities

- **Test Project Fixture**: A minimal Elixir project with valid mix.exs containing name, version, description, and optional dependencies for publishing tests
- **Test API Key**: An API key created for testing with configurable read/write permissions
- **E2E Test Case Module**: Base test case module extending the existing `E2E.Case` infrastructure with publish-specific helpers

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: E2E tests for `mix hex.publish` complete successfully within 60 seconds per test case
- **SC-002**: Test coverage includes at least 5 distinct publishing scenarios (basic publish, auth required, version management, error cases, permission checks)
- **SC-003**: All E2E tests pass consistently on 3 consecutive runs (no flaky tests)
- **SC-004**: Test failures provide clear, actionable error messages indicating the specific failure point
- **SC-005**: E2E test suite can be run in isolation without affecting existing unit tests or other E2E tests

## Assumptions

- The existing E2E test infrastructure (`mix test.e2e`, `E2E.Case`, `E2E.ServerHelper`) will be extended rather than replaced
- The `mix hex.publish` command from the official Hex package is available in the test environment
- Test API keys can be generated programmatically during test setup
- The test fixture project will be a minimal but valid Elixir project (not a real publishable package)
- Package size limits follow hex.pm standards (8MB compressed, 64MB uncompressed)

## Scope Boundaries

### In Scope

- E2E tests for `mix hex.publish --yes` command
- E2E tests for package publishing with API key authentication
- E2E tests for basic error cases and validation
- Test fixture project creation and management
- Integration with existing E2E test infrastructure

### Out of Scope

- E2E tests for `mix hex.publish` interactive mode (prompts)
- E2E tests for organization/private repository publishing
- E2E tests for package retirement/reversion workflows
- E2E tests for ownership transfer
- Performance/load testing for publishing

# Feature Specification: Telemetry-Based Logging System

**Feature Branch**: `001-telemetry-logging`
**Created**: 2025-12-22
**Status**: Draft
**Input**: User description: "please update log system, use telemetry instead of Logger, support attach telemetry to use Logger print to console and write to files"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Console Logging via Telemetry (Priority: P1)

As an operator running the HexHub application, I want all application events to be emitted through the telemetry system and displayed in the console, so that I can monitor the application's behavior in real-time without changing any code when I want to adjust logging output.

**Why this priority**: Console logging is the most fundamental observability need. Without it, operators cannot see what the application is doing. This is the MVP for the telemetry-based logging system.

**Independent Test**: Can be fully tested by starting the application and verifying that operational events (package publishes, upstream requests, authentication events) appear in the console with proper formatting.

**Acceptance Scenarios**:

1. **Given** the application is running with default configuration, **When** a package is published, **Then** a log entry appears in the console with timestamp, log level, and event details.
2. **Given** the application is running, **When** an upstream request is made, **Then** the request details and duration are logged to the console.
3. **Given** the application is running, **When** an authentication failure occurs, **Then** a warning-level log entry appears in the console with relevant details (without exposing sensitive data).
4. **Given** the telemetry handler is attached, **When** any operational event is emitted via telemetry, **Then** it is formatted and printed to the console using the standard logging interface.

---

### User Story 2 - File-Based Logging via Telemetry (Priority: P2)

As an operator, I want to configure the system to write logs to files, so that I can retain historical logs for debugging, auditing, and compliance purposes.

**Why this priority**: File logging is essential for production deployments where logs need to be persisted and analyzed later. It builds on the console logging foundation.

**Independent Test**: Can be tested by configuring file logging, generating events, and verifying log files are created with the expected content.

**Acceptance Scenarios**:

1. **Given** file logging is enabled via configuration, **When** operational events occur, **Then** log entries are written to the configured log file.
2. **Given** file logging is configured with a specific path, **When** the application starts, **Then** the log file is created (or appended to) at that path.
3. **Given** file logging is enabled, **When** multiple events occur rapidly, **Then** all events are written to the file without loss or corruption.
4. **Given** both console and file logging are enabled, **When** an event occurs, **Then** it appears in both the console and the log file.

---

### User Story 3 - Configurable Log Levels (Priority: P3)

As an operator, I want to configure which log levels are output to each destination (console and file), so that I can reduce noise in production while retaining detailed logs for debugging.

**Why this priority**: Log level filtering is important for production operations but the system is functional without it. Operators can always filter logs post-facto.

**Independent Test**: Can be tested by setting different log levels for console and file, generating events at various levels, and verifying only appropriate events appear in each destination.

**Acceptance Scenarios**:

1. **Given** console log level is set to "info", **When** a debug-level event occurs, **Then** it does NOT appear in the console.
2. **Given** file log level is set to "debug", **When** a debug-level event occurs, **Then** it IS written to the log file.
3. **Given** different log levels for console and file, **When** an info-level event occurs, **Then** it appears in both destinations (assuming both allow info level).
4. **Given** log level configuration is changed, **When** the application is restarted, **Then** the new log levels take effect.

---

### Edge Cases

- What happens when the log file path is not writable? System should fall back gracefully and report the error.
- What happens when disk space runs out during file logging? System should handle gracefully without crashing.
- What happens when a telemetry event contains nil or invalid data? System should log safely without raising exceptions.
- What happens when events are emitted before handlers are attached? Events should not cause errors; they are simply not logged.
- What happens when the same handler is attached multiple times? System should prevent duplicate handlers or handle gracefully.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST emit all operational events (package operations, authentication, upstream requests, storage operations, user actions) through the telemetry system rather than direct logging calls.
- **FR-002**: System MUST provide a default telemetry handler that outputs events to the console using the standard logging interface.
- **FR-003**: System MUST support an optional file-based telemetry handler that writes events to a configured file path.
- **FR-004**: System MUST allow handlers to be enabled/disabled via configuration without code changes.
- **FR-005**: System MUST support configurable log levels (debug, info, warning, error) for each output destination independently.
- **FR-006**: System MUST format log entries as structured JSON containing timestamp, log level, event name, and relevant metadata (e.g., `{"ts": "...", "level": "info", "event": "...", "meta": {...}}`).
- **FR-007**: System MUST NOT expose sensitive information (passwords, API keys, tokens) in log output.
- **FR-008**: System MUST handle handler failures gracefully without crashing the application.
- **FR-009**: System MUST allow both console and file handlers to be active simultaneously.
- **FR-010**: System MUST ensure existing telemetry metrics functionality continues to work alongside the new logging handlers.

### Key Entities

- **Telemetry Event**: An occurrence in the system with a name (list of atoms), measurements (numeric values), and metadata (contextual information).
- **Telemetry Handler**: A component that receives telemetry events and routes them to an output destination (console, file, external system).
- **Log Entry**: A formatted representation of a telemetry event containing timestamp, level, message, and metadata.
- **Handler Configuration**: Settings that control which handlers are active, their output destinations, and filtering rules (log levels).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of operational events in the application are emitted via telemetry rather than direct logging calls.
- **SC-002**: Console logging displays events within 100ms of occurrence under normal load.
- **SC-003**: File logging writes events with no more than 1 second delay under normal load.
- **SC-004**: Operators can enable/disable each logging destination without modifying code.
- **SC-005**: Log entries include all necessary context for debugging (event name, timestamp, relevant identifiers).
- **SC-006**: No sensitive data (passwords, tokens, keys) appears in log output.
- **SC-007**: System continues operating normally if a logging handler fails (no application crashes due to logging issues).
- **SC-008**: Existing telemetry metrics (LiveDashboard, Prometheus exports) continue working without modification.

## Clarifications

### Session 2025-12-23

- Q: What log entry format structure should be used? → A: Structured JSON (e.g., `{"ts": "...", "level": "info", "event": "...", "meta": {...}}`)

## Assumptions

- The application already has telemetry infrastructure in place (`lib/hex_hub/telemetry.ex`).
- Operators have access to environment variables or configuration files to set logging options.
- File system access is available for file-based logging in production environments.
- The standard logging interface is acceptable for console output formatting.
- Log rotation and retention policies are handled externally (logrotate, container logging, etc.) - not part of this feature.

# Feature Specification: Anonymous Publish Configuration

**Feature Branch**: `006-anonymous-publish-config`
**Created**: 2025-12-28
**Status**: Draft
**Input**: User description: "Add a config dialog with option to the admin user page, allow disable publish package without auth token to any publish, the publish user should be a specify user anonymous"

## Clarifications

### Session 2025-12-28

- Q: Should the system apply rate limiting or abuse prevention for anonymous publishing? → A: No rate limiting - accept all anonymous publishes without restriction.
- Q: Should anonymous package publishes be logged with additional tracking information? → A: Log IP address and timestamp for each anonymous publish.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Configure Anonymous Publishing (Priority: P1) 🎯 MVP

An administrator wants to control whether packages can be published without authentication. When anonymous publishing is enabled, any user can publish packages without providing an API key, and the published packages are attributed to a designated "anonymous" user. When disabled (default), all publish requests require a valid API key.

**Why this priority**: This is the core feature that enables or disables anonymous publishing. Without this configuration, the feature cannot function.

**Independent Test**: Navigate to admin settings page, toggle the anonymous publish setting, and verify the configuration is saved and reflected in the system behavior.

**Acceptance Scenarios**:

1. **Given** an administrator is on the admin settings page, **When** they toggle "Allow Anonymous Publishing" to enabled and save, **Then** the setting is persisted and anonymous publishing becomes available.

2. **Given** an administrator is on the admin settings page, **When** they toggle "Allow Anonymous Publishing" to disabled and save, **Then** the setting is persisted and all publish requests require authentication.

3. **Given** the admin settings page is loaded, **When** the administrator views the anonymous publishing section, **Then** they see the current state of the setting (enabled/disabled) and a clear description of what it does.

---

### User Story 2 - Publish Package Anonymously (Priority: P2)

When anonymous publishing is enabled, a user can publish a package without providing an API key. The package is attributed to a system-defined "anonymous" user, allowing package tracking while not requiring user registration.

**Why this priority**: This is the functional outcome of enabling anonymous publishing. It depends on US1 being complete.

**Independent Test**: With anonymous publishing enabled, submit a package without authentication and verify it appears in the package list attributed to the "anonymous" user.

**Acceptance Scenarios**:

1. **Given** anonymous publishing is enabled, **When** a user publishes a package without an API key, **Then** the package is accepted and attributed to the "anonymous" user.

2. **Given** anonymous publishing is enabled, **When** a user publishes a package without an API key, **Then** the package appears in the package list with "anonymous" as the publisher.

3. **Given** anonymous publishing is disabled (default), **When** a user attempts to publish a package without an API key, **Then** the request is rejected with an authentication error.

---

### User Story 3 - View Anonymous User in Admin (Priority: P3)

Administrators can view the "anonymous" user in the admin users page. This user is a system user that cannot be deleted or modified but can be viewed to see all packages published anonymously.

**Why this priority**: This provides visibility into anonymous publishing activity but is not required for the core functionality.

**Independent Test**: Navigate to admin users page and verify the "anonymous" user appears with appropriate indicators that it is a system user.

**Acceptance Scenarios**:

1. **Given** the admin users page is loaded, **When** the administrator views the user list, **Then** the "anonymous" user appears with a visual indicator that it is a system user.

2. **Given** the administrator views the "anonymous" user details, **When** they attempt to edit or delete the user, **Then** the system prevents these actions with an appropriate message.

3. **Given** the administrator views the "anonymous" user details, **When** they view the user's packages, **Then** they see all packages published anonymously.

---

### Edge Cases

- What happens when anonymous publishing is toggled while a publish is in progress?
  - The system should use the setting value at the time the publish request was received.

- What happens if the "anonymous" user is somehow deleted or corrupted?
  - The system should automatically recreate the "anonymous" user on startup if it doesn't exist.

- What happens when viewing packages published before anonymous publishing was enabled?
  - All packages retain their original publisher attribution; only new anonymous publishes use the "anonymous" user.

- What happens if someone tries to register a user named "anonymous"?
  - The system should prevent registration with reserved usernames including "anonymous".

- What about abuse prevention when anonymous publishing is enabled?
  - No rate limiting is applied; the system accepts all anonymous publishes without restriction. Administrators should disable anonymous publishing if abuse occurs.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide an admin settings page with a toggle for "Allow Anonymous Publishing"
- **FR-002**: System MUST persist the anonymous publishing setting across restarts
- **FR-003**: System MUST default anonymous publishing to disabled (requiring authentication)
- **FR-004**: System MUST create a system user "anonymous" on first startup if it doesn't exist
- **FR-005**: System MUST attribute all unauthenticated package publishes to the "anonymous" user when anonymous publishing is enabled
- **FR-006**: System MUST reject unauthenticated package publish requests when anonymous publishing is disabled
- **FR-007**: System MUST display the "anonymous" user in the admin users list with a visual indicator (e.g., badge or icon) marking it as a system user
- **FR-008**: System MUST prevent deletion or modification of the "anonymous" system user
- **FR-009**: System MUST prevent user registration with reserved usernames including "anonymous"
- **FR-010**: System MUST display a confirmation dialog when changing the anonymous publishing setting
- **FR-011**: System MUST log IP address and timestamp for each anonymous package publish for audit purposes

### Key Entities

- **Anonymous Publishing Setting**: A system configuration that controls whether packages can be published without authentication. Has a single boolean value (enabled/disabled).

- **Anonymous User**: A system-created user account with username "anonymous" that serves as the publisher for all packages submitted without authentication. Cannot be modified or deleted. Has relationships to packages (as publisher/owner).

- **System User Indicator**: A visual marker distinguishing system-created users (like "anonymous") from regular users in admin interfaces.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Administrators can toggle anonymous publishing setting in under 30 seconds
- **SC-002**: Anonymous package publishing works within 1 second of enabling the setting (no restart required)
- **SC-003**: 100% of unauthenticated publish requests are correctly handled based on the current setting
- **SC-004**: The "anonymous" user is visible and clearly marked in admin user lists
- **SC-005**: All packages published anonymously are correctly attributed and traceable to the "anonymous" user

## Assumptions

- The admin settings page already exists or will be created as part of this feature
- The package publishing flow already handles authentication and can be extended to check the anonymous publishing setting
- The "anonymous" user follows the same user model as regular users but with system-level protections
- The setting change takes effect immediately without requiring a server restart

# Feature Specification: Admin Package Management

**Feature Branch**: `005-admin-package-management`
**Created**: 2025-12-28
**Status**: Draft
**Input**: User description: "in the admin pages, it should have cached packages (fetch from remote), packages (local publish), if they have same name, use local published package first"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - View Locally Published Packages (Priority: P1)

As an administrator, I want to view all packages that have been published locally to my HexHub instance so that I can manage and monitor packages created by my organization.

**Why this priority**: Local packages are the primary content managed by the private hex server. Administrators need visibility into what has been published locally as this is the core function of a private package manager.

**Independent Test**: Can be fully tested by navigating to the admin packages page and verifying local packages are displayed with their metadata. Delivers immediate value by giving administrators visibility into local package inventory.

**Acceptance Scenarios**:

1. **Given** an administrator is logged into the admin dashboard, **When** they navigate to the "Local Packages" section, **Then** they see a list of all locally published packages with name, latest version, publisher, and publish date.
2. **Given** multiple versions of a local package exist, **When** viewing the package list, **Then** the administrator sees the most recent version displayed with an option to view version history.
3. **Given** no local packages have been published, **When** viewing the "Local Packages" section, **Then** the administrator sees an empty state message indicating no local packages exist.

---

### User Story 2 - View Cached Remote Packages (Priority: P2)

As an administrator, I want to view all packages that have been cached from the upstream repository (hex.pm) so that I can understand what external packages are being used by my organization.

**Why this priority**: Cached packages represent dependencies fetched from upstream. Understanding what external packages are in use helps administrators manage dependencies, plan for offline scenarios, and monitor usage patterns.

**Independent Test**: Can be fully tested by having packages fetched from upstream, then navigating to the cached packages view and verifying they appear correctly. Delivers value by providing visibility into external dependency usage.

**Acceptance Scenarios**:

1. **Given** packages have been fetched from the upstream repository, **When** the administrator navigates to the "Cached Packages" section, **Then** they see a list of all cached packages with name, cached version, source repository, and cache date.
2. **Given** a cached package has multiple versions cached, **When** viewing the cached package list, **Then** the administrator sees all cached versions with their respective cache dates.
3. **Given** no packages have been cached from upstream, **When** viewing the "Cached Packages" section, **Then** the administrator sees an empty state message indicating no cached packages exist.

---

### User Story 3 - Unified Package Search with Priority (Priority: P3)

As an administrator, I want to search across all packages (both local and cached) and understand package resolution priority so that I can quickly find packages and understand which version will be served to clients.

**Why this priority**: A unified view with priority indication helps administrators understand the effective package resolution behavior. This is essential for troubleshooting and ensuring local packages take precedence when names conflict.

**Independent Test**: Can be fully tested by having both a local and cached package with the same name, then searching for that package name and verifying the priority indicator shows local takes precedence. Delivers value by clarifying resolution behavior.

**Acceptance Scenarios**:

1. **Given** both local and cached packages exist with the same name, **When** the administrator views the unified package list, **Then** the local package is displayed with a "Local (Active)" indicator and the cached package shows "Cached (Shadowed)" or similar indication.
2. **Given** a package exists only in the cache (not locally published), **When** viewing the unified list, **Then** it shows as "Cached (Active)" indicating it will be served to clients.
3. **Given** the administrator searches for a package name that exists in both sources, **When** search results are displayed, **Then** both versions appear with clear priority indicators showing which one will be served.

---

### User Story 4 - Manage Cached Package Lifecycle (Priority: P4)

As an administrator, I want to delete specific cached packages or clear the entire cache so that I can manage storage space and remove outdated or unwanted cached dependencies.

**Why this priority**: Cache management is important for long-term operation but is not critical for initial functionality. Administrators need this capability to manage disk space and ensure cached packages can be refreshed when needed.

**Independent Test**: Can be fully tested by caching a package from upstream, then deleting it from the admin interface and verifying it is removed. Delivers value by giving administrators control over cache storage.

**Acceptance Scenarios**:

1. **Given** a cached package exists, **When** the administrator selects "Delete" for that package, **Then** they are prompted to confirm and upon confirmation the package is removed from the cache.
2. **Given** multiple cached packages exist, **When** the administrator selects "Clear All Cache", **Then** they are prompted to confirm and upon confirmation all cached packages are removed.
3. **Given** a cached package is deleted, **When** a client requests that package, **Then** it is re-fetched from upstream (if upstream is enabled and available).

---

### Edge Cases

- What happens when a local package and cached package have the same name but different versions? The local package versions take precedence; cached versions of that package are not served but remain visible in admin for reference.
- How does the system handle when upstream is disabled and a user requests a non-local package? The system returns a "package not found" error; cached packages remain available.
- What happens when an administrator deletes a local package that shadows a cached package? The cached package becomes active and will be served to clients.
- How does the system handle very large package caches (1000+ packages)? The admin interface uses pagination to display packages efficiently.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST display a dedicated "Local Packages" view in the admin dashboard showing all packages published directly to this HexHub instance.
- **FR-002**: System MUST display a dedicated "Cached Packages" view in the admin dashboard showing all packages fetched from upstream repositories.
- **FR-003**: System MUST indicate package source (local vs cached) in all admin package views.
- **FR-004**: System MUST show priority/resolution status for packages with conflicting names (local takes precedence, cached is shadowed).
- **FR-005**: System MUST allow administrators to delete individual cached packages.
- **FR-006**: System MUST allow administrators to clear all cached packages at once.
- **FR-007**: System MUST require confirmation before deleting cached packages.
- **FR-008**: System MUST display package metadata including: name, version(s), publish/cache date, and source.
- **FR-009**: System MUST support pagination when displaying large numbers of packages (50 packages per page).
- **FR-010**: System MUST provide a unified search that searches across both local and cached packages.
- **FR-011**: System MUST maintain package resolution priority: local packages always take precedence over cached packages with the same name.
- **FR-012**: System MUST show version history for both local and cached packages.

### Key Entities

- **Local Package**: A package published directly to this HexHub instance. Contains name, versions, owner/publisher, publish timestamps, and package metadata.
- **Cached Package**: A package fetched from an upstream repository and stored locally for faster access. Contains name, cached versions, source repository URL, cache timestamps, and original package metadata.
- **Package Resolution**: The logic determining which package version is served when both local and cached packages exist with the same name. Local always takes precedence.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Administrators can identify package source (local vs cached) within 2 seconds of viewing any package in the admin interface.
- **SC-002**: Administrators can determine which package version will be served to clients (resolution priority) within 3 seconds for packages with conflicting names.
- **SC-003**: Administrators can delete a cached package in 3 clicks or fewer (navigate, select, confirm).
- **SC-004**: Package lists load and display within 2 seconds for up to 1000 packages.
- **SC-005**: Search results appear within 1 second of submitting a search query.
- **SC-006**: 100% of local packages display correct priority status when a cached package with the same name exists.

## Clarifications

### Session 2025-12-28

- Q: Should cached package deletion require elevated permissions beyond basic admin access? → A: No additional restrictions - any authenticated administrator can delete cached packages.

## Assumptions

- The existing admin authentication and authorization system will be used for access control to these new views.
- Cached package deletion requires only basic admin authentication; no elevated role is needed since cached packages are copies of upstream content that can be re-fetched.
- The current storage abstraction (`HexHub.Storage`) already tracks whether a package is local or cached, or this metadata can be derived from existing data structures.
- Pagination will use a default of 50 items per page, which is a standard default for admin interfaces.
- The admin interface already uses DaisyUI/Tailwind CSS, and new views will follow the existing design patterns.
- Cached package deletion only removes the cached copy; it does not affect the upstream repository.

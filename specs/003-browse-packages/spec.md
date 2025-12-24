# Feature Specification: Browse Packages

**Feature Branch**: `003-browse-packages`
**Created**: 2025-12-25
**Status**: Draft
**Input**: User description: "At home page, has two links, browse packages and API documents, they are not implemented yet. In this task, we implement the browse packages part. The browse should link to a new page that includes search packages, include trend of packages. When search packages, package link should go to page showing package information, includes base info, versions, etc. Reference: hex.pm browse packages features."

## Clarifications

### Session 2025-12-25

- Q: When should search filtering occur - on form submission or live as user types? → A: Submit-based search (Enter key / search button)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Browse All Packages (Priority: P1)

As a developer, I want to browse all available packages in the HexHub registry so that I can discover packages that might be useful for my projects.

**Why this priority**: This is the core functionality - users must be able to see what packages exist in the registry. Without this, no other package discovery features make sense.

**Independent Test**: Can be fully tested by navigating to /packages and verifying a paginated list of packages appears with basic information (name, description, version, download counts).

**Acceptance Scenarios**:

1. **Given** packages exist in the registry, **When** user clicks "Browse Packages" on home page, **Then** user sees a paginated list of all packages with name, current version, description, and download counts
2. **Given** user is on packages list page, **When** packages are displayed, **Then** packages are sorted by recent downloads by default (showing trending packages first)
3. **Given** more than 30 packages exist, **When** user views the packages list, **Then** pagination controls appear allowing navigation through results
4. **Given** user is on packages list, **When** user views any package entry, **Then** the package name is a clickable link to the package detail page

---

### User Story 2 - Search Packages (Priority: P1)

As a developer, I want to search for packages by name or keyword so that I can quickly find specific packages I'm looking for.

**Why this priority**: Search is essential for usability - without it, users would have to manually browse through potentially thousands of packages to find what they need.

**Independent Test**: Can be fully tested by entering a search term and verifying matching packages are displayed, with result count shown.

**Acceptance Scenarios**:

1. **Given** user is on packages page, **When** user submits a search term (via Enter key or search button), **Then** the package list filters to show only packages matching the search term
2. **Given** user searches for "phoenix", **When** results are displayed, **Then** all shown packages contain "phoenix" in their name or description
3. **Given** user has searched for packages, **When** results are displayed, **Then** the total count of matching results is shown
4. **Given** search returns more than 30 results, **When** user views results, **Then** pagination is available for navigating through all matching packages

---

### User Story 3 - View Package Details (Priority: P1)

As a developer, I want to view detailed information about a specific package so that I can evaluate whether to use it in my project.

**Why this priority**: Package details are essential for making informed decisions about which packages to use. This completes the core browse-and-discover workflow.

**Independent Test**: Can be fully tested by clicking on a package name and verifying the detail page shows comprehensive package information.

**Acceptance Scenarios**:

1. **Given** user clicks on a package name, **When** the package detail page loads, **Then** user sees package name, description, current version, and license information
2. **Given** user is on package detail page, **When** viewing download statistics, **Then** user sees recent downloads, weekly downloads, and total all-time downloads
3. **Given** package has multiple versions, **When** user views the versions section, **Then** all versions are listed with release dates and links to version-specific documentation
4. **Given** package has dependencies, **When** user views dependencies section, **Then** all dependencies are listed with version constraints and links to those packages
5. **Given** package has external links, **When** user views the page, **Then** links to documentation, source repository, and changelog are displayed (if available)

---

### User Story 4 - Sort Packages (Priority: P2)

As a developer, I want to sort the package list by different criteria so that I can find packages based on popularity, recency, or alphabetically.

**Why this priority**: Sorting enhances discoverability but the core browse functionality works without it. Users can still find packages through search.

**Independent Test**: Can be fully tested by selecting different sort options and verifying the package order changes accordingly.

**Acceptance Scenarios**:

1. **Given** user is on packages list, **When** user selects "Recent Downloads" sort option, **Then** packages are ordered by downloads in the current period (highest first)
2. **Given** user is on packages list, **When** user selects "Total Downloads" sort option, **Then** packages are ordered by all-time downloads (highest first)
3. **Given** user is on packages list, **When** user selects "Recently Updated" sort option, **Then** packages are ordered by last release date (newest first)
4. **Given** user is on packages list, **When** user selects "Name" sort option, **Then** packages are ordered alphabetically A-Z
5. **Given** user is on packages list, **When** user selects "Recently Created" sort option, **Then** packages are ordered by initial publication date (newest first)

---

### User Story 5 - View Package Trends (Priority: P2)

As a developer, I want to see trending and popular packages so that I can discover what's commonly used in the Elixir community.

**Why this priority**: Trend sections help with discovery but users can achieve similar results through sorting. This adds polish to the experience.

**Independent Test**: Can be fully tested by viewing the packages page and verifying curated trend sections appear.

**Acceptance Scenarios**:

1. **Given** user visits the packages page, **When** page loads, **Then** a "Most Downloaded" section shows top packages by total downloads
2. **Given** user visits the packages page, **When** page loads, **Then** a "Recently Updated" section shows packages with the most recent releases
3. **Given** user visits the packages page, **When** page loads, **Then** a "New Packages" section shows the most recently published packages

---

### User Story 6 - Alphabetical Filter (Priority: P3)

As a developer, I want to filter packages by first letter so that I can browse packages alphabetically when I know approximately what I'm looking for.

**Why this priority**: This is a convenience feature that enhances browsing but is not essential. Users can achieve similar results through search or sorting.

**Independent Test**: Can be fully tested by clicking a letter filter and verifying only packages starting with that letter are shown.

**Acceptance Scenarios**:

1. **Given** user is on packages list, **When** user clicks letter "P" in the A-Z filter, **Then** only packages starting with "P" are displayed
2. **Given** user has filtered by letter, **When** results are shown, **Then** the selected letter is visually highlighted
3. **Given** user has filtered by letter, **When** user clicks "All" or clears filter, **Then** all packages are shown again

---

### Edge Cases

- What happens when search returns no results? Display a friendly "No packages found" message with suggestion to modify search terms.
- What happens when a package has no versions? Display package metadata with a note that no releases are available yet.
- What happens when package detail page is accessed for non-existent package? Display a 404-style page with message "Package not found" and link back to browse page.
- How does the system handle packages with very long descriptions? Truncate descriptions in list view with "..." and show full description on detail page.
- What happens when download statistics are unavailable? Display "N/A" or 0 with graceful handling.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST display a paginated list of packages at the /packages route
- **FR-002**: System MUST show package name, current version, description (truncated), and download count in list view
- **FR-003**: System MUST provide a search field that filters packages by name or description on form submission (Enter key or search button click)
- **FR-004**: System MUST display search result count when filtering
- **FR-005**: System MUST support sorting packages by: name, total downloads, recent downloads, recently updated, recently created
- **FR-006**: System MUST default to sorting by recent downloads (trending)
- **FR-007**: System MUST provide pagination with 30 packages per page
- **FR-008**: System MUST link package names to individual package detail pages
- **FR-009**: System MUST display package detail page at /packages/:name route
- **FR-010**: System MUST show on package detail page: name, description, current version, license, download statistics
- **FR-011**: System MUST display all available versions with release dates on package detail page
- **FR-012**: System MUST display package dependencies with version constraints
- **FR-013**: System MUST display links to external resources (docs, repository, changelog) when available
- **FR-014**: System MUST display A-Z alphabetical filter navigation on packages list
- **FR-015**: System MUST display trend sections (Most Downloaded, Recently Updated, New Packages) on packages page
- **FR-016**: System MUST handle non-existent package requests with appropriate error page

### Key Entities

- **Package**: Core entity representing a published Elixir package. Contains name (unique identifier), description, license, repository URL, documentation URL, changelog URL, inserted_at (creation date), updated_at (last modification)
- **Release**: Represents a specific version of a package. Contains version number, release date, download count, dependencies list, retirement status
- **Download Statistics**: Aggregated download counts for packages. Contains total downloads, recent period downloads, weekly downloads, daily downloads

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can find any package in the registry within 30 seconds using search or browse
- **SC-002**: Package list page loads and displays results in under 2 seconds
- **SC-003**: Search results appear within 1 second of user stopping typing
- **SC-004**: Package detail page displays all information in under 2 seconds
- **SC-005**: Users can complete the browse-to-detail workflow (find package, view details) in under 1 minute
- **SC-006**: 90% of users can locate a specific package on first search attempt
- **SC-007**: Pagination allows users to browse through all packages without performance degradation

## Assumptions

- The HexHub.Packages context already provides functions to list and retrieve package data
- Download statistics are tracked and available through the existing package data model
- External links (docs, repository, changelog) are stored as part of package metadata during publish
- The existing DaisyUI/Tailwind styling will be used for consistent UI design
- Package search will be performed on name and description fields
- Recent downloads period is defined as the last 30 days (standard hex.pm behavior)

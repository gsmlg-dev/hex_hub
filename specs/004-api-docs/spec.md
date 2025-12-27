# Feature Specification: API Documentation Page

**Feature Branch**: `004-api-docs`
**Created**: 2025-12-26
**Status**: Draft
**Input**: User description: "There is a API Document link at the home page, the api document page does not implement yet, we need to add it in this task. This link should link to public docs to this project. It should include how to set mix to use this service, how to publish to this service, the api document of this service, the api docs in openapi spec 3 yaml format"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - View Getting Started Guide (Priority: P1)

A new developer visits HexHub and wants to learn how to configure their Elixir project to use HexHub as their package registry. They click "API Documentation" from the home page and land on a documentation page that shows them exactly how to configure their `mix.exs` and environment variables to use HexHub as a private hex mirror.

**Why this priority**: This is the most fundamental use case - without knowing how to configure mix, developers cannot use HexHub at all. This is the entry point for all new users.

**Independent Test**: Can be fully tested by navigating to the documentation page and verifying the presence of clear, copy-paste-ready configuration instructions for mix setup.

**Acceptance Scenarios**:

1. **Given** I am on the home page, **When** I click "API Documentation", **Then** I am taken to a documentation page (not a raw API endpoint)
2. **Given** I am on the documentation page, **When** I look for mix configuration, **Then** I find clear instructions for setting `HEX_MIRROR` and other required environment variables
3. **Given** I am viewing mix setup instructions, **When** I copy the configuration, **Then** the code snippets are properly formatted and include all necessary steps

---

### User Story 2 - Learn How to Publish Packages (Priority: P1)

A developer wants to publish their package to HexHub instead of hex.pm. They visit the documentation page to learn the complete workflow: creating an account, generating an API key, and running `mix hex.publish` against HexHub.

**Why this priority**: Publishing packages is the core functionality of HexHub. Without clear publishing instructions, the platform cannot fulfill its primary purpose.

**Independent Test**: Can be fully tested by reading the publishing guide and verifying it covers account creation, API key generation, and the `mix hex.publish` command with proper environment setup.

**Acceptance Scenarios**:

1. **Given** I am on the documentation page, **When** I navigate to the publishing section, **Then** I find step-by-step instructions for publishing packages
2. **Given** I am viewing publishing instructions, **When** I follow the guide, **Then** I understand how to configure `HEX_API_URL` and authenticate with an API key
3. **Given** I have an API key, **When** I look for publish commands, **Then** I find the exact commands needed to publish (including `--yes` flags for non-interactive publishing)

---

### User Story 3 - Explore API Reference (Priority: P2)

A developer building integrations or tooling needs to understand the complete API surface of HexHub. They visit the documentation page to find comprehensive API documentation covering all endpoints, request/response formats, authentication methods, and error codes.

**Why this priority**: While not essential for basic usage, API reference is critical for developers building tools, CI/CD integrations, or custom workflows around HexHub.

**Independent Test**: Can be fully tested by viewing the API reference section and verifying it displays endpoint information with request/response examples.

**Acceptance Scenarios**:

1. **Given** I am on the documentation page, **When** I navigate to the API reference, **Then** I see a list of all available API endpoints organized by category
2. **Given** I am viewing an endpoint, **When** I look at its details, **Then** I see the HTTP method, URL path, required parameters, and example responses
3. **Given** I need authentication details, **When** I look for auth documentation, **Then** I find information about API keys, Bearer tokens, and rate limits

---

### User Story 4 - Download OpenAPI Specification (Priority: P3)

A developer wants to generate client code or import the API into their API testing tool. They need access to the raw OpenAPI specification file in YAML format.

**Why this priority**: This is a convenience feature for advanced users who need machine-readable API documentation. Most users will use the rendered documentation.

**Independent Test**: Can be fully tested by downloading the OpenAPI YAML file and validating it parses correctly as OpenAPI 3.0.

**Acceptance Scenarios**:

1. **Given** I am on the documentation page, **When** I look for the OpenAPI spec, **Then** I find a download link or view link for the raw YAML file
2. **Given** I download the OpenAPI spec, **When** I open it, **Then** it is a valid OpenAPI 3.0 specification
3. **Given** I have the OpenAPI spec, **When** I import it into an API tool, **Then** it correctly describes all HexHub API endpoints

---

### Edge Cases

- What happens when the documentation page is accessed without JavaScript enabled? (Content should still be readable)
- How does the page handle very long code snippets? (Should be scrollable with copy functionality)
- What happens when a user tries to access a deep link to a specific section? (Anchor links should work)
- How does the page look on mobile devices? (Should be responsive and readable)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a dedicated documentation page accessible from the home page "API Documentation" link
- **FR-002**: System MUST display a "Getting Started" section with mix configuration instructions
- **FR-003**: System MUST include environment variable examples (`HEX_MIRROR`, `HEX_API_URL`, `HEX_API_KEY`)
- **FR-004**: System MUST provide a "Publishing Packages" section with complete workflow documentation
- **FR-005**: System MUST document the account creation and API key generation process
- **FR-006**: System MUST display API reference documentation as styled HTML sections (parsed from hex-api.yaml server-side) covering all public endpoints
- **FR-007**: System MUST organize API endpoints by category (Users, Packages, Releases, Keys, etc.)
- **FR-008**: System MUST provide access to the OpenAPI 3.0 specification (hex-api.yaml)
- **FR-009**: System MUST render documentation in a readable, styled format (not raw markdown)
- **FR-010**: System MUST include code snippets that are copy-friendly with proper syntax highlighting
- **FR-011**: System MUST provide navigation across multiple documentation pages with separate routes (e.g., `/docs`, `/docs/getting-started`, `/docs/publishing`, `/docs/api-reference`)
- **FR-012**: System MUST update the home page link to point to the new documentation page

### Key Entities

- **Documentation Page**: Main container for all documentation content, rendered from stored content
- **Code Snippet**: Formatted, copy-able code examples with syntax highlighting
- **API Endpoint Entry**: Representation of a single API endpoint with method, path, parameters, and examples
- **Navigation Section**: Logical grouping of documentation content for easy navigation

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can navigate from the home page to documentation in 1 click
- **SC-002**: Documentation page loads and displays all content within 3 seconds on standard connections
- **SC-003**: All code snippets are selectable and copyable
- **SC-004**: Documentation covers 100% of the documented API endpoints from hex-api.yaml
- **SC-005**: Page is readable on both desktop and mobile devices (responsive design)
- **SC-006**: OpenAPI specification file is downloadable and validates as OpenAPI 3.0
- **SC-007**: Users can find any section using page navigation or browser search within 10 seconds
- **SC-008**: New users can understand how to configure mix for HexHub in under 5 minutes of reading

## Clarifications

### Session 2025-12-26

- Q: Should documentation be a single page or multiple pages? → A: Multiple pages with separate routes (e.g., `/docs/getting-started`, `/docs/api-reference`)
- Q: How should the API reference be displayed? → A: Render API endpoints as styled HTML sections (parse hex-api.yaml server-side)

## Assumptions

- The existing `hex-api.yaml` OpenAPI 3.0 specification file accurately describes the current API
- The documentation will be rendered as HTML from content stored in the application (not external hosting)
- Code snippets will use Elixir/Shell syntax highlighting where appropriate
- The existing DaisyUI/Tailwind CSS design system will be used for styling consistency
- Documentation content will be static (not dynamically generated from code comments)

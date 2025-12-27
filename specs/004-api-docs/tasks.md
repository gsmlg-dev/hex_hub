# Tasks: API Documentation Page

**Input**: Design documents from `/specs/004-api-docs/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Tests are included as required by Constitution Principle VI (Test Coverage Requirements).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

- **Phoenix app**: `lib/hex_hub_web/` for web layer, `priv/static/` for static files
- **Tests**: `test/hex_hub_web/controllers/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add dependency and prepare static files

- [x] T001 Add yaml_elixir dependency to mix.exs
- [x] T002 Run mix deps.get to install yaml_elixir
- [x] T003 [P] Create priv/static/openapi/ directory and copy hex-api.yaml

---

## Phase 2: Foundational (Core Infrastructure)

**Purpose**: Create controller, view module, and routes that ALL user stories depend on

**CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Create DocsController skeleton in lib/hex_hub_web/controllers/docs_controller.ex
- [x] T005 Create DocsHTML view module with OpenAPI parsing in lib/hex_hub_web/controllers/docs_html.ex
- [x] T006 Create docs_html/ template directory at lib/hex_hub_web/controllers/docs_html/
- [x] T007 Add documentation routes to lib/hex_hub_web/router.ex
- [x] T008 [P] Create docs_layout component in DocsHTML for shared sidebar navigation
- [x] T009 Update home page link from /api/users to /docs in lib/hex_hub_web/controllers/page_html/home.html.heex

**Checkpoint**: Foundation ready - routes work, view module compiles, navigation component exists

---

## Phase 3: User Story 1 - View Getting Started Guide (Priority: P1)

**Goal**: New developers can learn how to configure mix to use HexHub as their package registry

**Independent Test**: Navigate to `/docs/getting-started` and verify HEX_MIRROR configuration instructions are present with copy-paste-ready code snippets

### Tests for User Story 1

- [x] T010 [P] [US1] Create docs_controller_test.exs with tests for index and getting_started actions in test/hex_hub_web/controllers/docs_controller_test.exs

### Implementation for User Story 1

- [x] T011 [P] [US1] Implement index action in lib/hex_hub_web/controllers/docs_controller.ex
- [x] T012 [P] [US1] Create index.html.heex documentation landing page in lib/hex_hub_web/controllers/docs_html/index.html.heex
- [x] T013 [US1] Implement getting_started action in lib/hex_hub_web/controllers/docs_controller.ex
- [x] T014 [US1] Create getting_started.html.heex with HEX_MIRROR configuration guide in lib/hex_hub_web/controllers/docs_html/getting_started.html.heex
- [x] T015 [US1] Add code snippets for shell, mix.exs, Docker, and CI/CD configuration examples
- [x] T016 [US1] Add telemetry event for documentation page views per Constitution Principle VII

**Checkpoint**: User Story 1 complete - developers can view Getting Started guide with mix configuration

---

## Phase 4: User Story 2 - Learn How to Publish Packages (Priority: P1)

**Goal**: Developers can learn the complete workflow for publishing packages to HexHub

**Independent Test**: Navigate to `/docs/publishing` and verify publishing workflow documentation covers account creation, API key generation, and `mix hex.publish` command

### Tests for User Story 2

- [x] T017 [P] [US2] Add test for publishing action to test/hex_hub_web/controllers/docs_controller_test.exs

### Implementation for User Story 2

- [x] T018 [US2] Implement publishing action in lib/hex_hub_web/controllers/docs_controller.ex
- [x] T019 [US2] Create publishing.html.heex with publishing workflow guide in lib/hex_hub_web/controllers/docs_html/publishing.html.heex
- [x] T020 [US2] Add HEX_API_URL and HEX_API_KEY environment variable examples
- [x] T021 [US2] Add code snippets for shell, GitHub Actions, and Docker publishing examples
- [x] T022 [US2] Include documentation for --yes flag and non-interactive publishing

**Checkpoint**: User Story 2 complete - developers can learn publishing workflow

---

## Phase 5: User Story 3 - Explore API Reference (Priority: P2)

**Goal**: Developers can explore comprehensive API documentation covering all endpoints

**Independent Test**: Navigate to `/docs/api-reference` and verify all API endpoints from hex-api.yaml are displayed, organized by category

### Tests for User Story 3

- [x] T023 [P] [US3] Add test for api_reference action to test/hex_hub_web/controllers/docs_controller_test.exs

### Implementation for User Story 3

- [x] T024 [US3] Implement api_reference action in lib/hex_hub_web/controllers/docs_controller.ex
- [x] T025 [US3] Implement paths_by_tag/0 function in DocsHTML to group endpoints by OpenAPI tags
- [x] T026 [US3] Implement method_badge_class/1 helper for HTTP method styling
- [x] T027 [US3] Create api_reference.html.heex with endpoint listing in lib/hex_hub_web/controllers/docs_html/api_reference.html.heex
- [x] T028 [US3] Add endpoint cards showing method, path, summary, and parameters
- [x] T029 [US3] Add anchor links for each API category (Users, Packages, Releases, etc.)
- [x] T030 [US3] Include authentication and rate limiting documentation section

**Checkpoint**: User Story 3 complete - developers can explore full API reference

---

## Phase 6: User Story 4 - Download OpenAPI Specification (Priority: P3)

**Goal**: Developers can download the raw OpenAPI YAML file for code generation or API tools

**Independent Test**: Verify `/openapi/hex-api.yaml` is downloadable and validates as OpenAPI 3.0

### Tests for User Story 4

- [x] T031 [P] [US4] Add test verifying OpenAPI YAML file is served from priv/static/openapi/

### Implementation for User Story 4

- [x] T032 [US4] Add download link for OpenAPI spec to api_reference.html.heex
- [x] T033 [US4] Add OpenAPI download link to index.html.heex overview page
- [x] T034 [US4] Verify hex-api.yaml is correctly served as static file

**Checkpoint**: User Story 4 complete - developers can download OpenAPI spec

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final improvements affecting all user stories

- [x] T035 [P] Verify all pages are responsive on mobile devices
- [x] T036 [P] Test navigation sidebar works on all documentation pages
- [x] T037 Run mix format to ensure code formatting
- [x] T038 Run mix credo --strict to verify code quality
- [x] T039 Run full test suite: mix test
- [x] T040 Run quickstart.md verification checklist

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - US1 and US2 are both P1 priority - can run in parallel
  - US3 (P2) can run in parallel with US1/US2
  - US4 (P3) can run in parallel but is lowest priority
- **Polish (Phase 7)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational - No dependencies on other stories
- **User Story 2 (P1)**: Can start after Foundational - No dependencies on other stories
- **User Story 3 (P2)**: Can start after Foundational - Uses same DocsHTML module as US1/US2
- **User Story 4 (P3)**: Can start after Foundational - May add links to pages from US3

### Within Each User Story

- Tests FIRST (write test, ensure it fails)
- Controller actions before templates
- Templates with full content
- Story complete before moving to next priority

### Parallel Opportunities

- T003 can run in parallel with T001-T002 (different files)
- T008 can run in parallel with T004-T007 (layout component is separate)
- T010, T011, T012 can all run in parallel (different files)
- US1 and US2 can be worked on in parallel (different templates)
- US3 and US4 can be worked on in parallel (different concerns)

---

## Parallel Example: User Story 1

```bash
# Launch tests and models in parallel:
Task: "Create docs_controller_test.exs in test/hex_hub_web/controllers/"
Task: "Implement index action in docs_controller.ex"
Task: "Create index.html.heex landing page"

# Then sequentially:
Task: "Implement getting_started action"
Task: "Create getting_started.html.heex template"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T003)
2. Complete Phase 2: Foundational (T004-T009)
3. Complete Phase 3: User Story 1 (T010-T016)
4. **STOP and VALIDATE**: Test `/docs` and `/docs/getting-started` work
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Routes work, navigation exists
2. Add User Story 1 → Getting Started guide live (MVP!)
3. Add User Story 2 → Publishing guide live
4. Add User Story 3 → Full API reference live
5. Add User Story 4 → OpenAPI download available
6. Polish phase → All cross-cutting improvements

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (Getting Started)
   - Developer B: User Story 2 (Publishing)
3. Then:
   - Developer A: User Story 3 (API Reference)
   - Developer B: User Story 4 (OpenAPI Download)
4. Team completes Polish phase together

---

## Task Summary

| Phase | Story | Task Count | Parallel Tasks |
|-------|-------|------------|----------------|
| Setup | - | 3 | 1 |
| Foundational | - | 6 | 1 |
| User Story 1 | US1 | 7 | 3 |
| User Story 2 | US2 | 6 | 1 |
| User Story 3 | US3 | 8 | 1 |
| User Story 4 | US4 | 4 | 1 |
| Polish | - | 6 | 2 |
| **Total** | | **40** | **10** |

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Constitution Principle VII requires telemetry events for page views (T016)
- Constitution Principle VI requires test coverage (T010, T017, T023, T031)

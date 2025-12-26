# Tasks: Browse Packages

**Input**: Design documents from `/specs/003-browse-packages/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Tests are included as this is a user-facing feature requiring validation.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

Phoenix application structure:
- **Context**: `lib/hex_hub/` (business logic)
- **Web**: `lib/hex_hub_web/` (controllers, templates, views)
- **Tests**: `test/hex_hub/` and `test/hex_hub_web/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Routing and view module setup

- [x] T001 Add `/packages` and `/packages/:name` routes in lib/hex_hub_web/router.ex
- [x] T002 Create PackageHTML view module in lib/hex_hub_web/controllers/package_html.ex with helper functions
- [x] T003 [P] Create package_html directory for templates at lib/hex_hub_web/controllers/package_html/

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Context layer extensions that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Extend list_packages/1 to accept :sort option in lib/hex_hub/packages.ex (sort options: :recent_downloads, :total_downloads, :name, :recently_updated, :recently_created)
- [x] T005 [P] Add apply_sort/2 private function in lib/hex_hub/packages.ex for sorting package lists
- [x] T006 [P] Add list_most_downloaded/1 function in lib/hex_hub/packages.ex (returns top N by total downloads)
- [x] T007 [P] Add list_recently_updated/1 function in lib/hex_hub/packages.ex (returns packages with most recent releases)
- [x] T008 [P] Add list_new_packages/1 function in lib/hex_hub/packages.ex (returns newest packages by inserted_at)
- [x] T009 Add telemetry events for browse and view operations in lib/hex_hub/packages.ex

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Browse All Packages (Priority: P1) 🎯 MVP

**Goal**: Display paginated list of packages at /packages with default sorting by recent downloads

**Independent Test**: Navigate to /packages and verify a paginated list appears with package name, version, description, and download counts

### Tests for User Story 1

- [x] T010 [P] [US1] Add context tests for list_packages/1 with sorting in test/hex_hub/packages_test.exs
- [x] T011 [P] [US1] Add controller test for GET /packages in test/hex_hub_web/controllers/package_controller_test.exs

### Implementation for User Story 1

- [x] T012 [US1] Implement PackageController.index/2 action in lib/hex_hub_web/controllers/package_controller.ex (pagination, default sort)
- [x] T013 [US1] Create index.html.heex template in lib/hex_hub_web/controllers/package_html/index.html.heex (package list grid)
- [x] T014 [US1] Add format_downloads/1 helper in lib/hex_hub_web/controllers/package_html.ex (formats 1M, 100K, etc.)
- [x] T015 [US1] Add format_relative_time/1 helper in lib/hex_hub_web/controllers/package_html.ex
- [x] T016 [US1] Add pagination component to index.html.heex with page_range/3 helper
- [x] T017 [US1] Add empty state component to index.html.heex for when no packages exist
- [x] T018 [US1] Update home page link to point to /packages in lib/hex_hub_web/controllers/page_html/home.html.heex

**Checkpoint**: User Story 1 complete - browsing works with pagination and default sorting

---

## Phase 4: User Story 2 - Search Packages (Priority: P1)

**Goal**: Allow users to search packages by name or description with submit-based filtering

**Independent Test**: Enter a search term, press Enter or click search button, verify matching packages displayed with result count

### Tests for User Story 2

- [x] T019 [P] [US2] Add context tests for search functionality in test/hex_hub/packages_test.exs
- [x] T020 [P] [US2] Add controller test for GET /packages?search=term in test/hex_hub_web/controllers/package_controller_test.exs

### Implementation for User Story 2

- [x] T021 [US2] Extend list_packages/1 to accept :search option in lib/hex_hub/packages.ex
- [x] T022 [US2] Add matches_search?/2 private function in lib/hex_hub/packages.ex (case-insensitive match on name/description)
- [x] T023 [US2] Add search form component to index.html.heex with submit button
- [x] T024 [US2] Display search result count in index.html.heex header
- [x] T025 [US2] Add preserve_params/2 helper in lib/hex_hub_web/controllers/package_html.ex (maintains search across pagination)

**Checkpoint**: User Stories 1 AND 2 complete - browsing with search works

---

## Phase 5: User Story 3 - View Package Details (Priority: P1)

**Goal**: Display comprehensive package information including versions, dependencies, and download statistics

**Independent Test**: Click on a package name, verify detail page shows name, description, versions, dependencies, and stats

### Tests for User Story 3

- [x] T026 [P] [US3] Add controller test for GET /packages/:name in test/hex_hub_web/controllers/package_controller_test.exs
- [x] T027 [P] [US3] Add controller test for 404 response on non-existent package in test/hex_hub_web/controllers/package_controller_test.exs

### Implementation for User Story 3

- [x] T028 [US3] Implement PackageController.show/2 action in lib/hex_hub_web/controllers/package_controller.ex
- [x] T029 [US3] Add get_latest_version/1 private function in lib/hex_hub_web/controllers/package_controller.ex
- [x] T030 [US3] Add get_dependencies/1 private function in lib/hex_hub_web/controllers/package_controller.ex
- [x] T031 [US3] Add get_download_stats/2 private function in lib/hex_hub_web/controllers/package_controller.ex
- [x] T032 [US3] Create show.html.heex template in lib/hex_hub_web/controllers/package_html/show.html.heex
- [x] T033 [US3] Add package header section with name, version, description, license in show.html.heex
- [x] T034 [US3] Add download statistics section using DaisyUI stats component in show.html.heex
- [x] T035 [US3] Add external links section (docs, repository, changelog) in show.html.heex
- [x] T036 [US3] Add versions table with release dates in show.html.heex
- [x] T037 [US3] Add dependencies table with version constraints in show.html.heex
- [x] T038 [US3] Add mix.exs installation snippet using mockup-code component in show.html.heex
- [x] T039 [US3] Create not_found.html.heex template in lib/hex_hub_web/controllers/package_html/not_found.html.heex
- [x] T040 [US3] Add license_name/1 helper in lib/hex_hub_web/controllers/package_html.ex

**Checkpoint**: Core MVP complete - browse, search, and view details all work

---

## Phase 6: User Story 4 - Sort Packages (Priority: P2)

**Goal**: Allow users to sort package list by different criteria (downloads, name, date)

**Independent Test**: Select different sort options from dropdown, verify package order changes accordingly

### Tests for User Story 4

- [x] T041 [P] [US4] Add context tests for all sort options in test/hex_hub/packages_test.exs
- [x] T042 [P] [US4] Add controller test for GET /packages?sort=name in test/hex_hub_web/controllers/package_controller_test.exs

### Implementation for User Story 4

- [x] T043 [US4] Add parse_sort/1 private function in lib/hex_hub_web/controllers/package_controller.ex
- [x] T044 [US4] Add sort dropdown component to index.html.heex with all 5 sort options
- [x] T045 [US4] Update preserve_params/2 helper to maintain sort option across interactions

**Checkpoint**: User Stories 1-4 complete - full sorting functionality available

---

## Phase 7: User Story 5 - View Package Trends (Priority: P2)

**Goal**: Display curated trend sections (Most Downloaded, Recently Updated, New Packages)

**Independent Test**: Visit /packages, verify three trend sections appear with top 5 packages each

### Tests for User Story 5

- [x] T046 [P] [US5] Add context tests for list_most_downloaded/1 in test/hex_hub/packages_test.exs
- [x] T047 [P] [US5] Add context tests for list_recently_updated/1 in test/hex_hub/packages_test.exs
- [x] T048 [P] [US5] Add context tests for list_new_packages/1 in test/hex_hub/packages_test.exs

### Implementation for User Story 5

- [x] T049 [US5] Add trend data to PackageController.index/2 assigns in lib/hex_hub_web/controllers/package_controller.ex
- [x] T050 [US5] Add trend sections tabs component to index.html.heex using DaisyUI tabs
- [x] T051 [US5] Add compact package card component for trend sections in index.html.heex

**Checkpoint**: User Stories 1-5 complete - trends visible on packages page

---

## Phase 8: User Story 6 - Alphabetical Filter (Priority: P3)

**Goal**: Allow users to filter packages by first letter (A-Z navigation)

**Independent Test**: Click letter "P" in A-Z filter, verify only packages starting with "P" are displayed

### Tests for User Story 6

- [x] T052 [P] [US6] Add context tests for letter filtering in test/hex_hub/packages_test.exs
- [x] T053 [P] [US6] Add controller test for GET /packages?letter=P in test/hex_hub_web/controllers/package_controller_test.exs

### Implementation for User Story 6

- [x] T054 [US6] Extend list_packages/1 to accept :letter option in lib/hex_hub/packages.ex
- [x] T055 [US6] Add starts_with_letter?/2 private function in lib/hex_hub/packages.ex
- [x] T056 [US6] Add A-Z filter bar component to index.html.heex with letter buttons
- [x] T057 [US6] Add visual highlight for selected letter in A-Z filter
- [x] T058 [US6] Update preserve_params/2 helper to maintain letter filter across interactions

**Checkpoint**: All user stories complete - full browse functionality available

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T059 [P] Run mix format and fix any formatting issues
- [ ] T060 [P] Run mix credo and fix any style issues
- [ ] T061 [P] Run mix dialyzer and fix any type warnings
- [ ] T062 Run full test suite with mix test to verify all functionality
- [x] T063 [P] Add legacy /browse redirect to /packages in lib/hex_hub_web/router.ex
- [ ] T064 Manual verification: run through quickstart.md checklist

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 - BLOCKS all user stories
- **User Stories (Phases 3-8)**: All depend on Phase 2 completion
  - P1 stories (US1, US2, US3) should be done first
  - P2 stories (US4, US5) can follow
  - P3 stories (US6) can be last
- **Polish (Phase 9)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Phase 2 - No dependencies on other stories
- **User Story 2 (P1)**: Can start after Phase 2 - Builds on US1 template but independent
- **User Story 3 (P1)**: Can start after Phase 2 - Completely independent
- **User Story 4 (P2)**: Can start after Phase 2 - Extends US1 template
- **User Story 5 (P2)**: Can start after Phase 2 - Extends US1 template
- **User Story 6 (P3)**: Can start after Phase 2 - Extends US1 template

### Within Each User Story

- Tests written first (fail before implementation)
- Context functions before controller
- Controller before templates
- Helper functions as needed

### Parallel Opportunities

- All [P] tasks within a phase can run in parallel
- US1, US2, US3 can be worked on in parallel by different developers
- US4, US5, US6 can be worked on in parallel after US1 template exists

---

## Parallel Example: Foundational Phase

```bash
# After T004 completes, these can run in parallel:
Task: T005 - Add apply_sort/2 private function
Task: T006 - Add list_most_downloaded/1 function
Task: T007 - Add list_recently_updated/1 function
Task: T008 - Add list_new_packages/1 function
```

## Parallel Example: User Story 3

```bash
# Tests can run in parallel:
Task: T026 - Controller test for GET /packages/:name
Task: T027 - Controller test for 404 response

# After T028 (controller action), template sections can be parallel:
Task: T033 - Package header section
Task: T034 - Download statistics section
Task: T035 - External links section
Task: T036 - Versions table
Task: T037 - Dependencies table
```

---

## Implementation Strategy

### MVP First (User Stories 1-3 Only)

1. Complete Phase 1: Setup (T001-T003)
2. Complete Phase 2: Foundational (T004-T009)
3. Complete Phase 3: User Story 1 - Browse (T010-T018)
4. Complete Phase 4: User Story 2 - Search (T019-T025)
5. Complete Phase 5: User Story 3 - Details (T026-T040)
6. **STOP and VALIDATE**: Test all three independently
7. Deploy/demo if ready - Core browse experience complete!

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add US1 (Browse) → Deploy (users can see packages)
3. Add US2 (Search) → Deploy (users can find packages)
4. Add US3 (Details) → Deploy (users can evaluate packages) - **MVP Complete!**
5. Add US4 (Sort) → Deploy (enhanced discovery)
6. Add US5 (Trends) → Deploy (curated discovery)
7. Add US6 (A-Z Filter) → Deploy (alphabetical browsing)

### Suggested MVP Scope

**Phases 1-5 (T001-T040)** represent the MVP:
- Browse packages with pagination
- Search packages
- View package details

This delivers the core value proposition before enhancement features.

---

## Summary

| Phase | User Story | Tasks | Parallel Tasks |
|-------|------------|-------|----------------|
| 1. Setup | - | 3 | 1 |
| 2. Foundational | - | 6 | 4 |
| 3. US1 - Browse | P1 | 9 | 2 |
| 4. US2 - Search | P1 | 7 | 2 |
| 5. US3 - Details | P1 | 15 | 2 |
| 6. US4 - Sort | P2 | 5 | 2 |
| 7. US5 - Trends | P2 | 6 | 3 |
| 8. US6 - A-Z Filter | P3 | 7 | 2 |
| 9. Polish | - | 6 | 4 |
| **Total** | | **64** | **22** |

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing (TDD approach)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- All templates use DaisyUI components for consistent styling
- Telemetry events for observability (Constitution Principle VII)

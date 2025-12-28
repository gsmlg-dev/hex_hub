# Tasks: Admin Package Management

**Input**: Design documents from `/specs/005-admin-package-management/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅

**Tests**: Included per Constitution Principle VI (Test Coverage Requirements)

**Organization**: Tasks grouped by user story for independent implementation and testing

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

- **Context modules**: `lib/hex_hub/`
- **Admin controllers**: `lib/hex_hub_admin_web/controllers/`
- **Templates**: `lib/hex_hub_admin_web/controllers/*_html/`
- **Tests**: `test/hex_hub/` and `test/hex_hub_admin_web/controllers/`

---

## Phase 1: Setup (Schema Migration)

**Purpose**: Extend Mnesia schema to support source tracking

- [x] T001 Modify Mnesia table definition to add `source` field in lib/hex_hub/mnesia.ex
- [x] T002 Add migration function `migrate_package_source_field/0` for existing data in lib/hex_hub/mnesia.ex
- [x] T003 Add `source` index to `:packages` table in lib/hex_hub/mnesia.ex
- [x] T004 Call migration function in application startup in lib/hex_hub/application.ex

---

## Phase 2: Foundational (Core Context Module)

**Purpose**: Core business logic for source-aware package queries - MUST complete before user stories

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T005 Create HexHub.CachedPackages context module in lib/hex_hub/cached_packages.ex
- [x] T006 Implement `list_packages_by_source/2` function in lib/hex_hub/cached_packages.ex
- [x] T007 Implement `list_packages_with_priority/1` function in lib/hex_hub/cached_packages.ex
- [x] T008 Implement `get_package_by_source/2` function in lib/hex_hub/cached_packages.ex
- [x] T009 Update `Packages.create_package/4` to set `source: :local` in lib/hex_hub/packages.ex
- [x] T010 Update `Packages.create_package_from_upstream/2` to set `source: :cached` in lib/hex_hub/packages.ex
- [x] T011 [P] Create test file for CachedPackages context in test/hex_hub/cached_packages_test.exs
- [x] T012 [P] Add admin routes to router in lib/hex_hub_admin_web/router.ex

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - View Locally Published Packages (Priority: P1) 🎯 MVP

**Goal**: Display all locally published packages in admin dashboard with metadata

**Independent Test**: Navigate to `/admin/local-packages` and verify local packages display correctly with name, version, publisher, and dates

### Tests for User Story 1

- [x] T013 [P] [US1] Create controller test file in test/hex_hub_admin_web/controllers/local_package_controller_test.exs
- [x] T014 [P] [US1] Add test for `index/2` action listing local packages in test/hex_hub_admin_web/controllers/local_package_controller_test.exs
- [x] T015 [P] [US1] Add test for `show/2` action displaying package details in test/hex_hub_admin_web/controllers/local_package_controller_test.exs
- [x] T016 [P] [US1] Add test for empty state when no packages exist in test/hex_hub_admin_web/controllers/local_package_controller_test.exs
- [x] T017 [P] [US1] Add test for pagination in test/hex_hub_admin_web/controllers/local_package_controller_test.exs

### Implementation for User Story 1

- [x] T018 [US1] Create LocalPackageController module in lib/hex_hub_admin_web/controllers/local_package_controller.ex
- [x] T019 [US1] Implement `index/2` action with pagination, search, sort in lib/hex_hub_admin_web/controllers/local_package_controller.ex
- [x] T020 [US1] Implement `show/2` action with version history in lib/hex_hub_admin_web/controllers/local_package_controller.ex
- [x] T021 [US1] Add telemetry event emission for list operations in lib/hex_hub_admin_web/controllers/local_package_controller.ex
- [x] T022 [P] [US1] Create template directory lib/hex_hub_admin_web/controllers/local_package_html/
- [x] T023 [US1] Create index.html.heex template with package table in lib/hex_hub_admin_web/controllers/local_package_html/index.html.heex
- [x] T024 [US1] Create show.html.heex template with package details in lib/hex_hub_admin_web/controllers/local_package_html/show.html.heex
- [x] T025 [US1] Add empty state message in index template in lib/hex_hub_admin_web/controllers/local_package_html/index.html.heex
- [x] T026 [US1] Add pagination controls to index template in lib/hex_hub_admin_web/controllers/local_package_html/index.html.heex
- [x] T027 [US1] Add search form to index template in lib/hex_hub_admin_web/controllers/local_package_html/index.html.heex
- [x] T028 [US1] Add navigation link to admin sidebar/dashboard in lib/hex_hub_admin_web/components/layouts/root.html.heex

**Checkpoint**: User Story 1 complete - local packages viewable in admin

---

## Phase 4: User Story 2 - View Cached Remote Packages (Priority: P2)

**Goal**: Display all cached packages from upstream with source and status indicators

**Independent Test**: Navigate to `/admin/cached-packages` and verify cached packages display with shadowed indicator when local counterpart exists

### Tests for User Story 2

- [x] T029 [P] [US2] Create controller test file in test/hex_hub_admin_web/controllers/cached_package_controller_test.exs
- [x] T030 [P] [US2] Add test for `index/2` action listing cached packages in test/hex_hub_admin_web/controllers/cached_package_controller_test.exs
- [x] T031 [P] [US2] Add test for `show/2` action displaying cached package details in test/hex_hub_admin_web/controllers/cached_package_controller_test.exs
- [x] T032 [P] [US2] Add test for shadowed status when local counterpart exists in test/hex_hub_admin_web/controllers/cached_package_controller_test.exs
- [x] T033 [P] [US2] Add test for empty state when no cached packages exist in test/hex_hub_admin_web/controllers/cached_package_controller_test.exs

### Implementation for User Story 2

- [x] T034 [US2] Create CachedPackageController module in lib/hex_hub_admin_web/controllers/cached_package_controller.ex
- [x] T035 [US2] Implement `index/2` action with status annotation in lib/hex_hub_admin_web/controllers/cached_package_controller.ex
- [x] T036 [US2] Implement `show/2` action with shadowed indicator in lib/hex_hub_admin_web/controllers/cached_package_controller.ex
- [x] T037 [US2] Add telemetry event emission for list operations in lib/hex_hub_admin_web/controllers/cached_package_controller.ex
- [x] T038 [P] [US2] Create template directory lib/hex_hub_admin_web/controllers/cached_package_html/
- [x] T039 [US2] Create index.html.heex template with status badges in lib/hex_hub_admin_web/controllers/cached_package_html/index.html.heex
- [x] T040 [US2] Create show.html.heex template with shadowed warning in lib/hex_hub_admin_web/controllers/cached_package_html/show.html.heex
- [x] T041 [US2] Add pagination and search controls to index template in lib/hex_hub_admin_web/controllers/cached_package_html/index.html.heex
- [x] T042 [US2] Add navigation link to admin sidebar in lib/hex_hub_admin_web/components/layouts/root.html.heex

**Checkpoint**: User Stories 1 AND 2 complete - both package views functional

---

## Phase 5: User Story 3 - Unified Package Search with Priority (Priority: P3)

**Goal**: Search across both local and cached packages with priority indicators

**Independent Test**: Search for a package name that exists in both sources, verify results show both with "Active" and "Shadowed" labels

### Tests for User Story 3

- [x] T043 [P] [US3] Add test for `search/2` action in test/hex_hub_admin_web/controllers/package_controller_test.exs
- [x] T044 [P] [US3] Add test for priority annotation in search results in test/hex_hub_admin_web/controllers/package_controller_test.exs
- [x] T045 [P] [US3] Add test for source filter parameter in test/hex_hub_admin_web/controllers/package_controller_test.exs

### Implementation for User Story 3

- [x] T046 [US3] Add `search/2` action to existing PackageController in lib/hex_hub_admin_web/controllers/package_controller.ex
- [x] T047 [US3] Implement unified search logic calling CachedPackages.list_packages_with_priority in lib/hex_hub_admin_web/controllers/package_controller.ex
- [x] T048 [US3] Add telemetry event for search operations in lib/hex_hub_admin_web/controllers/package_controller.ex
- [x] T049 [US3] Create search.html.heex template with priority badges in lib/hex_hub_admin_web/controllers/package_html/search.html.heex
- [x] T050 [US3] Add search form to admin navigation in lib/hex_hub_admin_web/components/layouts/root.html.heex

**Checkpoint**: User Stories 1, 2, AND 3 complete - full package visibility

---

## Phase 6: User Story 4 - Manage Cached Package Lifecycle (Priority: P4)

**Goal**: Enable administrators to delete cached packages individually or clear entire cache

**Independent Test**: Delete a cached package and verify it is removed; clear all cache and verify empty state

### Tests for User Story 4

- [x] T051 [P] [US4] Add test for `delete/2` action in test/hex_hub_admin_web/controllers/cached_package_controller_test.exs
- [x] T052 [P] [US4] Add test for `clear_all/2` action in test/hex_hub_admin_web/controllers/cached_package_controller_test.exs
- [x] T053 [P] [US4] Add test for confirmation requirement in test/hex_hub_admin_web/controllers/cached_package_controller_test.exs
- [x] T054 [P] [US4] Add test for storage cleanup on delete in test/hex_hub/cached_packages_test.exs

### Implementation for User Story 4

- [x] T055 [US4] Implement `delete_cached_package/1` function in lib/hex_hub/cached_packages.ex
- [x] T056 [US4] Implement `clear_all_cached_packages/0` function in lib/hex_hub/cached_packages.ex
- [x] T057 [US4] Add telemetry events for delete operations in lib/hex_hub/cached_packages.ex
- [x] T058 [US4] Implement `delete/2` action in lib/hex_hub_admin_web/controllers/cached_package_controller.ex
- [x] T059 [US4] Implement `clear_all/2` action in lib/hex_hub_admin_web/controllers/cached_package_controller.ex
- [x] T060 [US4] Add delete button with confirmation dialog to show.html.heex in lib/hex_hub_admin_web/controllers/cached_package_html/show.html.heex
- [x] T061 [US4] Add "Clear All Cache" button with confirmation to index.html.heex in lib/hex_hub_admin_web/controllers/cached_package_html/index.html.heex
- [x] T062 [US4] Add flash message handling for delete success/error in lib/hex_hub_admin_web/controllers/cached_package_controller.ex

**Checkpoint**: All user stories complete - full admin package management

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T063 [P] Update admin dashboard with package statistics in lib/hex_hub_admin_web/controllers/admin_controller.ex
- [x] T064 [P] Add local/cached package counts to dashboard in lib/hex_hub_admin_web/controllers/admin_html/dashboard.html.heex
- [x] T065 Run `mix format` to ensure code formatting
- [x] T066 Run `mix credo --strict` and fix any warnings
- [x] T067 Run `mix dialyzer` and fix any type issues
- [x] T068 Run `mix test` to verify all tests pass
- [x] T069 Validate quickstart.md scenarios manually
- [x] T070 Update CLAUDE.md if new patterns introduced

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phases 3-6)**: All depend on Foundational phase completion
- **Polish (Phase 7)**: Depends on all user stories being complete

### User Story Dependencies

| Story | Depends On | Can Start After |
|-------|------------|-----------------|
| US1 (P1) | Foundational | Phase 2 complete |
| US2 (P2) | Foundational | Phase 2 complete |
| US3 (P3) | US1, US2 | Phases 3-4 complete (uses both package lists) |
| US4 (P4) | US2 | Phase 4 complete (extends cached package controller) |

### Within Each User Story

1. Tests written FIRST (ensure they FAIL before implementation)
2. Context functions before controllers
3. Controllers before templates
4. Core implementation before UI polish

### Parallel Opportunities

**Phase 1**: All tasks sequential (schema changes)

**Phase 2**: T011, T012 can run in parallel

**Phase 3 (US1)**:
- T013-T017 (all tests) can run in parallel
- T022 can run in parallel with controller work

**Phase 4 (US2)**:
- T029-T033 (all tests) can run in parallel
- T038 can run in parallel with controller work

**Phase 5 (US3)**:
- T043-T045 (all tests) can run in parallel

**Phase 6 (US4)**:
- T051-T054 (all tests) can run in parallel

**Phase 7**:
- T063, T064 can run in parallel

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together:
Task: "T013 Create controller test file"
Task: "T014 Add test for index/2 action"
Task: "T015 Add test for show/2 action"
Task: "T016 Add test for empty state"
Task: "T017 Add test for pagination"

# After tests created, implement in sequence:
# T018 → T019 → T020 → T021 (controller)
# T022 → T023 → T024 → T025 → T026 → T027 (templates)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T004)
2. Complete Phase 2: Foundational (T005-T012)
3. Complete Phase 3: User Story 1 (T013-T028)
4. **STOP and VALIDATE**: Test `/admin/local-packages` independently
5. Deploy/demo if ready

### Incremental Delivery

1. **Setup + Foundational** → Foundation ready
2. **User Story 1** → Local packages visible (MVP!)
3. **User Story 2** → Cached packages visible with status
4. **User Story 3** → Unified search with priority
5. **User Story 4** → Cache management operations
6. **Polish** → Dashboard updates, code quality

### Sequential Implementation (Recommended)

Given US3 depends on US1+US2, and US4 extends US2:

```
Phase 1 → Phase 2 → US1 → US2 → US3 → US4 → Polish
```

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks
- [Story] label maps task to specific user story for traceability
- Each user story is independently testable after completion
- Telemetry events required per Constitution Principle VII
- DaisyUI/Tailwind CSS for all templates per Constitution
- Commit after each task or logical group

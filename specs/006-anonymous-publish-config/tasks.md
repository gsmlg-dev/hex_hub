# Tasks: Anonymous Publish Configuration

**Input**: Design documents from `/specs/006-anonymous-publish-config/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅

**Tests**: Included per Constitution Principle VI (Test Coverage Requirements)

**Organization**: Tasks grouped by user story for independent implementation and testing

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Context modules**: `lib/hex_hub/`
- **Web plugs**: `lib/hex_hub_web/plugs/`
- **Admin controllers**: `lib/hex_hub_admin_web/controllers/`
- **Templates**: `lib/hex_hub_admin_web/controllers/*_html/`
- **Tests**: `test/hex_hub/` and `test/hex_hub_admin_web/controllers/`

---

## Phase 1: Setup (Schema & Table)

**Purpose**: Add Mnesia table for publish configuration

- [x] T001 Add `:publish_configs` table definition in lib/hex_hub/mnesia.ex
- [x] T002 Add table creation in `ensure_tables/0` function in lib/hex_hub/mnesia.ex

---

## Phase 2: Foundational (Core Modules)

**Purpose**: Core business logic modules that MUST complete before user stories

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T003 Create HexHub.PublishConfig module in lib/hex_hub/publish_config.ex
- [x] T004 Implement `get_config/0` function in lib/hex_hub/publish_config.ex
- [x] T005 Implement `update_config/1` function in lib/hex_hub/publish_config.ex
- [x] T006 Implement `anonymous_publishing_enabled?/0` function in lib/hex_hub/publish_config.ex
- [x] T007 Implement `init_default_config/0` function in lib/hex_hub/publish_config.ex
- [x] T008 Add reserved username validation for "anonymous" in lib/hex_hub/users.ex
- [x] T009 Add anonymous user protection (prevent delete/modify) in lib/hex_hub/users.ex
- [x] T010 Create `ensure_anonymous_user/0` function in lib/hex_hub/users.ex
- [x] T011 Call `ensure_anonymous_user/0` in application startup in lib/hex_hub/application.ex
- [x] T012 [P] Add telemetry event definitions for anonymous publishing in lib/hex_hub/telemetry.ex
- [x] T013 [P] Add admin routes for publish config in lib/hex_hub_admin_web/router.ex
- [x] T014 [P] Create test file for PublishConfig module in test/hex_hub/publish_config_test.exs

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Configure Anonymous Publishing (Priority: P1) 🎯 MVP

**Goal**: Admin can toggle anonymous publishing setting via admin dashboard

**Independent Test**: Navigate to `/admin/publish-config`, toggle setting, verify it persists and is reflected in system behavior

### Tests for User Story 1

- [x] T015 [P] [US1] Create controller test file in test/hex_hub_admin_web/controllers/publish_config_controller_test.exs
- [x] T016 [P] [US1] Add test for `index/2` action showing current config in test/hex_hub_admin_web/controllers/publish_config_controller_test.exs
- [x] T017 [P] [US1] Add test for `update/2` action toggling setting in test/hex_hub_admin_web/controllers/publish_config_controller_test.exs
- [x] T018 [P] [US1] Add test for config persistence across requests in test/hex_hub_admin_web/controllers/publish_config_controller_test.exs

### Implementation for User Story 1

- [x] T019 [US1] Create PublishConfigController module in lib/hex_hub_admin_web/controllers/publish_config_controller.ex
- [x] T020 [US1] Implement `index/2` action showing config form in lib/hex_hub_admin_web/controllers/publish_config_controller.ex
- [x] T021 [US1] Implement `update/2` action saving config in lib/hex_hub_admin_web/controllers/publish_config_controller.ex
- [x] T022 [US1] Add telemetry event emission for config changes in lib/hex_hub_admin_web/controllers/publish_config_controller.ex
- [x] T023 [P] [US1] Create template directory lib/hex_hub_admin_web/controllers/publish_config_html/
- [x] T024 [US1] Create PublishConfigHTML module in lib/hex_hub_admin_web/controllers/publish_config_html.ex
- [x] T025 [US1] Create index.html.heex template with toggle form in lib/hex_hub_admin_web/controllers/publish_config_html/index.html.heex
- [x] T026 [US1] Add confirmation dialog JavaScript in lib/hex_hub_admin_web/controllers/publish_config_html/index.html.heex
- [x] T027 [US1] Add status badge (Enabled/Disabled) in lib/hex_hub_admin_web/controllers/publish_config_html/index.html.heex
- [x] T028 [US1] Add navigation link to admin sidebar in lib/hex_hub_admin_web/components/layouts/root.html.heex

**Checkpoint**: User Story 1 complete - admin can configure anonymous publishing

---

## Phase 4: User Story 2 - Publish Package Anonymously (Priority: P2)

**Goal**: When enabled, packages can be published without authentication, attributed to "anonymous" user

**Independent Test**: Enable anonymous publishing, submit package without API key, verify it appears with "anonymous" as publisher

### Tests for User Story 2

- [x] T029 [P] [US2] Add test for anonymous publish when enabled in test/hex_hub_web/controllers/api/release_controller_test.exs
- [x] T030 [P] [US2] Add test for publish rejection when disabled in test/hex_hub_web/controllers/api/release_controller_test.exs
- [x] T031 [P] [US2] Add test for authenticated publish still works in test/hex_hub_web/controllers/api/release_controller_test.exs
- [x] T032 [P] [US2] Add test for IP logging on anonymous publish in test/hex_hub_web/controllers/api/release_controller_test.exs

### Implementation for User Story 2

- [x] T033 [US2] Create OptionalAuthenticate plug in lib/hex_hub_web/plugs/optional_authenticate.ex
- [x] T034 [US2] Implement key extraction logic in OptionalAuthenticate plug in lib/hex_hub_web/plugs/optional_authenticate.ex
- [x] T035 [US2] Implement anonymous user assignment when enabled in lib/hex_hub_web/plugs/optional_authenticate.ex
- [x] T036 [US2] Add IP address logging via telemetry in lib/hex_hub_web/plugs/optional_authenticate.ex
- [x] T037 [US2] Create new pipeline `:api_auth_optional` in lib/hex_hub_web/router.ex
- [x] T038 [US2] Update publish routes to use optional auth pipeline in lib/hex_hub_web/router.ex
- [x] T039 [US2] Update `maybe_add_owner/2` to handle anonymous user in lib/hex_hub_web/controllers/api/release_controller.ex
- [x] T040 [US2] Add anonymous publish telemetry event in lib/hex_hub_web/controllers/api/release_controller.ex

**Checkpoint**: User Stories 1 AND 2 complete - full anonymous publishing functional

---

## Phase 5: User Story 3 - View Anonymous User in Admin (Priority: P3)

**Goal**: Anonymous user visible in admin with system user badge, cannot be deleted/modified

**Independent Test**: Navigate to admin users page, verify "anonymous" user appears with system badge, verify edit/delete blocked

### Tests for User Story 3

- [x] T041 [P] [US3] Add test for anonymous user in user list in test/hex_hub_admin_web/controllers/user_controller_test.exs
- [x] T042 [P] [US3] Add test for system user badge display in test/hex_hub_admin_web/controllers/user_controller_test.exs
- [x] T043 [P] [US3] Add test for delete prevention in test/hex_hub_admin_web/controllers/user_controller_test.exs
- [x] T044 [P] [US3] Add test for edit prevention in test/hex_hub_admin_web/controllers/user_controller_test.exs

### Implementation for User Story 3

- [x] T045 [US3] Add system user badge component in lib/hex_hub_admin_web/components/core_components.ex (using DaisyUI badge inline)
- [x] T046 [US3] Update user list template to show system badge in lib/hex_hub_admin_web/controllers/user_html/index.html.heex
- [x] T047 [US3] Update user show template with system user indicator in lib/hex_hub_admin_web/controllers/user_html/show.html.heex
- [x] T048 [US3] Add delete protection check in UserController in lib/hex_hub_admin_web/controllers/user_controller.ex
- [x] T049 [US3] Add edit protection check in UserController in lib/hex_hub_admin_web/controllers/user_controller.ex
- [x] T050 [US3] Update user form to disable fields for system users in lib/hex_hub_admin_web/controllers/user_html/edit.html.heex

**Checkpoint**: All user stories complete - full feature implemented

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Quality assurance and code cleanup

- [x] T051 Run `mix format` to ensure code formatting
- [x] T052 Run `mix credo --strict` and fix any warnings
- [x] T053 Run `mix dialyzer` and fix any type issues (warnings from test support only)
- [x] T054 Run `mix test` to verify all tests pass (389 tests, 0 failures)
- [x] T055 Validate quickstart.md scenarios manually (feature implemented per spec)
- [x] T056 Update CLAUDE.md with new patterns if introduced (no new patterns)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phases 3-5)**: All depend on Foundational phase completion
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

| Story | Depends On | Can Start After |
|-------|------------|-----------------|
| US1 (P1) | Foundational | Phase 2 complete |
| US2 (P2) | Foundational | Phase 2 complete |
| US3 (P3) | Foundational | Phase 2 complete |

**Note**: All user stories can run in parallel after Foundational phase. However, US2 should ideally complete after US1 for integration testing.

### Within Each User Story

1. Tests written FIRST (ensure they FAIL before implementation)
2. Context/plug logic before controllers
3. Controllers before templates
4. Core implementation before UI polish

### Parallel Opportunities

**Phase 1**: All tasks sequential (schema changes)

**Phase 2**: T012, T013, T014 can run in parallel

**Phase 3 (US1)**:
- T015-T018 (all tests) can run in parallel
- T023 can run in parallel with controller work

**Phase 4 (US2)**:
- T029-T032 (all tests) can run in parallel

**Phase 5 (US3)**:
- T041-T044 (all tests) can run in parallel

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together:
Task: "T015 Create controller test file"
Task: "T016 Add test for index/2 action"
Task: "T017 Add test for update/2 action"
Task: "T018 Add test for config persistence"

# After tests created, implement in sequence:
# T019 → T020 → T021 → T022 (controller)
# T023 → T024 → T025 → T026 → T027 (templates)
# T028 (navigation)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T002)
2. Complete Phase 2: Foundational (T003-T014)
3. Complete Phase 3: User Story 1 (T015-T028)
4. **STOP and VALIDATE**: Test `/admin/publish-config` independently
5. Deploy/demo if ready

### Incremental Delivery

1. **Setup + Foundational** → Foundation ready
2. **User Story 1** → Admin can configure setting (MVP!)
3. **User Story 2** → Anonymous publishing works end-to-end
4. **User Story 3** → Full admin visibility
5. **Polish** → Code quality and documentation

### Sequential Implementation (Recommended)

Given team size and feature scope:

```
Phase 1 → Phase 2 → US1 → US2 → US3 → Polish
```

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks
- [Story] label maps task to specific user story for traceability
- Each user story is independently testable after completion
- Telemetry events required per Constitution Principle VII
- DaisyUI/Tailwind CSS for all templates per Constitution
- Commit after each task or logical group

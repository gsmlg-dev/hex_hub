# Tasks: E2E Test Suite for hex.publish

**Input**: Design documents from `/specs/002-hex-publish-e2e/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, quickstart.md

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4, US5)
- Include exact file paths in descriptions

## Path Conventions

- **Elixir Phoenix project**: `e2e_test/`, `lib/`, `test/`
- Test files in `e2e_test/`
- Fixtures in `e2e_test/fixtures/`
- Support modules in `e2e_test/support/`

---

## Phase 1: Setup

**Purpose**: Project initialization and test infrastructure setup

- [x] T001 Create publish fixture project directory at e2e_test/fixtures/publish_project/
- [x] T002 [P] Create minimal lib module at e2e_test/fixtures/publish_project/lib/e2e_test_pkg.ex
- [x] T003 [P] Create .gitignore for fixture project at e2e_test/fixtures/publish_project/.gitignore
- [x] T004 Create mix.exs with hex publishing fields at e2e_test/fixtures/publish_project/mix.exs

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core test infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T005 Create publish_helper.ex module at e2e_test/support/publish_helper.ex with hex_publish_env/2 function
- [x] T006 Add test user and API key creation helpers to e2e_test/support/publish_helper.ex
- [x] T007 Add fixture project cleanup helper (remove deps/, _build/, mix.lock) to e2e_test/support/publish_helper.ex
- [x] T008 Extend server_helper.ex to export start_server/0 for dynamic port allocation at e2e_test/support/server_helper.ex
- [x] T009 Create base publish_test.exs file with setup_all block at e2e_test/publish_test.exs

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Basic Package Publishing (Priority: P1) 🎯 MVP

**Goal**: Verify that `mix hex.publish --yes` successfully publishes a package to HexHub

**Independent Test**: Run `HEX_API_URL=http://localhost:PORT/api mix hex.publish --yes` and verify package appears via API

### Implementation for User Story 1

- [x] T010 [US1] Implement test "publishes package successfully with valid credentials" in e2e_test/publish_test.exs
- [x] T011 [US1] Add assertion for exit code 0 on successful publish in e2e_test/publish_test.exs
- [x] T012 [US1] Add API verification step to check package exists via GET /api/packages/:name in e2e_test/publish_test.exs
- [x] T013 [US1] Add tarball download verification via GET /api/packages/:name/releases/:version/download in e2e_test/publish_test.exs
- [x] T014 [US1] Run test and verify it passes with `mix test.e2e e2e_test/publish_test.exs --only us1`

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Authentication and API Key Validation (Priority: P1)

**Goal**: Verify authentication is required and API key permissions are enforced

**Independent Test**: Attempt publish with missing/invalid/read-only API keys and verify appropriate errors

### Implementation for User Story 2

- [x] T015 [US2] Implement test "fails with 401 when no API key provided" in e2e_test/publish_test.exs
- [x] T016 [US2] Implement test "fails with 401 when invalid API key provided" in e2e_test/publish_test.exs
- [x] T017 [US2] Add helper to create read-only API key in e2e_test/support/publish_helper.ex
- [x] T018 [US2] Implement test "fails with 403 when read-only API key provided" in e2e_test/publish_test.exs
- [x] T019 [US2] Run tests and verify all pass with `mix test.e2e e2e_test/publish_test.exs --only us2`

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Package Version Management (Priority: P2)

**Goal**: Verify multiple versions can be published and both remain accessible

**Independent Test**: Publish v0.1.0 then v0.2.0 and verify both versions accessible via API

### Implementation for User Story 3

- [x] T020 [US3] Add helper to update fixture project version in e2e_test/support/publish_helper.ex
- [x] T021 [US3] Implement test "publishes multiple versions of same package" in e2e_test/publish_test.exs
- [x] T022 [US3] Add assertion to verify both versions appear in package metadata in e2e_test/publish_test.exs
- [x] T023 [US3] Run tests and verify all pass with `mix test.e2e e2e_test/publish_test.exs --only us3`

**Checkpoint**: At this point, User Stories 1, 2, AND 3 should all work independently

---

## Phase 6: User Story 4 - Documentation Publishing (Priority: P3)

**Goal**: Verify documentation can be published with packages (out of MVP scope - deferred)

**Independent Test**: Publish package with ExDoc and verify docs are accessible

### Implementation for User Story 4

- [ ] T024 [US4] Add ex_doc dependency to fixture project mix.exs (deferred - would break other tests without deps.get)
- [x] T025 [US4] Create minimal @moduledoc in fixture module for docs generation at e2e_test/fixtures/publish_project/lib/e2e_test_pkg.ex
- [x] T026 [US4] Implement test "publishes package with documentation" in e2e_test/publish_test.exs (marked @skip - deferred)
- [x] T027 [US4] Add assertion to verify docs tarball accessible via /api/packages/:name/releases/:version/docs/download in e2e_test/publish_test.exs (in T026)
- [ ] T028 [US4] Run tests and verify all pass with `mix test.e2e e2e_test/publish_test.exs --only us4` (skipped - deferred)

**Checkpoint**: At this point, User Stories 1-4 should all work independently

---

## Phase 7: User Story 5 - Error Handling and Validation (Priority: P2)

**Goal**: Verify clear error messages for invalid publish attempts

**Independent Test**: Attempt publish with invalid configurations and verify error messages

### Implementation for User Story 5

- [x] T029 [US5] Create invalid fixture (no version) at e2e_test/fixtures/invalid_publish_project/
- [x] T030 [US5] Implement test "returns validation error for missing required fields" in e2e_test/publish_test.exs
- [x] T031 [US5] Implement test "returns validation error for invalid version format" in e2e_test/publish_test.exs (combined with T030)
- [x] T032 [US5] Add assertion to verify error message is clear and actionable in e2e_test/publish_test.exs
- [x] T033 [US5] Run tests and verify all pass with `mix test.e2e e2e_test/publish_test.exs --only us5`

**Checkpoint**: All user stories should now be independently functional

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Quality assurance and documentation

- [x] T034 Add @moduletag for each user story (us1, us2, us3, us4, us5) in e2e_test/publish_test.exs
- [x] T035 [P] Run mix format on all new files
- [x] T036 [P] Run mix credo --strict to verify no issues
- [x] T037 Run full E2E test suite 3 times to verify no flaky tests with `for i in 1 2 3; do mix test.e2e; done`
- [x] T038 Update CLAUDE.md with E2E publish test patterns if needed
- [x] T039 Run quickstart.md verification steps manually

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-7)**: All depend on Foundational phase completion
  - User stories can proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Phase 8)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 3 (P2)**: Can start after Foundational (Phase 2) - Builds on US1 patterns but independently testable
- **User Story 4 (P3)**: Can start after Foundational (Phase 2) - May extend fixture but independently testable
- **User Story 5 (P2)**: Can start after Foundational (Phase 2) - Uses different fixture, independently testable

### Within Each User Story

- Infrastructure (helpers) before tests
- Core implementation before edge case handling
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks T002, T003 can run in parallel
- US1 and US2 can be implemented in parallel (both P1)
- US3 and US5 can be implemented in parallel (both P2, different concerns)
- Polish tasks T035, T036 can run in parallel

---

## Parallel Example: User Stories 1 and 2

```bash
# After Foundational phase is complete, launch US1 and US2 in parallel:

# Developer A works on US1:
Task: "Implement test 'publishes package successfully' in e2e_test/publish_test.exs"
Task: "Add API verification step in e2e_test/publish_test.exs"

# Developer B works on US2:
Task: "Implement test 'fails with 401 when no API key' in e2e_test/publish_test.exs"
Task: "Implement test 'fails with 403 when read-only key' in e2e_test/publish_test.exs"
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (Basic Publishing)
4. Complete Phase 4: User Story 2 (Authentication)
5. **STOP and VALIDATE**: Run `mix test.e2e` and verify 5+ tests pass
6. Deploy/demo if ready - core publishing E2E coverage is complete

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP! Basic publish works)
3. Add User Story 2 → Test independently → Deploy/Demo (Auth verified)
4. Add User Story 3 → Test independently → Deploy/Demo (Multi-version works)
5. Add User Story 5 → Test independently → Deploy/Demo (Error handling works)
6. Add User Story 4 → Test independently → Deploy/Demo (Docs work)
7. Each story adds confidence without breaking previous functionality

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (Basic Publishing)
   - Developer B: User Story 2 (Authentication)
3. After US1/US2 complete:
   - Developer A: User Story 3 (Version Management)
   - Developer B: User Story 5 (Error Handling)
4. Finally: Developer A or B: User Story 4 (Documentation)

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Total: 39 tasks across 8 phases
- MVP scope: 14 tasks (Setup + Foundational + US1 + US2)

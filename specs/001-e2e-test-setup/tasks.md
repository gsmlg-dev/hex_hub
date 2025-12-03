# Tasks: E2E Test Infrastructure for Hex Package Proxy

**Input**: Design documents from `/specs/001-e2e-test-setup/`
**Prerequisites**: plan.md (required), spec.md (required), research.md

**Tests**: No explicit test tasks - this feature IS test infrastructure. Validation is through running `mix test.e2e` itself.

**Organization**: Tasks grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

Based on plan.md:
- E2E tests: `e2e_test/` at repository root
- Mix task: `lib/mix/tasks/`
- GitHub Actions: `.github/workflows/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create E2E test directory structure and foundational files

- [x] T001 Create e2e_test/ directory structure at repository root
- [x] T002 [P] Create e2e_test/support/ directory for helper modules
- [x] T003 [P] Create e2e_test/fixtures/ directory for test project fixture

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Create e2e_test/test_helper.exs with Mnesia initialization and storage config
- [x] T005 [P] Create e2e_test/support/e2e_case.ex base test case module with ExUnit setup
- [x] T006 [P] Create e2e_test/support/server_helper.ex with start_server/0 and stop_server/0 functions
- [x] T007 Create e2e_test/fixtures/test_project/mix.exs with {:jason, "~> 1.4"} dependency
- [x] T008 [P] Create e2e_test/fixtures/test_project/lib/test_project.ex empty module
- [x] T009 [P] Create e2e_test/fixtures/test_project/.gitignore for _build, deps, mix.lock

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Developer Validates Hex Proxy Functionality (Priority: P1) 🎯 MVP

**Goal**: Enable developers to run `mix test.e2e` to validate the complete package proxy workflow

**Independent Test**: Run `mix test.e2e` and observe packages fetched through local HexHub instance

### Implementation for User Story 1

- [x] T010 [US1] Create lib/mix/tasks/test.e2e.ex Mix task with @shortdoc and run/1 function
- [x] T011 [US1] Implement ExUnit configuration in Mix task to use e2e_test/ directory
- [x] T012 [US1] Add support for passing ExUnit args (--trace, --seed) through Mix task
- [x] T013 [US1] Implement dynamic port allocation in server_helper.ex using port: 0 config
- [x] T014 [US1] Implement HEX_MIRROR and HEX_UNSAFE_REGISTRY environment setup in server_helper.ex
- [x] T015 [US1] Create e2e_test/proxy_test.exs with setup_all block for server lifecycle
- [x] T016 [US1] Implement test case: fetch jason package through HexHub proxy in proxy_test.exs
- [x] T017 [US1] Implement resource cleanup in on_exit callback in proxy_test.exs
- [x] T018 [US1] Add timeout configuration (60s default) to proxy_test.exs test cases
- [x] T019 [US1] Add clear error messages for server startup failure in server_helper.ex
- [x] T020 [US1] Add clear error messages for package fetch failure in proxy_test.exs

**Checkpoint**: User Story 1 complete - `mix test.e2e` runs and validates proxy functionality

---

## Phase 4: User Story 2 - CI Pipeline Runs E2E Tests Automatically (Priority: P2)

**Goal**: GitHub Actions workflow runs E2E tests on PRs to main/develop and pushes to main

**Independent Test**: Create a PR and verify E2E workflow executes and reports results

### Implementation for User Story 2

- [x] T021 [US2] Create .github/workflows/e2e.yml with workflow name "E2E Tests"
- [x] T022 [US2] Configure triggers: push to main, pull_request to main/develop branches
- [x] T023 [US2] Add job setup: ubuntu-latest, erlef/setup-beam@v1 with Elixir 1.18, OTP 28
- [x] T024 [US2] Add dependency caching for deps/ and _build/ directories
- [x] T025 [US2] Add steps: checkout, setup-beam, deps.get, mix test.e2e
- [x] T026 [US2] Configure job timeout (15 minutes) and test timeout in workflow

**Checkpoint**: User Story 2 complete - CI runs E2E tests automatically on PRs

---

## Phase 5: User Story 3 - Developer Runs E2E Tests Locally (Priority: P3)

**Goal**: E2E tests run in isolation from unit tests - `mix test` excludes e2e_test/

**Independent Test**: Run `mix test` and verify 0 E2E tests execute; run `mix test.e2e` and verify 0 unit tests execute

### Implementation for User Story 3

- [x] T027 [US3] Verify mix.exs elixirc_paths does NOT include e2e_test/ for any environment
- [x] T028 [US3] Verify Mix task compiles e2e_test/support/ files before running tests
- [x] T029 [US3] Add documentation comment in lib/mix/tasks/test.e2e.ex explaining isolation
- [x] T030 [US3] Test isolation: run `mix test` and confirm e2e_test/ files are not executed

**Checkpoint**: User Story 3 complete - Tests are properly isolated

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final validation and cleanup

- [x] T031 [P] Run `mix format` on all new files in e2e_test/ and lib/mix/tasks/
- [x] T032 [P] Run `mix credo --strict` and fix any issues in new files
- [x] T033 Validate full E2E flow: start server, fetch package, cleanup resources
- [x] T034 Update .formatter.exs to include e2e_test/ in format paths if needed
- [x] T035 Run quickstart.md validation - execute all documented commands

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational phase
- **User Story 2 (Phase 4)**: Depends on User Story 1 (needs `mix test.e2e` to exist)
- **User Story 3 (Phase 5)**: Depends on User Story 1 (needs tests to isolate)
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No story dependencies
- **User Story 2 (P2)**: Depends on US1 completion (CI needs working `mix test.e2e`)
- **User Story 3 (P3)**: Depends on US1 completion (isolation verification needs working tests)

### Within Each Phase

- Tasks marked [P] can run in parallel within their phase
- Non-[P] tasks should run sequentially
- All tasks in a phase complete before next phase begins

### Parallel Opportunities

**Phase 1** (all parallel):
```
T001, T002, T003 can run together (different directories)
```

**Phase 2** (partial parallel):
```
T004 must complete first (test_helper.exs)
Then T005, T006, T008, T009 can run in parallel (different files)
T007 should complete before T008 (mix.exs before lib/)
```

**Phase 3** (mostly sequential):
```
T010-T012: Mix task implementation (sequential - same file)
T013-T014: server_helper.ex (sequential - same file)
T015-T020: proxy_test.exs (sequential - same file)
```

**Phase 4** (mostly sequential):
```
T021-T026: All in e2e.yml (sequential - same file)
```

---

## Parallel Example: Phase 2 Foundational

```bash
# After T004 completes, launch these in parallel:
Task: "Create e2e_test/support/e2e_case.ex"
Task: "Create e2e_test/support/server_helper.ex"
Task: "Create e2e_test/fixtures/test_project/lib/test_project.ex"
Task: "Create e2e_test/fixtures/test_project/.gitignore"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Run `mix test.e2e` - should fetch jason through HexHub
5. Can deploy/use immediately - local E2E testing works!

### Incremental Delivery

1. **Setup + Foundational** → Directory structure ready
2. **User Story 1** → `mix test.e2e` works locally (MVP!)
3. **User Story 2** → CI automation added
4. **User Story 3** → Isolation verified
5. Each story adds value without breaking previous functionality

### Suggested Execution

For a single developer:
1. P1 → P2 → P3 (sequential by priority)
2. Stop after P1 if immediate local testing is sufficient
3. Add P2 when CI integration is needed

---

## Task Summary

| Phase | Tasks | Parallel Opportunities |
|-------|-------|----------------------|
| Phase 1: Setup | 3 | 3 |
| Phase 2: Foundational | 6 | 4 |
| Phase 3: User Story 1 | 11 | 0 |
| Phase 4: User Story 2 | 6 | 0 |
| Phase 5: User Story 3 | 4 | 0 |
| Phase 6: Polish | 5 | 2 |
| **Total** | **35** | **9** |

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story is independently testable after completion
- Commit after each task or logical group
- Stop at any checkpoint to validate progress
- FR-001 through FR-010 from spec.md are covered by tasks across all user stories

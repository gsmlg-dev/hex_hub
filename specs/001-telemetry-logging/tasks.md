# Tasks: Telemetry-Based Logging System

**Input**: Design documents from `/specs/001-telemetry-logging/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, quickstart.md

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Elixir Phoenix project**: `lib/`, `test/`, `config/`
- New modules in `lib/hex_hub/telemetry/`
- Tests in `test/hex_hub/telemetry/`

---

## Phase 1: Setup

**Purpose**: Project initialization and telemetry logging infrastructure

- [x] T001 Create telemetry subdirectory at lib/hex_hub/telemetry/
- [x] T002 [P] Add telemetry logging configuration section to config/config.exs
- [x] T003 [P] Add runtime environment variable parsing to config/runtime.exs for LOG_CONSOLE_* and LOG_FILE_*
- [x] T004 Create test directory structure at test/hex_hub/telemetry/

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T005 Implement JSON log formatter module at lib/hex_hub/telemetry/formatter.ex with format_event/3 function
- [x] T006 Implement sensitive data redaction in lib/hex_hub/telemetry/formatter.ex with @sensitive_keys denylist
- [x] T007 Add log helper function to lib/hex_hub/telemetry.ex for simplified event emission (HexHub.Telemetry.log/4)
- [x] T008 [P] Create formatter tests at test/hex_hub/telemetry/formatter_test.exs
- [x] T009 Update lib/hex_hub/application.ex to register telemetry handlers on startup

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Console Logging via Telemetry (Priority: P1) 🎯 MVP

**Goal**: All application events emitted through telemetry and displayed in console with JSON formatting

**Independent Test**: Start application, trigger events (package publish, upstream request, auth failure), verify JSON log entries appear in console

### Implementation for User Story 1

- [x] T010 [US1] Implement console log handler at lib/hex_hub/telemetry/log_handler.ex with handle_event/4 callback
- [x] T011 [US1] Add handler attachment logic for console handler in lib/hex_hub/application.ex
- [x] T012 [US1] Create console handler tests at test/hex_hub/telemetry/log_handler_test.exs
- [x] T013 [P] [US1] Refactor lib/hex_hub/packages.ex - replace Logger calls with telemetry events
- [x] T014 [P] [US1] Refactor lib/hex_hub/upstream.ex - replace Logger calls with telemetry events
- [x] T015 [P] [US1] Refactor lib/hex_hub/storage.ex - replace Logger calls with telemetry events
- [x] T016 [P] [US1] Refactor lib/hex_hub/clustering.ex - replace Logger calls with telemetry events
- [x] T017 [P] [US1] Refactor lib/hex_hub/upstream_config.ex - replace Logger calls with telemetry events
- [x] T018 [P] [US1] Refactor lib/hex_hub_web/controllers/api/registry_controller.ex - replace Logger calls with telemetry events
- [x] T019 [P] [US1] Refactor lib/hex_hub_web/controllers/mcp_controller.ex - replace Logger calls with telemetry events
- [x] T020 [P] [US1] Refactor lib/hex_hub/mcp/server.ex - replace Logger calls with telemetry events
- [x] T021 [P] [US1] Refactor lib/hex_hub/mcp/handler.ex - replace Logger calls with telemetry events
- [x] T022 [P] [US1] Refactor lib/hex_hub/mcp/transport.ex - replace Logger calls with telemetry events
- [x] T023 [P] [US1] Refactor lib/hex_hub/mcp/http_controller.ex - replace Logger calls with telemetry events
- [x] T024 [P] [US1] Refactor lib/hex_hub/mcp/tools.ex - replace Logger calls with telemetry events
- [x] T025 [P] [US1] Refactor lib/hex_hub/mcp/tools/packages.ex - replace Logger calls with telemetry events
- [x] T026 [P] [US1] Refactor lib/hex_hub/mcp/tools/releases.ex - replace Logger calls with telemetry events
- [x] T027 [P] [US1] Refactor lib/hex_hub/mcp/tools/repositories.ex - replace Logger calls with telemetry events
- [x] T028 [P] [US1] Refactor lib/hex_hub/mcp/tools/dependencies.ex - replace Logger calls with telemetry events
- [x] T029 [P] [US1] Refactor lib/hex_hub/mcp/tools/documentation.ex - replace Logger calls with telemetry events
- [x] T030 [US1] Run mix test to verify all existing tests still pass after Logger refactoring

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - File-Based Logging via Telemetry (Priority: P2)

**Goal**: Configure system to write logs to files for historical retention

**Independent Test**: Enable file logging via config, generate events, verify log file created with JSON entries

### Implementation for User Story 2

- [x] T031 [US2] Implement file log handler GenServer at lib/hex_hub/telemetry/file_handler.ex
- [x] T032 [US2] Add file open/append logic with error handling in lib/hex_hub/telemetry/file_handler.ex
- [x] T033 [US2] Add handler attachment logic for file handler in lib/hex_hub/application.ex (conditional on config)
- [x] T034 [US2] Implement graceful fallback when file path not writable in lib/hex_hub/telemetry/file_handler.ex
- [x] T035 [US2] Create file handler tests at test/hex_hub/telemetry/file_handler_test.exs
- [x] T036 [US2] Add concurrent write safety tests to test/hex_hub/telemetry/file_handler_test.exs

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Configurable Log Levels (Priority: P3)

**Goal**: Configure which log levels are output to each destination independently

**Independent Test**: Set different log levels for console and file, verify filtering works per destination

### Implementation for User Story 3

- [x] T037 [US3] Add log level comparison logic to lib/hex_hub/telemetry/log_handler.ex
- [x] T038 [US3] Add log level comparison logic to lib/hex_hub/telemetry/file_handler.ex
- [x] T039 [US3] Update config/runtime.exs to support LOG_CONSOLE_LEVEL and LOG_FILE_LEVEL environment variables
- [x] T040 [US3] Create log level filtering tests at test/hex_hub/telemetry/log_handler_test.exs
- [x] T041 [US3] Create log level filtering tests at test/hex_hub/telemetry/file_handler_test.exs

**Checkpoint**: All user stories should now be independently functional

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T042 Update CLAUDE.md with telemetry logging patterns and examples
- [x] T043 Add edge case handling for nil/invalid event data in lib/hex_hub/telemetry/formatter.ex
- [x] T044 Add duplicate handler prevention logic in lib/hex_hub/application.ex
- [x] T045 [P] Run mix format to ensure code formatting compliance
- [x] T046 [P] Run mix credo --strict to verify static analysis passes
- [x] T047 [P] Run mix dialyzer to verify type checking passes
- [x] T048 Run full test suite with mix test to verify no regressions
- [x] T049 Run quickstart.md verification steps manually

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Phase 6)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Shares formatter with US1 but independently testable
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Extends US1 and US2 handlers but independently testable

### Within Each User Story

- Handler implementation before usage in application
- Core implementation before edge case handling
- Implementation before tests (unless TDD requested)
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel (T002, T003)
- All Foundational tasks marked [P] can run in parallel (T008)
- Once Foundational phase completes, Logger refactoring tasks T013-T029 can ALL run in parallel
- File handler tests T035, T036 can run in parallel

---

## Parallel Example: User Story 1 Logger Refactoring

```bash
# Launch all Logger refactoring tasks together (17 files):
Task: "Refactor lib/hex_hub/packages.ex - replace Logger calls with telemetry events"
Task: "Refactor lib/hex_hub/upstream.ex - replace Logger calls with telemetry events"
Task: "Refactor lib/hex_hub/storage.ex - replace Logger calls with telemetry events"
# ... (14 more files in parallel)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (Console Logging)
4. **STOP and VALIDATE**: Test console logging independently
5. Deploy/demo if ready - operators can now see telemetry events in console

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Test independently → Deploy/Demo (file logging added)
4. Add User Story 3 → Test independently → Deploy/Demo (configurable levels)
5. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (console handler + all 17 Logger refactors)
   - Developer B: User Story 2 (file handler) - can start after formatter exists
   - Developer C: User Story 3 (level filtering) - can start after handlers exist
3. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- 17 files need Logger refactoring - all can run in parallel once handler is ready

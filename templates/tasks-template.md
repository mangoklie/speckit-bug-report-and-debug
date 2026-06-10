---
description: "Task list template for bug fix implementation"
---

# Tasks: [BUG-NNN] — [Bug Title]

**Bug report**: `bugs/[BUG-NNN-YYYY-MM-DD-slug].md`
**Plan**: `bugs/[BUG-NNN]-plan.md`
**Branch**: `[branch-name]`

**Organization**: Tasks are grouped into two tracks — Fix (direct remediation) and Prevention (regression guard) — so the fix can be reviewed and merged independently of the prevention work if needed.

## Format: `[BUG-NNN-TNNN] [P?] [TRACK] Description — file/path`

- **[P]**: Can run in parallel (different files, no dependency on incomplete tasks)
- **[FIX]**: Fix Track — directly resolves the root cause or a pattern-sweep occurrence
- **[PREV]**: Prevention Track — stops this bug class from recurring
- Include exact file paths (and line numbers where applicable) in descriptions

<!--
  ============================================================================
  IMPORTANT: The tasks below are SAMPLE TASKS for illustration purposes only.

  The speckit.bug-debug.tasks command MUST replace these with actual tasks based on:
  - Root cause location from the bug report's ## Investigation section
  - Pattern sweep occurrences from the plan's ## Fix Scope section
  - Prevention strategy from the plan's ## Fix Scope / Prevention strategy

  Tasks MUST be ordered by dependency within each track:
  - Fix Track: primary fix first, pattern-sweep fixes next (parallel if different files),
    validation task always last
  - Prevention Track: regression test first, spec clarification second (if applicable),
    guard/lint rule third (if applicable)

  DO NOT keep these sample tasks in the generated tasks file.
  ============================================================================
-->

---

## Phase 1: Fix Track

**Purpose**: Directly resolve the confirmed root cause and all pattern-sweep occurrences.

**Input**: Root cause location, pattern sweep results, and chosen fix approach from `bugs/[BUG-NNN]-plan.md`.

- [ ] [BUG-NNN-T001] [FIX] Fix root cause at primary location — src/[module]/[file]:[line]
- [ ] [BUG-NNN-T002] [P] [FIX] Fix same pattern in [other module] — src/[other-module]/[file]:[line]
- [ ] [BUG-NNN-T003] [FIX] Validate fix against reproduction steps from investigation — [test/script/manual steps reference]

**Checkpoint**: Fix track complete — root cause resolved at all identified locations.
Verify against reproduction steps before proceeding to Prevention Track.

---

## Phase 2: Prevention Track

**Purpose**: Prevent this class of bug from recurring.

**Input**: Prevention strategy from `bugs/[BUG-NNN]-plan.md` Fix Scope section.

- [ ] [BUG-NNN-T004] [PREV] Add regression test asserting [what] — tests/[path]/[file]
- [ ] [BUG-NNN-T005] [PREV] Clarify spec section [X] to close gap — specs/[path]/[file]   ← omit if no spec gap
- [ ] [BUG-NNN-T006] [PREV] Add [guard/lint rule description] — [config/location]          ← omit if plan does not call for one

**Checkpoint**: Prevention track complete — regression test in place, spec updated if applicable, guard rule added if called for.

---

## Dependencies & Execution Order

### Track Dependencies

- **Fix Track (Phase 1)**: No external dependencies — starts immediately
- **Prevention Track (Phase 2)**: Can begin once the root cause fix (T001) is understood; regression test can often be written in parallel with pattern-sweep fixes

### Within Fix Track

- Primary fix first; pattern-sweep fixes can be [P] if they touch different files
- Validation task (always the last T00X in Phase 1) depends on all fix tasks being complete — never mark [P]

### Within Prevention Track

- Regression test: write first and verify it reproduces the bug before the fix makes it pass
- Spec clarification: independent of the test — can be [P] if the files differ
- Guard/lint rule: independent of both — can be [P] if the config file differs from the test file

### Parallel Opportunities

- Pattern-sweep fix tasks marked [P]: same change in different files — safe to parallelize
- Prevention tasks (test, spec, guard) are all independent of each other and can all be [P]

---

## Parallel Example: Fix Track

```
# Launch pattern-sweep fixes together (if all [P]):
Task: "Fix same pattern in [other module] — src/[other-module]/[file]:[line]"
Task: "Fix same pattern in [another module] — src/[another-module]/[file]:[line]"

# Then run validation (depends on all fixes):
Task: "Validate fix against reproduction steps"
```

---

## Implementation Strategy

### Fix First, Prevent Second

1. Complete Phase 1: Fix Track
   - Primary fix at root cause location
   - Pattern-sweep fixes (in parallel if marked [P])
   - Validate fix against reproduction steps — **STOP if validation fails**
2. Complete Phase 2: Prevention Track
   - Regression test (write to fail first, then confirm it passes after fix)
   - Spec clarification if applicable
   - Guard/lint rule if applicable

### If Validation Fails

Stop at the validation task. Do not proceed to Prevention Track.
Re-open the plan with `speckit.bug-debug.plan BUG-NNN` and revise the fix approach.

---

## Notes

- [P] tasks = different files, no shared dependency — safe to parallelize
- [FIX] tasks come before [PREV] tasks in the ID sequence
- Never pre-check a task checkbox — checkboxes are marked done during implementation
- Regression test should reproduce the bug before the fix is applied (TDD preferred)
- Pattern sweep fixes should be reviewed together in one PR if possible
- Do not generate tasks for hardening unrelated to this bug's confirmed root cause

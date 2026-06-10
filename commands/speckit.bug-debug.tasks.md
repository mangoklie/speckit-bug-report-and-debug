---
description: Create dependency-ordered implementation tasks for a bug fix, stored in bugs/BUG-NNN-tasks.md.
handoffs:
  - label: Implement Fix
    agent: speckit.implement
    prompt: Start implementing the bug fix tasks in order
    send: true
scripts:
  sh: scripts/bash/setup-bug-tasks.sh --json
  ps: scripts/powershell/setup-bug-tasks.ps1 -Json
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Pre-Execution Checks

**Check for extension hooks (before tasks generation)**:
- Check if `.specify/extensions.yml` exists in the project root.
- If it exists, read it and look for entries under the `hooks.before_tasks` key.
- If the YAML cannot be parsed or is invalid, skip hook checking silently and continue normally.
- Filter out hooks where `enabled` is explicitly `false`. Treat hooks without an `enabled` field as enabled by default.
- For each remaining hook, do **not** attempt to interpret or evaluate hook `condition` expressions:
  - If the hook has no `condition` field, or it is null/empty, treat the hook as executable.
  - If the hook defines a non-empty `condition`, skip the hook and leave condition evaluation to the HookExecutor implementation.
- For each executable hook, output the following based on its `optional` flag:
  - **Optional hook** (`optional: true`):
    ```
    ## Extension Hooks

    **Optional Pre-Hook**: {extension}
    Command: `/{command}`
    Description: {description}

    Prompt: {prompt}
    To execute: `/{command}`
    ```
  - **Mandatory hook** (`optional: false`):
    ```
    ## Extension Hooks

    **Automatic Pre-Hook**: {extension}
    Executing: `/{command}`
    EXECUTE_COMMAND: {command}

    Wait for the result of the hook command before proceeding to the Outline.
    ```
- If no hooks are registered or `.specify/extensions.yml` does not exist, skip silently.

## Outline

1. **Resolve bug reference** from `$ARGUMENTS` (`BUG-NNN`, partial name, or file path). If ambiguous, list candidates and ask the user to confirm.

2. **Setup**: Run `{SCRIPT} <BUG_REF>` from repo root and parse JSON for `BUG_REPORT`, `BUG_PLAN`, `BUG_TASKS`, `BUGS_DIR`, `BRANCH`, `TASKS_TEMPLATE`.
   - If the script errors because `BUG_PLAN` does not exist, stop and instruct the user to run `speckit.bug-debug.plan BUG-NNN` first.
   - All subsequent file paths come from the script output; do not hard-code paths.

3. **Load context**: Read:
   - `BUG_REPORT` — root cause, pattern sweep results, reproduction steps
   - `BUG_PLAN` — fix scope, affected files, prevention strategy, design decisions
   - `.specify/memory/constitution.md` — project principles; every task must comply
   - `TASKS_TEMPLATE` — structural scaffold (if non-empty; otherwise use Task Generation Rules structure below)

4. **Generate `BUG_TASKS`** — dependency-ordered implementation tasks. Use `TASKS_TEMPLATE` as structure. Fill with actual tasks derived from the plan, organized into two tracks:

   **Fix Track (Phase 1)** — tasks that directly resolve the root cause:
   - One task per affected location (root cause fix + each pattern-sweep occurrence if the plan covers them), ordered by dependency
   - Pattern-sweep fix tasks may be marked [P] if they touch different files with no shared dependency
   - Final fix-track task: validate fix against the exact reproduction steps from the investigation (never mark [P])

   **Prevention Track (Phase 2)** — tasks that stop this class of bug from recurring:
   - Regression test: one task describing what to assert and where the test belongs
   - Spec clarification (only if plan flagged a spec gap): one task naming the spec section to amend
   - Guard/lint rule (only if plan explicitly calls for one): one task describing the rule and location

   Do not generate tasks for hypothetical hardening unrelated to this bug's confirmed root cause.
   Do not duplicate tasks already in the plan document itself.
   All tasks must follow the checklist format in Task Generation Rules below.

5. **Update `BUG_REPORT`** — replace or update the `## Fix Plan` stub:

   ```
   ## Fix Plan

   **Plan**:  bugs/BUG-NNN-plan.md
   **Tasks**: bugs/BUG-NNN-tasks.md
   **Status**: ready to implement
   ```

## Mandatory Post-Execution Hooks

**You MUST complete this section before reporting completion to the user.**

Check if `.specify/extensions.yml` exists in the project root.
- If it does not exist, or no hooks are registered under `hooks.after_tasks`, skip to the Completion Report.
- If it exists, read it and look for entries under the `hooks.after_tasks` key.
- If the YAML cannot be parsed or is invalid, skip hook checking silently and continue to the Completion Report.
- Filter out hooks where `enabled` is explicitly `false`. Treat hooks without an `enabled` field as enabled by default.
- For each remaining hook, do **not** attempt to interpret or evaluate hook `condition` expressions:
  - If the hook has no `condition` field, or it is null/empty, treat the hook as executable.
  - If the hook defines a non-empty `condition`, skip the hook and leave condition evaluation to the HookExecutor implementation.
- For each executable hook, output the following based on its `optional` flag:
  - **Mandatory hook** (`optional: false`) — **You MUST emit `EXECUTE_COMMAND:` for each mandatory hook**:
    ```
    ## Extension Hooks

    **Automatic Hook**: {extension}
    Executing: `/{command}`
    EXECUTE_COMMAND: {command}
    ```
  - **Optional hook** (`optional: true`):
    ```
    ## Extension Hooks

    **Optional Hook**: {extension}
    Command: `/{command}`
    Description: {description}

    Prompt: {prompt}
    To execute: `/{command}`
    ```

## Completion Report

```
Tasks created: <BUG_TASKS>  (N tasks: N fix + N prevention)
Branch:   <BRANCH>
Template: templates/tasks-template.md

Parallel opportunities:
  [list any [P]-marked tasks]

Start implementing:
  speckit implement BUG-NNN-T001
```

## Task Generation Rules

**CRITICAL**: Tasks MUST be organized by track (Fix first, then Prevention) with dependency order within each track.

### Checklist Format (REQUIRED)

Every task MUST strictly follow this format:

```text
- [ ] [BUG-NNN-T001] [P?] [TRACK] Description — file/path
```

**Format Components**:

1. **Checkbox**: ALWAYS start with `- [ ]`
2. **Task ID**: `BUG-NNN-T` followed by zero-padded sequential number (`T001`, `T002`…) in dependency-execution order across both tracks
3. **[P] marker**: Include ONLY if task is parallelizable (touches different files, no dependency on an incomplete earlier task)
4. **[TRACK] label**: REQUIRED on every task
   - Fix Track: `[FIX]`
   - Prevention Track: `[PREV]`
5. **Description**: Clear action verb + exact file path after ` — ` (include line number where applicable)

**Examples**:

- ✅ CORRECT: `- [ ] [BUG-007-T001] [FIX] Fix null-check in auth middleware — src/middleware/auth.ts:42`
- ✅ CORRECT: `- [ ] [BUG-007-T002] [P] [FIX] Fix same pattern in session handler — src/session/handler.ts:17`
- ✅ CORRECT: `- [ ] [BUG-007-T003] [FIX] Validate fix against reproduction steps — tests/repro/bug-007.sh`
- ✅ CORRECT: `- [ ] [BUG-007-T004] [PREV] Add regression test for null token path — tests/middleware/auth.test.ts`
- ❌ WRONG: `- [ ] Fix null-check` (missing ID, track label, file path)
- ❌ WRONG: `- [x] [BUG-007-T001] [FIX] Fix auth` (pre-checked; missing file path)
- ❌ WRONG: `[BUG-007-T001] [FIX] Fix auth — src/auth.ts` (missing checkbox)
- ❌ WRONG: `- [ ] [BUG-007-T001] Fix auth — src/auth.ts` (missing track label)

### Task Organization

- **Fix Track (Phase 1)**: Primary fix at root cause, then pattern-sweep fixes (mark [P] if different files, no shared dependency), validation task last (never [P])
- **Prevention Track (Phase 2)**: Regression test first, spec clarification second (if applicable), guard/lint rule third (if applicable)
- Task IDs are sequential across both tracks — T001, T002… through all tasks regardless of track

## Key Rules

- Use absolute paths for filesystem operations; use project-relative paths in documentation
- Do NOT read source code beyond what is needed to verify file paths and dependency names
- Do NOT write or suggest any implementation code in the tasks file

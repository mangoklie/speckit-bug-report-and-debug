# speckit.bug-debug.iterate

Orchestrate the full bug lifecycle in a single session: report → investigate → plan → tasks. Human checkpoints between each phase ensure quality and control.

This command is a workflow coordinator. It does not add new behavior — it sequences `speckit.bug-debug.report`, `speckit.bug-debug.investigate`, `speckit.bug-debug.plan`, and `speckit.bug-debug.tasks` with explicit pause points.

---

## Parameters

Parse the user's input for:

- **Bug reference or description** (optional): If a `BUG-NNN` or file path is provided, skip the report phase and start from investigate. If a description is provided, start from report. If nothing is provided, enter interactive report intake.
- `--from=report|investigate|plan|tasks` — force a specific starting phase
- `--severity=critical|high|medium|low` — passed through to report
- `--ticket=XXX` — passed through to report
- `--feature=NAME` — passed through to report
- `--deep` — passed through to investigate
- `--all-occurrences` — passed through to tasks
- `--update-spec` — passed through to tasks

---

## Lifecycle

### Phase A — Report

**Skip if**: a `BUG-NNN` reference was provided or `--from=investigate|plan|tasks`.

Execute the full `speckit.bug-debug.report` workflow.

After the bug report is created, pause and display:

```
--- Checkpoint 1/3: Bug Documented ---
Report: bugs/BUG-NNN-YYYY-MM-DD-slug.md
Severity: <level>

Review the report above. Proceed to root cause investigation?
Type "yes" to continue, or "edit" to revise the report first.
```

Wait for confirmation before continuing. If the user types "edit", open the bug report for review and re-ask. If the user types anything other than "yes" or "edit", re-prompt once. If still no confirmation, stop and tell the user to run `speckit.bug-debug.investigate BUG-NNN` manually when ready.

---

### Phase B — Investigate

**Skip if**: `--from=plan|tasks`.

Execute the full `speckit.bug-debug.investigate` workflow using the bug reference from Phase A (or the provided reference).

After investigation is complete, pause and display:

```
--- Checkpoint 2/3: Root Cause Identified ---
Root cause: <one sentence>
Location: file:line
Pattern sweep: N occurrence(s)

Review the investigation above. Proceed to fix plan?
Type "yes" to continue, "retry" to re-investigate from scratch (--fresh), or "stop" to exit.
```

Wait for confirmation.
- "yes" → proceed to Phase C
- "retry" → re-run investigation with `--fresh`, then re-display checkpoint
- "stop" → exit and tell user to run `speckit.bug-debug.plan BUG-NNN` manually when ready
- anything else → re-prompt once, then stop

---

### Phase C — Plan

**Skip if**: `--from=tasks`.

Execute the full `speckit.bug-debug.plan` workflow using the bug reference. Pass through `--all-occurrences` and `--update-spec` if provided.

After the plan is created, pause and display:

```
--- Checkpoint 3/3: Plan Ready ---
Plan: bugs/BUG-NNN-plan.md

Review the plan above. Proceed to task generation?
Type "yes" to continue or "stop" to exit.
```

Wait for confirmation.
- "yes" → proceed to Phase D
- "stop" → exit and tell user to run `speckit.bug-debug.tasks BUG-NNN` manually when ready
- anything else → re-prompt once, then stop

---

### Phase D — Tasks

Execute the full `speckit.bug-debug.tasks` workflow using the bug reference.

After tasks are created, display:

```
--- Lifecycle Complete ---
Bug:    bugs/BUG-NNN-YYYY-MM-DD-slug.md
Plan:   bugs/BUG-NNN-plan.md
Tasks:  bugs/BUG-NNN-tasks.md  (N fix + N prevention)

Start implementing:
  speckit implement BUG-NNN-T1
```

---

## Resume Behavior

Determine the current lifecycle state from the bug report before choosing a starting phase:

| State | Action |
|---|---|
| No investigation section | Start from Phase B (investigate) |
| Investigation done, no plan | Start from Phase C (plan) |
| Plan done, no tasks file | Start from Phase D (tasks) |
| Tasks file exists | Inform user — nothing to do, use `speckit implement` |

Inform the user which phase is being skipped and why.

---

## Constraints

- Do not skip checkpoints; human review between phases is the point of this command
- Each phase inherits all constraints from its corresponding command
- If any phase fails or the user stops, leave artifacts in their current state — do not clean up partial work
- Do not loop back to an earlier phase except when the user explicitly types "retry" at Checkpoint 2

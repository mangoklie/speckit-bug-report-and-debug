# speckit.bug-debug.plan

Generate a complete, actionable fix plan from an investigated bug report. Produces a speckit-compatible plan document and appends tasks to the relevant spec artifacts.

This command requires that `speckit.bug-debug.investigate` has already been run on the bug — the `## Investigation` section of the bug report must be populated with a confirmed root cause.

---

## Parameters

Parse the user's input for:

- **Bug reference** (required): `BUG-NNN`, partial file name, or path. Resolve to a file in `docs/bugs/`.
- `--all-occurrences` — generate fix tasks for every pattern-sweep hit, not just the primary root cause location
- `--update-spec` — include tasks to patch affected spec artifacts where the bug reveals a spec gap or ambiguity

---

## Pre-flight

1. Locate the bug report in `docs/bugs/`. If ambiguous, list candidates.
2. Read the full bug report.
3. Check that `## Investigation` is populated and contains a confirmed root cause. If the investigation section is empty or says "Not yet investigated", stop and instruct the user to run `speckit.bug-debug.investigate BUG-NNN` first.
4. Load any spec artifacts listed in `## Spec Traceability`. These inform whether spec updates are needed.
5. If a feature spec directory exists (`specs/{feature}/`), check for an existing `tasks.md` to understand current task numbering and format.

---

## Phase 1 — Analyze the Bug Report

Extract from the investigation section:

- Confirmed root cause and its `file:line` location
- All pattern-sweep occurrences (file and line for each)
- Suggested fix approaches (descriptions from the investigation)
- Any spec divergences noted
- Affected spec sections (from traceability matrix)

---

## Phase 2 — Design the Fix Plan

Design two task tracks:

### Fix Track

Tasks that directly resolve the bug:

1. **Primary fix**: One task per root cause location. Describe the change needed — the _what_ and _why_, not the code. Reference `file:line`.
2. **Occurrence fixes** (if `--all-occurrences`): One task per pattern-sweep hit. These may be batched into a single task if occurrences are near-identical.
3. **Validation**: One task to verify the fix against the reproduction steps established during investigation.

### Prevention Track

Tasks that prevent this class of bug from reoccurring:

1. **Regression test**: Add a test that would have caught this bug before it shipped. Describe what the test should assert, where it belongs, and why it covers the root cause.
2. **Spec clarification** (if `--update-spec` or if investigation found a spec gap): One task to amend the relevant spec section with the correct requirement or edge case. Reference the spec section.
3. **Guard / lint rule** (optional, only suggest if a programmatic guard is clearly appropriate): Describe the rule and where it should live.

Do not generate tasks for hypothetical future bugs or speculative hardening unrelated to this root cause.

---

## Phase 3 — Write the Fix Plan Document

Create `docs/bugs/BUG-NNN-fix-plan.md` using speckit plan format:

```markdown
# Fix Plan: BUG-NNN — <bug title>

**Bug report**: docs/bugs/BUG-NNN-YYYY-MM-DD-slug.md
**Root cause**: <one sentence from investigation>
**Plan created**: YYYY-MM-DD

---

## Context

<Two to three sentences: what the bug is, where it lives, and why this plan fixes it without over-engineering.>

## Approach

<Describe the fix strategy at a high level. Reference the spec as the source of truth for correct behavior.>

## Scope

- Files to modify: <list>
- Tests to add: <list>
- Spec sections to update: <list or "none">

---

## Tasks

### Fix Track

- [ ] **[BUG-NNN-F1]** <Task title>
  - Location: `file:line`
  - What: <What to change and why>
  - Done when: <Acceptance condition>

- [ ] **[BUG-NNN-F2]** <Task title>
  ...

- [ ] **[BUG-NNN-F-VALIDATE]** Validate fix against reproduction steps
  - Run: <exact reproduction command from investigation>
  - Done when: Bug no longer reproduces

### Prevention Track

- [ ] **[BUG-NNN-P1]** Add regression test: <what it asserts>
  - Location: <test file or directory>
  - Done when: Test fails on unfixed code, passes on fixed code

- [ ] **[BUG-NNN-P2]** Update spec: <which section, what to add>  *(only if --update-spec or spec gap found)*
  - Location: `specs/{feature}/spec.md` section X
  - Done when: Spec explicitly covers the edge case that caused this bug

---

## Verification Checklist

- [ ] All Fix Track tasks complete
- [ ] Regression test added and passing
- [ ] No new test failures introduced
- [ ] Pattern-sweep occurrences addressed (if --all-occurrences)
- [ ] Spec updated (if applicable)
- [ ] Bug report status updated to `resolved`
```

---

## Phase 4 — Append Tasks to Spec Artifacts

If a feature spec directory exists at `specs/{feature}/` and a `tasks.md` is present:

- Append the Fix Track and Prevention Track tasks to `tasks.md`, tagged `[BUG-NNN]`
- Preserve existing task numbering and format conventions
- Add a section header: `## Bug Fix: BUG-NNN`

If no feature spec directory exists, note in the output that tasks are in the fix plan document only.

---

## Phase 5 — Update Bug Report

In the bug report's `## Fix Plan` section, replace the stub with a reference:

```markdown
## Fix Plan

**Plan**: docs/bugs/BUG-NNN-fix-plan.md
**Status**: ready to implement

Tasks: BUG-NNN-F1, BUG-NNN-F2, BUG-NNN-F-VALIDATE, BUG-NNN-P1 <etc.>
```

---

## Phase 6 — Emit Summary

```
Fix plan created: docs/bugs/BUG-NNN-fix-plan.md
Tasks: N fix + N prevention
Files to modify: <list>
<Tasks appended to: specs/{feature}/tasks.md>  (if applicable)

Implement with: speckit implement BUG-NNN-F1
```

---

## Constraints

- Do NOT write or suggest code implementations — describe what to change, not how to code it
- Do NOT generate tasks unrelated to the confirmed root cause or its direct pattern-sweep occurrences
- Do NOT modify `spec.md`, `plan.md`, or `tasks.md` unless `--update-spec` is set or a clear spec gap exists
- If the investigation section lacks a confirmed root cause, refuse and redirect to `speckit.bug-debug.investigate`

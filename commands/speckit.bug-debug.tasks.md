---
description: Create dependency-ordered implementation tasks for a bug fix, stored in bugs/BUG-NNN-tasks.md.
---

## User Input

```text
$ARGUMENTS
```

## Outline

1. **Resolve bug reference** from `$ARGUMENTS` (`BUG-NNN`, partial name, or file path). Locate the matching file in `bugs/`. If ambiguous, list candidates and ask the user to confirm. If `bugs/BUG-NNN-plan.md` does not exist, stop and instruct the user to run `speckit.bug-debug.plan BUG-NNN` first.

2. **Load context**:
   - `.specify/memory/constitution.md` — project principles; every task must comply
   - `bugs/BUG-NNN-YYYY-MM-DD-slug.md` — full bug report: root cause, pattern sweep results, reproduction steps
   - `bugs/BUG-NNN-plan.md` — fix approach, affected files, design decisions

3. **Create `bugs/BUG-NNN-tasks.md`** — dependency-ordered implementation tasks:
   - Every task uses checklist format: `- [ ] [BUG-NNN-TX] Description — file/path`
   - Organized into two tracks:

     **Fix track** — tasks that directly resolve the root cause:
     - One task per affected location (root cause + pattern-sweep occurrences if the plan covers them)
     - Ordered by dependency: foundational changes before anything that depends on them
     - Final fix-track task: validate fix against the exact reproduction steps from the investigation

     **Prevention track** — tasks that stop this class of bug from recurring:
     - Regression test: one task describing what to assert and where the test belongs
     - Spec clarification (only if plan flagged a spec gap): one task naming the spec section to amend
     - Guard/lint rule (only if plan explicitly calls for one): one task describing the rule and location

   - Do not generate tasks for hypothetical hardening unrelated to this bug's confirmed root cause
   - Do not duplicate tasks already in the plan document itself

4. **Update `bugs/BUG-NNN-YYYY-MM-DD-slug.md`** — replace or update the `## Fix Plan` stub to include the tasks reference:

   ```
   ## Fix Plan

   **Plan**:  bugs/BUG-NNN-plan.md
   **Tasks**: bugs/BUG-NNN-tasks.md
   **Status**: ready to implement
   ```

5. **Emit summary**:

   ```
   Tasks created: bugs/BUG-NNN-tasks.md  (N tasks: N fix + N prevention)

   Start implementing:
     speckit implement BUG-NNN-T1
   ```

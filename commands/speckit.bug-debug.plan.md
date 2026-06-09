---
description: Create a fix plan and tasks for a bug, stored in bugs/BUG-NNN-plan.md and bugs/BUG-NNN-tasks.md.
---

## User Input

```text
$ARGUMENTS
```

## Outline

1. **Resolve bug reference** from `$ARGUMENTS` (`BUG-NNN`, partial name, or file path). Locate the matching file in `bugs/`. If ambiguous, list candidates and ask the user to confirm. If the `## Investigation` section is empty or absent, stop and instruct the user to run `speckit.bug-debug.investigate BUG-NNN` first.

2. **Load context**:
   - `.specify/memory/constitution.md` — project principles and constraints; these govern every decision in the plan
   - `bugs/BUG-NNN-YYYY-MM-DD-slug.md` — the full bug report (summary, reproduction steps, investigation findings, root cause, pattern sweep results, suggested fix approaches)
   - Any spec artifacts listed in the bug report's `## Spec Traceability` table — load these to understand intended behavior

3. **Create `bugs/BUG-NNN-plan.md`** — a focused implementation plan for fixing the bug:
   - Technical context: where in the stack the bug lives, which files are involved, relevant dependencies
   - Design decisions: chosen fix approach (from the suggested approaches in the investigation), and why it was chosen over alternatives
   - Scope: primary root cause location + any pattern-sweep occurrences to address
   - Constitution compliance: note any constitution principles that constrain or shape the fix
   - File structure: which files will change and how

4. **Create `bugs/BUG-NNN-tasks.md`** — dependency-ordered implementation tasks:
   - Every task uses checklist format: `- [ ] [BUG-NNN-TX] Description with file path`
   - Two tracks:
     - **Fix track** — tasks that directly resolve the root cause (and pattern-sweep occurrences if `--all-occurrences` was passed)
     - **Prevention track** — regression test(s) that would have caught this bug; spec clarification tasks if `--update-spec` was passed or a spec gap was found
   - Ordered by dependency: foundational fixes before validation, tests after fix is in place
   - Final task: validate fix against the exact reproduction steps from the investigation

5. **Update `bugs/BUG-NNN-YYYY-MM-DD-slug.md`** — replace the `## Fix Plan` stub with a reference:

   ```
   ## Fix Plan

   **Plan**: bugs/BUG-NNN-plan.md
   **Tasks**: bugs/BUG-NNN-tasks.md
   **Status**: ready to implement
   ```

6. **Emit summary**:

   ```
   Plan created:  bugs/BUG-NNN-plan.md
   Tasks created: bugs/BUG-NNN-tasks.md  (N tasks: N fix + N prevention)

   Start implementing:
     speckit implement BUG-NNN-T1
   ```

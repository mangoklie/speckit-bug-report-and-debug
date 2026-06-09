---
description: Create a fix plan for a bug and store it in bugs/BUG-NNN-plan.md.
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
   - Scope: primary root cause location + any pattern-sweep occurrences to address; note whether prevention tasks (regression tests, spec clarifications) are warranted
   - Constitution compliance: note any constitution principles that constrain or shape the fix
   - File structure: which files will change and how

4. **Update `bugs/BUG-NNN-YYYY-MM-DD-slug.md`** — replace the `## Fix Plan` stub with a reference:

   ```
   ## Fix Plan

   **Plan**:  bugs/BUG-NNN-plan.md
   **Tasks**: bugs/BUG-NNN-tasks.md  ← run speckit.bug-debug.tasks BUG-NNN to generate
   **Status**: plan ready, tasks pending
   ```

5. **Emit summary**:

   ```
   Plan created: bugs/BUG-NNN-plan.md

   Next step:
     speckit.bug-debug.tasks BUG-NNN   — generate implementation tasks
   ```

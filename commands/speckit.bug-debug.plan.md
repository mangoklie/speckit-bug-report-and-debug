---
description: Create a fix plan for a bug and store it in bugs/BUG-NNN-plan.md.
scripts:
  sh: scripts/bash/setup-bug-plan.sh --json
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Pre-Execution Checks

**Check for extension hooks (before planning)**:
- Check if `.specify/extensions.yml` exists in the project root.
- If it exists, read it and look for entries under the `hooks.before_plan` key.
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

1. **Resolve bug reference** from `$ARGUMENTS` (`BUG-NNN`, partial name, or file path). If ambiguous, list candidates and ask the user to confirm. If the `## Investigation` section is empty or absent, stop and instruct the user to run `speckit.bug-debug.investigate BUG-NNN` first.

2. **Setup**: Run `{SCRIPT} <BUG_REF>` from repo root and parse JSON for `BUG_REPORT`, `BUG_PLAN`, `BUGS_DIR`, `BRANCH`. The script copies the plan template to `BUG_PLAN` if it does not already exist.

3. **Load context**: Read `BUG_REPORT` and `.specify/memory/constitution.md`. Load `BUG_PLAN` template (already copied by the script). Load any spec artifacts listed in the bug report's `## Spec Traceability` table.

4. **Fill the plan**: Follow the structure in `BUG_PLAN` template to:
   - Fill **Bug Context** from the investigation's root cause, location, causal chain, and pattern sweep results (copy directly — do not paraphrase)
   - Fill **Technical Context** (mark unknowns as "NEEDS CLARIFICATION")
   - Fill **Constitution Check** section from constitution (ERROR if violations are unjustified)
   - Fill **Fix Scope**: primary fix location + chosen approach + pattern sweep fixes + prevention strategy
   - Fill **Project Structure**: list exact files that will change
   - Fill **Complexity Tracking** only if constitution violations exist

5. **Update `BUG_REPORT`** — replace the `## Fix Plan` stub with:

   ```
   ## Fix Plan

   **Plan**:  bugs/BUG-NNN-plan.md
   **Tasks**: bugs/BUG-NNN-tasks.md  ← run speckit.bug-debug.tasks BUG-NNN to generate
   **Status**: plan ready, tasks pending
   ```

## Mandatory Post-Execution Hooks

**You MUST complete this section before reporting completion to the user.**

Check if `.specify/extensions.yml` exists in the project root.
- If it does not exist, or no hooks are registered under `hooks.after_plan`, skip to the Completion Report.
- If it exists, read it and look for entries under the `hooks.after_plan` key.
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
Plan created: bugs/BUG-NNN-plan.md
Branch: <BRANCH>
Template: templates/plan-template.md

Next step:
  speckit.bug-debug.tasks BUG-NNN   — generate implementation tasks
```

## Key Rules

- Use absolute paths for filesystem operations; use project-relative paths in documentation
- ERROR on constitution gate failures or unresolved clarifications
- Do NOT read source code beyond what is needed to verify file paths and dependency names
- Do NOT write or suggest any implementation code in the plan

# speckit.bug-debug.report

Document a bug. This command performs intake and structured documentation only.

**Hard boundary**: Do NOT read source code, trace execution, investigate root causes, write fixes, or modify any file outside `docs/bugs/`. Those activities belong to `speckit.bug-debug.investigate` and `speckit.bug-debug.plan`.

---

## Parameters

Parse the user's input for:

- `--severity=critical|high|medium|low` — severity override; assess independently if absent
- `--ticket=XXX` — external tracker reference (e.g. `--ticket=PROJ-123`)
- `--feature=NAME` — optional hint for spec artifact search
- Remaining text — bug description; if absent, enter interactive intake mode

---

## Workflow

### Step 1 — Parse Input

Extract severity flag, ticket reference, feature hint, and description from the user's input. If no description is present, proceed to interactive intake mode (Step 2). If a description is provided, use it as the starting point and fill gaps interactively.

### Step 2 — Interactive Intake

Ask the user for each item not yet established. Do not ask for items already clear from the description. Stop asking once all five essentials are gathered:

1. **Actual behavior** — what the system does
2. **Expected behavior** — what the system should do
3. **Reproduction steps** — numbered, minimal, deterministic
4. **Environment** — OS, runtime version, browser, deployment context, relevant config
5. **Impact** — who is affected and how severely

Ask only what is missing. Do not ask for items that can be inferred from the description.

### Step 3 — Duplicate Check

Search `docs/bugs/` for existing reports that describe the same symptom. Read file names and summaries only — do not deeply investigate code. If a likely duplicate exists, surface it and ask the user to confirm before proceeding.

### Step 4 — Assess Severity

If `--severity` was not provided, recommend one based on these thresholds:

| Severity | Criteria |
|---|---|
| critical | System down, data loss, security breach, payment failure |
| high | Core feature broken for all users, no workaround |
| medium | Feature degraded, workaround exists |
| low | Cosmetic, edge case, minor UX issue |

State your recommendation and rationale. The user may override.

### Step 5 — Spec Artifact Tracing (Optional)

Search `specs/` for feature directories that may be related to this bug. This step is best-effort — bugs may predate specs, span multiple features, or appear in undocumented areas. Do not force a link if none is clear.

For each potentially relevant spec found:
- Identify affected user stories (cite by ID or heading)
- Identify affected functional requirements
- Identify affected acceptance criteria

If no relevant spec is found, record "No linked spec — bug may predate feature documentation." in the traceability section.

### Step 6 — Determine Bug ID and File Path

Count existing files in `docs/bugs/` that match `BUG-*.md` to determine the next sequential number. Format: `BUG-001`, `BUG-002`, etc. (zero-padded to 3 digits; extend to 4 when count exceeds 999).

Derive a slug from the bug description: lowercase, hyphens only, max 6 words.

File path: `docs/bugs/BUG-NNN-YYYY-MM-DD-slug.md`

Example: `docs/bugs/BUG-007-2026-06-09-login-token-not-refreshed.md`

Create `docs/bugs/` if it does not exist.

### Step 7 — Write Bug Report

Create the bug report file using the template below. Fill every section. Leave `## Investigation` and `## Fix Plan` as empty stubs — those are populated by later commands.

```markdown
# BUG-NNN: <short title>

**Date**: YYYY-MM-DD
**Severity**: critical | high | medium | low
**Status**: open
**Ticket**: <ref or N/A>
**Reporter**: <from git config user.name if available, otherwise omit>

---

## Summary

<One to two sentence description of the bug.>

## Observed Behavior

<What the system actually does.>

## Expected Behavior

<What the system should do, per spec or reasonable expectation.>

## Reproduction Steps

1. <Step>
2. <Step>
3. <Step>

## Environment

- **OS**: 
- **Runtime / Version**: 
- **Browser** (if applicable): 
- **Deployment context**: 
- **Relevant config**: 

## Impact

<Who is affected, how severely, and any known workarounds.>

## Spec Traceability

| Spec | Section | User Story / Requirement |
|---|---|---|
| <path or "No linked spec"> | | |

## Investigation

> Not yet investigated. Run `speckit.bug-debug.investigate BUG-NNN` to perform root cause analysis.

## Fix Plan

> Not yet planned. Run `speckit.bug-debug.plan BUG-NNN` after investigation is complete.
```

### Step 8 — Confirm and Emit

Output a confirmation message:

```
Bug report created: docs/bugs/BUG-NNN-YYYY-MM-DD-slug.md
Severity: <level>
<Ticket: ref> (if provided)

Next steps:
  speckit.bug-debug.investigate BUG-NNN   — identify root cause
  speckit.bug-debug.iterate BUG-NNN       — run full lifecycle in one session
```

---

## Constraints

- Do NOT read source code files to understand the bug
- Do NOT suggest fixes or workarounds in the report
- Do NOT create files outside `docs/bugs/`
- Do NOT modify existing bug reports
- Surface a duplicate warning if one is found; do not silently skip creation

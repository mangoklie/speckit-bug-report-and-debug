# speckit.bug-debug.investigate

Systematically investigate a bug's root cause. This command is read-only — it updates the bug report with findings but applies no fixes.

**Hard constraints**:
- Do NOT modify source code, configuration, or test files
- Do NOT apply workarounds or patches
- MUST complete a full codebase pattern sweep before marking investigation done
- Surface honest uncertainty; do not fabricate confidence

---

## Parameters

Parse the user's input for:

- **Bug reference** (required): `BUG-NNN`, partial file name, or symptom description. Resolve to a file in `docs/bugs/`.
- `--deep` — spawn parallel sub-agents to analyze codebase sections concurrently
- `--fresh` — discard any prior investigation notes in the bug report and start from scratch

---

## Pre-flight

1. Locate the bug report file in `docs/bugs/`. If the reference is ambiguous, list candidates and ask the user to confirm.
2. Read the full bug report: summary, observed behavior, expected behavior, reproduction steps, environment.
3. If `--fresh` is set, clear the `## Investigation` section before proceeding.
4. If investigation notes already exist (and `--fresh` is not set), read them and continue from where analysis left off rather than restarting.
5. Load any linked spec artifacts from the `## Spec Traceability` table. These define intended behavior — they are your source of truth for "expected."

---

## Phase 1 — Build a Feedback Loop

Establish a repeatable, unambiguous signal that confirms the bug exists. Work through these strategies in order, stopping at the first that succeeds:

1. Failing automated test (existing or construct a minimal one)
2. `curl` / HTTP script that demonstrates the failure
3. CLI invocation that triggers the symptom
4. Headless browser script
5. Log replay or trace
6. Custom harness / fixture
7. Fuzzing / property test
8. Bisection (git bisect or equivalent)
9. Differential comparison (correct env vs broken env)
10. Manual reproduction checklist

Document which strategy succeeded and the exact command or steps used. If none succeed, state that explicitly and record the closest approximation found.

---

## Phase 2 — Hypothesize

Generate **3 to 5 falsifiable root-cause candidates**, ranked by likelihood (most likely first). For each hypothesis:

- State the claim precisely
- Identify the specific prediction it makes (observable consequence if true)
- Identify a disproving condition (what would falsify it)
- Assign initial likelihood: high / medium / low

Do not collapse multiple distinct causes into one hypothesis.

---

## Phase 3 — Trace

Starting from the entry point relevant to the bug (API handler, event listener, CLI command, etc.), follow code execution through the suspected failure path. At each step:

- Read the relevant file and function
- Note where behavior diverges from the spec or expected logic
- Eliminate hypotheses that the trace disproves
- Narrow focus to the surviving candidate(s)

Use `file:line` references for every finding. Do not summarize without citing exact locations.

If `--deep` is set: spawn parallel agents to analyze different subsystems simultaneously (e.g., one agent per service, layer, or module). Consolidate their findings before proceeding to Phase 4.

---

## Phase 4 — Root Cause Confirmation

Select the surviving hypothesis. Verify it against the trace evidence:

- State the confirmed root cause precisely
- Cite the exact `file:line` where the defect lives
- Explain the causal chain from root cause to observed symptom
- If multiple root causes remain plausible, rank them and state what additional evidence would distinguish them

**Mandatory pattern sweep**: Before marking investigation complete, search the entire codebase for the same defective pattern. This is not optional. Look for:

- The same logic error in parallel code paths
- Copy-pasted code with the same flaw
- The same incorrect assumption applied elsewhere

Record every occurrence found, even if it has not yet caused a visible symptom.

---

## Phase 5 — Update Bug Report

Append investigation results to the `## Investigation` section of the bug report. Do not overwrite the existing bug metadata (summary, reproduction steps, etc.).

Use this structure within the `## Investigation` section:

```markdown
## Investigation

**Investigated**: YYYY-MM-DD
**Investigator**: <git config user.name or "Claude">

### Feedback Loop

<Strategy used and exact reproduction command/steps.>

### Hypotheses

| # | Hypothesis | Likelihood | Status |
|---|---|---|---|
| 1 | <claim> | high | confirmed / eliminated |
| 2 | <claim> | medium | confirmed / eliminated |
| ... | | | |

### Trace Summary

<Narrative of execution path with file:line references. One finding per line is acceptable.>

### Root Cause

**Location**: `file:line`

<Precise description of the defect and the causal chain to the symptom.>

**Spec divergence** (if applicable): <How this violates the spec, with spec section reference.>

### Pattern Sweep Results

| File | Line | Description |
|---|---|---|
| `path/to/file.ext` | 42 | Same pattern — <brief note> |
| (none found) | | |

### Suggested Fix Approaches

1. <Approach description — no code, no patches>
2. <Alternative approach if relevant>

### Open Uncertainties

<Any limitations in the analysis, areas that could not be fully inspected, or confidence gaps. Omit section if none.>
```

---

## Phase 6 — Emit Summary

Output a human-readable investigation summary:

```
Investigation complete: docs/bugs/BUG-NNN-...md
Root cause: <one sentence>
Location: file:line
Pattern sweep: N occurrence(s) found

Next step:
  speckit.bug-debug.plan BUG-NNN   — generate fix plan and tasks
```

If significant uncertainty remains, state it clearly in the summary.

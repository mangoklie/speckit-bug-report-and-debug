# speckit-bug-report-and-debug

A [Spec Kit](https://github.com/github/spec-kit) extension for structured bug iteration: document bugs, trace root causes, and generate fix plans with regression prevention — all integrated with your speckit artifact workflow.

## Commands

| Command | Purpose |
|---|---|
| `speckit.bug-debug.report` | Intake and document a bug with spec tracing |
| `speckit.bug-debug.investigate` | Systematic root cause investigation (read-only) |
| `speckit.bug-debug.plan` | Generate fix plan + regression prevention tasks |
| `speckit.bug-debug.iterate` | Full lifecycle in one session with checkpoints |

## Workflow

```
report → investigate → plan → implement
   ↑___________________________________|
              (iterate orchestrates this)
```

Each command has a hard boundary. `report` never reads code. `investigate` never writes code. `plan` never implements. This separation keeps each phase focused and reviewable.

## Installation

Add to your speckit configuration:

```yaml
extensions:
  - id: bug-debug
    source: https://github.com/mangoklie/speckit-bug-report-and-debug/releases/download/v1.0.0/extension.yml
```

Then run:

```
speckit extensions install bug-debug
```

## Usage

### Document a new bug

```
speckit.bug-debug.report Login token not refreshed after password change
speckit.bug-debug.report --severity=high --ticket=PROJ-42 Cart total wrong for discount codes
```

Interactive mode (no description provided):

```
speckit.bug-debug.report
```

Bug reports are written to `docs/bugs/BUG-NNN-YYYY-MM-DD-slug.md`.

### Investigate root cause

```
speckit.bug-debug.investigate BUG-007
speckit.bug-debug.investigate BUG-007 --deep
```

`--deep` spawns parallel agents for large codebases. `--fresh` discards prior notes and restarts.

### Generate fix plan

```
speckit.bug-debug.plan BUG-007
speckit.bug-debug.plan BUG-007 --all-occurrences --update-spec
```

`--all-occurrences` generates tasks for every location found in the pattern sweep. `--update-spec` adds tasks to patch spec artifacts where the bug reveals a gap.

Fix plans are written to `docs/bugs/BUG-NNN-fix-plan.md`. Tasks are also appended to `specs/{feature}/tasks.md` if a linked feature spec exists.

### Full lifecycle in one session

```
speckit.bug-debug.iterate
speckit.bug-debug.iterate BUG-007          # start from investigate if already reported
speckit.bug-debug.iterate --deep --update-spec
```

Human checkpoints appear between each phase. You control when to proceed.

## Output Files

```
docs/
  bugs/
    BUG-001-2026-06-09-login-token-expiry.md          # bug report
    BUG-001-fix-plan.md                                # fix plan + tasks
    BUG-002-2026-06-10-cart-discount-wrong.md
    BUG-002-fix-plan.md
```

Bug reports follow this structure:

- Summary, severity, ticket reference
- Observed vs expected behavior
- Reproduction steps and environment
- Spec traceability matrix (links to spec artifacts where relevant)
- Investigation findings (populated by `investigate`)
- Fix plan reference (populated by `plan`)

## Hook

The extension registers an optional `after_implement` hook that prompts you to run a pattern sweep after a bug fix is implemented, confirming no similar occurrences remain.

## Requirements

- Spec Kit >= 0.4.0

## License

MIT — see [LICENSE](LICENSE)

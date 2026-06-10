#!/usr/bin/env bash

set -e

# Parse command line arguments
JSON_MODE=false
ARGS=()

for arg in "$@"; do
    case "$arg" in
        --json)
            JSON_MODE=true
            ;;
        --help|-h)
            echo "Usage: $0 [--json] <BUG_REF>"
            echo "  BUG_REF   Bug reference, e.g. BUG-001 or BUG-1"
            echo "  --json    Output results in JSON format"
            echo "  --help    Show this help message"
            exit 0
            ;;
        *)
            ARGS+=("$arg")
            ;;
    esac
done

# Get script directory and load common functions
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Require BUG_REF argument
if [[ ${#ARGS[@]} -eq 0 ]]; then
    echo "ERROR: BUG_REF is required (e.g. BUG-001)" >&2
    exit 1
fi

BUG_REF="${ARGS[0]}"

# Resolve REPO_ROOT
REPO_ROOT=$(find_repo_root "$SCRIPT_DIR")

# Get all paths from common functions
_paths_output=$(get_bug_paths "$BUG_REF" "$REPO_ROOT") || {
    echo "ERROR: Failed to resolve bug paths" >&2
    exit 1
}
eval "$_paths_output"
unset _paths_output

# Validate bug report was found
if [[ -z "$BUG_REPORT" ]] || [[ ! -f "$BUG_REPORT" ]]; then
    echo "ERROR: Bug report not found for reference '$BUG_REF' in $BUGS_DIR" >&2
    exit 1
fi

# Validate bug plan exists — tasks require a completed plan
if [[ -z "$BUG_PLAN" ]] || [[ ! -f "$BUG_PLAN" ]]; then
    echo "ERROR: Bug plan not found at $BUG_PLAN" >&2
    echo "Run speckit.bug-debug.plan $BUG_REF first to create the fix plan." >&2
    exit 1
fi

# Derive BUG_TASKS path from BUG_PLAN (replace -plan.md suffix with -tasks.md)
BUG_TASKS="${BUG_PLAN/-plan.md/-tasks.md}"

# Resolve tasks template (|| true so missing template doesn't abort under set -e)
TASKS_TEMPLATE=$(resolve_template "tasks-template" "$REPO_ROOT") || true

# Ensure the bugs directory exists
mkdir -p "$BUGS_DIR"

# Output results
if $JSON_MODE; then
    if has_jq; then
        jq -cn \
            --arg bug_report "$BUG_REPORT" \
            --arg bug_plan "$BUG_PLAN" \
            --arg bug_tasks "$BUG_TASKS" \
            --arg bugs_dir "$BUGS_DIR" \
            --arg branch "$CURRENT_BRANCH" \
            --arg tasks_template "${TASKS_TEMPLATE:-}" \
            '{BUG_REPORT:$bug_report,BUG_PLAN:$bug_plan,BUG_TASKS:$bug_tasks,BUGS_DIR:$bugs_dir,BRANCH:$branch,TASKS_TEMPLATE:$tasks_template}'
    else
        printf '{"BUG_REPORT":"%s","BUG_PLAN":"%s","BUG_TASKS":"%s","BUGS_DIR":"%s","BRANCH":"%s","TASKS_TEMPLATE":"%s"}\n' \
            "$(json_escape "$BUG_REPORT")" "$(json_escape "$BUG_PLAN")" \
            "$(json_escape "$BUG_TASKS")" "$(json_escape "$BUGS_DIR")" \
            "$(json_escape "$CURRENT_BRANCH")" "$(json_escape "${TASKS_TEMPLATE:-}")"
    fi
else
    echo "BUG_REPORT:      $BUG_REPORT"
    echo "BUG_PLAN:        $BUG_PLAN"
    echo "BUG_TASKS:       $BUG_TASKS"
    echo "BUGS_DIR:        $BUGS_DIR"
    echo "BRANCH:          $CURRENT_BRANCH"
    echo "TASKS_TEMPLATE:  ${TASKS_TEMPLATE:-not found}"
fi

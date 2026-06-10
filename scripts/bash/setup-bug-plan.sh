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

# Ensure the bugs directory exists
mkdir -p "$BUGS_DIR"

# Copy plan template if plan doesn't already exist
if [[ -f "$BUG_PLAN" ]]; then
    if $JSON_MODE; then
        echo "Plan already exists at $BUG_PLAN, skipping template copy" >&2
    else
        echo "Plan already exists at $BUG_PLAN, skipping template copy"
    fi
else
    TEMPLATE=$(resolve_template "plan-template" "$REPO_ROOT") || true
    if [[ -n "$TEMPLATE" ]] && [[ -f "$TEMPLATE" ]]; then
        cp "$TEMPLATE" "$BUG_PLAN"
        if $JSON_MODE; then
            echo "Copied plan template to $BUG_PLAN" >&2
        else
            echo "Copied plan template to $BUG_PLAN"
        fi
    else
        if $JSON_MODE; then
            echo "Warning: Plan template not found" >&2
        else
            echo "Warning: Plan template not found"
        fi
        touch "$BUG_PLAN"
    fi
fi

# Output results
if $JSON_MODE; then
    if has_jq; then
        jq -cn \
            --arg bug_report "$BUG_REPORT" \
            --arg bug_plan "$BUG_PLAN" \
            --arg bugs_dir "$BUGS_DIR" \
            --arg branch "$CURRENT_BRANCH" \
            '{BUG_REPORT:$bug_report,BUG_PLAN:$bug_plan,BUGS_DIR:$bugs_dir,BRANCH:$branch}'
    else
        printf '{"BUG_REPORT":"%s","BUG_PLAN":"%s","BUGS_DIR":"%s","BRANCH":"%s"}\n' \
            "$(json_escape "$BUG_REPORT")" "$(json_escape "$BUG_PLAN")" \
            "$(json_escape "$BUGS_DIR")" "$(json_escape "$CURRENT_BRANCH")"
    fi
else
    echo "BUG_REPORT: $BUG_REPORT"
    echo "BUG_PLAN:   $BUG_PLAN"
    echo "BUGS_DIR:   $BUGS_DIR"
    echo "BRANCH:     $CURRENT_BRANCH"
fi

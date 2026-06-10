#!/usr/bin/env bash

# Shared utilities for bug-debug scripts.

# Find REPO_ROOT by walking up from a given dir until extension.yml is found.
find_repo_root() {
    local dir="${1:-$(pwd)}"
    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/extension.yml" ]]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    # Fallback: use current working directory
    echo "$(pwd)"
}

# Find a bug report file in BUGS_DIR matching BUG_REF.
# BUG_REF may be: BUG-NNN, BUG-N, or a partial slug.
# Echoes the absolute file path, or nothing if not found.
find_bug_report() {
    local bug_ref="$1"
    local bugs_dir="$2"

    if [[ -z "$bug_ref" ]] || [[ -z "$bugs_dir" ]] || [[ ! -d "$bugs_dir" ]]; then
        return 1
    fi

    # Normalize: BUG-1 → BUG-001, BUG-01 → BUG-001
    local normalized
    if [[ "$bug_ref" =~ ^[Bb][Uu][Gg]-([0-9]+)$ ]]; then
        normalized=$(printf "BUG-%03d" "${BASH_REMATCH[1]}")
    else
        normalized="$bug_ref"
    fi

    # Exact prefix match first (BUG-NNN-*)
    local match
    match=$(find "$bugs_dir" -maxdepth 1 -name "${normalized}-*.md" ! -name "*-plan.md" ! -name "*-tasks.md" 2>/dev/null | sort | head -1)
    if [[ -n "$match" ]]; then
        echo "$match"
        return 0
    fi

    # Case-insensitive / partial match fallback
    local lower_ref="${bug_ref,,}"
    match=$(find "$bugs_dir" -maxdepth 1 -name "*.md" ! -name "*-plan.md" ! -name "*-tasks.md" 2>/dev/null \
        | grep -i "$lower_ref" | sort | head -1)
    if [[ -n "$match" ]]; then
        echo "$match"
        return 0
    fi

    return 1
}

# Resolve key paths for a bug reference.
# Outputs eval-able variable assignments:
#   BUG_REPORT, BUG_PLAN, BUGS_DIR, CURRENT_BRANCH
get_bug_paths() {
    local bug_ref="$1"
    local repo_root="${2:-$(find_repo_root "$(pwd)")}"
    local bugs_dir="$repo_root/bugs"

    local branch
    branch=$(git -C "$repo_root" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

    local bug_report=""
    local bug_id=""
    local bug_plan=""

    if [[ -n "$bug_ref" ]]; then
        bug_report=$(find_bug_report "$bug_ref" "$bugs_dir")
        if [[ -n "$bug_report" ]]; then
            # Extract BUG-NNN from filename
            local basename
            basename=$(basename "$bug_report" .md)
            if [[ "$basename" =~ ^(BUG-[0-9]+)- ]]; then
                bug_id="${BASH_REMATCH[1]}"
            fi
        fi
    fi

    if [[ -n "$bug_id" ]]; then
        bug_plan="$bugs_dir/${bug_id}-plan.md"
    else
        bug_plan=""
    fi

    printf 'BUG_REPORT=%q\n' "${bug_report:-}"
    printf 'BUG_PLAN=%q\n' "${bug_plan:-}"
    printf 'BUGS_DIR=%q\n' "$bugs_dir"
    printf 'CURRENT_BRANCH=%q\n' "$branch"
}

# Search for a template file by name in templates/ under REPO_ROOT.
# Echoes the absolute path, or nothing if not found.
resolve_template() {
    local name="$1"
    local repo_root="${2:-$(find_repo_root "$(pwd)")}"
    local template_path="$repo_root/templates/${name}.md"
    if [[ -f "$template_path" ]]; then
        echo "$template_path"
    fi
}

# Returns 0 if jq is available in PATH.
has_jq() {
    command -v jq >/dev/null 2>&1
}

# Basic JSON string escaping (used when jq is unavailable).
json_escape() {
    local str="$1"
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    str="${str//$'\n'/\\n}"
    str="${str//$'\r'/\\r}"
    str="${str//$'\t'/\\t}"
    echo "$str"
}

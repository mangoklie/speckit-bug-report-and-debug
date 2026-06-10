#!/usr/bin/env bash

set -e

JSON_MODE=false
DRY_RUN=false
SHORT_NAME=""
BUG_NUMBER=""
ARGS=()
i=1
while [ $i -le $# ]; do
    arg="${!i}"
    case "$arg" in
        --json)
            JSON_MODE=true
            ;;
        --dry-run)
            DRY_RUN=true
            ;;
        --short-name)
            if [ $((i + 1)) -gt $# ]; then
                echo 'Error: --short-name requires a value' >&2
                exit 1
            fi
            i=$((i + 1))
            next_arg="${!i}"
            if [[ "$next_arg" == --* ]]; then
                echo 'Error: --short-name requires a value' >&2
                exit 1
            fi
            SHORT_NAME="$next_arg"
            ;;
        --number)
            if [ $((i + 1)) -gt $# ]; then
                echo 'Error: --number requires a value' >&2
                exit 1
            fi
            i=$((i + 1))
            next_arg="${!i}"
            if [[ "$next_arg" == --* ]]; then
                echo 'Error: --number requires a value' >&2
                exit 1
            fi
            BUG_NUMBER="$next_arg"
            ;;
        --help|-h)
            echo "Usage: $0 [--json] [--dry-run] [--short-name <name>] [--number N] <bug_description>"
            echo ""
            echo "Options:"
            echo "  --json              Output in JSON format"
            echo "  --dry-run           Compute bug ID and paths without creating files"
            echo "  --short-name <name> Provide a custom short name (2-4 words) for the bug slug"
            echo "  --number N          Specify bug number manually (overrides auto-detection)"
            echo "  --help, -h          Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 'Login token not refreshed after session expires'"
            echo "  $0 --short-name 'login-token' 'Login token not refreshed'"
            echo "  $0 --number 5 'Payment processing timeout'"
            exit 0
            ;;
        *)
            ARGS+=("$arg")
            ;;
    esac
    i=$((i + 1))
done

BUG_DESCRIPTION="${ARGS[*]}"
if [ -z "$BUG_DESCRIPTION" ] && [ -z "$SHORT_NAME" ]; then
    echo "Usage: $0 [--json] [--dry-run] [--short-name <name>] [--number N] <bug_description>" >&2
    exit 1
fi

if [ -n "$BUG_DESCRIPTION" ]; then
    BUG_DESCRIPTION=$(echo "$BUG_DESCRIPTION" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')
fi

get_highest_from_bugs() {
    local bugs_dir="$1"
    local highest=0

    if [ -d "$bugs_dir" ]; then
        for file in "$bugs_dir"/BUG-*.md; do
            [ -f "$file" ] || continue
            # Skip plan and tasks files
            [[ "$file" == *-plan.md ]] && continue
            [[ "$file" == *-tasks.md ]] && continue
            basename=$(basename "$file")
            if echo "$basename" | grep -Eq '^BUG-[0-9]+-'; then
                number=$(echo "$basename" | grep -Eo '^BUG-([0-9]+)-' | grep -Eo '[0-9]+')
                number=$((10#$number))
                if [ "$number" -gt "$highest" ]; then
                    highest=$number
                fi
            fi
        done
    fi

    echo "$highest"
}

clean_slug() {
    local name="$1"
    echo "$name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-//' | sed 's/-$//'
}

generate_slug() {
    local description="$1"

    local stop_words="^(i|a|an|the|to|for|of|in|on|at|by|with|from|is|are|was|were|be|been|being|have|has|had|do|does|did|will|would|should|could|can|may|might|must|shall|this|that|these|those|my|your|our|their|want|need|add|get|set)$"

    local clean_name=$(echo "$description" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/ /g')

    local meaningful_words=()
    for word in $clean_name; do
        [ -z "$word" ] && continue
        if ! echo "$word" | grep -qiE "$stop_words"; then
            if [ ${#word} -ge 3 ]; then
                meaningful_words+=("$word")
            elif echo "$description" | grep -q "\b${word^^}\b"; then
                meaningful_words+=("$word")
            fi
        fi
    done

    if [ ${#meaningful_words[@]} -gt 0 ]; then
        local max_words=3
        if [ ${#meaningful_words[@]} -eq 4 ]; then max_words=4; fi

        local result=""
        local count=0
        for word in "${meaningful_words[@]}"; do
            if [ $count -ge $max_words ]; then break; fi
            if [ -n "$result" ]; then result="$result-"; fi
            result="$result$word"
            count=$((count + 1))
        done
        echo "$result"
    else
        local cleaned=$(clean_slug "$description")
        echo "$cleaned" | tr '-' '\n' | grep -v '^$' | head -3 | tr '\n' '-' | sed 's/-$//'
    fi
}

SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

REPO_ROOT=$(find_repo_root "$SCRIPT_DIR")
cd "$REPO_ROOT"

BUGS_DIR="$REPO_ROOT/bugs"

# Determine slug
if [ -n "$SHORT_NAME" ]; then
    SLUG=$(clean_slug "$SHORT_NAME")
else
    SLUG=$(generate_slug "$BUG_DESCRIPTION")
fi

# Determine bug number
if [ -z "$BUG_NUMBER" ]; then
    HIGHEST=$(get_highest_from_bugs "$BUGS_DIR")
    BUG_NUMBER=$((HIGHEST + 1))
fi

BUG_NUM=$(printf "%03d" "$((10#$BUG_NUMBER))")
BUG_ID="BUG-${BUG_NUM}"
BUG_DATE=$(date +%Y-%m-%d)
BUG_FILE="$BUGS_DIR/${BUG_ID}-${BUG_DATE}-${SLUG}.md"

BRANCH=$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

if [ "$DRY_RUN" != true ]; then
    mkdir -p "$BUGS_DIR"

    if [ ! -f "$BUG_FILE" ]; then
        TEMPLATE=$(resolve_template "bug-report-template" "$REPO_ROOT") || true
        if [ -n "$TEMPLATE" ] && [ -f "$TEMPLATE" ]; then
            cp "$TEMPLATE" "$BUG_FILE"
        else
            touch "$BUG_FILE"
        fi
    fi
fi

if $JSON_MODE; then
    if has_jq; then
        if [ "$DRY_RUN" = true ]; then
            jq -cn \
                --arg bug_id "$BUG_ID" \
                --arg bug_file "$BUG_FILE" \
                --arg bugs_dir "$BUGS_DIR" \
                --arg branch "$BRANCH" \
                '{BUG_ID:$bug_id,BUG_FILE:$bug_file,BUGS_DIR:$bugs_dir,BRANCH:$branch,DRY_RUN:true}'
        else
            jq -cn \
                --arg bug_id "$BUG_ID" \
                --arg bug_file "$BUG_FILE" \
                --arg bugs_dir "$BUGS_DIR" \
                --arg branch "$BRANCH" \
                '{BUG_ID:$bug_id,BUG_FILE:$bug_file,BUGS_DIR:$bugs_dir,BRANCH:$branch}'
        fi
    else
        if [ "$DRY_RUN" = true ]; then
            printf '{"BUG_ID":"%s","BUG_FILE":"%s","BUGS_DIR":"%s","BRANCH":"%s","DRY_RUN":true}\n' \
                "$(json_escape "$BUG_ID")" "$(json_escape "$BUG_FILE")" \
                "$(json_escape "$BUGS_DIR")" "$(json_escape "$BRANCH")"
        else
            printf '{"BUG_ID":"%s","BUG_FILE":"%s","BUGS_DIR":"%s","BRANCH":"%s"}\n' \
                "$(json_escape "$BUG_ID")" "$(json_escape "$BUG_FILE")" \
                "$(json_escape "$BUGS_DIR")" "$(json_escape "$BRANCH")"
        fi
    fi
else
    echo "BUG_ID:   $BUG_ID"
    echo "BUG_FILE: $BUG_FILE"
    echo "BUGS_DIR: $BUGS_DIR"
    echo "BRANCH:   $BRANCH"
fi

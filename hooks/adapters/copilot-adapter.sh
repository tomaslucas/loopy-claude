#!/usr/bin/env bash
# hooks/adapters/copilot-adapter.sh - Universal Copilot ↔ Claude adapter
# Usage: copilot-adapter.sh <hook_type>
# Hook types: preToolUse, postToolUse

set -euo pipefail

HOOK_TYPE="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="$SCRIPT_DIR/../core"

# Read input from stdin
INPUT=$(cat)

# --- Translation Functions ---

translate_to_claude_format() {
    # Extract Copilot fields
    local tool_name=$(echo "$INPUT" | jq -r '.toolName // ""')
    local tool_args_str=$(echo "$INPUT" | jq -r '.toolArgs // "{}"')
    
    # Parse toolArgs (it's a JSON string)
    local tool_input=$(echo "$tool_args_str" | jq -c '.' 2>/dev/null || echo '{}')
    
    # Build Claude format
    jq -nc \
        --arg tool_name "$tool_name" \
        --argjson tool_input "$tool_input" \
        '{tool_name: $tool_name, tool_input: $tool_input}'
}

# --- Hook Handlers ---

handle_pre_tool_use() {
    local claude_input=$(translate_to_claude_format)
    
    # Call core script, capture stderr and exit code separately
    # We need to preserve the exit code while capturing stderr
    local tmpfile=$(mktemp)
    set +e
    echo "$claude_input" | "$CORE_DIR/pre-tool-use.sh" 2>"$tmpfile"
    local exit_code=$?
    set -e
    
    local error_msg=$(cat "$tmpfile")
    rm -f "$tmpfile"
    
    # Translate response
    if [[ $exit_code -eq 2 ]]; then
        # Blocked - return Copilot deny format
        jq -nc \
            --arg reason "$error_msg" \
            '{permissionDecision: "deny", permissionDecisionReason: $reason}'
    fi
    # Allow: no output needed (or could output {"permissionDecision":"allow"})
    
    exit 0  # Copilot always expects exit 0
}

handle_post_tool_use() {
    local tool_name=$(echo "$INPUT" | jq -r '.toolName // "unknown"')
    local result_type=$(echo "$INPUT" | jq -r '.toolResult.resultType // "unknown"')
    local timestamp=$(echo "$INPUT" | jq -r '.timestamp // 0')
    local cwd=$(echo "$INPUT" | jq -r '.cwd // ""')
    
    # Log event via core script
    "$CORE_DIR/log-event.sh" \
        "copilot" \
        "unknown" \
        "tool" \
        "text" \
        "$tool_name" \
        "$result_type" \
        "0" \
        "{\"cwd\":\"$cwd\",\"timestamp\":$timestamp}"
    
    exit 0
}

# --- Router ---

case "$HOOK_TYPE" in
    preToolUse)
        handle_pre_tool_use
        ;;
    postToolUse)
        handle_post_tool_use
        ;;
    *)
        echo "Error: Unknown hook type: $HOOK_TYPE" >&2
        echo "Usage: copilot-adapter.sh <preToolUse|postToolUse>" >&2
        exit 1
        ;;
esac

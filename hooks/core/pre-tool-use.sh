#!/usr/bin/env bash
# hooks/core/pre-tool-use.sh - Block dangerous commands before execution
# Usage: Called by Claude Code via .claude/settings.json PreToolUse hook
# Input: JSON via stdin with tool_name and tool_input fields
# Exit: 0 = allow, 2 = block tool + show error to Claude

set -euo pipefail

# Read JSON from stdin
INPUT=$(cat)

# Extract fields (with fallback if jq not available)
if command -v jq >/dev/null 2>&1; then
    TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
    COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.path // .tool_input.file_path // ""')
else
    # Fallback: basic grep extraction (less robust)
    TOOL_NAME=$(echo "$INPUT" | grep -oP '"tool_name"\s*:\s*"\K[^"]+' || echo "")
    COMMAND=$(echo "$INPUT" | grep -oP '"command"\s*:\s*"\K[^"]+' || echo "")
    FILE_PATH=$(echo "$INPUT" | grep -oP '"(path|file_path)"\s*:\s*"\K[^"]+' || echo "")
fi

# Block dangerous rm patterns
if [[ "$TOOL_NAME" == "bash" || "$TOOL_NAME" == "Bash" ]]; then
    # Block rm -rf, rm -fr, and recursive+force variations
    if echo "$COMMAND" | grep -qE 'rm\s+.*-[a-zA-Z]*r[a-zA-Z]*f|rm\s+.*-[a-zA-Z]*f[a-zA-Z]*r|rm\s+--recursive.*--force|rm\s+--force.*--recursive'; then
        echo "BLOCKED: Dangerous rm command detected. Use specific file paths without -rf" >&2
        exit 2
    fi
    
    # Block force push
    if echo "$COMMAND" | grep -qE 'git\s+push\s+(-f|--force)'; then
        echo "BLOCKED: Force push is prohibited. Create new branch or resolve conflicts" >&2
        exit 2
    fi
fi

# Block .env file access (except .env.example and .env.sample)
if [[ "$TOOL_NAME" =~ ^(Read|Write|Edit|read|write|edit|view|create)$ ]]; then
    # Allow .env.example and .env.sample
    if [[ "$FILE_PATH" =~ \.env$ ]] && [[ ! "$FILE_PATH" =~ \.(example|sample)$ ]]; then
        echo "BLOCKED: Direct .env access prohibited. Use .env.example or .env.sample" >&2
        exit 2
    fi
    
    # Block other common secret files
    if [[ "$FILE_PATH" =~ \.(pem|key|p12|pfx)$ ]]; then
        echo "BLOCKED: Direct secret file access prohibited" >&2
        exit 2
    fi
fi

# Allow all other operations
exit 0

#!/usr/bin/env bash
# hooks/core/log-event.sh - Emit structured telemetry event
# Usage: log-event.sh <agent> <model> <mode> <format> <event> <status> <attempt> <details>

set -euo pipefail

AGENT="${1:-unknown}"
MODEL="${2:-unknown}"
MODE="${3:-unknown}"
FORMAT="${4:-text}"
EVENT="${5:-unknown}"
STATUS="${6:-unknown}"
ATTEMPT="${7:-0}"
DETAILS="${8:-"{}"}"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
LOG_FILE="logs/session-events.jsonl"

# Ensure logs directory exists
mkdir -p logs

# Build JSON event (graceful fallback without jq)
if command -v jq >/dev/null 2>&1 && echo "$DETAILS" | jq . >/dev/null 2>&1; then
    # Use jq for proper JSON formatting if available and details is valid JSON
    # -c for compact output (JSONL requires one object per line)
    EVENT_JSON=$(jq -nc \
        --arg ts "$TIMESTAMP" \
        --arg agent "$AGENT" \
        --arg model "$MODEL" \
        --arg mode "$MODE" \
        --arg format "$FORMAT" \
        --arg event "$EVENT" \
        --arg status "$STATUS" \
        --arg attempt "$ATTEMPT" \
        --argjson details "$DETAILS" \
        '{
            timestamp: $ts,
            agent: $agent,
            model: $model,
            mode: $mode,
            format: $format,
            event: $event,
            status: $status,
            attempt: ($attempt | tonumber),
            details: $details
        }')
else
    # Fallback: construct JSON with printf (basic escaping)
    EVENT_JSON=$(cat <<EOF
{"timestamp":"${TIMESTAMP}","agent":"${AGENT}","model":"${MODEL}","mode":"${MODE}","format":"${FORMAT}","event":"${EVENT}","status":"${STATUS}","attempt":${ATTEMPT},"details":${DETAILS}}
EOF
)
fi

# Append to JSONL file
echo "$EVENT_JSON" >> "$LOG_FILE"

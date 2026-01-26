#!/usr/bin/env bash
set -euo pipefail

# analyze-session.sh - Analyze loopy session logs
# Usage:
#   ./analyze-session.sh                     # Analyze most recent log
#   ./analyze-session.sh logs/log-*.txt      # Analyze specific log

LOGS_DIR="logs"
TARGET="${1:-}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Find target log
if [ -z "$TARGET" ]; then
    # No argument: find most recent log
    TARGET=$(ls -t "$LOGS_DIR"/log-*.txt 2>/dev/null | head -1)
    if [ -z "$TARGET" ]; then
        echo -e "${YELLOW}No logs found in $LOGS_DIR${NC}"
        echo "Run ./loop.sh first to generate logs"
        exit 1
    fi
    echo "Analyzing most recent: $(basename "$TARGET")"
    echo ""
elif [ ! -f "$TARGET" ]; then
    echo -e "${RED}Log file not found: $TARGET${NC}"
    echo ""
    echo "Available logs:"
    ls -1t "$LOGS_DIR"/log-*.txt 2>/dev/null | head -5 | while read -r f; do
        echo "  • $(basename "$f")"
    done
    exit 1
fi

FILENAME=$(basename "$TARGET")

# Check for jq
if ! command -v jq >/dev/null 2>&1; then
    echo -e "${RED}Error: jq is required but not installed${NC}"
    echo "Install with: sudo apt install jq  # or brew install jq"
    exit 1
fi

# Extract metadata from log header
MODE=$(grep "^Mode:" "$TARGET" | head -1 | awk '{print $2}' || echo "unknown")
MODEL=$(grep "^Model:" "$TARGET" | head -1 | awk '{print $2}' || echo "unknown")
BRANCH=$(grep "^Branch:" "$TARGET" | head -1 | awk '{print $2}' || echo "unknown")
MAX_ITER=$(grep "^Max:" "$TARGET" | head -1 | awk '{print $2}' || echo "unknown")
AGENT=$(grep "^Agent:" "$TARGET" | head -1 | awk '{print $2}' || echo "claude")

# Determine output format from config (for graceful degradation)
CONFIG_FILE="loopy.config.json"
if [ -f "$CONFIG_FILE" ]; then
    OUTPUT_FORMAT=$(jq -r ".agents.${AGENT}.outputFormat // \"stream-json\"" "$CONFIG_FILE" 2>/dev/null || echo "stream-json")
else
    # Assume stream-json if no config (backward compat with claude default)
    OUTPUT_FORMAT="stream-json"
fi

# Count iterations from text logs
ITERATIONS_STARTED=$(grep -c "^Starting iteration" "$TARGET" || echo "0")
ITERATIONS_COMPLETED=$(grep -c "^Iteration .* complete" "$TARGET" || echo "0")

# Initialize defaults for non-JSON agents
IS_ERROR="false"
TOTAL_COST="0"
DURATION_MS="0"
DURATION_SEC="0"
NUM_TURNS="0"
RESULT_JSON=""

# JSON parsing only for stream-json output format
if [ "$OUTPUT_FORMAT" = "stream-json" ]; then
    # Extract JSON result entry
    RESULT_JSON=$(grep '"type":"result"' "$TARGET" | tail -1)

    if [ -z "$RESULT_JSON" ]; then
        echo -e "${YELLOW}Warning: No result entry found in log${NC}"
        echo "This may be an incomplete or malformed log file"
        echo ""
    fi

    # Parse result data
    IS_ERROR=$(echo "$RESULT_JSON" | jq -r '.is_error // false' 2>/dev/null || echo "false")
    TOTAL_COST=$(echo "$RESULT_JSON" | jq -r '.total_cost_usd // 0' 2>/dev/null || echo "0")
    DURATION_MS=$(echo "$RESULT_JSON" | jq -r '.duration_ms // 0' 2>/dev/null || echo "0")
    NUM_TURNS=$(echo "$RESULT_JSON" | jq -r '.num_turns // 0' 2>/dev/null || echo "0")

    # Convert duration to human readable
    DURATION_SEC=$(echo "scale=1; $DURATION_MS / 1000" | bc 2>/dev/null || echo "0")
fi

# Detect stop condition
STOP_CONDITION="unknown"
if grep -q "Max iterations reached" "$TARGET"; then
    STOP_CONDITION="max_iterations"
elif grep -q "No pending tasks in plan.md" "$TARGET"; then
    STOP_CONDITION="plan_empty"
elif grep -q "^Rate limit detected" "$TARGET"; then
    STOP_CONDITION="rate_limit"
elif grep -q "Agent signaled completion" "$TARGET"; then
    STOP_CONDITION="completion_signal"
elif [ "$IS_ERROR" = "true" ]; then
    STOP_CONDITION="execution_error"
fi

# Print report header
echo "═══════════════════════════════════════════════════════════════"
echo "Session Analysis: $FILENAME"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Configuration
echo "Configuration:"
echo "  Mode:        $MODE"
echo "  Model:       $MODEL"
echo "  Agent:       $AGENT"
echo "  Branch:      $BRANCH"
echo "  Max iter:    $MAX_ITER"
echo ""

# Execution summary
echo "Execution:"
echo "  Iterations started:   $ITERATIONS_STARTED"
echo "  Iterations completed: $ITERATIONS_COMPLETED"
echo "  Duration:             ${DURATION_SEC}s"
echo "  Turns:                $NUM_TURNS"
echo "  Stop condition:       $STOP_CONDITION"
echo ""

# Cost Analysis - only available for stream-json output
if [ "$OUTPUT_FORMAT" != "stream-json" ]; then
    echo "Cost Analysis:"
    echo "  Cost/Token analysis not available for agent: $AGENT"
    echo "  (agent uses $OUTPUT_FORMAT output format, not stream-json)"
    echo ""
elif [ -n "$RESULT_JSON" ] && [ "$TOTAL_COST" != "0" ]; then
    echo "Cost Analysis:"
    # Use LC_NUMERIC=C to ensure consistent decimal formatting
    LC_NUMERIC=C printf "  Total Cost: \$%.4f\n" "$TOTAL_COST"
    echo ""

    # Per-model breakdown
    echo "  Model Breakdown:"
    echo "$RESULT_JSON" | jq -r '.modelUsage // {} | to_entries[] |
        "    " + .key + ": $" + (.value.costUSD | tostring) + "\n" +
        "      Input:  " + (.value.inputTokens | tostring) + " tokens" +
        (if .value.cacheReadInputTokens > 0 then " (" + (.value.cacheReadInputTokens | tostring) + " cache read)" else "" end) +
        (if .value.cacheCreationInputTokens > 0 then " (" + (.value.cacheCreationInputTokens | tostring) + " cache creation)" else "" end) + "\n" +
        "      Output: " + (.value.outputTokens | tostring) + " tokens"
    ' 2>/dev/null || echo "    (parsing error)"
    echo ""

    # Token efficiency
    TOTAL_INPUT=$(echo "$RESULT_JSON" | jq -r '.usage.input_tokens // 0' 2>/dev/null || echo "0")
    TOTAL_CACHE_READ=$(echo "$RESULT_JSON" | jq -r '.usage.cache_read_input_tokens // 0' 2>/dev/null || echo "0")
    TOTAL_CACHE_CREATION=$(echo "$RESULT_JSON" | jq -r '.usage.cache_creation_input_tokens // 0' 2>/dev/null || echo "0")
    TOTAL_OUTPUT=$(echo "$RESULT_JSON" | jq -r '.usage.output_tokens // 0' 2>/dev/null || echo "0")

    TOTAL_INPUT_WITH_CACHE=$((TOTAL_INPUT + TOTAL_CACHE_CREATION + TOTAL_CACHE_READ))

    if [ "$TOTAL_INPUT_WITH_CACHE" -gt 0 ]; then
        CACHE_HIT_RATE=$(echo "scale=1; 100 * $TOTAL_CACHE_READ / $TOTAL_INPUT_WITH_CACHE" | bc 2>/dev/null || echo "0")
        echo "  Token Efficiency:"
        echo "    Total input:  $TOTAL_INPUT_WITH_CACHE tokens ($TOTAL_INPUT regular, $TOTAL_CACHE_CREATION cache creation, $TOTAL_CACHE_READ cache read)"
        echo "    Total output: $TOTAL_OUTPUT tokens"
        echo "    Cache hit rate: ${CACHE_HIT_RATE}%"
        echo ""
    fi
fi

# Error detection - only real errors
if [ "$IS_ERROR" = "true" ]; then
    echo -e "${RED}Errors:${NC}"
    echo "  ⚠ Execution failed"

    # Extract error details
    ERROR_SUBTYPE=$(echo "$RESULT_JSON" | jq -r '.subtype // "unknown"' 2>/dev/null || echo "unknown")
    ERROR_RESULT=$(echo "$RESULT_JSON" | jq -r '.result // ""' 2>/dev/null || echo "")

    if [ "$ERROR_SUBTYPE" != "unknown" ] && [ "$ERROR_SUBTYPE" != "null" ]; then
        echo "  Type: $ERROR_SUBTYPE"
    fi

    if [ -n "$ERROR_RESULT" ] && [ "$ERROR_RESULT" != "null" ]; then
        echo "  Reason: $ERROR_RESULT" | head -c 200
        [ ${#ERROR_RESULT} -gt 200 ] && echo "..."
    fi

    echo ""
fi

# Rate limit warning
if [ "$STOP_CONDITION" = "rate_limit" ]; then
    echo -e "${RED}⚠ Rate Limit Hit${NC}"
    echo "  API quota exhausted. Wait before retrying."
    echo ""
fi

# Success indicator
if [ "$IS_ERROR" = "false" ] && [ "$STOP_CONDITION" != "rate_limit" ]; then
    echo -e "Status: ${GREEN}✓ Clean execution${NC}"
    echo ""
fi

# Footer
echo "───────────────────────────────────────────────────────────────"
echo "Full log: $TARGET"
echo "───────────────────────────────────────────────────────────────"

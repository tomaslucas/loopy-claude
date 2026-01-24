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

# Extract metadata from log
MODE=$(grep "^Mode:" "$TARGET" | head -1 | awk '{print $2}' || echo "unknown")
MODEL=$(grep "^Model:" "$TARGET" | head -1 | awk '{print $2}' || echo "unknown")
BRANCH=$(grep "^Branch:" "$TARGET" | head -1 | awk '{print $2}' || echo "unknown")
MAX_ITER=$(grep "^Max:" "$TARGET" | head -1 | awk '{print $2}' || echo "unknown")

# Count iterations
ITERATIONS_STARTED=$(grep -c "^Starting iteration" "$TARGET" || echo "0")
ITERATIONS_COMPLETED=$(grep -c "^Iteration .* complete" "$TARGET" || echo "0")

# Detect stop condition
STOP_CONDITION="unknown"
if grep -q "Max iterations reached" "$TARGET"; then
    STOP_CONDITION="max_iterations"
elif grep -q "No pending tasks in plan.md" "$TARGET"; then
    STOP_CONDITION="plan_empty"
elif grep -q "Rate limit detected" "$TARGET"; then
    STOP_CONDITION="rate_limit"
elif grep -q "Agent signaled completion" "$TARGET"; then
    STOP_CONDITION="completion_signal"
elif grep -q "Error: Claude execution failed" "$TARGET"; then
    STOP_CONDITION="execution_error"
fi

# Check for errors
ERROR_COUNT=$(grep -ic "error" "$TARGET" || echo "0")
FAILED_COUNT=$(grep -ic "failed" "$TARGET" || echo "0")

# Check git pushes
PUSH_COUNT=$(grep -c "^Pushing changes" "$TARGET" || echo "0")
PUSH_ERRORS=$(grep -c "fatal.*push\|error.*push" "$TARGET" || echo "0")

# Detect warnings
WARNING_COUNT=$(grep -ic "warning\|warn" "$TARGET" || echo "0")

# Print report
echo "═══════════════════════════════════════════════════════════════"
echo "Session Analysis: $FILENAME"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Configuration:"
echo "  Mode:        $MODE"
echo "  Model:       $MODEL"
echo "  Branch:      $BRANCH"
echo "  Max iter:    $MAX_ITER"
echo ""
echo "Execution:"
echo "  Iterations started:   $ITERATIONS_STARTED"
echo "  Iterations completed: $ITERATIONS_COMPLETED"
echo "  Stop condition:       $STOP_CONDITION"
echo ""

# Git activity
if [ "$PUSH_COUNT" -gt 0 ]; then
    echo "Git Activity:"
    echo "  Pushes:        $PUSH_COUNT"
    if [ "$PUSH_ERRORS" -gt 0 ]; then
        echo -e "  Push errors:   ${RED}$PUSH_ERRORS${NC}"
    else
        echo -e "  Push errors:   ${GREEN}0${NC}"
    fi
    echo ""
fi

# Issues
ISSUES=false

if [ "$ERROR_COUNT" -gt 0 ] || [ "$FAILED_COUNT" -gt 0 ]; then
    ISSUES=true
    echo -e "${RED}Issues Detected:${NC}"
    [ "$ERROR_COUNT" -gt 0 ] && echo "  ⚠ Errors: $ERROR_COUNT occurrences"
    [ "$FAILED_COUNT" -gt 0 ] && echo "  ⚠ Failures: $FAILED_COUNT occurrences"
    echo ""
fi

if [ "$WARNING_COUNT" -gt 0 ]; then
    ISSUES=true
    echo -e "${YELLOW}Warnings: $WARNING_COUNT occurrences${NC}"
    echo ""
fi

if [ "$STOP_CONDITION" = "rate_limit" ]; then
    ISSUES=true
    echo -e "${RED}⚠ Rate Limit Hit${NC}"
    echo "  API quota exhausted. Wait before retrying."
    echo ""
fi

if [ "$STOP_CONDITION" = "execution_error" ]; then
    ISSUES=true
    echo -e "${RED}⚠ Execution Error${NC}"
    echo "  Claude CLI failed. Check log for details."
    echo ""
fi

# Summary
if [ "$ISSUES" = false ]; then
    echo -e "Status: ${GREEN}✓ Clean execution${NC}"
    echo ""
fi

# Recommendations
echo "Recommendations:"

if [ "$STOP_CONDITION" = "max_iterations" ] && [ "$MODE" = "build" ]; then
    echo "  • Max iterations reached but tasks may remain"
    echo "    Check plan.md and continue with: ./loop.sh build N"
fi

if [ "$STOP_CONDITION" = "rate_limit" ]; then
    echo "  • Wait 10-15 minutes before retrying"
    echo "  • Consider using --model haiku for cheaper runs"
fi

if [ "$ERROR_COUNT" -gt 5 ]; then
    echo "  • High error count ($ERROR_COUNT)"
    echo "    Review log for recurring issues: grep -i error $TARGET"
fi

if [ "$WARNING_COUNT" -gt 10 ]; then
    echo "  • Many warnings ($WARNING_COUNT)"
    echo "    Review: grep -i warn $TARGET"
fi

if [ "$PUSH_ERRORS" -gt 0 ]; then
    echo "  • Git push failed"
    echo "    Check branch permissions and upstream configuration"
fi

if [ "$ITERATIONS_COMPLETED" -eq 0 ] && [ "$ITERATIONS_STARTED" -gt 0 ]; then
    echo "  • No iterations completed despite starting"
    echo "    Possible early termination or crash"
fi

echo ""
echo "───────────────────────────────────────────────────────────────"
echo "Full log: $TARGET"
echo "───────────────────────────────────────────────────────────────"

#!/usr/bin/env bash
# shellcheck disable=SC2155
set -euo pipefail

# loop.sh - Simple orchestrator for loopy
# Usage:
#   ./loop.sh [mode] [max_iterations] [--model MODEL]
#   ./loop.sh plan 5                    # Plan mode, max 5 iterations, opus
#   ./loop.sh build                     # Build mode, default max 1, sonnet
#   ./loop.sh build 10 --model haiku    # Build mode, 10 iterations, haiku
#   ./loop.sh reverse --model opus 3    # Reverse mode, opus, max 3

# Parse arguments
MODE=""
MAX_ITERATIONS=""
MODEL_OVERRIDE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --model)
            MODEL_OVERRIDE="$2"
            shift 2
            ;;
        --*)
            echo "Error: Unknown flag $1"
            exit 1
            ;;
        *)
            if [ -z "$MODE" ]; then
                MODE="$1"
            elif [ -z "$MAX_ITERATIONS" ]; then
                MAX_ITERATIONS="$1"
            else
                echo "Error: Unexpected argument $1"
                exit 1
            fi
            shift
            ;;
    esac
done

# Apply defaults
MODE="${MODE:-build}"
MAX_ITERATIONS="${MAX_ITERATIONS:-1}"
PROMPT_FILE="prompts/${MODE}.md"

# Setup logging
LOGS_DIR="logs"
mkdir -p "$LOGS_DIR"
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE="$LOGS_DIR/log-${MODE}-${TIMESTAMP}.txt"

# Log function (outputs to both stdout and file)
log() {
    echo "$@" | tee -a "$LOG_FILE"
}

# Validate mode
if [[ ! -f "$PROMPT_FILE" ]]; then
    log "Error: prompts/${MODE}.md not found"
    log "Available modes: plan, build, reverse"
    exit 1
fi

# Validate max_iterations is a number
if ! [[ "$MAX_ITERATIONS" =~ ^[0-9]+$ ]]; then
    log "Error: max_iterations must be a number"
    log "Usage: ./loop.sh [mode] [max_iterations] [--model MODEL]"
    exit 1
fi

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)

# Select model based on mode
case "$MODE" in
    plan)
        MODEL="opus"        # Needs extended_thinking
        ;;
    reverse)
        MODEL="opus"        # JTBD inference + grouping needs reasoning
        ;;
    *)
        MODEL="sonnet"      # Build is straightforward
        ;;
esac

# Apply overrides (CLI flag takes precedence over env var)
if [ -n "$MODEL_OVERRIDE" ]; then
    MODEL="$MODEL_OVERRIDE"
elif [ -n "${LOOPY_MODEL:-}" ]; then
    MODEL="$LOOPY_MODEL"
fi

# Banner
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "Mode:   $MODE"
log "Model:  $MODEL"
log "Branch: $CURRENT_BRANCH"
log "Prompt: $PROMPT_FILE"
log "Max:    $MAX_ITERATIONS iteration(s)"
log "Log:    $LOG_FILE"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log ""

ITERATION=0

while true; do
    # Stop 1: Max iterations reached
    if [ "$ITERATION" -ge "$MAX_ITERATIONS" ]; then
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log "Max iterations reached: $MAX_ITERATIONS"
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        break
    fi

    # Stop 2: Empty plan (build mode only)
    if [ "$MODE" = "build" ]; then
        if ! grep -q -- '- \[ \]' plan.md 2>/dev/null; then
            log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            log "No pending tasks in plan.md"
            log "All work complete!"
            log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            break
        fi
    fi

    # Execute iteration
    log "Starting iteration $((ITERATION + 1))/$MAX_ITERATIONS..."
    log ""

    # Run Claude (output to both screen and log, capture for checks)
    OUTPUT=$(cat "$PROMPT_FILE" | claude -p \
        --model "$MODEL" \
        --dangerously-skip-permissions \
        --output-format=stream-json \
        --verbose 2>&1 | tee -a "$LOG_FILE") || {
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log "Error: Claude execution failed"
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        exit 1
    }

    # Stop 3: Rate limit detected (check JSON error messages only)
    if echo "$OUTPUT" | jq -e 'select(.error.type == "rate_limit_error" or .error.type == "overloaded_error" or (.error.message // "" | test("rate.?limit|quota.*exhausted"; "i")))' >/dev/null 2>&1; then
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log "Rate limit detected"
        log "API quota exhausted. Try again later."
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        break
    fi

    # Stop 4: Completion signal
    if echo "$OUTPUT" | grep -q '<promise>COMPLETE</promise>'; then
        log ""
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log "Agent signaled completion"
        log "All work finished!"
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        break
    fi

    # Push changes (if any)
    if git diff --quiet && git diff --cached --quiet; then
        log "No changes to push"
    else
        log "Pushing changes..."
        git push origin "$CURRENT_BRANCH" 2>&1 | tee -a "$LOG_FILE" || \
            git push -u origin "$CURRENT_BRANCH" 2>&1 | tee -a "$LOG_FILE"
    fi

    ITERATION=$((ITERATION + 1))
    log ""
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "Iteration $ITERATION complete"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log ""
done

log ""
log "Loop finished after $ITERATION iteration(s)"
log "Full log saved to: $LOG_FILE"

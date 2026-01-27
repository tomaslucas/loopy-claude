#!/usr/bin/env bash
# shellcheck disable=SC2155
set -euo pipefail

# loop.sh - Simple orchestrator for loopy
# Usage:
#   ./loop.sh [mode] [max_iterations] [--model MODEL] [--agent AGENT]
#   ./loop.sh plan 5                    # Plan mode, max 5 iterations, opus
#   ./loop.sh build                     # Build mode, default max 1, sonnet
#   ./loop.sh build 10 --model haiku    # Build mode, 10 iterations, haiku
#   ./loop.sh reverse --model opus 3    # Reverse mode, opus, max 3
#   ./loop.sh build --agent copilot     # Build with Copilot agent

# Dependency checking functions
detect_platform() {
    case "$(uname -s)" in
        Linux*)
            if [ -f /etc/debian_version ]; then
                echo "debian"
            elif [ -f /etc/redhat-release ]; then
                echo "redhat"
            elif [ -f /etc/arch-release ]; then
                echo "arch"
            else
                echo "linux"
            fi
            ;;
        Darwin*)
            echo "macos"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            echo "windows"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

suggest_install() {
    local cmd="$1"
    local platform=$(detect_platform)

    case "$cmd" in
        jq)
            case "$platform" in
                debian) echo "    Install: sudo apt install jq" ;;
                redhat) echo "    Install: sudo dnf install jq" ;;
                arch)   echo "    Install: sudo pacman -S jq" ;;
                macos)  echo "    Install: brew install jq" ;;
                *)      echo "    Install: https://stedolan.github.io/jq/download/" ;;
            esac
            ;;
        git)
            case "$platform" in
                debian) echo "    Install: sudo apt install git" ;;
                redhat) echo "    Install: sudo dnf install git" ;;
                arch)   echo "    Install: sudo pacman -S git" ;;
                macos)  echo "    Install: xcode-select --install" ;;
                *)      echo "    Install: https://git-scm.com/downloads" ;;
            esac
            ;;
        awk)
            case "$platform" in
                debian) echo "    Install: sudo apt install gawk" ;;
                redhat) echo "    Install: sudo dnf install gawk" ;;
                macos)  echo "    Note: awk is pre-installed on macOS" ;;
                *)      echo "    Install: Check your package manager for gawk" ;;
            esac
            ;;
        *)
            echo "    Install: Check your package manager"
            ;;
    esac
}

check_dependencies() {
    local missing_required=()
    local missing_optional=()

    # Required dependencies
    for cmd in git awk tee grep; do
        if ! command -v "$cmd" &>/dev/null; then
            missing_required+=("$cmd")
        fi
    done

    # Optional dependencies
    for cmd in jq; do
        if ! command -v "$cmd" &>/dev/null; then
            missing_optional+=("$cmd")
        fi
    done

    # Report missing required
    if [ ${#missing_required[@]} -gt 0 ]; then
        echo "Error: Missing required dependencies:"
        for cmd in "${missing_required[@]}"; do
            echo "  - $cmd"
            suggest_install "$cmd"
        done
        exit 3
    fi

    # Warn about missing optional
    if [ ${#missing_optional[@]} -gt 0 ]; then
        echo "Warning: Missing optional dependencies:"
        for cmd in "${missing_optional[@]}"; do
            echo "  - $cmd (will use fallback)"
            suggest_install "$cmd"
        done
        echo ""
    fi
}

# Help function
show_help() {
    cat << 'EOF'
Usage: ./loop.sh <mode> [max_iterations] [--model MODEL] [--agent AGENT]

Modes:
  plan        Generate implementation plan from specs (opus)
  build       Execute ONE task from plan.md (sonnet)
  validate    Validate ONE spec from pending-validations.md (sonnet)
  reverse     Analyze legacy code, generate specs (opus)
  work        Alternate build/validate until complete (sonnet)
  audit       Audit repository for spec compliance (opus)
  prime       Orient and understand the repository
  bug         Analyze a bug and create corrective tasks
  post-mortem Analyze session logs for learning
  reconcile   Resolve escalated spec-code divergences (opus)

Options:
  --model MODEL   Override default model (opus/sonnet/haiku)
  --agent AGENT   Use specific agent (claude/copilot)
  --log FILE      Use specific log file (for post-mortem)

Examples:
  ./loop.sh plan                # Generate plan (completes in 1 iteration)
  ./loop.sh build               # Execute one build task
  ./loop.sh work 20             # Run build/validate cycle
  ./loop.sh audit               # Full repository audit
  ./loop.sh build --agent copilot
EOF
    exit 0
}

# Show help if no arguments
if [[ $# -eq 0 ]]; then
    show_help
fi

# Parse arguments
MODE=""
MAX_ITERATIONS=""
MODEL_OVERRIDE=""
AGENT_OVERRIDE=""
LOG_OVERRIDE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            ;;
        --model)
            MODEL_OVERRIDE="$2"
            shift 2
            ;;
        --agent)
            AGENT_OVERRIDE="$2"
            shift 2
            ;;
        --log)
            LOG_OVERRIDE="$2"
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
                # Check if this looks like a file path (for post-mortem mode)
                if [[ "$1" == *"/"* || "$1" == *.txt || "$1" == *.log ]]; then
                    LOG_OVERRIDE="$1"
                else
                    MAX_ITERATIONS="$1"
                fi
            elif [ -z "$LOG_OVERRIDE" ]; then
                # Third positional argument: log file (for post-mortem mode)
                LOG_OVERRIDE="$1"
            else
                echo "Error: Unexpected argument $1"
                exit 1
            fi
            shift
            ;;
    esac
done

# Check dependencies early (before any operations)
check_dependencies

# Set JQ_AVAILABLE flag for fallback logic
JQ_AVAILABLE=true
command -v jq &>/dev/null || JQ_AVAILABLE=false

# Apply defaults
MODE="${MODE:-build}"
# Work mode: calculate iterations from pending tasks + validations
# Uses 2x multiplier as safety margin (validations may generate corrective tasks)
# The loop exits naturally when no pending work remains; MAX_ITERATIONS is a safety cap
if [ -z "$MAX_ITERATIONS" ]; then
    if [ "$MODE" = "work" ]; then
        PENDING_TASKS=$(grep -c -- '- \[ \]' plan.md 2>/dev/null) || PENDING_TASKS=0
        PENDING_VALIDATIONS=$(grep -c -- '- \[ \]' pending-validations.md 2>/dev/null) || PENDING_VALIDATIONS=0
        MAX_ITERATIONS=$(( (PENDING_TASKS + PENDING_VALIDATIONS) * 2 ))
        [ "$MAX_ITERATIONS" -lt 1 ] && MAX_ITERATIONS=1
    else
        MAX_ITERATIONS=1
    fi
fi
PROMPT_FILE=".claude/commands/${MODE}.md"

# Resolve agent (flag > env > config default > hardcoded)
CONFIG_FILE="loopy.config.json"
if [ -n "$AGENT_OVERRIDE" ]; then
    AGENT_NAME="$AGENT_OVERRIDE"
elif [ -n "${LOOPY_AGENT:-}" ]; then
    AGENT_NAME="$LOOPY_AGENT"
elif [ -f "$CONFIG_FILE" ]; then
    if [ "$JQ_AVAILABLE" = true ]; then
        AGENT_NAME=$(jq -r '.default // "claude"' "$CONFIG_FILE")
    else
        # Fallback: grep + sed for config parsing
        AGENT_NAME=$(grep '"default"' "$CONFIG_FILE" 2>/dev/null | sed 's/.*: *"\([^"]*\)".*/\1/' || echo "claude")
        [ -z "$AGENT_NAME" ] && AGENT_NAME="claude"
    fi
else
    AGENT_NAME="claude"
fi

# Load agent configuration
load_agent_config() {
    local agent="$1"
    local field="$2"
    if [ -f "$CONFIG_FILE" ]; then
        if [ "$JQ_AVAILABLE" = true ]; then
            jq -r ".agents.${agent}.${field} // empty" "$CONFIG_FILE"
        else
            # Fallback: grep + sed (limited functionality)
            grep "\"${field}\"" "$CONFIG_FILE" 2>/dev/null | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/' || echo ""
        fi
    fi
}

# Validate agent exists in config
if [ -f "$CONFIG_FILE" ]; then
    if [ "$JQ_AVAILABLE" = true ]; then
        if ! jq -e ".agents.${AGENT_NAME}" "$CONFIG_FILE" >/dev/null 2>&1; then
            echo "Error: Unknown agent '$AGENT_NAME'"
            echo "Available agents: $(jq -r '.agents | keys | join(", ")' "$CONFIG_FILE")"
            exit 1
        fi
    else
        # Fallback: basic grep check
        if ! grep -q "\"${AGENT_NAME}\"" "$CONFIG_FILE" 2>/dev/null; then
            echo "Error: Unknown agent '$AGENT_NAME'"
            echo "Check loopy.config.json for available agents"
            exit 1
        fi
    fi
fi

# Get agent configuration
AGENT_COMMAND=$(load_agent_config "$AGENT_NAME" "command")
AGENT_COMMAND="${AGENT_COMMAND:-claude}"
AGENT_PROMPT_FLAG=$(load_agent_config "$AGENT_NAME" "promptFlag")
AGENT_PROMPT_FLAG="${AGENT_PROMPT_FLAG:--p}"
AGENT_MODEL_FLAG=$(load_agent_config "$AGENT_NAME" "modelFlag")
AGENT_MODEL_FLAG="${AGENT_MODEL_FLAG:---model}"
AGENT_EXTRA_ARGS=$(load_agent_config "$AGENT_NAME" "extraArgs")
AGENT_EXTRA_ARGS="${AGENT_EXTRA_ARGS:---dangerously-skip-permissions --output-format=stream-json --verbose}"
AGENT_OUTPUT_FORMAT=$(load_agent_config "$AGENT_NAME" "outputFormat")
AGENT_OUTPUT_FORMAT="${AGENT_OUTPUT_FORMAT:-stream-json}"
AGENT_RATE_LIMIT_PATTERN=$(load_agent_config "$AGENT_NAME" "rateLimitPattern")
AGENT_RATE_LIMIT_PATTERN="${AGENT_RATE_LIMIT_PATTERN:-rate_limit_error|overloaded_error}"

# Function to map logical model name to agent-specific model
map_model_name() {
    local agent="$1"
    local logical_model="$2"
    if [ -f "$CONFIG_FILE" ]; then
        if [ "$JQ_AVAILABLE" = true ]; then
            local mapped=$(jq -r ".agents.${agent}.models.${logical_model} // empty" "$CONFIG_FILE")
            if [ -n "$mapped" ]; then
                echo "$mapped"
                return
            fi
        else
            # Fallback: grep for model mapping (limited)
            local mapped=$(grep "\"${logical_model}\"" "$CONFIG_FILE" 2>/dev/null | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/' || echo "")
            if [ -n "$mapped" ]; then
                echo "$mapped"
                return
            fi
        fi
    fi
    echo "$logical_model"
}

# Function to build agent command
build_agent_command() {
    local model="$1"
    local actual_model=$(map_model_name "$AGENT_NAME" "$model")
    echo "$AGENT_COMMAND $AGENT_PROMPT_FLAG $AGENT_MODEL_FLAG $actual_model $AGENT_EXTRA_ARGS"
}

# Function to execute agent (handles stdin vs argument prompt delivery)
execute_agent() {
    local prompt_file="$1"
    local model="$2"
    local arguments="${3:-}"
    local actual_model=$(map_model_name "$AGENT_NAME" "$model")
    
    # Build prompt content with optional $ARGUMENTS injection
    local prompt_content
    prompt_content=$(filter_frontmatter "$prompt_file")
    
    # Inject $ARGUMENTS if provided
    if [ -n "$arguments" ]; then
        prompt_content="# Arguments

\$ARGUMENTS=\"$arguments\"

---

$prompt_content"
    fi
    
    if [[ "$AGENT_NAME" == "copilot" ]]; then
        # Copilot: prompt as argument
        $AGENT_COMMAND $AGENT_PROMPT_FLAG "$prompt_content" $AGENT_MODEL_FLAG "$actual_model" $AGENT_EXTRA_ARGS 2>&1
    else
        # Claude and others: prompt via stdin
        echo "$prompt_content" | $AGENT_COMMAND $AGENT_PROMPT_FLAG $AGENT_MODEL_FLAG "$actual_model" $AGENT_EXTRA_ARGS 2>&1
    fi
}

# Function to check for rate limit based on agent output format
check_rate_limit() {
    local output="$1"
    if [[ "$AGENT_OUTPUT_FORMAT" == "stream-json" ]]; then
        # JSON-based rate limit check
        if [ "$JQ_AVAILABLE" = true ]; then
            if echo "$output" | jq -e 'select(.error.type == "rate_limit_error" or .error.type == "overloaded_error" or (.error.message // "" | test("rate.?limit|quota.*exhausted"; "i")))' >/dev/null 2>&1; then
                return 0
            fi
        else
            # Fallback: grep-based rate limit detection
            if echo "$output" | grep -qiE 'rate_limit_error|overloaded_error|quota.*exhausted'; then
                return 0
            fi
        fi
    else
        # Text-based rate limit check using pattern from config
        if echo "$output" | grep -qiE "$AGENT_RATE_LIMIT_PATTERN"; then
            return 0
        fi
    fi
    return 1
}

# Setup logging
LOGS_DIR="logs"
mkdir -p "$LOGS_DIR"
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE="$LOGS_DIR/log-${MODE}-${TIMESTAMP}.txt"

# Log function (outputs to both stdout and file)
log() {
    echo "$@" | tee -a "$LOG_FILE"
}

# Filter YAML frontmatter from command files
# Removes everything from line 1 (if ---) through the next --- line
filter_frontmatter() {
    local file="$1"
    awk '
        BEGIN { in_frontmatter = 0; found_end = 0 }
        NR == 1 && /^---$/ { in_frontmatter = 1; next }
        in_frontmatter && /^---$/ { in_frontmatter = 0; found_end = 1; next }
        !in_frontmatter { print }
    ' "$file"
}

# Validate mode (work mode doesn't need its own prompt file)
if [[ "$MODE" != "work" && ! -f "$PROMPT_FILE" ]]; then
    log "Error: .claude/commands/${MODE}.md not found"
    log "Available modes: plan, build, reverse, validate, work, audit, prime, bug, post-mortem, reconcile"
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
    validate)
        MODEL="sonnet"      # Straightforward checklist + orchestration
        ;;
    post-mortem)
        MODEL="sonnet"      # Log analysis is straightforward
        ;;
    audit)
        MODEL="opus"        # Deep analysis requires reasoning
        ;;
    reconcile)
        MODEL="opus"        # Divergence analysis requires reasoning
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
log "Agent:  $AGENT_NAME"
log "Mode:   $MODE"
log "Model:  $MODEL"
log "Branch: $CURRENT_BRANCH"
if [ "$MODE" != "work" ]; then
    log "Prompt: $PROMPT_FILE"
fi
log "Max:    $MAX_ITERATIONS iteration(s)"
log "Log:    $LOG_FILE"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log ""

ITERATION=0

# Handle work mode specially (alternates build/validate automatically)
if [ "$MODE" = "work" ]; then
    log "Work mode: alternating build/validate until complete"
    log ""

    while [ "$ITERATION" -lt "$MAX_ITERATIONS" ]; do
        # Priority 1: Pending tasks
        if grep -q -- '- \[ \]' plan.md 2>/dev/null; then
            log "Found pending tasks - running build..."
            CURRENT_MODE="build"
        # Priority 2: Pending validations
        elif grep -q -- '- \[ \]' pending-validations.md 2>/dev/null; then
            log "Found pending validations - running validate..."
            CURRENT_MODE="validate"
        else
            log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            log "No pending work - all complete!"
            log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            break
        fi

        # Set model for current mode
        case "$CURRENT_MODE" in
            build) CURRENT_MODEL="sonnet" ;;
            validate) CURRENT_MODEL="sonnet" ;;
        esac

        # Apply model override if provided
        if [ -n "$MODEL_OVERRIDE" ]; then
            CURRENT_MODEL="$MODEL_OVERRIDE"
        fi

        # Execute single iteration
        log "Starting work iteration $((ITERATION + 1))/$MAX_ITERATIONS (mode: $CURRENT_MODE, model: $CURRENT_MODEL)..."
        log ""

        CURRENT_PROMPT=".claude/commands/${CURRENT_MODE}.md"
        OUTPUT=$(execute_agent "$CURRENT_PROMPT" "$CURRENT_MODEL" "" | tee -a "$LOG_FILE") || {
            log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            log "Error: $AGENT_NAME execution failed"
            log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            exit 1
        }

        # Check for rate limit
        if check_rate_limit "$OUTPUT"; then
            log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            log "Rate limit detected"
            log "API quota exhausted. Try again later."
            log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            break
        fi

        # Check for ESCALATE signal (validation hit 3 attempts, needs human)
        if echo "$OUTPUT" | grep -q '<promise>ESCALATE</promise>'; then
            log ""
            log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            log "ESCALATE: Validation requires human intervention"
            log "A spec has failed validation 3 times."
            log "Review pending-validations.md for details."
            log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            break
        fi

        # Push changes if any (check both dirty working tree AND unpushed commits)
        NEEDS_PUSH=false
        if ! git diff --quiet || ! git diff --cached --quiet; then
            NEEDS_PUSH=true
        elif git rev-parse --verify "@{u}" >/dev/null 2>&1; then
            # Has upstream: check if ahead
            AHEAD=$(git rev-list --count "@{u}..HEAD" 2>/dev/null || echo "0")
            [ "$AHEAD" -gt 0 ] && NEEDS_PUSH=true
        else
            # No upstream: check if there are local commits
            LOCAL_COMMITS=$(git rev-list --count HEAD 2>/dev/null || echo "0")
            [ "$LOCAL_COMMITS" -gt 0 ] && NEEDS_PUSH=true
        fi

        if [ "$NEEDS_PUSH" = true ]; then
            log "Pushing changes..."
            git push origin "$CURRENT_BRANCH" 2>&1 | tee -a "$LOG_FILE" || \
                git push -u origin "$CURRENT_BRANCH" 2>&1 | tee -a "$LOG_FILE"
        else
            log "No changes to push"
        fi

        ITERATION=$((ITERATION + 1))
        log ""
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log "Work iteration $ITERATION complete (ran $CURRENT_MODE)"
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log ""
    done

    # Check if we hit max iterations
    if [ "$ITERATION" -ge "$MAX_ITERATIONS" ]; then
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log "Max iterations reached: $MAX_ITERATIONS"
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    fi

    log ""
    log "Loop finished after $ITERATION iteration(s)"
    log "Full log saved to: $LOG_FILE"

    # Post-mortem hook: runs AFTER log is complete
    log ""
    log "Running post-mortem analysis..."
    POST_MORTEM_ARGS="--agent $AGENT_NAME"
    [ -n "$MODEL_OVERRIDE" ] && POST_MORTEM_ARGS="$POST_MORTEM_ARGS --model $MODEL_OVERRIDE"
    LOOPY_LOG_FILE="$LOG_FILE" ./loop.sh post-mortem 1 $POST_MORTEM_ARGS || log "Post-mortem analysis failed (non-fatal)"
    exit 0
fi

# Standard mode execution loop
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

    # Stop 2b: Empty pending validations (validate mode only)
    if [ "$MODE" = "validate" ]; then
        if ! grep -q -- '- \[ \]' pending-validations.md 2>/dev/null; then
            log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            log "No pending validations in pending-validations.md"
            log "All specs validated!"
            log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            break
        fi
    fi

    # Execute iteration
    log "Starting iteration $((ITERATION + 1))/$MAX_ITERATIONS..."
    log ""

    # Build arguments for post-mortem mode if log override provided
    PROMPT_ARGUMENTS=""
    if [ "$MODE" = "post-mortem" ] && [ -n "$LOG_OVERRIDE" ]; then
        PROMPT_ARGUMENTS="$LOG_OVERRIDE"
    fi
    
    # Run agent (output to both screen and log, capture for checks)
    OUTPUT=$(execute_agent "$PROMPT_FILE" "$MODEL" "$PROMPT_ARGUMENTS" | tee -a "$LOG_FILE") || {
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log "Error: $AGENT_NAME execution failed"
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        exit 1
    }

    # Stop 3: Rate limit detected
    if check_rate_limit "$OUTPUT"; then
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

    # Push changes if any (check both dirty working tree AND unpushed commits)
    NEEDS_PUSH=false
    if ! git diff --quiet || ! git diff --cached --quiet; then
        NEEDS_PUSH=true
    elif git rev-parse --verify "@{u}" >/dev/null 2>&1; then
        # Has upstream: check if ahead
        AHEAD=$(git rev-list --count "@{u}..HEAD" 2>/dev/null || echo "0")
        [ "$AHEAD" -gt 0 ] && NEEDS_PUSH=true
    else
        # No upstream: check if there are local commits
        LOCAL_COMMITS=$(git rev-list --count HEAD 2>/dev/null || echo "0")
        [ "$LOCAL_COMMITS" -gt 0 ] && NEEDS_PUSH=true
    fi

    if [ "$NEEDS_PUSH" = true ]; then
        log "Pushing changes..."
        git push origin "$CURRENT_BRANCH" 2>&1 | tee -a "$LOG_FILE" || \
            git push -u origin "$CURRENT_BRANCH" 2>&1 | tee -a "$LOG_FILE"
    else
        log "No changes to push"
    fi

    ITERATION=$((ITERATION + 1))
    log ""
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "Iteration $ITERATION complete"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log ""
done

# Post-mortem hook: Analyze session for learning (skip for non-productive/interactive modes)
if [[ "$MODE" != "post-mortem" && "$MODE" != "prime" && "$MODE" != "bug" && "$MODE" != "audit" && "$MODE" != "reconcile" ]]; then
    log ""
    log "Loop finished after $ITERATION iteration(s)"
    log "Full log saved to: $LOG_FILE"

    log ""
    log "Running post-mortem analysis..."
    POST_MORTEM_ARGS="--agent $AGENT_NAME"
    [ -n "$MODEL_OVERRIDE" ] && POST_MORTEM_ARGS="$POST_MORTEM_ARGS --model $MODEL_OVERRIDE"
    LOOPY_LOG_FILE="$LOG_FILE" ./loop.sh post-mortem 1 $POST_MORTEM_ARGS || log "Post-mortem analysis failed (non-fatal)"
else
    log ""
    log "Loop finished after $ITERATION iteration(s)"
    log "Full log saved to: $LOG_FILE"
fi

# Loop Orchestrator System

> Simple bash-based orchestrator for iterative AI-driven development with intelligent stop conditions and session logging

## Status: Ready

---

## 1. Overview

### Purpose

Provide a minimal, transparent loop that feeds prompts to Claude Code, manages iteration count, detects completion signals, and logs all output for debugging and analysis.

### Goals

- Ultra-simple implementation (~150 lines bash)
- Support multiple modes (plan, build, reverse)
- Intelligent stop conditions (4 types)
- Session logging (stdout + file simultaneously)
- Cross-platform compatibility (macOS + Linux, bash + zsh)
- Model selection based on mode
- No magic, no abstraction layers

### Non-Goals

- Multi-CLI support (Claude Code only)
- Metadata processing from prompts
- Complex configuration systems
- Real-time progress bars or UI
- Distributed execution or parallelization
- Tool restriction enforcement

---

## 2. Architecture

### Flow

```
User invokes loop.sh
    ↓
Parse arguments (mode, max_iterations)
    ↓
Select model (opus for plan, sonnet otherwise)
    ↓
Setup logging (logs/log-{mode}-{timestamp}.txt)
    ↓
LOOP START
    ↓
Check stop conditions (4 types)
    ↓
    If stop → break and report
    If continue → execute iteration
    ↓
cat prompts/{mode}.md | claude -p --model {model} ...
    ↓ (output to screen + log file)
Detect completion signals in output
    ↓
Git push changes
    ↓
Increment iteration counter
    ↓
LOOP BACK or STOP
    ↓
Report summary
```

### Components

```
loop.sh (main script)
├── Argument parsing
├── Model selection
├── Logging setup
├── Stop conditions (4)
│   ├── Max iterations
│   ├── Empty plan (build mode)
│   ├── Rate limit detection
│   └── Completion signal
├── Claude execution
├── Git push
└── Summary report

prompts/ (external)
├── plan.md
├── build.md
└── reverse.md

logs/ (output)
└── log-{mode}-{timestamp}.txt
```

---

## 3. Implementation Details

### 3.1 Script Structure

**Shebang (portable):**
```bash
#!/usr/bin/env bash
set -euo pipefail
```

**Why `/usr/bin/env bash`:**
- Finds bash in PATH (works on macOS, Linux, *BSD)
- More portable than `/bin/bash` (macOS bash is in different location)

**Why `set -euo pipefail`:**
- `e`: Exit on error
- `u`: Error on undefined variables
- `pipefail`: Detect failures in pipelines

### 3.2 Argument Parsing

```bash
MODE="${1:-build}"        # Default: build
MAX_ITERATIONS="${2:-1}"  # Default: 1 (safe)
PROMPT_FILE="prompts/${MODE}.md"
```

**Defaults:**
- Mode: `build` (most common use case)
- Max iterations: `1` (prevents runaway costs)

**Validation:**
- Prompt file must exist
- Max iterations must be numeric

### 3.3 Model Selection

```bash
case "$MODE" in
    plan)
        MODEL="opus"      # Needs extended_thinking
        ;;
    *)
        MODEL="sonnet"    # Sufficient for build/reverse
        ;;
esac

# Allow override via environment variable
MODEL="${LOOPY_MODEL:-$MODEL}"
```

**Override example:**
```bash
LOOPY_MODEL=haiku ./loop.sh build
```

### 3.4 Logging System

```bash
LOGS_DIR="logs"
mkdir -p "$LOGS_DIR"
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE="$LOGS_DIR/log-${MODE}-${TIMESTAMP}.txt"

log() {
    echo "$@" | tee -a "$LOG_FILE"
}
```

**Features:**
- All output to stdout + log file
- Timestamp in filename (no collisions)
- logs/ directory gitignored (no commit spam)

**Log format:**
```
logs/log-build-2026-01-23-15-30-45.txt
logs/log-plan-2026-01-23-16-20-10.txt
```

### 3.5 Stop Conditions (4 Types)

**Stop 1: Max Iterations**
```bash
if [ "$ITERATION" -ge "$MAX_ITERATIONS" ]; then
    log "Max iterations reached: $MAX_ITERATIONS"
    break
fi
```

**Stop 2: Empty Plan (Build Mode Only)**
```bash
if [ "$MODE" = "build" ]; then
    if ! grep -q '- \[ \]' plan.md 2>/dev/null; then
        log "No pending tasks in plan.md"
        break
    fi
fi
```

**Stop 3: Rate Limit Detection**
```bash
if echo "$OUTPUT" | jq -e 'select(.error.type == "rate_limit_error" or .error.type == "overloaded_error" or (.error.message // "" | test("rate.?limit|quota.*exhausted"; "i")))' >/dev/null 2>&1; then
    log "Rate limit detected"
    break
fi
```

Checks JSON error messages from API to avoid false positives when Claude reads files containing rate limit keywords.

**Stop 4: Completion Signal**
```bash
if echo "$OUTPUT" | grep -q '<promise>COMPLETE</promise>'; then
    log "Agent signaled completion"
    break
fi
```

### 3.6 Claude Execution

```bash
OUTPUT=$(cat "$PROMPT_FILE" | claude -p \
    --model "$MODEL" \
    --dangerously-skip-permissions \
    --output-format=stream-json \
    --verbose 2>&1 | tee -a "$LOG_FILE") || {
    log "Error: Claude execution failed"
    exit 1
}
```

**Flags explained:**
- `-p`: Pipe mode (stdin)
- `--model "$MODEL"`: opus or sonnet
- `--dangerously-skip-permissions`: Auto-approve tools
- `--output-format=stream-json`: Structured output (for logging)
- `--verbose`: Detailed execution info
- `2>&1`: Capture stderr + stdout
- `| tee -a "$LOG_FILE"`: Stdout + file simultaneously

**Capture OUTPUT for stop condition checks**

### 3.7 Git Push

```bash
if git diff --quiet && git diff --cached --quiet; then
    log "No changes to push"
else
    log "Pushing changes..."
    git push origin "$CURRENT_BRANCH" 2>&1 | tee -a "$LOG_FILE" || \
        git push -u origin "$CURRENT_BRANCH" 2>&1 | tee -a "$LOG_FILE"
fi
```

**Features:**
- Check if changes exist first
- Create remote branch if needed (`-u`)
- Log push output (for debugging)
- Non-blocking errors (continues loop)

---

## 4. Usage Examples

### Basic Usage

```bash
# Build mode, 1 iteration (safest)
./loop.sh build

# Plan mode, 5 iterations
./loop.sh plan 5

# Reverse engineering, 10 iterations
./loop.sh reverse 10
```

### With Model Override

```bash
# Use haiku for cheaper build
LOOPY_MODEL=haiku ./loop.sh build 5

# Force opus for complex build task
LOOPY_MODEL=opus ./loop.sh build 1
```

### Typical Workflow

```bash
# 1. Generate plan from specs
./loop.sh plan 5

# 2. Review plan.md
cat plan.md

# 3. Build one task (test)
./loop.sh build 1

# 4. Review, then continue
./loop.sh build 10

# 5. Analyze logs if issues
cat logs/log-build-2026-01-23-15-30-45.txt
```

---

## 5. Cross-Platform Compatibility

### Bash Version Requirements

- **macOS:** bash 3.2+ (default)
- **Linux:** bash 4.x, 5.x
- **zsh:** Compatible (via `/usr/bin/env bash`)

### Compatible Commands Used

All POSIX-compliant:
- ✅ `date +%Y-%m-%d-%H-%M-%S` (GNU + BSD)
- ✅ `mkdir -p` (POSIX)
- ✅ `tee -a` (POSIX)
- ✅ `grep -q`, `grep -qiE` (POSIX)
- ✅ `cat`, `echo` (POSIX)
- ✅ `$(( ))` arithmetic (POSIX)
- ✅ `jq` (JSON parsing, widely available)

### Avoided Problematic Commands

- ❌ `sed -i` (BSD vs GNU incompatibility)
- ❌ `readarray`, `mapfile` (bash 4+ only)
- ❌ Process substitution `<()` (not in sh)
- ❌ Arrays with complex syntax

---

## 6. Error Handling

### Claude Execution Failure

```bash
OUTPUT=$(...) || {
    log "Error: Claude execution failed"
    exit 1
}
```

Stops immediately, logs error, exits with code 1.

### Missing Prompt File

```bash
if [[ ! -f "$PROMPT_FILE" ]]; then
    log "Error: prompts/${MODE}.md not found"
    exit 1
fi
```

Validates before starting loop.

### Git Push Failure

```bash
git push ... || git push -u ...
```

Attempts with and without `-u`, logs both attempts.
Non-fatal (continues loop).

### Rate Limit

```bash
if echo "$OUTPUT" | jq -e 'select(.error.type == "rate_limit_error" or .error.type == "overloaded_error" or (.error.message // "" | test("rate.?limit|quota.*exhausted"; "i")))' >/dev/null 2>&1; then
    log "Rate limit detected"
    break  # Graceful stop
fi
```

Parses JSON error messages from API to detect rate limit errors. Uses jq to avoid false positives when Claude reads files containing rate limit keywords in their content. Stops gracefully (no error exit).

---

## 7. Session Logging

### Log File Structure

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Mode:   build
Model:  sonnet
Branch: main
Prompt: prompts/build.md
Max:    5 iteration(s)
Log:    logs/log-build-2026-01-23-15-30-45.txt
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Starting iteration 1/5...

[Claude output here...]

Pushing changes...
[Git push output...]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Iteration 1 complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Repeat for each iteration...]

Loop finished after 3 iteration(s)
Full log saved to: logs/log-build-2026-01-23-15-30-45.txt
```

### Debugging with Logs

```bash
# Find recent build logs
ls -lt logs/log-build-*.txt | head -5

# Search for errors
grep -i error logs/log-build-2026-01-23-15-30-45.txt

# Check rate limit issues
grep -i "rate\|quota\|limit" logs/*.txt

# Analyze stop conditions
grep "complete\|finished\|reached" logs/*.txt
```

---

## 8. Testing Strategy

### Unit Tests

Test individual functions (if extracted):

```bash
# Test log function
test_log_output() {
    LOG_FILE="/tmp/test.log"
    log "test message"
    grep -q "test message" /tmp/test.log || fail
}

# Test model selection
test_model_selection() {
    MODE="plan"
    # Run model selection logic
    [ "$MODEL" = "opus" ] || fail
}
```

### Integration Tests

Test end-to-end scenarios:

```bash
# Test single iteration
./loop.sh build 1
[ $? -eq 0 ] || fail "Loop failed"

# Test stop on empty plan
echo "# Plan\n\n(no pending tasks)" > plan.md
./loop.sh build 5
# Should stop immediately, not run 5 iterations
```

### Cross-Platform Tests

Run on both macOS and Linux:

```bash
# macOS (bash 3.2)
./loop.sh build 1

# Linux (bash 4.x)
./loop.sh build 1

# zsh compatibility
zsh loop.sh build 1  # Should work via shebang
```

---

## 9. Implementation Guidance

### File Structure

```
loopy/
├── loop.sh               # This system (executable)
├── prompts/
│   ├── plan.md
│   ├── build.md
│   └── reverse.md
├── logs/                 # Gitignored
│   └── log-*.txt
├── specs/
│   └── *.md
├── plan.md               # Mutable
└── .gitignore            # Includes logs/
```

### .gitignore Entry

```
logs/
*.log
```

### Make Executable

```bash
chmod +x loop.sh
```

---

## 10. Edge Cases

### Empty Repository

```bash
# No prompts/ directory
./loop.sh build
# Error: prompts/build.md not found
```

Validated at startup.

### No Git Repository

```bash
git branch --show-current
# fatal: not a git repository
```

Script will fail on `git push`. Requires git repo.

### Concurrent Execution

```bash
# Terminal 1
./loop.sh build 5 &

# Terminal 2
./loop.sh build 5 &
```

**Not recommended:** Git conflicts, race conditions on plan.md.
Use sequentially or on different branches.

### Very Long Iterations

If single iteration runs > 10 minutes:
- Log continues streaming
- No timeout in script
- Claude CLI may have own timeout

---

## 11. Future Enhancements (Out of Scope)

- Progress bars or spinners
- Dry-run mode (preview without execution)
- Parallel mode execution
- Cost tracking (token usage)
- Iteration time tracking
- Automatic branch creation
- Interactive mode (pause between iterations)

---

## 12. Notes

### Why Default to 1 Iteration?

**Safety first:**
- Prevents accidental expensive runs
- Forces intentional scaling (`./loop.sh build 10`)
- User reviews after each task before continuing

### Why Opus for Plan Mode?

Plan generation requires:
- `<extended_thinking>` (strategic analysis)
- Context budget reasoning
- Task grouping decisions

Opus handles this better than Sonnet.

Build mode is straightforward execution → Sonnet sufficient.

### Why Session Logging?

**Common debugging scenarios:**
- "Why did it stop early?" → Check log for stop condition
- "What error occurred?" → Search log for "error"
- "Did it run out of quota?" → Check for rate limit message
- "What did it actually do?" → Review full transcript

Logs are post-mortem analysis tool.

---

**Implementation:** See `loop.sh` in project root

# CLI Agnostic System

> External configuration for multi-agent support, enabling loopy-claude to work with Claude Code, Copilot, and future CLI agents through a unified interface

## Status: Draft

---

## 1. Overview

### Purpose

Decouple loopy-claude from Claude Code dependency by externalizing agent configuration, allowing users to select which CLI agent executes the workflow (Claude Code, Copilot, or future agents) via a simple `--agent` flag and JSON configuration file.

### Goals

- External configuration file (`loopy.config.json`) for agent definitions
- `--agent` flag in `loop.sh` for runtime agent selection
- Model name mapping per agent (e.g., `opus` → `claude-opus-4.5` for Copilot)
- Extensible design (add new agents by editing config, no code changes)
- Default agent configurable (maintains backward compatibility with `claude`)
- Prompts remain unchanged (agent-agnostic, self-contained with explicit paths)

### Non-Goals

- Automatic fallback between agents (user selects consciously)
- Agent capability detection (user knows what each agent supports)
- Parallel execution across multiple agents
- Agent-specific prompt variants (one prompt set for all)
- Runtime agent switching mid-session

---

## 2. Architecture

### Components

```
loopy.config.json (new)
├── default: "claude"
└── agents
    ├── claude
    │   ├── command
    │   ├── promptFlag
    │   ├── modelFlag
    │   ├── models (mapping)
    │   └── extraArgs
    └── copilot
        ├── command
        ├── promptFlag
        ├── modelFlag
        ├── models (mapping)
        └── extraArgs

loop.sh (modified)
├── Argument parsing (+--agent flag)
├── Config loading (read loopy.config.json)
├── Agent resolution (flag > env > config default)
├── Command building (dynamic from config)
└── Execution (agent-agnostic invocation)

export-loopy.sh (modified)
└── Dependency check (verify default agent's CLI)
```

### Flow

```
User: ./loop.sh plan 5 --agent copilot
    ↓
Parse arguments (mode=plan, max=5, agent=copilot)
    ↓
Load loopy.config.json
    ↓
Resolve agent config (agents.copilot)
    ↓
Map model name (opus → claude-opus-4.5)
    ↓
Build command:
  copilot -p --model claude-opus-4.5 --allow-all-tools
    ↓
Execute with prompt piped to stdin
    ↓
(rest of loop.sh unchanged)
```

---

## 3. Implementation Details

### 3.1 Configuration File Structure

**File:** `loopy.config.json` (project root)

```json
{
  "default": "claude",
  "agents": {
    "claude": {
      "command": "claude",
      "promptFlag": "-p",
      "modelFlag": "--model",
      "models": {
        "opus": "opus",
        "sonnet": "sonnet",
        "haiku": "haiku"
      },
      "extraArgs": "--dangerously-skip-permissions --output-format=stream-json --verbose",
      "outputFormat": "stream-json",
      "rateLimitPattern": "rate_limit_error|overloaded_error|quota.*exhausted"
    },
    "copilot": {
      "command": "copilot",
      "promptFlag": "-p",
      "modelFlag": "--model",
      "models": {
        "opus": "claude-opus-4.5",
        "sonnet": "claude-sonnet-4.5",
        "haiku": "claude-haiku-4.5"
      },
      "extraArgs": "--allow-all-tools -s",
      "outputFormat": "text",
      "rateLimitPattern": "rate.?limit|quota|too many requests"
    }
  }
}
```

**Note:** The `-s` (silent) flag for Copilot suppresses stats output, keeping logs cleaner.

**Field definitions:**

| Field | Type | Description |
|-------|------|-------------|
| `default` | string | Agent name to use when `--agent` not specified |
| `agents` | object | Map of agent name → agent configuration |
| `command` | string | CLI executable name |
| `promptFlag` | string | Flag to pass prompt (e.g., `-p`) |
| `modelFlag` | string | Flag to specify model (e.g., `--model`) |
| `models` | object | Map of logical name → agent-specific model name |
| `extraArgs` | string | Additional CLI arguments (permissions, output format) |
| `outputFormat` | string | Output format identifier (`stream-json`, `text`). Used by analyze-session.sh |
| `rateLimitPattern` | string | Regex pattern to detect rate limit errors in output |

### 3.2 Agent Resolution Order

```
1. --agent flag (highest priority)
2. LOOPY_AGENT environment variable
3. loopy.config.json "default" field
4. Hardcoded fallback: "claude" (if no config)
```

### 3.3 Command Building

**Pseudocode:**

```bash
build_agent_command() {
    local agent_name="$1"
    local model_logical="$2"  # opus, sonnet, haiku
    
    # Read from config
    local command=$(jq -r ".agents.${agent_name}.command" loopy.config.json)
    local prompt_flag=$(jq -r ".agents.${agent_name}.promptFlag" loopy.config.json)
    local model_flag=$(jq -r ".agents.${agent_name}.modelFlag" loopy.config.json)
    local model_actual=$(jq -r ".agents.${agent_name}.models.${model_logical}" loopy.config.json)
    local extra_args=$(jq -r ".agents.${agent_name}.extraArgs" loopy.config.json)
    
    # Build command
    echo "${command} ${prompt_flag} ${model_flag} ${model_actual} ${extra_args}"
}
```

**Example outputs:**

```bash
# Claude
build_agent_command "claude" "opus"
# → claude -p --model opus --dangerously-skip-permissions

# Copilot  
build_agent_command "copilot" "opus"
# → copilot -p --model claude-opus-4.5 --allow-all-tools
```

### 3.4 Prompt Delivery

Both agents accept prompts via stdin with `-p` flag:

```bash
# Current (Claude)
cat "$PROMPT_FILE" | claude -p ...

# New (agent-agnostic)
cat "$PROMPT_FILE" | $AGENT_COMMAND
```

**Note:** Copilot's `-p` accepts the prompt as an argument, not stdin. Adjustment needed:

```bash
if [[ "$AGENT_NAME" == "copilot" ]]; then
    # Copilot: prompt as argument
    PROMPT_CONTENT=$(cat "$PROMPT_FILE")
    $COMMAND -p "$PROMPT_CONTENT" $MODEL_FLAG $MODEL $EXTRA_ARGS
else
    # Claude and others: prompt via stdin
    cat "$PROMPT_FILE" | $COMMAND $PROMPT_FLAG $MODEL_FLAG $MODEL $EXTRA_ARGS
fi
```

### 3.5 Output and Logging

**Current:** `--output-format=stream-json` (Claude-specific)

**New approach:**
- Add optional `outputFormat` field to agent config
- If not specified, omit the flag (agent uses default)
- Logging via `tee` works regardless (captures all stdout)

```json
{
  "claude": {
    "extraArgs": "--dangerously-skip-permissions --output-format=stream-json --verbose"
  },
  "copilot": {
    "extraArgs": "--allow-all-tools"
  }
}
```

### 3.6 Rate Limit Detection

**Current:** Parses Claude JSON error format

**New approach:** Agent-specific rate limit patterns in config

```json
{
  "claude": {
    "rateLimitPattern": "rate_limit_error|overloaded_error|quota.*exhausted"
  },
  "copilot": {
    "rateLimitPattern": "rate.?limit|quota|too many requests"
  }
}
```

**Detection logic:**

```bash
RATE_LIMIT_PATTERN=$(jq -r ".agents.${AGENT_NAME}.rateLimitPattern // 'rate.?limit'" loopy.config.json)

if echo "$OUTPUT" | grep -qiE "$RATE_LIMIT_PATTERN"; then
    log "Rate limit detected"
    break
fi
```

### 3.7 Session Analysis (analyze-session.sh)

**Current:** Parses Claude-specific JSON format (`"type":"result"`, `modelUsage`, `costUSD`)

**Problem:** Copilot does not produce this JSON format. Logs will only contain text output.

**New approach:** Graceful degradation based on `outputFormat` field

```bash
# Detect agent from log header (new field added by loop.sh)
AGENT=$(grep "^Agent:" "$TARGET" | head -1 | awk '{print $2}' || echo "unknown")

# Load output format from config
OUTPUT_FORMAT=$(jq -r ".agents.${AGENT}.outputFormat // 'text'" loopy.config.json 2>/dev/null || echo "text")

if [[ "$OUTPUT_FORMAT" == "stream-json" ]]; then
    # Full JSON parsing (Claude)
    RESULT_JSON=$(grep '"type":"result"' "$TARGET" | tail -1)
    # ... existing cost/token parsing
else
    # Text-only analysis (Copilot, others)
    echo "  Cost Analysis: Not available (agent: $AGENT)"
    echo "  Token Usage:   Not available (no JSON output)"
fi
```

**What works for all agents:**
- Iterations started/completed (from text markers)
- Stop condition detection (from text patterns)
- Duration (from timestamps)
- Mode, Model, Branch (from log header)

**What requires stream-json (Claude only):**
- Cost breakdown (`total_cost_usd`)
- Token usage (`modelUsage`, `input_tokens`, `output_tokens`)
- Cache efficiency (`cache_read_input_tokens`)
- Error details (`is_error`, `subtype`)

**Log header update (loop.sh):**

```bash
log "Agent:  $AGENT_NAME"  # NEW: Add agent to header
```

This allows analyze-session.sh to determine which parsing strategy to use.

---

## 4. API / Interface

### Command-Line Interface

```bash
# Syntax
./loop.sh [mode] [max_iterations] [--model MODEL] [--agent AGENT]

# Examples
./loop.sh plan 5                      # Uses default agent (claude)
./loop.sh plan 5 --agent copilot      # Uses Copilot
./loop.sh build 10 --agent claude     # Explicit Claude
./loop.sh build --agent copilot --model sonnet  # Copilot with Sonnet
```

### Environment Variable

```bash
# Set default agent via environment
export LOOPY_AGENT=copilot
./loop.sh plan 5                      # Uses copilot

# Flag overrides environment
LOOPY_AGENT=copilot ./loop.sh plan 5 --agent claude  # Uses claude
```

### Configuration File

Location: `loopy.config.json` in project root

Created by:
- `export-loopy.sh` (generated with defaults)
- Manual creation
- Future: `./loop.sh init`

---

## 5. Testing Strategy

### Manual Testing

**Test 1: Default agent (no flag)**
```bash
./loop.sh build 1
# Expected: Uses claude (default)
# Verify: Log shows "Agent: claude"
```

**Test 2: Explicit agent flag**
```bash
./loop.sh build 1 --agent copilot
# Expected: Uses copilot
# Verify: Log shows "Agent: copilot"
```

**Test 3: Environment variable**
```bash
LOOPY_AGENT=copilot ./loop.sh build 1
# Expected: Uses copilot
# Verify: Log shows "Agent: copilot"
```

**Test 4: Flag overrides environment**
```bash
LOOPY_AGENT=copilot ./loop.sh build 1 --agent claude
# Expected: Uses claude (flag wins)
```

**Test 5: Model mapping**
```bash
./loop.sh plan 5 --agent copilot
# Expected: Model resolves to claude-opus-4.5 (not "opus")
# Verify: Command includes "--model claude-opus-4.5"
```

**Test 6: Missing config graceful fallback**
```bash
mv loopy.config.json loopy.config.json.bak
./loop.sh build 1
# Expected: Falls back to hardcoded claude defaults
# Verify: Warning shown, execution continues
```

**Test 7: Unknown agent error**
```bash
./loop.sh build 1 --agent unknown
# Expected: Error message, exit 1
# Verify: "Unknown agent: unknown"
```

---

## 6. Acceptance Criteria

- [ ] `loopy.config.json` defines agent configurations (command, flags, models, extraArgs, outputFormat, rateLimitPattern)
- [ ] `--agent` flag selects which agent to use
- [ ] Default agent is `claude` (backward compatible)
- [ ] Model names mapped per agent (opus → claude-opus-4.5 for copilot)
- [ ] Prompts work unchanged with both agents
- [ ] Logging captures output from any agent
- [ ] Rate limit detection works per agent pattern
- [ ] Missing config falls back to hardcoded claude defaults
- [ ] Unknown agent produces clear error message
- [ ] `export-loopy.sh` generates default `loopy.config.json`
- [ ] `export-loopy.sh` verifies default agent's CLI is installed
- [ ] `export-loopy.sh` PRESET_FULL includes `loopy.config.json`
- [ ] `export-loopy.sh` README-LOOPY.md template updated for multi-agent
- [ ] Banner shows current agent name
- [ ] Environment variable `LOOPY_AGENT` works as fallback
- [ ] `analyze-session.sh` reads Agent from log header
- [ ] `analyze-session.sh` gracefully degrades when JSON output unavailable
- [ ] `analyze-session.sh` shows basic metrics (iterations, stop condition) for all agents
- [ ] `README.md` updated to document multi-agent support
- [ ] `README.md` Configuration section includes `loopy.config.json`
- [ ] `README.md` FAQ updated (no longer "Claude Code only")
- [ ] `README.md` includes `--agent` flag in usage examples

---

## 7. Implementation Guidance

### Impact Analysis

**Change Type:** Enhancement (extends existing system)

**Files affected:**

| File | Change |
|------|--------|
| `loop.sh` | Add `--agent` parsing, config loading, dynamic command building, add Agent to banner |
| `loopy.config.json` | **New file** - agent configurations |
| `analyze-session.sh` | Graceful degradation for non-JSON output formats, read Agent from log header |
| `export-loopy.sh` | Generate config, verify default agent CLI, update README-LOOPY.md template, add loopy.config.json to PRESET_FULL |
| `README.md` | Update "Claude Code only" references, add `--agent` flag docs, add `loopy.config.json` to Configuration section, update FAQ, add multi-agent examples |
| `specs/loop-orchestrator-system.md` | Update Non-Goals → Goals |

**Search commands:**
```bash
grep -n "claude -p" loop.sh                    # Direct claude invocations
grep -n "command -v claude" *.sh               # Dependency checks
grep -n "MODEL=" loop.sh                       # Model selection logic
grep -n "stream-json\|output-format" *.sh      # Output format references
grep -n '"type":"result"' analyze-session.sh   # JSON parsing
grep -n "PRESET_FULL" export-loopy.sh          # Preset file list
grep -n "README-LOOPY" export-loopy.sh         # Generated readme
grep -n "Claude Code only\|single.*CLI" README.md  # Multi-CLI references in docs
grep -n "LOOPY_MODEL" README.md                # Environment variable docs
```

### Implementation Hints

**loop.sh changes:**

1. Add argument parsing for `--agent`:
```bash
while [[ $# -gt 0 ]]; do
    case "$1" in
        --agent)
            AGENT_OVERRIDE="$2"
            shift 2
            ;;
        # ... existing cases
    esac
done
```

2. Add config loading function:
```bash
load_agent_config() {
    local agent="$1"
    if [[ -f "loopy.config.json" ]]; then
        # Read config with jq
    else
        # Hardcoded fallback for claude
    fi
}
```

3. Update banner to show agent:
```bash
log "Agent:  $AGENT_NAME"
```

4. Replace hardcoded claude invocation with dynamic command

**analyze-session.sh changes:**

1. Extract Agent from log header:
```bash
AGENT=$(grep "^Agent:" "$TARGET" | head -1 | awk '{print $2}' || echo "claude")
```

2. Conditional JSON parsing:
```bash
OUTPUT_FORMAT=$(jq -r ".agents.${AGENT}.outputFormat // 'text'" loopy.config.json 2>/dev/null || echo "stream-json")

if [[ "$OUTPUT_FORMAT" == "stream-json" ]]; then
    # Existing JSON parsing code
else
    echo "  Cost/Token analysis not available for agent: $AGENT"
fi
```

**export-loopy.sh changes:**

1. Add loopy.config.json to PRESET_FULL:
```bash
PRESET_FULL=(
    "loop.sh"
    "analyze-session.sh"
    "export-loopy.sh"
    "loopy.config.json"  # NEW
    ".claude/"
    ".gitignore"
)
```

2. Update dependency check:
```bash
# Read default agent from config
DEFAULT_AGENT=$(jq -r '.default // "claude"' loopy.config.json 2>/dev/null || echo "claude")
AGENT_COMMAND=$(jq -r ".agents.${DEFAULT_AGENT}.command // \"claude\"" loopy.config.json 2>/dev/null || echo "claude")

if ! command -v "$AGENT_COMMAND" &>/dev/null; then
    echo "⚠ WARNING: Default agent CLI not found: $AGENT_COMMAND"
    # Warning only, don't block export
fi
```

3. Update README-LOOPY.md template to mention multi-agent:
```markdown
## Prerequisites

- Default agent CLI installed (check with `claude --version` or `copilot --version`)
- Configuration: `loopy.config.json` (generated automatically)

## Using Different Agents

\`\`\`bash
./loop.sh plan 5                      # Uses default agent (claude)
./loop.sh plan 5 --agent copilot      # Uses Copilot
\`\`\`
```

**loopy.config.json:**
- Generate during `export-loopy.sh` with full default structure
- Include in PRESET_FULL array

**README.md changes:**

1. Update line 9: "feeds prompts to Claude Code" → "feeds prompts to AI agents (Claude Code, Copilot, etc.)"

2. Update line 100 (Model selection): Add note about `--agent` flag

3. Update Configuration section (lines 305-319):
```markdown
### Configuration

#### Agent Configuration

Agents are configured in `loopy.config.json`:

\`\`\`json
{
  "default": "claude",
  "agents": {
    "claude": { ... },
    "copilot": { ... }
  }
}
\`\`\`

#### Environment Variables

\`\`\`bash
# Override agent
LOOPY_AGENT=copilot ./loop.sh build 10

# Override model  
LOOPY_MODEL=haiku ./loop.sh build 10
\`\`\`
```

4. Update Philosophy section (lines 428-430):
   - Remove "Claude Code only" 
   - Change to "Default to Claude Code, extensible to other agents"

5. Update FAQ (lines 479-480):
```markdown
**Q: Can I use other AI agents besides Claude Code?**
A: Yes. Use `--agent copilot` flag or set `LOOPY_AGENT=copilot`. 
Configure agents in `loopy.config.json`. Default is Claude Code for backward compatibility.
```

6. Add new example in Usage Examples section:
```markdown
### Example 4: Using Different Agents

\`\`\`bash
# Use Claude Code (default)
./loop.sh plan 5

# Use Copilot
./loop.sh plan 5 --agent copilot

# Use Copilot with GPT-5 for contrast review
./loop.sh plan 5 --agent copilot --model gpt-5
\`\`\`
```

7. Update File Structure to include loopy.config.json:
```markdown
├── loopy.config.json        # Agent configurations (optional)
```

### Verification Strategy

```bash
# Verify config created
test -f loopy.config.json && echo "✓ Config exists"

# Verify claude still works (backward compat)
./loop.sh build 1 2>&1 | grep -q "Agent: claude" && echo "✓ Default works"

# Verify copilot works
./loop.sh build 1 --agent copilot 2>&1 | grep -q "Agent: copilot" && echo "✓ Copilot works"

# Verify model mapping
./loop.sh plan 1 --agent copilot 2>&1 | grep -q "claude-opus-4.5" && echo "✓ Model mapped"

# Verify analyze-session graceful degradation
./loop.sh build 1 --agent copilot
./analyze-session.sh  # Should show "Cost analysis not available" without error

# Verify export includes config
./export-loopy.sh full --dry-run 2>&1 | grep -q "loopy.config.json" && echo "✓ Config in export"

# Verify README.md updates
grep -q "loopy.config.json" README.md && echo "✓ README mentions config"
grep -q "\-\-agent" README.md && echo "✓ README documents --agent flag"
! grep -q "Claude Code only" README.md && echo "✓ README updated (no 'Claude Code only')"
```

---

## 8. Migration Notes

### For Existing Users

**No action required** - default behavior unchanged:
- `./loop.sh plan 5` continues to use Claude Code
- Config file optional (falls back to hardcoded defaults)

### For New Features

To use Copilot:
1. Ensure `copilot` CLI installed
2. Create or verify `loopy.config.json` exists
3. Run with `--agent copilot`

---

## 9. Notes

### Design Decisions

**Why external config instead of hardcoded?**
- Extensibility: Add new agents without code changes
- Transparency: Users see exactly how each agent is invoked
- Customization: Users can adjust extraArgs per project

**Why no automatic fallback?**
- Predictability: User knows exactly which agent runs
- Cost awareness: Different agents have different pricing
- Debugging: Clear which agent produced output

**Why keep prompts unchanged?**
- Prompts already use explicit paths (`.claude/agents/spec-checker.md`)
- Both agents understand the same instructions with Claude models
- Maintenance: One prompt set, not N variants

### Trade-offs Accepted

**Limitation:** Copilot lacks Task tool (subagents)
- **Impact:** Validate mode runs sequentially instead of parallel
- **Mitigation:** Functional but slower; documented behavior

**Limitation:** No capability detection
- **Impact:** User must know agent limitations
- **Mitigation:** Document in README-LOOPY.md

### Future Enhancements (Out of Scope)

- Agent capability matrix in config
- Cost tracking per agent
- Performance comparison reports
- GUI for agent selection
- `./loop.sh agents list` command

---

**Version:** 1.0
**Last Updated:** 2026-01-26


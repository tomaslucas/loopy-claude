# Copilot Hooks System

> Adapter system enabling GitHub Copilot to reuse existing Claude Code security hooks without code duplication

## Status: Draft

---

## 1. Overview

### Purpose

Enable GitHub Copilot CLI to use the same security validation and telemetry scripts (`hooks/core/`) that Claude Code uses, via an adapter that translates between Copilot's JSON format and Claude's expected format.

### Goals

- Reuse existing `hooks/core/pre-tool-use.sh` for security validation in Copilot
- Reuse existing `hooks/core/log-event.sh` for telemetry in Copilot
- Single universal adapter (`copilot-adapter.sh`) for all hook types
- Zero modifications to existing Claude Code hooks or configuration
- Export support via `export-loopy.sh` for new projects

### Non-Goals

- Implementing Copilot-exclusive hooks (`sessionStart`, `sessionEnd`, `userPromptSubmitted`, `errorOccurred`)
- Modifying `.claude/settings.json` or `hooks/core/*.sh`
- Creating separate adapters per hook type
- Supporting bidirectional sync (Copilot format is input-only)

---

## 2. Architecture

### Data Flow

```
Copilot CLI
    │
    │ (JSON: camelCase, toolArgs=string)
    ▼
.github/hooks/hooks.json
    │
    │ routes to
    ▼
hooks/adapters/copilot-adapter.sh preToolUse
    │
    │ [TRANSLATE: Copilot → Claude]
    │   - toolName → tool_name
    │   - toolArgs (string) → tool_input (object)
    ▼
hooks/core/pre-tool-use.sh
    │
    │ (exit 0 = allow, exit 2 = block + stderr)
    ▼
copilot-adapter.sh
    │
    │ [TRANSLATE: Claude → Copilot]
    │   - exit 2 + stderr → JSON {"permissionDecision":"deny",...}
    │   - Always exit 0 (Copilot requirement)
    ▼
Copilot CLI receives JSON response


Claude Code (unchanged)
    │
    │ (JSON: snake_case, tool_input=object)
    ▼
.claude/settings.json → hooks/core/pre-tool-use.sh
    │
    │ (exit code directly)
    ▼
Claude Code receives exit code
```

### Components

| Component | Change | Purpose |
|-----------|--------|---------|
| `.github/hooks/hooks.json` | **New** | Copilot hooks configuration |
| `hooks/adapters/copilot-adapter.sh` | **New** | Universal format translator |
| `tests/e2e/copilot-hooks-verify.sh` | **New** | VDD verification script |
| `export-loopy.sh` | **Modify** | Generate `.github/hooks/hooks.json` |
| `hooks/core/pre-tool-use.sh` | Unchanged | Existing security validation |
| `hooks/core/log-event.sh` | Unchanged | Existing telemetry |
| `.claude/settings.json` | Unchanged | Existing Claude configuration |

### Dependencies

| Component | Purpose | Location |
|-----------|---------|----------|
| hooks/core/pre-tool-use.sh | Security validation logic | hooks/core/ |
| hooks/core/log-event.sh | Telemetry emitter | hooks/core/ |
| jq | JSON parsing (with fallback) | System |

---

## 3. Implementation Details

### 3.1 Format Differences

#### Input JSON - preToolUse

**Claude Code:**
```json
{
  "tool_name": "bash",
  "tool_input": {
    "command": "rm -rf /important",
    "path": "/some/file"
  }
}
```

**Copilot:**
```json
{
  "timestamp": 1704614600000,
  "cwd": "/path/to/project",
  "toolName": "bash",
  "toolArgs": "{\"command\":\"rm -rf /important\"}"
}
```

**Key differences:**
1. `tool_name` (snake_case) → `toolName` (camelCase)
2. `tool_input` (object) → `toolArgs` (JSON string requiring double parse)
3. Copilot adds: `timestamp`, `cwd`

#### Output JSON - preToolUse

**Claude Code:**
- Exit code `0` = allow
- Exit code `2` + stderr message = block

**Copilot:**
- Always exit code `0`
- JSON stdout to block:
```json
{
  "permissionDecision": "deny",
  "permissionDecisionReason": "Error message"
}
```

#### Input JSON - postToolUse

**Copilot:**
```json
{
  "timestamp": 1704614700000,
  "cwd": "/path/to/project",
  "toolName": "bash",
  "toolArgs": "{\"command\":\"npm test\"}",
  "toolResult": {
    "resultType": "success",
    "textResultForLlm": "All tests passed"
  }
}
```

### 3.2 Adapter Structure

**File:** `hooks/adapters/copilot-adapter.sh`

```bash
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
    
    # Call core script, capture exit code safely
    set +e
    local error_msg=$(echo "$claude_input" | "$CORE_DIR/pre-tool-use.sh" 2>&1)
    local exit_code=$?
    set -e
    
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
```

### 3.3 Copilot Configuration

**File:** `.github/hooks/hooks.json`

```json
{
  "version": 1,
  "hooks": {
    "preToolUse": [
      {
        "type": "command",
        "bash": "./hooks/adapters/copilot-adapter.sh preToolUse",
        "cwd": ".",
        "timeoutSec": 30
      }
    ],
    "postToolUse": [
      {
        "type": "command",
        "bash": "./hooks/adapters/copilot-adapter.sh postToolUse",
        "cwd": ".",
        "timeoutSec": 10
      }
    ]
  }
}
```

### 3.4 Export Integration

**Modification to `export-loopy.sh`:**

Add to `generate_templates()` function:

```bash
# Create .github/hooks/hooks.json for Copilot
if [[ "$DRY_RUN" == true ]]; then
    echo "[DRY RUN] Would create .github/hooks/hooks.json"
else
    mkdir -p "$dest/.github/hooks"
    cat > "$dest/.github/hooks/hooks.json" <<'EOF'
{
  "version": 1,
  "hooks": {
    "preToolUse": [
      {
        "type": "command",
        "bash": "./hooks/adapters/copilot-adapter.sh preToolUse",
        "cwd": ".",
        "timeoutSec": 30
      }
    ],
    "postToolUse": [
      {
        "type": "command",
        "bash": "./hooks/adapters/copilot-adapter.sh postToolUse",
        "cwd": ".",
        "timeoutSec": 10
      }
    ]
  }
}
EOF
    echo "✓ Created .github/hooks/hooks.json"
fi
```

---

## 4. API / Interface

### Adapter CLI

```bash
# Syntax
./hooks/adapters/copilot-adapter.sh <hook_type>

# Hook types
preToolUse   - Security validation before tool execution
postToolUse  - Telemetry logging after tool execution

# Input: JSON via stdin (Copilot format)
# Output: JSON via stdout (for preToolUse deny only)
# Exit: Always 0 (Copilot requirement)
```

### Files Created

| Path | Purpose |
|------|---------|
| `.github/hooks/hooks.json` | Copilot hooks configuration |
| `hooks/adapters/copilot-adapter.sh` | Universal adapter script |
| `tests/e2e/copilot-hooks-verify.sh` | VDD verification script |

### Files Modified

| Path | Change |
|------|--------|
| `export-loopy.sh` | Add `.github/hooks/hooks.json` generation |
| `specs/README.md` | Add entry to Active Specs |

---

## 5. Testing Strategy

### VDD Verification Script

**File:** `tests/e2e/copilot-hooks-verify.sh`

Tests to include:
1. **Dangerous command blocked** - `rm -rf` returns deny JSON
2. **Safe command allowed** - Normal command returns no output
3. **Force push blocked** - `git push --force` returns deny
4. **Env file blocked** - `.env` access returns deny
5. **postToolUse logging** - Writes to `logs/session-events.jsonl`
6. **Invalid hook type** - Returns error message

### Manual Verification

```bash
# Test preToolUse - dangerous command
echo '{"toolName":"bash","toolArgs":"{\"command\":\"rm -rf /\"}"}' | \
  ./hooks/adapters/copilot-adapter.sh preToolUse
# Expected: {"permissionDecision":"deny","permissionDecisionReason":"BLOCKED: ..."}

# Test preToolUse - safe command
echo '{"toolName":"bash","toolArgs":"{\"command\":\"ls -la\"}"}' | \
  ./hooks/adapters/copilot-adapter.sh preToolUse
# Expected: (no output, exit 0)

# Test postToolUse - verify logging
echo '{"timestamp":1704614700000,"cwd":"/tmp","toolName":"bash","toolArgs":"{}","toolResult":{"resultType":"success"}}' | \
  ./hooks/adapters/copilot-adapter.sh postToolUse
tail -1 logs/session-events.jsonl | jq .
# Expected: JSON with "agent": "copilot"
```

---

## 6. Acceptance Criteria

- [ ] `.github/hooks/hooks.json` exists with preToolUse and postToolUse configuration
- [ ] `hooks/adapters/copilot-adapter.sh` exists and is executable
- [ ] Adapter correctly translates Copilot format to Claude format
- [ ] Adapter correctly translates Claude exit codes to Copilot JSON
- [ ] `rm -rf` command is blocked with deny JSON response
- [ ] `git push --force` is blocked with deny JSON response
- [ ] `.env` file access is blocked with deny JSON response
- [ ] Safe commands are allowed (no output, exit 0)
- [ ] postToolUse writes to `logs/session-events.jsonl` with agent="copilot"
- [ ] Invalid hook type shows usage error
- [ ] `tests/e2e/copilot-hooks-verify.sh` exists and all tests pass
- [ ] `export-loopy.sh` generates `.github/hooks/hooks.json` in destination
- [ ] Existing `hooks/core/pre-tool-use.sh` unchanged
- [ ] Existing `.claude/settings.json` unchanged

---

## 7. Implementation Guidance

> Context for plan generator to create specific, verifiable tasks

### Impact Analysis

**Change Type:** [x] New Feature

**Affected Areas:**

Files to create:
- `.github/hooks/hooks.json` - Copilot configuration
- `hooks/adapters/copilot-adapter.sh` - Universal adapter
- `tests/e2e/copilot-hooks-verify.sh` - VDD verification

Files to modify:
- `export-loopy.sh` (~20 lines: add hooks.json generation to generate_templates)
- `specs/README.md` (add to Active Specs table)

Files NOT to modify:
- `hooks/core/pre-tool-use.sh` - Existing logic unchanged
- `hooks/core/log-event.sh` - Existing logic unchanged
- `.claude/settings.json` - Claude configuration unchanged

### Implementation Hints

**Phase 1: Create adapter (isolated)**
- Create `hooks/adapters/copilot-adapter.sh`
- Test manually with echo | adapter
- Verify translation works correctly

**Phase 2: Create Copilot config**
- Create `.github/hooks/` directory
- Create `hooks.json` with correct paths

**Phase 3: Create VDD test**
- Create `tests/e2e/copilot-hooks-verify.sh`
- Must FAIL initially (before adapter exists)
- Test all security patterns

**Phase 4: Update export**
- Modify `export-loopy.sh` generate_templates()
- Add hooks.json generation

**Critical implementation notes:**
- Use `set +e` before capturing exit code, `set -e` after
- Adapter must ALWAYS return exit 0 to Copilot
- `toolArgs` requires double JSON parsing (it's a string)
- Use `|| true` in tests to prevent early exit

### Verification Strategy

```bash
# Phase 1: Adapter exists and is executable
[ -x hooks/adapters/copilot-adapter.sh ] && echo "✅ Adapter executable"

# Phase 2: Copilot config exists
[ -f .github/hooks/hooks.json ] && echo "✅ hooks.json exists"
jq . .github/hooks/hooks.json && echo "✅ Valid JSON"

# Phase 3: VDD test passes
./tests/e2e/copilot-hooks-verify.sh && echo "✅ All tests pass"

# Phase 4: Export generates hooks.json
./export-loopy.sh full --dry-run 2>&1 | grep -q "hooks.json" && echo "✅ Export includes hooks.json"
```

---

## 8. Selected Implementation Strategy

> Strategy investigation performed during design/planning phase

**Investigation date:** 2026-01-30

### Pattern Analysis
- Similar pattern found in: `hooks/core/pre-tool-use.sh` (exit code semantics)
- Project convention: Bash scripts, optional jq dependency with fallback
- Existing adapter directory: `hooks/adapters/` (empty, has .gitkeep)

### Approaches Considered

**Approach A: Universal Adapter (Selected)**
- Single `copilot-adapter.sh` receiving hook type as parameter
- Pros: One file, easy maintenance, extensible
- Cons: Slightly more complex routing logic
- Complexity: Low

**Approach B: Separate Adapter Per Hook**
- `copilot-pre-tool-use.sh`, `copilot-post-tool-use.sh`
- Pros: Simpler individual files
- Cons: Code duplication, more files to maintain
- Complexity: Low but redundant

**Approach C: Shared Library + Thin Wrappers**
- Common functions in `copilot-common.sh`, thin wrappers per hook
- Pros: DRY principle
- Cons: Over-engineered for 2 hooks
- Complexity: Medium

### Decision

**Selected:** Approach A (Universal Adapter)

**Justification:** 
- Only 2 hooks to implement (preToolUse, postToolUse)
- Single file is easier to understand and maintain
- Case/switch routing is simple and readable
- Extensible if more hooks needed in future

**Accepted trade-offs:** 
- Single file slightly larger than multiple minimal files
- Must parse hook type argument (trivial overhead)

---

## 9. Notes

### Copilot Hook Limitations vs Claude

| Feature | Claude Code | Copilot |
|---------|-------------|---------|
| `matcher` (filter by tool) | ✅ | ❌ |
| `permissions.deny` declarative | ✅ | ❌ |
| `$CLAUDE_PROJECT_DIR` variable | ✅ | ❌ |
| Session hooks | ❌ | ✅ |
| `timestamp`, `cwd` in all events | ❌ | ✅ |

### Future Extensibility

To add `sessionStart` hook in future:

1. Add to `.github/hooks/hooks.json`:
```json
"sessionStart": [{
  "type": "command",
  "bash": "./hooks/adapters/copilot-adapter.sh sessionStart"
}]
```

2. Add handler in `copilot-adapter.sh`:
```bash
handle_session_start() {
    local source=$(echo "$INPUT" | jq -r '.source')
    # Custom logic here
}

case "$HOOK_TYPE" in
    # ... existing ...
    sessionStart) handle_session_start ;;
esac
```

### jq Dependency

The adapter uses `jq` for JSON parsing. If `jq` is not available:
- preToolUse will fail to translate correctly
- Consider adding fallback grep-based parsing if needed

Current `pre-tool-use.sh` already has jq fallback, so this is consistent with project patterns.

---

**Related specs:**
- `compound-architecture-system.md` — Defines hooks architecture
- `cli-agnostic-system.md` — Multi-agent support via loopy.config.json

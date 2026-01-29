# Compound Architecture System

> Architectural evolution enabling compound learning through optimized context, verification-driven development, structured telemetry, and focused post-mortems

## Status: Ready

---

## 1. Overview

### Purpose

Evolve loopy-claude from linear task execution to compound engineering: each unit of work makes subsequent work easier through accumulated knowledge in the PIN, deterministic verification, and operational learning.

### Goals

- **Optimize Context**: Reduce context window saturation via spec archiving and decision summaries in PIN
- **Robustness (VDD)**: Ensure infrastructure code works in reality via mandatory E2E verification scripts
- **Structured Telemetry**: Enable empirical analysis of agent behavior via JSON event logging
- **Operational Learning**: Focus post-mortem on process improvement, not product documentation
- **Multi-Agent Parity**: Support Claude Code and Copilot with unified telemetry despite output format differences
- **Git Workflow Robustness**: Handle repos without remotes gracefully (Issue #13 Bug #2)

### Non-Goals

- Changing the core plan→build→validate loop (preserved)
- Adding ML/embeddings (keep it simple: bash + files)
- Breaking backward compatibility with existing specs
- Automated spec migration (human moves archived specs back manually)

---

## 2. Architecture

### Knowledge Flow (New)

```
                    ┌─────────────────────────────────────┐
                    │         PRODUCT KNOWLEDGE           │
                    │  (What was built + key decisions)   │
                    └─────────────────────────────────────┘
                                     ▲
                                     │
    Spec ──► Build ──► Validate ──► PIN (specs/README.md)
                           │              │
                           │         Archived Knowledge
                           │         + Key Decisions
                           ▼              │
                    specs/archive/   ◄────┘
                    (frozen files)

                    ┌─────────────────────────────────────┐
                    │         PROCESS KNOWLEDGE           │
                    │    (How to operate efficiently)     │
                    └─────────────────────────────────────┘
                                     ▲
                                     │
    Logs ──► Post-Mortem ──► lessons-learned.md
     │              │
     │         Operational Patterns Only:
     │         - Failed commands
     │         - Syntax errors
     │         - Tool misuse
     ▼
logs/session-events.jsonl
(structured telemetry)
```

### Directory Structure (New)

```
loopy-claude/
├── specs/
│   ├── README.md              # PIN: Active + Archived Knowledge sections
│   ├── archive/               # NEW: Frozen specs (validated)
│   └── *.md                   # Active specs only
├── tests/
│   ├── unit/                  # NEW: Pure logic tests
│   └── e2e/                   # NEW: VDD infrastructure scripts
├── hooks/
│   ├── core/                  # NEW: Agent-agnostic scripts
│   │   └── log-event.sh       # JSON telemetry emitter
│   └── adapters/              # NEW: Agent-specific wrappers
│       ├── claude/
│       └── copilot/
├── logs/
│   ├── log-*.txt              # Existing text logs (unchanged)
│   └── session-events.jsonl   # NEW: Structured telemetry
├── .claude/commands/          # Prompts (modified)
└── loop.sh                    # Orchestrator (modified)

REMOVE:
├── prompts/                   # Symlinks no longer needed
```

### Components

| Component | Change | Purpose |
|-----------|--------|---------|
| `specs/README.md` | **Restructure** | Decision Map with Active/Archived sections |
| `specs/archive/` | **New** | Cold storage for validated specs |
| `.claude/commands/plan.md` | **Modify** | VDD rules + ignore archive |
| `.claude/commands/validate.md` | **Modify** | Archive lifecycle on PASS |
| `.claude/commands/post-mortem.md` | **Modify** | Operational focus only |
| `hooks/core/log-event.sh` | **New** | JSON telemetry emitter |
| `loop.sh` | **Modify** | Telemetry hooks + conditional push |
| `loopy.config.json` | **Modify** | Hooks configuration per agent |
| `tests/unit/` | **New** | Convention for unit tests |
| `tests/e2e/` | **New** | VDD verification scripts |
| `prompts/` | **Delete** | Remove obsolete symlinks |

### Dependencies

| Component | Purpose | Location |
|-----------|---------|----------|
| specs/README.md | Current PIN structure | Project root |
| loop.sh | Orchestrator with git push logic | Project root |
| loopy.config.json | Agent configuration | Project root |
| .claude/commands/*.md | Mode prompts | .claude/commands/ |
| lessons-learned.md | Post-mortem output | Project root |

---

## 3. Implementation Details

### 3.1 PIN Structure (specs/README.md)

New template structure:

```markdown
# Loopy-Claude Specifications

## How to Use

1. **AI agents:** Study `specs/README.md` before any spec work
2. **Search here** to find relevant existing specs by keyword
3. **When creating new spec:** Add entry to Active Specs
4. **Plan mode:** Reads Active Specs only, trusts Archived summaries

---

## Active Specs

| Spec | Purpose |
|------|---------|
| [feature-a-system.md](feature-a-system.md) | Brief description |

---

## Archived Knowledge

Validated and frozen specs. **Do NOT read these files** — use the decision summary below.

| Feature | Decision/Trade-off | Archived |
|---------|-------------------|----------|
| Auth System | JWT Stateless for horizontal scaling | [specs/archive/auth-system.md](archive/auth-system.md) |
| Loop Orchestrator | Bash simplicity over Python flexibility | [specs/archive/loop-orchestrator-system.md](archive/loop-orchestrator-system.md) |

**To evolve an archived spec:** Move it back to `specs/` and update this table.

---

## Key Design Decisions (Quick Reference)
<!-- Preserved from current README -->
```

### 3.2 VDD (Verification Driven Development) Rules

New instructions for `plan.md`:

```markdown
### VDD: Verification Driven Development

**Trigger:** Any task involving infrastructure, CLI tools, containers, databases, or system operations.

**Mandatory First Task:**
When generating tasks for such specs, the FIRST task MUST be:

- [ ] Create E2E verification script (file: `tests/e2e/{feature}-verify.sh`)
      Done when: Script exists and FAILS until feature is properly implemented
      Verify: bash tests/e2e/{feature}-verify.sh returns non-zero
      (cite: specs/{feature}-system.md)

**Rationale:** The verification script becomes a contract. Code is not complete until the script passes.

**Examples of VDD scripts:**
- Docker: Script that starts container, runs health check, stops container
- CLI: Script that runs commands and validates output patterns
- Database: Script that connects, runs migrations, queries data
```

### 3.3 Archive Lifecycle in validate.md

New instructions for `validate.md` on PASS:

```markdown
### On Validation PASS (Archival Process)

After confirming spec is fully implemented:

1. **Extract Decision Summary:**
   Read spec Section 8 (Selected Implementation Strategy) or key architectural decisions.
   Formulate one-line summary: "{Feature}: {Key trade-off or decision}"

2. **Update PIN (specs/README.md):**
   - Remove entry from "Active Specs" table
   - Add entry to "Archived Knowledge" table with decision summary

3. **Archive Spec File:**
   ```bash
   mv specs/{spec-name}.md specs/archive/
   ```

4. **Commit with citation:**
   ```bash
   git add specs/README.md specs/archive/{spec-name}.md
   git commit -m "Archive: {spec-name} validated
   
   Decision: {one-line summary}
   
   (cite: specs/archive/{spec-name}.md)"
   ```
```

### 3.4 Post-Mortem Refocus

New directive for `post-mortem.md`:

```markdown
### Scope: Operational Patterns ONLY

**IGNORE** (handled by PIN/Archive):
- Architectural decisions
- Library choices
- API design
- Business logic

**FOCUS ON:**
- Failed bash commands (command not found, wrong syntax)
- Recurring code syntax errors (agent-generated)
- Tool misuse (grep on binary, wrong file paths)
- VDD verification failures (why plan didn't anticipate)
- Rate limits and timeouts
- Subagent inefficiencies

**Log Format Awareness:**
Session events may have mixed formats:
- `format: "stream-json"` (Claude Code): Parse as JSON
- `format: "text"` (Copilot): Analyze semantically

**Output:** lessons-learned.md = "Execution Best Practices" guide
```

### 3.5 Telemetry Event Schema

JSON schema for `logs/session-events.jsonl`:

```json
{
  "timestamp": "2026-01-29T12:34:56Z",
  "agent": "claude",
  "model": "opus",
  "mode": "build",
  "format": "stream-json",
  "status": "success",
  "duration_seconds": 123,
  "iteration": 1,
  "task_id": "implement-auth-controller",
  "spec_cited": "specs/auth-system.md",
  "files_touched": ["src/auth.js", "tests/auth.test.js"],
  "error_type": null,
  "retry_count": 0,
  "exit_code": 0
}
```

### 3.6 Security Hooks

Based on proven patterns from other projects, implement security hooks to prevent destructive operations.

**hooks/core/pre-tool-use.sh** (or .py):
```bash
#!/usr/bin/env bash
# Block dangerous commands before execution

# Read JSON from stdin
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# Block dangerous rm patterns
if [[ "$TOOL_NAME" == "Bash" ]]; then
    if echo "$COMMAND" | grep -qE 'rm\s+.*-[a-z]*r[a-z]*f|rm\s+-rf|rm\s+--recursive.*--force'; then
        echo "BLOCKED: Dangerous rm command detected" >&2
        exit 2  # Exit 2 = block tool, show error to Claude
    fi
    
    # Block force push
    if echo "$COMMAND" | grep -qE 'git\s+push\s+(-f|--force)'; then
        echo "BLOCKED: Force push is prohibited" >&2
        exit 2
    fi
fi

# Block .env file access (except .env.example/.env.sample)
if [[ "$TOOL_NAME" =~ ^(Read|Write|Edit)$ ]]; then
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
    if echo "$FILE_PATH" | grep -qE '\.env$|\.env\.[^(example|sample)]'; then
        echo "BLOCKED: Direct .env access prohibited. Use .env.example" >&2
        exit 2
    fi
fi

exit 0
```

**.claude/settings.json** integration:
```json
{
  "permissions": {
    "deny": [
      "Bash(git push --force:*)",
      "Bash(git push -f:*)",
      "Bash(rm -rf:*)"
    ]
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/hooks/core/pre-tool-use.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/hooks/core/log-event.sh post-tool \"$?\" || true"
          }
        ]
      }
    ]
  }
}
```

**Blocked patterns:**
- `rm -rf`, `rm -fr`, `rm --recursive --force` (and variations)
- `git push --force`, `git push -f`
- Direct `.env` file access (allow `.env.example`, `.env.sample`)
- Parent directory traversal in destructive commands

### 3.7 Telemetry Hook (hooks/core/log-event.sh)

```bash
#!/usr/bin/env bash
# hooks/core/log-event.sh - Emit structured telemetry event
# Usage: log-event.sh <agent> <model> <mode> <format> <status> <duration> <exit_code> [meta_json]

set -euo pipefail

AGENT="${1:-unknown}"
MODEL="${2:-unknown}"
MODE="${3:-unknown}"
FORMAT="${4:-text}"
STATUS="${5:-unknown}"
DURATION="${6:-0}"
EXIT_CODE="${7:-0}"
META_JSON="${8:-{}}"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
LOG_FILE="logs/session-events.jsonl"

# Ensure logs directory exists
mkdir -p logs

# Build JSON event (using printf to avoid jq dependency)
EVENT=$(cat <<EOF
{"timestamp":"${TIMESTAMP}","agent":"${AGENT}","model":"${MODEL}","mode":"${MODE}","format":"${FORMAT}","status":"${STATUS}","duration_seconds":${DURATION},"exit_code":${EXIT_CODE},"meta":${META_JSON}}
EOF
)

# Append to JSONL file
echo "$EVENT" >> "$LOG_FILE"
```

### 3.7 loop.sh Modifications

#### 3.7.1 Conditional Push (Issue #13 Bug #2)

Replace current push logic with:

```bash
# Push changes if any AND remote exists
push_if_possible() {
    # Check if remote exists
    if ! git remote -v | grep -q .; then
        log "No remote configured, skipping push"
        return 0
    fi
    
    # Check if there are changes to push
    NEEDS_PUSH=false
    if ! git diff --quiet || ! git diff --cached --quiet; then
        NEEDS_PUSH=true
    elif git rev-parse --verify "@{u}" >/dev/null 2>&1; then
        AHEAD=$(git rev-list --count "@{u}..HEAD" 2>/dev/null || echo "0")
        [ "$AHEAD" -gt 0 ] && NEEDS_PUSH=true
    else
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
}
```

#### 3.7.2 Telemetry Integration

Around agent execution, add timing and telemetry:

```bash
# Before execution
EXEC_START=$(date +%s)

# Execute agent (existing code)
OUTPUT=$(execute_agent "$PROMPT_FILE" "$MODEL" "$PROMPT_ARGUMENTS" | tee -a "$LOG_FILE") || {
    EXEC_END=$(date +%s)
    DURATION=$((EXEC_END - EXEC_START))
    ./hooks/core/log-event.sh "$AGENT_NAME" "$MODEL" "$MODE" "$OUTPUT_FORMAT" "error" "$DURATION" "1" "{}"
    log "Error: $AGENT_NAME execution failed"
    exit 1
}

EXEC_END=$(date +%s)
DURATION=$((EXEC_END - EXEC_START))

# Determine status from output
if echo "$OUTPUT" | grep -q '<promise>COMPLETE</promise>'; then
    STATUS="complete"
elif echo "$OUTPUT" | grep -q '<promise>TASK_COMPLETE</promise>'; then
    STATUS="task_complete"
elif echo "$OUTPUT" | grep -q '<promise>ESCALATE</promise>'; then
    STATUS="escalate"
elif check_rate_limit "$OUTPUT"; then
    STATUS="rate_limit"
else
    STATUS="continue"
fi

# Get output format from config
if [ "$JQ_AVAILABLE" = true ]; then
    OUTPUT_FORMAT=$(jq -r ".agents.${AGENT_NAME}.outputFormat // \"text\"" "$CONFIG_FILE" 2>/dev/null || echo "text")
else
    OUTPUT_FORMAT="text"
fi

# Log telemetry event
./hooks/core/log-event.sh "$AGENT_NAME" "$MODEL" "$MODE" "$OUTPUT_FORMAT" "$STATUS" "$DURATION" "0" "{}"
```

---

## 4. API / Interface

### 4.1 New Directories

| Path | Purpose | Created By |
|------|---------|-----------|
| `specs/archive/` | Frozen validated specs | validate mode (on PASS) |
| `tests/unit/` | Unit tests (convention) | build mode (as needed) |
| `tests/e2e/` | VDD verification scripts | plan mode (mandatory for infra) |
| `hooks/core/` | Agent-agnostic telemetry scripts | This spec |
| `hooks/adapters/claude/` | Claude-specific wrappers | Future (if needed) |
| `hooks/adapters/copilot/` | Copilot-specific wrappers | Future (if needed) |

### 4.2 Modified Files

| File | Modification |
|------|-------------|
| `specs/README.md` | New structure: Active Specs + Archived Knowledge |
| `.claude/commands/plan.md` | Add VDD rules + archive exclusion |
| `.claude/commands/validate.md` | Add archival process on PASS |
| `.claude/commands/post-mortem.md` | Refocus to operational patterns |
| `loop.sh` | Telemetry hooks + conditional push |

### 4.3 Deleted Files

| Path | Reason |
|------|--------|
| `prompts/*.md` (all symlinks) | Obsolete, .claude/commands/ is canonical |
| `prompts/` (directory) | Empty after symlink removal |

---

## 5. Testing Strategy

### Manual Verification

1. **Archive Lifecycle:**
   - Create test spec, implement, validate
   - Verify spec moved to `specs/archive/`
   - Verify PIN updated with decision summary

2. **VDD Flow:**
   - Create spec requiring infrastructure
   - Run plan mode
   - Verify first task is "Create E2E verification script"

3. **Telemetry:**
   - Run any mode
   - Verify `logs/session-events.jsonl` contains event
   - Verify JSON is valid: `jq . logs/session-events.jsonl`

4. **Conditional Push:**
   - Create repo without remote: `git init test-repo`
   - Run loop.sh
   - Verify no push error, message: "No remote configured"

5. **Post-Mortem Focus:**
   - Run build with intentional bash error
   - Run post-mortem
   - Verify lessons-learned.md captures operational pattern, not design

---

## 6. Acceptance Criteria

- [ ] `specs/README.md` has Active Specs and Archived Knowledge sections
- [ ] `specs/archive/` directory exists
- [ ] Plan mode generates VDD task first for infra specs
- [ ] Plan mode does NOT read files in `specs/archive/`
- [ ] Validate mode (on PASS) moves spec to archive and updates PIN
- [ ] Post-mortem ignores product decisions, focuses on operational patterns
- [ ] `hooks/core/log-event.sh` exists and emits valid JSON
- [ ] `loop.sh` calls telemetry hook after each iteration
- [ ] `loop.sh` skips push if no remote configured (no error)
- [ ] `tests/unit/` and `tests/e2e/` directories exist
- [ ] `prompts/` directory removed (symlinks deleted)
- [ ] `build.md` Step 6 captures commit hash before writing done.md
- [ ] done.md entries include actual commit hashes (not `-`)
- [ ] `audit.md` knows about `specs/archive/` directory
- [ ] `reconcile.md` knows archived specs can't have escalations
- [ ] `.claude/settings.json` exists with security hooks
- [ ] Security hook blocks `rm -rf`, `git push --force`, `.env` access
- [ ] `.gitignore` includes telemetry files
- [ ] Documentation updated to reflect new structure

---

## 7. Implementation Guidance

> Context for plan generator to create specific, verifiable tasks

### Impact Analysis

**Change Type:** [x] Refactor (architectural evolution)

**Affected Areas:**

Files to create:
- `specs/archive/.gitkeep` (preserve empty dir)
- `tests/unit/.gitkeep`
- `tests/e2e/.gitkeep`
- `hooks/core/log-event.sh` (telemetry emitter)
- `hooks/core/pre-tool-use.sh` (security: block dangerous commands)
- `hooks/adapters/.gitkeep`
- `.claude/settings.json` (hooks configuration + deny permissions)

Files to modify:
- `specs/README.md` (~complete rewrite of structure)
- `.claude/commands/plan.md` (~30 lines: VDD rules + archive exclusion)
- `.claude/commands/build.md` (~15 lines: reorder Step 6 for commit hash capture)
- `.claude/commands/validate.md` (~40 lines: archival process)
- `.claude/commands/post-mortem.md` (~20 lines: scope refocus)
- `.claude/commands/reconcile.md` (~5 lines: archive awareness)
- `.claude/commands/audit.md` (~10 lines: archive awareness)
- `.claude/settings.json` (new: security hooks + permissions)
- `.gitignore` (~3 lines: telemetry files)
- `loop.sh` (~50 lines: telemetry + conditional push)

Files to delete:
- `prompts/audit.md` (symlink)
- `prompts/bug.md` (symlink)
- `prompts/build.md` (symlink)
- `prompts/plan.md` (symlink)
- `prompts/post-mortem.md` (symlink)
- `prompts/prime.md` (symlink)
- `prompts/reconcile.md` (symlink)
- `prompts/reverse.md` (symlink)
- `prompts/validate.md` (symlink)
- `prompts/` (directory)

Documentation to update:
- `README.md` (new directory structure, VDD concept)

### Implementation Hints

**Phase 1: Directory Structure (Safe)**
- Create new directories with .gitkeep
- Delete prompts/ symlinks and directory
- No behavioral changes yet

**Phase 2: PIN Restructure (Safe)**
- Rewrite specs/README.md with new template
- Move current entries to Active Specs section
- Empty Archived Knowledge initially

**Phase 3: Telemetry (Isolated)**
- Create hooks/core/log-event.sh
- Test independently before loop.sh integration

**Phase 4: loop.sh Modifications (CAUTION)**
- ⚠️ Changes to loop.sh while running can cause issues
- Recommend: Make changes, commit, then test with fresh invocation
- Add conditional push function
- Add telemetry integration points

**Phase 5: Prompt Modifications**
- Update plan.md (VDD + archive exclusion)
- Update validate.md (archival process)
- Update post-mortem.md (operational focus)

### Verification Strategy

```bash
# Phase 1: Directory structure
[ -d specs/archive ] && echo "✅ specs/archive exists"
[ -d tests/unit ] && echo "✅ tests/unit exists"
[ -d tests/e2e ] && echo "✅ tests/e2e exists"
[ -d hooks/core ] && echo "✅ hooks/core exists"
[ ! -d prompts ] && echo "✅ prompts/ removed"

# Phase 2: PIN structure
grep -q "## Active Specs" specs/README.md && echo "✅ Active Specs section"
grep -q "## Archived Knowledge" specs/README.md && echo "✅ Archived Knowledge section"

# Phase 3: Telemetry
[ -x hooks/core/log-event.sh ] && echo "✅ log-event.sh executable"
./hooks/core/log-event.sh claude opus build stream-json test 1 0 "{}"
jq . logs/session-events.jsonl && echo "✅ Valid JSON"

# Phase 4: loop.sh
grep -q "No remote configured" loop.sh && echo "✅ Conditional push"
grep -q "log-event.sh" loop.sh && echo "✅ Telemetry integration"

# Phase 5: Prompts
grep -q "specs/archive" .claude/commands/plan.md && echo "✅ Archive exclusion"
grep -q "VDD" .claude/commands/plan.md && echo "✅ VDD rules"
grep -q "mv specs/" .claude/commands/validate.md && echo "✅ Archival command"
grep -q "Operational Patterns" .claude/commands/post-mortem.md && echo "✅ Operational focus"
```

---

## 8. Selected Implementation Strategy

> Strategy investigation performed during design/planning phase

**Investigation date:** 2026-01-29

### Pattern Analysis
- Similar pattern found in: Current loop.sh git push logic
- Project convention: Bash scripts, no external dependencies beyond jq (optional)

### Approaches Considered

**Approach A: Single Mega-Spec (Selected)**
- Pros: Coherent view of all changes, single source of truth, easier to reason about dependencies
- Cons: Large spec, longer to implement
- Complexity: Medium

**Approach B: Multiple Focused Specs**
- Pros: Smaller specs, parallel implementation possible
- Cons: Cross-spec dependencies harder to track, risk of inconsistency
- Complexity: Medium (but higher coordination overhead)

**Approach C: Incremental PRs Without Spec**
- Pros: Faster to start
- Cons: Loses design coherence, violates framework philosophy
- Complexity: Low initially, high in maintenance

### Decision

**Selected:** Approach A (Single Mega-Spec)

**Justification:** This is an architectural evolution touching multiple interconnected components. A single spec ensures all changes are designed together and dependencies are explicit.

**Accepted trade-offs:** Longer implementation cycle, but cleaner result.

### Hooks Architecture Decision

**Selected:** Hybrid (core scripts + agent adapters)

**Justification:** 
- Claude Code outputs `stream-json` → trivial to parse
- Copilot outputs `text` → needs regex/semantic parsing
- Core telemetry script is agent-agnostic
- Adapters can be added later if needed

**Accepted trade-offs:** Initial implementation only covers core; adapters deferred.

---

## 9. Notes

### Migration Path for Existing Specs

Existing specs in `specs/` are NOT automatically moved. The archival process applies only to specs validated AFTER this system is implemented.

To manually archive an existing spec:
1. Add entry to Archived Knowledge in PIN with decision summary
2. Move file: `mv specs/foo.md specs/archive/`
3. Commit changes

### loop.sh Modification Safety

⚠️ **IMPORTANT:** `loop.sh` cannot be safely modified while it's running itself.

Recommended approach:
1. Make all loop.sh changes in a single task
2. Commit immediately
3. Test with a fresh `./loop.sh` invocation
4. Do NOT use `work` mode to modify loop.sh

### Backward Compatibility

- Existing `plan.md` tasks remain valid
- Existing `pending-validations.md` entries remain valid
- Old logs in `logs/log-*.txt` are preserved
- New telemetry is additive (new file, not replacing old logs)

### Issue #13 Integration

This spec addresses both bugs from Issue #13:
- **Bug #1 (Frozen specs):** Resolved by archive model — specs in `specs/` are always analyzed; archived specs are summarized in PIN
- **Bug #2 (Push without remote):** Resolved by conditional push function

### Audit Mode Interaction

**Changes needed in audit.md:**

1. **Phase 0 awareness:** Understand Active vs Archived sections in PIN
2. **Step 1 Inventory:** Include `specs/archive/` in directory listing
3. **Step 2 Scope:** 
   - Audit ✅ specs that are in `specs/archive/` (already validated)
   - Also audit any ✅ specs still in `specs/` (shouldn't happen normally)
4. **Missing strategy check:** Only report for specs in `specs/` (archived specs already passed validation)

**audit.md modifications (~10 lines):**
```markdown
## Phase 0: Orient (update step 2)

2. Note which specs are marked ✅ (Implemented):
   - Check `specs/` for active specs
   - Check `specs/archive/` for archived (validated) specs
   - Both are audit targets
```

### .gitignore Updates

**Current .gitignore is mostly complete.** Add:

```gitignore
# Telemetry (structured logs)
logs/session-events.jsonl

# Claude Code settings (may contain personal permissions)
# Note: .claude/settings.json is project-specific, consider if it should be tracked
```

**Do NOT ignore:**
- `hooks/` — This is project code, must be tracked
- `specs/archive/` — This is validated documentation, must be tracked
- `tests/e2e/` — VDD scripts, must be tracked

### Reconcile Mode Interaction

**Key principle:** Reconcile does NOT archive specs. Only validate mode (on PASS) triggers archival.

**Why escalated specs are never archived:**
- Escalation means validation FAILED 3 times
- Spec is still in `specs/` (Active), not `specs/archive/`
- After reconcile resolves the issue, spec returns to pending-validations
- Next validate run (if PASS) handles archival

**Changes needed in reconcile.md:**

1. **Phase 0 awareness:** Update to understand PIN has Active/Archived sections
2. **Option B clarification:** After updating spec, do NOT move to archive — leave for validate to handle
3. **Add note:** "Archived specs cannot have escalations (they already passed validation)"

**reconcile.md modifications (~5 lines):**
```markdown
## Phase 0: Orient (add after step 2)

3. Note: Escalated specs are always in `specs/` (Active), never in `specs/archive/`
   (Archived specs passed validation; escalations only occur for failed validations)
```

### done.md Commit Hash Fix

**Problem:** Current build.md writes to done.md BEFORE committing, so the commit hash is unknown. Entries show `-` instead of actual hash.

**Solution:** Reorder Step 6 in build.md:

1. Commit changes (without done.md)
2. Capture commit hash: `HASH=$(git rev-parse --short HEAD)`
3. Append entry to done.md with actual hash
4. Amend commit to include done.md: `git add done.md && git commit --amend --no-edit`

**New Step 6 flow:**
```bash
# 1. Commit implementation
git add plan.md {affected files}
git commit -m "Task: {brief description}..."

# 2. Capture hash
HASH=$(git rev-parse --short HEAD)

# 3. Update done.md with real hash
echo "| $(date '+%Y-%m-%d %H:%M') | {task-title} | $HASH | {spec-path} |" >> done.md

# 4. Amend to include done.md
git add done.md
git commit --amend --no-edit
```

This ensures every done.md entry has a clickable commit reference.

---

**Related specs:**
- `loop-orchestrator-system.md` — Modified for telemetry and conditional push
- `prompt-plan-system.md` — Modified for VDD and archive exclusion
- `prompt-build-system.md` — Modified for commit hash capture in done.md
- `prompt-validate-system.md` — Modified for archival lifecycle
- `post-mortem-system.md` — Modified for operational focus
- `reconcile-system.md` — Modified for archive awareness
- `audit-system.md` — Modified for archive awareness
- `done-tracking-system.md` — Enhanced with actual commit hashes

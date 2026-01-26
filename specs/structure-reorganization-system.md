# Structure Reorganization System

> Reorganize loopy-claude to align with Claude Code plugin conventions, extract validate agents, and add automated work mode

## Status: Validated

---

## 1. Overview

### Purpose

Evolve loopy-claude's structure to follow Claude Code plugin conventions (`.claude/commands/`, `.claude/agents/`), extract reusable validation agents, and add an automated `work` mode that orchestrates build→validate cycles with fresh context per iteration.

### Goals

- Reorganize prompts into `.claude/commands/` with proper frontmatter
- Extract validate.md's parallel Tasks into standalone agents (`.claude/agents/`)
- Add `work` mode to loop.sh that alternates build/validate automatically
- Maintain backward compatibility (loop.sh continues working)
- Enable interactive use of commands via `/plan`, `/build`, etc.
- Enable independent testing of validation agents
- Preserve fresh context per iteration (key loopy-claude principle)

### Non-Goals

- Converting to full Claude Code plugin format (deferred to future spec)
- Changing the core logic of plan.md, build.md, validate.md, reverse.md
- Adding external dependencies (Python SDK, databases, etc.)
- Modifying the spec creation workflow (feature-designer skill unchanged)
- Implementing export-loopy.sh changes (separate concern)

---

## 2. Architecture

### Components

```
BEFORE:
loopy-claude/
├── prompts/
│   ├── plan.md
│   ├── build.md
│   ├── validate.md
│   └── reverse.md
├── .claude/
│   └── skills/
│       └── feature-designer/
└── loop.sh

AFTER:
loopy-claude/
├── .claude/
│   ├── commands/
│   │   ├── plan.md          ← Moved + frontmatter
│   │   ├── build.md         ← Moved + frontmatter
│   │   ├── validate.md      ← Moved + frontmatter + agent refs
│   │   ├── reverse.md       ← Moved + frontmatter
│   │   ├── prime.md         ← Moved + frontmatter (orientation)
│   │   └── bug.md           ← NEW: Bug analysis and task creation
│   ├── agents/
│   │   ├── spec-checker.md  ← NEW: Extracted from validate
│   │   └── spec-inferencer.md ← NEW: Extracted from validate
│   └── skills/
│       └── feature-designer/
├── prompts/                  ← DEPRECATED (symlinks or remove)
└── loop.sh                   ← MODIFIED: new work mode + frontmatter filter
```

### Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    ./loop.sh work 50                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ LOOP (until no pending work OR max iterations)          │   │
│  │                                                          │   │
│  │   ┌──────────────────┐                                  │   │
│  │   │ Check plan.md    │                                  │   │
│  │   │ for `- [ ]` tasks│                                  │   │
│  │   └────────┬─────────┘                                  │   │
│  │            │                                             │   │
│  │      ┌─────▼─────┐     YES                              │   │
│  │      │ Has tasks?├──────────► RUN BUILD (1 iteration)   │   │
│  │      └─────┬─────┘            └──► Fresh context        │   │
│  │            │ NO                    └──► TASK_COMPLETE   │   │
│  │            ▼                                             │   │
│  │   ┌────────────────────┐                                │   │
│  │   │ Check pending-     │                                │   │
│  │   │ validations.md     │                                │   │
│  │   │ for `- [ ]` specs  │                                │   │
│  │   └────────┬───────────┘                                │   │
│  │            │                                             │   │
│  │      ┌─────▼─────┐     YES                              │   │
│  │      │ Has specs?├──────────► RUN VALIDATE (1 iter)     │   │
│  │      └─────┬─────┘            └──► Fresh context        │   │
│  │            │ NO                    └──► SPEC_VALIDATED  │   │
│  │            ▼                            or CORRECTIONS  │   │
│  │   ┌────────────────┐                                    │   │
│  │   │ ALL COMPLETE   │                                    │   │
│  │   │ Exit loop      │                                    │   │
│  │   └────────────────┘                                    │   │
│  │                                                          │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Validate Agent Invocation Flow

```
validate.md (orchestrator)
    │
    ├─► Step 2: Code Discovery (direct Read/Grep)
    │
    ├─► Step 3: Parallel Verification
    │       │
    │       ├─► Task 1: Read .claude/agents/spec-checker.md
    │       │           Inject: SPEC_PATH, SPEC_TEXT, EVIDENCE
    │       │           Model: sonnet
    │       │           Description: "Run subagent spec-checker (explicit)"
    │       │
    │       └─► Task 2: Read .claude/agents/spec-inferencer.md
    │                   Inject: SPEC_PATH, SPEC_TEXT, EVIDENCE
    │                   Model: opus
    │                   Description: "Run subagent spec-inferencer (explicit)"
    │
    └─► Step 4: Merge results, deduplicate, decide
```

### Dependencies

| Component | Purpose | Location |
|-----------|---------|----------|
| bash | Shell interpreter | System |
| claude CLI | Agent execution | System |
| sed | Frontmatter filtering | System |
| grep | Task/validation detection | System |
| Existing commands | plan, build, validate, reverse | .claude/commands/ |
| New agents | spec-checker, spec-inferencer | .claude/agents/ |

---

## 3. Implementation Details

### 3.1 Command Frontmatter Format

Each command in `.claude/commands/` requires YAML frontmatter:

```yaml
---
name: command-name
description: Brief description of what command does
---

# Command Title

[existing content unchanged]
```

**Specific frontmatter for each command:**

```yaml
# plan.md
---
name: plan
description: Generate implementation plan from specs using multi-phase analysis with extended thinking
---

# build.md
---
name: build
description: Execute ONE task from plan.md with mandatory verification and fix loop
---

# validate.md
---
name: validate
description: Validate ONE spec from pending-validations.md using parallel checker and inferencer agents
---

# reverse.md
---
name: reverse
description: Analyze legacy code and generate specifications (READ-ONLY guarantee)
---

# prime.md
---
name: prime
description: Gain understanding of the repository structure and philosophy before working
---

# bug.md
---
name: bug
description: Analyze a reported bug, determine root cause, and create corrective tasks in plan.md
---
```

### 3.2 Bug Command Definition

**bug.md:**

```yaml
---
name: bug
description: Analyze a reported bug, determine root cause, and create corrective tasks in plan.md
---

# Bug Analysis

Analyze the reported bug and create corrective tasks in plan.md.

## Input

$ARGUMENTS - Description of the bug or problem detected

## Workflow

1. **Understand the problem**
   - Parse the bug description from $ARGUMENTS
   - Identify which component/spec is affected
   - Search codebase for related code (Grep, Read)

2. **Locate the spec**
   - Find the relevant spec in specs/
   - Read the spec to understand expected behavior
   - Compare expected vs actual behavior

3. **Determine bug type**
   - **Code bug**: Implementation doesn't match spec
   - **Spec bug**: Spec is incomplete or incorrect
   - **Missing feature**: Spec exists but feature not implemented

4. **Strategic Analysis** (for code bugs and missing features)

   Before creating tasks, analyze for optimal grouping:

   **4.1 Check existing plan.md:**
   - Are there pending tasks touching the same files?
   - Are there related tasks that should be grouped?
   - If yes → merge fix into existing task or group together

   **4.2 Context budget estimation:**
   - **Small** (<500 lines): Single task OK
   - **Medium** (500-1500 lines): Consider grouping related fixes
   - **Large** (>2000 lines): MUST split into logical sub-tasks

   **4.3 Dependency check:**
   - Does fix depend on other pending tasks? → Order appropriately
   - Do other tasks depend on this fix? → Mark as foundational

   **4.4 Grouping rules:**
   - Same file + <500 lines = MAX 1 task (group everything)
   - Related files + <1500 lines = Prefer grouping
   - If splitting, add: `[Split: reason]`

   **Output:** Decision on task structure (single/grouped/split)

5. **Create corrective action**

   **If code bug:**
   Add task to plan.md (applying Phase 4 decisions):
   ```markdown
   - [ ] Fix: {brief description of the fix needed}
         Done when: {concrete criteria}
         Verify: {command or check}
         (cite: specs/{relevant-spec}.md)
         [Grouped: reason] or [Split: reason] (if applicable)
   ```

   **If missing feature:**
   Add task to plan.md with implementation steps (apply same grouping rules).

   **If spec bug:**
   Output recommendation:
   ```
   SPEC_UPDATE_NEEDED: specs/{spec}.md
   Issue: {what's wrong with the spec}
   Suggestion: {how to fix it}
   
   → Run /feature-designer to update the spec
   ```

6. **Report**
   - Summarize what was found
   - Confirm task added to plan.md (or spec update needed)
   - Suggest next step: `./loop.sh build` or `/feature-designer`

## Output

After analysis, output one of:

```
✅ Task added to plan.md
   Fix: {description}
   Next: ./loop.sh build
```

or

```
⚠️ Spec update needed
   Spec: specs/{name}.md
   Issue: {description}
   Next: /feature-designer
```

## Constraints

- Do NOT modify specs (only plan.md for code bugs)
- Do NOT implement fixes (only create tasks)
- Always cite the relevant spec
- If unclear, ask for clarification before creating task
```

### 3.3 Agent Definitions

**spec-checker.md:**

```yaml
---
name: spec-checker
description: Use when validating implementation against spec acceptance criteria. Mechanical checklist verification with evidence-based PASS/FAIL.
tools: ["Read", "Grep", "Bash"]
model: sonnet
color: green
---

# Spec Checker Agent

## Inputs (provided by orchestrator)
- SPEC_PATH: Path to specification file
- SPEC_TEXT: Full specification content
- EVIDENCE: Pre-gathered code discovery (files, excerpts, grep results)

## Task
Extract ALL acceptance criteria from SPEC_TEXT and verify each using EVIDENCE and codebase access.

For each criterion:
1. Identify what should exist (function, class, config, test, etc.)
2. Search codebase to verify existence
3. Check if implementation matches spec requirements
4. Output: PASS or FAIL with evidence

## Critical Verification Rules

### Rule 1: Enumerated Sets Must Be Complete

When the spec lists an explicit set of items (files, commands, flags, endpoints):
- You MUST verify EVERY item in the set exists
- Partial matches are FAIL (5 of 6 = FAIL)
- Report "Expected vs Found vs Missing" explicitly

**Example:**
```
Spec says: "commands/ contains plan.md, build.md, validate.md, reverse.md, prime.md, bug.md"
Check: ls -la .claude/commands/*.md
Expected: 6 files
Found: 5 files (missing bug.md)
Result: ❌ FAIL
```

### Rule 2: Literal Strings Must Match Exactly

When the spec provides an exact command, pattern, or code snippet:
- You MUST verify exact literal match using `grep -F` (fixed string)
- "Functionally similar" is NOT acceptable unless spec explicitly allows alternatives
- Run the spec's test snippets if provided

**Example:**
```
Spec says: sed '1{/^---$/!q;};1,/^---$/d'
Check: grep -F "sed '1{/^---$/!q;};1,/^---$/d'" loop.sh
Found: sed '/^---$/,/^---$/d'
Result: ❌ FAIL (different pattern)
```

## Output Format (STRICT)

SET CHECKS:

- Set: {what is being enumerated}
  Expected: [{item1}, {item2}, ...]
  Found: [{items found}]
  Missing: [{items not found}]
  Result: ✅ PASS / ❌ FAIL

LITERAL CHECKS:

- Literal: {exact string from spec}
  Location: {where it should be}
  Found: {what was actually found}
  Result: ✅ PASS / ❌ FAIL

CHECKLIST RESULTS:

✅ PASS: {criterion description}
   Evidence: {file:line or grep result}

❌ FAIL: {criterion description}
   Expected: {what spec requires}
   Found: {what exists or "not found"}

## Constraints
- Do NOT infer or assume - only verify observable facts
- Do NOT spawn subagents (orchestrator handles parallelism)
- Evidence required for every finding
- Partial set matches are FAIL
- Approximate literal matches are FAIL
```

**spec-inferencer.md:**

```yaml
---
name: spec-inferencer
description: Use when validating implementation behavior against specification intent. Semantic inference to detect behavioral drift.
tools: ["Read", "Grep", "Bash"]
model: opus
color: magenta
---

# Spec Inferencer Agent

## Inputs (provided by orchestrator)
- SPEC_PATH: Path to specification file
- SPEC_TEXT: Full specification content
- EVIDENCE: Pre-gathered code discovery (files, excerpts, grep results)

## Task
1. Read ALL code implementing this spec
2. Generate "behavior summary" - what code ACTUALLY does (not what spec says)
3. Compare actual behavior against spec's Purpose, Goals, JTBD, Architecture
4. Identify divergences between actual behavior and spec intent

## Output Format (STRICT)

BEHAVIOR SUMMARY:

What the code does:
- {observed behavior 1}
- {observed behavior 2}
...

DIVERGENCES:

1. {description of divergence}
   Spec requires: {requirement}
   Code does: {actual behavior}
   Impact: {severity: low/medium/high}

2. {next divergence}
...

If no divergences: "No divergences detected. Implementation matches spec intent."

## Constraints
- Focus on WHAT code does, not HOW
- Infer intent from behavior
- Do NOT spawn subagents
- Mark confidence if uncertain about finding
```

### 3.3 Modified validate.md (Agent Invocation)

Replace inline Task prompts with agent file references:

```markdown
### Step 3: Parallel Verification (MANDATORY)

**CRITICAL:** Launch BOTH tasks in parallel. Do NOT run sequentially.

**Task 1: Mechanical Checklist**

1. Read `.claude/agents/spec-checker.md` completely
2. Use its instructions as the Task prompt
3. Append context block:
   ```
   --- CONTEXT ---
   SPEC_PATH: {spec_path}
   SPEC_TEXT: {full spec content}
   EVIDENCE:
     RELEVANT_FILES: {discovered files}
     FILE_EXCERPTS: {key code sections with file:line}
     GREP_RESULTS: {pattern search results}
   ```
4. Task description: "Run subagent spec-checker (explicit). Verify acceptance criteria mechanically."
5. Model: sonnet

**Task 2: Semantic Inference**

1. Read `.claude/agents/spec-inferencer.md` completely
2. Use its instructions as the Task prompt
3. Append same context block as Task 1
4. Task description: "Run subagent spec-inferencer (explicit). Summarize behavior and compare to intent."
5. Model: opus

**Execute Tasks:**
Launch both tasks simultaneously using the Task tool. Wait for both to complete before proceeding.
```

### 3.4 Modified loop.sh

**Changes required:**

1. **Update PROMPT_FILE path:**
```bash
# Before
PROMPT_FILE="prompts/${MODE}.md"

# After
PROMPT_FILE=".claude/commands/${MODE}.md"
```

2. **Add frontmatter filter function:**
```bash
# Filter YAML frontmatter from command files
filter_frontmatter() {
    local file="$1"
    # Remove lines between first --- and second ---
    sed '1{/^---$/!q;};1,/^---$/d' "$file"
}
```

3. **Modify claude invocation:**
```bash
# Before
cat "$PROMPT_FILE" | claude -p --model "$MODEL" ...

# After
filter_frontmatter "$PROMPT_FILE" | claude -p --model "$MODEL" ...
```

4. **Add work mode:**
```bash
# New mode handling
case "$MODE" in
    work)
        log "Work mode: alternating build/validate until complete"
        
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
                log "No pending work - all complete!"
                break
            fi
            
            # Set model for current mode
            case "$CURRENT_MODE" in
                build) CURRENT_MODEL="sonnet" ;;
                validate) CURRENT_MODEL="sonnet" ;;
            esac
            
            # Execute single iteration
            CURRENT_PROMPT=".claude/commands/${CURRENT_MODE}.md"
            OUTPUT=$(filter_frontmatter "$CURRENT_PROMPT" | claude -p \
                --model "$CURRENT_MODEL" \
                --dangerously-skip-permissions \
                --output-format=stream-json \
                --verbose 2>&1 | tee -a "$LOG_FILE")
            
            # Check for rate limit
            if echo "$OUTPUT" | jq -e 'select(.error.type == "rate_limit_error")' >/dev/null 2>&1; then
                log "Rate limit detected - stopping"
                break
            fi
            
            # Push changes if any
            if ! git diff --quiet || ! git diff --cached --quiet; then
                git push origin "$CURRENT_BRANCH" 2>&1 | tee -a "$LOG_FILE" || true
            fi
            
            ITERATION=$((ITERATION + 1))
            log "Work iteration $ITERATION complete (ran $CURRENT_MODE)"
        done
        
        exit 0
        ;;
esac
```

### 3.5 Backward Compatibility

**Option A: Symlinks (recommended)**
```bash
# Create prompts/ as symlinks to .claude/commands/
mkdir -p prompts
ln -sf ../.claude/commands/plan.md prompts/plan.md
ln -sf ../.claude/commands/build.md prompts/build.md
ln -sf ../.claude/commands/validate.md prompts/validate.md
ln -sf ../.claude/commands/reverse.md prompts/reverse.md
```

**Option B: Remove prompts/ entirely**
- Update any documentation referencing prompts/
- Update export-loopy.sh to use new paths
- Remove prompts/ directory

---

## 4. Acceptance Criteria

### Structure Reorganization
- [ ] `.claude/commands/` directory exists with plan.md, build.md, validate.md, reverse.md, prime.md, bug.md
- [ ] Each command has valid YAML frontmatter (name, description)
- [ ] `.claude/agents/` directory exists with spec-checker.md, spec-inferencer.md
- [ ] Each agent has valid frontmatter (name, description, tools, model, color)
- [ ] prompts/ either removed or contains symlinks to .claude/commands/
- [ ] bug.md accepts $ARGUMENTS and creates tasks in plan.md

### loop.sh Modifications
- [ ] loop.sh reads from `.claude/commands/` instead of `prompts/`
- [ ] Frontmatter is filtered before passing to claude CLI
- [ ] Existing modes (plan, build, validate, reverse) work unchanged
- [ ] New `work` mode alternates build/validate automatically
- [ ] `work` mode terminates when no `- [ ]` in plan.md AND pending-validations.md
- [ ] `work` mode respects max_iterations as safety limit
- [ ] Rate limit detection works in work mode

### Agent Integration
- [ ] validate.md references agents via file read + context injection
- [ ] spec-checker.md can be invoked standalone for testing
- [ ] spec-inferencer.md can be invoked standalone for testing
- [ ] Parallel Task invocation works with explicit agent naming
- [ ] Agent output format matches expected schema for merge step

### Backward Compatibility
- [ ] `./loop.sh build` continues to work
- [ ] `./loop.sh plan 5` continues to work
- [ ] `./loop.sh validate` continues to work
- [ ] Interactive `/plan`, `/build`, `/validate`, `/prime`, `/bug` commands available in Claude

---

## 5. Implementation Guidance

### Impact Analysis

**Change Type:** [X] Enhancement | [ ] New Feature | [ ] Refactor

**Affected Areas:**

Files/components affected:
- **MOVE:** `prompts/*.md` → `.claude/commands/*.md`
- **NEW:** `.claude/agents/spec-checker.md`
- **NEW:** `.claude/agents/spec-inferencer.md`
- **MODIFY:** `loop.sh` (frontmatter filter + work mode)
- **MODIFY:** `.claude/commands/validate.md` (agent references)
- **UPDATE:** `specs/README.md` (add this spec)
- **UPDATE:** `README.md` (document new structure)

Integration points:
- loop.sh → .claude/commands/*.md (path change)
- validate.md → .claude/agents/*.md (new dependency)
- Claude CLI → frontmatter filter (new preprocessing)

### Implementation Hints

**Phase 1: Structure (no logic changes)**
1. Create `.claude/commands/` directory
2. Copy prompts/*.md to .claude/commands/*.md (plan, build, validate, reverse, prime)
3. Add frontmatter to each command
4. Create bug.md as new command
5. Create `.claude/agents/` directory
6. Create spec-checker.md and spec-inferencer.md
7. Test: verify files exist with correct structure

**Phase 2: loop.sh modifications**
1. Add `filter_frontmatter()` function
2. Change PROMPT_FILE path
3. Update claude invocation to use filter
4. Test: `./loop.sh build` still works

**Phase 3: work mode**
1. Add work mode case in loop.sh
2. Implement alternating logic
3. Test: `./loop.sh work 5` alternates correctly

**Phase 4: validate.md agent integration**
1. Modify Step 3 to read agent files
2. Update Task prompts to inject context
3. Test: validate mode uses agents correctly

**Phase 5: Cleanup**
1. Decide: symlinks or remove prompts/
2. Update documentation
3. Update specs/README.md

### Verification Strategy

**Command-based verification:**

```bash
# Test 1: Structure exists
test -d .claude/commands && echo "✅ commands dir exists"
test -d .claude/agents && echo "✅ agents dir exists"
test -f .claude/commands/build.md && echo "✅ build.md moved"
test -f .claude/commands/prime.md && echo "✅ prime.md moved"
test -f .claude/commands/bug.md && echo "✅ bug.md created"
test -f .claude/agents/spec-checker.md && echo "✅ spec-checker created"

# Test 2: Frontmatter present
head -1 .claude/commands/build.md | grep -q "^---$" && echo "✅ frontmatter present"

# Test 3: loop.sh still works
./loop.sh build 1  # Should execute one build iteration

# Test 4: work mode
./loop.sh work 3   # Should alternate based on pending work

# Test 5: Interactive commands available
claude -p "Show available commands" | grep -q "/build" && echo "✅ /build available"
```

**Manual checks:**
- Run full build cycle with `./loop.sh build 5`
- Run validate cycle with `./loop.sh validate 3`
- Run work cycle with `./loop.sh work 10`
- Verify agents are invoked in validate mode (check logs)
- Test `/plan` interactively in Claude

---

## 6. Testing Strategy

### Unit Tests (manual)

**Test 1: Frontmatter filter**
```bash
# Create test file
cat > /tmp/test.md << 'EOF'
---
name: test
description: Test command
---

# Actual Content
This should appear.
EOF

# Test filter
sed '1{/^---$/!q;};1,/^---$/d' /tmp/test.md
# Expected: Only "# Actual Content" and "This should appear."
```

**Test 2: Work mode termination**
```bash
# Setup: Empty plan.md and pending-validations.md
echo "# Plan" > plan.md
echo "# Pending" > pending-validations.md

./loop.sh work 10
# Expected: Immediate "No pending work - all complete!"
```

**Test 3: Work mode alternation**
```bash
# Setup: Add task to plan.md
echo "- [ ] Test task" >> plan.md

./loop.sh work 2
# Expected: Runs build, then checks again
```

### Integration Tests

**Test 1: Full workflow**
```bash
# 1. Create a simple spec
# 2. Run ./loop.sh plan 3
# 3. Review plan.md has tasks
# 4. Run ./loop.sh work 20
# 5. Verify: tasks completed, validations run, specs validated
```

---

## 7. Notes

### Design Decisions

**Why move to .claude/commands/ instead of keeping prompts/?**
- Aligns with Claude Code plugin conventions
- Enables auto-discovery of commands (`/plan`, `/build`, etc.)
- Single source of truth (no duplication)
- Future-proofs for full plugin conversion

**Why extract agents instead of keeping inline Task prompts?**
- Testability: Agents can be invoked standalone
- Reusability: Other commands could use same agents
- Maintainability: Clear separation of concerns
- Scalability: Easy to add more validation agents

**Why explicit agent invocation (read file + inject context)?**
- Task tool doesn't support agent references directly
- Explicit naming in description increases selection accuracy
- Context packet gives full control over what agent sees
- Pattern proven in production (TAC orchestrator, compound-engineering-plugin)

**Why work mode alternates instead of running all build then all validate?**
- Corrections from validate create new tasks in plan.md
- Alternating catches issues early
- Each iteration = fresh context (key loopy-claude principle)
- Matches natural development flow: implement → verify → fix → verify

### Trade-offs Accepted

**Limitation:** Agent selection not 100% guaranteed
- **Pro:** Works with existing Task tool
- **Con:** Claude interprets, doesn't execute literally
- **Mitigation:** Explicit naming in description + prompt

**Limitation:** Work mode adds complexity to loop.sh
- **Pro:** Fully automated build→validate cycles
- **Con:** More code to maintain
- **Mitigation:** Clean separation, well-documented

**Limitation:** Frontmatter filter adds preprocessing
- **Pro:** Enables dual use (loop.sh + interactive)
- **Con:** Extra step in pipeline
- **Mitigation:** Simple one-liner sed, well-tested

### Future Enhancements

- Convert to full Claude Code plugin (plugin.json, auto-discovery)
- Add more validation agents (security-checker, performance-analyzer)
- Add hooks for pre/post build actions
- Integrate with MCP servers for external tools
- Export as installable plugin (`amp plugin add`)

---

## 8. References

### Internal
- [loop-orchestrator-system.md](loop-orchestrator-system.md) - Current loop.sh spec
- [prompt-build-system.md](prompt-build-system.md) - Build mode spec
- [prompt-validate-system.md](prompt-validate-system.md) - Validate mode spec

### External
- [Claude Code Subagents](https://code.claude.com/docs/en/sub-agents) - Official subagent documentation
- [compound-engineering-plugin](https://github.com/EveryInc/compound-engineering-plugin) - Reference implementation
- [TAC orchestrator](https://github.com/tomaslucas/tac) - SDK-based workflow orchestration

---

**Version:** 1.0
**Last Updated:** 2026-01-25
**Authors:** Collaborative design session (human + Claude)

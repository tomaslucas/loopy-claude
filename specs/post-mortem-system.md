# Post-Mortem Learning System

> Autonomous session analysis that extracts lessons from execution logs and maintains persistent knowledge for future sessions

## Status: Ready

---

## 1. Overview

### Purpose

Enable the system to learn from its own execution by automatically analyzing session logs after each run, extracting errors and inefficiencies, and persisting that knowledge in a structured file that future sessions read before starting.

### Goals

- Autonomous learning without human intervention
- Persistent knowledge across sessions (`lessons-learned.md`)
- Structured lessons: what to avoid, what to use, why
- Bounded growth (max 20 items per section)
- Automatic pruning via semantic analysis
- Integration with existing prompts (Plan, Build, Validate, Reverse)

### Non-Goals

- Machine learning or embeddings (keep it simple: bash + files)
- Manual curation required (fully autonomous)
- Quantitative metrics storage (that's for `analyze-session.sh`)
- Learning from successful patterns (focus on errors and inefficiencies)

---

## 2. Architecture

### Flow

```
loop.sh (plan/build/validate/reverse/work) completes
    ↓
Hook: if MODE not in [post-mortem, prime, bug]
    ↓
Launch: ./loop.sh post-mortem 1
    ↓
post-mortem.md prompt executes
    ↓
Read most recent log: ls -t logs/log-*.txt | head -1
    ↓
Analyze: errors, inefficiencies
    ↓
Read lessons-learned.md (or create if missing)
    ↓
Update relevant section (Plan/Build/Validate/Reverse)
    ↓
Prune if > 20 items (semantic analysis, fallback FIFO)
    ↓
Commit & push
```

### Components

```
loop.sh
├── Existing modes (plan, build, validate, reverse, work, prime, bug)
├── NEW: post-mortem mode
└── NEW: Auto-trigger hook after productive modes

.claude/commands/
├── plan.md (reads lessons-learned.md in Phase 0)
├── build.md (reads lessons-learned.md in Phase 0)
├── validate.md (reads lessons-learned.md in Phase 0)
├── reverse.md (reads lessons-learned.md in Phase 0)
└── NEW: post-mortem.md

lessons-learned.md (project root)
├── ## Plan (max 20 items)
├── ## Build (max 20 items)
├── ## Validate (max 20 items)
└── ## Reverse (max 20 items)
```

### Dependencies

| Component | Purpose | Location |
|-----------|---------|----------|
| loop.sh | Orchestrator, triggers post-mortem | Project root |
| post-mortem.md | Analysis prompt | .claude/commands/ |
| lessons-learned.md | Persistent knowledge | Project root |
| Session logs | Input for analysis | logs/ |

---

## 3. Implementation Details

### 3.1 Lesson Structure

Each lesson follows this format:

```markdown
- **Evitar:** {what not to do} | **Usar:** {what to do instead} | **Razón:** {why} ({YYYY-MM-DD})
```

Example:
```markdown
- **Evitar:** pkill para terminar procesos | **Usar:** kill <PID> | **Razón:** Entorno prohíbe pkill (2026-01-26)
- **Evitar:** Subagents para <30 specs | **Usar:** Read tool directo | **Razón:** 3x más eficiente en tokens (2026-01-26)
```

### 3.2 lessons-learned.md Structure

```markdown
# Lessons Learned

## Plan
<!-- Max 20 items. Managed by post-mortem. -->

## Build
<!-- Max 20 items. Managed by post-mortem. -->

## Validate
<!-- Max 20 items. Managed by post-mortem. -->

## Reverse
<!-- Max 20 items. Managed by post-mortem. -->
```

### 3.3 Analysis Scope

Post-mortem analyzes logs for:

**Errors:**
- Execution failures
- Rate limits hit
- Command errors
- Permission issues

**Inefficiencies:**
- Re-reading same file multiple times
- Spawning unnecessary subagents
- Repeated failed commands
- Excessive token usage patterns

### 3.4 Pruning Strategy

When a section reaches 20 items and a new one must be added:

1. **Semantic analysis (primary):** LLM evaluates which lessons are:
   - Obsolete (code/context changed)
   - Redundant (covered by another lesson)
   - Least generalizable (too specific to one case)

2. **FIFO fallback:** If semantic analysis is inconclusive, remove oldest by date.

### 3.5 Hook in loop.sh

```bash
# After main loop completes, before final summary
if [[ "$MODE" != "post-mortem" && "$MODE" != "prime" && "$MODE" != "bug" ]]; then
    log "Running post-mortem analysis..."
    ./loop.sh post-mortem 1
fi
```

### 3.6 Log Detection

Post-mortem finds the log to analyze:

```bash
LAST_LOG=$(ls -t logs/log-*.txt | head -1)
```

Simple, reliable: the most recent log is always the session that just completed.

### 3.7 Empty Analysis Handling

If post-mortem finds no errors or inefficiencies:
- Does NOT modify lessons-learned.md
- Does NOT create empty commits
- Simply completes with `<promise>COMPLETE</promise>`

---

## 4. API / Interface

### 4.1 New Mode

```bash
./loop.sh post-mortem [max_iterations]
```

- **Model:** sonnet (hardcoded, not configurable)
- **Default iterations:** 1
- **Prompt:** `.claude/commands/post-mortem.md`

### 4.2 Integration Points

**Prompts that read lessons-learned.md:**

In Phase 0 / Orient section, add:

```markdown
4. Read `lessons-learned.md` section for this mode (if exists)
```

**Files affected:**
- `.claude/commands/plan.md`
- `.claude/commands/build.md`
- `.claude/commands/validate.md`
- `.claude/commands/reverse.md`

---

## 5. Testing Strategy

### Manual Tests

1. **Basic flow:**
   - Run `./loop.sh build 1`
   - Verify post-mortem runs automatically after
   - Check `lessons-learned.md` exists

2. **Lesson extraction:**
   - Introduce deliberate error (e.g., invalid command)
   - Run build, verify post-mortem captures it

3. **Pruning:**
   - Populate Build section with 20 items
   - Run build with new error
   - Verify oldest/least relevant removed

4. **No-op case:**
   - Run clean session
   - Verify lessons-learned.md unchanged

5. **Recursion prevention:**
   - Run `./loop.sh post-mortem 1` directly
   - Verify it does NOT trigger another post-mortem

---

## 6. Acceptance Criteria

- [ ] Post-mortem mode exists and executes with sonnet
- [ ] Hook triggers automatically after plan/build/validate/reverse/work
- [ ] Hook does NOT trigger after post-mortem/prime/bug
- [ ] lessons-learned.md created on first run if missing
- [ ] Lessons follow structured format (Evitar/Usar/Razón + date)
- [ ] Each section limited to 20 items
- [ ] Pruning works (semantic + FIFO fallback)
- [ ] Clean sessions don't modify lessons-learned.md
- [ ] Plan/Build/Validate/Reverse read lessons-learned.md in Phase 0
- [ ] Commits and pushes automatically

---

## 7. Implementation Guidance

> Context for plan generator to create specific, verifiable tasks

### Impact Analysis

**Change Type:** [x] New Feature

**Affected Areas:**

Files to create:
- `.claude/commands/post-mortem.md` (new prompt)
- `lessons-learned.md` (created by post-mortem if missing)

Files to modify:
- `loop.sh` (~10 lines: model case, hook after loop)
- `.claude/commands/plan.md` (~2 lines: read lessons in Phase 0)
- `.claude/commands/build.md` (~2 lines: read lessons in Phase 0)
- `.claude/commands/validate.md` (~2 lines: read lessons in Phase 0)
- `.claude/commands/reverse.md` (~2 lines: read lessons in Phase 0)
- `README.md` (document learning system in Core Components section)

### Implementation Hints

**Core Implementation:**
- post-mortem.md: Single-phase prompt that reads log, analyzes, updates lessons-learned.md
- loop.sh hook: Simple conditional after main loop, before final log message
- Model selection: Add `post-mortem)` case returning `sonnet`

**Prompt Integration:**
- Add single line to Phase 0 of each prompt
- Conditional read: only if file exists

**Verification Strategy:**

```bash
# Verify post-mortem mode works
./loop.sh post-mortem 1

# Verify hook triggers (check log)
./loop.sh build 1
grep "Running post-mortem" logs/log-build-*.txt

# Verify lessons file structure
cat lessons-learned.md | head -20

# Verify prompt integration
grep "lessons-learned" .claude/commands/plan.md
```

---

## 8. Notes

### Why Sonnet for Post-Mortem?

- Log analysis doesn't require extended_thinking
- Structured extraction is straightforward
- Cost-effective (~$0.02 per analysis)
- Fast execution

### Why 20 Items Per Section?

- 20 items × ~50 tokens = ~1000 tokens per section
- 4 sections = ~4000 tokens total
- Negligible in 200K context window
- Enough to capture meaningful patterns without noise

### Why Semantic Pruning?

FIFO alone would discard lessons that are still relevant. The LLM can evaluate:
- "This lesson references code that no longer exists" → remove
- "This lesson duplicates another" → merge or remove
- "This lesson was very specific to one incident" → remove

### Why Root Directory for lessons-learned.md?

Consistency with other process artifacts:
- `plan.md` — task tracking
- `pending-validations.md` — validation queue
- `lessons-learned.md` — accumulated knowledge

All are project state, not agent configuration.

### Trade-off: Cost vs Learning

Every productive session adds ~$0.02-0.05 for post-mortem. Over 100 sessions = $2-5.

Value: Avoiding even one repeated mistake (wasted iteration at ~$0.50) pays for 10-25 post-mortems.

---

**Related specs:**
- `loop-orchestrator-system.md` — Modified to add hook
- `prompt-plan-system.md` — Modified to read lessons
- `prompt-build-system.md` — Modified to read lessons
- `prompt-validate-system.md` — Modified to read lessons
- `prompt-reverse-system.md` — Modified to read lessons

# Plan Generation Prompt System

> Intelligent plan generator that reconciles multiple sources of truth, performs gap analysis, and creates context-aware implementation plans

## Status: Ready

---

## 1. Overview

### Purpose

Transform specifications into actionable, verifiable implementation plans through 5-phase workflow with strategic analysis and intelligent task grouping.

### Goals

- Multi-source truth reconciliation (git log > README)
- Gap analysis (specs vs actual code)
- Impact analysis (identify affected files)
- Strategic task grouping (context budget aware)
- Plan lifecycle management (0% / 1-79% / 80-100%)
- Specs describe WHAT, plan describes HOW

### Non-Goals

- Implementing code (that's build mode)
- Modifying specs (specs are immutable)
- Using AGENTS.md or external docs (self-contained)
- Requiring CHANGELOG.md (git log sufficient)
- Complex metadata processing

---

## 2. Architecture

### 5-Phase Workflow

```
Phase 0: Orient
    ↓ (study specs, codebase structure)
Phase 1: Gather Context
    ↓ (git log + README reconciliation)
Phase 2: Read Selected Specs
    ↓ (only truly pending specs)
Phase 3: Task Expansion
    ↓ (impact analysis via grep/search)
Phase 4: Strategic Analysis
    ↓ (<extended_thinking> with grouping)
Phase 5: Generate Plan
    ↓ (plan.md with lifecycle management)
```

### Data Flow

```
specs/README.md (PIN)
    ↓
git log (technical truth)
    ↓
Reconciliation
    ↓ (determine INCLUDED_SPECS)
Read only included specs
    ↓
Impact Analysis
    ↓ (grep search for affected files)
Strategic Analysis
    ↓ (<extended_thinking>)
    ├─ Dependency analysis
    ├─ Context budget estimation
    ├─ Smart task grouping
    └─ Phase optimization
    ↓
plan.md
    ├─ Logical phases
    ├─ Specific, verifiable tasks
    ├─ Citations preserved
    └─ Only pending [ ] tasks
```

---

## 3. Key Features

### 3.1 Multi-Source Reconciliation

**Problem:** Specs may be marked pending but actually implemented.

**Solution:** Check multiple sources with precedence:

```
Precedence: git log > README > spec Status
```

**Decision matrix:**

| git log | README | Action |
|---------|--------|--------|
| "feat: X complete" | ⏳ | SKIP (trust git) |
| No evidence | ⏳ | INCLUDE (truly pending) |
| No evidence | ✅ | VERIFY (might be manual update) |

**Benefit:** Avoids regenerating already-done work.

### 3.2 Impact Analysis

**Problem:** Specs say "update X" but don't specify all affected files.

**Solution:** Search codebase for patterns:

```bash
grep -r "function_name\|class_name" src/
grep -r "config_key" .
```

**Output:** List of affected files with line numbers and occurrence counts.

**Benefit:** Tasks become specific ("Update 5 files: X, Y, Z...") not generic.

### 3.3 Strategic Task Grouping

**Problem:** Too many small tasks OR too few giant tasks.

**Solution:** Context-aware grouping with `<extended_thinking>`:

**Group ONLY when:**
- ✅ Same file AND combined < 500 lines
- ✅ Related files AND combined < 1500 lines
- ✅ Similar verification pattern

**Do NOT group if:**
- ❌ Would require reading > 3 files
- ❌ Files are > 500 lines each
- ❌ Different verification strategies

**Benefit:** Tasks sized for single-iteration completion.

### 3.4 Plan Lifecycle Management

**Problem:** When plan.md exists, unclear what to do.

**Solution:** Completion-ratio-based decisions:

| Ratio | Action | Behavior |
|-------|--------|----------|
| 0% | UPDATE | Keep existing [ ], add new |
| 1-79% | CLEAN & UPDATE | Remove [x], keep [ ], add new |
| 80-100% | REGENERATE | Commit current, fresh start |

**Benefit:** Clear, deterministic behavior.

### 3.5 Subagent Strategy

**Inline guidance:**

- **< 30 specs**: Read directly (no subagents)
- **30-100 specs**: 2-5 subagents for categorization
- **> 100 specs**: Up to 15-30 subagents strategically

**Anti-patterns flagged:**
- ❌ One subagent per spec (wasteful)
- ❌ General-purpose subagent for known file

---

## 4. Prompt Structure

### Section 1: Phase 0 (Orient)

```markdown
Study specs/README.md
Study existing codebase
Note patterns and conventions
```

Simple orientation, no heavy lifting.

### Section 2: Subagent Strategy

Inline rules (no AGENTS.md needed):
- Decision rule: 20K overhead per subagent
- Math examples for each scenario
- Anti-patterns listed

### Section 3: Phase 1 (Gather Context)

```markdown
Step 1: Read specs/README.md
  → Extract ✅ ⏳ 📋 statuses

Step 2: Check git history
  → git log patterns

Step 3: Reconcile
  → Decision matrix (git > README)
  → Output: INCLUDED_SPECS[]
```

Multi-source truth reconciliation.

### Section 4: Phase 2 (Read Specs)

```markdown
Read ONLY INCLUDED_SPECS from Phase 1
Extract requirements, goals, architecture
Note acceptance criteria
```

Focused reading, not exhaustive.

### Section 5: Phase 3 (Task Expansion)

```markdown
For each requirement:
  - Search codebase (grep patterns)
  - Identify affected files
  - Count occurrences
  - Document findings
```

Impact analysis for specificity.

### Section 6: Phase 4 (Strategic Analysis)

```markdown
<extended_thinking> required

4.1 Dependency Analysis
4.2 Context Budget Estimation
4.3 Smart Task Grouping
4.4 Task Sizing Guidelines
4.5 Preserve Traceability
4.6 Phase Structure Optimization
```

The intelligence layer. Uses Opus for deep reasoning.

### Section 7: Phase 5 (Generate Plan)

```markdown
Step 1: Check if plan.md exists
  → Apply lifecycle rules

Step 2: Write plan.md
  → Logical phases
  → Specific tasks with:
    - Done when
    - Verify
    - Citations
    - [Grouped] notes if applicable

Step 3: Validate plan
  → No [x] tasks
  → All citations present
  → Phases ordered

Step 4: Commit
```

Output generation with validation.

### Section 8: Guardrails

Numbered 9s system:
- 99999 through 999999999999
- Priorities: no implementation, trust reconciliation, preserve citations, etc.

### Section 9: Completion Signal

```markdown
<promise>COMPLETE</promise>
```

Signals orchestrator to stop.

---

## 5. Example Output

### Generated plan.md

```markdown
# Implementation Plan

Generated: 2026-01-23
Specs analyzed: 3

## Phase 1: Core Infrastructure

- [ ] Implement authentication controller (file: `src/auth.js`)
      Done when: Controller has login/logout methods with JWT
      Verify: grep -q "login.*logout" src/auth.js && grep -q "jwt" src/auth.js
      (cite: specs/auth-system.md requirements)

- [ ] Add JWT middleware to API routes (2 files: routes.js, middleware.js)
      Done when: All protected routes use auth middleware
      Verify: grep -c "authMiddleware" src/routes.js returns 5
      (cite: specs/auth-system.md requirements)
      [Grouped: Sequential dependency, related files, ~200 lines context]

## Phase 2: Testing

- [ ] Add unit tests for auth controller (file: `tests/auth.test.js`)
      Done when: Tests cover login/logout/token validation
      Verify: npm test -- auth.test.js passes
      (cite: specs/auth-system.md testing requirements)
```

**Characteristics:**
- Specific file paths
- Concrete "Done when" criteria
- Executable "Verify" commands
- Citations to source specs
- Grouped tasks explained
- Logical phases (not spec boundaries)

---

## 6. Testing Strategy

### Validation Tests

```bash
# Test reconciliation logic
echo "✅ Complete" > specs/README.md  # Mark spec done
./loop.sh plan 1
grep -q "auth-system" plan.md && fail "Should skip completed spec"

# Test plan lifecycle (80% rule)
# Create plan with 80% [x] tasks
./loop.sh plan 1
grep -q "Regenerated" plan.md || fail "Should regenerate"
```

### Context Efficiency Tests

```bash
# Test subagent decision
# Create 5 specs
./loop.sh plan 1
# Check logs - should NOT spawn subagents
grep -i "subagent" logs/*.txt && fail "Should use direct reads"

# Create 50 specs
./loop.sh plan 1
# Check logs - should spawn 2-5 subagents
```

### Output Validation

```bash
# Verify plan.md format
grep -q "^## Phase" plan.md || fail "Missing phases"
grep -q "Done when:" plan.md || fail "Missing done when"
grep -q "Verify:" plan.md || fail "Missing verify"
grep -q "cite:" plan.md || fail "Missing citations"

# Verify no [x] tasks
grep -q "- \[x\]" plan.md && fail "Should have no completed tasks"
```

---

## 7. Implementation Guidance

### Prompt File Location

```
prompts/plan.md
```

Implemented at: `prompts/plan.md`

### Total Size

~380 lines markdown

### Model Requirement

**Opus required** for Phase 4 (`<extended_thinking>`)

Loop.sh automatically selects opus for plan mode.

### Expected Execution Time

- Small project (< 10 specs): 2-5 minutes
- Medium project (10-30 specs): 5-10 minutes
- Large project (> 30 specs): 10-20 minutes

Depends on spec count and codebase size.

---

## 8. Key Design Decisions

### Why No CHANGELOG.md?

**Reason:** Agent-maintained, redundant with git log

**Benefits:**
- Simpler reconciliation (2 sources not 3)
- Faster execution (no file to scan)
- Git log is sufficient technical truth

### Why DELETE Completed Tasks?

**Reason:** Plan shows only what's LEFT

**Benefits:**
- Cleaner plan.md (focused)
- Stop condition trivial (no [ ] tasks)
- History in git (where it belongs)

### Why 5 Phases Not 3?

**Reason:** Separation of concerns

**Phases:**
1. Context gathering (reconciliation)
2. Reading (focused, not exhaustive)
3. Expansion (impact analysis)
4. Analysis (intelligence)
5. Generation (output)

Each phase has clear input/output.

### Why Extended Thinking?

**Reason:** Task grouping requires reasoning

**Without it:**
- Too many tiny tasks OR too few giant tasks
- Poor context budget management
- Missed optimization opportunities

**With it:**
- Intelligently sized tasks
- Strategic grouping
- Dependencies identified

---

## 9. Notes

### Specs Without Checklists

**Key insight:** Specs describe WHAT (requirements), plan describes HOW (tasks).

**Flow:**
```
Spec: "System must support JWT authentication"
    ↓ (plan generator reasons)
Plan: "Implement auth controller (src/auth.js)
       Add JWT middleware (src/middleware/auth.js)
       Update routes to use middleware (src/routes.js)"
```

Plan generator creates specific, actionable tasks from high-level requirements.

### When to Regenerate

**80% rule:** If plan is 80%+ complete, regenerate fresh.

**Rationale:**
- Old plan likely stale
- Remaining 20% may be obsolete
- Better to fresh-analyze specs

**Edge case:** If those 20% tasks are still valid, they'll appear in new plan.

---

**Implementation:** See `prompts/plan.md`

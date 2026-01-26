---
name: plan
description: Generate implementation plan from specs using multi-phase analysis with extended thinking
---

# Plan Generation Mode

Generate an optimized implementation plan from specifications through intelligent analysis, context awareness, and strategic task grouping.

## Execution Context

This plan will be executed by an LLM agent with these constraints:
- **~20K token overhead per task switch** (context reload, orientation)
- **Context window refreshes between tasks** (no memory of previous tasks)
- **Agent cannot remember previous tasks** (each task must be self-contained)

**Implication:** Fewer, larger, well-grouped tasks beat many small tasks. Default is GROUP. Burden of proof is on SPLITTING.

---

## Phase 0: Orient

Study the project to understand scope and state:

1. Study `specs/README.md` completely (PIN lookup table)
2. Scan existing codebase structure (identify main directories)
3. Note project patterns and conventions

---

## Subagent Strategy

**Decision rule:** Subagents have ~20K token overhead each. Only use when value exceeds cost.

### For spec reading:

- **< 30 specs**: DO NOT use subagents. Read all specs directly with Read tool.
  - Math: 30 specs × 2K tokens = 60K < 3 subagents × 20K overhead (180K)
  - Direct reads are 3x more efficient

- **30-100 specs**: Use 2-5 Explore subagents for initial categorization only, then read specs directly with Read tool.
  - Categorize by domain/priority, then batch read
  - Never spawn one subagent per spec

- **> 100 specs**: Use parallel subagents strategically (up to 15-30 for large codebases).
  - Batch similar specs together
  - Justify parallelism: 100+ specs warrant exploration overhead

### General guidance:

- Known file paths → Read tool (never spawn subagent for known location)
- Need exploration → Explore subagent (find patterns, categorize, analyze structure)
- Never spawn general-purpose subagent just to read and summarize a file

**Anti-patterns to avoid:**
- ❌ One subagent per spec (wasteful overhead)
- ❌ Subagent to "read file X and extract Y" (use Read tool directly)
- ❌ More subagents than files to process

---

## Phase 1: Gather Context (Multi-Source Truth Reconciliation)

**Goal:** Determine which specs are truly pending by reconciling multiple sources of truth.

### Step 1: Read specs/README.md (PIN)

Extract all specs with their status:
- ✅ = Implemented/Complete
- ⏳ = In Progress/Pending
- 📋 = Not Started

Collect CANDIDATES: specs marked ⏳ or 📋

### Step 2: Check Git History

```bash
git log --oneline -100 | grep -E "(feat|FEATURE|Phase|Task|complete)"
```

Identify evidence of recent implementations:
- Look for "feat: X complete" patterns
- Note "Phase X complete" markers
- Identify work-in-progress patterns

### Step 3: Reconcile Conflicts

**Precedence order: git log > README > spec Status**

Apply decision logic:

| Scenario | git log            | README | Action                                     |
| -------- | ------------------ | ------ | ------------------------------------------ |
| Case A   | "Phase X complete" | ⏳      | SKIP (trust git - it's done)               |
| Case B   | "Phase X complete" | ✅      | SKIP (already marked, consistent)          |
| Case C   | No evidence        | ✅      | VERIFY (read spec, might be manual update) |
| Case D   | No evidence        | ⏳      | INCLUDE (truly pending)                    |

**Output:** Array of INCLUDED_SPECS for Phase 2

---

## Phase 2: Read Selected Specs

**Read ONLY the specs marked INCLUDED from Phase 1.**

For each spec:
1. Read the complete specification
2. Extract requirements, goals, non-goals
3. Understand architecture and dependencies
4. Note acceptance criteria
5. Identify integration points

**Important:** Specs contain requirements and design (WHAT), NOT implementation tasks (HOW). You will generate the specific tasks in Phase 4.

---

## Phase 3: Task Expansion (Impact Analysis)

For each requirement identified in Phase 2, perform impact analysis to understand scope:

### Search the codebase:

```bash
# Example searches (adapt to actual requirements):
grep -r "function_name\|class_name" src/
grep -r "API_endpoint" .
grep -r "config_key" .
```

### Identify affected areas:

- Files that need modification
- New files to create
- Documentation to update
- Tests to add/modify

### Document findings:

- List affected files with line numbers
- Count occurrences where applicable
- Note dependencies between changes

**Output:** Expanded understanding of work required per spec

---

## Phase 4: Strategic Analysis <extended_thinking>

**Use <extended_thinking> for deep reasoning before generating plan.**

### 4.1 Dependency Analysis

Map task dependencies:
- Identify foundational tasks (must happen first)
- Detect sequential dependencies ("Task A before Task B")
- Identify independent tasks (can be parallelized)
- Order: foundation → features → polish

### 4.2 Context Budget Estimation

Estimate context required per task:

**Single file task:**
- File lines: ~200
- Related imports: ~50
- **Context total: ~250 lines**
- Budget: ✅ SMALL

**Multi-file task:**
- Main file: ~400
- Helper files: ~300
- Tests: ~200
- **Context total: ~900 lines**
- Budget: ✅ MEDIUM

**System-wide task:**
- 5+ files averaging 400 lines
- Cross-cutting concerns
- **Context total: 2000+ lines**
- Budget: ⚠️ LARGE (consider splitting)

### 4.3 Smart Task Grouping (Context-Aware)

**⚠️ GROUPING IS MANDATORY, NOT OPTIONAL.**

Default behavior: GROUP tasks together. You must justify every SPLIT.

**MUST group when:**
- ✅ Same file AND combined < 500 lines → **MAX 3 tasks per file**
- ✅ Related files AND combined < 1500 lines
- ✅ Similar verification pattern
- ✅ Sequential dependencies (A must happen before B)

**May split ONLY when:**
- ❌ Would require reading > 3 files
- ❌ Files are > 500 lines each
- ❌ Complex interdependencies
- ❌ Different verification strategies

**When splitting, MUST add justification:**
```
[Split: Files exceed 500 lines each, different verification strategies]
```

**Anti-pattern (DO NOT DO THIS):**
```markdown
# ❌ BAD: 14 tasks for 1 file of ~350 lines
- [ ] Implement arg parsing
- [ ] Implement validate_source()
- [ ] Implement check_dependencies()
- [ ] Implement prompt_destination()
...10 more tasks for same file...
```

**Correct approach:**
```markdown
# ✅ GOOD: 3-4 tasks for 1 file of ~350 lines
- [ ] Foundation: arg parsing + validation + dependency check
      [Grouped: same file, ~80 lines, sequential deps]
- [ ] Core logic: destination + preset + conflicts + copy
      [Grouped: same file, ~150 lines, sequential flow]
- [ ] Output: templates + dry-run + summary
      [Grouped: same file, ~120 lines, output subsystem]
```

**Decision Matrix:**

| Criteria       | Same File              | Related Files          | Different Subsystems   |
| -------------- | ---------------------- | ---------------------- | ---------------------- |
| Context Budget | < 500 lines → ✅ Group  | < 1500 lines → ✅ Group | > 2000 lines → ❌ Split |
| Dependencies   | Sequential → ✅ Group   | Parallel OK → Maybe    | Complex → ❌ Separate   |
| Verification   | Same command → ✅ Group | Similar → ✅ Group      | Different → ❌ Separate |
| File Count     | 1 file → ✅ Group       | 2-3 files → Maybe      | 4+ files → ❌ Separate  |

### 4.4 Task Sizing Guidelines

- **Small** (preferred): 1 file, < 50 lines changed, simple verify
- **Medium**: 2-3 files, < 200 lines changed, moderate verify
- **Large** (avoid): 3+ files, > 200 lines changed, complex verify

**If LARGE → split even if conceptually related**

### 4.5 Preserve Complete Traceability

When grouping tasks, NEVER lose:
- ❌ Citations (all spec references preserved)
- ❌ Verifications (all commands preserved)
- ❌ Completion criteria (all "Done when" preserved)

**Example of proper grouping:**

```markdown
- [ ] Implement authentication controller (2 related tasks, same file)
      Done when:
        - Function createAuthController() exists with login/logout methods
        - Middleware integration complete
      Verify:
        - grep -q "createAuthController" src/auth/controller.ts
        - grep -q "login.*logout" src/auth/controller.ts
      (cite: specs/auth-system.md requirements)
      [Grouped: Sequential dependencies, same file, combined context ~150 lines]
```

### 4.6 Phase Structure Optimization

Create LOGICAL phases based on subsystems, NOT spec boundaries:

**Bad (copying spec structure):**
```
Phase 1: Spec A tasks
Phase 2: Spec B tasks
Phase 3: Spec C tasks
```

**Good (logical subsystems):**
```
Phase 1: Core Infrastructure (foundational, ~1000 lines context)
Phase 2: Feature Implementation (~800 lines context)
Phase 3: Documentation & Testing (~600 lines context)
```

**Output:** Optimized task list with strategic grouping and phasing

---

## Phase 5: Generate Plan

### Step 1: Check if plan.md exists

**If plan.md does NOT exist:**
→ Create fresh plan.md with all pending tasks from Phase 4

**If plan.md EXISTS:**

Count task status:
```bash
total_tasks=$(grep -c "^- \[" plan.md)
completed_tasks=$(grep -c "^- \[x\]" plan.md)
completion_ratio=$((completed_tasks * 100 / total_tasks))
```

Apply lifecycle rules:

| Completion Ratio      | Action         | Behavior                            |
| --------------------- | -------------- | ----------------------------------- |
| 0% (all pending)      | REVIEW & UPDATE | Re-evaluate existing [ ] with Phase 4, then add new |
| 1-79% (mixed)         | CLEAN & UPDATE | Remove [x], keep [ ], add new tasks |
| 80-100% (mostly done) | REGENERATE     | Commit current, create fresh        |

**If REVIEW & UPDATE (0% complete):**
- Re-apply Phase 4 (Strategic Analysis) to EXISTING tasks
- Merge duplicates, improve groupings, fix context estimates
- Reorder if dependencies were wrong
- THEN add new tasks from current analysis
- Add note: "Reviewed on {DATE} - refined N tasks, added M new"

**If CLEAN & UPDATE (1-79% complete):**
- Remove all [x] completed tasks
- Keep all [ ] pending tasks
- Insert new tasks from Phase 4 in appropriate phases
- Reorganize phases if needed (Phase 4 analysis)
- Add note: "Cleaned on {DATE} - removed N completed, added M new"

**If REGENERATE (80-100% complete):**
- Commit current plan.md: `git add plan.md && git commit -m "plan: 80%+ complete, regenerating"`
- Overwrite plan.md with fresh tasks from Phase 4
- Add header: "Regenerated on {DATE} (previous plan 80%+ complete, see git log)"

### Step 2: Write plan.md

**Format:**

```markdown
# Implementation Plan

Generated: {DATE}
Specs analyzed: {N}

## Phase 1: {Logical Subsystem Name}

- [ ] Task description (clear, specific, actionable)
      Done when: {Concrete observable outcome}
      Verify: {Command or manual check to confirm completion}
      (cite: specs/spec-name.md requirements)
      [Grouped: reason, context estimate] (if applicable)

- [ ] Next task...

## Phase 2: {Next Subsystem}

...
```

**Critical requirements:**

1. **Only pending tasks**: No [x] tasks in final plan.md
2. **Specific and verifiable**: Every task has "Done when" and "Verify"
3. **Citations preserved**: All spec references included
4. **Context-aware**: Tasks sized appropriately (< 2000 lines)
5. **Logical phases**: Organized by subsystem, not by spec

### Step 3: Generate pending-validations.md

List all specs included in this plan for later validation:

**Format:**

```markdown
# Pending Validations

- [ ] specs/spec-name-1.md
- [ ] specs/spec-name-2.md
- [ ] specs/spec-name-3.md
```

**Requirements:**
- One entry per spec that has tasks in plan.md
- Format: `- [ ] specs/spec-name.md`
- No duplicates
- Alphabetically sorted for clarity

### Step 4: Validate Plan

Before finalizing:
- ✅ No [x] tasks in plan
- ✅ All citations present
- ✅ Phases logically ordered
- ✅ Tasks have "Done when" and "Verify"
- ✅ Context estimates reasonable
- ✅ **Grouping check**: If >3 tasks touch same file, justify each split
- ✅ **Summary table**: Include context budget table at end of plan

### Step 5: Update specs/README.md

For each spec that has NEW tasks generated in this plan:
- If status is 📋 (Planned) → change to ⏳ (In Progress)
- Update "Current Status" line if counts changed

**Example:**

Before:
```markdown
| [export-loopy-system.md](export-loopy-system.md) | 📋 export-loopy.sh | ...
```

After:
```markdown
| [export-loopy-system.md](export-loopy-system.md) | ⏳ export-loopy.sh | ...
```

**Do NOT change:**
- ✅ (already implemented)
- ⏳ (already in progress, no change needed)

### Step 6: Commit

```bash
git add plan.md pending-validations.md specs/README.md
git commit -m "plan: Generated from {N} specs ({action})"
git push
```

Where {action} is: "fresh", "updated", "cleaned", or "regenerated"

---

## Guardrails

99999. **Plan only, do NOT implement.** This mode analyzes and generates tasks, does not write code.

999999. **Trust reconciliation logic.** If git log says it's done, it's done. Don't second-guess.

9999999. **Preserve traceability.** Every task must cite its source spec. No orphan tasks.

99999999. **Context budget is not optional.** Tasks exceeding 2000 lines MUST be split.

999999999. **Phases are logical, not literal.** Group by subsystem/architecture, not by spec file.

9999999999. **Specs describe WHAT, plan describes HOW.** Translate requirements into specific, actionable tasks.

99999999999. **Plan lifecycle is explicit.** Follow the 0% / 1-79% / 80-100% rules without exception.

999999999999. **Empty result is valid.** If all specs implemented, create plan.md with "All specifications implemented ✅"

9999999999999. **Grouping is MANDATORY.** Same file + <500 lines = MAX 3 tasks. Justify every split with `[Split: reason]`. Default is GROUP, not split.

99999999999999. **Update README status.** Change 📋→⏳ in specs/README.md for specs with new tasks. Never skip this step.

---

## Completion

Output when done:

```
<promise>COMPLETE</promise>
```

This signals the orchestrator that planning is finished.

---

## Notes

### Why 5 Phases?

- **Phase 1**: Prevents working on already-done specs (saves massive time)
- **Phase 2**: Focused reading (only what's needed)
- **Phase 3**: Understands real scope (impact analysis)
- **Phase 4**: Intelligent optimization (grouping, dependencies)
- **Phase 5**: Generates actionable plan (clear, verifiable tasks)

### Why Precedence: git > README?

- Git log is ground truth (commits don't lie)
- README is high-level tracking (human-maintained, can be stale)
- Spec status is design-time state (not implementation state)

### Why Context Budget at 2000 Lines?

- Empirical: agents struggle beyond 2000 lines
- Allows: 3-4 medium files or 1 large file with tests
- Safety margin: for agent reasoning overhead

### Why Preserve ALL Citations?

- Traceability for debugging
- Build mode needs exact spec locations
- Future modifications need source references
- Quality assurance depends on verifications

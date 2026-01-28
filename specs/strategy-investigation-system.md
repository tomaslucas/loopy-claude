# Strategy Investigation System

> Document implementation strategies before task generation to enable human review and informed decision-making

## Status: Ready

---

## 1. Overview

### Purpose

Ensure implementation decisions are investigated, documented, and reviewable by humans before autonomous execution begins. This enables the "human on the loop" supervision model where humans validate strategic decisions without participating in every step.

### Goals

- Investigate existing code patterns before proposing solutions
- Evaluate 2-3 implementation approaches with trade-offs
- Document selected strategy permanently in specs
- Enable human review window between /plan and /build
- Provide context for /bug fixes beyond trivial corrections

### Non-Goals

- Replacing Feature Designer for new feature design (complementary)
- Requiring human approval for every task (only strategic decisions)
- Slowing down trivial bug fixes (lightweight version for /bug)
- Making the build loop interactive (remains autonomous)

---

## 2. Human Participation Model

### "Human ON the Loop" (Not IN the Loop)

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   ┌──────────────┐     ┌──────────┐     ┌──────────────┐       │
│   │   Feature    │────▶│  /plan   │────▶│    HUMAN     │──┐    │
│   │   Designer   │     │          │     │   REVIEWS    │  │    │
│   └──────────────┘     └──────────┘     └──────────────┘  │    │
│          ▲                                    │           │    │
│          │                             OK ────┘    Adjust │    │
│          │                             │                  │    │
│   ┌──────┴────────────────────────────────────────────────┘    │
│   │                                    ▼                       │
│   │   ┌────────────────────────────────────────────┐           │
│   │   │           AUTONOMOUS LOOP                  │           │
│   │   │      build → validate → (repeat)           │           │
│   │   └────────────────────────────────────────────┘           │
│   │                                    │                       │
│   │                          Fail 3x or Bug                    │
│   │                                    ▼                       │
│   │   ┌──────────┐     ┌───────────────────────┐               │
│   └───│   /bug   │◀────│  Human reports +      │               │
│       │          │     │  provides context     │               │
│       └──────────┘     └───────────────────────┘               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Phase Responsibilities

| Phase | Human Role | Mechanism |
|-------|------------|-----------|
| **Design** (Feature Designer) | Active participation | AskUserQuestion loops |
| **Plan** | Review & approve | Human reviews plan.md + strategies BEFORE build |
| **Build/Validate** | None (autonomous) | No intervention unless escalation (3 failures) |
| **Bug** | Provide context | Human reports bug, may redirect proposed fix |

### Key Insight

The human's window for intervention is **between /plan and /build**, not during execution. Once approved, the loop runs autonomously until completion or escalation.

---

## 3. Strategy Investigation Workflow

### 3.1 When to Investigate

| Component | Trigger | Depth |
|-----------|---------|-------|
| **Feature Designer** | Always (during Phase 1) | Full: 3 approaches, detailed trade-offs |
| **/plan** | Specs without "Selected Implementation Strategy" section | Full: 3 approaches, update spec |
| **/bug** | Non-trivial bugs (multi-file, architectural) | Light: 2-3 approaches, document in task |

### 3.2 Investigation Steps

**Step 1: Pattern Analysis**
```bash
# Search for similar solutions in codebase
grep -r "similar_pattern" src/
grep -r "related_function" .
```
- How have we solved similar problems?
- What patterns does this codebase use?
- Are there conventions to follow?

**Step 2: Library Verification**
```bash
# Check existing dependencies
cat package.json | grep "library"  # or equivalent
grep -r "import.*library" src/
```
- Do our dependencies already solve this?
- Are we about to reinvent the wheel?
- What's the learning curve vs building custom?

**Step 3: Approach Evaluation**

For each of 2-3 approaches, analyze:

| Criterion | Questions |
|-----------|-----------|
| **Complexity** | Lines of code? New dependencies? Learning curve? |
| **Performance** | Time/space complexity? Bottlenecks? |
| **Security** | Attack surface? Data exposure? Validation needed? |
| **Maintainability** | Testable? Debuggable? Future-proof? |
| **Consistency** | Matches existing patterns? Creates split-brain? |

**Step 4: Selection & Justification**

Choose best approach with clear reasoning:
- Why this approach over others?
- What trade-offs are we accepting?
- What risks remain?

### 3.3 Output Format

Document in spec as new section:

```markdown
## Selected Implementation Strategy

**Investigation date:** {DATE}

### Pattern Analysis
- Similar pattern found in: `path/to/file.ext`
- Project convention: {description}

### Libraries Evaluated
- {library}: {verdict - use/don't use/already in use}

### Approaches Considered

**Approach A: {name}**
- Pros: {list}
- Cons: {list}
- Complexity: {low/medium/high}

**Approach B: {name}**
- Pros: {list}
- Cons: {list}
- Complexity: {low/medium/high}

**Approach C: {name}** (if applicable)
- Pros: {list}
- Cons: {list}
- Complexity: {low/medium/high}

### Decision
**Selected:** Approach {X}

**Justification:** {why this approach is best for our context}

**Accepted trade-offs:** {what we're consciously sacrificing}
```

---

## 4. Component Integration

### 4.1 Feature Designer

**Location:** Phase 1 (Iterative Requirements), before Coherence Validation

**Behavior:**
- During deep dive per topic, evaluate implementation approaches
- Use AskUserQuestion to present options with trade-offs
- Document selected strategy in generated spec (Phase 3)

**Output:** Spec includes "Selected Implementation Strategy" section

### 4.2 /plan (Phase 3b: Strategy Investigation)

**Location:** Between Phase 3 (Impact Analysis) and Phase 4 (Strategic Analysis)

**Behavior:**
```
For each INCLUDED_SPEC:
  IF spec has "Selected Implementation Strategy":
    → Read and use for task generation
  ELSE (legacy spec):
    → Run Strategy Investigation workflow
    → Update spec with new section
    → Then generate tasks
```

**Output:** All specs have strategy section; tasks align with documented strategy

### 4.3 /build

**Location:** Step 2 (Read spec)

**Behavior:**
- Read spec including strategy section
- Follow documented approach
- If implementation diverges from strategy, note in commit message

**Output:** Code follows documented strategy

### 4.4 /validate

**Location:** New verification in two-pass check

**Behavior:**
- Verify implementation follows documented strategy
- Check for divergence between strategy and actual code
- If divergence found: flag as potential issue (not automatic fail)

**Output:** Validation report includes strategy compliance check

### 4.5 /audit

**Location:** Step 3 (Cross-cutting analysis)

**Behavior:**
- Detect specs marked ✅ that lack "Selected Implementation Strategy" section
- Report as "Incomplete: missing implementation strategy"
- Severity: Low (documentation gap, not functional issue)

**Output:** Audit report lists specs without strategy documentation

### 4.6 /bug

**Location:** Step 4 (Strategic Analysis), for non-trivial bugs only

**Behavior:**
```
IF bug is trivial (single file, < 50 lines, clear fix):
  → Skip strategy investigation
  → Create fix task directly

ELSE (non-trivial):
  → Run lightweight investigation (2-3 approaches)
  → Document decision in task description (not in spec)
  → Format:
    - [ ] Fix: {description}
          Strategy: {brief approach selected}
          Alternatives considered: {list}
          (cite: specs/X.md)
```

**Output:** Non-trivial bug fixes include strategy context in task

### 4.7 /reconcile

**Location:** New divergence type

**Behavior:**
- Handle case: "Strategy says X, code does Y"
- Present options via AskUserQuestion:
  1. Update code to match strategy
  2. Update strategy to match code (with justification)
  3. Document as intentional divergence

**Output:** Reconciled strategy and code, with audit trail

---

## 5. Testing Strategy

### Unit Tests

```bash
# Test strategy section detection
echo "## Selected Implementation Strategy" > test-spec.md
grep -q "Selected Implementation Strategy" test-spec.md && echo "PASS"

# Test legacy spec detection (no section)
grep -q "Selected Implementation Strategy" old-spec.md || echo "Legacy detected"
```

### Integration Tests

```bash
# Test /plan generates strategy for legacy spec
./loop.sh plan 1
grep -q "Selected Implementation Strategy" specs/legacy-spec.md || fail

# Test /audit detects missing strategy
./loop.sh audit
grep -q "missing implementation strategy" audits/audit-*.md
```

### Manual Verification

1. Run Feature Designer for new feature
2. Verify generated spec includes strategy section
3. Run /plan, verify it reads existing strategy
4. Run /build, verify code follows strategy
5. Run /validate, verify strategy compliance check

---

## 6. Acceptance Criteria

- [ ] prime.md documents "human on the loop" model
- [ ] Feature Designer generates specs with strategy section
- [ ] /plan has Phase 3b for strategy investigation
- [ ] /plan updates legacy specs with strategy section
- [ ] /build reads strategy as part of spec reading
- [ ] /validate checks strategy compliance
- [ ] /audit detects specs without strategy section
- [ ] /bug includes lightweight strategy for non-trivial fixes
- [ ] /reconcile handles strategy vs code divergence
- [ ] spec-template.md includes strategy section placeholder

---

## 7. Implementation Guidance

### Impact Analysis

**Change Type:** [x] Enhancement

**Affected Areas:**

Files to modify:
- `.claude/commands/plan.md` - Add Phase 3b
- `.claude/commands/build.md` - Add strategy reading to Step 2
- `.claude/commands/validate.md` - Add strategy compliance check
- `.claude/commands/audit.md` - Add missing strategy detection
- `.claude/commands/bug.md` - Add lightweight strategy for non-trivial
- `.claude/commands/reconcile.md` - Add strategy divergence handling
- `.claude/commands/prime.md` - Document human participation model (DONE)
- `.claude/skills/feature-designer/SKILL.md` - Add strategy generation
- `.claude/skills/feature-designer/resources/spec-template.md` - Add section

Specs to update:
- `specs/prompt-plan-system.md` - Document Phase 3b
- `specs/prompt-build-system.md` - Document strategy reading
- `specs/prompt-validate-system.md` - Document strategy check
- `specs/audit-system.md` - Document missing strategy detection
- `specs/reconcile-system.md` - Document strategy divergence
- `specs/feature-designer-skill.md` - Document strategy generation

### Verification Strategy

```bash
# Verify all commands updated
for cmd in plan build validate audit bug reconcile; do
  grep -q -i "strateg" .claude/commands/$cmd.md || echo "Missing: $cmd"
done

# Verify spec template updated
grep -q "Selected Implementation Strategy" .claude/skills/feature-designer/resources/spec-template.md

# Verify specs updated
grep -q "strategy-investigation" specs/README.md
```

---

## 8. Notes

### Why Document Strategy in Specs?

**Permanence:** Specs are the source of truth. Strategy decisions are design decisions.

**Reviewability:** Human can review strategy before build starts.

**Traceability:** Future developers understand WHY, not just WHAT.

**Consistency:** Build mode follows documented approach, not ad-hoc decisions.

### Why Lightweight for /bug?

**Speed:** Most bugs are trivial; full investigation is overkill.

**Context:** Bug reporter often provides direction.

**Task-level:** Bug fixes don't warrant permanent spec changes (usually).

### Trade-offs Accepted

- **More upfront work:** Investigation takes time before tasks are generated
- **Spec updates:** Legacy specs get modified (adds maintenance)
- **Judgment required:** Distinguishing trivial vs non-trivial bugs is subjective

**Benefit:** Better decisions, human oversight, documented rationale.

---

**Created:** 2026-01-28
**Context:** Discussion in thread T-019c060f-70e8-76da-baed-8fc828ddb7fe

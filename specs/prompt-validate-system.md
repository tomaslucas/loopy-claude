# Validate Mode Prompt System

> Post-implementation validation that compares code behavior against specifications and creates corrective tasks when divergence is detected

## Status: Ready

---

## 1. Overview

### Purpose

Validate that implemented code matches specifications by comparing actual behavior against spec requirements. When divergence is detected, create corrective tasks in plan.md to realign implementation with spec (spec is source of truth).

### Goals

- Validate one spec per iteration from pending-validations.md
- Two-pass verification: mechanical checklist + semantic inference
- Parallel execution via Tasks (sonnet for checklist, opus for inference)
- Deduplicate findings before creating corrective tasks
- Only remove spec from pending when validation passes clean
- Maximum 3 validation attempts per spec (prevent infinite loops)
- Create specific, actionable tasks in plan.md when divergence found

### Non-Goals

- Modifying specs (specs are immutable source of truth)
- Implementing fixes (that's build mode)
- Validating multiple specs per iteration
- Skipping either verification pass
- Running without pending-validations.md

---

## 2. Architecture

### Flow

```
User invokes ./loop.sh validate
    ↓
Read pending-validations.md
    ↓
Pick first pending spec (marked - [ ])
    ↓
Read spec completely
    ↓
Identify implemented code (grep for patterns, read files)
    ↓
PARALLEL EXECUTION
    ├─ Task 1 (sonnet): Mechanical Checklist
    │   └─ Verify acceptance criteria, goals, API contracts
    └─ Task 2 (opus): Semantic Inference
        └─ Generate behavior summary from code
        └─ Compare against spec intent/JTBD
    ↓
Combine results (deduplicate findings)
    ↓
If divergences found:
    ├─ Create corrective tasks in plan.md
    ├─ Increment attempt counter for this spec
    └─ Keep spec in pending-validations.md
If no divergences:
    ├─ Remove spec from pending-validations.md
    └─ Log validation success
    ↓
Output <promise>SPEC_VALIDATED</promise> or <promise>CORRECTIONS_NEEDED</promise>
```

### Components

```
validate.md (prompt)
├── Spec selection from pending-validations.md
├── Code discovery (grep, file reading)
├── Parallel Tasks
│   ├── Task 1: Checklist verification (sonnet)
│   └── Task 2: Semantic inference (opus)
├── Result combination & deduplication
├── Corrective task generation
└── Pending-validations.md management

pending-validations.md (tracking)
├── - [ ] specs/spec-name.md
├── - [ ] specs/another-spec.md (attempt: 2/3)
└── (specs removed when validated clean)

plan.md (output)
└── Corrective tasks added when divergence found
```

---

## 3. Key Features

### 3.1 Two-Pass Verification

**Problem:** Single-pass verification either misses obvious issues (too shallow) or wastes tokens (too deep).

**Solution:** Parallel passes with different focus:

**Pass 1: Mechanical Checklist (Task - sonnet)**
- Extract acceptance criteria from spec
- For each criterion, verify in code:
  - Function/class exists? (grep)
  - API contract matches? (read signatures)
  - Config keys present? (grep)
  - Tests exist? (file check)
- Output: List of PASS/FAIL per criterion

**Pass 2: Semantic Inference (Task - opus)**
- Read implemented code thoroughly
- Generate "behavior summary" (what code actually does)
- Compare against spec's:
  - Purpose/Goals
  - JTBD (jobs to be done)
  - Architecture intent
- Output: List of divergences (if any)

**Combination:**
- Agent receives both task outputs
- Deduplicates (same issue reported differently)
- Merges into unified divergence list

### 3.2 Parallel Task Execution

**Problem:** Sequential passes are slow.

**Solution:** Launch both tasks simultaneously:

```markdown
## Execute Verification

Launch two parallel tasks:

**Task 1: Checklist Verification**
Prompt: "Read spec {X}, extract acceptance criteria. For each criterion,
verify implementation exists in codebase. Return PASS/FAIL per criterion
with evidence."
Model: sonnet

**Task 2: Semantic Inference**
Prompt: "Read all code implementing spec {X}. Generate behavior summary
(what the code does, not what spec says). Compare against spec goals
and JTBD. Report any divergences."
Model: opus

Wait for both tasks to complete.
```

**Deduplication instruction:**
```markdown
Review both task outputs. Remove duplicate findings (same issue
described differently). Merge into single divergence list.
```

### 3.3 Attempt Tracking

**Problem:** Validation-correction loop could cycle forever.

**Solution:** Track attempts per spec:

**Format in pending-validations.md:**
```markdown
# Pending Validations

- [ ] specs/auth-system.md
- [ ] specs/export-loopy.md (attempt: 2/3)
- [ ] specs/user-system.md (attempt: 3/3 - ESCALATE)
```

**Logic:**
- First validation: no counter (implicit attempt 1)
- If creates corrections: add `(attempt: 2/3)`
- If still fails: increment to `(attempt: 3/3 - ESCALATE)`
- At attempt 3: mark ESCALATE, do not create more tasks, notify human

**Escalation output:**
```markdown
⚠️ ESCALATION REQUIRED

Spec: specs/user-system.md
Attempts: 3/3
Status: Validation failed after 3 correction cycles

Remaining divergences:
1. {description}
2. {description}

Recommendation: Human review required. Possible causes:
- Spec ambiguity
- Implementation approach incompatible with spec
- Spec needs updating (if implementation is correct)
```

### 3.4 Corrective Task Generation

**Problem:** Divergences need actionable fixes.

**Solution:** Generate specific tasks in plan.md:

**Format:**
```markdown
- [ ] Fix: {specific divergence description}
      Done when: {observable fix criteria}
      Verify: {command or check}
      (cite: specs/{spec-name}.md)
      [Validation correction - attempt {N}]
```

**Example:**
```markdown
- [ ] Fix: Missing rate limiting on /api/login endpoint
      Done when: Rate limiter middleware applied to login route
      Verify: grep -q "rateLimiter" src/routes/auth.js
      (cite: specs/auth-system.md section 4.2)
      [Validation correction - attempt 1]
```

**Placement:** Tasks added to plan.md at the end (or in appropriate phase if structure exists).

### 3.5 Clean Validation = Removal

**Problem:** When is a spec truly validated?

**Solution:** Only remove when BOTH passes report no divergences:

```markdown
If checklist: all PASS
AND inference: no divergences
THEN:
  - Remove spec from pending-validations.md
  - Output: <promise>SPEC_VALIDATED</promise>
  - Log: "✅ specs/{name}.md validated successfully"
```

---

## 4. Prompt Structure

### Section 1: Phase 0 (Orient)

```markdown
Study pending-validations.md
Pick first - [ ] entry
Read the full spec
```

### Section 2: Code Discovery

```markdown
Identify implemented code:
- Search for patterns from spec (grep)
- Read main implementation files
- Note test files if present
```

### Section 3: Parallel Verification

```markdown
Launch two Tasks in parallel:

Task 1 (sonnet): Checklist
- Extract acceptance criteria from spec
- Verify each against codebase
- Return PASS/FAIL list

Task 2 (opus): Inference
- Read all implementation code
- Generate behavior summary
- Compare against spec intent
- Return divergence list
```

### Section 4: Result Processing

```markdown
Receive both task outputs
Deduplicate findings
Merge into unified divergence list

If divergences found:
  - Create corrective tasks in plan.md
  - Update attempt counter
  - Keep spec in pending-validations.md

If no divergences:
  - Remove spec from pending-validations.md
  - Log success
```

### Section 5: Guardrails

Numbered 9s system:
- 99999999999999: Spec is source of truth (never modify specs)
- 9999999999999: Both passes mandatory (never skip)
- 999999999999: Deduplicate before creating tasks
- 99999999999: Respect attempt limit (escalate at 3)
- 9999999999: Tasks must be specific and verifiable

### Section 6: Completion Signals

```markdown
Spec validated: <promise>SPEC_VALIDATED</promise>
Corrections created: <promise>CORRECTIONS_NEEDED</promise>
Escalation required: <promise>ESCALATE</promise>
All specs validated: <promise>COMPLETE</promise>
```

---

## 5. Example Execution

### Input (pending-validations.md):

```markdown
# Pending Validations

- [ ] specs/auth-system.md
- [ ] specs/export-loopy.md
```

### Execution Flow:

**Step 1:** Pick `specs/auth-system.md`

**Step 2:** Read spec, identify:
- Goals: JWT auth, rate limiting, session management
- Key files: src/auth.js, src/middleware/auth.js

**Step 3:** Launch parallel tasks:

**Task 1 output (checklist):**
```
✅ PASS: JWT token generation exists
✅ PASS: Login endpoint implemented
✅ PASS: Logout endpoint implemented
❌ FAIL: Rate limiting not found on /api/login
✅ PASS: Session middleware present
```

**Task 2 output (inference):**
```
Behavior summary:
- Auth controller handles login/logout with JWT
- Tokens stored in memory (spec says Redis)
- No rate limiting observed
- Session management via cookies

Divergences:
1. Token storage: code uses memory, spec requires Redis
2. Rate limiting: not implemented (spec section 4.2)
```

**Step 4:** Combine and deduplicate:
- Rate limiting issue appears in both → merge to one
- Token storage only in inference → keep
- Final: 2 divergences

**Step 5:** Create corrective tasks:

```markdown
- [ ] Fix: Implement rate limiting on /api/login endpoint
      Done when: Rate limiter middleware applied, 5 req/min limit
      Verify: grep -q "rateLimiter" src/routes/auth.js
      (cite: specs/auth-system.md section 4.2)
      [Validation correction - attempt 1]

- [ ] Fix: Migrate token storage from memory to Redis
      Done when: Redis client used for token storage
      Verify: grep -q "redis" src/auth.js && grep -q "setToken" src/auth.js
      (cite: specs/auth-system.md section 3.1)
      [Validation correction - attempt 1]
```

**Step 6:** Update pending-validations.md:
```markdown
- [ ] specs/auth-system.md (attempt: 2/3)
- [ ] specs/export-loopy.md
```

**Step 7:** Output `<promise>CORRECTIONS_NEEDED</promise>`

---

## 6. Testing Strategy

### Validation Pass Tests

```bash
# Test clean validation
# Create spec + matching implementation
./loop.sh validate 1
grep -q "SPEC_VALIDATED" logs/log-validate-*.txt || fail

# Verify spec removed from pending
! grep -q "test-spec.md" pending-validations.md || fail
```

### Divergence Detection Tests

```bash
# Test divergence detection
# Create spec + incomplete implementation
./loop.sh validate 1
grep -q "CORRECTIONS_NEEDED" logs/log-validate-*.txt || fail

# Verify tasks created
grep -q "Validation correction" plan.md || fail
```

### Attempt Limit Tests

```bash
# Test escalation at 3 attempts
# Create spec that always fails
./loop.sh validate 3
grep -q "ESCALATE" logs/log-validate-*.txt || fail
grep -q "attempt: 3/3" pending-validations.md || fail
```

### Parallel Task Tests

```bash
# Verify both tasks execute
./loop.sh validate 1
grep -q "Checklist" logs/log-validate-*.txt || fail
grep -q "Inference" logs/log-validate-*.txt || fail
```

---

## 7. Implementation Guidance

### Prompt File Location

```
prompts/validate.md
```

### Total Size

~350 lines markdown

### Model Requirement

**Sonnet as base** (main orchestration), but Tasks use:
- Task 1: sonnet (mechanical checklist)
- Task 2: opus (semantic inference)

### Expected Execution Time

- Simple spec (1-2 files): 3-5 minutes
- Medium spec (3-5 files): 5-10 minutes
- Complex spec (many files): 10-15 minutes

Parallel tasks reduce wall-clock time vs sequential.

---

## 8. Key Design Decisions

### Why Two Passes?

**Checklist catches:**
- Missing functions/classes
- Wrong API signatures
- Missing config
- Absent tests

**Inference catches:**
- Subtle behavioral drift
- JTBD violations
- Architecture intent mismatches
- Edge case handling

Neither alone is sufficient.

### Why Parallel Tasks?

**Benefits:**
- Faster (wall-clock time)
- Independent reasoning (no bias from first pass)
- Right model for right job (sonnet for mechanical, opus for inference)

**Trade-off:** Slightly more tokens (two contexts), but time savings worth it.

### Why 3 Attempts Max?

**Reasoning:**
- Attempt 1: Initial divergence found
- Attempt 2: Corrections applied, maybe new issues
- Attempt 3: If still failing, something fundamental is wrong

After 3 cycles, human intervention is more efficient than more automation.

### Why Spec is Source of Truth?

**Principle:** Specs define intended behavior. Code should match specs.

**If code is "correct" but spec is "wrong":**
- This is a spec update issue
- Escalation notifies human
- Human decides: update spec or fix code

Validate never modifies specs.

---

## 9. Notes

### Integration with Build Mode

**Flow:**
```
plan.md (tasks) → build (implements) → pending-validations.md
    ↓
validate (checks) → divergences? → plan.md (corrective tasks)
    ↓
build (fixes) → validate (re-checks) → clean? → done
```

Validate and build can alternate until convergence or escalation.

### pending-validations.md Format

```markdown
# Pending Validations

Generated by plan mode. Specs listed here need validation after build completes.

- [ ] specs/auth-system.md
- [ ] specs/export-loopy.md (attempt: 2/3)
- [x] specs/loop-orchestrator.md (validated 2026-01-24)
```

Note: [x] entries kept for history but ignored by validate.

### When No Pending Validations

If `pending-validations.md` is empty or has no `- [ ]` entries:
- Validate outputs `<promise>COMPLETE</promise>`
- Loop.sh stop condition triggers
- All specs validated successfully

---

**Implementation:** See `prompts/validate.md`

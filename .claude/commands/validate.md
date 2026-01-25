---
name: validate
description: Validate ONE spec from pending-validations.md using parallel checker and inferencer agents
---

# Validate Mode

Validate ONE spec from pending-validations.md by comparing implementation against specification, create corrective tasks when divergence is detected, and signal completion.

---

## Phase 0: Orient

Study the validation context:

1. Read `pending-validations.md` completely (understand validation queue)
2. Pick the first pending spec (marked `- [ ]`)
3. Read the FULL spec to understand requirements
4. Note current attempt count (if shown)

**CRITICAL:** Specs are source of truth. NEVER modify specs during validation.

---

## Subagent Strategy

**Decision rule:** Subagents have ~20K token overhead each. Only use when value exceeds cost.

### For code discovery:

- **Known file paths** (spec mentions specific files): Use Read tool directly
  - Math: 5 files × 2K = 10K tokens < 1 subagent × 20K overhead
  - Direct reads are 2x more efficient

- **Need to find files** (generic patterns): Use Grep to locate, then Read directly
  - Search for patterns from spec (function names, classes, config keys)
  - Once found, read with Read tool

- **Large codebase** (> 15 files to verify): Use 1-2 Explore subagents for initial discovery
  - Map implementation landscape
  - Then read specific files directly

### For parallel verification:

- **Always launch TWO Tasks in parallel** for verification (mandatory):
  - Task 1: Checklist verification (model: sonnet)
  - Task 2: Semantic inference (model: opus)
  - These run simultaneously for speed

### General guidance:

- Known file paths → Read tool (never spawn subagent for known location)
- Pattern search → Grep tool (not subagent)
- Large-scale discovery → Explore subagent (find patterns, identify files)
- Verification passes → Task tool with parallel execution

**Anti-patterns to avoid:**
- ❌ Spawning general-purpose subagent to "read and check file X"
- ❌ Sequential verification (must be parallel)
- ❌ Subagents for simple grep operations

---

## Validation Workflow

Validate ONE spec completely following this mandatory workflow:

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CRITICAL VALIDATION WORKFLOW (MANDATORY)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

### Step 1: Read Spec Completely

Pick first `- [ ]` entry from pending-validations.md.

Read the FULL spec to understand:
- **Purpose/Goals**: What the system should accomplish
- **Architecture**: How it should be structured
- **Key Features**: Specific capabilities required
- **Acceptance Criteria**: Observable requirements
- **Non-Goals**: What it should NOT do

Check attempt count:
- No counter = first validation (attempt 1)
- `(attempt: 2/3)` = second validation
- `(attempt: 3/3 - ESCALATE)` = final attempt

### Step 2: Code Discovery

Identify implemented code without making assumptions:

1. **Search for patterns from spec**:
   ```bash
   # Function/class names mentioned in spec
   grep -r "function_name" .

   # File paths cited in spec
   test -f path/from/spec.js

   # Config keys from spec
   grep -r "config_key" .
   ```

2. **Read main implementation files**:
   - Use Read tool for identified files
   - Note test files if present
   - Map actual file structure

3. **Document what you found**:
   - List files that implement this spec
   - Note missing files (if spec mentions them)
   - Identify test coverage

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

### Step 4: Result Processing

**Receive both task outputs.**

#### Deduplication:

Review both task outputs and remove duplicates:
- Same issue reported differently
- Overlapping concerns
- Redundant findings

**Example:**
```
Task 1: ❌ FAIL: Rate limiting not found
Task 2: Divergence: No rate limiting implemented

→ Merge to: "Missing rate limiting on API endpoints"
```

#### Merge Findings:

Create unified divergence list:

```markdown
DIVERGENCES FOUND:

1. {specific issue}
   - Source: Checklist / Inference / Both
   - Spec section: {citation}
   - Description: {clear explanation}

2. {next issue}
   ...
```

### Step 5: Decision Logic

**If NO divergences found:**

```markdown
✅ VALIDATION PASSED

Spec: {spec_path}
Status: All criteria met, no behavioral drift detected
Actions:
  - Remove spec from pending-validations.md
  - Mark as validated

Output: <promise>SPEC_VALIDATED</promise>
```

**If divergences found AND attempt < 3:**

```markdown
⚠️ DIVERGENCES DETECTED

Spec: {spec_path}
Attempt: {current}/3
Divergences: {count}

Actions:
  - Create corrective tasks in plan.md
  - Update attempt counter in pending-validations.md
  - Keep spec in pending queue

Output: <promise>CORRECTIONS_NEEDED</promise>
```

**If divergences found AND attempt = 3:**

```markdown
🚨 ESCALATION REQUIRED

Spec: {spec_path}
Attempts: 3/3
Status: Validation failed after 3 correction cycles

Remaining divergences:
1. {description}
2. {description}

Recommendation: Human review required. Possible causes:
- Spec ambiguity or outdated requirements
- Implementation approach incompatible with spec
- Spec needs updating (if implementation is correct)

Actions:
  - Mark (attempt: 3/3 - ESCALATE) in pending-validations.md
  - Do NOT create more corrective tasks
  - Notify user

Output: <promise>ESCALATE</promise>
```

### Step 6: Create Corrective Tasks (if needed)

**Only when divergences found AND attempt < 3.**

For each divergence, create a task in plan.md:

**Format:**
```markdown
- [ ] Fix: {specific divergence description}
      Done when: {observable fix criteria}
      Verify: {command or semantic check}
      (cite: {spec_path} section {X})
      [Validation correction - attempt {N}]
```

**Example:**
```markdown
- [ ] Fix: Missing rate limiting on /api/login endpoint
      Done when: Rate limiter middleware applied to login route (5 req/min limit)
      Verify: grep -q "rateLimiter" src/routes/auth.js
      (cite: specs/auth-system.md section 4.2)
      [Validation correction - attempt 2]
```

**Placement:** Add tasks to plan.md at the end (or in appropriate phase if structure exists).

**Task Quality Requirements:**
- ✅ Specific (clear what to fix)
- ✅ Verifiable (has concrete completion check)
- ✅ Cites spec section
- ✅ Includes attempt number

### Step 7: Update pending-validations.md

**If validation PASSED:**
- Remove the spec entry completely (delete line)

**If divergences found (attempt < 3):**
- Update attempt counter:
  - First validation → add `(attempt: 2/3)`
  - Second validation → update to `(attempt: 3/3)`

**If escalation required (attempt = 3):**
- Update to: `(attempt: 3/3 - ESCALATE)`
- Keep in pending-validations.md for human review

**Example pending-validations.md:**
```markdown
# Pending Validations

- [ ] specs/auth-system.md (attempt: 2/3)
- [ ] specs/export-loopy.md
- [ ] specs/user-system.md (attempt: 3/3 - ESCALATE)
```

### Step 8: Update specs/README.md

**Only when validation PASSED (`SPEC_VALIDATED`):**

Update the spec's status in `specs/README.md` table:
- Change ⏳ (In Progress) → ✅ (Implemented)
- Or change 📋 (Planned) → ✅ (Implemented) if it skipped the ⏳ state
- Update "Current Status" counts if needed

**Example:**

Before:
```markdown
| [export-loopy-system.md](export-loopy-system.md) | ⏳ export-loopy.sh | ...

Current Status: 4 implemented, 1 in progress, 2 planned
```

After:
```markdown
| [export-loopy-system.md](export-loopy-system.md) | ✅ export-loopy.sh | ...

Current Status: 5 implemented, 0 in progress, 2 planned
```

**If divergences found or escalation:** Do NOT update README (status stays as-is).

### Step 9: Output Completion Signal

Output the appropriate signal:

```
<promise>SPEC_VALIDATED</promise>
```

or

```
<promise>CORRECTIONS_NEEDED</promise>
```

or

```
<promise>ESCALATE</promise>
```

or (if pending-validations.md is now empty):

```
<promise>COMPLETE</promise>
```

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

---

## Guardrails

### Process (highest priority)

99999999999999. **Spec is source of truth**: NEVER modify specs. Code must match specs, not vice versa.

9999999999999. **Both passes mandatory**: NEVER skip either verification task. Both checklist and inference required.

999999999999. **Parallel execution required**: Tasks must run in parallel, not sequentially.

99999999999. **Deduplicate before creating tasks**: Merge duplicate findings to avoid redundant work.

9999999999. **Respect attempt limit**: Escalate at attempt 3. Do NOT create more tasks after escalation.

### Task Creation Quality

999999999. **Tasks must be specific**: "Fix auth" is too vague. "Add rate limiting to /api/login" is specific.

99999999. **Tasks must be verifiable**: Include concrete verification command or semantic criteria.

9999999. **Tasks must cite spec**: Include spec path and section number for context.

999999. **Tasks show attempt number**: Tag with `[Validation correction - attempt N]`.

### Validation Accuracy

99999. **Do NOT invent requirements**: Only verify what spec explicitly states.

9999. **Mark confidence**: If uncertain about a finding, note it clearly.

999. **Evidence required**: Checklist findings need file:line citations or grep results.

### File Management

99. **Clean removal on success**: Delete validated spec from pending-validations.md completely.

9. **Update README on success**: Change ⏳→✅ (or 📋→✅) in specs/README.md only after validation passes.

8. **Preserve escalations**: Keep escalated specs in pending for human review.

---

## Completion Signals

**Spec validated successfully:**
```
<promise>SPEC_VALIDATED</promise>
```

**Corrective tasks created:**
```
<promise>CORRECTIONS_NEEDED</promise>
```

**Escalation required (3 attempts reached):**
```
<promise>ESCALATE</promise>
```

**All specs validated (pending-validations.md empty):**
```
<promise>COMPLETE</promise>
```

---

## Notes

### Why Two Passes?

**Checklist catches:**
- Missing functions/classes
- Wrong API signatures
- Missing config keys
- Absent tests

**Inference catches:**
- Subtle behavioral drift
- JTBD violations
- Architecture intent mismatches
- Edge case handling gaps

Neither alone is sufficient. Checklist is mechanical, inference is semantic.

### Why Parallel Tasks?

**Benefits:**
- Faster (wall-clock time halved)
- Independent reasoning (no bias from first pass)
- Right model for right job (sonnet for checklist, opus for inference)

**Trade-off:** Slightly more tokens (two contexts), but time savings worth it.

### Why 3 Attempts Max?

**Reasoning:**
- Attempt 1: Initial divergence found
- Attempt 2: Corrections applied, maybe new issues surface
- Attempt 3: If still failing, something fundamental is wrong

After 3 cycles, human intervention is more efficient than more automation.

### Why Spec is Source of Truth?

**Principle:** Specs define intended behavior. Code should match specs.

**If code is "correct" but spec is "wrong":**
- This is a spec update issue (not validation issue)
- Escalation notifies human
- Human decides: update spec or fix code

Validate mode never modifies specs.

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

### Example Execution

**Input (pending-validations.md):**
```markdown
# Pending Validations

- [ ] specs/auth-system.md
- [ ] specs/export-loopy.md
```

**Step 1:** Pick `specs/auth-system.md`

**Step 2:** Read spec, identify:
- Goals: JWT auth, rate limiting, session management
- Key files: src/auth.js, src/middleware/auth.js

**Step 3:** Launch parallel tasks:

Task 1 output (checklist):
```
✅ PASS: JWT token generation exists
✅ PASS: Login endpoint implemented
✅ PASS: Logout endpoint implemented
❌ FAIL: Rate limiting not found on /api/login
✅ PASS: Session middleware present
```

Task 2 output (inference):
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

**Step 4:** Deduplicate:
- Rate limiting appears in both → merge to one
- Token storage only in inference → keep
- Final: 2 divergences

**Step 5:** Create corrective tasks in plan.md:

```markdown
- [ ] Fix: Implement rate limiting on /api/login endpoint
      Done when: Rate limiter middleware applied (5 req/min limit)
      Verify: grep -q "rateLimiter" src/routes/auth.js
      (cite: specs/auth-system.md section 4.2)
      [Validation correction - attempt 1]

- [ ] Fix: Migrate token storage from memory to Redis
      Done when: Redis client used for token storage
      Verify: grep -q "redis.*setToken" src/auth.js
      (cite: specs/auth-system.md section 3.1)
      [Validation correction - attempt 1]
```

**Step 6:** Update pending-validations.md:
```markdown
- [ ] specs/auth-system.md (attempt: 2/3)
- [ ] specs/export-loopy.md
```

**Step 7:** Output `<promise>CORRECTIONS_NEEDED</promise>`

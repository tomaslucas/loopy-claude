# Build Mode Prompt System

> Task execution prompt with mandatory verification workflow that ensures quality and prevents incomplete implementations

## Status: Ready

---

## 1. Overview

### Purpose

Execute ONE task from plan.md completely, verify it works correctly, commit changes, and signal completion. Repeat until plan is empty.

### Goals

- Mandatory verification workflow (6 steps)
- Self-verification before completion
- Delete completed tasks (keep plan clean)
- Inline subagent strategy (no AGENTS.md)
- Support executable and semantic verification
- Fix failures immediately (up to 3 attempts)
- Complete implementation (no placeholders/stubs)

### Non-Goals

- Executing multiple tasks per iteration
- Skipping verification steps
- Marking tasks [x] instead of deleting
- External documentation dependencies
- Tool restriction enforcement

---

## 2. Architecture

### 6-Step Workflow

```
Step 1: Read Task Completely
    ↓ (understand Done when, Verify, citations)
Step 2: Pre-Implementation Research (MANDATORY)
    ↓ (search codebase, read FULL spec - no shortcuts)
Step 3: Implement
    ↓ (complete, no placeholders)
Step 4: Self-Verify (MANDATORY)
    ↓ (execute command OR check semantic criteria)
    ↓ (+ quick quality scan: secrets, injection, paths)
    If FAILS → Step 5
    If PASSES → Step 6
Step 5: Fix and Re-verify
    ↓ (analyze, fix, re-verify, up to 3 attempts)
    → GOTO Step 4
Step 6: Complete
    ↓ (tests, commit, delete task, signal)
```

### Decision Tree (Step 4 Verification)

```
Task has "Verify:" field?
    ├─ Yes → Is it executable command?
    │   ├─ Yes → Execute via Bash
    │   │   ├─ Exit code 0 → PASS
    │   │   └─ Exit code non-0 → FAIL
    │   └─ No → Semantic criteria
    │       └─ Read files, check each criterion
    │           ├─ All met → PASS
    │           └─ Any missing → FAIL
    └─ No → Use "Done when" as checklist
        └─ Verify each criterion + basic sanity checks
```

---

## 3. Key Features

### 3.1 Mandatory Spec Reading

**Problem:** Agents skip reading the spec and implement based on task description only.

**Solution:** Step 2 requires reading the FULL cited spec before implementing.

**Enforcement:**
- Step 2 marked (MANDATORY) with explicit "DO NOT proceed to Step 3"
- Guardrail 9999999999999 (second highest priority)
- Checklist includes: requirements, non-goals, architecture constraints

**Benefits:**
- Agent understands the "why" behind the task
- Catches implicit requirements not in task description
- Prevents drift from spec intent

### 3.2 Mandatory Verification

**Problem:** Agents claim task complete but code has errors.

**Solution:** Step 4 is non-negotiable.

**Enforcement:**
- Guardrail 99999999999999 (highest priority)
- Explicit "DO NOT output TASK_COMPLETE yet" instruction
- Fix workflow if verification fails

**Types supported:**
1. **Executable commands:**
   ```
   Verify: grep -c "pattern" file.txt
   Verify: npm test -- auth.test.js
   Verify: jq . config.json
   ```

2. **Semantic criteria:**
   ```
   Done when: Section exists with diagram
   Verify: Read file, confirm section and diagram present
   ```

3. **Fallback (no Verify field):**
   ```
   Use "Done when" criteria
   + Basic sanity checks (syntax, file existence, tests)
   ```

### 3.3 Quick Quality Scan

**Problem:** Common security/quality issues slip through functional verification.

**Solution:** Mandatory checklist in Step 4 before completing.

**Checks:**
- ❌ Hardcoded secrets, passwords, or API keys
- ❌ SQL string concatenation (use parameterized queries)
- ❌ eval() or exec() with external input
- ❌ Infinite loops without exit conditions
- ❌ Unsanitized file paths (path traversal risk)
- ❌ Ignoring error return values

**Benefits:**
- Zero-overhead (checklist, not subagent)
- Catches 80% of common security issues
- Reinforces good habits

### 3.4 In-Session Fix Loop

**Problem:** Agent marks complete despite failures.

**Solution:** Fix before completion (context still fresh).

**Workflow:**
```
Verify FAILS
    ↓
Analyze what went wrong
    ↓
Fix the issue
    ↓
Re-verify
    ↓ (repeat up to 3 times)
If still failing after 3 attempts:
    → Document issue, stop
```

**Why 3 attempts:**
- 1st: Simple oversight (typo, missed file)
- 2nd: Deeper issue (logic error)
- 3rd: Fundamental problem (wrong approach)

After 3 failures → something wrong, better to stop and reassess.

### 3.5 DELETE Completed Tasks

**Problem:** Plan.md grows with [x] noise.

**Solution:** Remove entire task block after completion.

**Implementation:**
```bash
# After task verified and committed:
# Delete task from plan.md (description + Done when + Verify + cite)
# Result: plan.md only shows pending work
```

**Stop condition:** No more `- [ ]` in plan.md → signal `<promise>COMPLETE</promise>`

**Benefits:**
- Clean, focused plan
- Clear progress (what's LEFT)
- History in git commits

### 3.6 Subagent Strategy

**Inline guidance (no AGENTS.md):**

- **File paths known**: Read tool directly
  - Math: 5 files × 2K = 10K < 1 subagent × 20K
- **Need to find files**: 1-3 Explore subagents
- **Many files (> 15)**: Consider 5-10 parallel subagents
- **Testing/validation**: Bash tool directly (no subagent)

**Anti-patterns flagged:**
- ❌ Subagent to "read and summarize file X"
- ❌ One subagent per known file
- ❌ Subagents for simple operations

### 3.7 Complete Implementation

**Guardrail 999999999999:**

"Implement completely. No placeholders, no stubs, no TODOs."

**Examples of incomplete (forbidden):**
```python
def process_data(input):
    # TODO: implement validation
    pass
```

```javascript
function authenticate(user) {
    // Placeholder for auth logic
    return true;
}
```

**Required:**
- Actual implementation
- Working code
- Tests pass

---

## 4. Prompt Structure

### Section 1: Phase 0 (Orient)

```markdown
Study specs/README.md
Study plan.md
Scan existing codebase
```

Context setup.

### Section 2: Subagent Strategy

Inline rules matching plan.md style.

### Section 3: Task Selection

```markdown
Pick first pending task (marked [ ]) from plan.md
```

Tasks pre-prioritized by plan generator.

### Section 4: Implementation Workflow

**6-step process** (detailed):
- Step 1: Read task completely
- Step 2: Pre-implementation research
- Step 3: Implement
- Step 4: Self-verify (MANDATORY)
- Step 5: If verification fails
- Step 6: Only when verification passes

**Critical verification workflow block** with visual separators (━━━).

### Section 5: Guardrails

Numbered 9s system organized by category:
- **Process** (highest): verification, spec reading, task deletion
- **Implementation Quality**: complete implementation, quality scan, DRY
- **Codebase Hygiene**: fix bugs, fix spec inconsistencies, update plan
- **Documentation** (lowest): capture why, version tags

### Section 6: Completion Signals

```markdown
Task done: <promise>TASK_COMPLETE</promise>
All tasks done: <promise>COMPLETE</promise>
```

---

## 5. Example Execution

### Input (plan.md task):

```markdown
- [ ] Implement authentication controller (file: `src/auth.js`)
      Done when: Controller has login/logout methods with JWT validation
      Verify: grep -q "login.*logout.*jwt" src/auth.js && npm test -- auth.test.js
      (cite: specs/auth-system.md requirements)
```

### Execution Flow:

**Step 1:** Read task, understand requirements

**Step 2:**
```bash
grep -r "auth" src/  # Check existing implementation
cat specs/auth-system.md  # Read full context
```

**Step 3:** Implement `src/auth.js`:
```javascript
const jwt = require('jsonwebtoken');

class AuthController {
  login(username, password) {
    // Validate credentials
    // Generate JWT
    return { token: jwt.sign({username}, SECRET) };
  }

  logout(token) {
    // Invalidate token
  }
}
```

**Step 4:** Self-verify:
```bash
# Run verification command
grep -q "login.*logout.*jwt" src/auth.js
# Exit code: 0 (PASS)

npm test -- auth.test.js
# Tests: 5 passed (PASS)
```

**Step 6:** Complete:
```bash
git add src/auth.js tests/auth.test.js
git commit -m "Task: Implement authentication controller

Added JWT-based auth with login/logout methods

(cite: specs/auth-system.md)"

# Delete task from plan.md
# Output: <promise>TASK_COMPLETE</promise>
```

---

## 6. Testing Strategy

### Verification Workflow Tests

```bash
# Test executable verification
echo 'Verify: test -f dummy.txt' > task
./loop.sh build 1
# Should execute command and check exit code

# Test semantic verification
echo 'Done when: Section X exists\nVerify: Read file, confirm section' > task
./loop.sh build 1
# Should read file and check criterion

# Test failure handling
# Task with impossible verification
./loop.sh build 1
# Should attempt fix up to 3 times, then stop
```

### Task Deletion Tests

```bash
# Before
grep -c "- \[ \]" plan.md  # Returns N

./loop.sh build 1

# After
grep -c "- \[ \]" plan.md  # Returns N-1
grep -c "- \[x\]" plan.md  # Returns 0 (no [x] tasks)
```

### Completion Signal Tests

```bash
# Create plan with 1 task
./loop.sh build 5  # Max 5 but only 1 task
# Should stop after 1 (plan empty)
# Should output <promise>COMPLETE</promise>
```

---

## 7. Implementation Guidance

### Prompt File Location

```
prompts/build.md
```

Implemented at: `prompts/build.md`

### Total Size

~320 lines markdown

### Model Requirement

**Sonnet sufficient** (straightforward execution, no extended_thinking needed)

Loop.sh defaults to sonnet for build mode.

### Expected Execution Time

- Simple task (1 file): 2-5 minutes
- Medium task (2-3 files + tests): 5-10 minutes
- Complex task (multiple files, integration): 10-20 minutes

---

## 8. Key Design Decisions

### Why Mandatory Verification?

**Common failure pattern (without verification):**
```
Agent: "I implemented the feature"
Reality: Syntax error, tests fail, incomplete
Result: Wasted iteration, compound problems
```

**With verification:**
```
Agent: Implement → Verify → Fix → Verify → Complete
Reality: Code works, tests pass, spec met
Result: Clean progress, no rework
```

Verification catches issues while context is fresh.

### Why DELETE Instead of Mark [x]?

**Benefits:**
- Plan shows only what's LEFT (cleaner)
- History in git (where it belongs)
- Stop condition trivial (no [ ] tasks)
- Reduces tokens (shorter plan.md)

**History available via:**
```bash
git log -p plan.md  # See evolution
git show HEAD~1:plan.md  # See previous version
```

### Why Fix In-Session (Up to 3 Times)?

**Benefits:**
- Context still fresh (agent understands task)
- Cheaper than new iteration
- Learns from mistakes immediately

**Why stop at 3:**
- Prevents infinite loops
- After 3 failures → fundamental issue
- Better to document and escalate

### Why No AGENTS.md?

**Reason:** Prompts should be self-contained.

**Benefits:**
- Autonomous operation
- No file dependencies
- Portable prompts
- Easier to test

All guidance inline (subagent strategy, guardrails).

---

## 9. Notes

### Task Granularity

Plan generator creates tasks sized for single iteration:
- Small: 1 file, < 50 lines changed
- Medium: 2-3 files, < 200 lines changed
- Large: Avoided (plan generator splits)

Build mode trusts plan generator's sizing.

### When Tests Fail

**Workflow:**
```
Implement → Verify → Tests fail
    ↓
Debug (analyze failure)
    ↓
Fix issue
    ↓
Re-verify → Tests pass
    ↓
Complete
```

Never mark complete with failing tests.

### Git Commit Messages

**Format:**
```
Task: {brief description}

{what was done}

(cite: specs/{spec-name}.md)
```

**Example:**
```
Task: Add JWT middleware to API routes

Integrated authMiddleware into all protected endpoints.
Updated routes.js and middleware.js.

(cite: specs/auth-system.md)
```

---

**Implementation:** See `prompts/build.md`

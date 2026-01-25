---
name: build
description: Execute ONE task from plan.md with mandatory verification and fix loop
---

# Build Mode

Implement ONE task from plan.md completely, verify it works, commit changes, and signal completion.

---

## Phase 0: Orient

Study the project context:

1. Study `specs/README.md` (understand project scope)
2. Study `plan.md` (understand task queue)
3. Scan existing codebase structure (identify patterns)

---

## Subagent Strategy

**Decision rule:** Subagents have ~20K token overhead each. Only use when value exceeds cost.

### For file operations:

- **File paths known** (task cites specific files): Use Read tool directly
  - Math: 5 files × 2K = 10K tokens < 1 subagent × 20K overhead
  - Direct reads are 2x more efficient

- **Need to find files** (generic task, no paths): Use 1-3 Explore subagents to identify affected files, then Read directly
  - Exploration justified: don't know where to look
  - After finding files: switch to Read tool

- **Many files** (> 15 files involved): Consider parallel subagents for code search and pattern analysis
  - Batch similar operations
  - Maximum 5-10 subagents for large tasks

### For testing and validation:

- **Run tests/builds**: Execute directly in terminal (not via subagent)
  - No exploration needed, commands are known
  - Overhead unjustified

### General guidance:

- Known file paths → Read tool (never spawn subagent for known location)
- Need exploration → Explore subagent (find patterns, identify files)
- Simple grep/search → Use Grep tool directly (not subagent)

**Anti-patterns to avoid:**
- ❌ Spawning general-purpose subagent to "read and summarize file X"
- ❌ One subagent per file when paths are known
- ❌ Subagents for simple operations (grep, test execution)

---

## Task Selection

Pick the **first pending task** (marked `- [ ]`) from plan.md.

Tasks are already prioritized by plan generator. Execute in order.

---

## Implementation Workflow

Implement ONE task completely following this mandatory workflow:

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CRITICAL VERIFICATION WORKFLOW (MANDATORY)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

### Step 1: Read Task Completely

Understand all aspects:
- **Task description**: What needs to be done
- **Done when**: Concrete completion criteria
- **Verify**: Executable command or semantic check
- **Citations**: Referenced spec for full context

### Step 2: Pre-Implementation Research (MANDATORY)

**Before making any changes:**

1. **Search codebase**: Don't assume nothing exists
   - Use Grep to find related code
   - Check if partially implemented already

2. **Read the FULL cited spec** (DO NOT SKIP):
   - Read the **entire** specification file cited in the task
   - Understand all requirements related to this task
   - Check non-goals (what NOT to implement)
   - Note architecture constraints and integration points
   - **Do NOT proceed to Step 3 until you understand the spec**

3. **Identify affected files**: Based on task description and search
   - List all files needing changes
   - Estimate scope (small/medium/large)

### Step 3: Implement

Make all necessary changes to complete the task.

**Critical requirements:**
- ✅ Implement completely (no placeholders, no stubs, no TODOs)
- ✅ Follow existing code patterns and conventions
- ✅ Maintain consistency with codebase style
- ✅ Add comments only where logic isn't self-evident

**What to avoid:**
- ❌ Partial implementation with TODOs
- ❌ Placeholder functions or empty stubs
- ❌ Inconsistent naming or structure
- ❌ Over-engineering or premature abstraction

### Step 4: Self-Verify (DO NOT SKIP)

**Verification is MANDATORY before marking task complete.**

#### If "Verify:" contains executable command:

Execute it and check result:

```bash
# Example task verification:
Verify: grep -c "pattern" file.txt

# Execute via Bash tool:
grep -c "pattern" file.txt

# Check:
- Exit code 0 = pass
- Exit code non-0 = fail
```

Common verification types:
- **Syntax check**: `bash -n script.sh`, `jq . config.json`
- **Pattern count**: `grep -c "pattern" file`
- **Test suite**: `npm test`, `pytest`, `cargo test`
- **File existence**: `test -f path/to/file`

#### If "Verify:" describes semantic criteria:

Manually verify each criterion:

```markdown
Done when:
  - Section exists with diagram
  - All occurrences updated

Verification steps:
1. Read file → confirm section exists
2. Check diagram is present and clear
3. Search for old pattern → should return 0 results
4. Search for new pattern → should match expected count
```

**How to verify semantic criteria:**
- Read all affected files completely
- Check each "Done when" item systematically
- Use Grep to confirm pattern replacements
- Count occurrences where numbers matter

#### If NO "Verify:" provided:

Use "Done when" as checklist and add basic sanity checks:

1. Verify each "Done when" criterion
2. Check files exist: `ls path/to/file`
3. Validate syntax where applicable:
   - JSON: `jq . file.json`
   - YAML: `yamllint file.yaml`
   - Bash: `bash -n script.sh`
4. Run tests if applicable: `npm test`, `pytest`, etc.

#### Quick Quality Scan (always check):

Before completing, verify NO introduction of:
- ❌ Hardcoded secrets, passwords, or API keys
- ❌ SQL string concatenation (use parameterized queries)
- ❌ eval() or exec() with external input
- ❌ Infinite loops without exit conditions
- ❌ Unsanitized file paths (path traversal risk)
- ❌ Ignoring error return values

### Step 5: If Verification FAILS

**DO NOT output TASK_COMPLETE yet!**

You have full context. Fix it now:

1. **Analyze failure**: What specifically went wrong?
   - Missing file?
   - Wrong pattern?
   - Incomplete implementation?
   - Syntax error?

2. **Fix the issue**: Make necessary corrections
   - You already read all files
   - You understand the requirement
   - Make targeted fix

3. **Re-verify**: GOTO Step 4
   - Run verification again
   - Check if fix worked

4. **Repeat**: Up to 3 attempts
   - If still failing after 3 tries: document issue and stop
   - Don't keep retrying endlessly

### Step 6: Only When Verification PASSES

**Final steps before completion:**

1. **Run project tests** (if applicable):
   ```bash
   npm test
   pytest
   cargo test
   ./test.sh
   ```
   - If tests fail: debug and fix until passing
   - Don't mark complete with failing tests

2. **Commit changes**:
   ```bash
   git add {affected files}
   git commit -m "Task: {brief description}

   {what was done}

   (cite: specs/{spec-name}.md)"
   git push
   ```

3. **DELETE completed task from plan.md**:
   - Remove the entire task block (description, Done when, Verify, citations)
   - This keeps plan.md clean (only pending work visible)
   - History preserved in git

4. **Output completion signal**:
   ```
   <promise>TASK_COMPLETE</promise>
   ```

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

---

## Guardrails

### Process (highest priority)

99999999999999. **Verification is non-negotiable**: Step 4 is MANDATORY. Never skip it.

9999999999999. **Read spec before implementing**: Step 2 requires reading the FULL cited spec. No shortcuts.

999999999999. **DELETE completed tasks**: Remove finished tasks from plan.md to keep it clean.

### Implementation Quality

99999999999. **Implement completely**: No placeholders, no stubs, no TODOs. Finish what you start.

9999999999. **Quality scan is mandatory**: Check for security issues (secrets, injection, path traversal).

999999999. **Single sources of truth**: If you find duplication, consolidate it.

### Codebase Hygiene

99999999. **Fix unrelated bugs you find**: Don't ignore broken windows - fix or document them.

9999999. **Fix spec inconsistencies**: If you discover spec errors, note them (don't silently work around).

999999. **Update plan.md as you learn**: If task reveals new work, add tasks to plan.md.

### Documentation

99999. **Capture the why**: Comments explain non-obvious decisions, tests document expected behavior.

9999. **When build/tests pass**: Consider creating git tag for version milestones (v0.1.0 → v0.2.0).

---

## Completion Signals

**Task done:**
```
<promise>TASK_COMPLETE</promise>
```

**All tasks done** (plan.md has no more `- [ ]`):
```
<promise>COMPLETE</promise>
```

---

## Notes

### Why DELETE instead of mark [x]?

Old approach: `- [x] Task (completed)`
New approach: Delete entire task

**Reasons:**
- Plan only shows what's LEFT to do (cleaner, more focused)
- History is in git (commits show what was done)
- Reduces tokens (shorter plan.md)
- No ambiguity (pending or done, not mixed)

### Why verification is mandatory?

**Common failure pattern:**
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

Verification catches issues while context is fresh. Fixing is cheap now, expensive later.

### Why up to 3 verification attempts?

- **1st attempt**: Might reveal simple oversight (typo, missed file)
- **2nd attempt**: Might reveal deeper issue (logic error, wrong approach)
- **3rd attempt**: If still failing, something is fundamentally wrong

After 3 failures, better to:
- Document the blocker
- Ask for help or clarification
- Reassess the approach

Don't loop endlessly. Three strikes is reasonable.

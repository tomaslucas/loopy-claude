# Done Tracking System

> Lightweight history of completed tasks for human observability without inflating plan.md

## Status: Draft

---

## 1. Overview

### Purpose

The current design deletes completed tasks from plan.md (good for focus and tokens), but this loses the "at-a-glance progress narrative". Humans asking "what did we do this week?" must dig through git log. This system adds a minimal append-only log of completions.

### Goals

- One-line entry per completed task
- Append-only (never edited by automation)
- Machine-parseable for metrics
- Human-readable for progress tracking
- Zero impact on plan.md cleanliness
- Minimal token overhead

### Non-Goals

- Detailed task descriptions (that's in git commits)
- Full task content preservation (that's in git history)
- Analytics or dashboards (just raw data)
- Automatic cleanup or rotation

---

## 2. Architecture

### Flow

```
Build mode completes a task
    ↓
Delete task from plan.md (existing behavior)
    ↓
NEW: Append one-line entry to done.md
    ↓
Commit includes both plan.md and done.md
```

### Entry Format

```
{YYYY-MM-DD HH:MM} | {task-title} | {commit-hash} | {spec-path}
```

Example:
```
2026-01-26 14:30 | Implement rate limit detection | abc1234 | specs/loop-orchestrator-system.md
2026-01-26 15:45 | Add jq fallback for config parsing | def5678 | specs/dependency-check-system.md
2026-01-26 16:20 | Create reconcile prompt | 789abcd | specs/reconcile-system.md
```

### Components

```
done.md (project root)
├── Header (static)
└── Entries (append-only, one per completed task)

.claude/commands/build.md
└── Modified Step 6 to append to done.md before commit
```

---

## 3. Implementation Details

### 3.1 done.md Structure

```markdown
# Completed Tasks

> Append-only log of completed tasks. See git log for details.

| Date | Task | Commit | Spec |
|------|------|--------|------|
| 2026-01-26 14:30 | Implement rate limit detection | abc1234 | specs/loop-orchestrator-system.md |
| 2026-01-26 15:45 | Add jq fallback | def5678 | specs/dependency-check-system.md |
```

### 3.2 Build Mode Integration

In build.md Step 6 (after verification passes, before commit):

```markdown
### Step 6: Record Completion and Commit

1. **Append to done.md**:
   
   Extract task title (first line of task description).
   
   If done.md doesn't exist, create it with header:
   ```markdown
   # Completed Tasks
   
   > Append-only log of completed tasks. See git log for details.
   
   | Date | Task | Commit | Spec |
   |------|------|--------|------|
   ```
   
   Append entry (commit hash will be added after commit):
   ```markdown
   | {YYYY-MM-DD HH:MM} | {task-title} | pending | {spec-path} |
   ```

2. **Delete completed task from plan.md**

3. **Commit changes**:
   ```bash
   git add plan.md done.md {affected files}
   git commit -m "Task: {brief description}
   
   {what was done}
   
   (cite: specs/{spec-name}.md)"
   ```

4. **Update done.md with actual commit hash**:
   ```bash
   COMMIT_HASH=$(git rev-parse --short HEAD)
   # Replace "pending" with actual hash in last entry
   sed -i "s/| pending |/| $COMMIT_HASH |/" done.md
   git add done.md
   git commit --amend --no-edit
   ```
```

### 3.3 Alternative: Single Commit Approach

To avoid the amend, we can predict the format:

```markdown
1. Delete task from plan.md
2. Append to done.md with placeholder
3. Commit all changes
4. After commit, update done.md with hash
5. Amend commit to include updated done.md
```

Or simpler: just use "see git log" instead of hash:

```
| 2026-01-26 14:30 | Implement rate limit detection | - | specs/loop-orchestrator-system.md |
```

The `-` indicates "check git log at this timestamp". Less precise but simpler implementation.

### 3.4 Validation Mode Integration

Validate mode doesn't complete tasks directly, but when it removes a validated spec from pending-validations.md, it could optionally log:

```
| 2026-01-26 17:00 | ✓ Validated: export-loopy-system.md | abc1234 | specs/export-loopy-system.md |
```

This is optional — the primary use case is build task tracking.

### 3.5 Metrics Extraction

done.md is machine-parseable:

```bash
# Count tasks completed today
grep "^| $(date +%Y-%m-%d)" done.md | wc -l

# List tasks for a specific spec
grep "specs/loop-orchestrator-system.md" done.md

# Tasks completed this week
grep -E "^| 2026-01-(2[0-6])" done.md
```

---

## 4. API / Interface

### Files

| File | Purpose | Management |
|------|---------|------------|
| done.md | Completion log | Append-only by build mode |

### No New Modes

This integrates into existing build mode, no new loop.sh mode needed.

---

## 5. Testing Strategy

### Manual Tests

1. **First task completion:**
   - Ensure done.md doesn't exist
   - Complete a task via build mode
   - Verify done.md created with header + entry

2. **Subsequent completions:**
   - Complete another task
   - Verify entry appended (not replaced)

3. **Entry format:**
   - Check date format correct
   - Check task title extracted properly
   - Check spec path present

4. **Metrics extraction:**
   - Run grep commands from 3.5
   - Verify parseable output

---

## 6. Acceptance Criteria

- [ ] done.md created on first task completion (if missing)
- [ ] done.md has header with table format
- [ ] Each completed task appends one entry
- [ ] Entry contains: date, task title, commit indicator, spec path
- [ ] done.md included in task commit
- [ ] done.md never truncated or edited (append-only)
- [ ] Machine-parseable with grep

---

## 7. Implementation Guidance

### Impact Analysis

**Change Type:** [x] Enhancement

**Affected Areas:**

Files to create:
- `done.md` (created dynamically on first completion)

Files to modify:
- `.claude/commands/build.md` (~15 lines: Step 6 expansion)
- `specs/README.md` (add entry)

### Verification Strategy

```bash
# After running build mode
test -f done.md && echo "✓ done.md exists"

# Check format
head -5 done.md

# Check entry added
tail -1 done.md | grep -E "^\| [0-9]{4}-[0-9]{2}-[0-9]{2}"
```

---

## 8. Notes

### Why Append-Only?

- Simpler implementation (no parsing, just append)
- Clear audit trail
- No risk of corruption from partial writes
- Easy to manually review/edit if needed

### Why Table Format?

- Human-readable in terminal and GitHub/GitLab
- Machine-parseable with simple tools
- Consistent column widths make scanning easy

### Why Not in git log?

Git log contains this information, but:
- Requires git commands to extract
- Mixed with non-task commits
- Harder to get quick overview
- No single-file artifact for progress reporting

done.md is the "summary view" while git log is the "detail view".

### Size Management

At ~100 bytes per entry:
- 100 tasks = 10KB
- 1000 tasks = 100KB
- 10000 tasks = 1MB

For most projects, done.md will never need rotation. For very long-lived projects, manual archival (move to done-2025.md) is simple.

### Why Simpler Than Post-Mortem?

Post-mortem is analytical (processes logs, extracts lessons, prunes).
Done tracking is mechanical (append a line).

Different complexity levels for different purposes.

---

**Related specs:**
- `prompt-build-system.md` — Modified to append entries
- `loop-orchestrator-system.md` — No changes needed

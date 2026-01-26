# Implementation Plan

Generated: 2026-01-26
Specs analyzed: 3 (reconcile-system, dependency-check-system, done-tracking-system)

---

## Phase 1: Reconcile Prompt

- [ ] Create .claude/commands/reconcile.md with complete reconciliation workflow
      Done when:
        - File exists at .claude/commands/reconcile.md
        - Has frontmatter with name: reconcile and description
        - Detects escalated entries via pattern: (attempt: 3/3.*ESCALATE)
        - Graceful exit if no escalations found
        - Generates structured divergence report for each escalated spec
        - Presents A/B/C/D options via AskUserQuestion
        - Option A: generates corrective tasks, resets validation entry
        - Option B: shows diff preview, requires confirmation, adds migration note
        - Option C: skips without changes
        - Option D: shows detailed divergence report
        - Multiple escalations processed sequentially with continue prompt
        - All changes committed with clear message
        - Outputs <promise>COMPLETE</promise> when done
      Verify:
        - test -f .claude/commands/reconcile.md
        - grep -q "ESCALATE" .claude/commands/reconcile.md
        - grep -q "AskUserQuestion" .claude/commands/reconcile.md
        - grep -q "divergence" .claude/commands/reconcile.md
        - grep -q '<promise>COMPLETE</promise>' .claude/commands/reconcile.md
      (cite: specs/reconcile-system.md sections 3.1-3.7, 6)

---

## Phase 2: Done Tracking

- [ ] Add done.md tracking to build.md Step 6
      Done when:
        - Step 6 includes logic to create done.md if missing (with header)
        - Step 6 appends one-line entry per completed task
        - Entry format: | {YYYY-MM-DD HH:MM} | {task-title} | - | {spec-path} |
        - done.md included in task commit
        - Table format with columns: Date, Task, Commit, Spec
        - Append-only semantics documented (never truncate)
      Verify:
        - grep -q "done.md" .claude/commands/build.md
        - grep -q "Completed Tasks" .claude/commands/build.md
        - grep -q "append" .claude/commands/build.md
      (cite: specs/done-tracking-system.md sections 3.1-3.2, 6)

---

## Phase 3: README Updates

- [ ] Update specs/README.md status for implemented specs
      Done when:
        - reconcile-system.md status changed from 📋 to ⏳
        - dependency-check-system.md status changed from 📋 to ⏳
        - done-tracking-system.md status changed from 📋 to ⏳
        - Current Status line updated: "0 in progress" → "3 in progress"
      Verify:
        - grep -q "reconcile-system.md.*⏳" specs/README.md
        - grep -q "dependency-check-system.md.*⏳" specs/README.md
        - grep -q "done-tracking-system.md.*⏳" specs/README.md
        - grep -q "3 in progress" specs/README.md
      (cite: specs/README.md Implementation Status section)

---

## Context Budget Summary

| Phase | Files | Est. Lines | Context |
|-------|-------|------------|---------|
| Phase 1 | reconcile.md (new) | ~250 | ✅ SMALL |
| Phase 2 | build.md | ~360 (344 existing + 15 new) | ✅ SMALL |
| Phase 3 | specs/README.md | ~150 | ✅ SMALL |

**Total: 3 tasks across 3 phases**

# Implementation Plan

Generated: 2026-01-26
Specs analyzed: 3 (reconcile-system, dependency-check-system, done-tracking-system)

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

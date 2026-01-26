# Implementation Plan

Generated: 2026-01-26
Specs analyzed: 3 (reconcile-system, dependency-check-system, done-tracking-system)

---

## Phase 1: Loop.sh Infrastructure

- [ ] Add dependency checking and reconcile mode to loop.sh
      Done when:
        - check_dependencies() function exists and runs at startup
        - detect_platform() function returns correct platform identifier
        - suggest_install() function provides platform-specific install hints
        - Required deps checked: git, awk, tee, grep
        - Optional deps checked: jq (with fallback mode)
        - Missing required → exit 3 with clear message
        - Missing optional → warning + JQ_AVAILABLE=false flag
        - jq fallback mode works for config parsing
        - jq fallback mode works for rate limit detection
        - Reconcile mode added to help text and mode switch
        - Reconcile uses opus model
        - Check runs once at startup (not per-iteration)
      Verify:
        - bash -n loop.sh
        - grep -q "check_dependencies" loop.sh
        - grep -q "detect_platform" loop.sh
        - grep -q "suggest_install" loop.sh
        - grep -q "JQ_AVAILABLE" loop.sh
        - grep -q "reconcile)" loop.sh
        - grep -A2 'reconcile)' loop.sh | grep -q opus
      (cite: specs/dependency-check-system.md sections 3.1-3.5, specs/reconcile-system.md section 4.1)
      [Grouped: Same file (loop.sh), combined ~90 lines new code, sequential integration point]

---

## Phase 2: Reconcile Prompt

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

## Phase 3: Done Tracking

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

## Phase 4: README Updates

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
| Phase 1 | loop.sh | ~600 (516 existing + 90 new) | ✅ MEDIUM |
| Phase 2 | reconcile.md (new) | ~250 | ✅ SMALL |
| Phase 3 | build.md | ~360 (344 existing + 15 new) | ✅ SMALL |
| Phase 4 | specs/README.md | ~150 | ✅ SMALL |

**Total: 4 tasks across 4 phases**

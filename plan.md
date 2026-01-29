# Implementation Plan

Generated: 2026-01-29
Specs analyzed: 1 (compound-architecture-system.md)

## Phase 3: Telemetry Infrastructure

- [ ] Create hooks/core/log-event.sh telemetry emitter
      Done when:
        - Script exists and is executable
        - Accepts parameters: agent, model, mode, format, event, status, attempt, details
        - Appends JSONL to logs/session-events.jsonl
        - Works with or without jq (graceful fallback)
      Verify:
        - test -x hooks/core/log-event.sh
        - bash -n hooks/core/log-event.sh
        - ./hooks/core/log-event.sh claude opus build stream-json test_event 0 1 '{}' && test -f logs/session-events.jsonl
      (cite: specs/compound-architecture-system.md Section 3.5)

- [ ] Update .gitignore for telemetry files
      Done when:
        - logs/session-events.jsonl is ignored
        - hooks/ directory is NOT ignored (tracked code)
      Verify:
        - grep -q "session-events.jsonl" .gitignore
        - ! grep -q "^hooks/" .gitignore
      (cite: specs/compound-architecture-system.md Section 9 .gitignore Updates)
      [Grouped: Related to telemetry, same context]

## Phase 4: VDD Rules in Plan Mode

- [ ] Add VDD (Verification Driven Development) rules to plan.md
      Done when:
        - VDD section exists with trigger conditions
        - E2E verification script requirement documented
        - tests/e2e/{feature}-verify.sh pattern specified
        - specs/archive/ exclusion rule added
      Verify:
        - grep -q "VDD" .claude/commands/plan.md
        - grep -q "tests/e2e" .claude/commands/plan.md
        - grep -q "specs/archive" .claude/commands/plan.md
      (cite: specs/compound-architecture-system.md Section 3.2)

## Phase 5: Prompt Modifications (Lifecycle & Focus)

- [ ] Add archival lifecycle to validate.md on PASS
      Done when:
        - "On Validation PASS" section exists with archival steps
        - Extract Decision Summary step documented
        - Update PIN step documented (Active → Archived)
        - mv specs/{name}.md specs/archive/ command included
      Verify:
        - grep -q "Archival Process" .claude/commands/validate.md
        - grep -q "mv specs/" .claude/commands/validate.md
        - grep -q "Archived Knowledge" .claude/commands/validate.md
      (cite: specs/compound-architecture-system.md Section 3.3)

- [ ] Refocus post-mortem.md to operational patterns only
      Done when:
        - "Operational Patterns ONLY" section exists
        - IGNORE list (architectural decisions, library choices, API design)
        - FOCUS ON list (failed commands, syntax errors, tool misuse)
        - Log format awareness for mixed stream-json/text
      Verify:
        - grep -q "Operational Patterns" .claude/commands/post-mortem.md
        - grep -q "IGNORE" .claude/commands/post-mortem.md || grep -q "Do NOT extract" .claude/commands/post-mortem.md
        - grep -q "stream-json\|format" .claude/commands/post-mortem.md
      (cite: specs/compound-architecture-system.md Section 3.4)

- [ ] Add archive awareness to audit.md and reconcile.md
      Done when:
        - audit.md Phase 0 mentions specs/archive/
        - audit.md includes archived specs in inventory
        - reconcile.md notes escalated specs are never in archive
      Verify:
        - grep -q "specs/archive" .claude/commands/audit.md
        - grep -q "archive" .claude/commands/reconcile.md
      (cite: specs/compound-architecture-system.md Section 9 Audit/Reconcile Mode Interaction)
      [Grouped: Both are minor archive-awareness updates, ~20 lines each]

## Phase 6: Build Mode Commit Hash Fix

- [ ] Fix done.md commit hash capture in build.md Step 6
      Done when:
        - Commit happens BEFORE done.md entry
        - Commit hash captured via git rev-parse --short HEAD
        - done.md entry uses actual hash (not "-")
        - git commit --amend includes done.md
      Verify:
        - grep -q "rev-parse" .claude/commands/build.md
        - grep -q "amend" .claude/commands/build.md
      (cite: specs/compound-architecture-system.md Section 9 done.md Commit Hash Fix)

## Phase 7: Loop.sh Modifications (CAUTION)

- [ ] Add conditional git push to loop.sh (Issue #13 fix)
      Done when:
        - Function checks if remote exists before pushing
        - Graceful handling when no remote configured
        - Warning message when push skipped
      Verify:
        - grep -q "No remote configured\|remote.*origin" loop.sh
        - bash -n loop.sh
      (cite: specs/compound-architecture-system.md Section 3.6)

- [ ] Add telemetry integration to loop.sh
      Done when:
        - Calls hooks/core/log-event.sh at mode start/end
        - Passes agent, model, mode, format parameters
        - Graceful if hook doesn't exist (|| true pattern)
      Verify:
        - grep -q "log-event.sh" loop.sh
        - bash -n loop.sh
      (cite: specs/compound-architecture-system.md Section 3.5)
      [Grouped: Both loop.sh changes, should be done together to minimize risk]

---

## Context Budget Summary

| Phase | Estimated Context | Files Touched |
|-------|------------------|---------------|
| 1. Directory Structure | ~50 lines | 6 .gitkeep files, prompts/ |
| 2. PIN Restructure | ~200 lines | specs/README.md |
| 3. Telemetry | ~150 lines | hooks/core/log-event.sh, .gitignore |
| 4. VDD in Plan | ~100 lines | .claude/commands/plan.md |
| 5. Prompt Modifications | ~300 lines | validate.md, post-mortem.md, audit.md, reconcile.md |
| 6. Build Fix | ~50 lines | .claude/commands/build.md |
| 7. Loop.sh | ~700 lines | loop.sh |

**Total: 10 tasks across 7 phases (~1550 lines total context)**

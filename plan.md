# Implementation Plan

Generated: 2026-01-30
Specs analyzed: 1 (copilot-hooks-system.md)

## Context Budget Summary

| Phase | Estimated Context | Files Touched |
|-------|------------------|---------------|
| 1. VDD Verification | ~50 lines | tests/e2e/copilot-hooks-verify.sh |
| 2. Adapter + Config | ~350 lines | hooks/adapters/copilot-adapter.sh, .github/hooks/hooks.json |
| 3. Export Integration | ~50 lines | export-loopy.sh (modify ~20 lines) |

**Total: 3 tasks across 3 phases (~450 lines total context)**

---

## Phase 2: Adapter and Configuration

- [ ] Create Copilot adapter and hooks configuration
      Done when:
        - hooks/adapters/copilot-adapter.sh exists and is executable
        - Adapter translates Copilot format (toolName, toolArgs string) to Claude format (tool_name, tool_input object)
        - Adapter translates Claude exit codes to Copilot JSON (exit 2 + stderr → permissionDecision: deny)
        - Adapter always exits 0 (Copilot requirement)
        - .github/hooks/hooks.json exists with preToolUse and postToolUse configuration
        - VDD test passes (tests/e2e/copilot-hooks-verify.sh exits 0)
      Verify:
        - [ -x hooks/adapters/copilot-adapter.sh ] && echo "✅ Adapter executable"
        - [ -f .github/hooks/hooks.json ] && jq . .github/hooks/hooks.json && echo "✅ Valid JSON"
        - echo '{"toolName":"bash","toolArgs":"{\"command\":\"rm -rf /\"}"}' | ./hooks/adapters/copilot-adapter.sh preToolUse | grep -q "deny" && echo "✅ Dangerous blocked"
        - ./tests/e2e/copilot-hooks-verify.sh && echo "✅ All VDD tests pass"
      (cite: specs/copilot-hooks-system.md Sections 3.2, 3.3, 6 Acceptance Criteria)
      [Grouped: Adapter + config are tightly coupled, same subsystem, ~300 lines combined]

---

## Phase 3: Export Integration

- [ ] Update export-loopy.sh to generate .github/hooks/hooks.json
      Done when:
        - generate_templates() function creates .github/hooks/hooks.json in destination
        - Dry-run mode shows hooks.json would be created
        - Full export creates valid hooks.json
      Verify:
        - grep -q "github/hooks/hooks.json" export-loopy.sh && echo "✅ Code added"
        - ./export-loopy.sh full --dry-run 2>&1 | grep -q "hooks.json" && echo "✅ Dry-run shows hooks.json"
      (cite: specs/copilot-hooks-system.md Section 3.4 Export Integration)

---

## Documentation Review

Spec: copilot-hooks-system.md
Documentation tasks: NONE
Justification: No new user-facing concepts. Hooks system already documented in archived compound-architecture-system.md. Export change is internal implementation detail.

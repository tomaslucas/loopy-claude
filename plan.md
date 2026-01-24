# Implementation Plan

Generated: 2026-01-24
Specs analyzed: 1 (prompt-validate-system.md)
Action: regenerated (previous plan 100% complete, see git log)

---

## Phase 1: Loop.sh Integration

- [ ] Update loop.sh to support validate mode with stop condition
      Done when:
        - Case statement includes "validate" with model "sonnet"
        - Stop condition added: empty pending-validations.md (no `- [ ]` entries) for validate mode
        - Error message updated to include "validate" in available modes
      Verify:
        - grep -q 'validate)' loop.sh
        - grep -q 'pending-validations.md' loop.sh
        - grep -q 'Available modes.*validate\|validate.*Available' loop.sh || grep -q '"plan, build, reverse, validate"' loop.sh
        - bash -n loop.sh
      (cite: specs/prompt-validate-system.md section 2 Architecture)
      [Context estimate: ~200 lines - loop.sh is 183 lines, small modification]

---

## Context Budget Summary

| Task | Files | Lines | Budget |
|------|-------|-------|--------|
| Create validate.md | 1 new + 2 reference | ~400 new + ~800 ref | MEDIUM |
| Update loop.sh | 1 existing | ~20 changes | SMALL |

Total tasks: 2 (from 1 spec)
Grouping rationale: Spec has two distinct deliverables (new prompt file, shell script integration). Each is self-contained with different verification strategies.

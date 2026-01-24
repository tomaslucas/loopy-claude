# Implementation Plan

Generated: 2026-01-24
Specs analyzed: 1 (prompt-validate-system.md)
Action: regenerated (previous plan 100% complete, see git log)

---

## Phase 1: Validate Mode Prompt

- [ ] Create prompts/validate.md with complete validation workflow
      Done when:
        - File exists at prompts/validate.md (~350 lines)
        - Contains Phase 0 (Orient) with pending-validations.md reading
        - Contains Subagent Strategy section
        - Contains Parallel Verification section with Task 1 (sonnet/checklist) and Task 2 (opus/inference)
        - Contains Result Processing section with deduplication logic
        - Contains Attempt Tracking logic (max 3, escalation)
        - Contains Corrective Task Generation format
        - Contains Guardrails with numbered 9s system
        - Contains Completion Signals (SPEC_VALIDATED, CORRECTIONS_NEEDED, ESCALATE, COMPLETE)
      Verify:
        - test -f prompts/validate.md
        - grep -q "Phase 0" prompts/validate.md
        - grep -q "pending-validations.md" prompts/validate.md
        - grep -q "Task 1.*sonnet\|sonnet.*Task 1" prompts/validate.md
        - grep -q "Task 2.*opus\|opus.*Task 2" prompts/validate.md
        - grep -q "SPEC_VALIDATED" prompts/validate.md
        - grep -q "CORRECTIONS_NEEDED" prompts/validate.md
        - grep -q "ESCALATE" prompts/validate.md
        - grep -q "attempt.*3\|3.*attempt" prompts/validate.md
      (cite: specs/prompt-validate-system.md sections 2-6)
      [Context estimate: ~400 lines - reference build.md/reverse.md patterns]

---

## Phase 2: Loop.sh Integration

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

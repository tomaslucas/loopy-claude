# Implementation Plan

Generated: 2026-01-26
Specs analyzed: 3 (reconcile-system, dependency-check-system, done-tracking-system)

---


## Context Budget Summary

| Phase | Files | Est. Lines | Context |
|-------|-------|------------|---------|
| Phase 1 | reconcile.md (new) | ~250 | ✅ SMALL |
| Phase 2 | build.md | ~360 (344 existing + 15 new) | ✅ SMALL |
| Phase 3 | specs/README.md | ~150 | ✅ SMALL |

**Total: 3 tasks across 3 phases**

---

## Validation Corrections

- [ ] Fix: Exclude reconcile mode from post-mortem hook
      Done when: Reconcile mode excluded from post-mortem hook at loop.sh:650 (following pattern of audit, prime, bug)
      Verify: grep "post-mortem\|prime\|bug\|audit" loop.sh | grep -q reconcile
      (cite: specs/reconcile-system.md section 2 - interactive decision-making mode)
      [Validation correction - attempt 2]

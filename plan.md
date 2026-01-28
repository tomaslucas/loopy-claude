# Implementation Plan

Generated: 2026-01-28
Specs analyzed: 1 (strategy-investigation-system.md)

---

## Phase 2: Command Updates

- [ ] Add strategy reading to /build Step 2
      Done when:
        - build.md Step 2 explicitly mentions reading strategy section
        - Notes that divergence from strategy should be documented in commit
      Verify:
        - grep -q "strategy" .claude/commands/build.md
      (cite: specs/strategy-investigation-system.md section 4.3)

- [ ] Add strategy compliance check to /validate
      Done when:
        - validate.md includes strategy compliance in verification
        - Checks if implementation follows documented strategy
        - Flags divergence as potential issue (not automatic fail)
      Verify:
        - grep -q "strategy compliance" .claude/commands/validate.md
      (cite: specs/strategy-investigation-system.md section 4.4)

- [ ] Add missing strategy detection to /audit
      Done when:
        - audit.md Step 3 checks for specs without "Selected Implementation Strategy"
        - Reports as "Incomplete: missing implementation strategy"
        - Severity marked as Low
      Verify:
        - grep -q "missing.*strategy" .claude/commands/audit.md
      (cite: specs/strategy-investigation-system.md section 4.5)

- [ ] Add lightweight strategy to /bug for non-trivial fixes
      Done when:
        - bug.md has trivial vs non-trivial classification
        - Non-trivial bugs get 2-3 approach analysis
        - Task format includes Strategy: and Alternatives considered:
      Verify:
        - grep -q "trivial" .claude/commands/bug.md
        - grep -q "Alternatives considered" .claude/commands/bug.md
      (cite: specs/strategy-investigation-system.md section 4.6)

- [ ] Add strategy divergence handling to /reconcile
      Done when:
        - reconcile.md handles "Strategy says X, code does Y" case
        - Presents 3 options: update code, update strategy, document divergence
        - Uses AskUserQuestion for resolution
      Verify:
        - grep -q "strategy.*divergence" .claude/commands/reconcile.md
      (cite: specs/strategy-investigation-system.md section 4.7)

[Grouped: 6 commands, similar changes, ~50 lines each, same subsystem]

---

## Phase 3: Specification Updates

- [ ] Update related specs to document strategy-investigation integration
      Done when:
        - specs/prompt-plan-system.md mentions Phase 3b
        - specs/prompt-build-system.md mentions strategy reading
        - specs/prompt-validate-system.md mentions strategy compliance
        - specs/audit-system.md mentions missing strategy detection
        - specs/reconcile-system.md mentions strategy divergence
        - specs/feature-designer-skill.md mentions strategy generation
      Verify:
        - for s in prompt-plan prompt-build prompt-validate audit reconcile feature-designer; do grep -q -i "strateg" specs/$s*.md; done
      (cite: specs/strategy-investigation-system.md section 7)
      [Grouped: 6 spec files, documentation only, ~10 lines each]

---

## Context Budget Summary

| Phase | Files | Est. Lines | Status |
|-------|-------|------------|--------|
| Phase 1: Feature Designer | 1 | ~40 | Pending |
| Phase 2: Commands | 6 | ~300 | Pending |
| Phase 3: Spec docs | 6 | ~60 | Pending |
| **Total** | **13** | **~400** | ✅ Within budget |

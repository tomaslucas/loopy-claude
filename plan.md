# Implementation Plan

Generated: 2026-01-26
Reviewed: 2026-01-26 (no changes needed - plan correctly structured)
Specs analyzed: 1 (post-mortem-system.md)

---

## Phase 1: Core Implementation

## Phase 2: Prompt Integration

## Phase 3: Documentation

- [ ] Update README.md to document learning system
      Done when:
        - Core Components section includes post-mortem description
        - Workflow diagram shows post-mortem auto-trigger
        - File structure shows lessons-learned.md
        - Model selection table includes post-mortem → sonnet
      Verify:
        - grep -q "post-mortem" README.md && echo "post-mortem documented"
        - grep -q "lessons-learned" README.md && echo "lessons file documented"
      (cite: specs/post-mortem-system.md section 7 - Implementation Guidance)
      [Single file, independent of other phases]

---

## Context Budget Summary

| Phase | Files | Est. Lines | Status |
|-------|-------|------------|--------|
| Phase 1 | post-mortem.md (new ~150), loop.sh (~390 + 10) | ~550 | ✅ Within budget |
| Phase 2 | plan.md, build.md, validate.md, reverse.md (Phase 0 sections only ~50 each) | ~200 | ✅ Within budget |
| Phase 3 | README.md | ~560 | ✅ Within budget |

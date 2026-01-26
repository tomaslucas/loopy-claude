# Implementation Plan

Generated: 2026-01-26
Reviewed: 2026-01-26 (no changes needed - plan correctly structured)
Specs analyzed: 1 (post-mortem-system.md)

---

## Phase 1: Core Implementation

## Phase 2: Prompt Integration

- [ ] Add lessons-learned.md reading to all productive mode prompts
      Done when:
        - `.claude/commands/plan.md` Phase 0 includes step to read lessons-learned.md section for "Plan"
        - `.claude/commands/build.md` Phase 0 includes step to read lessons-learned.md section for "Build"
        - `.claude/commands/validate.md` Phase 0 includes step to read lessons-learned.md section for "Validate"
        - `.claude/commands/reverse.md` Phase 0 includes step to read lessons-learned.md section for "Reverse"
        - All reads are conditional (only if file exists)
      Verify:
        - grep -q "lessons-learned" .claude/commands/plan.md && echo "plan.md updated"
        - grep -q "lessons-learned" .claude/commands/build.md && echo "build.md updated"
        - grep -q "lessons-learned" .claude/commands/validate.md && echo "validate.md updated"
        - grep -q "lessons-learned" .claude/commands/reverse.md && echo "reverse.md updated"
      (cite: specs/post-mortem-system.md section 4.2)
      [Grouped: All 4 prompts get identical ~2 line change, combined context ~300 lines of Phase 0 sections]

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

# Implementation Plan

Generated: 2026-01-26
Specs analyzed: 1 (post-mortem-system.md)

---

## Phase 1: Core Implementation

- [ ] Create post-mortem.md prompt and add loop.sh support
      Done when:
        - `.claude/commands/post-mortem.md` exists with analysis workflow
        - Prompt reads most recent log, analyzes for errors/inefficiencies
        - Prompt updates lessons-learned.md with structured lessons (Evitar/Usar/Razón + date)
        - Prompt handles pruning when section exceeds 20 items
        - Prompt handles empty analysis (no changes, just completes)
        - `loop.sh` has `post-mortem)` case in model selection returning `sonnet`
        - `loop.sh` has hook after main loop that triggers post-mortem for productive modes
        - Hook does NOT trigger for post-mortem/prime/bug modes (prevents recursion)
      Verify:
        - test -f .claude/commands/post-mortem.md && echo "post-mortem.md exists"
        - grep -q "post-mortem)" loop.sh && echo "model case exists"
        - grep -q 'MODE.*!=.*post-mortem' loop.sh && echo "hook conditional exists"
        - grep -q "lessons-learned" .claude/commands/post-mortem.md && echo "prompt references lessons file"
      (cite: specs/post-mortem-system.md sections 2, 3, 4)
      [Grouped: Same subsystem - post-mortem mode creation, ~150 lines new + ~10 lines loop.sh changes]

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

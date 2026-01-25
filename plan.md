# Implementation Plan

Generated: 2026-01-25
Specs analyzed: 1 (structure-reorganization-system.md)
Action: regenerated (previous plan had no pending tasks)

---

## Phase 2: Agent Creation

- [ ] Create .claude/agents/ directory with spec-checker.md and spec-inferencer.md
      Done when:
        - .claude/agents/ directory exists
        - spec-checker.md has frontmatter (name, description, tools, model, color) and task definition
        - spec-inferencer.md has frontmatter (name, description, tools, model, color) and task definition
        - Agent output formats match expected schema (CHECKLIST RESULTS / BEHAVIOR SUMMARY + DIVERGENCES)
      Verify:
        - test -d .claude/agents && echo "✅ agents dir exists"
        - test -f .claude/agents/spec-checker.md && head -5 .claude/agents/spec-checker.md | grep -q "model: sonnet" && echo "✅ spec-checker with sonnet"
        - test -f .claude/agents/spec-inferencer.md && head -5 .claude/agents/spec-inferencer.md | grep -q "model: opus" && echo "✅ spec-inferencer with opus"
        - grep -q "CHECKLIST RESULTS" .claude/agents/spec-checker.md && echo "✅ checker output format"
        - grep -q "DIVERGENCES" .claude/agents/spec-inferencer.md && echo "✅ inferencer output format"
      (cite: specs/structure-reorganization-system.md section 3.3)
      [Grouped: Both agents same directory, ~180 lines total, same verification pattern]

---

## Phase 3: loop.sh Modifications

- [ ] Update loop.sh: frontmatter filter, path change, and work mode
      Done when:
        - filter_frontmatter() function exists and correctly removes YAML frontmatter
        - PROMPT_FILE path changed to ".claude/commands/${MODE}.md"
        - Error message updated to reference new path
        - Claude invocation uses filter_frontmatter
        - work mode case implemented with build/validate alternation
        - work mode respects max_iterations and detects rate limits
        - work mode terminates when no pending work in plan.md AND pending-validations.md
      Verify:
        - grep -q "filter_frontmatter" loop.sh && echo "✅ frontmatter function exists"
        - grep -q '\.claude/commands/' loop.sh && echo "✅ path updated"
        - grep -q 'case.*work' loop.sh && echo "✅ work mode case exists"
        - grep -q 'CURRENT_MODE="build"' loop.sh && echo "✅ work mode alternation"
        - ./loop.sh build 1 2>&1 | head -20  # Manual test: should still work
      (cite: specs/structure-reorganization-system.md section 3.4)
      [Grouped: Single file, all modifications interdependent, ~280 lines total after changes]

---

## Phase 4: validate.md Agent Integration

- [ ] Update .claude/commands/validate.md to reference agent files instead of inline prompts
      Done when:
        - Step 3 references .claude/agents/spec-checker.md by file path
        - Step 3 references .claude/agents/spec-inferencer.md by file path
        - Context injection format documented (SPEC_PATH, SPEC_TEXT, EVIDENCE)
        - Task descriptions use explicit agent naming pattern
        - Instructions to read agent file before using as Task prompt
      Verify:
        - grep -q "\.claude/agents/spec-checker\.md" .claude/commands/validate.md && echo "✅ checker referenced"
        - grep -q "\.claude/agents/spec-inferencer\.md" .claude/commands/validate.md && echo "✅ inferencer referenced"
        - grep -q "CONTEXT" .claude/commands/validate.md && echo "✅ context injection documented"
        - grep -q "Read.*agent" .claude/commands/validate.md && echo "✅ read instruction present"
      (cite: specs/structure-reorganization-system.md section 3.3)
      [Single file modification, depends on Phase 2 agents existing]

---

## Phase 5: Cleanup, Backward Compatibility, and Documentation

- [ ] Create backward compatibility symlinks and update documentation
      Done when:
        - prompts/ directory contains symlinks to .claude/commands/*.md (plan, build, validate, reverse, prime)
        - OR prompts/ is removed entirely (if symlinks chosen, keep; if not, remove)
        - README.md File Structure section updated to show new .claude/commands/ and .claude/agents/ paths
        - specs/README.md entry for structure-reorganization-system updated from 📋 to ⏳
      Verify:
        - test -L prompts/build.md && echo "✅ symlinks exist" || test ! -d prompts && echo "✅ prompts removed"
        - grep -q "\.claude/commands/" README.md && echo "✅ README updated"
        - grep -q "\.claude/agents/" README.md && echo "✅ README has agents section"
        - grep "structure-reorganization-system" specs/README.md | grep -q "⏳" && echo "✅ spec status updated"
        - ./loop.sh build 1 2>&1 | grep -q "Starting iteration" && echo "✅ backward compat works"
      (cite: specs/structure-reorganization-system.md sections 3.5, 5)
      [Grouped: All cleanup/docs, same verification approach, ~200 lines changes across files]

---

## Validation Corrections

(No pending validation corrections)

---

## Context Budget Summary

| Phase | Files | Lines Estimate | Budget |
|-------|-------|----------------|--------|
| Phase 1 | 6 new + 5 source ref | ~500 new + ~400 ref | MEDIUM |
| Phase 2 | 2 new | ~180 new | SMALL |
| Phase 3 | 1 modify | ~280 modified | MEDIUM |
| Phase 4 | 1 modify | ~100 modified | SMALL |
| Phase 5 | 3 modify | ~200 modified | SMALL |

Total tasks: 5 (from 1 spec)

Grouping rationale: Tasks grouped by logical subsystem and dependency order. All command files grouped together (same operation pattern). Both agents grouped (same directory, same structure). loop.sh changes grouped (interdependent). Documentation/cleanup grouped (non-critical, same verification). Each phase is self-contained with clear entry/exit criteria.

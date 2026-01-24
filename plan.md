# Implementation Plan

Generated: 2026-01-24
Specs analyzed: 1 (feature-designer-skill.md)

## Phase 3: Resource Files

- [ ] Create resources/guardrails.md with critical rules
      Done when:
        - Contains all guardrail categories from spec
        - Includes tool restrictions (Read/Write/Grep/Glob/AskUserQuestion ONLY)
        - Has emoji markers for visibility
      Verify:
        - grep -q "Tool Restrictions" .claude/skills/feature-designer/resources/guardrails.md
        - grep -q "AskUserQuestion" .claude/skills/feature-designer/resources/guardrails.md
        - grep -q "Coherence is Mandatory" .claude/skills/feature-designer/resources/guardrails.md
      (cite: specs/feature-designer-skill.md Section 8 - resources/guardrails.md)

- [ ] Create resources/examples.md with usage examples
      Done when:
        - Contains at least 2 usage examples
        - Shows skill activation flow
        - References Phase 0-3 workflow
      Verify:
        - grep -q "Example 1" .claude/skills/feature-designer/resources/examples.md
        - grep -q "crystallize" .claude/skills/feature-designer/resources/examples.md
      (cite: specs/feature-designer-skill.md Section 8 - resources/examples.md)

## Phase 4: Finalization

- [ ] Update specs/README.md to mark feature-designer-skill as ✅ Implemented
      Done when:
        - Status changed from ⏳ to ✅
        - Code column updated to show ".claude/skills"
      Verify:
        - grep -q "feature-designer-skill.md.*✅" specs/README.md
      (cite: specs/feature-designer-skill.md Section 6 Phase 3 - Update PIN)

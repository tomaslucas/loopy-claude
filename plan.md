# Implementation Plan

Generated: 2026-01-24
Specs analyzed: 1 (feature-designer-skill.md)

## Phase 3: Resource Files

- [ ] Create resources/spec-template.md with template structure (NO implementation checklists)
      Done when:
        - Template contains all 8 sections from spec
        - Section 7 is "Implementation Guidance" with NO [ ] checkboxes
        - Contains placeholder markers for feature name, purpose, goals, etc.
      Verify:
        - grep -q "## 1. Overview" .claude/skills/feature-designer/resources/spec-template.md
        - grep -q "## 7. Implementation Guidance" .claude/skills/feature-designer/resources/spec-template.md
        - ! grep -q "^- \[ \]" .claude/skills/feature-designer/resources/spec-template.md || echo "FAIL: Found implementation checklist"
      (cite: specs/feature-designer-skill.md Section 7 - Spec Template Structure)

- [ ] Create resources/phase0-research.md with mandatory research checklist
      Done when:
        - Contains 5-step research checklist
        - Contains red flags section
        - References specs/README.md (PIN)
      Verify:
        - grep -q "specs/README.md" .claude/skills/feature-designer/resources/phase0-research.md
        - grep -q "Red flags" .claude/skills/feature-designer/resources/phase0-research.md
      (cite: specs/feature-designer-skill.md Section 8 - resources/phase0-research.md)

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

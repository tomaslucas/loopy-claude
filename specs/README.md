# Loopy-Claude Specifications

Lookup table for specifications. The "Purpose" column contains semantic keywords to improve search tool hit rate.

## How to Use

1. **AI agents:** Study `specs/README.md` before any spec work
2. **Search here** to find relevant existing specs by keyword
3. **When creating new spec:** Add entry here with semantic keywords
4. **Plan mode:** Uses this to reconcile git log vs spec status

---

## Core Systems

| Spec                                                       | Code                 | Purpose                                                                                                                                                                                                                                                                                                                        |
| ---------------------------------------------------------- | -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| [loop-orchestrator-system.md](loop-orchestrator-system.md) | ✅ loop.sh            | Simple bash orchestrator, **4 stop conditions** (max iterations, empty plan, rate limit, completion signal), session logging, model selection, cross-platform compatibility, git automation, iteration control                                                                                                                 |
| [prompt-plan-system.md](prompt-plan-system.md)             | ✅ prompts/plan.md    | **5-phase intelligent planning**, multi-source reconciliation (git log > README), gap analysis, **Impact Analysis**, task expansion, **strategic grouping with extended_thinking**, context budget estimation, dependency analysis, plan lifecycle (0%/1-79%/80-100%), DELETE completed tasks                                  |
| [prompt-build-system.md](prompt-build-system.md)           | ✅ prompts/build.md   | **Mandatory verification workflow**, 6-step execution, self-verify before complete, **in-session fix loop** (up to 3 attempts), delete completed tasks, complete implementation (no TODOs/placeholders), executable and semantic verification, git discipline                                                                  |
| [prompt-reverse-system.md](prompt-reverse-system.md)       | ✅ prompts/reverse.md | **Legacy code analysis**, READ-ONLY guarantee, **3-phase workflow** (Discovery → Analysis → Spec Generation), batch processing for context efficiency, JSON intermediates, uncertainty detection, reconstruction checklists, JTBD inference from behavior                                                                      |
| [feature-designer-skill.md](feature-designer-skill.md)     | ⏳ .claude/skills     | **Interactive spec creation**, **continuous AskUserQuestion loop**, critical thinking framework, 4-phase workflow (Research → Iteration → Coherence → Crystallization), **specs without checklists**, tool restrictions (Read/Write/Grep/Glob/AskUserQuestion), YAGNI and simplicity emphasis, cross-spec coherence validation |

---

## Implementation Status

**Legend:**
- ✅ **Implemented** - Code exists and is functional
- ⏳ **In Progress** - Under active development
- 📋 **Planned** - Specification complete, not yet implemented

**Current Status:** All core specs implemented and ready.

---

## Key Design Decisions (Quick Reference)

These are documented in specs but highlighted here for agent awareness:

1. **Specs WITHOUT implementation checklists**
   - Specs describe WHAT (requirements, architecture)
   - Plan generator creates HOW (specific, verifiable tasks)
   - Separation: design (immutable) vs execution (generated)

2. **DELETE completed tasks from plan.md**
   - Plan shows only what's LEFT to do
   - History is in git log (where it belongs)
   - Stop condition: no more `- [ ]` tasks

3. **Reconciliation: git log > README > spec Status**
   - Git commits don't lie (technical truth)
   - README can be stale (human-maintained)
   - Spec status is design-time state

4. **No AGENTS.md dependency**
   - Prompts are self-contained
   - All guidance inline (subagent strategy, guardrails)
   - Portable and autonomous

5. **Model selection by mode**
   - plan → opus (extended_thinking required)
   - reverse → opus (JTBD inference + strategic grouping)
   - build → sonnet (straightforward execution)

6. **Mandatory verification in build mode**
   - Step 4 is non-negotiable
   - Fix in-session (up to 3 attempts)
   - Never mark complete with failing verification

---

## Naming Conventions

**Format:** `{domain}-system.md` or `{domain}-{type}.md`

**Examples:**
- `loop-orchestrator-system.md`
- `prompt-plan-system.md`
- `feature-designer-skill.md`

**Rules:**
- Lowercase with hyphens
- No numeric prefixes
- Descriptive and specific
- Include type suffix when relevant (-system, -skill, -prompt)

---

## Search Keywords by Topic

**Orchestration & Control:**
- loop, iteration, stop conditions, max iterations, completion signal
- orchestrator, workflow, automation

**Planning:**
- plan, gap analysis, reconciliation, task creation
- extended thinking, strategic grouping, context budget
- Impact Analysis, dependency analysis

**Building:**
- build, execution, verification, self-verify
- delete tasks, complete implementation, git commit
- mandatory workflow, fix loop

**Legacy Code:**
- reverse engineering, legacy analysis, READ-ONLY
- batch processing, JSON intermediates, reconstruction
- uncertainty detection, JTBD inference

**Design & Specs:**
- feature design, interactive, AskUserQuestion
- critical thinking, YAGNI, simplicity, trade-offs
- coherence validation, spec creation, crystallization

---

**Last Updated:** 2026-01-24
**Project:** loopy-claude

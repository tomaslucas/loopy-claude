# Loopy-Claude Specifications

> Project Intelligence Network (PIN): Decision map for AI agents. Read Active Specs in detail; trust Archived summaries.

## How to Use

1. **AI agents:** Study `specs/README.md` before any spec work
2. **Search here** to find relevant existing specs by keyword
3. **When creating new spec:** Add entry to Active Specs table
4. **Plan mode:** Reads Active Specs only, trusts Archived summaries
5. **Do NOT read archived specs** — use the decision summary instead

---

## Active Specs

| Spec                                                       | Code                 | Purpose                                                                                                                                                                                                                                                                                                                        |
| ---------------------------------------------------------- | -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| [loop-orchestrator-system.md](loop-orchestrator-system.md) | ✅ loop.sh            | Simple bash orchestrator, **5 stop conditions** (max iterations, empty plan, empty pending-validations, rate limit, completion signal), session logging, model selection, cross-platform compatibility, git automation, iteration control, **multi-agent support** (see cli-agnostic-system)                                                                                                                 |
| [cli-agnostic-system.md](cli-agnostic-system.md) | ✅ Implemented | **Multi-agent support**, external configuration (`loopy.config.json`), `--agent` flag, model name mapping, Claude Code + Copilot support, extensible design, backward compatible defaults |
| [prompt-plan-system.md](prompt-plan-system.md)             | ✅ .claude/commands/plan.md    | **5-phase intelligent planning**, multi-source reconciliation (git log > README), gap analysis, **Impact Analysis**, task expansion, **strategic grouping with extended_thinking**, context budget estimation, dependency analysis, plan lifecycle (0%/1-79%/80-100%), DELETE completed tasks, **specs/README.md status update** (📋→⏳)                                  |
| [prompt-build-system.md](prompt-build-system.md)           | ✅ .claude/commands/build.md   | **Mandatory verification workflow**, 6-step execution, **mandatory spec reading** (Step 2), **quick quality scan** (secrets, injection, paths), self-verify before complete, **in-session fix loop** (up to 3 attempts), delete completed tasks, complete implementation (no TODOs/placeholders), categorized guardrails                                                                  |
| [prompt-validate-system.md](prompt-validate-system.md)     | ✅ .claude/commands/validate.md | **Post-implementation validation**, **preflight checks** (cost optimization), **two-pass verification** (checklist + semantic inference), **parallel Tasks** (sonnet + opus), **set completeness** (enumerated items), **literal matching** (exact patterns), spec vs code comparison, **pending-validations.md tracking**, attempt limiting (max 3), corrective task generation, escalation workflow, spec as source of truth, **specs/README.md status update** (⏳→✅)                                                                  |
| [prompt-reverse-system.md](prompt-reverse-system.md)       | ✅ .claude/commands/reverse.md | **Legacy code analysis**, READ-ONLY guarantee, **3-phase workflow** (Discovery → Analysis → Spec Generation), batch processing for context efficiency, JSON intermediates, uncertainty detection, reconstruction checklists, JTBD inference from behavior                                                                      |
| [feature-designer-skill.md](feature-designer-skill.md)     | ✅ .claude/skills     | **Interactive spec creation**, **continuous AskUserQuestion loop**, critical thinking framework, 4-phase workflow (Research → Iteration → Coherence → Crystallization), **specs without checklists**, tool restrictions (Read/Write/Grep/Glob/AskUserQuestion), YAGNI and simplicity emphasis, cross-spec coherence validation |
| [export-loopy-system.md](export-loopy-system.md)           | ✅ export-loopy.sh    | **Component export script**, **preset configurations** (full/minimal/design/devtools), interactive destination selection, conflict resolution (ask per file), dependency verification (claude CLI), template generation (specs/README.md, plan.md), .gitignore merging, dry-run mode, flexible source location, permissions preservation |
| [structure-reorganization-system.md](structure-reorganization-system.md) | ✅ Implemented | **Claude Code alignment**, move prompts to `.claude/commands/`, extract validate agents to `.claude/agents/`, **work mode** (automated build→validate cycles), frontmatter support, backward compatibility, interactive command support |
| [post-mortem-system.md](post-mortem-system.md) | ✅ .claude/commands/post-mortem.md | **Autonomous learning**, session log analysis, `lessons-learned.md` persistence, structured lessons (Evitar/Usar/Razón), 20 items per section limit, semantic pruning, auto-trigger after productive modes, prompt integration (Phase 0 reads lessons) |
| [audit-system.md](audit-system.md) | ✅ .claude/commands/audit.md | **Repository audit**, spec compliance verification, READ-ONLY analysis, holistic cross-spec view, divergence detection, structured report generation, periodic maintenance tool, opus model |
| [reconcile-system.md](reconcile-system.md) | ✅ reconcile.md | **Post-escalation workflow**, structured divergence reports, human decision gate (fix code vs update spec), AskUserQuestion options, migration notes in specs, audit trail of reconciliation decisions |
| [dependency-check-system.md](dependency-check-system.md) | ✅ loop.sh | **Pre-flight validation**, required vs optional dependencies, graceful jq fallback, platform-specific install suggestions, exit code 3 on missing required, cross-platform (Linux/macOS/WSL) |
| [done-tracking-system.md](done-tracking-system.md) | ✅ done.md, build.md | **Completion history**, append-only done.md, one-line per task, machine-parseable table format, human progress visibility, zero plan.md impact, metrics extraction |
| [strategy-investigation-system.md](strategy-investigation-system.md) | ✅ Multiple | **Human on the loop model**, strategy investigation before task generation, 3-approach trade-off analysis, permanent documentation in specs, lightweight version for /bug, affects plan/build/validate/audit/reconcile/feature-designer |
| [compound-architecture-system.md](compound-architecture-system.md) | ⏳ In Progress | **Architectural evolution**, compound learning, **PIN as Decision Map** (Active/Archived sections), **specs/archive/** cold storage, **VDD** (Verification Driven Development), **structured telemetry** (JSON events), **operational post-mortem** (process not product), **conditional git push** (Issue #13), hooks system, tests/unit + tests/e2e conventions |

---

---

## Archived Knowledge

Validated and frozen specs. **Do NOT read these files** — use the decision summary below.

| Feature | Decision/Trade-off | Archived |
|---------|-------------------|----------|

**To evolve an archived spec:** Move it back to `specs/` and update this table.

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

7. **Human ON the loop (not IN the loop)**
   - Design phase: human actively participates (Feature Designer)
   - Plan phase: human reviews strategy BEFORE build starts
   - Build/Validate: autonomous, no intervention unless escalation
   - Strategy documented in specs for permanent reference

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

**Validation:**
- validate, verification, spec vs code, divergence
- pending-validations, checklist, semantic inference
- corrective tasks, attempt tracking, escalation
- two-pass, parallel tasks, deduplication

**Design & Specs:**
- feature design, interactive, AskUserQuestion
- critical thinking, YAGNI, simplicity, trade-offs
- coherence validation, spec creation, crystallization

**Export & Installation:**
- export, install, bootstrap, setup, template
- preset, conflict resolution, dry-run
- component sharing, project initialization
- dependency verification, quick start

**Learning & Analysis:**
- post-mortem, lessons learned, autonomous learning
- session analysis, log analysis, error detection
- inefficiency detection, pruning, knowledge persistence
- structured lessons, semantic analysis

**Strategy & Human Oversight:**
- strategy investigation, trade-offs, approach evaluation
- human on the loop, human supervision, review window
- pattern analysis, library verification, implementation decision
- selected implementation strategy, approaches considered

---

**Last Updated:** 2026-01-29 (added compound-architecture-system spec)
**Project:** loopy-claude

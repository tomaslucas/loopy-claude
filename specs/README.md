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

| Spec | Code | Purpose |
|------|------|---------|
| *(none - all specs validated and archived)* | | |

---

## Archived Knowledge

Validated and frozen specs. **Do NOT read these files** — use the decision summary below.

| Feature | Decision/Trade-off | Archived |
|---------|-------------------|----------|
| Loop Orchestrator | Bash simplicity (~150 lines) over Python flexibility; 5 stop conditions | [loop-orchestrator-system.md](archive/loop-orchestrator-system.md) |
| CLI Agnostic | External JSON config for multi-agent support; no auto-fallback between agents | [cli-agnostic-system.md](archive/cli-agnostic-system.md) |
| Plan System | 5-phase workflow; specs describe WHAT, plan describes HOW; git log > README for truth | [prompt-plan-system.md](archive/prompt-plan-system.md) |
| Build System | Mandatory 6-step verification; 3-attempt fix loop; no placeholders allowed | [prompt-build-system.md](archive/prompt-build-system.md) |
| Validate System | Two-pass verification (checklist + semantic); spec is immutable source of truth | [prompt-validate-system.md](archive/prompt-validate-system.md) |
| Reverse Engineering | READ-ONLY guarantee; 3-phase batch processing; JSON intermediates for context | [prompt-reverse-system.md](archive/prompt-reverse-system.md) |
| Feature Designer | Continuous AskUserQuestion loop; specs WITHOUT implementation checklists | [feature-designer-skill.md](archive/feature-designer-skill.md) |
| Export System | Preset configurations (full/minimal/design/devtools); interactive conflict resolution | [export-loopy-system.md](archive/export-loopy-system.md) |
| Structure Reorganization | Claude Code alignment (.claude/commands/); work mode for automated cycles | [structure-reorganization-system.md](archive/structure-reorganization-system.md) |
| Post-Mortem | Operational patterns only (not product); 20 items max per section with semantic pruning | [post-mortem-system.md](archive/post-mortem-system.md) |
| Audit System | READ-ONLY holistic analysis; cross-spec divergence detection; opus model | [audit-system.md](archive/audit-system.md) |
| Reconcile System | Human decision gate (fix code vs update spec); post-escalation workflow | [reconcile-system.md](archive/reconcile-system.md) |
| Dependency Check | Fail fast on missing critical deps; graceful jq fallback; cross-platform | [dependency-check-system.md](archive/dependency-check-system.md) |
| Done Tracking | Append-only done.md; one-line per task; zero plan.md impact | [done-tracking-system.md](archive/done-tracking-system.md) |
| Strategy Investigation | Human on the loop model; 3-approach trade-off before autonomous build | [strategy-investigation-system.md](archive/strategy-investigation-system.md) |
| Compound Architecture | Single mega-spec for coherent evolution; VDD for infrastructure; JSON telemetry | [compound-architecture-system.md](archive/compound-architecture-system.md) |

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

**Last Updated:** 2026-01-29 (archived all validated specs)
**Project:** loopy-claude

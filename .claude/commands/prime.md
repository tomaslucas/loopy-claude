---
name: prime
description: Gain understanding of the repository structure and philosophy before working
---


# Prime

Execute the `Workflow` and `Report` sections to understand the codebase and the philosofy of the repository, then summarize your understanding.

## Workflow

- Run `git ls-files` to list all files in the repository.
- Study `specs/README.md` for an overview of the project.

## Human Participation Model

This system uses **"human on the loop"** (supervision), NOT "human in the loop" (active participation in every step).

| Phase | Human Role | Mechanism |
|-------|------------|-----------|
| **Design** (Feature Designer) | Active participation | AskUserQuestion loops |
| **Plan** | Review & approve | Human reviews plan.md + strategies BEFORE build |
| **Build/Validate** | Autonomous | No intervention unless escalation (3 failures) |
| **Bug** | Provide context | Human reports bug, may redirect LLM's proposed fix |

**Key insight:** The human's window for intervention is **between /plan and /build**, not during execution. Once approved, the loop runs autonomously until completion or escalation.

---

## Report

Summarize your understanding of the repository.

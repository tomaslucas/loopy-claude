# Loopy-claude

Simple loop-based autonomous coding system. Design specs, generate plans, build code.

---

## What is Loopy-claude?

Loopy is a minimal orchestrator that feeds prompts to Claude Code, managing iterations, stop conditions, and progress commits. It's built on radical simplicity: no abstraction layers, no magic, just transparent bash scripts and well-crafted prompts.

**Philosophy:** Simple is better than clever. Direct is better than abstracted. Debuggable is better than magical.

---

## Quick Start

### Installation

```bash
# Clone repository
git clone <your-repo-url>
cd loopy-claude

# Make scripts executable
chmod +x loop.sh analyze-session.sh
```

### Basic Usage

```bash
# 1. Design features (optional, interactive)
claude
> /feature-designer
> [conversational design session]
> crystallize

# 2. Generate plan from specs
./loop.sh plan 5

# 3. Review plan
cat plan.md

# 4. Build (execute tasks)
./loop.sh build 10

# 5. Analyze session (optional)
./analyze-session.sh
```

---

## How It Works

### Workflow

```
Design (optional)
    ↓ via feature-designer skill
specs/*.md created
    ↓
./loop.sh plan
    ↓ reads specs, analyzes gaps, creates tasks
plan.md generated
    ↓
./loop.sh build
    ↓ executes tasks, verifies, commits
Code implemented
    ↓
Git commits + push
```

### Core Components

**1. Prompts** (`prompts/`)
- `plan.md` - Intelligent plan generator (5 phases, extended thinking)
- `build.md` - Task executor with mandatory verification
- `reverse.md` - Legacy code analyzer (generates specs from code)

**2. Orchestrator** (`loop.sh`)
- Simple bash loop
- 4 stop conditions (max iterations, empty plan, rate limit, completion signal)
- Session logging to `logs/`
- Model selection (opus for plan/reverse, sonnet for build)

**3. Analyzer** (`analyze-session.sh`)
- Post-mortem analysis of sessions
- Detects errors, warnings, stop conditions
- Contextual recommendations

**4. Specs** (`specs/`)
- Immutable design documents (WHAT to build)
- No implementation checklists (plan generator creates tasks)
- PIN (`specs/README.md`) for quick lookup

---

## Usage Examples

### Example 1: New Feature

```bash
# Design
claude
> I want to design authentication
> [AskUserQuestion loop until solid]
> crystallize as auth-system

# Plan
./loop.sh plan 3
# Generates plan.md with specific, verifiable tasks

# Build
./loop.sh build 10
# Executes tasks, verifies, commits
```

### Example 2: Legacy Codebase

```bash
# Analyze existing code (generates specs)
./loop.sh reverse 10

# Review generated specs
ls specs-reverse/

# Generate plan for improvements
./loop.sh plan 5

# Implement
./loop.sh build 20
```

### Example 3: Model Override

```bash
# Use haiku for cheaper build
./loop.sh build 10 --model haiku

# Force opus for complex task
./loop.sh build 5 --model opus
```

---

## Key Concepts

### Specs Without Checklists

**Traditional approach:**
```markdown
## Implementation Checklist
- [ ] Task 1
- [ ] Task 2
```

**Loopy approach:**
```markdown
## Implementation Guidance
What needs to exist (high-level)
How to verify it works
```

**Why:** Specs describe WHAT (requirements). Plan generator creates HOW (specific tasks).

### Plan Lifecycle

**plan.md only shows pending work:**
- Completed tasks are DELETED (not marked [x])
- History is in git log
- Stop when no `[ ]` tasks remain

**Lifecycle rules:**
- 0% complete → UPDATE (add new tasks)
- 1-79% complete → CLEAN & UPDATE (remove [x], add new)
- 80-100% complete → REGENERATE (commit current, fresh start)

### Reconciliation (Plan Mode)

**Multi-source truth:**
```
git log > README > spec Status
```

Plan generator checks git history first to avoid regenerating already-done work.

### Mandatory Verification (Build Mode)

**6-step workflow:**
1. Read task
2. Research (grep codebase, read spec)
3. Implement
4. **Self-verify** (execute command OR check semantic criteria)
5. Fix if fails (up to 3 attempts)
6. Complete (only when verified)

No task marked complete with failing verification.

---

## Architecture

### Design Decisions

**1. Specs without checklists**
- Specs = immutable design (WHAT)
- Plan generator = intelligent task creator (HOW)
- Separation of concerns

**2. DELETE completed tasks**
- Plan shows only what's LEFT
- History in git (where it belongs)
- Stop condition trivial

**3. Loop without metadata**
- Prompts are plain markdown
- No YAML parsing
- Easy to debug

**4. No AGENTS.md dependency**
- Prompts are self-contained
- All guidance inline
- Portable and autonomous

**5. Reconciliation: git > README**
- Git log is technical truth
- README is human lookup
- No CHANGELOG in plan mode (simpler)

### Stop Conditions

**4 types:**
1. **Max iterations** - Safety limit
2. **Empty plan** - No `[ ]` tasks (build mode)
3. **Rate limit** - API quota exhausted
4. **Completion signal** - `<promise>COMPLETE</promise>`

### Model Selection

```bash
plan    → opus     # extended_thinking needed
reverse → opus     # JTBD inference + grouping
build   → sonnet   # straightforward execution
```

Override: `./loop.sh <mode> <max> --model <model>`

---

## File Structure

```
loopy-claude/
├── loop.sh                  # Main orchestrator
├── analyze-session.sh       # Session analyzer
├── prompts/
│   ├── plan.md             # 5-phase plan generator
│   ├── build.md            # Verification workflow
│   └── reverse.md          # Legacy analyzer
├── specs/
│   ├── README.md           # PIN (lookup table)
│   └── *.md                # Specifications
├── plan.md                 # Generated plan (mutable)
├── logs/                   # Session logs (gitignored)
├── .claude/
│   └── skills/
│       └── feature-designer/  # Interactive spec creator
└── README.md               # This file
```

---

## Configuration

### Defaults

- **Mode:** build
- **Max iterations:** 1 (safe default)
- **Model:** opus (plan/reverse), sonnet (build)

### Environment Variables

```bash
# Override model
LOOPY_MODEL=haiku ./loop.sh build 10
```

### .gitignore

```
logs/
*.log
plan.md.completed-*
reverse-analysis/
specs-reverse/
```

---

## Troubleshooting

### Common Issues

**Loop stops immediately:**
```bash
# Check if plan has pending tasks
grep '- \[ \]' plan.md

# If empty, regenerate plan
./loop.sh plan 5
```

**Rate limit hit:**
```bash
# Wait 10-15 minutes
# Or use cheaper model
./loop.sh build 10 --model haiku
```

**High token usage:**
```bash
# Analyze session
./analyze-session.sh

# Check for:
# - Excessive subagent usage
# - Large file reads
# - Unnecessary exploration
```

**Verification failures:**
```bash
# Check recent log
tail -100 logs/log-build-<timestamp>.txt

# Look for "Verify:" failures
# Agent will attempt up to 3 fixes
```

---

## Comparison to Other Tools

### vs Traditional Ralph Wiggum

**Similarities:**
- Spec → Plan → Build workflow
- Claude Code integration
- Git automation

**Differences:**
- ✅ Radical simplicity (no multi-CLI abstraction)
- ✅ Specs without checklists (intelligent plan generator)
- ✅ DELETE completed tasks (not mark [x])
- ✅ No AGENTS.md (self-contained prompts)
- ✅ Single focus (Claude Code only)

### vs Manual Development

**Loopy advantages:**
- Consistent verification workflow
- Git discipline enforced
- Session logging for debugging
- Context-aware task sizing

**Manual advantages:**
- Full control over approach
- No token costs
- Immediate feedback

**Best of both:**
- Use loopy for repetitive tasks
- Use manual for creative work
- Use feature-designer skill to bridge (interactive design)

---

## Philosophy

### Simplicity

> "Simple is better than clever. Direct is better than abstracted. Debuggable is better than magical."

- Loop is ~180 lines bash
- Prompts are plain markdown
- No hidden complexity

### Transparency

- All logs saved (`logs/`)
- All prompts readable (`prompts/`)
- All specs version-controlled (`specs/`)
- Nothing hidden

### Focus

- Claude Code only (no multi-CLI complexity)
- Task execution only (no IDE integration)
- Autonomous operation (no interactive prompts)

### Discipline

- Mandatory verification (no skipping)
- Complete implementation (no TODOs/placeholders)
- Git commits enforced
- DELETE completed tasks (clean plan)

---

## Inspiration

**Inspired by:**
- [Ralph Playbook](https://github.com/ghuntley/how-to-ralph-wiggum) by Geoffrey Huntley
- [snarktank/ralph](https://github.com/snarktank/ralph) by Ryan Carson

**Key insight from Huntley:** The simplest loop that works is often the best.

**Our evolution:** Radical simplification + intelligent prompts + mandatory verification.

---

## Contributing

Loopy is designed to be forkable and hackable:

1. **Fork the repo**
2. **Modify prompts** (`prompts/*.md`) - they're just markdown
3. **Test your changes** - run loop.sh locally
4. **Share improvements** - PRs welcome

**Areas for contribution:**
- Prompt improvements (better verification strategies)
- Additional skills (beyond feature-designer)
- Documentation (more examples)
- Bug fixes

---

## License

[Specify your license]

---

## FAQ

**Q: Why Claude Code only?**
A: Simplicity. Supporting multiple CLIs adds 10x complexity for marginal benefit. Fork and adapt if you need others.

**Q: Why delete completed tasks instead of marking [x]?**
A: Plan shows only what's LEFT to do. History is in git. Cleaner, more focused.

**Q: Why opus for plan mode?**
A: Plan generation needs `<extended_thinking>` for strategic analysis, task grouping, context budgeting. Opus handles this better.

**Q: Can I run without feature-designer skill?**
A: Yes. Skill is optional. Create specs manually using the template in `specs/`.

**Q: How do I add a new mode?**
A: 1) Create `prompts/newmode.md`, 2) Test with `./loop.sh newmode 1`, 3) Done. Loop is mode-agnostic.

**Q: What if I want different stop conditions?**
A: Edit `loop.sh` directly. It's simple bash, easy to customize.

---

**Version:** 1.0
**Last Updated:** 2026-01-24

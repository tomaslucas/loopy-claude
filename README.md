# Loopy-claude

Simple loop-based autonomous coding system. Design specs, generate plans, build code.

> **Note:**
> This is a personal research project exploring how minimal an autonomous coding orchestrator can be.
> **Use at your own risk. Provided "AS IS" without warranties of any kind** (see [LICENSE](LICENSE)).
>
> The name "loopy-claude" is inspired by Geoffrey Huntley's "Ralph Wiggum" project and Anthropic's "Claude Code."
> **This is an independent, unofficial project with no affiliation or endorsement from Anthropic or any other entity.**

---

## What is Loopy-claude?

Loopy is a minimal orchestrator that feeds prompts to AI agents (Claude Code, Copilot, or others), managing iterations, stop conditions, and progress commits. It's built on radical simplicity: no abstraction layers, no magic, just transparent bash scripts and well-crafted prompts.

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
./loop.sh plan

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
specs/*.md created (📋 Planned)
    ↓
./loop.sh plan
    ↓ reads specs, analyzes gaps, creates tasks
    ↓ updates specs/README.md (📋→⏳)
plan.md generated
    ↓
./loop.sh build
    ↓ executes tasks, verifies, commits
    ↓ adds completed specs to pending-validations.md
Code implemented
    ↓
./loop.sh validate
    ↓ compares implementation vs spec
    ↓ if divergences → creates corrective tasks in plan.md
    ↓ if passes → updates specs/README.md (⏳→✅)
    ↓
    ├─→ PASS: spec validated, removed from pending-validations
    │
    └─→ FAIL: back to plan → build → validate (max 3 attempts)

After plan/build/validate/reverse/work completes:
    ↓ auto-trigger
./loop.sh post-mortem 1
    ↓ analyzes session logs
    ↓ extracts errors and inefficiencies
    ↓ updates lessons-learned.md
    ↓
lessons-learned.md (persistent knowledge for future sessions)
```

### Core Components

**1. Commands** (`.claude/commands/`)
- `plan.md` - Intelligent plan generator (5 phases, extended thinking)
- `build.md` - Task executor with mandatory verification
- `validate.md` - Post-implementation validator (spec vs code)
- `reverse.md` - Legacy code analyzer (generates specs from code)
- `work.md` - Automated build→validate cycles (virtual mode, no prompt file)
- `audit.md` - Repository audit for spec compliance (READ-ONLY, generates reports)
- `prime.md` - Repository orientation guide
- `bug.md` - Bug analysis and corrective task creation
- `post-mortem.md` - Autonomous learning from session logs (auto-triggered)

**2. Agents** (`.claude/agents/`)
- `spec-checker.md` - Mechanical checklist verification
- `spec-inferencer.md` - Semantic behavior inference
- Used by validate command for parallel verification

**3. Orchestrator** (`loop.sh`)
- ~470 lines bash (includes multi-agent support and work mode)
- 5 stop conditions (max iterations, empty plan, empty pending-validations, rate limit, completion signal)
- Session logging to `logs/`
- Model selection (opus for plan/reverse/audit, sonnet for build/validate/post-mortem)
- Work mode: automated build→validate cycles with smart iteration calculation
- Multi-agent support (Claude Code, Copilot CLI via `loopy.config.json`)

**4. Analyzer** (`analyze-session.sh`)
- Post-mortem analysis of sessions
- Detects errors, warnings, stop conditions
- Contextual recommendations

**5. Learning System** (`post-mortem.md` + `lessons-learned.md`)
- Autonomous learning from execution logs
- Extracts errors and inefficiencies after each session
- Persists structured lessons (what to avoid, what to use, why)
- Auto-triggers after productive modes (plan/build/validate/reverse/work)
- Max 20 lessons per mode, semantic pruning when full
- `lessons-learned.md` auto-created on first post-mortem run

**6. Specs** (`specs/`)
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
./loop.sh plan
# Generates plan.md with specific, verifiable tasks
# Plan completes in 1 iteration (signals COMPLETE)

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
./loop.sh plan

# Implement
./loop.sh build 20
```

### Example 3: Work Mode (Automated Build→Validate)

```bash
# Smart iteration calculation (recommended)
./loop.sh work
# Calculates: (pending_tasks + pending_validations) × 2

# Manual iteration limit
./loop.sh work 50

# The 2× multiplier accounts for corrective tasks that validations may generate
# Loop exits naturally when no pending work remains
```

### Example 4: Model Override

```bash
# Use haiku for cheaper build
./loop.sh build 10 --model haiku

# Force opus for complex task
./loop.sh build 5 --model opus
```

### Example 5: Using Different Agents

```bash
# Use Claude Code (default)
./loop.sh plan

# Use Copilot
./loop.sh plan --agent copilot

# Use Copilot with specific model
./loop.sh build 10 --agent copilot --model sonnet
```

### Example 6: Audit Repository

```bash
# Full repository audit (compares all specs vs implementation)
./loop.sh audit

# Review generated report
cat audits/audit-2026-01-26-14-40.md

# Report is auto-committed to git

# When to use:
# - Periodic maintenance (monthly/quarterly)
# - Before major releases
# - After significant refactoring
# - To detect spec drift or systemic issues

# Audit vs Validate:
# - audit: READ-ONLY, holistic analysis of ALL specs
# - validate: ONE spec at a time, can fix divergences
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

**3. Simple YAML frontmatter**
- Commands have minimal frontmatter (name, description)
- Filtered by loop.sh before execution
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

**5 types:**
1. **Max iterations** - Safety limit
2. **Empty plan** - No `[ ]` tasks (build mode)
3. **Empty pending-validations** - No specs to validate (validate mode)
4. **Rate limit** - API quota exhausted
5. **Completion signal** - `<promise>COMPLETE</promise>`

### Model Selection

```bash
plan        → opus     # extended_thinking needed for strategic planning
reverse     → opus     # JTBD inference + strategic grouping
audit       → opus     # deep reasoning, cross-spec analysis, nuanced judgment
validate    → sonnet   # orchestrates parallel validation agents
build       → sonnet   # straightforward execution
post-mortem → sonnet   # log analysis and extraction
work        → sonnet   # alternates build/validate (both use sonnet)
```

Override: `./loop.sh <mode> <max> --model <model>`

---

## File Structure

```
loopy-claude/
├── loop.sh                  # Main orchestrator (~470 lines)
├── analyze-session.sh       # Session analyzer
├── export-loopy.sh          # Component export script
├── .claude/
│   ├── commands/            # Command prompts (main location)
│   │   ├── plan.md         # 5-phase plan generator
│   │   ├── build.md        # Verification workflow
│   │   ├── validate.md     # Post-implementation validator
│   │   ├── reverse.md      # Legacy analyzer
│   │   ├── audit.md        # Repository audit (READ-ONLY)
│   │   ├── prime.md        # Repository orientation
│   │   ├── bug.md          # Bug analysis and task creation
│   │   └── post-mortem.md  # Autonomous learning from logs
│   ├── agents/             # Reusable validation agents
│   │   ├── spec-checker.md    # Mechanical checklist verification
│   │   └── spec-inferencer.md # Semantic behavior inference
│   └── skills/
│       └── feature-designer/  # Interactive spec creator
├── prompts/                 # Backward compatibility symlinks to .claude/commands/
│   ├── plan.md → ../.claude/commands/plan.md
│   ├── build.md → ../.claude/commands/build.md
│   ├── validate.md → ../.claude/commands/validate.md
│   ├── reverse.md → ../.claude/commands/reverse.md
│   ├── audit.md → ../.claude/commands/audit.md
│   ├── prime.md → ../.claude/commands/prime.md
│   ├── bug.md → ../.claude/commands/bug.md
│   └── post-mortem.md → ../.claude/commands/post-mortem.md
├── pending-validations.md  # Queue of specs awaiting validation
├── lessons-learned.md      # Persistent knowledge (auto-created on first use)
├── specs/
│   ├── README.md           # PIN (lookup table)
│   └── *.md                # Specifications
├── audits/                 # Audit reports (auto-committed)
│   └── audit-*.md          # Timestamped audit reports
├── plan.md                 # Generated plan (mutable)
├── loopy.config.json       # Agent configurations
├── logs/                   # Session logs (gitignored)
└── README.md               # This file
```

---

## Configuration

### Defaults

- **Mode:** build
- **Max iterations:** 1 (safe default)
- **Model:** opus (plan/reverse), sonnet (build)
- **Agent:** claude (default, configurable)

### Agent Configuration

Agents are configured in `loopy.config.json`:

```json
{
  "default": "claude",
  "agents": {
    "claude": {
      "command": "claude",
      "promptFlag": "-p",
      "modelFlag": "--model",
      "models": { "opus": "opus", "sonnet": "sonnet", "haiku": "haiku" },
      "extraArgs": "--dangerously-skip-permissions --output-format=stream-json --verbose",
      "outputFormat": "stream-json",
      "rateLimitPattern": "rate_limit_error|overloaded_error|quota.*exhausted"
    },
    "copilot": {
      "command": "copilot",
      "promptFlag": "-p",
      "modelFlag": "--model",
      "models": { "opus": "claude-opus-4.5", "sonnet": "claude-sonnet-4.5", "haiku": "claude-haiku-4.5" },
      "extraArgs": "--allow-all-tools -s",
      "outputFormat": "text",
      "rateLimitPattern": "rate.?limit|quota|too many requests"
    }
  }
}
```

**Configuration fields:**
- `command`: CLI executable name
- `promptFlag`: Flag for prompt input (-p for both)
- `modelFlag`: Flag for model selection (--model for both)
- `models`: Logical name → agent-specific model mapping
- `extraArgs`: Additional flags passed to agent
- `outputFormat`: "stream-json" (Claude) or "text" (Copilot) - affects rate limit detection
- `rateLimitPattern`: Regex pattern for detecting rate limit errors in output

Select agent via flag or environment variable:

```bash
# Via flag (highest priority)
./loop.sh plan --agent copilot

# Via environment variable
LOOPY_AGENT=copilot ./loop.sh plan

# Resolution order: --agent flag > LOOPY_AGENT env > config default > "claude"
```

### Environment Variables

```bash
# Override agent
LOOPY_AGENT=copilot ./loop.sh build 10

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
./loop.sh plan
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
- ✅ Radical simplicity (config-based multi-agent, not code changes)
- ✅ Specs without checklists (intelligent plan generator)
- ✅ DELETE completed tasks (not mark [x])
- ✅ No AGENTS.md (self-contained prompts)
- ✅ Extensible via `loopy.config.json`

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

- Loop is ~470 lines bash (includes multi-agent support, work mode, configuration system)
- Prompts are plain markdown with YAML frontmatter
- No hidden complexity, no magic

### Transparency

- All logs saved (`logs/`)
- All commands readable (`.claude/commands/`)
- All specs version-controlled (`specs/`)
- Nothing hidden

### Focus

- Default to Claude Code, extensible to other agents via `loopy.config.json`
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

Loopy is my onw personal project. Feel free to fork and modify as you see fit.
I don't currently accept external contributions.

---

## License

MIT License. See `LICENSE` file for details.

---

## Security

### Security Posture

Loopy-claude follows a "simple and transparent" security model:

- **No Secret Management**: API keys provided via environment variables only (never stored)
- **Limited Blast Radius**: Each mode operates with focused permissions
- **Human in the Loop**: Destructive operations require explicit approval
- **Auditable Execution**: All actions logged to `.claude/sessions/` for review
- **No Auto-Update**: No telemetry, no automatic updates, no hidden behavior

### Reporting Security Vulnerabilities

Found a security issue? Please report it via [GitHub Issues](https://github.com/tomaslucas/loopy-claude/issues). See [SECURITY.md](SECURITY.md) for full details on scope, out-of-scope items, and reporting guidelines.

### Safe Usage

To use loopy-claude safely:

1. **Protect API Keys**: Never commit `ANTHROPIC_API_KEY` to version control
2. **Review Generated Code**: Always review before committing or deploying
3. **Test in Isolation**: Use development environments first
4. **Keep Dependencies Updated**: Regularly update Anthropic SDK
5. **Review Session Logs**: Check logs in `.claude/sessions/` for unexpected behavior

### What We Don't Do

Intentionally absent for simplicity:
- Automatic dependency updates
- Complex CI/CD pipelines
- Binary distribution or auto-update mechanisms
- Telemetry or analytics
- Built-in credential storage

### Before Making Public

If you fork this repository and plan to make it public, see [.github/SECURITY_CHECKLIST.md](.github/SECURITY_CHECKLIST.md) for a comprehensive security verification checklist.

---

## FAQ

**Q: Can I use other AI agents besides Claude Code?**
A: Yes. Use `--agent copilot` flag or set `LOOPY_AGENT=copilot`. Configure agents in `loopy.config.json`. Default is Claude Code for backward compatibility.

**Q: Why delete completed tasks instead of marking [x]?**
A: Plan shows only what's LEFT to do. History is in git. Cleaner, more focused.

**Q: Why opus for plan mode?**
A: Plan generation needs `<extended_thinking>` for strategic analysis, task grouping, context budgeting. Opus handles this better.

**Q: Why opus for audit mode?**
A: Audit requires deep reasoning, cross-spec analysis, and nuanced judgment about spec compliance. Sonnet excels at execution but opus handles complex comparative analysis better.

**Q: Why opus for reverse mode?**
A: Reverse engineering requires JTBD (Jobs To Be Done) inference from code behavior and strategic grouping of findings. This needs opus-level reasoning.

**Q: Can I run without feature-designer skill?**
A: Yes. Skill is optional. Create specs manually using the template in `specs/`.

**Q: How do I add a new mode?**
A: 1) Create `.claude/commands/newmode.md` with frontmatter, 2) Test with `./loop.sh newmode 1`, 3) Done. Loop is mode-agnostic.

**Q: What if I want different stop conditions?**
A: Edit `loop.sh` directly. It's simple bash, easy to customize.

**Q: How does work mode calculate max iterations?**
A: If you don't specify max iterations, work mode calculates: `(pending_tasks + pending_validations) × 2`. The 2× multiplier is a safety margin for corrective tasks that validations may generate. The loop exits naturally when no pending work remains.

**Q: What's the difference between audit and validate?**
A:
- **audit**: READ-ONLY holistic analysis of ALL specs vs implementation. Generates report in `audits/`. Use for periodic maintenance.
- **validate**: Validates ONE spec at a time from `pending-validations.md`. Can generate corrective tasks. Part of build→validate workflow.

---

**Version:** 1.2
**Last Updated:** 2026-01-26
**Changes:** Updated documentation to reflect current codebase (audit mode, work mode details, configuration fields, accurate line counts)

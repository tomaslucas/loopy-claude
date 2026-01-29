# Reconcile System

> Structured workflow for resolving escalated spec-code divergences that require human decision

## Status: Draft

---

## 1. Overview

### Purpose

After validation escalates (3 failed attempts), there's currently no structured path forward. The human must manually investigate, decide whether the spec or code is "right", and make corrections. This system provides a guided workflow for that decision.

### Goals

- Structured extraction of divergence evidence from escalated specs
- Clear presentation of "change code" vs "change spec" options
- Human decision gate before any spec modification
- Audit trail of reconciliation decisions
- Integration with existing validate → build cycle

### Non-Goals

- Automatic spec modification (always requires human approval)
- AI deciding which is "correct" (human decides)
- Replacing the escalation mechanism (this is post-escalation)
- Handling non-escalated validation failures

---

## 2. Architecture

### Flow

```
pending-validations.md contains ESCALATE entry
    ↓
Human runs: ./loop.sh reconcile
    ↓
reconcile.md prompt executes
    ↓
Read escalated spec + implementation code
    ↓
Generate structured divergence report
    ↓
Present options via AskUserQuestion:
  A) Change code (generate corrective tasks)
  B) Change spec (propose spec edits)
  C) Skip (leave for later)
  + Strategy divergence options (E/F/G) when applicable
    ↓
If A: Add tasks to plan.md, remove from pending-validations
If B: Apply spec edits, remove from pending-validations
If C: Leave entry, continue to next escalation
    ↓
Commit changes
```

### Components

```
loop.sh
├── Existing modes
└── NEW: reconcile mode (model: opus)

.claude/commands/
└── NEW: reconcile.md

pending-validations.md
├── Normal entries: - [ ] specs/foo.md
└── Escalated entries: - [ ] specs/foo.md (attempt: 3/3 - ESCALATE)
```

### Dependencies

| Component | Purpose | Location |
|-----------|---------|----------|
| loop.sh | Orchestrator, adds reconcile mode | Project root |
| reconcile.md | Reconciliation prompt | .claude/commands/ |
| pending-validations.md | Source of escalated specs | Project root |
| AskUserQuestion | Human decision gate | Claude tool |

---

## 3. Implementation Details

### 3.1 Escalation Detection

Reconcile mode identifies escalated specs by pattern:

```bash
grep -E '\(attempt: 3/3.*ESCALATE\)' pending-validations.md
```

If no escalations found, output message and complete immediately.

### 3.2 Divergence Report Structure

For each escalated spec, generate:

```markdown
## Divergence Report: {spec-name}

### Spec Requirements (source of truth)
- Requirement 1: {description}
- Requirement 2: {description}
...

### Current Implementation
- File: {path} - {what it does}
- File: {path} - {what it does}
...

### Divergences Detected
1. **{divergence title}**
   - Spec says: {requirement}
   - Code does: {actual behavior}
   - Evidence: {file:line or grep result}

2. **{divergence title}**
   ...

### Analysis
- Likely cause: {hypothesis}
- Complexity to fix code: {low/medium/high}
- Complexity to update spec: {low/medium/high}
```

### 3.3 Decision Options

Present via AskUserQuestion:

```
Spec: {spec-name}
Divergences: {count}

How should we resolve this?

○ A) Fix the code to match spec
   - Will generate {N} corrective tasks in plan.md
   - Spec remains unchanged (source of truth)

○ B) Update the spec to match code
   - Will propose spec edits for your review
   - Code is considered correct as-is

○ C) Skip for now
   - Leave escalation in pending-validations.md
   - Address in a future session

○ D) View detailed divergence report
   - Show full analysis before deciding
```

### 3.4 Option A: Fix Code

1. Generate specific, verifiable tasks in plan.md
2. Remove escalation entry from pending-validations.md
3. Add fresh validation entry: `- [ ] specs/{name}.md`
4. Commit changes

### 3.5 Option B: Update Spec

1. Generate proposed spec edits (show diff preview)
2. Ask for confirmation before applying
3. Apply edits to spec file
4. Add migration note to spec's Notes section:
   ```markdown
   ## Notes
   
   ### Reconciliation History
   - **{DATE}**: Reconciled divergence - {brief description}
     - Decision: Spec updated to match implementation
     - Reason: {user's stated reason or "per user decision"}
   ```
4. Remove escalation entry from pending-validations.md
5. Update specs/README.md status if needed
6. Commit changes

### 3.6 Option C: Skip

1. Leave entry unchanged in pending-validations.md
2. Proceed to next escalation (if any)
3. Log that spec was skipped

### 3.7 Multiple Escalations

If multiple specs are escalated:
- Process one at a time
- After each decision, ask: "Continue to next escalation? (Y/n)"
- Allow early exit

---

## 4. API / Interface

### 4.1 New Mode

```bash
./loop.sh reconcile [max_iterations] [--agent AGENT] [--model MODEL]
```

- **Model:** opus by default (needs reasoning for divergence analysis)
- **Default iterations:** 1
- **Prompt:** `.claude/commands/reconcile.md`

### 4.2 Integration Points

**Triggered after:**
- Work mode exits with ESCALATE
- Manual run when escalations exist

**Affects:**
- pending-validations.md (removes resolved escalations)
- plan.md (if Option A chosen)
- specs/*.md (if Option B chosen)
- specs/README.md (status updates)

---

## 5. Testing Strategy

### Manual Tests

1. **Basic flow:**
   - Manually add escalated entry to pending-validations.md
   - Run `./loop.sh reconcile`
   - Verify divergence report generated
   - Test each option (A, B, C)

2. **No escalations:**
   - Ensure pending-validations.md has no ESCALATE entries
   - Run reconcile
   - Verify graceful exit with message

3. **Multiple escalations:**
   - Add 2-3 escalated entries
   - Verify sequential processing
   - Test early exit

4. **Spec update safety:**
   - Choose Option B
   - Verify diff preview shown before changes
   - Verify migration note added

---

## 6. Acceptance Criteria

- [ ] Reconcile mode exists and executes with opus
- [ ] Detects escalated entries in pending-validations.md
- [ ] Generates structured divergence report
- [ ] Presents A/B/C/D options via AskUserQuestion
- [ ] Option A: generates corrective tasks, resets validation
- [ ] Option B: shows diff preview, requires confirmation, adds migration note
- [ ] Option C: skips without changes
- [ ] Multiple escalations processed sequentially
- [ ] Graceful handling when no escalations exist
- [ ] All changes committed with clear message

---

## 7. Implementation Guidance

### Impact Analysis

**Change Type:** [x] New Feature

**Affected Areas:**

Files to create:
- `.claude/commands/reconcile.md` (new prompt)

Files to modify:
- `loop.sh` (~5 lines: model case for reconcile)
- `specs/README.md` (add reconcile-system.md entry)

### Verification Strategy

```bash
# Verify mode exists
./loop.sh reconcile --help 2>&1 | grep -q reconcile

# Verify model selection
grep -A2 'reconcile)' loop.sh | grep -q opus

# Verify prompt exists
test -f .claude/commands/reconcile.md
```

---

## 8. Notes

### Why Human Decision Required?

The "spec vs code" question is fundamentally a design decision:
- Spec might be outdated (code evolved, spec didn't)
- Code might be wrong (implementation bug)
- Both might be partially right (spec ambiguous)

Only a human can make this judgment with full context.

### Why Opus?

Reconcile requires:
- Deep code analysis to understand actual behavior
- Spec interpretation to understand intent
- Divergence synthesis to explain the gap
- Option generation with complexity estimates

This is reasoning-heavy work suited to opus.

### Relationship to Audit

Audit is periodic health check (read-only, holistic view).
Reconcile is targeted intervention (interactive, one spec at a time).

They're complementary:
- Audit might identify specs that need reconciliation
- Reconcile is how you act on individual escalations

---

**Related specs:**
- `prompt-validate-system.md` — Creates escalations
- `loop-orchestrator-system.md` — Adds reconcile mode
- `audit-system.md` — Complementary holistic check

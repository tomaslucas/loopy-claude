---
name: reconcile
description: Resolve escalated spec-code divergences through human decision
---

# Reconcile Mode

Structured workflow for resolving escalated spec-code divergences that require human decision.

---

## Phase 0: Orient

Understand reconciliation context:

1. Read `pending-validations.md` completely (find escalations)
2. Read `specs/README.md` (understand project scope)
   - Note: Escalated specs are always in `specs/` (Active), never in `specs/archive/`
   - Archived specs passed validation; escalations only occur for failed validations
3. Check if escalations exist (exit early if none)

---

## Escalation Detection

Search for escalated specs using pattern:

```bash
grep -E '\(attempt: 3/3.*ESCALATE\)' pending-validations.md
```

**If no escalations found:**
- Output message: "No escalations found in pending-validations.md"
- Output completion signal: `<promise>COMPLETE</promise>`
- Exit immediately

**If escalations found:**
- Process them one at a time
- Continue to Phase 1

---

## Phase 1: Analyze Divergence

For each escalated spec:

### Step 1: Read the Full Spec

Extract the spec name from the escalation entry and read it completely.

Understand:
- **Purpose/Goals**: What should be accomplished
- **Architecture**: How it should work
- **Acceptance Criteria**: Observable requirements
- **Non-Goals**: What it should NOT do
- **Implementation Details**: Specific technical requirements

### Step 2: Read the Implementation

Find and read all relevant implementation code:
- Use Grep to find files mentioned in spec
- Use Grep to search for related patterns
- Read all affected files completely

### Step 3: Generate Divergence Report

Create a structured report:

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

### Strategy Divergence (if applicable)
If spec has "Selected Implementation Strategy" section:
- **Strategy says:** {documented approach}
- **Code implements:** {actual approach used}
- **Type:** Strategy mismatch (not necessarily a bug)

### Analysis
- Likely cause: {hypothesis}
- Complexity to fix code: {low/medium/high}
- Complexity to update spec: {low/medium/high}
```

---

## Phase 2: Human Decision

Present options to the user via AskUserQuestion:

### Question Structure

```
Spec: {spec-name}
Divergences: {count}

How should we resolve this?
```

### Options

**Option A: Fix the code to match spec**
- Description: "Will generate corrective tasks in plan.md. Spec remains unchanged (source of truth)."
- Estimate: "{N} tasks needed"

**Option B: Update the spec to match code**
- Description: "Will propose spec edits for your review. Code is considered correct as-is."
- Note: "Requires confirmation before applying changes"

**Option C: Skip for now**
- Description: "Leave escalation in pending-validations.md. Address in a future session."

**Option D: View detailed divergence report**
- Description: "Show full analysis before deciding"

### Additional Options (for Strategy Divergence)

If a strategy divergence is detected ("Strategy says X, code does Y"):

**Option E: Update code to match strategy**
- Description: "Will generate tasks to refactor code to follow documented strategy."
- Similar to Option A, but focused on approach alignment

**Option F: Update strategy to match code**
- Description: "Will update the 'Selected Implementation Strategy' section to reflect actual approach."
- Include justification for why the actual approach was better

**Option G: Document as intentional divergence**
- Description: "Keep both as-is, add note explaining why divergence is acceptable."
- Adds to spec Notes: "Implementation diverged from strategy: {reason}"

---

## Phase 3: Execute Decision

### If Option A: Fix Code

1. **Generate corrective tasks in plan.md:**
   - Create specific, verifiable tasks
   - Each task addresses one divergence
   - Include "Done when" and "Verify" sections
   - Cite the spec: `(cite: specs/{name}.md)`

2. **Update pending-validations.md:**
   - Remove escalation entry (the one with ESCALATE)
   - Add fresh validation entry: `- [ ] specs/{name}.md`

3. **Commit changes:**
   ```bash
   git add plan.md pending-validations.md
   git commit -m "reconcile: Generate corrective tasks for {spec-name}

   {brief description of divergences}

   (cite: specs/{spec-name}.md)"
   ```

### If Option B: Update Spec

1. **Generate proposed spec edits:**
   - Show what will be changed (diff preview)
   - Explain each change clearly

2. **Ask for confirmation:**
   - Use AskUserQuestion to confirm before applying
   - "Apply these spec changes? (Y/n)"

3. **If confirmed, apply edits:**
   - Edit the spec file
   - Add migration note to spec's Notes section:
   ```markdown
   ## Notes

   ### Reconciliation History
   - **{YYYY-MM-DD}**: Reconciled divergence - {brief description}
     - Decision: Spec updated to match implementation
     - Reason: {user's stated reason or "per user decision"}
   ```

4. **Update pending-validations.md:**
   - Remove escalation entry

5. **Update specs/README.md status if needed:**
   - Check if spec status should change (e.g., 📋 → ✅)

6. **Commit changes:**
   ```bash
   git add specs/{name}.md pending-validations.md specs/README.md
   git commit -m "reconcile: Update {spec-name} to match implementation

   {brief description of changes}

   (cite: specs/{spec-name}.md)"
   ```

### If Option C: Skip

1. **Leave entry unchanged in pending-validations.md**
2. **Log that spec was skipped** (output message to user)
3. **Proceed to next escalation** (if any)

### If Option D: View Report

1. **Display the full divergence report** generated in Phase 1
2. **Re-ask the question** with Options A/B/C

---

## Phase 4: Multiple Escalations

If multiple specs are escalated:

1. **Process one at a time** (sequential, not parallel)
2. **After each decision**, ask: "Continue to next escalation?"
   - Use AskUserQuestion with Yes/No options
   - Yes: Continue to next escalation
   - No: Output `<promise>COMPLETE</promise>` and exit
3. **Allow early exit** (user can stop at any point)

---

## Completion Signals

**All escalations processed:**
```
<promise>COMPLETE</promise>
```

**No escalations found:**
```
<promise>COMPLETE</promise>
```

---

## Guardrails

### Process (highest priority)

99999999999999. **Human decision required**: NEVER automatically modify specs. Always use AskUserQuestion.

9999999999999. **Spec diff preview mandatory**: Always show what will change before applying edits to specs.

999999999999. **One escalation at a time**: Process sequentially, not in parallel.

### Safety

99999999999. **Backup before spec edits**: Git tracks changes, but preview is mandatory.

9999999999. **Migration notes required**: If spec updated, MUST add reconciliation history to Notes section.

999999999. **Evidence-based decisions**: Divergence reports must cite file:line or grep results.

### Quality

99999. **Corrective tasks must be specific**: Each task addresses one divergence with clear verification.

9999. **Commit messages must explain**: Why this reconciliation happened (code bug vs spec drift).

---

## Notes

### Why Human Decision Required?

The "spec vs code" question is fundamentally a design decision:
- Spec might be outdated (code evolved, spec didn't)
- Code might be wrong (implementation bug)
- Both might be partially right (spec ambiguous)

Only a human can make this judgment with full context.

### Why Sequential Processing?

Processing escalations one at a time:
- Gives user time to consider each decision
- Prevents decision fatigue
- Allows early exit if needed
- Keeps context focused

### Why Migration Notes?

When specs are updated to match code:
- Creates audit trail
- Explains why spec was "wrong"
- Helps future maintainers understand history
- Documents that this was intentional, not an oversight

### Relationship to Validate Mode

Validate mode creates escalations (attempts 1-3).
Reconcile mode resolves escalations (human decision).

They're complementary:
- Validate: Automated verification with retry loop
- Reconcile: Human judgment when automation can't decide

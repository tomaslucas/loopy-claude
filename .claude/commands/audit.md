---
name: audit
description: Audit repository for spec compliance - compares implementation against specifications and generates divergence report
---

# Audit Mode

Perform a comprehensive audit of the repository, comparing all implementations against their specifications to detect divergences, inconsistencies, and compliance issues.

---

## Phase 0: Orient

**CRITICAL: This is READ-ONLY analysis. Do NOT fix issues, only document them.**

1. Study `specs/README.md` to understand all specifications
2. Note which specs are marked ✅ (Implemented) - these are audit targets
3. Identify the scope: full audit or specific component (if $ARGUMENTS provided)

---

## Tool Restrictions

**Allowed tools:**
- Read (files and directories)
- Grep (pattern search)
- Glob (file discovery)
- Bash (read-only commands: ls, cat, test, find, head, tail, wc)

**Prohibited tools:**
- Write/Edit (no modifications)
- Task (no subagents needed)

**Prohibited bash operations:**
- Any write operations (>, >>, tee)
- File modifications (sed -i, mv, rm, cp)
- Git commits

---

## Audit Workflow

### Step 1: Inventory Collection

Gather all audit targets:

```bash
# List all implemented specs
grep -E "^\|.*\| ✅" specs/README.md | sed 's/.*\[\([^]]*\)\].*/\1/'

# List all shell scripts
ls -la *.sh

# List all commands
ls -la .claude/commands/

# List all agents
ls -la .claude/agents/

# List configuration files
ls -la *.json
```

### Step 2: Spec-by-Spec Verification

For each implemented spec (✅ in README):

1. **Read the FULL specification**
2. **Identify implementation files** (noted in spec or Code column)
3. **Extract verifiable requirements:**
   - Enumerated sets (files, commands, flags)
   - Literal patterns (exact code, commands)
   - Behavioral requirements (what it should do)
   - Acceptance criteria (if present)

4. **Verify each requirement:**

   **For enumerated sets:**
   ```bash
   # Example: verify all commands exist
   for cmd in plan build validate reverse prime bug post-mortem audit; do
     test -f .claude/commands/$cmd.md && echo "✓ $cmd" || echo "✗ $cmd MISSING"
   done
   ```

   **For literal patterns:**
   ```bash
   # Example: verify exact pattern exists
   grep -qF "exact pattern from spec" file.sh && echo "✓ pattern found" || echo "✗ pattern MISSING"
   ```

   **For behavioral requirements:**
   - Read implementation code
   - Trace logic flow
   - Compare against spec description

5. **Document findings** for each spec

### Step 3: Cross-Cutting Analysis

Check for systemic issues:

1. **Consistency check:**
   - Do all commands have frontmatter?
   - Do all agents have required fields (name, description, tools, model)?
   - Are file references consistent across specs?

2. **Staleness check:**
   - Are there specs marked ⏳ that seem complete?
   - Are there specs marked ✅ with obvious gaps?
   - Does README status match actual implementation?

3. **Structural check:**
   - Do expected directories exist?
   - Are symlinks valid (if used)?
   - Are permissions correct on scripts?

### Step 4: Generate Audit Report

Create comprehensive report with this structure:

```markdown
# Audit Report

**Generated:** {YYYY-MM-DD HH:MM}
**Scope:** {Full audit | Specific component}
**Specs Audited:** {count}

---

## Executive Summary

- **Compliant:** {count} specs fully match implementation
- **Divergences:** {count} specs with issues
- **Critical:** {count} issues requiring immediate attention

---

## ❌ Divergences Found

### 1. {Spec Name} - {Brief Issue}

**Spec says:** {requirement from spec}
**Implementation does:** {what code actually does}
**Impact:** Critical | High | Medium | Low
**Files affected:** {list}

### 2. {Next divergence}
...

---

## ⚠️ Warnings

{Issues that are technically correct but potentially problematic}

---

## ✅ Compliant Specs

{List of specs that passed all checks}

---

## 📋 Recommended Actions

| Priority | Issue | Suggested Fix |
|----------|-------|---------------|
| Critical | ... | ... |
| High | ... | ... |
| Medium | ... | ... |
| Low | ... | ... |

---

## Audit Details

### {Spec Name}
**Status:** ✅ Compliant | ❌ Divergent
**Checks performed:**
- [x] {check 1}
- [x] {check 2}
- [ ] {failed check}
**Notes:** {any observations}

{Repeat for each spec}
```

### Step 5: Save Report

Save the report to `audits/` directory:

```bash
mkdir -p audits
# Report filename: audit-{YYYY-MM-DD-HH-MM}.md
```

Output the report location and summary.

---

## Guardrails

99999. **READ-ONLY CRITICAL:** Do NOT modify any files. Only read and report.

9999. **Evidence required:** Every finding must cite specific file:line or grep result.

999. **Spec is source of truth:** Compare implementation TO spec, not vice versa.

99. **No false positives:** If uncertain, mark as "Needs Review" not "Divergent".

9. **Actionable findings:** Each divergence should suggest a concrete fix.

---

## Scope Control

**If $ARGUMENTS provided:**
- Audit only the specified component/spec
- Example: `/audit loop.sh` → audit only loop-orchestrator-system.md

**If no arguments:**
- Full audit of all implemented specs

---

## Completion

Output summary and signal:

```
Audit complete: {compliant}/{total} specs compliant
Report saved to: audits/audit-{timestamp}.md

<promise>COMPLETE</promise>
```

---

## Notes

### Why Opus Model?

Audit requires:
- Deep reasoning to understand spec intent
- Cross-referencing multiple files
- Nuanced judgment on compliance vs divergence
- Comprehensive report generation

Opus handles complex analysis better than Sonnet.

### Why No Subagents?

- Audit needs holistic view (subagents lose cross-spec context)
- Sequential analysis is more thorough
- Findings may relate across specs (subagents can't correlate)

### When to Run Audit?

- After major implementation phases
- Before releases/milestones
- When specs are updated significantly
- Periodically (weekly/monthly maintenance)

### Audit vs Validate

| Audit | Validate |
|-------|----------|
| All specs at once | One spec at a time |
| Read-only report | Creates corrective tasks |
| Holistic view | Focused verification |
| Human reviews report | Automated fix loop |
| Periodic maintenance | Part of build cycle |

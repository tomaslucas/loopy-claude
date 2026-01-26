# Audit System Specification

**Status:** Draft → Implemented  
**Code:** `.claude/commands/audit.md`, `loop.sh` (audit mode)

---

## 1. Overview

### 1.1 Purpose

The audit system provides **comprehensive repository health checks** by comparing all implementations against their specifications. Unlike validate mode (which checks one spec at a time), audit performs a holistic analysis of the entire codebase.

### 1.2 Key Characteristics

- **READ-ONLY**: No modifications, only generates reports
- **Holistic**: Cross-spec analysis detects systemic issues
- **Periodic**: Manual trigger for maintenance (not part of build cycle)
- **Evidence-based**: Every finding cites specific file:line

---

## 2. Jobs to Be Done (JTBD)

1. **As a maintainer**, I want to verify all specs are correctly implemented so I can trust the codebase.
2. **As a developer**, I want to detect spec drift so I can update outdated documentation.
3. **As a reviewer**, I want a comprehensive compliance report so I can assess project health.

---

## 3. Technical Specification

### 3.1 Command Definition

**Location:** `.claude/commands/audit.md`

**Frontmatter:**
```yaml
---
name: audit
description: Audit repository for spec compliance - compares implementation against specifications and generates divergence report
---
```

### 3.2 Model Selection

- **Model:** `opus` (requires deep reasoning, cross-referencing, nuanced judgment)
- **Why not sonnet:** Complex analysis, spec intent interpretation, comprehensive report generation

### 3.3 Tool Restrictions

**Allowed:**
- Read (files and directories)
- Grep (pattern search)
- Glob (file discovery)
- Bash (read-only: ls, cat, test, find, head, tail, wc)

**Prohibited:**
- Write/Edit
- Task (no subagents - audit needs holistic context)
- Bash write operations (>, >>, tee, sed -i, mv, rm, cp)
- Git commits

### 3.4 Workflow Phases

1. **Phase 0: Orient** - Study specs/README.md, identify audit targets
2. **Step 1: Inventory** - Collect all audit targets (specs marked ✅)
3. **Step 2: Verification** - Spec-by-spec requirements checking
4. **Step 3: Cross-cutting** - Systemic issues (consistency, staleness, structure)
5. **Step 4: Report** - Generate structured audit report
6. **Step 5: Save** - Persist to `audits/audit-{timestamp}.md`

### 3.5 Report Structure

```markdown
# Audit Report

**Generated:** {YYYY-MM-DD HH:MM}
**Scope:** {Full audit | Specific component}
**Specs Audited:** {count}

## Executive Summary
- Compliant: {count}
- Divergences: {count}
- Critical: {count}

## ❌ Divergences Found
### 1. {Spec} - {Issue}
**Spec says:** ...
**Implementation does:** ...
**Impact:** Critical | High | Medium | Low
**Files affected:** ...

## ⚠️ Warnings
## ✅ Compliant Specs
## 📋 Recommended Actions
| Priority | Issue | Suggested Fix |
```

### 3.6 Scope Control

- With `$ARGUMENTS`: Audit only specified component/spec
- Without arguments: Full audit of all implemented specs

### 3.7 Completion Signal

```
<promise>COMPLETE</promise>
```

---

## 4. Integration with loop.sh

### 4.1 Mode Registration

```bash
case "$MODE" in
    audit)
        MODEL="opus"        # Deep analysis requires reasoning
        ;;
```

### 4.2 Post-mortem Exclusion

Audit mode should NOT trigger post-mortem (read-only, no lessons to learn):

```bash
# Post-mortem hook exclusions
if [[ "$MODE" != "post-mortem" && "$MODE" != "prime" && "$MODE" != "bug" && "$MODE" != "audit" ]]; then
```

### 4.3 Stop Conditions

Audit uses standard stop conditions:
- Max iterations (default: 1)
- Completion signal (`<promise>COMPLETE</promise>`)
- Rate limit

---

## 5. Audit vs Validate Comparison

| Aspect | Audit | Validate |
|--------|-------|----------|
| Scope | All specs at once | One spec at a time |
| Output | Read-only report | Creates corrective tasks |
| Context | Holistic cross-spec view | Focused single-spec |
| Automation | Human reviews report | Automated fix loop |
| Frequency | Periodic maintenance | Part of build cycle |
| Model | Opus | Sonnet |
| Subagents | No (needs full context) | Yes (spec-checker, inferencer) |

---

## 6. When to Run Audit

- After major implementation phases
- Before releases/milestones
- When specs are updated significantly
- Periodically (weekly/monthly maintenance)
- When divergence is suspected

---

## 7. Guardrails

99999. **READ-ONLY CRITICAL:** No file modifications under any circumstances
9999. **Evidence required:** Every finding must cite file:line or grep result
999. **Spec is truth:** Compare implementation TO spec, not vice versa
99. **No false positives:** Mark uncertain items as "Needs Review"
9. **Actionable:** Each divergence must suggest concrete fix

---

## 8. Acceptance Criteria

1. [ ] `.claude/commands/audit.md` exists with correct frontmatter
2. [ ] `loop.sh` supports `audit` mode with `opus` model
3. [ ] Audit mode excluded from post-mortem hook
4. [ ] Running `./loop.sh audit` produces report in `audits/` directory
5. [ ] Report includes all sections defined in §3.5

---

**Created:** 2026-01-26
**Author:** Automated spec generation from audit command

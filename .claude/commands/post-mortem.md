---
name: post-mortem
description: Analyze session logs and extract lessons learned
---

# Post-Mortem Mode

Analyze the most recent session log for errors and inefficiencies, extract actionable lessons, and update lessons-learned.md.

---

## Workflow

### Step 1: Identify the Log to Analyze

**Priority 1: If `$ARGUMENTS` is provided:**
Use the file path from `$ARGUMENTS` (CLI usage: `/post-mortem logs/file.txt` or `./loop.sh post-mortem --log logs/file.txt`).

**Priority 2: If `LOOPY_LOG_FILE` environment variable is set:**
Use that file directly (passed by loop.sh when post-mortem runs as pipeline step).

**Priority 3: Otherwise, find the most recent productive session log:**

```bash
ls -t logs/log-*.txt | grep -v 'log-post-mortem' | head -1
```

Read the entire log to understand what happened in the session.

### Step 2: Analyze for Errors and Inefficiencies

Look for:

**Errors:**
- Command execution failures
- Rate limit hits
- Permission issues
- Syntax errors
- Failed verifications

**Inefficiencies:**
- Re-reading the same file multiple times
- Spawning unnecessary subagents when direct tool use would work
- Repeated failed commands (same command failing multiple times)
- Excessive token usage patterns
- Circular logic or repeated work

### Step 3: Extract Lessons

For each significant error or inefficiency found, formulate a lesson using this structure:

```
- **Evitar:** {what not to do} | **Usar:** {what to do instead} | **Razón:** {why} ({YYYY-MM-DD})
```

**Guidelines:**
- Be specific and actionable
- Focus on generalizable patterns, not one-off incidents
- Include the date for pruning reference
- Make it immediately useful for future sessions

**Example lessons:**
```
- **Evitar:** pkill para terminar procesos | **Usar:** kill <PID> | **Razón:** Entorno prohíbe pkill (2026-01-26)
- **Evitar:** Subagents para <15 archivos conocidos | **Usar:** Read tool directo | **Razón:** 2x más eficiente en tokens (2026-01-26)
- **Evitar:** grep sin -q en condicionales | **Usar:** grep -q | **Razón:** Reduce ruido en logs (2026-01-26)
```

### Step 4: Determine Target Section

Based on the mode that was running:
- Log named `log-plan-*.txt` → Update **Plan** section
- Log named `log-build-*.txt` → Update **Build** section
- Log named `log-validate-*.txt` → Update **Validate** section
- Log named `log-reverse-*.txt` → Update **Reverse** section
- Log named `log-work-*.txt` → Update **Build** section (work mode primarily does build)

### Step 5: Update lessons-learned.md

Read the existing `lessons-learned.md` (or create it if missing).

**If file doesn't exist, create with this structure:**

```markdown
# Lessons Learned

## Plan
<!-- Max 20 items. Managed by post-mortem. -->

## Build
<!-- Max 20 items. Managed by post-mortem. -->

## Validate
<!-- Max 20 items. Managed by post-mortem. -->

## Reverse
<!-- Max 20 items. Managed by post-mortem. -->
```

**Update the appropriate section:**

1. Add new lessons to the relevant section
2. If section now has > 20 items, prune using semantic analysis:
   - Remove obsolete lessons (references code/context that no longer exists)
   - Remove redundant lessons (duplicates another lesson)
   - Remove overly specific lessons (too tied to one incident, not generalizable)
   - Fallback: If no clear candidates, remove oldest by date (FIFO)

3. Maintain the 20-item limit per section

### Step 6: Commit and Complete

**If changes were made:**

```bash
git add lessons-learned.md
git commit -m "Post-mortem: Extract lessons from session

Analysis of [mode] session identified [N] lessons:
- [brief summary of what was learned]

(cite: specs/post-mortem-system.md)"
git push
```

**If no lessons found (clean session):**

Simply complete without making changes. A clean session with no errors or inefficiencies is success, not something to document.

Output:
```
<promise>COMPLETE</promise>
```

---

## Important Notes

### This Mode Runs Automatically

You are triggered automatically after productive sessions (plan/build/validate/reverse/work). You do NOT need to trigger yourself again.

### Focus on Learnable Patterns

Not everything is a lesson. Skip:
- One-off typos that won't repeat
- External issues (API downtime, network problems)
- Expected behavior (e.g., "verification failed" when code was wrong is normal)

Extract lessons from:
- Repeated mistakes (same error multiple times)
- Systemic inefficiencies (tool misuse, workflow issues)
- Violations of established guidelines
- Missed opportunities for optimization

### Semantic Pruning Example

When a section has 21 items and needs pruning:

**Good removal candidates:**
- "Evitar: usar old-api.sh | Usar: new-api.sh | Razón: old-api.sh deprecated" ← code no longer exists
- "Evitar: read file X twice | Usar: read once" ← duplicates a more general lesson about caching reads
- "Evitar: typo in exact filename Y | Usar: spell correctly" ← too specific

**Keep these:**
- "Evitar: pkill commands | Usar: kill <PID> | Razón: environment restriction" ← still relevant
- "Evitar: subagents for known files | Usar: Read tool | Razón: token efficiency" ← general pattern
- "Evitar: missing -q in grep | Usar: grep -q | Razón: cleaner output" ← common mistake

### Empty Analysis is Success

If you analyze a log and find no significant errors or inefficiencies, that's a GOOD thing. Don't invent lessons. Just output `<promise>COMPLETE</promise>` and move on.

---

## Completion Signal

When done (whether changes were made or not):

```
<promise>COMPLETE</promise>
```

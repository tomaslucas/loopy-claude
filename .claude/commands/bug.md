---
name: bug
description: Analyze a reported bug, determine root cause, and create corrective tasks in plan.md
---

# Bug Analysis

Analyze the reported bug and create corrective tasks in plan.md.

## Input

$ARGUMENTS - Description of the bug or problem detected

## Workflow

1. **Understand the problem**
   - Parse the bug description from $ARGUMENTS
   - Identify which component/spec is affected
   - Search codebase for related code (Grep, Read)

2. **Locate the spec**
   - Find the relevant spec in specs/
   - Read the spec to understand expected behavior
   - Compare expected vs actual behavior

3. **Determine bug type**
   - **Code bug**: Implementation doesn't match spec
   - **Spec bug**: Spec is incomplete or incorrect
   - **Missing feature**: Spec exists but feature not implemented

4. **Strategic Analysis** (for code bugs and missing features)

   **4.0 Trivial vs Non-Trivial Classification:**
   
   First, classify the bug:
   
   | Type | Criteria | Strategy Depth |
   |------|----------|----------------|
   | **Trivial** | Single file, <50 lines, obvious fix | Skip strategy, create task directly |
   | **Non-trivial** | Multi-file, architectural, or unclear fix | Lightweight strategy (2-3 approaches) |
   
   **For NON-TRIVIAL bugs, include lightweight strategy in task:**
   ```markdown
   - [ ] Fix: {description}
         Strategy: {brief approach selected}
         Alternatives considered: {list other approaches}
         Done when: {criteria}
         Verify: {command}
         (cite: specs/{spec}.md)
   ```

   Before creating tasks, analyze for optimal grouping:

   **4.1 Check existing plan.md:**
   - Are there pending tasks touching the same files?
   - Are there related tasks that should be grouped?
   - If yes → merge fix into existing task or group together

   **4.2 Context budget estimation:**
   - **Small** (<500 lines): Single task OK
   - **Medium** (500-1500 lines): Consider grouping related fixes
   - **Large** (>2000 lines): MUST split into logical sub-tasks

   **4.3 Dependency check:**
   - Does fix depend on other pending tasks? → Order appropriately
   - Do other tasks depend on this fix? → Mark as foundational

   **4.4 Grouping rules:**
   - Same file + <500 lines = MAX 1 task (group everything)
   - Related files + <1500 lines = Prefer grouping
   - If splitting, add: `[Split: reason]`

   **Output:** Decision on task structure (single/grouped/split)

5. **Create corrective action**

   **If code bug:**
   Add task to plan.md (applying Phase 4 decisions):
   ```markdown
   - [ ] Fix: {brief description of the fix needed}
         Done when: {concrete criteria}
         Verify: {command or check}
         (cite: specs/{relevant-spec}.md)
         [Grouped: reason] or [Split: reason] (if applicable)
   ```

   **If missing feature:**
   Add task to plan.md with implementation steps (apply same grouping rules).

   **If spec bug:**
   Output recommendation:
   ```
   SPEC_UPDATE_NEEDED: specs/{spec}.md
   Issue: {what's wrong with the spec}
   Suggestion: {how to fix it}

   → Run /feature-designer to update the spec
   ```

6. **Report**
   - Summarize what was found
   - Confirm task added to plan.md (or spec update needed)
   - Suggest next step: `./loop.sh build` or `/feature-designer`

## Output

After analysis, output one of:

```
✅ Task added to plan.md
   Fix: {description}
   Next: ./loop.sh build
```

or

```
⚠️ Spec update needed
   Spec: specs/{name}.md
   Issue: {description}
   Next: /feature-designer
```

## Constraints

- Do NOT modify specs (only plan.md for code bugs)
- Do NOT implement fixes (only create tasks)
- Always cite the relevant spec
- If unclear, ask for clarification before creating task

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

4. **Create corrective action**

   **If code bug:**
   Add task to plan.md:
   ```markdown
   - [ ] Fix: {brief description of the fix needed}
         Done when: {concrete criteria}
         Verify: {command or check}
         (cite: specs/{relevant-spec}.md)
   ```

   **If spec bug:**
   Output recommendation:
   ```
   SPEC_UPDATE_NEEDED: specs/{spec}.md
   Issue: {what's wrong with the spec}
   Suggestion: {how to fix it}

   → Run /feature-designer to update the spec
   ```

   **If missing feature:**
   Add task to plan.md with implementation steps.

5. **Report**
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

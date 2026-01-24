# Reverse Engineering Mode

Analyze legacy codebase (READ-ONLY) and generate specifications that enable system reconstruction.

---

## Phase 0: Orient

**CRITICAL: This is READ-ONLY analysis. NEVER modify target code or documentation.**

Understand scope:

1. Identify target repository (current directory or specified path)
2. Note languages, frameworks, structure
3. Prepare output directories:
   - `reverse-analysis/` (intermediate artifacts)
   - `specs-reverse/` (final specifications)

---

## Subagent Strategy

**Decision rule:** Subagents have ~20K token overhead each. Only use when value exceeds cost.

### For repository analysis:

- **< 20 modules**: Read all modules directly with Read tool
  - Math: 20 modules × 3K = 60K tokens < 3 subagents × 20K overhead
  - Sequential reading more efficient

- **20-50 modules**: Use 5-10 Explore subagents for initial categorization, then batch read
  - Categorize by functional area
  - Then read modules directly

- **> 50 modules**: Use parallel subagents for batch processing
  - Standard budget: 10-20 subagents (2-3 modules each)
  - Premium budget: Up to 50 subagents
  - Each subagent: analyze one module → output JSON

### For code reading:

- Known files → Read tool directly
- Need to find patterns → Grep tool
- Large-scale exploration → Explore subagent

**Anti-patterns:**
- ❌ One subagent per module when < 20 modules
- ❌ Loading entire codebase into main context
- ❌ Subagent just to "read and summarize" known file

---

## Workflow: 3 Phases

Reverse engineering proceeds in stages. Check state to determine current phase.

### State Check (determines phase)

```bash
# Check what exists:
ls reverse-analysis/discovery.json 2>/dev/null
ls reverse-analysis/analysis-*.json 2>/dev/null | wc -l
ls specs-reverse/*.md 2>/dev/null | wc -l
```

**Decision tree:**
- NO discovery.json → Execute Phase 1 (Discovery)
- discovery.json exists BUT incomplete analysis → Execute Phase 2 (Analysis)
- All analysis complete BUT no specs → Execute Phase 3 (Spec Generation)
- Specs exist → Output `<promise>COMPLETE</promise>` and STOP

---

## Phase 1: Discovery

**Goal:** Understand repository structure without reading all code.

### Step 1: Scan Repository

Use bash utilities to explore:

```bash
# Find code files (exclude docs, tests if obvious)
find . -type f -name "*.py" -o -name "*.js" -o -name "*.sql" | grep -v -E "(docs/|README|\.git|node_modules)"

# Identify entry points
find . -name "main.*" -o -name "index.*" -o -name "app.*"

# Detect languages
find . -type f | grep -oE '\.[a-z]+$' | sort | uniq -c

# Detect frameworks (package files)
ls package.json requirements.txt Gemfile pom.xml 2>/dev/null
```

### Step 2: Create Discovery Artifact

```bash
mkdir -p reverse-analysis
```

Write `reverse-analysis/discovery.json`:

```json
{
  "repository_path": "/path/to/analyzed",
  "total_modules": 45,
  "languages": ["python", "javascript", "sql"],
  "frameworks": ["flask", "react"],
  "entry_points": ["src/main.py", "frontend/index.js"],
  "modules": [
    {"path": "src/auth.py", "type": "python", "lines": 234},
    {"path": "src/processor.py", "type": "python", "lines": 567},
    ...
  ]
}
```

**Keep discovery.json lightweight** (~10KB max). Structure only, NO code content.

### Step 3: Commit and Continue

```bash
git add reverse-analysis/discovery.json
git commit -m "reverse: discovery phase complete"
```

If total_modules < 20: continue to Phase 2 in same session
If total_modules >= 20: stop here, Phase 2 runs next iteration

---

## Phase 2: Analysis (Batch Processing)

**Goal:** Analyze each module, output JSON summaries.

### Step 1: Read Discovery

```bash
cat reverse-analysis/discovery.json
```

Extract: total_modules, modules list

### Step 2: Determine Batch

Check how many already analyzed:

```bash
ls reverse-analysis/analysis-*.json 2>/dev/null | wc -l
```

Calculate remaining: `total_modules - analyzed_count`

**Batch size:**
- If < 20 total: analyze all remaining
- If >= 20 total: analyze next 10-20 (based on budget/time)

### Step 3: Analyze Modules (Batch)

For each module in current batch:

1. **Read module code**
2. **Infer JTBD** from behavior:
   - Function/class names (process_*, extract_*, handle_*)
   - Input/output patterns
   - Inline comments (NOT formal docs)
   - Dependencies and call patterns

3. **Extract interfaces**:
   - Public functions/classes
   - API endpoints
   - Exported symbols

4. **Map dependencies**:
   - Imports, requires
   - External library usage
   - Internal module calls

5. **Detect uncertainties**:
   - Magic numbers without explanation
   - Complex logic without comments (cyclomatic > 10)
   - Unclear external dependencies

6. **Output JSON**: `reverse-analysis/analysis-{module_name}.json`

```json
{
  "module_name": "auth.py",
  "module_path": "src/auth.py",
  "inferred_jtbd": "Manage user authentication and session tokens",
  "interfaces": [
    {"name": "login", "type": "function", "signature": "login(username, password)"},
    {"name": "verify_token", "type": "function", "signature": "verify_token(token)"}
  ],
  "dependencies": [
    {"name": "jwt", "type": "external", "usage": "token generation"},
    {"name": "database", "type": "internal", "usage": "user lookup"}
  ],
  "uncertainties": [
    {
      "location": "auth.py:45",
      "type": "magic_value",
      "description": "Token expiry = 3600, no comment explaining why 1 hour"
    }
  ]
}
```

**Use subagents for parallelism if > 20 modules** (each subagent analyzes 1-2 modules).

### Step 4: Check Progress

Count analysis files:

```bash
analyzed=$(ls reverse-analysis/analysis-*.json | wc -l)
total=$(jq -r '.total_modules' reverse-analysis/discovery.json)
```

If `analyzed < total`:
- Commit batch
- Continue in next iteration

If `analyzed == total`:
- Commit batch
- Continue to Phase 3 (if time) or stop

---

## Phase 3: Spec Generation

**Goal:** Create human-readable specs from analysis JSONs.

### Step 1: Load All Analysis

```bash
cat reverse-analysis/discovery.json
cat reverse-analysis/analysis-*.json
```

**Context-efficient:** Reading JSON summaries (~100 bytes/module), not raw code.

### Step 2: Group by Functional Boundaries

Analyze modules and cluster by:
- Similar JTBD (cohesive purpose)
- Shared data structures
- High call frequency between modules
- Namespace/directory proximity

**Constraint:** Each spec < 1500 lines

**Output:** Functional groups (e.g., "auth-system", "data-processor", "api-layer")

### Step 3: Generate Specs

For each functional group, create spec:

```markdown
# {Component} System

> One-line description based on observed behavior

## Status: Generated (Reverse-Engineered)

**Analysis Date:** {DATE}
**Source:** {repo_path}

---

## 1. Overview

### Detected Purpose
{What code actually does, inferred from analysis}

### Observed Goals
- Goal 1 (FACT: observed in code)
- Goal 2 (ASSUMPTION: inferred, needs review)

### Scope Boundaries
{What this system does NOT do}

---

## 2. Detected Architecture

{Optional diagram if architecture is non-trivial}

### Components
- Component A: {path}, {purpose}
- Component B: {path}, {purpose}

### Dependencies
| Dependency | Type | Usage |
|------------|------|-------|
| flask | External | Web framework |
| internal_module | Internal | Data processing |

---

## 3. Implementation Details

### Observed Behavior
{Key functions/classes with citations}

```python
# src/file.py:45-67
def example_function():
    # FACT: Does X
    # UNCERTAINTY: Magic number 100
```

### Key Interfaces
{Public APIs, functions, classes}

---

## 4. ⚠️ Assumptions & Uncertainties

### Uncertainties Requiring Review
1. **Magic Value at {location}**
   - Found: {value}
   - Context: {missing explanation}
   - Requires: Human verification

### Assumptions Made
1. **ASSUMPTION:** {description}
   - Basis: {evidence}
   - Confidence: High/Medium/Low

---

## 5. Existing Tests Found

- Unit tests: {path} ({coverage}%)
- Integration tests: {path}
- Patterns: {observed test patterns}

---

## 6. Reconstruction Checklist

> Tasks to rebuild this system from scratch

### Phase 1: Setup
- [ ] Create project structure
- [ ] Install dependencies: {list from analysis}

### Phase 2: Core Implementation
- [ ] Implement {component A} ({behavior description})
  - [ ] {Sub-task 1}
  - [ ] ⚠️ UNCERTAINTY: {unresolved item}

### Phase 3: Testing
- [ ] Recreate unit tests
- [ ] Add integration tests

### Phase 4: Validation
- [ ] Compare behavior with original
- [ ] Resolve uncertainties

---

## 7. Metadata

**Files Analyzed:** {count}
**Lines of Code:** {count}
**Uncertainties:** {count} items requiring review

---
```

### Step 4: Create Reverse PIN

Write `specs-reverse/README.md`:

```markdown
# Reverse-Engineered Specifications

Generated from legacy codebase analysis.

| Spec | Keywords | Status |
|------|----------|--------|
| [auth-system.md](auth-system.md) | authentication, jwt, session | Generated |
| [data-processor.md](data-processor.md) | etl, transform, pipeline | Generated |

**Source:** {repository}
**Analysis Date:** {date}
**Total Specs:** {count}
```

### Step 5: Commit and Signal Complete

```bash
git add specs-reverse/
git commit -m "reverse: generated {N} specs from analysis"
```

Output:

```
<promise>COMPLETE</promise>
```

---

## Guardrails

99999. **READ-ONLY CRITICAL:** NEVER modify target code or documentation during analysis

999999. **Do NOT invent or assume:** If unclear → mark as UNCERTAINTY

9999999. **Exclude formal docs:** Skip README, docs/, man pages. INCLUDE inline code comments.

99999999. **Reconstruction focus:** Specs must enable system cloning from scratch

999999999. **Mark confidence:** FACT (observed) vs ASSUMPTION (inferred)

9999999999. **Batch processing:** For large repos, analyze in chunks to avoid context overload

99999999999. **Checkpoint frequently:** Commit discovery.json and analysis-*.json as you go

999999999999. **Generate diagrams selectively:** Only when architecture is complex (multi-tier, pipelines)

---

## Completion Signal

When all specs generated:

```
<promise>COMPLETE</promise>
```

---

## Notes

### Why 3 Phases?

- **Phase 1 (Discovery)**: Understand scope without reading everything (~10K tokens)
- **Phase 2 (Analysis)**: Deep dive per module, output JSON (~5-20K per module via subagents)
- **Phase 3 (Spec Generation)**: Synthesize JSONs into specs (~50K total context)

### Why JSON Intermediates?

Prevents context explosion. Without JSONs:
- 200 modules × 3K each = 600K tokens (exceeds context limit)

With JSONs:
- 200 modules → 200 JSON summaries × 100 bytes = 20KB (manageable)

### Why Checkpoint?

Large repos may need multiple iterations:
- Iteration 1: Discovery + 20 modules analyzed
- Iteration 2: 20 more modules analyzed
- Iteration 3: Remaining modules + spec generation

Checkpoints allow resuming without re-analyzing.

### When to Use Diagrams?

**Generate diagram when:**
- Multi-tier architecture (API → Business → Data)
- Complex data flows (3+ interconnected modules)
- Pipeline patterns (ETL, transformations)

**Skip diagram when:**
- Single-file script
- Flat utilities (no hierarchy)
- Simple CRUD (obvious structure)

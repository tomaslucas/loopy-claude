# Reverse Engineering Prompt System

> READ-ONLY analysis prompt that transforms legacy codebases into specifications through 3-phase batch processing

## Status: Ready

---

## 1. Overview

### Purpose

Analyze existing code (READ-ONLY) and generate specifications that enable system reconstruction without access to original documentation.

### Goals

- 3-phase workflow (Discovery → Analysis → Spec Generation)
- Batch processing for large repos (avoid context overload)
- JSON intermediates for context efficiency
- Uncertainty detection and flagging
- Reconstruction checklists in specs
- Completely READ-ONLY (never modify target)

### Non-Goals

- Modifying legacy code
- Including formal documentation in analysis
- Real-time or IDE integration
- Binary-only systems

---

## 2. Architecture

### 3-Phase Workflow

```
Phase 1: Discovery
    ↓ (scan structure, NO code reading)
    Output: discovery.json (~10KB)

Phase 2: Analysis (Batch Processing)
    ↓ (per-module analysis, subagents)
    Output: analysis-{module}.json (100 bytes each)

Phase 3: Spec Generation
    ↓ (read all JSONs, group by JTBD)
    Output: specs-reverse/*.md
```

### Key Insight: Context Efficiency

**Without JSON intermediates:**
- 200 modules × 3K each = 600K tokens (exceeds limit)

**With JSON intermediates:**
- 200 JSON summaries × 100 bytes = 20KB (manageable)

Phase 2 isolates context via subagents.
Phase 3 reads only JSON summaries, not raw code.

---

## 3. Key Features

### 3.1 State-Based Resumption

**Check state to determine phase:**

```bash
discovery.json exists? → Phase 2
analysis-*.json count < total? → Phase 2 (continue batch)
All analysis complete? → Phase 3
specs-reverse/*.md exist? → COMPLETE
```

Allows multi-iteration processing for large repos.

### 3.2 Batch Processing

**Batch sizes:**
- Small repo (< 20 modules): Analyze all at once
- Medium repo (20-50): Batches of 10-20
- Large repo (> 50): Batches of 20-50 (budget dependent)

Each iteration:
- Analyzes one batch
- Commits JSON checkpoints
- Stops (orchestrator continues next iteration)

### 3.3 Uncertainty Detection

**Patterns flagged:**
- Magic numbers without explanation
- Complex logic without comments (cyclomatic > 10)
- Unclear external dependencies
- Ambiguous behavior

**Output in specs:**
```markdown
## 4. ⚠️ Assumptions & Uncertainties

### Uncertainties
1. **Magic Value at src/file.py:123**
   - Found: `THRESHOLD = 100`
   - Context: No comment
   - Requires: Human verification
```

### 3.4 Reconstruction Focus

**Goal:** Specs enable cloning system from scratch.

**Each spec includes:**
- Detected architecture (FACTS, not assumptions)
- Observed behavior with code citations
- Existing tests found
- **Reconstruction checklist** (step-by-step rebuild tasks)

---

## 4. Output Structure

### Intermediate Artifacts

```
reverse-analysis/
├── discovery.json          # Phase 1 output
├── analysis-module1.json   # Phase 2 outputs
├── analysis-module2.json
└── ...
```

### Final Specs

```
specs-reverse/
├── README.md               # Reverse PIN
├── auth-system.md          # Grouped by functional boundary
├── data-processor.md
└── ...
```

---

## 5. Key Design Decisions

### Why 3 Phases?

**Separation prevents context explosion:**
- Phase 1: Structure only (no code content)
- Phase 2: Per-module isolation (via subagents)
- Phase 3: JSON summaries (not raw code)

### Why JSON Intermediates?

**Checkpointing + Context efficiency:**
- Resume after interruption
- Read 200 summaries instead of 200 code files
- Bounded context regardless of repo size

### Why READ-ONLY Critical?

**Reverse engineering analyzes, never modifies:**
- Target repo stays pristine
- All outputs in separate directories
- Guardrail 99999999999 (highest priority)

### Why Reconstruction Checklists?

**Specs must enable system cloning:**
- Not just documentation
- Actionable tasks to rebuild
- Step-by-step implementation guide

---

## 6. Implementation Guidance

### Prompt File Location

```
prompts/reverse.md
```

Implemented at: `prompts/reverse.md`

### Total Size

~450 lines markdown

### Model Requirement

**Sonnet sufficient** (analysis doesn't need extended_thinking like plan mode)

### Expected Execution Time

- Small repo (< 10K LOC): 5-10 minutes
- Medium repo (10K-50K LOC): 20-40 minutes
- Large repo (> 50K LOC): 60+ minutes (multiple iterations)

---

**Implementation:** See `prompts/reverse.md`

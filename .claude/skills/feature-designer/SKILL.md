---
name: Feature Designer
description: Design software features through conversational requirements gathering. Iteratively explore requirements, architecture, edge cases, and non-goals until design is solid, then generate formal specifications. Use when planning new features, adding functionality, modifying behavior, or architecting systems.
tools:
  - Read
  - Write
  - Grep
  - Glob
  - AskUserQuestion
---

# Feature Designer

Interactive conversational skill for designing software features through iterative requirements gathering and spec generation.

---

## Phase 0: Mandatory Research

**Always starts here. No exceptions.**

1. Read `specs/README.md` (PIN)
2. Search for related specs (grep, semantic search)
3. Read related specs COMPLETELY
4. **Review actual code** (grep patterns in implementation)
5. Verify assumptions with user

**Why critical:**
- Prevents specifying impossible solutions
- Ensures consistency with existing architecture
- Avoids duplication

**Red flag:** Starting design without Phase 0 → STOP.

---

## Phase 1: Iterative Requirements (The Loop)

**Conversational and iterative. Stay in this phase until user explicitly triggers crystallization.**

### Step 1: Identify Jobs to Be Done (JTBD)

Use AskUserQuestion to explore:
- What problems are we solving?
- Who are the users?
- What outcomes do they want?

### Step 2: Break Into Topics of Concern

Apply **"One Sentence Without 'And'" test**:
- ✅ "Auth system manages identity" (one topic)
- ❌ "User system handles auth, profiles, and billing" (three topics)

Use AskUserQuestion to validate topic boundaries.

### Step 3: Deep Dive Per Topic (Iterative)

**FOR EACH TOPIC**, run continuous AskUserQuestion loop:

1. Ask about goals, non-goals
2. Ask about architecture components
3. Ask about external dependencies
4. Ask about testing strategy
5. Ask about edge cases
6. Ask about integration points
7. **Strategy Investigation** (see Step 3b below)
8. **Keep asking until topic is solid**

### Step 3b: Strategy Investigation (Per Topic)

**During deep dive, evaluate implementation approaches:**

1. **Pattern Analysis:**
   - Search codebase for similar solutions (`grep -r "pattern" .`)
   - Identify existing conventions and patterns
   - Note reusable components

2. **Approach Evaluation:**
   Identify 2-3 implementation approaches and analyze each:

   | Criterion | Questions |
   |-----------|-----------|
   | **Complexity** | Lines of code? New dependencies? Learning curve? |
   | **Performance** | Time/space complexity? Bottlenecks? |
   | **Security** | Attack surface? Data exposure? Validation needed? |
   | **Maintainability** | Testable? Debuggable? Future-proof? |
   | **Consistency** | Matches existing patterns? Creates split-brain? |

3. **Present Options via AskUserQuestion:**

   ```
   Question: How should we implement {topic}?

   Options:
   ○ Approach A: {name}
     Pros: {list}
     Cons: {list}
     Complexity: {low/medium/high}

   ○ Approach B: {name}
     Pros: {list}
     Cons: {list}
     Complexity: {low/medium/high}

   ○ Approach C: {name} (if applicable)
     Pros: {list}
     Cons: {list}
     Complexity: {low/medium/high}

   ○ Other (specify custom approach)

   Recommended: Approach {X} because {reasoning}
   ```

4. **Document Decision:**
   Record the selected strategy for inclusion in generated spec (Section 8)

**Checkpoint Criteria:**

Design is "solid" when you can answer:
- ✅ What components exist and how do they interact?
- ✅ What data flows through the system?
- ✅ What are failure modes and edge cases?
- ✅ How do we test it?
- ✅ What's explicitly NOT included? (non-goals)

**Don't rush.** Use AskUserQuestion liberally. This is where design happens.

### Critical Thinking Guidelines

For each design aspect, reason about:

**Architecture:**
- Is this the simplest approach that works?
- What are failure modes?
- How does it scale?
- What are coupling points?
- Does it follow existing patterns?

**Engineering:**
- Is this testable?
- Is this maintainable?
- What's the refactor cost if wrong?
- YAGNI: Are we building for hypothetical futures?

**Trade-offs:**
- Performance vs simplicity
- Flexibility vs complexity
- Time-to-implement vs robustness
- Development speed vs long-term maintainability

**Each AskUserQuestion should:**
- Present 2-4 options (not just yes/no)
- Explain trade-offs clearly
- Recommend approach (with reasoning)
- Allow "Other" for user custom input
- Show consequences of each choice

**Never:**
- ❌ Assume user wants the "obvious" choice
- ❌ Skip to crystallization without explicit trigger
- ❌ Accept vague requirements without drilling down
- ❌ Move forward with unresolved uncertainties
- ❌ Ask yes/no questions when options exist

---

## Phase 2: Cross-Spec Coherence Validation

**Before generating any specs, validate coherence with existing specs.**

This phase ensures 100% alignment across all specifications to prevent implementation failures, integration breakage, and wasted effort.

### Critical Decisions to Extract

From the new design, systematically identify:

**1. Language/Runtime:**
- Version requirements (Python 3.11+, Node 18+, Go 1.21+)
- Compatibility constraints
- Runtime-specific features required

**2. Key Libraries/Frameworks:**
- Core dependencies (Pydantic, FastAPI, Django, React)
- Version requirements
- Conflicting alternatives (e.g., can't use both Express and Fastify)

**3. Data Storage:**
- Database type (PostgreSQL, MongoDB, Redis, SQLite)
- Schema format (SQL, NoSQL document structure)
- Migration requirements

**4. API Contracts:**
- Format (REST, GraphQL, gRPC)
- Serialization (JSON, XML, Protobuf)
- Authentication mechanism (JWT, OAuth, API keys)

**5. External Services:**
- Third-party APIs
- Cloud services (AWS, GCP, Azure)
- Required credentials/configuration

### Search Strategy

**Step 1: Identify Related Specs**
```
grep -r "keyword1\|keyword2\|keyword3" specs/ | grep -v README
```

Search for:
- Technology names (PostgreSQL, Redis, FastAPI)
- Domain concepts (auth, user, payment)
- Integration points (API, webhook, event)

**Step 2: Read Completely**
- Read each related spec from top to bottom
- Don't skim - conflicts hide in details
- Pay attention to "Implementation Details" and "Dependencies" sections

**Step 3: Extract Their Decisions**
- What language/version do they use?
- What libraries do they depend on?
- What data formats do they expect?
- What APIs do they expose/consume?

### Validation Report Template

Present findings to user in structured format:

```markdown
🔍 Cross-Spec Coherence Validation

Analyzing: {list new spec topics}
Related specs found: {list existing spec names}

Critical Decisions (New Design):
- Language/Runtime: {e.g., Python 3.11+}
- Libraries: {e.g., Pydantic v2, FastAPI}
- Data Storage: {e.g., PostgreSQL}
- API Format: {e.g., REST with JSON}
- External Services: {e.g., Stripe API, AWS S3}

┌─────────────────────────────────────────────────────────┐
│ CONFLICTS DETECTED                                      │
└─────────────────────────────────────────────────────────┘

⚠️ CONFLICT 1: Python Version Mismatch
- New design: Python 3.11+ (requires modern type hints)
- Existing (auth-system.md): Python 3.8+
- Impact: Type hint syntax incompatible, CI may fail
- Resolution options:
  a) Update auth-system to require Python 3.11+ (Recommended)
     Pro: Modern syntax, better type safety
     Con: Requires Python upgrade in deployment
  b) Downgrade new design to Python 3.8+
     Pro: No infrastructure changes
     Con: Cannot use modern features
  c) Document split - allow both versions
     Pro: No immediate changes
     Con: Inconsistent codebase, future confusion

⚠️ CONFLICT 2: Data Validation Library
- New design: Pydantic v2
- Existing (user-system.md): Manual dict validation
- Impact: Different validation patterns, harder to maintain
- Resolution options:
  a) Migrate user-system to Pydantic v2 (Recommended)
     Pro: Consistent validation, better type safety
     Con: Requires refactoring existing code
  b) Keep manual validation for existing, Pydantic for new
     Pro: No changes to existing code
     Con: Two validation patterns to maintain
  c) Use manual validation for new design
     Pro: Consistency with existing
     Con: More verbose, error-prone

┌─────────────────────────────────────────────────────────┐
│ NO CONFLICTS DETECTED                                   │
└─────────────────────────────────────────────────────────┘

✅ API Format: REST with JSON
- New: REST/JSON
- Existing: Compatible or absent
- No action needed

✅ Database: PostgreSQL
- New: PostgreSQL
- Existing specs: No database specified
- No conflict, new dependency
```

### Conflict Categories

**Direct Conflict:**
- Two incompatible choices made
- Example: New uses PostgreSQL, existing uses SQLite
- Example: New uses Python 3.11+, existing uses Python 3.8+

**Implicit Conflict:**
- New design requires something existing doesn't specify
- Example: New uses Pydantic, existing has no validation
- Example: New uses async/await, existing is synchronous

**Integration Mismatch:**
- Components expect different contracts
- Example: New outputs JSON, existing expects XML
- Example: New uses async API, existing uses blocking calls

**Version Conflict:**
- Same library, different incompatible versions
- Example: New uses Pydantic v2, existing uses Pydantic v1
- Example: New uses React 18+, existing uses React 16

### Blocking Workflow

**Step 1-5:** Extract and detect (as above)

**Step 6:** 🛑 **BLOCK UNTIL USER DECIDES**

Use AskUserQuestion to present ALL conflicts. Do NOT proceed without explicit resolution.

Example:
```
Question: Conflict 1 - How to resolve Python version mismatch?

New design requires Python 3.11+, existing auth-system uses Python 3.8+

Options:
○ Update auth-system to Python 3.11+ (Recommended)
  Pro: Modern syntax, consistent codebase
  Con: Requires Python upgrade in deployment

○ Downgrade new design to Python 3.8+
  Pro: No infrastructure changes
  Con: Cannot use modern type hints

○ Document as migration - allow both versions temporarily
  Pro: No immediate code changes
  Con: Inconsistent, technical debt

○ Other (specify custom approach)
```

**Step 7:** Apply approved resolution

For each conflict:
- If user chose to update existing specs → batch edit them
- If user chose to adjust new design → note for crystallization
- If user chose to document → prepare migration notes

**Step 8:** Add migration notes if needed

When updating existing specs, add to their "Notes" section:

```markdown
## Migration Notes
- **2026-01-24**: Updated to require Python 3.11+ (was Python 3.8+)
  - Reason: Consistency with notification-system, modern type hints
  - Impact: Deployments must upgrade Python version
  - Related: notification-system.md
```

**Step 9:** Confirm all conflicts resolved

Present summary:
```
✅ Coherence Validation Complete

Conflicts resolved: 2
- Python version → Updated to 3.11+ across all specs
- Validation library → Migrated to Pydantic v2

Specs updated: 2
- auth-system.md (Python version, added migration notes)
- user-system.md (Validation approach, added Pydantic)

Ready to proceed to Phase 3: Crystallization
```

**Step 10:** 🛑 **DO NOT CRYSTALLIZE UNTIL USER CONFIRMS**

Wait for explicit trigger: "proceed", "crystallize", "generate specs"

### Why This Matters

**Without coherence validation:**
- Day 1: Create conflicting specs ✅
- Day 2: Plan mode generates implementation ⚙️
- Day 3: Integration fails 💥
- Day 4: Debug and find conflict 🔍
- Day 5: Update specs ♻️
- Day 6: Regenerate plan 🔧
- Day 7: Finally working ✅
- **Cost: 7 days**

**With coherence validation:**
- Day 1: Create specs, validate, resolve conflicts ✅
- Day 2: Plan mode generates correct implementation ⚙️
- Day 3: Integration works ✅
- **Cost: 3 days**

**Validation saves time, money, and frustration.**

---

## Phase 3: Crystallization (Batch Generation)

**Only execute after user explicitly triggers.**

Trigger phrases:
- "crystallize"
- "create the specs"
- "generate specifications"
- "ready to formalize"
- "looks good, write it up"

**Process:**

1. Read template (`resources/spec-template.md`)
2. Create ALL specs (one per topic):
   - Filename: `specs/{topic-name}-system.md`
   - Use lowercase-with-hyphens
   - **NO implementation checklists** (Section 7 is Implementation Guidance only)
   - **Include Section 8: Selected Implementation Strategy** with decisions from Step 3b
3. Update PIN (`specs/README.md`)
4. Evaluate project documentation updates:
   - Review documentation that may be affected by the new feature
   - If updates needed → add to spec's "Files to modify" section
5. Confirm completion to user

**Section 8 Format (in generated specs):**

```markdown
## 8. Selected Implementation Strategy

**Investigation date:** {DATE}

### Pattern Analysis
- Similar pattern found in: `path/to/file.ext`
- Project convention: {description}

### Approaches Considered

**Approach A: {name}**
- Pros: {list}
- Cons: {list}
- Complexity: {low/medium/high}

**Approach B: {name}**
- Pros: {list}
- Cons: {list}
- Complexity: {low/medium/high}

### Decision
**Selected:** Approach {X}

**Justification:** {why this approach is best for our context}

**Accepted trade-offs:** {what we're consciously sacrificing}
```

**Important:** Create all specs at once (batch), not one at a time.

---

## Guardrails

99999. **NEVER crystallize without explicit trigger**
       User must say "crystallize", "create specs", etc.

999999. **AskUserQuestion is the core loop**
        Continuously ask, never assume

9999999. **Critical thinking required**
         Evaluate simplicity, YAGNI, trade-offs

99999999. **Phase 0 is mandatory**
          Always research before design

999999999. **Specs ≠ Code**
           No VERSION increment, no CHANGELOG update

9999999999. **Coherence is mandatory**
            Validate cross-spec consistency

99999999999. **Tool restrictions enforced**
             Read/Write/Grep/Glob/AskUserQuestion only

---

## Critical Thinking Framework

**For every design decision, evaluate:**

### 1. Simplicity First
- What's the simplest thing that could work?
- Can we defer complexity until proven necessary?
- Is this over-engineering for the use case?

### 2. YAGNI (You Aren't Gonna Need It)
- Are we building for hypothetical futures?
- Can this be added later if needed?
- What's the cost of wrong guess?

### 3. Explicit Trade-offs
- Performance vs Maintainability
- Flexibility vs Simplicity
- Development Speed vs Robustness

### 4. Pattern Consistency
- Does this match existing codebase patterns?
- If diverging, is there strong justification?
- Will this create split-brain architecture?

### 5. Testing Strategy
- How do we verify this works?
- What are edge cases?
- Is this testable in isolation?

### 6. Failure Modes
- What can go wrong?
- How do we detect failures?
- Graceful degradation possible?

### 7. Dependencies
- Are we adding new external dependencies?
- Is the dependency battle-tested?
- Can we minimize coupling?

**Reason through these BEFORE asking user, then present options with this analysis baked in.**

---

## Notes

**See also:**
- `resources/spec-template.md` - Template for generated specs
- `resources/phase0-research.md` - Research checklist
- `resources/guardrails.md` - Critical rules reference
- `resources/examples.md` - Usage examples

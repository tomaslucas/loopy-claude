# Feature Designer Skill

> Interactive conversational skill for designing software features through iterative requirements gathering and spec generation

## Status: Ready

---

## 1. Overview

### Purpose

Guide users through feature design via conversation (JTBD → Topics → Specs), ensuring solid design through continuous critical questioning before crystallization into formal specifications.

### Goals

- Natural language activation ("design a feature", "plan authentication", "architect API")
- Tool-restricted (Read, Write, Grep, Glob, AskUserQuestion only)
- Iterative refinement via continuous AskUserQuestion loop
- Critical thinking on architecture, engineering, trade-offs
- 4-phase workflow (Research → Iteration → Coherence → Crystallization)
- Generate specs WITHOUT implementation checklists
- Update specs/README.md (PIN) automatically
- Optional (can create specs manually with template)

### Non-Goals

- Implementing code (that's build mode)
- Replacing manual spec creation (just a helper)
- Running during plan/build loops
- Making assumptions without user validation
- Crystallizing without explicit user trigger

---

## 2. Core Principle: Iterative Refinement via AskUserQuestion

**This skill operates as a continuous questioning loop. NEVER advance to crystallization without explicit user trigger.**

### Workflow Pattern

```
1. LLM reads context (specs, code)
    ↓
2. LLM thinks critically about design
    ↓
3. LLM uses AskUserQuestion:
   - Present options with trade-offs
   - Ask about edge cases
   - Propose architectural approaches
   - Challenge assumptions
   - Identify gaps
    ↓
4. User responds
    ↓
5. LLM reasons about response
    ↓
6. GOTO 3 (loop continues)

STOP only when user says:
- "crystallize"
- "create the specs"
- "generate specifications"
- "ready to formalize"
- "looks good, write it up"
```

### Critical Thinking Guidelines

For each design aspect, LLM must reason about:

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

## 3. Critical Thinking Framework

**For every design decision, LLM must evaluate:**

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

Present trade-offs in AskUserQuestion:
```
Option A: [approach]
  Pro: Simple, fast to implement
  Con: Less flexible for future changes

Option B: [approach]
  Pro: Highly configurable
  Con: More complex, longer dev time
```

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

**LLM should reason through these BEFORE asking user, then present options with this analysis baked in.**

---

## 4. Example: Iterative Refinement Session

```
User: "I want to add notifications"

LLM thinks:
- What type of notifications?
- Delivery channels?
- Real-time or batch?
- Storage requirements?

LLM → AskUserQuestion:
┌─────────────────────────────────────────────────────┐
│ Question: What notification channels?               │
│                                                     │
│ Options:                                            │
│ ○ Email only (Recommended for MVP)                 │
│   Pro: Simple, fewer dependencies, well-tested     │
│   Con: Not real-time, requires email config        │
│                                                     │
│ ○ Email + Push notifications (Mobile apps)         │
│   Pro: Real-time, better UX for mobile users       │
│   Con: Requires APNS/FCM, token management         │
│                                                     │
│ ○ Email + Push + In-app                           │
│   Pro: Full-featured, all bases covered            │
│   Con: Highest complexity, most dependencies       │
│                                                     │
│ ○ Other (specify custom approach)                  │
└─────────────────────────────────────────────────────┘

User selects: "Email + Push"

LLM thinks:
- Push means mobile apps exist or planned
- Need token management (device registration)
- Delivery guarantees? Best-effort or confirmed?
- What happens if push fails?

LLM → AskUserQuestion:
┌─────────────────────────────────────────────────────┐
│ Question: Push notification delivery guarantees?   │
│                                                     │
│ Options:                                            │
│ ○ Best-effort (Recommended)                        │
│   Pro: Simple, no storage overhead, fast           │
│   Con: No retry if device offline                  │
│   Use when: Non-critical notifications             │
│                                                     │
│ ○ Guaranteed delivery                              │
│   Pro: Retry until delivered, audit trail          │
│   Con: Complex, storage needed, retry logic        │
│   Use when: Critical user actions                  │
│                                                     │
│ ○ Other (specify)                                  │
└─────────────────────────────────────────────────────┘

User selects: "Best-effort"

LLM thinks:
- Token storage: where?
- Expiry handling?
- Multiple devices per user?

LLM → AskUserQuestion:
[... continues until user says "crystallize" ...]
```

---

## 5. Metadata Structure

```yaml
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
```

**Keywords for auto-activation:**
- design, feature, plan, architecture, requirements
- add functionality, modify behavior
- new feature, architect system

**Tools explained:**
- **Read**: Study existing specs and code patterns
- **Write**: Create new specification files
- **Grep**: Search for patterns in codebase
- **Glob**: Find related files
- **AskUserQuestion**: Iterative refinement loop (CRITICAL)

---

## 6. Workflow: 4 Phases

### Phase 0: Research (Mandatory)

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

### Phase 1: Iterative Requirements (The Loop)

**Conversational and iterative. Stay in this phase until user explicitly triggers crystallization.**

#### Step 1: Identify Jobs to Be Done (JTBD)

Use AskUserQuestion to explore:
- What problems are we solving?
- Who are the users?
- What outcomes do they want?

#### Step 2: Break Into Topics of Concern

Apply **"One Sentence Without 'And'" test**:
- ✅ "Auth system manages identity" (one topic)
- ❌ "User system handles auth, profiles, and billing" (three topics)

Use AskUserQuestion to validate topic boundaries.

#### Step 3: Deep Dive Per Topic (Iterative)

**FOR EACH TOPIC**, run continuous AskUserQuestion loop:

1. Ask about goals, non-goals
2. Ask about architecture components
3. Ask about external dependencies
4. Ask about testing strategy
5. Ask about edge cases
6. Ask about integration points
7. **Keep asking until topic is solid**

**Checkpoint Criteria:**

Design is "solid" when you can answer:
- ✅ What components exist and how do they interact?
- ✅ What data flows through the system?
- ✅ What are failure modes and edge cases?
- ✅ How do we test it?
- ✅ What's explicitly NOT included? (non-goals)

**Don't rush.** Use AskUserQuestion liberally. This is where design happens.

### Phase 2: Cross-Spec Coherence Validation

**Before generating any specs, validate coherence with existing specs.**

This phase ensures 100% alignment across all specifications to prevent implementation failures, integration breakage, and wasted effort.

#### Critical Decisions to Extract

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

#### Search Strategy

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

#### Validation Report Template

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

#### Conflict Categories

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

#### Blocking Workflow

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

#### Why This Matters

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

### Phase 3: Crystallization (Batch Generation)

**Only execute after user explicitly triggers.**

1. Read template (`resources/spec-template.md`)
2. Create ALL specs (one per topic):
   - Filename: `specs/{topic-name}-system.md`
   - Use lowercase-with-hyphens
   - **NO implementation checklists** (Section 7 is Implementation Guidance only)
3. Update PIN (`specs/README.md`)
4. Confirm completion to user

**Important:** Create all specs at once (batch), not one at a time.

---

## 7. Spec Template Structure

### Template (resources/spec-template.md)

```markdown
# {Feature Name}

> One-line summary

## Status: Draft | Ready | Implemented

---

## 1. Overview

### Purpose
{Why this exists}

### Goals
- {Goal 1}
- {Goal 2}

### Non-Goals
- {Explicitly out of scope}

---

## 2. Architecture

### Components
{ASCII diagram if useful}

### Dependencies
| Component | Purpose | Location |
|-----------|---------|----------|

---

## 3. Implementation Details

{Core types, key algorithms}

---

## 4. API / Interface

{Endpoints, methods, contracts}

---

## 5. Testing Strategy

{What to test, how}

---

## 6. Acceptance Criteria

- [ ] Criterion 1: {Observable behavior}
- [ ] Criterion 2: {Measurable outcome}

---

## 7. Implementation Guidance

> Context for plan generator to create specific, verifiable tasks

### Impact Analysis

**Change Type:** [ ] New Feature | [ ] Enhancement | [ ] Refactor

**Affected Areas:**

Search commands used:
- `grep -r "pattern" src/` → X files found
- `grep -r "config_key" .` → Y occurrences

Files/components affected:
- `path/to/file1.ext` (~line X, purpose: ...)
- `path/to/file2.ext` (N occurrences)

Integration points:
- Component A: how it integrates
- External dependency B: what changes

### Implementation Hints

**Core Implementation:**
- Create/modify: {high-level description}
- Key functions/classes: {names, not details}
- Expected behavior: {what code should do}

**Documentation:**
- Update: {which doc files need changes}
- Add: {new documentation needed}

**Testing:**
- Unit tests for: {areas requiring coverage}
- Integration tests for: {end-to-end scenarios}
- Edge cases: {specific scenarios to validate}

### Verification Strategy

How to verify the feature works:
- Command-based: `test command here`
- Manual checks: {observable behaviors}
- Acceptance criteria: {measurable outcomes}

---

**Note:** Plan generator reads this and creates specific tasks in plan.md. This spec describes WHAT; plan describes HOW.

---

## 8. Notes

{Additional context, trade-offs, decisions}
```

**Critical: Section 7 has NO implementation checklists (no [ ] tasks).**

---

## 8. Common Pitfalls and Examples

### Why Coherence Validation Matters

**Scenario: Skipping Phase 2 Validation**

```
Timeline WITHOUT validation:
─────────────────────────────────────────────────────────
Day 1: Design notification system
       - Decides on Python 3.11+, Pydantic v2, PostgreSQL
       - Creates specs without checking existing
       ✅ Feels productive

Day 2: Plan mode starts implementation
       - Generates code using Pydantic v2
       - Assumes Python 3.11+ features
       ⚙️ Everything compiles

Day 3: Integration with existing auth-system
       - Auth uses Python 3.8, manual dict validation
       - Type errors appear
       - Validation formats incompatible
       💥 INTEGRATION FAILS

Day 4: Debug session
       - Find the conflict in specs
       - Realize auth-system assumptions wrong
       🔍 Root cause identified

Day 5: Update specs to resolve conflict
       - Decide to upgrade auth-system to Pydantic
       - Update auth-system.md spec
       ♻️ Redesign required

Day 6: Regenerate implementation plan
       - Plan mode creates migration tasks
       - Implement auth-system changes
       🔧 Rework in progress

Day 7: Finally working
       - Integration tests pass
       ✅ Done (but exhausted)

Total Cost: 7 days, frustration, wasted implementation effort
```

```
Timeline WITH Phase 2 validation:
─────────────────────────────────────────────────────────
Day 1: Design notification system
       - Decides on Python 3.11+, Pydantic v2, PostgreSQL
       - Phase 2: Searches for related specs
       - Finds auth-system.md uses Python 3.8, dict validation
       - 🛑 DETECTS CONFLICT
       - AskUserQuestion: How to resolve?
       - User decides: Upgrade auth-system to Pydantic v2
       - Updates auth-system.md with migration notes
       ✅ Coherent specs created

Day 2: Plan mode generates correct implementation
       - Knows about migration requirements
       - Creates proper tasks
       ⚙️ Correct from start

Day 3: Integration works first try
       - No surprises
       - All specs aligned
       ✅ Success

Total Cost: 3 days, no rework, happy developer
Savings: 4 days (57% faster)
```

### Real Conflict Examples

#### Example 1: Python Version Conflict

**Context:** Adding a new data-processing module

**Conflict:**
- **New design:** Requires Python 3.11+ (uses match/case statements, modern type hints)
- **Existing (api-server.md):** Specifies Python 3.8+ (deployed to environment with Python 3.8)

**Impact if missed:**
- Syntax errors in production
- CI pipeline failures
- Delayed deployment waiting for Python upgrade

**Resolution options:**
```
a) Update api-server to require Python 3.11+
   Pro: Consistent, access to modern features
   Con: Infrastructure upgrade needed, coordination required
   Cost: 1-2 days for deployment updates

b) Downgrade new module to Python 3.8 compatible
   Pro: Works with existing infrastructure
   Con: Cannot use modern syntax, more verbose code
   Cost: Slight development overhead

c) Document as temporary split during migration
   Pro: Allows parallel work
   Con: Technical debt, must resolve eventually
   Cost: Future migration effort
```

#### Example 2: Data Validation Library

**Context:** Building a new user profile feature

**Conflict:**
- **New design:** Uses Pydantic v2 for data validation
- **Existing (user-system.md):** Manual dictionary validation with custom validators

**Impact if missed:**
- Two different validation patterns in codebase
- Inconsistent error messages
- Harder to maintain and train new developers
- Potential data validation gaps

**Resolution options:**
```
a) Migrate user-system to Pydantic v2 (Recommended)
   Pro: Consistency, better type safety, less code
   Con: Refactoring effort, testing required
   Cost: 2-3 days for migration

b) Keep both approaches
   Pro: No immediate changes needed
   Con: Long-term maintenance burden, split patterns
   Cost: Ongoing confusion and dual maintenance

c) Use manual validation for new feature
   Pro: Consistency with existing code
   Con: More code to write, error-prone, no type hints
   Cost: More development time per feature
```

#### Example 3: Database Choice

**Context:** Adding a caching layer

**Conflict:**
- **New design:** Uses Redis for caching
- **Existing (data-layer.md):** Uses SQLite for all persistence, no cache mentioned

**Impact if missed:**
- Unexpected infrastructure dependency
- Deployment complexity increases
- Local development requires Redis setup
- Cost implications (Redis hosting)

**Resolution:**
```
This is NOT a conflict - it's a new dependency

Action: Update data-layer.md to document:
- SQLite: Persistent storage
- Redis: Caching layer (NEW)
- Clear boundaries between use cases

No conflict, just documentation update needed
```

#### Example 4: API Format Mismatch

**Context:** New payment service integrating with existing order system

**Conflict:**
- **New design:** Expects JSON API responses
- **Existing (order-system.md):** Returns XML for historical reasons

**Impact if missed:**
- Integration code fails
- Need XML→JSON conversion layer
- Potential data loss if conversion not bijective

**Resolution options:**
```
a) Update order-system to support JSON (Recommended)
   Pro: Modern standard, easier integration
   Con: Must maintain backward compatibility for existing clients
   Cost: 3-4 days to add JSON endpoints

b) Add XML parsing to payment service
   Pro: No changes to existing system
   Con: Payment service has XML dependency
   Cost: 1 day for XML handling

c) Create adapter service
   Pro: Decoupled systems
   Con: Another service to maintain
   Cost: 2-3 days for adapter
```

### Anti-Patterns to Avoid

❌ **"I'll check compatibility later"**
- Later = during implementation = too late
- Rework is expensive
- **Do:** Validate in Phase 2, before crystallization

❌ **"It's probably fine, the existing code is flexible"**
- Assumptions break
- "Probably" is not a plan
- **Do:** Read existing specs completely, verify assumptions

❌ **"We can have two different approaches"**
- Consistency matters
- Split patterns confuse developers
- **Do:** Decide on one approach, migrate if needed

❌ **"Let's document the inconsistency and move on"**
- Technical debt accumulates
- Future developers suffer
- **Do:** Resolve now or create explicit migration plan

✅ **"Let me search for related specs and validate"**
- Proper Phase 2 execution
- Catches conflicts early
- Saves time and effort

### Cost-Benefit Analysis

**Time Investment:**
- Phase 2 validation: 15-30 minutes
- Searching specs: 5-10 minutes
- Resolving conflicts with user: 10-20 minutes
- Total: ~30 minutes

**Potential Savings:**
- Avoid 1-3 days of rework
- Prevent integration failures
- Reduce debugging time
- Lower frustration

**ROI: ~10,000% (30 minutes saves 2+ days)**

### When Conflicts Are Actually Fine

Not all differences are conflicts:

✅ **Different domains, no interaction:**
- Frontend uses React, backend uses FastAPI
- No conflict - different layers

✅ **Complementary technologies:**
- PostgreSQL for persistence + Redis for cache
- No conflict - different purposes

✅ **Explicitly scoped:**
- microservice-a uses SQLite, microservice-b uses PostgreSQL
- No conflict if properly isolated

**The key:** Validate that apparent conflicts are actually compatible given system boundaries.

---

## 9. Implementation Guidance

### Skill Structure

Create skill at `.claude/skills/feature-designer/`:

```
.claude/skills/feature-designer/
├── SKILL.md                    # Main skill file
└── resources/
    ├── spec-template.md        # Template WITHOUT checklists
    ├── phase0-research.md      # Research checklist
    ├── guardrails.md           # Critical rules
    └── examples.md             # Usage examples
```

### SKILL.md Content

```yaml
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

{Paste phases 0-3 workflow from this spec}

## Phase 0: Mandatory Research
{From section 6 above}

## Phase 1: Iterative Requirements
{From section 6 above}

## Phase 2: Coherence Validation
{From section 6 above}

## Phase 3: Crystallization
{From section 6 above}

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
```

### resources/spec-template.md

Copy template from Section 7 above.

### resources/phase0-research.md

```markdown
# Phase 0: Mandatory Research Checklist

Before designing anything:

1. ✅ Read `specs/README.md` (PIN lookup table)
2. ✅ Search for related specs:
   ```
   grep -r "keyword" specs/
   ```
3. ✅ Read related specs COMPLETELY
4. ✅ Review actual code implementation:
   ```
   grep -r "pattern" src/
   ```
5. ✅ Verify assumptions with user via AskUserQuestion

**Red flags:**
- ❌ Starting design without reading PIN
- ❌ Assuming how things work without reading code
- ❌ Skipping research phase
```

### resources/guardrails.md

```markdown
# Critical Guardrails

## Highest Priority

**🚨 Specs ≠ Code**
- ❌ DO NOT increment VERSION
- ❌ DO NOT update CHANGELOG.md
- ✅ DO update specs/README.md (PIN)

**🔍 Phase 0 is Mandatory**
- Never spec based on assumptions
- Always research first

**🎯 Wait for Explicit Trigger**
- Only crystallize when user says so
- Don't rush to formalize

**📦 Batch Crystallization**
- Create all specs at once
- Update PIN once at end

**🎨 One Topic = One Spec**
- Use "One Sentence Without 'And'" test

**🧪 Non-Goals Are Critical**
- Every spec must have explicit non-goals

**🔗 Coherence is Mandatory**
- All specs must be 100% aligned
- Validate before crystallization
- Block until conflicts resolved

**🔧 Tool Restrictions**
- Read, Write, Grep, Glob, AskUserQuestion ONLY
- No Bash, Edit, or other tools
```

### resources/examples.md

```markdown
# Usage Examples

## Example 1: New Feature Design

User: "I want to design a notification system"

Skill activates (keywords detected)
  ↓ Phase 0: Research
  ↓ Phase 1: AskUserQuestion loop
  ↓ User says "crystallize"
  ↓ Phase 2: Coherence check
  ↓ Phase 3: Generate specs

[See Section 4 of main spec for detailed example]

## Example 2: Adding to Existing System

[Additional examples...]
```

---

## 10. Key Design Decisions

### Why AskUserQuestion is Core?

**Prevents assumptions:**
- LLM can't read minds
- Requirements are discovered through conversation
- Trade-offs require user judgment

**Enables critical thinking:**
- Forces LLM to identify options
- Makes trade-offs explicit
- Allows user to guide design

### Why Tool Restrictions?

**Prevents:**
- Running code during design (premature)
- Modifying existing code (not design phase)
- Executing tests (not ready yet)

**Allows:**
- Reading code (understanding patterns)
- Creating specs (output)
- Searching (research)
- Asking questions (refinement)

### Why Continuous Loop Until "Crystallize"?

**Design needs time:**
- First idea often not best
- Edge cases emerge through discussion
- Architecture solidifies iteratively

**User is in control:**
- They decide when design is ready
- They can iterate as long as needed
- No premature crystallization

### Why Critical Thinking Framework?

**Quality matters:**
- Simple is better than clever
- YAGNI prevents over-engineering
- Explicit trade-offs enable informed decisions

**Consistency matters:**
- Following existing patterns reduces cognitive load
- Diverging needs strong justification

---

## 11. Notes

### When to Use Skill vs Manual

**Use skill when:**
- Need help structuring thoughts
- Unsure about architecture decisions
- Want interactive exploration
- Need coherence validation

**Create manually when:**
- Design is already clear
- Prefer writing directly
- Small, simple feature

**Skill is optional,** not required.

### Skill is Self-Contained

- No references to external projects
- Reproducible from this spec alone
- All resources bundled in skill directory

---

**Implementation:** Create `.claude/skills/feature-designer/` following structure in Section 8.

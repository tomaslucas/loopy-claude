# Critical Guardrails

## 🚨 Specs ≠ Code

### The Rule
- ❌ DO NOT increment VERSION
- ❌ DO NOT update CHANGELOG.md
- ✅ DO update specs/README.md (PIN) including:
  - Active Specs table entry
  - Search Keywords by Topic (for semantic discovery)
  - Key Design Decisions (if cross-cutting)

### Why This Matters (CRITICAL)

Specs are design documents, not code releases. Version and changelog updates signal shipped functionality to users and deployment systems.

**PIN sections serve different purposes:**
- **Active Specs table**: Quick navigation to spec files
- **Search Keywords**: Semantic discovery (find specs by concept, not filename)
- **Key Design Decisions**: Cross-cutting decisions visible without reading each spec

**What happens if you violate this:**

```
Scenario: You design a new feature and increment VERSION
↓
VERSION file: 0.4.0 → 0.5.0
↓
CI/CD sees new version
↓
Deployment pipeline triggered
↓
ERROR: No actual code changes, just spec updates
↓
Failed deployment, confused team
```

**Specs vs Code:**
- Specs = planning phase (no version change)
- Code implementation = execution phase (version change)
- PIN update = navigation aid (always update)

**Real cost:**
- False deployment triggers: 30-60 minutes debugging
- Team confusion: "Did we ship 0.5.0?"
- Rollback procedures unnecessarily invoked

---

## 🔍 Phase 0 is Mandatory

### The Rule
- Never spec based on assumptions
- Always research first

### Why This Matters (CRITICAL)

Assuming how systems work leads to impossible or conflicting specifications.

**Failure case without Phase 0:**

```
Day 1: User asks to design "authentication improvement"
       LLM assumes OAuth2 is used
       Creates spec based on OAuth2 assumptions
       ✅ Spec looks great

Day 2: Plan mode tries to implement
       Discovers system uses JWT, not OAuth2
       💥 Spec is incompatible with reality

Day 3: Must redesign entire spec
       ♻️ Wasted effort

Cost: 2+ days
```

**Success with Phase 0:**

```
Day 1: User asks to design "authentication improvement"
       LLM reads specs/README.md (PIN)
       Searches for "auth" in specs/
       Finds auth-system.md
       Reads it: uses JWT
       Designs spec for JWT enhancement
       ✅ Compatible from day 1

Cost: 1 day
Savings: 1+ day
```

**Phase 0 prevents:**
- Impossible specifications
- Conflicting designs
- Duplicating existing features
- Breaking existing patterns

---

## 🎯 Wait for Explicit Trigger

### The Rule
- Only crystallize when user says so
- Don't rush to formalize

### Why This Matters (IMPORTANT)

Good design emerges through iteration. Premature crystallization locks in poor decisions.

**Failure case: Rushing to crystallize**

```
User: "I want notifications"

LLM immediately: "Great! Creating spec..."
↓
Assumes email notifications
↓
Creates notification-system.md
✅ Done quickly

User: "Wait, I meant push notifications for mobile"
↓
Spec is wrong
♻️ Must redo entire spec

Cost: Wasted work + user frustration
```

**Success: Iterative refinement**

```
User: "I want notifications"

LLM: "What channels?" (AskUserQuestion)
User: "Email and push"

LLM: "Real-time or batch?" (AskUserQuestion)
User: "Real-time"

LLM: "Delivery guarantees?" (AskUserQuestion)
User: "Best-effort is fine"

[... 3-5 more questions ...]

User: "Looks good, crystallize it"
↓
LLM creates complete, accurate spec
✅ Right the first time

Cost: Same time, better outcome
```

**Trigger phrases to wait for:**
- "crystallize"
- "create the specs"
- "generate specifications"
- "ready to formalize"
- "looks good, write it up"

---

## 📦 Batch Crystallization

### The Rule
- Create all specs at once
- Update PIN once at end

### Why This Matters

Batch operations prevent partial states and ensure atomic updates.

**Wrong: One at a time**
```
Create auth-system.md → Update PIN
Create user-system.md → Update PIN
Create notification-system.md → Update PIN

Issues:
- PIN updated 3 times (3 commits)
- Intermediate states are incomplete
- User might interrupt between specs
```

**Right: Batch creation**
```
Create auth-system.md
Create user-system.md
Create notification-system.md
Update PIN once with all three

Benefits:
- One atomic operation
- PIN always consistent
- Cleaner git history
```

---

## 🎨 One Topic = One Spec

### The Rule
- Use "One Sentence Without 'And'" test

### Why This Matters

Single responsibility makes specs maintainable and understandable.

**Examples:**

✅ **Good (one topic):**
- "Auth system manages user identity"
- "Notification system delivers messages to users"
- "Payment system processes transactions"

❌ **Bad (multiple topics):**
- "User system handles auth, profiles, and billing"
  → Split into: auth-system.md, user-profile-system.md, billing-system.md

**Real consequence of violating:**

```
Bad spec: user-management-system.md
Contains: authentication, profiles, notifications, billing

Problem:
- 800 lines long, hard to read
- Changes to auth require touching notification code
- Unclear boundaries
- Multiple teams need to coordinate on one file

After split:
- auth-system.md (150 lines) → Auth team owns
- user-profile-system.md (100 lines) → User team owns
- notification-system.md (200 lines) → Messaging team owns
- billing-system.md (180 lines) → Finance team owns

Result: Clear ownership, easier maintenance
```

---

## 🧪 Non-Goals Are Critical

### The Rule
- Every spec must have explicit non-goals

### Why This Matters (CRITICAL)

Non-goals prevent scope creep and set clear boundaries.

**Without non-goals:**

```
Spec: "Notification system delivers messages"

Team member A: "Should we support SMS?"
Team member B: "What about Slack integration?"
Team member C: "Can we add scheduling?"

Result: Scope balloons, project delays
```

**With non-goals:**

```
Spec: "Notification system delivers messages"

Goals:
- Email delivery
- Push notifications (iOS, Android)

Non-Goals:
- ❌ SMS (expensive, different regulations)
- ❌ Slack/Discord (future phase)
- ❌ Scheduled delivery (v2 feature)
- ❌ Rich media (images, video)

Result: Clear boundaries, focused implementation
```

**Non-goals save time by:**
- Preventing feature creep
- Making trade-offs explicit
- Setting expectations upfront
- Allowing quick "no" to out-of-scope requests

---

## 🔗 Coherence is Mandatory

### The Rule
- All specs must be 100% aligned
- Validate before crystallization
- Block until conflicts resolved

### Why This Matters (CRITICAL)

Inconsistent specs cause implementation failures, integration breakage, and wasted effort.

**Real failure case:**

```
Scenario: Skipping coherence validation

Day 1: Design notification-system
       - Decides on Python 3.11+, Pydantic v2, PostgreSQL
       - Creates spec without checking existing
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

**Success with coherence validation:**

```
Day 1: Design notification-system
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

Total Cost: 3 days
Savings: 4 days (57% faster)
```

### Common Conflicts to Check

**Language/Runtime Version:**
- Python 3.8 vs 3.11+
- Node 16 vs 18+
- Go 1.19 vs 1.21+

**Libraries:**
- Pydantic v1 vs v2
- React 16 vs 18
- FastAPI vs Flask

**Data Storage:**
- PostgreSQL vs SQLite
- Redis vs in-memory cache
- MongoDB vs SQL database

**API Formats:**
- REST vs GraphQL
- JSON vs XML
- Sync vs async

---

## 🔧 Tool Restrictions

### The Rule
- Read, Write, Grep, Glob, AskUserQuestion ONLY
- No Bash, Edit, or other tools

### Why This Matters

Design phase should not execute code or modify existing implementations.

**Allowed tools:**
- **Read**: Study existing specs and code patterns
- **Write**: Create new specification files
- **Grep**: Search for patterns in codebase
- **Glob**: Find related files
- **AskUserQuestion**: Iterative refinement loop

**Forbidden tools:**
- ❌ **Bash**: No code execution during design
- ❌ **Edit**: No modifying existing code
- ❌ **Task**: No launching other processes
- ❌ **NotebookEdit**: No Jupyter modifications

**Why forbidden:**

```
❌ Using Bash to run tests during design:
   - Tests might fail (normal during design phase)
   - Failures create confusion
   - Design should be theoretical, not executable

❌ Using Edit to modify code:
   - Design phase ≠ implementation phase
   - Premature changes before spec is solid
   - Violates separation of concerns

✅ Using Read to understand code:
   - Informs design decisions
   - Ensures compatibility
   - Non-invasive research
```

---

## Summary: Cost of Violations

| Guardrail Violated            | Immediate Cost               | Long-term Cost                 |
| ----------------------------- | ---------------------------- | ------------------------------ |
| Specs ≠ Code (VERSION update) | 30-60 min (false deployment) | Team confusion, broken process |
| Skip Phase 0                  | 1-2 days (rework specs)      | Impossible implementations     |
| Premature crystallization     | 1-2 hours (redo spec)        | Poor design quality            |
| No batch ops                  | 3x commits, messy history    | Maintenance overhead           |
| Multiple topics per spec      | 2x reading time              | Unclear ownership              |
| No non-goals                  | Scope creep (weeks)          | Project delays                 |
| Skip coherence validation     | 3-5 days (rework)            | Integration failures           |
| Wrong tools                   | Confusion, errors            | Process breakdown              |

**ROI of following guardrails: 10,000%+**

Spending 30 minutes on proper Phase 0 and Phase 2 validation saves days of rework.

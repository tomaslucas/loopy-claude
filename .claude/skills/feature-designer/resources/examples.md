# Usage Examples

## How the Skill Activates

User types natural language trigger → Skill detects keywords → Phases 0-3 execute

**Trigger keywords:**
- "design a feature"
- "plan [feature]"
- "architect [system]"
- "add functionality"
- "design notification system"

---

## Example 1: New Feature Design (Notification System)

### User Request

```
User: "I want to design a notification system"
```

### Skill Activation Flow

```
Trigger detected: "design" + "notification system"
  ↓
Phase 0: Research
  - Read specs/README.md (PIN)
  - Search for related specs (messaging, alerts, etc.)
  - Review existing code patterns
  - Verify assumptions with user
  ↓
Phase 1: Iterative Requirements Loop
  - AskUserQuestion: What notification channels?
  - AskUserQuestion: Delivery guarantees?
  - AskUserQuestion: Storage requirements?
  - AskUserQuestion: Testing strategy?
  - ... (continues until design is solid) ...
  ↓
User says: "crystallize"
  ↓
Phase 2: Coherence Validation
  - Check for conflicts with existing specs
  - Validate consistency
  - Resolve any conflicts via AskUserQuestion
  ↓
Phase 3: Crystallization
  - Generate specs/notification-system.md
  - Update specs/README.md (PIN)
  - Confirm completion
```

### Example Interaction

```
User: "I want to design a notification system"

LLM (Phase 0):
Let me research existing specs and code patterns first.
[Reads specs/README.md, searches for related patterns]

LLM (Phase 1):
I found some existing patterns. Let me ask about requirements.

AskUserQuestion:
┌─────────────────────────────────────────────────────┐
│ Question: What notification channels?               │
│                                                     │
│ Options:                                            │
│ ○ Email only (Recommended for MVP)                 │
│   Pro: Simple, fewer dependencies, well-tested     │
│   Con: Not real-time, requires email config        │
│                                                     │
│ ○ Email + Push notifications                       │
│   Pro: Real-time, better UX for mobile users       │
│   Con: Requires APNS/FCM, token management         │
│                                                     │
│ ○ Email + Push + In-app                           │
│   Pro: Full-featured, all bases covered            │
│   Con: Highest complexity, most dependencies       │
└─────────────────────────────────────────────────────┘

User selects: "Email + Push"

LLM:
Good choice. Now let's think about delivery guarantees.

AskUserQuestion:
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
└─────────────────────────────────────────────────────┘

[... conversation continues ...]

User: "crystallize"

LLM (Phase 2):
Checking coherence with existing specs...
No conflicts detected.

LLM (Phase 3):
Created specs/notification-system.md
Updated specs/README.md
Design complete!
```

---

## Example 2: Adding to Existing System (Authentication Enhancement)

### User Request

```
User: "Add OAuth support to our authentication system"
```

### Skill Activation Flow

```
Trigger detected: "add" + "authentication"
  ↓
Phase 0: Research
  - Read specs/README.md
  - Find existing auth-system.md spec
  - Read auth-system.md COMPLETELY
  - Review current auth implementation in code
  - Identify integration points
  ↓
Phase 1: Iterative Requirements Loop
  - AskUserQuestion: Which OAuth providers?
  - AskUserQuestion: Keep existing auth or migrate?
  - AskUserQuestion: Session management strategy?
  - AskUserQuestion: User account linking approach?
  - ... (continues) ...
  ↓
User says: "looks good, write it up"
  ↓
Phase 2: Coherence Validation
  - Compare with existing auth-system.md
  - Detect conflicts (session storage, user model)
  - Present conflicts to user
  - User chooses resolution
  ↓
Phase 3: Crystallization
  - Update specs/auth-system.md (enhance existing)
  - OR create specs/oauth-integration.md (new spec)
  - Update specs/README.md (PIN)
```

### Example Interaction

```
User: "Add OAuth support to our authentication system"

LLM (Phase 0):
Let me research your current authentication setup.
[Reads specs/auth-system.md, reviews code]

I see you have JWT-based auth currently. Let me ask about OAuth integration.

LLM (Phase 1):
AskUserQuestion:
┌─────────────────────────────────────────────────────┐
│ Question: Which OAuth providers to support?         │
│                                                     │
│ Options:                                            │
│ ○ Google only (Recommended for MVP)                │
│   Pro: Single provider, simpler testing            │
│   Con: Limited user choice                         │
│                                                     │
│ ○ Google + GitHub                                  │
│   Pro: Developer-friendly, covers most use cases   │
│   Con: Two provider configs to maintain            │
│                                                     │
│ ○ Generic OAuth 2.0 (supports any provider)       │
│   Pro: Maximum flexibility                         │
│   Con: Complex configuration, more edge cases      │
└─────────────────────────────────────────────────────┘

User selects: "Google + GitHub"

LLM:
AskUserQuestion:
┌─────────────────────────────────────────────────────┐
│ Question: How to handle existing users?             │
│                                                     │
│ Options:                                            │
│ ○ Keep both (password + OAuth) (Recommended)       │
│   Pro: Users keep existing login, add OAuth later  │
│   Con: Two auth paths to maintain                  │
│                                                     │
│ ○ Migrate all to OAuth only                        │
│   Pro: Single auth system, simpler code            │
│   Con: Forces users to change, potential friction  │
│                                                     │
│ ○ OAuth only for new users                         │
│   Pro: Gradual transition                          │
│   Con: Dual system indefinitely                    │
└─────────────────────────────────────────────────────┘

[... continues ...]

User: "ready to formalize"

LLM (Phase 2):
Checking coherence with specs/auth-system.md...

Detected conflict:
- Current spec: JWT stored in httpOnly cookie
- OAuth flow: Needs state parameter in session storage

AskUserQuestion:
┌─────────────────────────────────────────────────────┐
│ Question: How to resolve session storage conflict?  │
│                                                     │
│ Options:                                            │
│ ○ Add session storage for OAuth flow only          │
│   Pro: Minimal changes to existing auth            │
│   Con: Two storage mechanisms                      │
│                                                     │
│ ○ Migrate all auth to session-based                │
│   Pro: Unified approach                            │
│   Con: Breaking change for existing users          │
└─────────────────────────────────────────────────────┘

User selects: "Add session storage for OAuth flow only"

LLM (Phase 3):
Updated specs/auth-system.md with OAuth integration
Updated specs/README.md (PIN)
Design complete!
```

---

## Example 3: Complex Multi-Spec Design (API Gateway)

### User Request

```
User: "Design an API gateway with rate limiting, auth, and logging"
```

### Skill Flow (Multi-Topic)

```
Trigger detected: "design" + "API gateway"
  ↓
Phase 0: Research
  ↓
Phase 1: Topic Identification

  LLM: This involves multiple topics:
  - API gateway routing
  - Rate limiting
  - Authentication middleware
  - Logging system

  Apply "One Sentence Without 'And'" test:
  ❌ "Gateway handles routing and rate limiting and auth" (multiple topics)
  ✅ Split into separate concerns

  AskUserQuestion: Should these be separate specs?
  User confirms: Yes

  ↓ FOR EACH TOPIC (iterate):

  Topic 1: API Gateway (routing)
    - AskUserQuestion loop for routing
    - Design solidifies

  Topic 2: Rate Limiting
    - AskUserQuestion loop for rate limits
    - Design solidifies

  Topic 3: Auth Middleware
    - Check if auth-system.md exists
    - Determine if enhancement or new spec

  Topic 4: Logging
    - AskUserQuestion loop for logging

  ↓
User: "crystallize"
  ↓
Phase 2: Cross-Spec Coherence
  - Validate all 4 topics are consistent
  - Check integration points
  - Resolve conflicts
  ↓
Phase 3: Batch Crystallization
  - Create specs/api-gateway-system.md
  - Create specs/rate-limiting.md
  - Update specs/auth-system.md (if exists)
  - Create specs/logging-system.md
  - Update specs/README.md (single update for all)
```

---

## Key Patterns in Examples

### Phase 0-3 Workflow

All examples follow the same pattern:

1. **Phase 0: Research** (mandatory)
   - Read PIN (specs/README.md)
   - Search for related specs
   - Review existing code
   - Verify assumptions

2. **Phase 1: Iterative Loop** (conversation)
   - Continuous AskUserQuestion
   - Critical thinking about trade-offs
   - Explore edge cases
   - Stay in loop until user triggers crystallization

3. **Phase 2: Coherence** (validation)
   - Check for conflicts
   - Present conflicts to user
   - Get user decision
   - Ensure 100% consistency

4. **Phase 3: Crystallization** (generation)
   - Batch create all specs
   - Update PIN once
   - Confirm completion

### Critical Elements

Every example demonstrates:
- ✅ Explicit trigger words ("crystallize", "write it up")
- ✅ AskUserQuestion with 2-4 options + trade-offs
- ✅ Critical thinking (Pro/Con, Use when)
- ✅ Research before design
- ✅ Coherence validation
- ✅ Batch spec generation

### What NOT to Do

Examples avoid:
- ❌ Crystallizing without user trigger
- ❌ Yes/no questions (always provide options)
- ❌ Assuming user wants "obvious" choice
- ❌ Skipping Phase 0 research
- ❌ Creating specs one at a time (always batch)
- ❌ Ignoring conflicts between specs

---

## Quick Reference: User Triggers

**Activation triggers:**
- "design [feature]"
- "architect [system]"
- "plan [functionality]"
- "add [feature]"

**Crystallization triggers:**
- "crystallize"
- "create the specs"
- "generate specifications"
- "ready to formalize"
- "looks good, write it up"
- "create specs now"

**Never crystallize unless user says one of these explicitly.**

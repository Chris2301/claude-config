---
description: Interview the user to define a new feature, then generate planning artifacts (proposal, specs, design, tasks)
---

### `/propose-feature-interview`

Conduct an adaptive, technically deep interview with the user to understand a new feature, then generate planning artifacts.

**All output artifacts MUST be written in English**, regardless of the conversation language.

## Instructions

### Phase 1: Feature Discovery

Conduct the interview in the user's language (e.g. Dutch), but make clear that the generated artifacts will be in English.

#### Step 1 — What and Why

Ask the user:
1. **What** do you want to build? (short description)
2. **Why** is this needed? (what problem does it solve, who benefits?)

Wait for answers before continuing.

#### Step 2 — Scope

Based on the answers, ask:
3. What is **in scope**? (confirm your understanding, ask if anything is missing)
4. What is **out of scope**? (explicitly exclude things to prevent scope creep)

Wait for answers before continuing.

### Phase 2: Domain Detection & Technical Deep-Dive

Based on the feature description from Phase 1, determine which domains are affected. Ask the user to confirm:

> "Based on your description, this feature touches: **[list domains]**. Is that correct, or should I add/remove any?"

Domains: `backend`, `frontend`, `database`, `infrastructure`

Then, for EACH affected domain, conduct a **domain-specific interview round**. Only ask questions for the domains that are relevant.

#### Preparing for the deep-dive

Before asking domain-specific questions, read the relevant knowledge sources:

1. **Always read**: `openspec/project.md` — domain model, tech stack, architecture, existing entities
2. **Read current accumulated state** to understand what already exists:
   - `openspec/specs/spec.md` — existing customer journeys across all completed features
   - `openspec/specs/design.md` — existing technical design decisions
   Present a brief summary to the user: *"The system currently has these journeys: [list]. And these key design decisions: [list]. This feature will likely affect: [specific journeys/decisions]."*
   If both files are empty, note: *"No journeys or design decisions have been recorded yet — this will be the first."*
3. **Per affected domain**, read the corresponding agent definition to absorb its expertise:
   - `backend` → read `.claude/agents/spring-engineer.md` (BCE pattern, stateless principles, TDD workflow, code conventions, Java 21 / Spring Boot patterns)
   - `frontend` → read `.claude/agents/angular-engineer.md` (Angular v21, signals, NgRx Signal Store, standalone components, Signal Forms / Reactive Forms, httpResource/resource, routing, Vitest for unit tests, Playwright for E2E)
   - `infrastructure` → read `.claude/agents/devops-engineer.md` (k3s, Helm, Docker, Traefik, resource constraints, monitoring)
4. **MUST read** reviewer agents for additional perspective on what matters:
   - `.claude/agents/architect-reviewer.md` — architectural concerns, BCE compliance, API design
   - `.claude/agents/security-reviewer.md` — auth, secrets, OWASP concerns
   - `.claude/agents/performance-reviewer.md` — N+1 queries, bundle size, indexing

Use this absorbed knowledge to:
- Ask **informed, specific questions** that a senior engineer in that domain would ask
- **Suggest options** based on the tech stack and conventions (e.g. "Would a table component work here, or do you need something more custom?")
- **Proactively flag** things the user might not think of (e.g. "Since we use BCE, the business logic should live in a service, not the controller — do you have a sense of the validation rules?")
- **Reference existing patterns** from the project (e.g. "The domain model already has User → Site as 1:N — does this new entity hang off Site or User?")

#### Conducting the domain interviews

For each affected domain, ask **5-7 focused questions** derived from the agent's expertise and the project context. The questions are NOT hardcoded — generate them dynamically based on:
- What the agent definition says matters for that domain (patterns, conventions, constraints)
- What already exists in `openspec/project.md` (entities, modules, relationships)
- What the user described in Phase 1 (don't re-ask what's already clear)

**Guidelines per domain:**

- **Backend**: Focus on entities, business rules, API contract, relationships to existing domain model, error handling, external integrations. Think in BCE layers: what's boundary (controller/DTO), what's control (service logic), what's entity (domain model)?
- **Frontend**: Focus on user flows, component breakdown, state management strategy (local signals vs. shared signal store), forms and validation, UI component choices, empty/loading/error states. Think in terms of: what does the user see and do?
- **Database**: Focus on table design, column types and constraints, foreign keys to existing tables, indexes for expected queries, migration approach. Often overlaps with backend — only ask what wasn't covered there.
- **Infrastructure**: Focus on configuration needs, service topology, resource constraints (single-node k3s, ~32GB RAM), environment variables, health checks, monitoring.

**IMPORTANT — You are a senior technical consultant, not a passive interviewer:**

1. **Suggest before you ask.** Don't present a blank slate — come with a concrete proposal based on the agent's expertise and let the user react. For example:
   - "Based on the Angular conventions, I'd suggest a standalone `SiteListComponent` with a `SiteStore` signal store — does that align with what you're thinking?"
   - "For this entity, you'll probably need at minimum: id, name, userId (FK), createdAt. What other fields?"
   - "Since we're stateless, session-based approaches won't work — shall we use JWT claims for this?"

2. **Keep iterating.** After the user answers, don't just move on — analyze their answer and follow up:
   - Spot gaps: "You mentioned a list view, but what happens when the user clicks an item? Edit in-place, detail page, or modal?"
   - Spot risks: "If users can delete sites, should we soft-delete (keep data) or hard-delete? This affects the database design."
   - Spot opportunities: "Since you need filtering, a search input with debounced search would pair well with the table — want me to include that?"
   - Connect domains: "The validation rule you described for the backend (max 10 sites per user) — should the frontend also enforce this and disable the 'add' button, or only show an error after submit?"

3. **Think ahead for the user.** Proactively bring up things they haven't mentioned but will need:
   - "You'll need loading states for this API call — skeleton loader or spinner?"
   - "This endpoint returns a list — should we add pagination now or is the data volume small enough to skip it?"
   - "For this form, do you want optimistic UI updates or wait for the server response?"

4. **Continue until the picture is complete.** Each domain round is not a fixed set of questions — it's a conversation. Keep going until you and the user agree that the domain is sufficiently covered. Signal when you think a domain is complete: "I think we've covered the backend well enough to generate tasks — anything else, or shall we move to frontend?"

Wait for answers after each domain round before continuing to the next.

---

### Phase 3: E2E Test Journeys

After the domain deep-dives, discuss how this feature fits into the E2E test landscape. No separate artifact — the conclusions feed directly into the tasks.

#### Preparation

1. Search the codebase for existing E2E tests: look for `e2e/`, `tests/e2e/`, `playwright/` directories and `*.spec.ts` files
2. If E2E tests exist, read them and present a short overview to the user:
   - Which journeys exist today (file name + one-line summary per journey)
   - How they're organized (by journey, by page, by feature)

#### The conversation

Present the overview of existing E2E tests (or note that none exist yet), then discuss:

1. **Does this feature extend an existing journey or need a new one?** Suggest based on what you see.
2. **What's the most valuable journey to add?** Propose a concrete flow: "User starts at X, does Y, sees Z" — based on the user flows from the frontend domain round. Frame it as: "If you watched this in `--headed` mode, would it demo the feature?"
3. **What's NOT worth an E2E test?** Actively steer the user away from over-testing: "The empty state is a single-component check — unit test is enough there."
4. **Which existing tests might break?** Flag if the feature changes behavior covered by current journeys.

Same rules as the domain rounds — suggest, iterate, keep it practical.

Wait for confirmation before continuing.

---

### Phase 4: Confirm Understanding

Summarize your understanding back to the user in a structured overview:

- **Feature**: one-line summary
- **Why**: the motivation
- **Scope**: in/out
- **Journey impact** (how this feature changes the customer experience):
  - **New journeys**: [list each new journey with a one-line description]
  - **Modified journeys**: [list existing journeys that change, with before/after summary]
  - **Removed journeys**: [list, if any]
- **Design decisions**: [list key technical decisions that will be recorded, e.g. "Auth Provider Abstraction: Mock + OIDC via environment switch"]
- **Per domain** (only affected domains):
  - **Backend**: entities, endpoints, key business rules
  - **Frontend**: key screens/flows, main components, state approach
  - **Database**: tables, key relationships
  - **Infrastructure**: config, services
- **E2E Journeys**: list each E2E test journey with a one-line description (e.g. "User creates a site and sees it in the list")
- **Open questions**: anything still unresolved

Ask: "Is this correct? Anything to add or change?"

Wait for confirmation before proceeding to Phase 5.

### Phase 5: Generate Artifacts

Once the user confirms, generate the planning artifacts.

#### 1. Determine the change name

Convert the feature description to kebab-case (e.g. "add user notifications" → `add-user-notifications`).

#### 2. Read project context

Read these files to understand the project:
1. `openspec/project.md` — architecture, domain model, tech stack, conventions
2. `openspec/specs/` — current state of what is built
3. Relevant files in `openspec/reference/` — technology guides that may apply

#### 3. Create the directory structure

```
openspec/changes/<change-name>/
  proposal.md
  design.md
  tasks.md
  specs/
    <domain>/
      spec.md
```

Create multiple domain folders under `specs/` if the change spans several areas (e.g. `specs/backend/spec.md` + `specs/frontend/spec.md`).

#### 4. Generate each artifact — IN ENGLISH

Use the interview answers to fill in the templates below. **All content MUST be in English.** Translate any Dutch input from the interview into proper English.

**IMPORTANT**: The depth and specificity of the artifacts should reflect the depth of the interview. Use concrete entity names, field names, endpoint paths, component names, etc. from the conversation — not generic placeholders.

---

## Templates

### proposal.md

```markdown
# Proposal: [Change Title]

## Intent
[1-2 sentences: why is this change needed — derived from interview Phase 1]

## Scope
- [What is included — derived from interview Phase 1]
- [What is explicitly out of scope]

## Approach
[1-2 paragraphs: high-level strategy — derived from the technical deep-dive in Phase 2. Reference specific technical choices discussed (e.g. "Use a signal store for X state", "New REST endpoints for Y"). Not full implementation details — that goes in design.md]

## Open Questions
- [Unresolved decisions from the interview]
```

### specs/`<domain>`/spec.md

```markdown
# Spec Delta for [Domain]

## ADDED Journeys

### Journey: [Journey Name — derived from interview Phase 2 user flows]
[Narrative description of what the user experiences, chronologically. Use concrete page names, button labels, and actions from the interview. Describe the full flow from the user's perspective — what they see, what they click, what happens next. Use RFC 2119 keywords (MUST, SHOULD, MAY, etc.) to indicate obligation levels. Include error cases and edge cases as part of the narrative where relevant, e.g. "If the email is not recognized, the system MUST show an error message."]

## MODIFIED Journeys

### Journey: [Existing Journey Name — must match a journey in openspec/specs/spec.md]
[Updated narrative description of the full journey after the change.]
(Previously: [brief description of what the journey was before])

## REMOVED Journeys

### Journey: [Journey Name]
(Reason: [why this journey is being removed])
```

> Only include ADDED, MODIFIED, or REMOVED sections that are relevant. Delete empty sections.
> Create a separate spec.md per domain if the feature spans multiple domains.
> Journeys describe the customer experience chronologically — what the user sees and does, not how the system implements it. Technical details belong in design.md.
> Use [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) keywords (MUST, MUST NOT, SHOULD, SHOULD NOT, MAY) to indicate obligation levels. This makes explicit what is required vs. recommended vs. optional.

### design.md

```markdown
# Design: [Change Title]

## Overview
[1-2 sentences summarizing the technical approach — derived from Phase 2]

## Key Decisions

### [Decision Title]
**Choice:** [What was decided — use specifics from the interview]
**Rationale:** [Why this over alternatives]

## Components Affected

### Backend
- [Entity/Service/Controller] — [what changes, e.g. "new SiteService with CRUD operations"]

### Frontend
- [Component/Store/Service] — [what changes, e.g. "new SiteListComponent with data table"]

### Database
- [Table/Migration] — [what changes]

### Infrastructure
- [Config/Service] — [what changes]

> Only include sections for affected domains. Delete empty domain sections.

## Data Model Changes
[New tables with columns, types, and constraints. Or "None" if no data changes.]
[Reference existing entities from openspec/project.md where relevant.]

## API Changes
[New or modified endpoints with method, path, request/response shape. Or "None" if no API changes.]

## Risks and Mitigations
| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| [Risk description — informed by the error scenarios discussed] | Low/Medium/High | [How to address it] |

## Design Delta

> This section is merged into `openspec/specs/design.md` after feature completion.
> Only include decisions that represent lasting architectural choices — not ephemeral implementation details.

### Decision: [Decision Name — from Key Decisions above]
**Choice:** [What was decided — use specifics from the interview]
**Rationale:** [Why this over alternatives]
```

### tasks.md

```markdown
# Tasks: [Change Title]

# **Critical: TDD approach — tests first!**

## 1. [First Work Area — e.g. "Database: Site table and migration"]
- [ ] 1.1 [Concrete task with specific names — e.g. "Create Site entity with fields: id, name, repoUrl, userId"]
- [ ] 1.2 [Concrete task — e.g. "Create Flyway migration V2__create_site_table.sql"]

## 2. [Second Work Area — e.g. "Backend: Site CRUD API"]
- [ ] 2.1 [Concrete task — e.g. "Write unit tests for SiteService.create() with validation rules"]
- [ ] 2.2 [Concrete task — e.g. "Implement SiteService with create, findByUser, update, delete"]
- [ ] 2.3 [Concrete task — e.g. "Write SiteController with REST endpoints: POST/GET/PUT/DELETE /api/sites"]
- [ ] 2.4 [Concrete task — e.g. "Integration test: full CRUD flow via MockMvc"]

## 3. [Third Work Area — e.g. "Frontend: Site Management"]
- [ ] 3.1 [Concrete task — e.g. "Create SiteStore (signal store) with loadSites, createSite, deleteSite"]
- [ ] 3.2 [Concrete task — e.g. "Create SiteListComponent with data table showing name and repoUrl"]
- [ ] 3.3 [Concrete task — e.g. "Create SiteFormComponent with reactive form and validation"]
- [ ] 3.4 [Concrete task — e.g. "E2E test: user creates a site and sees it in the list"]

## N. Verification
- [ ] N.1 [Cross-domain verification task]
- [ ] N.2 [Final integration/E2E check]
```

> **Task quality guidelines:**
> - Number tasks hierarchically (1.1, 1.2, 2.1, etc.)
> - Each task should be small enough to complete in a single focused session
> - Group by logical work area (database → backend → frontend → infra → E2E journeys → verification)
> - Order respects dependencies: database before backend, backend before frontend, E2E after frontend
> - Use concrete names from the interview: entity names, field names, component names, endpoint paths
> - Each backend/frontend task should imply its TDD cycle (test first, then implement)
> - E2E journey tasks should describe the full user flow (not just "write E2E test") so the implementing agent knows the journey

---

### Phase 6: Present the result

After creating all files, output:

```
Created openspec/changes/<change-name>/
  - proposal.md
  - specs/<domain>/spec.md (per domain)
  - design.md
  - tasks.md
Ready for review. Edit any artifact before implementation.
```

Remind the user they can refine any artifact before starting implementation.

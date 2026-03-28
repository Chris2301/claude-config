---
description: Create a new feature change with planning artifacts (proposal, specs, design, tasks)
---

### `/spec:propose`

Create a new change and generate planning artifacts in one step.

**Syntax:**
```text
/spec:propose [change-name-or-description]
```

**Arguments:**
| Argument | Required | Description |
|----------|----------|-------------|
| `change-name-or-description` | No | Kebab-case name or plain-language change description |

## Instructions

### 1. Determine the change name

If the user provided a plain-language description, convert it to kebab-case (e.g. "add user notifications" becomes `add-user-notifications`). If no argument was given, ask the user what feature or change they want to propose.

### 2. Read project context

Read these files to understand the project before creating artifacts:
1. `openspec/project.md` — architecture, domain model, tech stack, conventions
2. `openspec/specs/` — current state of what is built
3. Relevant files in `openspec/reference/` — technology guides that may apply

### 3. Create the directory structure

Create the following under `openspec/changes/<change-name>/`:

```
openspec/changes/<change-name>/
  proposal.md
  design.md
  tasks.md
  specs/
    <domain>/
      spec.md
```

Choose `<domain>` based on what area of the system the change affects (e.g. `auth`, `ui`, `api`, `data`, `messaging`). Create multiple domain folders if the change spans several areas.

### 4. Generate each artifact using the skeleton templates below

Copy the templates exactly as-is into the files, keeping all `[bracketed placeholders]` intact. Do NOT read the codebase, do NOT research, do NOT fill in placeholders. Just create the files with the raw templates. Use `<change-name>` as the `[Change Title]` and `general` as the default `<domain>`.

---

## Skeleton Templates

### proposal.md

```markdown
# Proposal: [Change Title]

## Intent
The WHY
[1-2 sentences: why is this change needed? e.g. "Users have no way to reset their password without contacting support"]

## Scope
- [What is included in this change, e.g. "Add password reset flow via email"]
- [What is included in this change, e.g. "Rate-limit reset requests to 3 per hour"]
- [What is explicitly out of scope, e.g. "SMS-based reset, admin-initiated reset"]

## Approach
[1-2 paragraphs: High-level strategy, not implementation details — that goes in design.md. e.g. "Use a time-limited signed token sent via email. Validate on a dedicated reset endpoint. Expire after 15 minutes."]

## Open Questions
- [Any unresolved decisions, e.g. "Should the token be single-use or valid until expiry?"]
```

### specs/`<domain>`/spec.md

```markdown
# Spec Delta for [Domain]

## ADDED Journeys

### Journey: [Journey Name, e.g. "Reset password via email"]
[Narrative description of what the user experiences, chronologically. Use RFC 2119 keywords (MUST, SHOULD, MAY, etc.) to indicate obligation levels.
e.g. "When I click 'Forgot password' on the login page, I MUST see a form asking for my email address. After submitting my email, the system MUST send a reset link and I MUST see a confirmation message. When I click the reset link, I MUST be taken to a page where I enter a new password. After submitting, I MUST be redirected to the login page. The reset link MUST expire after 15 minutes and MUST NOT be reusable. The form SHOULD show inline validation errors for invalid email formats."]

## MODIFIED Journeys

### Journey: [Existing Journey Name, e.g. "Log in"]
[Updated narrative description of the full journey after the change.]
(Previously: [brief description of what the journey was before, e.g. "User clicked Login and was instantly logged in."])

## REMOVED Journeys

### Journey: [Journey Name, e.g. "Answer security questions"]
(Reason: [why this journey is being removed, e.g. "Replaced by email-based password reset"])
```

> Only include ADDED, MODIFIED, or REMOVED sections that are relevant. Most new features will only have ADDED. Delete empty sections.
> Journeys describe the customer experience chronologically — what the user sees and does, not how the system implements it. Technical details belong in design.md.
> Use [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) keywords (MUST, MUST NOT, SHOULD, SHOULD NOT, MAY) to indicate obligation levels. This makes explicit what is required vs. recommended vs. optional.

### design.md

```markdown
# Design: [Change Title]

## Overview
The HOW
[1-2 sentences summarizing the technical approach, e.g. "Add a token-based password reset flow using a new ResetService and a transactional email sender"]

## Key Decisions

### [Decision 1 Title, e.g. "Token strategy"]
**Choice:** [What was decided, e.g. "Signed JWT with 15-minute expiry"]
**Rationale:** [Why this over alternatives, e.g. "Stateless — no need to store tokens in the database"]

### [Decision 2 Title, e.g. "Email provider"]
**Choice:** [What was decided, e.g. "SendGrid via SMTP relay"]
**Rationale:** [Why this over alternatives, e.g. "Already used for transactional receipts, no new vendor needed"]

## Components Affected
- [Component/module name, e.g. "auth-service"] — [what changes, e.g. "new ResetController and ResetService"]
- [Component/module name, e.g. "email-service"] — [what changes, e.g. "new reset email template"]

## Data Model Changes
[New tables, columns, schemas, or message formats, e.g. "Add `password_reset_requests` table with columns: id, user_id, token_hash, expires_at". Write "None" if no data changes.]

## API Changes
[New or modified endpoints, e.g. "POST /api/auth/reset-request, POST /api/auth/reset-confirm". Write "None" if no API changes.]

## Risks and Mitigations
| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| [Risk description, e.g. "Token brute-force"] | Low/Medium/High | [How to address it, e.g. "Rate-limit endpoint to 3 attempts per IP per hour"] |

## Design Delta

> This section is merged into `openspec/specs/design.md` after feature completion.

### Decision: [Decision Name, e.g. "Token strategy"]
**Choice:** [What was decided, e.g. "Signed JWT with 15-minute expiry"]
**Rationale:** [Why, e.g. "Stateless — no need to store tokens in the database"]
```

### tasks.md

```markdown
# Tasks: [Change Title]
The WHAT

# **Critical: TDD approach - tests first!**

## 1. [First Work Area, e.g. "Reset Token Infrastructure"]
- [ ] 1.1 [Concrete task, e.g. "Create ResetToken model and repository"]
- [ ] 1.2 [Concrete task, e.g. "Implement token generation with signed JWT"]
- [ ] 1.3 [Concrete task, e.g. "Add expiry validation logic"]

## 2. [Second Work Area, e.g. "API Endpoints"]
- [ ] 2.1 [Concrete task, e.g. "Add POST /reset-request endpoint"]
- [ ] 2.2 [Concrete task, e.g. "Add POST /reset-confirm endpoint"]

## 3. [Testing, e.g. "Verification"]
- [ ] 3.1 [Concrete task, e.g. "Unit tests for token generation and validation"]
- [ ] 3.2 [Concrete task, e.g. "Integration test for full reset flow"]
```

> Number tasks hierarchically (1.1, 1.2, 2.1, etc.). Each task should be small enough to complete in a single focused session. Group by logical work area, not by file.

---

## 6. Present the result

After creating all files, output a summary:

```
Created openspec/changes/<change-name>/
  - proposal.md
  - specs/<domain>/spec.md
  - design.md
  - tasks.md
Ready for review. Edit any artifact before implementation.
```

Remind the user they can refine any artifact before starting implementation — artifacts are living documents that should be updated as understanding evolves.

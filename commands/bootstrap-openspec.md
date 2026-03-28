---
description: Create the openspec folder structure and interview the user to generate project.md and initial specs
---

### `/bootstrap-openspec`

Bootstrap the OpenSpec directory structure and interview the user to define the project context and existing capabilities.

**All output artifacts MUST be written in English**, regardless of the conversation language.

## Instructions

### Phase 0: Check existing state

Check if `openspec/` exists and what it already contains.

- If `openspec/project.md` already exists, warn the user and ask if they want to overwrite or update it.
- If `openspec/specs/` already has specs, list them and ask if the user wants to add more or start fresh.
- If nothing exists yet, proceed directly to Phase 1.

### Phase 1: Create directory structure

Create the following directories if they don't exist:

```
openspec/
├── specs/                  # Truth — what IS built
├── changes/                # Proposals — what SHOULD change
├── archive/                # Completed changes
└── reference/              # Technology guides, conventions
```

### Phase 2: Interview for project.md

Conduct the interview in the user's language (e.g. Dutch), but make clear that the generated artifacts will be in English.

#### Step 1 — Project identity

Ask the user:
1. **What** is this project? (name, one-line description)
2. **Who** is this for? (target users, stakeholders)
3. **What problem** does it solve?

Wait for answers before continuing.

#### Step 2 — Tech stack

Ask the user:
4. What is the **backend** stack? (language, framework, build tool)
5. What is the **frontend** stack? (framework, UI library, state management)
6. What **database(s)** are used?
7. What **infrastructure** is used? (hosting, containers, CI/CD, monitoring)

Offer to pre-fill from CLAUDE.md if it exists and contains tech stack info. Ask the user to confirm or correct.

Wait for answers before continuing.

#### Step 3 — Architecture & conventions

Ask the user:
8. What is the **high-level architecture**? (monolith, microservices, modular monolith, etc.)
9. What are the **main domains/modules** in the system?
10. Are there **naming conventions** or patterns to follow? (e.g. package structure, API style, file naming)
11. What **testing strategy** is used? (TDD, unit/integration/E2E, frameworks)

Wait for answers before continuing.

#### Step 4 — Domain model

Ask the user:
12. What are the **core entities** in the system? (e.g. User, Order, Product)
13. How do they **relate** to each other? (1:N, N:M, ownership)
14. Are there **key business rules** that apply across the system?

Wait for answers before continuing.

#### Step 5 — Confirm project.md

Present a summary of the project context. Ask: "Is this correct? Anything to add or change?"

Wait for confirmation before generating.

### Phase 3: Generate project.md — IN ENGLISH

Write `openspec/project.md` using the template below, filled in with interview answers. **All content MUST be in English.** Translate any non-English input.

```markdown
# Project: [Project Name]

## Overview
[1-2 sentences: what this project is and who it's for]

## Problem Statement
[What problem does this solve]

## Tech Stack

### Backend
- **Language:** [e.g. Java 21]
- **Framework:** [e.g. Spring Boot]
- **Build:** [e.g. Maven]

### Frontend
- **Framework:** [e.g. Angular v21]
- **UI Library:** [ TBD]
- **State Management:** [e.g. NgRx Signal Store]

### Database
- [e.g. PostgreSQL]

### Infrastructure
- **Hosting:** [e.g. k3s/k3d]
- **Containers:** [e.g. Docker, Helm]
- **CI/CD:** [e.g. ArgoCD]
- **Monitoring:** [e.g. Grafana + Prometheus + Loki + Tempo]

## Architecture
[High-level architecture description: monolith, microservices, etc.]

### Modules
- **[Module name]** — [what it does]

## Domain Model

### Entities
- **[Entity]** — [description]

### Relationships
- [Entity A] → [Entity B]: [relationship type and description]

### Key Business Rules
- [Rule description]

## Conventions

### Naming
- [Convention, e.g. "All code in English"]
- [Convention, e.g. "kebab-case for file names"]

### Testing
- [Strategy, e.g. "TDD: red-green-refactor"]
- [Frameworks, e.g. "JUnit 5 + Mockito for backend unit tests"]

### Git
- [Convention, e.g. "Conventional commits: feat:, fix:, refactor:"]
- [Convention, e.g. "Main branch: develop"]
```

### Phase 4: Interview for initial specs

After project.md is created, ask the user:

#### Step 6 — Existing capabilities

Ask:
15. What **capabilities** or features are already built? (list them, even roughly)
16. For each capability, what are the **key requirements**? (what MUST the system do?)
17. Are there important **scenarios** to document? (happy path, edge cases)

Group answers by domain/capability. Wait for answers before continuing.

If the user says nothing is built yet or they want to skip specs for now, that's fine — skip to Phase 6.

#### Step 7 — Confirm specs

For each capability, present a summary:
- **Capability name**
- **Requirements** (MUST/SHALL/SHOULD statements)
- **Key scenarios** (GIVEN/WHEN/THEN)

Ask: "Is this correct? Anything to add or change?"

Wait for confirmation before generating.

### Phase 5: Generate specs — IN ENGLISH

For each capability, create `openspec/specs/<capability>/spec.md` using this template:

```markdown
# [Capability Name]

## Requirements

### Requirement: [Requirement Name]
[Clear statement using MUST/SHALL/SHOULD]

#### Scenario: [Scenario name]
- GIVEN [precondition]
- WHEN [action or event]
- THEN [expected outcome]
- AND [additional outcome]
```

Use kebab-case for `<capability>` folder names (e.g. `user-auth`, `order-management`).

### Phase 6: Present the result

After creating all files, output a tree of what was created:

```
Created openspec/
  - project.md
  - specs/
    - <capability>/spec.md
    - ...
  - changes/       (empty — use /propose-feature to add changes)
  - archive/       (empty — completed changes go here)
  - reference/     (empty — add technology guides here)
```

Remind the user:
- `project.md` is the source of truth for project context — keep it updated
- `specs/` documents what IS built — update after each feature ships
- Use `/propose-feature` or `/propose-feature-interview` to plan new changes
- All artifacts are living documents — refine as understanding evolves

---
name: architecture-review
description: Architecture review criteria for full-stack cloud-native applications
---

# Architecture Review Skill

## Core Philosophy

**KISS FIRST** — Readability and simplicity always come first. Do not reward complexity. Flag unnecessary abstractions, premature generalizations, and over-engineered solutions. The simplest correct solution is the best solution.

## Core Review Process

1. **Read changes** — Understand the full scope of the diff. Identify all files touched, new classes, new endpoints, new dependencies, and structural changes.
2. **Map to architecture baseline** — Verify the changes follow the established patterns: BCE (Boundary-Control-Entity), package-per-feature, and the project's conventions. See `references/backend-patterns.md` and `references/frontend-patterns.md`.
3. **Check cloud-native compliance** — Verify statelessness, externalized config, and proper health/readiness endpoints. See `references/cloud-native.md`.
4. **Scan for anti-patterns** — Check for over-engineering, tight coupling, leaky abstractions, and circular dependencies. See `references/backend-patterns.md`.
5. **Review API design** — Check RESTful conventions, DTO separation, consistent response format, and OpenAPI consistency. See `references/cloud-native.md`.
6. **Check cross-cutting concerns** — Verify error handling, logging, validation, and configuration follow project standards.

## Reference Guide

| Topic                  | Reference File                      |
|------------------------|-------------------------------------|
| Backend Patterns       | `references/backend-patterns.md`    |
| Frontend Patterns      | `references/frontend-patterns.md`   |
| Cloud-Native Rules     | `references/cloud-native.md`        |

## Re-review Scope (Cycle 2+)

When performing a follow-up review after fixes have been applied:

- Only evaluate the changes made in response to previous findings.
- Do NOT introduce new findings unless they are **Critical** severity.
- Flag regressions introduced by the fixes themselves.
- Confirm previous findings are resolved and mark them as such.

## Output Format

Report findings using the following severity levels:

- **Critical** — Architectural violation that will cause production issues, data loss, or blocks horizontal scaling. Must be fixed before merge.
- **Warning** — Deviation from project conventions or design smell that should be addressed. Will cause maintenance burden if left unfixed.
- **Suggestion** — Improvement opportunity. Not blocking, but would improve code quality or maintainability.

Each finding must include: severity, file and line reference, description of the issue, and a concrete remediation suggestion.

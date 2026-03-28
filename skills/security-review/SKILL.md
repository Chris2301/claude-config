---
name: security-review
description: Security review criteria for backend, frontend, and Kubernetes
metadata:
  domain: security
  triggers:
    - security review
    - vulnerability
    - OWASP
    - auth
    - secrets
---

# Security Review Skill

## Core Review Process

1. **Read changes** — Understand the full scope of the diff. Identify all files touched, new endpoints, new dependencies, and configuration changes.
2. **Map to OWASP** — Cross-reference every change against the OWASP Top 10 and OWASP API Security Top 10. See `references/owasp.md`.
3. **Check authentication and authorization** — Verify that every endpoint has explicit authorization, tokens are validated correctly, and frontend auth flows are secure. See `references/authentication.md`.
4. **Check secrets and data exposure** — Scan for hardcoded secrets, PII in logs, sensitive data in URLs, and insecure storage of tokens or credentials. See `references/owasp.md`.
5. **Check infrastructure** — Verify container security, Kubernetes pod security, network policies, and ingress configuration. See `references/infrastructure.md`.
6. **Check compliance** — Ensure changes do not introduce stateful behavior, bypass TLS, or weaken existing security controls.

## Reference Guide

| Topic                  | Reference File                      |
|------------------------|-------------------------------------|
| Authentication & Auth  | `references/authentication.md`      |
| OWASP Checklists       | `references/owasp.md`               |
| Infrastructure Security| `references/infrastructure.md`      |

## Output Format

Report findings using the following severity levels:

- **Critical** — Exploitable vulnerability or missing security control that must be fixed before merge. Include the relevant OWASP category (e.g., A01: Broken Access Control).
- **High** — Security weakness that significantly increases risk. Include the relevant OWASP category.
- **Medium** — Defense-in-depth gap or missing best practice that should be addressed. Include the relevant OWASP category where applicable.
- **Low** — Minor hardening opportunity or informational note.

Each finding must include: severity, file and line reference, description of the issue, the relevant OWASP category (if applicable), and a concrete remediation suggestion.

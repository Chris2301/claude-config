# OWASP Reference

## OWASP Top 10 (Web Applications)

### A01: Broken Access Control
- Missing or incorrect authorization checks on endpoints.
- IDOR (Insecure Direct Object Reference): user can access resources by changing IDs in the URL.
- Missing function-level access control (e.g., admin endpoints accessible to regular users).
- CORS misconfiguration allowing unauthorized origins.

### A02: Cryptographic Failures
- Sensitive data transmitted without TLS.
- Weak hashing algorithms (MD5, SHA1) for passwords. Require bcrypt/scrypt/argon2.
- Missing encryption for sensitive data at rest.
- Hardcoded encryption keys or secrets.

### A03: Injection
- SQL injection: flag raw SQL concatenation, unparameterized queries, native queries without bind parameters.
- XSS: flag unescaped user input rendered in HTML (backend templates or frontend innerHTML/bypassSecurityTrust).
- Command injection: flag Runtime.exec() or ProcessBuilder with user input.
- LDAP/NoSQL injection where applicable.

### A05: Security Misconfiguration
- Debug mode enabled in production configuration.
- Default credentials or accounts.
- Unnecessary HTTP methods enabled.
- Missing security headers (Content-Security-Policy, X-Frame-Options, X-Content-Type-Options, Strict-Transport-Security).
- Stack traces or verbose error messages exposed to clients.

### A06: Vulnerable and Outdated Components
- Dependencies with known CVEs.
- Outdated framework or library versions.
- Unused dependencies that increase attack surface.

## OWASP API Security Top 10

### Broken Object Level Authorization (API1)
- API endpoints that accept object IDs without verifying the caller owns or has access to the object.
- Flag any endpoint that uses a path variable ID without authorization check against the authenticated user.

### Broken Authentication (API2)
- Weak or missing authentication on API endpoints.
- See `authentication.md` for detailed checks.

### Broken Object Property Level Authorization (API3)
- API responses exposing internal or sensitive properties (internal IDs, password hashes, admin flags).
- Mass assignment: accepting and persisting properties the client should not control.

### Unrestricted Resource Consumption (API4)
- Missing pagination on list endpoints.
- Missing request size limits.
- Missing rate limiting on resource-intensive operations.
- Unbounded file uploads.

### Broken Function Level Authorization (API5)
- Admin or elevated operations accessible without proper role checks.
- Missing distinction between user and admin endpoints.

### Mass Assignment (API6)
- Binding request bodies directly to entity objects without a DTO layer.
- Flag any `@RequestBody` that maps to a JPA entity instead of a DTO.

## Secrets and Data Exposure

- Flag secrets (API keys, passwords, tokens, connection strings) found in:
  - Source code
  - Code comments
  - Test files (unless clearly marked as test-only values)
  - Default/fallback values in configuration
  - Log statements
- Flag PII (names, emails, addresses, phone numbers, national IDs) in log statements.
- Flag sensitive data in URLs (query parameters or path segments).
- Flag sensitive data in error responses returned to clients.

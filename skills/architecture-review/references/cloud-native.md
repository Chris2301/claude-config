# Cloud-Native Architecture Reference

## Stateless Mandates

- No server-side sessions. No `HttpSession`, no `@SessionScope`, no Spring Session with sticky sessions.
- No local file storage for persistent data. Use database or S3-compatible object storage (MinIO).
- Externalize all configuration via environment variables or ConfigMaps. No hardcoded environment-specific values in source code.

## Caching

- In-memory `@Cacheable` (using `ConcurrentMapCacheManager`) is acceptable for single-replica deployments.
- Severity: **Warning** (not Critical) — note that Redis migration is planned for multi-instance scaling.
- Design cache keys and eviction logic to be Redis-compatible for future migration.
- Do NOT add Redis as a dependency yet.

## Configuration

- Flag hardcoded environment-specific configuration (URLs, ports, hostnames, credentials).
- Configuration should work across environments (local, staging, production) via externalized values.
- Spring profiles for environment-specific overrides are acceptable.

## Health and Observability

- Flag missing `/actuator/health` endpoint.
- Flag missing liveness and readiness probes in Kubernetes manifests.
- Logs MUST go to stdout/stderr. Flag any logging to files.
- Structured logging is preferred (JSON format in production).

## API Design

- RESTful conventions: proper HTTP methods, plural resource names, consistent URL structure.
- OpenAPI/Swagger documentation should match the actual API behavior.
- DTO separation: request DTOs, response DTOs, and entities are distinct. Never expose entities directly.
- Consistent response format across all endpoints (especially error responses).
- Pagination on all list endpoints.
- API versioning strategy should be consistent (URL path versioning preferred: `/api/v1/...`).

## Graceful Shutdown

- Spring Boot graceful shutdown must be enabled.
- In-flight requests should complete before shutdown.
- Database connections and external resources should be released cleanly.

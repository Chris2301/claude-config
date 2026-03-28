# Infrastructure Security Reference

## Kubernetes

- Containers MUST run as non-root. Flag missing `runAsNonRoot: true` in pod security context.
- Containers MUST use `readOnlyRootFilesystem: true`. Flag when missing.
- Flag any container running in `privileged: true` mode.
- Flag missing `NetworkPolicies` — pods should have explicit ingress and egress rules.
- Secrets MUST be managed via HashiCorp Vault integration. Flag secrets stored in plaintext ConfigMaps or environment variables in manifests.
- Pod security context MUST set `allowPrivilegeEscalation: false`.
- Flag missing `seccompProfile` settings.

## Container Images

- Images MUST be pulled from the self-hosted Harbor registry only. Flag any image reference to Docker Hub, GHCR, or other public registries in production manifests.
- Production images must not contain unnecessary tools (curl, wget, shell, package managers). Prefer distroless or minimal Alpine-based images.
- Flag missing image vulnerability scanning in the CI pipeline.
- Flag images using `latest` tag instead of a pinned version or digest.

## Traefik / Ingress

- TLS termination MUST be configured on all ingress routes. Flag any HTTP-only ingress rule without redirect to HTTPS.
- Rate limiting middleware MUST be applied to authentication and public-facing endpoints.
- Ingress rules should be as restrictive as possible — only expose required paths.
- Flag missing `X-Forwarded-*` header handling.

## Stateless Violations

- Flag any use of `HttpSession`, `@SessionScope`, or Spring Session with sticky sessions.
- Flag any code that writes to the local filesystem expecting persistence across restarts.
- Flag in-memory state that would break horizontal scaling (e.g., in-memory user sessions, in-memory queues shared across requests).
- In-memory `@Cacheable` is acceptable for single-replica but must be noted as a scaling concern.

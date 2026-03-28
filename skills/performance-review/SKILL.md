---
name: performance-review
description: Performance review criteria for backend, frontend, and infrastructure
---

# Performance Review Skill

## Context

- Self-hosted k3s cluster, single node, approximately 32GB RAM.
- Single replica per service — be resource-conscious.
- Database: PostgreSQL.
- Caching: in-memory (`@Cacheable` with `ConcurrentMapCacheManager`). Redis is planned but not yet added.

## Core Review Process

1. **Read changes** — Understand the full scope of the diff. Identify all files touched, new queries, new endpoints, new dependencies, and data access patterns.
2. **Check database access patterns** — Look for N+1 queries, missing indexes, unbounded queries, and inefficient fetch strategies. See `references/backend-performance.md`.
3. **Check blocking and timeouts** — Identify synchronous calls to external services, missing timeouts, and operations that could block request threads. See `references/backend-performance.md`.
4. **Check memory usage** — Look for unbounded collections, large object graphs, eager fetching, and memory leaks. See `references/backend-performance.md`.
5. **Check frontend bundle and rendering** — Look for bundle size issues, change detection problems, and network inefficiencies. See `references/frontend-performance.md`.
6. **Check container and pod resources** — Verify image sizes, resource requests/limits, and startup configuration. See `references/infrastructure-performance.md`.

## Reference Guide

| Topic                        | Reference File                              |
|------------------------------|---------------------------------------------|
| Backend Performance          | `references/backend-performance.md`         |
| Frontend Performance         | `references/frontend-performance.md`        |
| Infrastructure Performance   | `references/infrastructure-performance.md`  |

## Output Format

Report findings using the following severity levels:

- **Critical** — Will cause production outages, OOM kills, or unacceptable response times under normal load. Must be fixed before merge.
- **Warning** — Performance concern that will degrade user experience or waste resources under expected load. Should be addressed.
- **Info** — Optimization opportunity. Not urgent, but worth noting for future improvement.

Each finding must include: severity, file and line reference, description of the issue, estimated impact, and a concrete remediation suggestion.

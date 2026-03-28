# Backend Performance Reference

## N+1 Queries (HIGHEST PRIORITY)

This is the most common and impactful performance issue in JPA-based applications. Always check for it first.

- Flag JPA relationships (`@OneToMany`, `@ManyToOne`, `@ManyToMany`, `@OneToOne`) without an explicit fetch strategy.
- Flag loops that execute queries inside the loop body (service or repository calls within iteration).
- Flag `@OneToMany` or `@ManyToOne` relationships without `JOIN FETCH` in the query or `@EntityGraph` on the repository method.
- Suggest batch fetching (`@BatchSize`), `JOIN FETCH` queries, `@EntityGraph`, or DTO projections as alternatives.
- Flag `FetchType.EAGER` on collections — prefer `FetchType.LAZY` with explicit fetching when needed.

## Query Performance

- Flag missing database indexes on columns used in WHERE clauses, JOIN conditions, or ORDER BY.
- Flag `SELECT *` style queries (loading full entities) when only a subset of fields is needed. Suggest DTO projections or `@Query` with specific column selection.
- Flag list endpoints without pagination. All collection endpoints MUST support pagination via `Pageable`.
- Flag queries without result limits that could return unbounded result sets.
- Flag missing `@Transactional(readOnly = true)` on read-only service methods.

## Blocking and Concurrency

- Flag synchronous HTTP calls to external services without timeouts. Suggest configuring `RestTemplate`/`WebClient` timeouts.
- Flag `Thread.sleep()` in production code.
- Flag large synchronous operations that could block request threads (file processing, bulk data operations).
- Flag missing timeout configuration on database queries or external service calls.

## Memory

- Flag loading large collections entirely into memory. Suggest streaming (`Stream<T>`) or pagination.
- Flag unbounded caches (caches without size limits or TTL).
- Flag large object graphs caused by eager fetching of deep entity relationships.
- Flag `String` concatenation in loops. Suggest `StringBuilder` or `String.join()`.
- Flag `@Cacheable` on methods returning large objects or collections without size awareness.

## Caching

- In-memory `@Cacheable` with `ConcurrentMapCacheManager` is the current standard. Do NOT suggest adding Redis.
- Flag caching of user-specific or request-specific data (low cache hit ratio).
- Verify cache keys are meaningful and avoid collisions.
- Flag missing cache eviction (`@CacheEvict`) for mutable data.
- Flag caching of rapidly changing data without appropriate TTL considerations.

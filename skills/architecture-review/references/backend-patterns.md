# Backend Architecture Patterns Reference

## BCE Pattern (Boundary-Control-Entity)

### Boundary (Controllers, DTOs)
- Controllers are thin. They handle input validation and delegation only. No business logic.
- Controllers MUST return `ResponseEntity<T>`.
- Use DTOs for request and response payloads. Never expose JPA entities directly in API responses.
- Input validation via Bean Validation annotations (`@Valid`, `@NotNull`, `@Size`, etc.) on DTOs.

### Control (Services)
- All business logic lives in services.
- Services call repositories. Services never call other controllers.
- Services may call other services when needed, but avoid deep service-to-service chains.
- Service methods should be focused — one responsibility per method.

### Entity (JPA Entities, Repositories)
- JPA entities represent the data model. No HTTP concerns, no business logic beyond basic domain invariants.
- Repositories handle data access only. No business logic, no HTTP concerns.
- Use Spring Data JPA interfaces. Custom queries via `@Query` when needed.

## Package Structure

- Package-per-feature preferred (e.g., `com.example.product`, `com.example.order`).
- Each feature package contains its own controllers, services, repositories, DTOs, and entities.
- Cross-cutting concerns (security, configuration, exception handling) live in shared packages.

## Lombok Restrictions

Allowed:
- `@Getter` / `@Setter` on JPA entities only.
- `@RequiredArgsConstructor` on services and controllers (for constructor injection).

Flag as anti-patterns:
- `@Data` — generates equals/hashCode that cause issues with JPA entities, and encourages mutable DTOs where records should be used.
- `@Builder` — hides constructor complexity, makes it harder to see required vs optional fields.
- `@AllArgsConstructor` — bypasses the explicit constructor pattern, makes refactoring fragile.
- `@Slf4j` — use explicit logger declaration for clarity.

## Anti-Patterns to Flag

### Over-Engineering
- Interfaces or abstract classes with only one implementation and no planned second implementation.
- Design patterns (Strategy, Factory, Observer) applied without a clear justification in the current requirements.
- Premature optimization (caching, async, batching) where there is no measured performance problem.
- Generic utility classes that wrap standard library functionality without adding value.

### Tight Coupling
- Circular dependencies between packages or services.
- God classes with too many responsibilities (more than ~5 injected dependencies is a smell).
- Direct instantiation of dependencies instead of injection.

### Leaky Abstractions
- Business logic in controllers (conditional logic, data transformation, orchestration).
- SQL or query logic in service classes.
- HTTP concerns (status codes, headers) in service classes.
- Repository methods that encode business rules in their query logic without the service being aware.

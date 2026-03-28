# Java Conventions Reference

## Spring Boot Conventions

- Constructor injection is the standard. Use `@RequiredArgsConstructor` (Lombok) or explicit constructors.
- Never use `@Autowired` on fields. Flag field injection.
- Injected fields MUST be `final`.
- Use records for DTOs and value objects. Flag classes used as DTOs that could be records.
- Controllers MUST return `ResponseEntity<T>`. Flag controllers returning bare objects.
- Exception classes should have meaningful names describing the error (e.g., `ProductNotFoundException`, `InsufficientStockException`). Flag generic names like `CustomException`, `AppException`, `ServiceException`.

## Lombok Restrictions

Allowed:
- `@Getter` / `@Setter` — on JPA entities only.
- `@RequiredArgsConstructor` — on services and controllers for constructor injection.

Flag as anti-patterns:
- `@Data` — generates problematic equals/hashCode for JPA entities, encourages mutable DTOs.
- `@Builder` — hides constructor complexity, prefer explicit constructors or records.
- `@AllArgsConstructor` — fragile to field reordering, bypasses explicit construction.
- `@Slf4j` — use explicit `private static final Logger log = LoggerFactory.getLogger(ClassName.class)` for clarity.

## Naming Conventions

| Element         | Convention                  | Example                        |
|-----------------|-----------------------------|--------------------------------|
| Classes         | PascalCase                  | `ProductService`               |
| Methods         | camelCase, verb prefix      | `findById()`, `calculateTotal()` |
| Constants       | UPPER_SNAKE_CASE            | `MAX_RETRY_COUNT`              |
| Packages        | lowercase, no underscores   | `com.example.product`          |
| Boolean fields  | is/has/should/can prefix    | `isActive`, `hasPermission`    |
| DTOs            | Descriptive + suffix        | `ProductResponse`, `CreateProductRequest` |
| Entities        | Domain noun, no suffix      | `Product`, `Order`             |

## Formatting

- No wildcard imports (`import java.util.*`). Flag every occurrence.
- No unused imports. Flag every occurrence.
- No dead code (commented-out code, unreachable statements, unused private methods).
- Consistent blank lines: one blank line between methods, no multiple consecutive blank lines.
- Opening braces on the same line (K&R style).
- Use Java 21 features where appropriate: records, sealed classes, pattern matching, text blocks.

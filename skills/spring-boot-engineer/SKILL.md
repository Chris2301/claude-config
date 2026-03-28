---
name: spring-boot-engineer
description: Spring Boot 3.x implementation patterns for this project. BCE architecture, stateless cloud-native design, JPA, Spring Security 6, and TDD patterns. Use when implementing backend features.
metadata:
  domain: backend
  triggers: Spring Boot, Spring Framework, Spring Security, Spring Data JPA, Java REST API, BCE pattern, backend feature
  role: specialist
  scope: implementation
  output-format: code
  related-skills: angular-engineer, devops-engineer, security-reviewer
---

# Spring Boot Engineer

## Core Workflow

1. **Read spec** — Identify business rules, edge cases, and affected BCE layers
2. **Design** — Plan Boundary (controller + DTOs), Control (service), Entity (JPA entity + repository); confirm design before coding
3. **TDD** — For each business rule: RED (failing test) → GREEN (minimal code) → REFACTOR
4. **Integration tests** — Verify full request path: HTTP → Controller → Service → Repository → Response
5. **Verify** — Run `mvn verify` and confirm all tests pass before finishing

## Reference Guide

Load detailed guidance based on context:

| Topic | Reference | Load When |
|-------|-----------|-----------|
| BCE Patterns | `references/bce-patterns.md` | Controllers, services, entities, DTOs, package structure |
| Data Access | `references/data-access.md` | JPA entities, repositories, transactions, query optimization |
| Security | `references/security.md` | Spring Security 6, stateless auth, JWT/OAuth2, method security |
| Testing | `references/testing.md` | Unit tests, integration tests, Testcontainers, MockMvc |
| Cloud Native | `references/cloud-native.md` | Stateless design, caching, health endpoints, graceful shutdown |
| Reactive | `references/reactive-webflux.md` | WebFlux endpoints, Mono/Flux, R2DBC, WebTestClient |

## Quick Start — BCE Minimal Working Structure

A standard feature consists of these layers. Use as starting points.

### Entity (JPA)

```java
@Entity
@Table(name = "products")
@Getter
@Setter
public class Product {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal price;

    protected Product() {} // JPA

    public Product(String name, BigDecimal price) {
        this.name = name;
        this.price = price;
    }
}
```

### Entity (Repository)

```java
@Repository
public interface ProductRepository extends JpaRepository<Product, Long> {

    List<Product> findByNameContainingIgnoreCase(String name);

    boolean existsByName(String name);
}
```

### Control (Service)

```java
@Service
@RequiredArgsConstructor
public class ProductService {

    private final ProductRepository productRepository;

    @Transactional(readOnly = true)
    public List<Product> search(String name) {
        return productRepository.findByNameContainingIgnoreCase(name);
    }

    @Transactional
    public Product create(CreateProductRequest request) {
        var product = new Product(request.name(), request.price());
        return productRepository.save(product);
    }
}
```

### Boundary (Controller)

```java
@RestController
@RequestMapping("/api/v1/products")
@Validated
@RequiredArgsConstructor
public class ProductController {

    private final ProductService productService;

    @GetMapping
    public ResponseEntity<List<ProductResponse>> search(@RequestParam(defaultValue = "") String name) {
        List<ProductResponse> products = productService.search(name).stream()
                .map(ProductResponse::from)
                .toList();
        return ResponseEntity.ok(products);
    }

    @PostMapping
    public ResponseEntity<ProductResponse> create(@Valid @RequestBody CreateProductRequest request) {
        Product product = productService.create(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(ProductResponse.from(product));
    }
}
```

### Boundary (DTOs — records)

```java
public record CreateProductRequest(
    @NotBlank String name,
    @DecimalMin("0.0") BigDecimal price
) {}

public record ProductResponse(
    Long id,
    String name,
    BigDecimal price
) {
    public static ProductResponse from(Product product) {
        return new ProductResponse(product.getId(), product.getName(), product.getPrice());
    }
}
```

## Constraints

### MUST DO

| Rule | Correct Pattern |
|------|----------------|
| Constructor injection | `@RequiredArgsConstructor` or explicit constructor — never `@Autowired` on fields |
| Validate API input | `@Valid @RequestBody` on every mutating endpoint |
| ResponseEntity returns | Always return `ResponseEntity<T>` from controllers — use `ResponseEntity.status(HttpStatus.CREATED)` for POST |
| BCE separation | Controllers delegate only, services hold logic, repositories do data access |
| Transaction scope | `@Transactional` on writes, `@Transactional(readOnly = true)` on reads |
| Secure errors | Return generic HTTP errors (400/401/403/404/503), be specific in logs only |
| Externalize config | Environment variables or ConfigMaps — never hardcode values |
| Records for DTOs | Use Java records for all request/response DTOs |

### Lombok — Restricted Usage

Only these Lombok annotations are allowed:
- `@Getter` / `@Setter` — on entities
- `@RequiredArgsConstructor` — on services, controllers, components

**Forbidden Lombok annotations:**
- `@Data` (generates too much: equals/hashCode/toString can break JPA)
- `@Builder` / `@AllArgsConstructor` (bypasses domain constructor validation)
- `@NoArgsConstructor` on public scope (use `protected` no-arg constructor for JPA manually)
- `@Slf4j` (use explicit `LoggerFactory.getLogger()` for clarity)

### MUST NOT DO

- Use `@Data`, `@Builder`, `@AllArgsConstructor`, or other forbidden Lombok annotations
- Use field injection (`@Autowired` on fields)
- Put business logic in controllers or repositories
- Skip input validation on API endpoints
- Return bare objects from controllers — always use `ResponseEntity<T>`
- Use `@Component` when `@Service`/`@Repository`/`@RestController` applies
- Store secrets in `application.yml` / hardcode credentials
- Use deprecated Spring Boot 2.x patterns (e.g., `WebSecurityConfigurerAdapter`)
- Return stack traces or internal details in API error responses
- Mix blocking and reactive code (e.g., calling `.block()` inside a WebFlux chain)

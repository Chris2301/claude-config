# BCE Patterns — Boundary Control Entity

This project uses the BCE (Boundary Control Entity) pattern for clear separation of responsibilities.

## Layer Overview

| Layer | Role | Spring Stereotype | Rules |
|-------|------|-------------------|-------|
| **Boundary** | HTTP interface, DTOs, validation | `@RestController` | Thin — input validation + delegation only. No business logic. |
| **Control** | Business logic, orchestration | `@Service` | All logic lives here. Calls repositories, never other controllers. |
| **Entity** | Domain model, data access | `@Entity` + `@Repository` | Data structures + persistence. No HTTP concerns, no business orchestration. |

Cross-cutting concerns (security, logging, exception handling) live outside BCE layers.

## Package Structure

```
com.example.product/
  ProductController.java        # Boundary
  CreateProductRequest.java     # Boundary (DTO)
  ProductResponse.java          # Boundary (DTO)
  ProductService.java           # Control
  Product.java                  # Entity
  ProductRepository.java        # Entity (data access)
```

Package-per-feature preferred. Small projects may have fewer packages — be pragmatic.

## Boundary — Controllers

Always return `ResponseEntity<T>` for explicit control over status codes and headers.

```java
@RestController
@RequestMapping("/api/v1/products")
@Validated
@RequiredArgsConstructor
public class ProductController {

    private final ProductService productService;

    @GetMapping
    public ResponseEntity<List<ProductResponse>> findAll() {
        List<ProductResponse> products = productService.findAll().stream()
                .map(ProductResponse::from)
                .toList();
        return ResponseEntity.ok(products);
    }

    @GetMapping("/{id}")
    public ResponseEntity<ProductResponse> findById(@PathVariable Long id) {
        return ResponseEntity.ok(ProductResponse.from(productService.findById(id)));
    }

    @PostMapping
    public ResponseEntity<ProductResponse> create(@Valid @RequestBody CreateProductRequest request) {
        Product product = productService.create(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(ProductResponse.from(product));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ProductResponse> update(
            @PathVariable Long id,
            @Valid @RequestBody UpdateProductRequest request) {
        return ResponseEntity.ok(ProductResponse.from(productService.update(id, request)));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        productService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
```

## Boundary — DTOs (Java Records)

```java
// Request DTOs — use Jakarta Validation annotations
public record CreateProductRequest(
    @NotBlank(message = "Name is required")
    @Size(max = 100)
    String name,

    @NotNull(message = "Price is required")
    @DecimalMin(value = "0.0", inclusive = false)
    BigDecimal price
) {}

public record UpdateProductRequest(
    @Size(max = 100)
    String name,

    @DecimalMin(value = "0.0", inclusive = false)
    BigDecimal price
) {}

// Response DTOs — static factory from entity
public record ProductResponse(
    Long id,
    String name,
    BigDecimal price,
    LocalDateTime createdAt
) {
    public static ProductResponse from(Product product) {
        return new ProductResponse(
            product.getId(),
            product.getName(),
            product.getPrice(),
            product.getCreatedAt()
        );
    }
}
```

## Control — Services

```java
@Service
@RequiredArgsConstructor
public class ProductService {

    private final ProductRepository productRepository;

    @Transactional(readOnly = true)
    public List<Product> findAll() {
        return productRepository.findAll();
    }

    @Transactional(readOnly = true)
    public Product findById(Long id) {
        return productRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Product not found: " + id));
    }

    @Transactional
    public Product create(CreateProductRequest request) {
        var product = new Product(request.name(), request.price());
        return productRepository.save(product);
    }

    @Transactional
    public Product update(Long id, UpdateProductRequest request) {
        Product product = findById(id);
        if (request.name() != null) {
            product.setName(request.name());
        }
        if (request.price() != null) {
            product.setPrice(request.price());
        }
        return productRepository.save(product);
    }

    @Transactional
    public void delete(Long id) {
        if (!productRepository.existsById(id)) {
            throw new EntityNotFoundException("Product not found: " + id);
        }
        productRepository.deleteById(id);
    }
}
```

## Entity — JPA Entities

Use `@Getter` / `@Setter` from Lombok. Never use `@Data` (breaks JPA equals/hashCode) or `@Builder` (bypasses domain validation).

```java
@Entity
@Table(name = "products", indexes = {
    @Index(name = "idx_product_name", columnList = "name")
})
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

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(nullable = false)
    private LocalDateTime updatedAt;

    protected Product() {} // JPA requires no-arg constructor

    public Product(String name, BigDecimal price) {
        this.name = name;
        this.price = price;
    }

    @PrePersist
    void prePersist() {
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    void preUpdate() {
        this.updatedAt = LocalDateTime.now();
    }
}
```

## Entity — Repositories

```java
@Repository
public interface ProductRepository extends JpaRepository<Product, Long> {

    List<Product> findByNameContainingIgnoreCase(String name);

    boolean existsByName(String name);

    @Query("SELECT p FROM Product p WHERE p.price BETWEEN :min AND :max")
    List<Product> findByPriceRange(@Param("min") BigDecimal min, @Param("max") BigDecimal max);
}
```

## Cross-Cutting — Global Exception Handler

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(EntityNotFoundException.class)
    @ResponseStatus(HttpStatus.NOT_FOUND)
    public ErrorResponse handleNotFound(EntityNotFoundException ex) {
        log.warn("Resource not found: {}", ex.getMessage());
        return new ErrorResponse(HttpStatus.NOT_FOUND.value(), "Resource not found");
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public ValidationErrorResponse handleValidation(MethodArgumentNotValidException ex) {
        Map<String, String> errors = ex.getBindingResult().getFieldErrors().stream()
                .collect(Collectors.toMap(
                        FieldError::getField,
                        error -> error.getDefaultMessage() != null ? error.getDefaultMessage() : "Invalid value"
                ));
        return new ValidationErrorResponse(HttpStatus.BAD_REQUEST.value(), "Validation failed", errors);
    }

    @ExceptionHandler(Exception.class)
    @ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
    public ErrorResponse handleUnexpected(Exception ex) {
        log.error("Unexpected error", ex);
        return new ErrorResponse(HttpStatus.INTERNAL_SERVER_ERROR.value(), "Oops something went wrong");
    }
}

record ErrorResponse(int status, String message) {}

record ValidationErrorResponse(int status, String message, Map<String, String> errors) {}
```

## Quick Reference

| Annotation | Layer | Purpose |
|------------|-------|---------|
| `@RestController` | Boundary | REST endpoint class |
| `@Validated` | Boundary | Enable method-level validation |
| `@Valid @RequestBody` | Boundary | Validate incoming request body |
| `@Service` | Control | Business logic component |
| `@Transactional` | Control | Transaction boundary |
| `@Entity` | Entity | JPA-managed domain object |
| `@Repository` | Entity | Data access interface |
| `@RestControllerAdvice` | Cross-cutting | Global exception handling |

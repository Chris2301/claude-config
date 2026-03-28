# Data Access — Spring Data JPA + PostgreSQL

## Entity Patterns

### Basic Entity

```java
@Entity
@Table(name = "orders", indexes = {
    @Index(name = "idx_order_customer", columnList = "customer_id"),
    @Index(name = "idx_order_status", columnList = "status")
})
@Getter
@Setter
public class Order {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "customer_id", nullable = false)
    private Long customerId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private OrderStatus status;

    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal total;

    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<OrderItem> items = new ArrayList<>();

    @Version
    private Long version; // Optimistic locking

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(nullable = false)
    private LocalDateTime updatedAt;

    protected Order() {}

    public Order(Long customerId) {
        this.customerId = customerId;
        this.status = OrderStatus.PENDING;
        this.total = BigDecimal.ZERO;
    }

    // Bidirectional relationship helper
    public void addItem(OrderItem item) {
        items.add(item);
        item.setOrder(this);
        recalculateTotal();
    }

    public void removeItem(OrderItem item) {
        items.remove(item);
        item.setOrder(null);
        recalculateTotal();
    }

    private void recalculateTotal() {
        this.total = items.stream()
                .map(OrderItem::getSubtotal)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
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

    // getters + setters
}
```

### Enum for Status Fields

```java
public enum OrderStatus {
    PENDING, CONFIRMED, SHIPPED, DELIVERED, CANCELLED
}
```

## Repository Patterns

### Standard Repository

```java
@Repository
public interface OrderRepository extends JpaRepository<Order, Long> {

    List<Order> findByCustomerIdOrderByCreatedAtDesc(Long customerId);

    List<Order> findByStatus(OrderStatus status);

    boolean existsByCustomerIdAndStatus(Long customerId, OrderStatus status);

    // JOIN FETCH to prevent N+1
    @Query("SELECT o FROM Order o LEFT JOIN FETCH o.items WHERE o.id = :id")
    Optional<Order> findByIdWithItems(@Param("id") Long id);

    // Projection for read-only use
    @Query("SELECT new com.example.order.OrderSummaryResponse(o.id, o.status, o.total, o.createdAt) " +
           "FROM Order o WHERE o.customerId = :customerId")
    List<OrderSummaryResponse> findSummariesByCustomerId(@Param("customerId") Long customerId);

    // Bulk update
    @Modifying
    @Query("UPDATE Order o SET o.status = :status WHERE o.id IN :ids")
    int updateStatusByIds(@Param("ids") List<Long> ids, @Param("status") OrderStatus status);

    // Pagination
    Page<Order> findByStatusOrderByCreatedAtDesc(OrderStatus status, Pageable pageable);
}
```

### Specifications for Dynamic Queries

```java
public class OrderSpecifications {

    public static Specification<Order> hasCustomerId(Long customerId) {
        return (root, query, cb) ->
            customerId == null ? null : cb.equal(root.get("customerId"), customerId);
    }

    public static Specification<Order> hasStatus(OrderStatus status) {
        return (root, query, cb) ->
            status == null ? null : cb.equal(root.get("status"), status);
    }

    public static Specification<Order> createdBetween(LocalDateTime from, LocalDateTime to) {
        return (root, query, cb) -> {
            if (from == null && to == null) return null;
            if (from != null && to != null) return cb.between(root.get("createdAt"), from, to);
            if (from != null) return cb.greaterThanOrEqualTo(root.get("createdAt"), from);
            return cb.lessThanOrEqualTo(root.get("createdAt"), to);
        };
    }

    public static Specification<Order> totalGreaterThan(BigDecimal amount) {
        return (root, query, cb) ->
            amount == null ? null : cb.greaterThan(root.get("total"), amount);
    }
}

// Usage in service
public Page<Order> search(OrderSearchCriteria criteria, Pageable pageable) {
    Specification<Order> spec = Specification
        .where(OrderSpecifications.hasCustomerId(criteria.customerId()))
        .and(OrderSpecifications.hasStatus(criteria.status()))
        .and(OrderSpecifications.createdBetween(criteria.from(), criteria.to()));

    return orderRepository.findAll(spec, pageable);
}
```

## Transaction Management

```java
@Service
@RequiredArgsConstructor
public class OrderService {

    private final OrderRepository orderRepository;
    private final InventoryService inventoryService;

    // Read-only at class level is a good default
    @Transactional(readOnly = true)
    public Order findById(Long id) {
        return orderRepository.findByIdWithItems(id)
                .orElseThrow(() -> new EntityNotFoundException("Order not found: " + id));
    }

    // Write transaction for mutations
    @Transactional
    public Order create(CreateOrderRequest request) {
        var order = new Order(request.customerId());

        request.items().forEach(item -> {
            inventoryService.reserveStock(item.productId(), item.quantity());
            order.addItem(new OrderItem(item.productId(), item.quantity(), item.price()));
        });

        return orderRepository.save(order);
    }

    // Explicit rollback rules
    @Transactional(noRollbackFor = NotificationException.class)
    public Order complete(Long id) {
        Order order = findById(id);
        order.setStatus(OrderStatus.DELIVERED);
        return orderRepository.save(order);
    }
}
```

## Query Optimization

### Preventing N+1

```java
// BAD — triggers N+1 queries
List<Order> orders = orderRepository.findAll();
orders.forEach(o -> o.getItems().size()); // N additional queries

// GOOD — single query with JOIN FETCH
@Query("SELECT DISTINCT o FROM Order o LEFT JOIN FETCH o.items WHERE o.status = :status")
List<Order> findByStatusWithItems(@Param("status") OrderStatus status);

// GOOD — EntityGraph
@EntityGraph(attributePaths = {"items"})
List<Order> findByStatus(OrderStatus status);
```

### Pagination

```java
// Always paginate list endpoints
@GetMapping
public ResponseEntity<Page<OrderResponse>> findAll(
        @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC)
        Pageable pageable) {
    return ResponseEntity.ok(orderService.findAll(pageable).map(OrderResponse::from));
}
```

### Projections for Read-Only

```java
// DTO projection — fetches only needed columns
public record OrderSummaryResponse(Long id, OrderStatus status, BigDecimal total, LocalDateTime createdAt) {}

@Query("SELECT new com.example.order.OrderSummaryResponse(o.id, o.status, o.total, o.createdAt) FROM Order o")
Page<OrderSummaryResponse> findAllSummaries(Pageable pageable);
```

## Database Migrations (Flyway)

```sql
-- V1__create_orders_table.sql
CREATE TABLE orders (
    id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    total NUMERIC(12,2) NOT NULL DEFAULT 0,
    version BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_status ON orders(status);

-- V2__create_order_items_table.sql
CREATE TABLE order_items (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id BIGINT NOT NULL,
    quantity INTEGER NOT NULL,
    price NUMERIC(10,2) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_order_items_order ON order_items(order_id);
```

## Quick Reference

| Annotation | Purpose |
|------------|---------|
| `@Entity` | JPA-managed domain object |
| `@Table(indexes = ...)` | Table details + indexes |
| `@Id` + `@GeneratedValue(IDENTITY)` | Auto-increment primary key (PostgreSQL BIGSERIAL) |
| `@Column(nullable, length, precision)` | Column constraints |
| `@OneToMany` / `@ManyToOne` | Relationships — always set `mappedBy` on the non-owning side |
| `@Version` | Optimistic locking |
| `@Transactional` | Transaction boundary — on service methods |
| `@Transactional(readOnly = true)` | Read-only transaction — enables query optimizations |
| `@Query` | Custom JPQL or native SQL |
| `@Modifying` | Marks `@Query` as UPDATE/DELETE |
| `@EntityGraph` | Eager-fetch specific associations to prevent N+1 |

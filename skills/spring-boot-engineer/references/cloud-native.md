# Cloud Native — Stateless Design

All services MUST be stateless and horizontally scalable. Every instance must be interchangeable.

## Stateless Rules

| Rule | Do | Don't |
|------|----|-------|
| Authentication | Stateless JWT/OAuth2 tokens | `HttpSession`, Spring Session, sticky sessions |
| File storage | Object storage (S3/MinIO) or database | Write to local filesystem |
| Configuration | Environment variables, ConfigMaps, Vault | Hardcoded values, `.properties` files with secrets |
| State | Database or external store | In-memory state that survives restarts |

## Caching — @Cacheable

Use Spring's `@Cacheable` with default in-memory cache (`ConcurrentMapCacheManager`) for now.
Design for Redis migration later — but do NOT add Redis as a dependency yet.

```java
@Configuration
@EnableCaching
public class CacheConfig {
    // Default ConcurrentMapCacheManager is sufficient for single-replica
    // When migrating to Redis: swap this config, keep @Cacheable annotations unchanged
}

@Service
@RequiredArgsConstructor
public class ProductService {

    private final ProductRepository productRepository;

    @Cacheable(value = "products", key = "#id")
    @Transactional(readOnly = true)
    public Product findById(Long id) {
        return productRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Product not found: " + id));
    }

    @CacheEvict(value = "products", key = "#id")
    @Transactional
    public Product update(Long id, UpdateProductRequest request) {
        Product product = findById(id);
        // update fields...
        return productRepository.save(product);
    }

    @CacheEvict(value = "products", allEntries = true)
    @Transactional
    public void deleteAll() {
        productRepository.deleteAll();
    }
}
```

### Cache Key Design

Design cache keys so they work with both in-memory and Redis:
- Use simple, predictable keys: entity type + ID
- Avoid complex objects as cache keys
- Always pair `@Cacheable` with `@CacheEvict` on mutations

## Health Endpoints

```java
// application.yml
management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
  endpoint:
    health:
      show-details: always
      probes:
        enabled: true
  health:
    livenessState:
      enabled: true
    readinessState:
      enabled: true
```

### Custom Health Indicator

```java
@Component
@RequiredArgsConstructor
public class ExternalServiceHealthIndicator implements HealthIndicator {

    private final WebClient webClient;

    @Override
    public Health health() {
        try {
            webClient.get().uri("/health")
                    .retrieve()
                    .toBodilessEntity()
                    .block(Duration.ofSeconds(3));
            return Health.up().withDetail("externalService", "reachable").build();
        } catch (Exception e) {
            return Health.down().withDetail("externalService", e.getMessage()).build();
        }
    }
}
```

## Graceful Shutdown

```yaml
# application.yml
server:
  shutdown: graceful

spring:
  lifecycle:
    timeout-per-shutdown-phase: 30s
```

Spring handles `SIGTERM`:
1. Stop accepting new requests
2. Wait for in-flight requests to complete (up to 30s)
3. Release resources and shut down

## Configuration Externalization

```java
// Type-safe configuration bound to a record
@ConfigurationProperties(prefix = "app.product")
public record ProductConfig(
    int maxPageSize,
    Duration cacheTtl,
    String defaultCurrency
) {}

// Enable in main class or config
@EnableConfigurationProperties(ProductConfig.class)

// Usage via constructor injection
@Service
@RequiredArgsConstructor
public class ProductService {
    private final ProductRepository repo;
    private final ProductConfig config;
}
```

```yaml
# application.yml — defaults only, secrets via env vars
app:
  product:
    max-page-size: 50
    cache-ttl: 5m
    default-currency: EUR

spring:
  datasource:
    url: ${DATABASE_URL}
    username: ${DATABASE_USERNAME}
    password: ${DATABASE_PASSWORD}
```

## Observability

```yaml
# Prometheus metrics for Grafana
management:
  metrics:
    export:
      prometheus:
        enabled: true
    tags:
      application: ${spring.application.name}

# Structured logging for Loki
logging:
  pattern:
    console: '{"timestamp":"%d","level":"%p","logger":"%logger","message":"%m","traceId":"%X{traceId}","spanId":"%X{spanId}"}%n'
```

## Quick Reference

| Feature | Config |
|---------|--------|
| Graceful shutdown | `server.shutdown: graceful` |
| Liveness probe | `GET /actuator/health/liveness` |
| Readiness probe | `GET /actuator/health/readiness` |
| Prometheus metrics | `GET /actuator/prometheus` |
| Cache (current) | `ConcurrentMapCacheManager` (in-memory) |
| Cache (future) | Redis — design keys for this now |
| Secrets | Environment variables or Vault — never in config files |

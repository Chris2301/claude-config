# Reactive — Spring WebFlux + R2DBC

Use WebFlux for non-blocking, reactive endpoints. NEVER mix blocking and reactive code.

## When to Use WebFlux vs MVC

| Use MVC (default) | Use WebFlux |
|-------------------|-------------|
| Standard CRUD APIs | High-concurrency / streaming endpoints |
| JPA/Hibernate data access | External API aggregation (multiple calls) |
| Simple request-response | Server-Sent Events (SSE) |
| Most features in this project | WebSocket communication |

Most features should use MVC. Use WebFlux only when the reactive model provides a clear benefit.

## Reactive Controller (Boundary)

```java
@RestController
@RequestMapping("/api/v1/events")
@Validated
@RequiredArgsConstructor
public class EventController {

    private final EventService eventService;

    @GetMapping
    public ResponseEntity<Flux<EventResponse>> findAll() {
        return ResponseEntity.ok(eventService.findAll());
    }

    @GetMapping("/{id}")
    public Mono<ResponseEntity<EventResponse>> findById(@PathVariable Long id) {
        return eventService.findById(id)
                .map(ResponseEntity::ok)
                .defaultIfEmpty(ResponseEntity.notFound().build());
    }

    @PostMapping
    public Mono<ResponseEntity<EventResponse>> create(@Valid @RequestBody CreateEventRequest request) {
        return eventService.create(request)
                .map(event -> ResponseEntity.status(HttpStatus.CREATED).body(event));
    }

    @DeleteMapping("/{id}")
    public Mono<ResponseEntity<Void>> delete(@PathVariable Long id) {
        return eventService.delete(id)
                .then(Mono.just(ResponseEntity.noContent().<Void>build()));
    }
}
```

## Reactive Service (Control)

```java
@Service
@RequiredArgsConstructor
public class EventService {

    private final EventRepository eventRepository;

    public Flux<EventResponse> findAll() {
        return eventRepository.findAll()
                .map(EventResponse::from);
    }

    public Mono<EventResponse> findById(Long id) {
        return eventRepository.findById(id)
                .map(EventResponse::from)
                .switchIfEmpty(Mono.error(
                        new EntityNotFoundException("Event not found: " + id)));
    }

    @Transactional
    public Mono<EventResponse> create(CreateEventRequest request) {
        var event = new Event(request.name(), request.description());
        return eventRepository.save(event)
                .map(EventResponse::from);
    }

    @Transactional
    public Mono<Void> delete(Long id) {
        return eventRepository.findById(id)
                .switchIfEmpty(Mono.error(
                        new EntityNotFoundException("Event not found: " + id)))
                .flatMap(eventRepository::delete);
    }
}
```

## R2DBC Entity

R2DBC uses Spring Data annotations, not JPA annotations. No `@Entity`, no `@Table` from JPA.

```java
@Table("events")
@Getter
@Setter
public class Event {

    @Id
    private Long id;

    private String name;

    private String description;

    @CreatedDate
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;

    public Event() {}

    public Event(String name, String description) {
        this.name = name;
        this.description = description;
    }
}
```

## R2DBC Repository

```java
public interface EventRepository extends R2dbcRepository<Event, Long> {

    Flux<Event> findByNameContainingIgnoreCase(String name);

    @Query("SELECT * FROM events WHERE created_at > :since ORDER BY created_at DESC")
    Flux<Event> findCreatedSince(LocalDateTime since);

    @Query("SELECT COUNT(*) FROM events WHERE name = :name")
    Mono<Long> countByName(String name);
}
```

## R2DBC Configuration

```yaml
spring:
  r2dbc:
    url: r2dbc:postgresql://${DATABASE_HOST:localhost}:5432/${DATABASE_NAME:app}
    username: ${DATABASE_USERNAME}
    password: ${DATABASE_PASSWORD}
    pool:
      initial-size: 5
      max-size: 20
      max-idle-time: 30m
```

## WebClient for External APIs

```java
@Component
@RequiredArgsConstructor
public class ExternalApiClient {

    private final WebClient webClient;

    public Mono<ExternalData> fetchData(String id) {
        return webClient
                .get()
                .uri("/data/{id}", id)
                .retrieve()
                .onStatus(HttpStatusCode::is4xxClientError, response ->
                        Mono.error(new EntityNotFoundException("External resource not found")))
                .onStatus(HttpStatusCode::is5xxServerError, response ->
                        Mono.error(new ServiceUnavailableException("External service unavailable")))
                .bodyToMono(ExternalData.class)
                .timeout(Duration.ofSeconds(5))
                .retryWhen(Retry.backoff(3, Duration.ofSeconds(1)));
    }
}

@Configuration
class WebClientConfig {

    @Bean
    public WebClient webClient(WebClient.Builder builder) {
        return builder
                .baseUrl("${external.api.base-url}")
                .defaultHeader(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
                .build();
    }
}
```

## Common Reactor Operators

```java
// Transform synchronously
Mono<String> upper = Mono.just("hello").map(String::toUpperCase);

// Chain async operations
Mono<OrderResponse> result = userRepository.findById(id)
        .flatMap(user -> orderRepository.findByUserId(user.getId())
                .collectList()
                .map(orders -> new OrderResponse(user, orders)));

// Combine multiple async sources
Mono<DashboardResponse> dashboard = Mono.zip(
        userService.getProfile(id),
        orderService.getRecentOrders(id),
        DashboardResponse::new);

// Error handling
Mono<User> safe = userRepository.findById(id)
        .onErrorResume(DatabaseException.class, e -> cacheRepository.findById(id))
        .doOnError(e -> log.error("Failed to fetch user {}", id, e));

// Backpressure — process in batches
Flux<Result> batched = dataRepository.findAll()
        .buffer(100)
        .flatMap(batch -> processBatch(batch), 5); // max 5 concurrent
```

## Testing Reactive Code

### Unit Test with StepVerifier

```java
@ExtendWith(MockitoExtension.class)
class EventServiceTest {

    @Mock
    private EventRepository eventRepository;

    @InjectMocks
    private EventService eventService;

    @Test
    @DisplayName("should find event by id")
    void shouldFindEventById() {
        var event = new Event("Conference", "Annual tech conference");
        when(eventRepository.findById(1L)).thenReturn(Mono.just(event));

        StepVerifier.create(eventService.findById(1L))
                .expectNextMatches(response -> response.name().equals("Conference"))
                .verifyComplete();
    }

    @Test
    @DisplayName("should error when event not found")
    void shouldErrorWhenNotFound() {
        when(eventRepository.findById(99L)).thenReturn(Mono.empty());

        StepVerifier.create(eventService.findById(99L))
                .expectError(EntityNotFoundException.class)
                .verify();
    }
}
```

### Integration Test with WebTestClient

```java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class EventIntegrationTest {

    @Autowired
    private WebTestClient webTestClient;

    @Autowired
    private EventRepository eventRepository;

    @BeforeEach
    void setUp() {
        eventRepository.deleteAll().block();
    }

    @Test
    @DisplayName("should create and retrieve event")
    void shouldCreateAndRetrieveEvent() {
        var request = new CreateEventRequest("Conference", "Annual tech conference");

        webTestClient.post()
                .uri("/api/v1/events")
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(request)
                .exchange()
                .expectStatus().isCreated()
                .expectBody(EventResponse.class)
                .value(response -> {
                    assertThat(response.name()).isEqualTo("Conference");
                });
    }

    @Test
    @DisplayName("should return 404 for unknown event")
    void shouldReturn404ForUnknown() {
        webTestClient.get()
                .uri("/api/v1/events/{id}", 999L)
                .exchange()
                .expectStatus().isNotFound();
    }
}
```

## Critical Rules

| Rule | Why |
|------|-----|
| NEVER call `.block()` in reactive chain | Defeats the purpose, can cause deadlocks |
| NEVER mix JPA and R2DBC in same service | JPA is blocking, R2DBC is non-blocking — choose one per module |
| Use `StepVerifier` for testing | Don't use `.block()` in tests either — use `StepVerifier` |
| Always handle empty with `switchIfEmpty()` | Prevents silent null propagation |
| Set timeouts on external calls | `timeout(Duration.ofSeconds(5))` — prevent hanging |
| Use `retryWhen` for resilience | Exponential backoff: `Retry.backoff(3, Duration.ofSeconds(1))` |

## Quick Reference

| Operator | Purpose |
|----------|---------|
| `Mono.just()` | Create Mono from value |
| `Flux.fromIterable()` | Create Flux from collection |
| `.map()` | Transform synchronously |
| `.flatMap()` | Transform to another Mono/Flux (async) |
| `.switchIfEmpty()` | Fallback for empty result |
| `.zip()` | Combine multiple async sources |
| `.retryWhen()` | Retry with backoff strategy |
| `.timeout()` | Set max wait time |
| `.onErrorResume()` | Fallback on specific error |
| `.buffer()` | Batch elements for backpressure |
| `StepVerifier.create()` | Test reactive streams |

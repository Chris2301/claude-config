# Testing — TDD with JUnit 5 + Spring Boot Test

## Unit Tests — Plain JUnit 5 + Mockito (no Spring context)

### Service Test

```java
@ExtendWith(MockitoExtension.class)
class ProductServiceTest {

    @Mock
    private ProductRepository productRepository;

    @InjectMocks
    private ProductService productService;

    @Test
    @DisplayName("should create product when request is valid")
    void shouldCreateProduct() {
        // Given
        var request = new CreateProductRequest("Widget", BigDecimal.TEN);
        var product = new Product("Widget", BigDecimal.TEN);

        when(productRepository.save(any(Product.class))).thenReturn(product);

        // When
        Product result = productService.create(request);

        // Then
        assertThat(result.getName()).isEqualTo("Widget");
        verify(productRepository).save(any(Product.class));
    }

    @Test
    @DisplayName("should throw when product not found")
    void shouldThrowWhenNotFound() {
        // Given
        when(productRepository.findById(99L)).thenReturn(Optional.empty());

        // When & Then
        assertThatThrownBy(() -> productService.findById(99L))
                .isInstanceOf(EntityNotFoundException.class)
                .hasMessageContaining("99");
    }
}
```

### Parameterized Tests for Edge Cases

```java
@ParameterizedTest
@CsvSource({
    "64, false",
    "65, true",
    "66, true",
    "100, true"
})
@DisplayName("should determine senior status based on age")
void shouldDetermineSeniorStatus(int age, boolean expectedSenior) {
    var person = new Person("Test", age);
    assertThat(person.isSenior()).isEqualTo(expectedSenior);
}

@ParameterizedTest
@NullAndEmptySource
@ValueSource(strings = {"  ", "\t"})
@DisplayName("should reject blank names")
void shouldRejectBlankNames(String name) {
    assertThatThrownBy(() -> new Product(name, BigDecimal.TEN))
            .isInstanceOf(IllegalArgumentException.class);
}
```

## Integration Tests — @SpringBootTest + Testcontainers

### Full Stack Integration Test

```java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Testcontainers
@ActiveProfiles("test")
class ProductIntegrationTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine")
            .withDatabaseName("testdb")
            .withUsername("test")
            .withPassword("test");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }

    @Autowired
    private TestRestTemplate restTemplate;

    @Autowired
    private ProductRepository productRepository;

    @BeforeEach
    void setUp() {
        productRepository.deleteAll();
    }

    @Test
    @DisplayName("should create and retrieve product via API")
    void shouldCreateAndRetrieveProduct() {
        // Create
        var request = new CreateProductRequest("Widget", new BigDecimal("9.99"));
        ResponseEntity<ProductResponse> createResponse = restTemplate.postForEntity(
                "/api/v1/products", request, ProductResponse.class);

        assertThat(createResponse.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(createResponse.getBody()).isNotNull();
        assertThat(createResponse.getBody().name()).isEqualTo("Widget");

        // Retrieve
        Long id = createResponse.getBody().id();
        ResponseEntity<ProductResponse> getResponse = restTemplate.getForEntity(
                "/api/v1/products/{id}", ProductResponse.class, id);

        assertThat(getResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(getResponse.getBody().name()).isEqualTo("Widget");
    }

    @Test
    @DisplayName("should return 400 for invalid request")
    void shouldReturn400ForInvalidRequest() {
        var request = new CreateProductRequest("", new BigDecimal("-1"));
        ResponseEntity<String> response = restTemplate.postForEntity(
                "/api/v1/products", request, String.class);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
    }

    @Test
    @DisplayName("should return 404 for unknown product")
    void shouldReturn404ForUnknown() {
        ResponseEntity<String> response = restTemplate.getForEntity(
                "/api/v1/products/{id}", String.class, 999L);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
    }
}
```

### Web Layer Test with MockMvc

```java
@WebMvcTest(ProductController.class)
class ProductControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private ProductService productService;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    @DisplayName("should return products")
    void shouldReturnProducts() throws Exception {
        var product = new Product("Widget", BigDecimal.TEN);
        when(productService.findAll()).thenReturn(List.of(product));

        mockMvc.perform(get("/api/v1/products"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].name").value("Widget"));
    }

    @Test
    @DisplayName("should create product and return 201")
    void shouldCreateProduct() throws Exception {
        var request = new CreateProductRequest("Widget", BigDecimal.TEN);
        var product = new Product("Widget", BigDecimal.TEN);
        when(productService.create(any())).thenReturn(product);

        mockMvc.perform(post("/api/v1/products")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.name").value("Widget"));
    }

    @Test
    @DisplayName("should return 400 for missing name")
    void shouldReturn400ForMissingName() throws Exception {
        String invalidJson = """
                {"name": "", "price": 10.0}
                """;

        mockMvc.perform(post("/api/v1/products")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(invalidJson))
                .andExpect(status().isBadRequest());
    }
}
```

### Repository Test with @DataJpaTest

```java
@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Testcontainers
@ActiveProfiles("test")
class ProductRepositoryTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }

    @Autowired
    private ProductRepository productRepository;

    @Test
    @DisplayName("should find products by name containing")
    void shouldFindByNameContaining() {
        productRepository.save(new Product("Blue Widget", BigDecimal.TEN));
        productRepository.save(new Product("Red Widget", BigDecimal.ONE));
        productRepository.save(new Product("Green Gadget", BigDecimal.ONE));

        List<Product> results = productRepository.findByNameContainingIgnoreCase("widget");

        assertThat(results).hasSize(2);
        assertThat(results).extracting(Product::getName)
                .containsExactlyInAnyOrder("Blue Widget", "Red Widget");
    }
}
```

## Test Data Naming

Use clearly fake test data: `"test-client-id"`, `"Test User"`, `"test@example.invalid"`. Never use words like "real" or "actual" in test data identifiers — they confuse credential scanners and code reviewers.

## Test Naming Convention

```java
// Pattern: should[ExpectedBehavior]When[Condition]
void shouldCreateProductWhenRequestIsValid()
void shouldThrowWhenProductNotFound()
void shouldReturnEmptyListWhenNoProductsMatch()
void shouldAddSeniorAnnotationWhenAgeIs65OrAbove()
```

## Quick Reference

| Annotation | Purpose |
|------------|---------|
| `@ExtendWith(MockitoExtension.class)` | Unit test with Mockito |
| `@Mock` | Mock dependency |
| `@InjectMocks` | Inject mocks into subject |
| `@SpringBootTest` | Full integration test with app context |
| `@WebMvcTest` | Controller-only test with MockMvc |
| `@DataJpaTest` | Repository test with JPA |
| `@Testcontainers` | Enable Testcontainers |
| `@Container` | Declare test container |
| `@DynamicPropertySource` | Override Spring properties from container |
| `@ActiveProfiles("test")` | Use test profile |
| `@ParameterizedTest` | Run test with multiple inputs |
| `@DisplayName` | Human-readable test name |

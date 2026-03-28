# Frontend Testing Patterns

## Vitest Setup (Angular v20+)

Angular v20+ has native Vitest support through `@angular/build`.

```bash
npm install -D vitest jsdom
```

Configure in `angular.json`:

```json
{
  "projects": {
    "your-app": {
      "architect": {
        "test": {
          "builder": "@angular/build:unit-test",
          "options": {
            "tsConfig": "tsconfig.spec.json",
            "buildTarget": "your-app:build"
          }
        }
      }
    }
  }
}
```

Run tests:

```bash
ng test              # Run tests
ng test --watch      # Watch mode
ng test --code-coverage  # With coverage
ng test --include='**/product*.spec.ts'  # Specific files
ng test --watch=false    # CI mode
```

## Vitest vs Jasmine Migration

| Jasmine | Vitest |
|---------|--------|
| `jasmine.createSpy('name')` | `vi.fn()` |
| `spy.and.returnValue(val)` | `spy.mockReturnValue(val)` |
| `spyOn(obj, 'method').and.returnValue(val)` | `vi.spyOn(obj, 'method').mockReturnValue(val)` |
| `jasmine.createSpyObj('name', ['a','b'])` | `{ a: vi.fn(), b: vi.fn() }` |
| `jasmine.clock().install()` / `.tick(n)` | `vi.useFakeTimers()` / `vi.advanceTimersByTime(n)` |
| `done` callback | `async`/`await` |

## Unit Test for a Component

```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { ProductListComponent } from './product-list.component';
import { ProductStore } from './product.store';
import { ProductService } from './product.service';
import { of } from 'rxjs';
import { signal } from '@angular/core';

describe('ProductListComponent', () => {
  let fixture: ComponentFixture<ProductListComponent>;
  let component: ProductListComponent;

  const mockProductService = {
    getProducts: vi.fn().mockReturnValue(of([])),
  };

  beforeEach(async () => {
    vi.clearAllMocks();

    await TestBed.configureTestingModule({
      imports: [ProductListComponent],
      providers: [
        ProductStore,
        { provide: ProductService, useValue: mockProductService },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(ProductListComponent);
    component = fixture.componentInstance;
  });

  it('should create the component', () => {
    expect(component).toBeTruthy();
  });

  it('should display product list when products are loaded', () => {
    const products = [
      { id: '1', name: 'Widget', price: 9.99 },
      { id: '2', name: 'Gadget', price: 19.99 },
    ];
    mockProductService.getProducts.mockReturnValue(of(products));

    fixture.detectChanges();

    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.querySelectorAll('.product-card').length).toBe(2);
    expect(compiled.textContent).toContain('Widget');
  });

  it('should show empty state when no products exist', () => {
    mockProductService.getProducts.mockReturnValue(of([]));
    fixture.detectChanges();

    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.textContent).toContain('No products found');
  });

  it('should show loader while loading', () => {
    const store = TestBed.inject(ProductStore);
    store.setLoading();
    fixture.detectChanges();

    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.querySelector('.loading')).toBeTruthy();
  });
});
```

## Unit Test for a Service

```typescript
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting, HttpTestingController } from '@angular/common/http/testing';
import { ProductService } from './product.service';

describe('ProductService', () => {
  let service: ProductService;
  let httpMock: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        ProductService,
        provideHttpClient(),
        provideHttpClientTesting(),
      ],
    });

    service = TestBed.inject(ProductService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify();
  });

  it('should fetch products from the API', () => {
    const mockProducts = [
      { id: '1', name: 'Widget', price: 9.99, description: '', category: '' },
    ];

    service.getProducts().subscribe((products) => {
      expect(products.length).toBe(1);
      expect(products[0].name).toBe('Widget');
    });

    const req = httpMock.expectOne('/api/products');
    expect(req.request.method).toBe('GET');
    req.flush(mockProducts);
  });

  it('should create a product via POST', () => {
    const newProduct = { name: 'New Widget', price: 14.99, description: 'A new widget', category: 'Electronics' };

    service.createProduct(newProduct).subscribe((created) => {
      expect(created.id).toBe('42');
    });

    const req = httpMock.expectOne('/api/products');
    expect(req.request.method).toBe('POST');
    req.flush({ ...newProduct, id: '42' });
  });
});
```

## Unit Test for a Signal Store

```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { TestBed } from '@angular/core/testing';
import { ProductStore } from './product.store';
import { ProductService } from './product.service';
import { of, throwError } from 'rxjs';

describe('ProductStore', () => {
  let store: InstanceType<typeof ProductStore>;

  const mockProductService = {
    getProducts: vi.fn(),
    deleteProduct: vi.fn(),
  };

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        ProductStore,
        { provide: ProductService, useValue: mockProductService },
      ],
    });

    store = TestBed.inject(ProductStore);
  });

  it('should have initial state', () => {
    expect(store.products()).toEqual([]);
    expect(store.loading()).toBe(false);
  });

  it('should load products via rxMethod', () => {
    const products = [{ id: '1', name: 'Widget', price: 9.99 }];
    mockProductService.getProducts.mockReturnValue(of(products));

    store.loadProducts();

    expect(store.products()).toEqual(products);
    expect(store.loading()).toBe(false);
  });

  it('should handle load error', () => {
    mockProductService.getProducts.mockReturnValue(throwError(() => new Error('Network error')));

    store.loadProducts();

    expect(store.error()).toBe('Network error');
    expect(store.loading()).toBe(false);
  });
});
```

## Testing Signal Reactivity

```typescript
import { signal, computed } from '@angular/core';

it('should update computed signal when source signal changes', () => {
  const price = signal(100);
  const quantity = signal(2);
  const total = computed(() => price() * quantity());

  expect(total()).toBe(200);

  price.set(150);
  expect(total()).toBe(300);

  quantity.set(3);
  expect(total()).toBe(450);
});
```

For components, call `fixture.detectChanges()` after signals change to update the DOM.

```typescript
it('should reflect signal changes in the template', () => {
  component.title.set('Updated Title');
  fixture.detectChanges();

  const compiled = fixture.nativeElement as HTMLElement;
  expect(compiled.querySelector('h1')?.textContent).toContain('Updated Title');
});
```

## Testing OnPush Components

```typescript
@Component({
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<span>{{ data().name }}</span>`,
})
export class OnPushComponent {
  data = input.required<{ name: string }>();
}

it('should update when input signal changes', () => {
  const fixture = TestBed.createComponent(OnPushComponent);

  fixture.componentRef.setInput('data', { name: 'Initial' });
  fixture.detectChanges();
  expect(fixture.nativeElement.textContent).toContain('Initial');

  fixture.componentRef.setInput('data', { name: 'Updated' });
  fixture.detectChanges();
  expect(fixture.nativeElement.textContent).toContain('Updated');
});
```

## Testing Inputs and Outputs

```typescript
@Component({
  selector: 'app-item',
  template: `<div (click)="select()">{{ item().name }}</div>`,
})
export class ItemComponent {
  item = input.required<Item>();
  selected = output<Item>();

  select() {
    this.selected.emit(this.item());
  }
}

it('should emit selected event on click', () => {
  const fixture = TestBed.createComponent(ItemComponent);
  const item: Item = { id: '1', name: 'Test Item' };

  fixture.componentRef.setInput('item', item);
  fixture.detectChanges();

  let emittedItem: Item | undefined;
  fixture.componentInstance.selected.subscribe(i => emittedItem = i);

  fixture.nativeElement.querySelector('div').click();

  expect(emittedItem).toEqual(item);
});
```

## Testing httpResource

```typescript
import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting, HttpTestingController } from '@angular/common/http/testing';

describe('UserComponent with httpResource', () => {
  let httpMock: HttpTestingController;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [UserComponent],
      providers: [
        provideHttpClient(),
        provideHttpClientTesting(),
      ],
    }).compileComponents();

    httpMock = TestBed.inject(HttpTestingController);
  });

  it('should display user name after loading', () => {
    const fixture = TestBed.createComponent(UserComponent);
    fixture.detectChanges();

    expect(fixture.nativeElement.textContent).toContain('Loading');

    const req = httpMock.expectOne('/api/users/1');
    req.flush({ id: '1', name: 'John Doe' });
    fixture.detectChanges();

    expect(fixture.nativeElement.textContent).toContain('John Doe');
  });
});
```

## Testing Signal Forms

```typescript
import { form, FormField, required, email } from '@angular/forms/signals';

describe('LoginComponent', () => {
  let fixture: ComponentFixture<LoginComponent>;
  let component: LoginComponent;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [LoginComponent],
    }).compileComponents();

    fixture = TestBed.createComponent(LoginComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should be invalid when empty', () => {
    expect(component.loginForm().invalid()).toBe(true);
  });

  it('should be valid with correct data', () => {
    component.model.set({
      email: 'test@example.com',
      password: 'password123',
    });

    expect(component.loginForm().valid()).toBe(true);
  });

  it('should show email error for invalid email', () => {
    component.loginForm.email().value.set('invalid');
    fixture.detectChanges();

    expect(component.loginForm.email().invalid()).toBe(true);
    expect(component.loginForm.email().errors().some(e => e.kind === 'email')).toBe(true);
  });

  it('should disable submit button when invalid', () => {
    const button = fixture.nativeElement.querySelector('button');
    expect(button.disabled).toBe(true);
  });
});
```

## Mocking Signal-Based Services

```typescript
import { vi } from 'vitest';

const mockAuth = {
  user: signal<User | null>(null),
  isAuthenticated: computed(() => mockAuth.user() !== null),
  login: vi.fn(),
  logout: vi.fn(),
};

beforeEach(async () => {
  await TestBed.configureTestingModule({
    imports: [ProtectedPageComponent],
    providers: [
      { provide: AuthService, useValue: mockAuth },
    ],
  }).compileComponents();
});

it('should show content when authenticated', () => {
  mockAuth.user.set({ id: '1', name: 'Test User' });

  const fixture = TestBed.createComponent(ProtectedPageComponent);
  fixture.detectChanges();

  expect(fixture.nativeElement.querySelector('.protected-content')).toBeTruthy();
});
```

## Testing Async with fakeAsync

```typescript
import { fakeAsync, tick, flush } from '@angular/core/testing';

it('should debounce search', fakeAsync(() => {
  const fixture = TestBed.createComponent(SearchComponent);
  fixture.detectChanges();

  fixture.componentInstance.query.set('test');

  tick(300); // Advance time for debounce
  fixture.detectChanges();

  expect(fixture.componentInstance.results().length).toBeGreaterThan(0);

  flush(); // Flush remaining timers
}));
```

## Vitest Advanced Patterns

### Parameterized Tests

```typescript
it.each([
  { input: '', expected: false },
  { input: 'test', expected: false },
  { input: 'test@example.com', expected: true },
  { input: 'invalid@', expected: false },
])('should validate email "$input" as $expected', ({ input, expected }) => {
  expect(isValidEmail(input)).toBe(expected);
});
```

### Fake Timers

```typescript
import { vi, beforeEach, afterEach } from 'vitest';

beforeEach(() => {
  vi.useFakeTimers();
});

afterEach(() => {
  vi.useRealTimers();
});

it('should debounce search input', async () => {
  const fixture = TestBed.createComponent(SearchComponent);
  fixture.detectChanges();

  fixture.componentInstance.query.set('test');
  vi.advanceTimersByTime(300);
  await fixture.whenStable();
  fixture.detectChanges();

  expect(fixture.componentInstance.results().length).toBeGreaterThan(0);
});
```

### Module Mocking

```typescript
vi.mock('./analytics.service', () => ({
  AnalyticsService: class {
    track = vi.fn();
    identify = vi.fn();
  },
}));
```

### Snapshot Testing

```typescript
it('should match snapshot', () => {
  const fixture = TestBed.createComponent(UserCardComponent);
  fixture.componentRef.setInput('user', { id: '1', name: 'John', email: 'john@example.com' });
  fixture.detectChanges();

  expect(fixture.nativeElement.innerHTML).toMatchSnapshot();
});
```

### Test Fixtures (Factory Functions)

```typescript
const createTestProduct = (overrides = {}) => ({
  id: '1',
  name: 'Test Product',
  price: 99.99,
  ...overrides,
});

it('should calculate total', () => {
  const fixture = TestBed.createComponent(OrderComponent);
  fixture.componentRef.setInput('products', [
    createTestProduct({ price: 10 }),
    createTestProduct({ id: '2', price: 20 }),
  ]);
  fixture.detectChanges();

  expect(fixture.componentInstance.total()).toBe(30);
});
```

## Playwright E2E Tests

Organize E2E tests by user journey, not by page or component.

```typescript
// e2e/product-management.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Product Management Journey', () => {
  test('should allow a user to create, view, and delete a product', async ({ page }) => {
    await page.goto('/products');
    await page.getByRole('button', { name: 'Add Product' }).click();
    await expect(page).toHaveURL('/products/new');

    await page.getByLabel('Product Name').fill('Test Widget');
    await page.getByLabel('Price').fill('24.99');
    await page.getByRole('button', { name: 'Save Product' }).click();

    await expect(page).toHaveURL(/\/products\/[\w-]+/);
    await expect(page.getByText('Test Widget')).toBeVisible();
  });

  test('should show validation errors when form is incomplete', async ({ page }) => {
    await page.goto('/products/new');
    await page.getByRole('button', { name: 'Save Product' }).click();

    await expect(page.getByText('Product Name is required')).toBeVisible();
  });
});
```

### E2E File Organization

```
e2e/
  product-management.spec.ts     // create, edit, delete products
  order-checkout.spec.ts         // browse, add to cart, checkout
  user-onboarding.spec.ts        // register, verify email, first login
  admin-configuration.spec.ts    // manage settings, roles
```

## Rules

| Rule | Rationale |
| ---- | --------- |
| Test component behavior through DOM interaction (clicks, queries), NEVER via type-cast escapes to access private/protected members | Cast-based tests like `(component as unknown as Record<...>)['method']()` test implementation details, are fragile on refactoring, and bypass TypeScript's access control |
| Use clearly fake test data names: `'test-client-id'`, `'Test User'`, `'test@example.invalid'` | Words like "real" confuse credential scanners; use `test-`/`mock-`/`fake-` prefixes and `.invalid`/`.example` domains (RFC 2606) |

## Quick Reference

| Pattern | When to Use |
| ------- | ----------- |
| `vi.fn()` | Create mock functions |
| `vi.spyOn(obj, 'method')` | Spy on existing methods |
| `vi.clearAllMocks()` | Reset all mocks in beforeEach |
| `vi.useFakeTimers()` / `vi.advanceTimersByTime(n)` | Control time in tests |
| `vi.mock('module')` | Mock entire modules |
| `it.each([...])` | Parameterized tests |
| `TestBed.configureTestingModule` | Set up standalone components/services |
| `fixture.componentRef.setInput('name', value)` | Set signal inputs |
| `fixture.detectChanges()` | Trigger change detection after signal updates |
| `provideHttpClient()` + `provideHttpClientTesting()` | Mock HTTP calls |
| `HttpTestingController` | Assert and flush HTTP requests |
| `{ provide: X, useValue: mock }` | Replace real service with mock |
| `fakeAsync` + `tick(ms)` | Test time-dependent code |
| `page.getByRole()` | Playwright — locate by accessible role |
| `expect(page).toHaveURL(...)` | Playwright — assert navigation |

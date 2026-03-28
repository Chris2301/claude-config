# HTTP & Data Fetching Patterns

## httpResource() — Signal-Based HTTP (Recommended)

`httpResource()` wraps HttpClient with signal-based state management. Reactive to parameter changes.

```typescript
import { Component, signal } from '@angular/core';
import { httpResource } from '@angular/common/http';

interface Product {
  id: string;
  name: string;
  price: number;
}

@Component({
  selector: 'app-product-detail',
  standalone: true,
  imports: [],
  templateUrl: './product-detail.component.html',
})
export class ProductDetailComponent {
  productId = signal('123');

  // Reactive HTTP resource — refetches when productId changes
  productResource = httpResource<Product>(() => `/api/products/${this.productId()}`);

  getErrorMessage(error: unknown): string {
    if (error instanceof HttpErrorResponse) {
      return error.error?.message || `Error ${error.status}: ${error.statusText}`;
    }
    return 'An unexpected error occurred';
  }
}
```

```html
<!-- product-detail.component.html -->
@if (productResource.isLoading()) {
  <p>Loading...</p>
} @else if (productResource.error()) {
  <p>{{ getErrorMessage(productResource.error()) }}</p>
  <button type="button" (click)="productResource.reload()">Retry</button>
} @else if (productResource.hasValue()) {
  <h1>{{ productResource.value().name }}</h1>
  <p>{{ productResource.value().price | currency }}</p>
}
```

### httpResource Options

```typescript
// Simple GET request
productResource = httpResource<Product>(() => `/api/products/${this.productId()}`);

// With full request options
productResource = httpResource<Product>(() => ({
  url: `/api/products/${this.productId()}`,
  method: 'GET',
  headers: { 'Authorization': `Bearer ${this.token()}` },
  params: { include: 'details' },
}));

// With default value
productsResource = httpResource<Product[]>(() => '/api/products', {
  defaultValue: [],
});

// Skip request when params undefined
productResource = httpResource<Product>(() => {
  const id = this.productId();
  return id ? `/api/products/${id}` : undefined;
});
```

### Resource State

```typescript
// Status signals
productResource.value()      // Current value or undefined
productResource.hasValue()   // Boolean — has resolved value
productResource.error()      // Error or undefined
productResource.isLoading()  // Boolean — currently loading
productResource.status()     // 'idle' | 'loading' | 'reloading' | 'resolved' | 'error' | 'local'

// Actions
productResource.reload()     // Manually trigger reload
productResource.set(value)   // Set local value
productResource.update(fn)   // Update local value
```

## resource() — Generic Async Data

For non-HTTP async operations or custom fetch logic:

```typescript
import { resource, signal } from '@angular/core';

@Component({...})
export class SearchComponent {
  query = signal('');

  searchResource = resource({
    // Reactive params — triggers reload when changed
    params: () => ({ q: this.query() }),

    // Async loader function
    loader: async ({ params, abortSignal }) => {
      if (!params.q) return [];

      const response = await fetch(`/api/search?q=${params.q}`, {
        signal: abortSignal,
      });
      return response.json() as Promise<SearchResult[]>;
    },
  });
}
```

### Resource with Default Value

```typescript
productsResource = resource({
  defaultValue: [] as Product[],
  params: () => ({ filter: this.filter() }),
  loader: async ({ params }) => {
    const res = await fetch(`/api/products?filter=${params.filter}`);
    return res.json();
  },
});
// value() returns Product[] (never undefined)
```

### Conditional Loading

```typescript
const productId = signal<string | null>(null);

productResource = resource({
  params: () => {
    const id = productId();
    return id ? { id } : undefined; // undefined = skip loading
  },
  loader: async ({ params }) => {
    return fetch(`/api/products/${params.id}`).then(r => r.json());
  },
});
// Status is 'idle' when params returns undefined
```

## Loading States Pattern

```typescript
@Component({
  templateUrl: './data.component.html',
})
export class DataComponent {
  query = signal('');
  dataResource = httpResource<Data[]>(() =>
    this.query() ? `/api/search?q=${this.query()}` : undefined
  );
}
```

```html
<!-- data.component.html -->
@switch (dataResource.status()) {
  @case ('idle') {
    <p>Enter a search term</p>
  }
  @case ('loading') {
    <p>Loading...</p>
  }
  @case ('reloading') {
    <app-data [data]="dataResource.value()" />
    <p>Reloading...</p>
  }
  @case ('resolved') {
    <app-data [data]="dataResource.value()" />
  }
  @case ('error') {
    <app-error
      [error]="dataResource.error()"
      (retry)="dataResource.reload()"
    />
  }
}
```

## HttpClient — Traditional Approach

For complex scenarios or when you need Observable operators:

```typescript
import { Component, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { toSignal } from '@angular/core/rxjs-interop';

@Component({...})
export class ProductsComponent {
  private readonly http = inject(HttpClient);

  // Convert Observable to Signal
  products = toSignal(
    this.http.get<Product[]>('/api/products'),
    { initialValue: [] }
  );
}
```

### HTTP Methods in a Service

```typescript
@Injectable({ providedIn: 'root' })
export class ProductService {
  private readonly http = inject(HttpClient);

  getProducts() {
    return this.http.get<Product[]>('/api/products');
  }

  getProduct(id: string) {
    return this.http.get<Product>(`/api/products/${id}`);
  }

  createProduct(product: CreateProductDto) {
    return this.http.post<Product>('/api/products', product);
  }

  updateProduct(id: string, product: UpdateProductDto) {
    return this.http.put<Product>(`/api/products/${id}`, product);
  }

  patchProduct(id: string, changes: Partial<Product>) {
    return this.http.patch<Product>(`/api/products/${id}`, changes);
  }

  deleteProduct(id: string) {
    return this.http.delete<void>(`/api/products/${id}`);
  }
}
```

## Functional Interceptors

```typescript
// core/auth/auth.interceptor.ts
import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const authService = inject(AuthService);
  const token = authService.token();

  if (token) {
    req = req.clone({
      setHeaders: { Authorization: `Bearer ${token}` },
    });
  }

  return next(req);
};

// core/error/error.interceptor.ts
export const errorInterceptor: HttpInterceptorFn = (req, next) => {
  return next(req).pipe(
    catchError((error: HttpErrorResponse) => {
      if (error.status === 401) {
        inject(Router).navigate(['/login']);
      }
      return throwError(() => error);
    })
  );
};
```

### Register Interceptors

```typescript
// app.config.ts
import { provideHttpClient, withInterceptors } from '@angular/common/http';

export const appConfig: ApplicationConfig = {
  providers: [
    provideHttpClient(
      withInterceptors([
        authInterceptor,
        errorInterceptor,
      ])
    ),
  ],
};
```

## Service Layer with httpResource

Combine httpResource for reactive reads with HttpClient for mutations:

```typescript
@Injectable({ providedIn: 'root' })
export class ProductService {
  private readonly http = inject(HttpClient);

  private currentProductId = signal<string | null>(null);

  // Reactive resource — updates when currentProductId changes
  currentProduct = httpResource<Product>(() => {
    const id = this.currentProductId();
    return id ? `/api/products/${id}` : undefined;
  });

  selectProduct(id: string) {
    this.currentProductId.set(id);
  }

  // Mutations use HttpClient
  create(product: Omit<Product, 'id'>) {
    return this.http.post<Product>('/api/products', product);
  }

  update(id: string, product: Partial<Product>) {
    return this.http.patch<Product>(`/api/products/${id}`, product);
  }

  delete(id: string) {
    return this.http.delete<void>(`/api/products/${id}`);
  }
}
```

## Pagination with httpResource

```typescript
interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  pageSize: number;
  totalPages: number;
}

@Component({
  templateUrl: './product-list.component.html',
})
export class ProductListComponent {
  page = signal(1);
  pageSize = signal(10);

  productsResource = httpResource<PaginatedResponse<Product>>(() => ({
    url: '/api/products',
    params: {
      page: this.page().toString(),
      pageSize: this.pageSize().toString(),
    },
  }));

  nextPage() {
    this.page.update(p => p + 1);
  }

  prevPage() {
    this.page.update(p => Math.max(1, p - 1));
  }
}
```

```html
<!-- product-list.component.html -->
@if (productsResource.isLoading()) {
  <p>Loading...</p>
} @else if (productsResource.hasValue()) {
  @for (product of productsResource.value().data; track product.id) {
    <app-product-card [product]="product" />
  }

  <div class="pagination">
    <button type="button" (click)="prevPage()" [disabled]="page() === 1">
      Previous
    </button>
    <span>Page {{ page() }} of {{ productsResource.value().totalPages }}</span>
    <button type="button" (click)="nextPage()" [disabled]="page() >= productsResource.value().totalPages">
      Next
    </button>
  </div>
}
```

## Debounced Search

```typescript
@Component({...})
export class SearchComponent {
  query = signal('');

  private readonly http = inject(HttpClient);

  results = toSignal(
    toObservable(this.query).pipe(
      debounceTime(300),
      distinctUntilChanged(),
      filter(q => q.length >= 2),
      switchMap(q => this.http.get<Result[]>(`/api/search?q=${q}`)),
      catchError(() => of([]))
    ),
    { initialValue: [] }
  );
}
```

## When to Use What

| Scenario | Solution |
| -------- | -------- |
| Simple GET that reacts to signal params | `httpResource()` |
| Non-HTTP async data (WebSocket, IndexedDB) | `resource()` |
| Mutations (POST, PUT, DELETE) | `HttpClient` in a service |
| Complex RxJS pipelines (retry, debounce) | `HttpClient` + `toSignal()` |
| Data shared across components via store | `HttpClient` + NgRx Signal Store `rxMethod` |

## Quick Reference

| API | Purpose |
| --- | ------- |
| `httpResource<T>(() => url)` | Reactive signal-based HTTP GET |
| `resource({ params, loader })` | Generic async data with signal reactivity |
| `httpResource.status()` | `'idle'` \| `'loading'` \| `'reloading'` \| `'resolved'` \| `'error'` |
| `httpResource.reload()` | Manually re-fetch data |
| `httpResource.set(value)` | Set local value without HTTP call |
| `toSignal(observable, { initialValue })` | Convert Observable to Signal |
| `HttpInterceptorFn` | Functional interceptor type |
| `withInterceptors([...])` | Register interceptors in app config |

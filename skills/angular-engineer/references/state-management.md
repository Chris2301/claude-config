# NgRx Signal Store Patterns

## Basic Signal Store

Define state, computed values, and methods.

```typescript
// feature/product/product.store.ts
import { computed } from '@angular/core';
import { signalStore, withState, withComputed, withMethods, patchState } from '@ngrx/signals';
import { Product } from './product.model';

type ProductState = {
  products: Product[];
  loading: boolean;
  filter: string;
};

const initialState: ProductState = {
  products: [],
  loading: false,
  filter: '',
};

export const ProductStore = signalStore(
  withState(initialState),
  withComputed((state) => ({
    filteredProducts: computed(() => {
      const filter = state.filter().toLowerCase();
      return filter
        ? state.products().filter((p) => p.name.toLowerCase().includes(filter))
        : state.products();
    }),
    productCount: computed(() => state.products().length),
    hasProducts: computed(() => state.products().length > 0),
  })),
  withMethods((store) => ({
    setProducts(products: Product[]) {
      patchState(store, { products, loading: false });
    },
    setLoading() {
      patchState(store, { loading: true });
    },
    setFilter(filter: string) {
      patchState(store, { filter });
    },
    clearFilter() {
      patchState(store, { filter: '' });
    },
  })),
);
```

## Signal Store with HTTP Calls

Use `rxMethod` from `@ngrx/signals/rxjs-interop` to bridge RxJS observables into the store.

```typescript
// feature/product/product.store.ts
import { computed, inject } from '@angular/core';
import {
  signalStore,
  withState,
  withComputed,
  withMethods,
  patchState,
} from '@ngrx/signals';
import { rxMethod } from '@ngrx/signals/rxjs-interop';
import { pipe, switchMap, tap } from 'rxjs';
import { tapResponse } from '@ngrx/operators';
import { ProductService } from './product.service';
import { Product } from './product.model';

type ProductState = {
  products: Product[];
  loading: boolean;
  error: string | null;
};

const initialState: ProductState = {
  products: [],
  loading: false,
  error: null,
};

export const ProductStore = signalStore(
  withState(initialState),
  withComputed((state) => ({
    productCount: computed(() => state.products().length),
  })),
  withMethods((store, productService = inject(ProductService)) => ({
    loadProducts: rxMethod<void>(
      pipe(
        tap(() => patchState(store, { loading: true, error: null })),
        switchMap(() =>
          productService.getProducts().pipe(
            tapResponse({
              next: (products) => patchState(store, { products, loading: false }),
              error: (error: Error) =>
                patchState(store, { loading: false, error: error.message }),
            }),
          ),
        ),
      ),
    ),
    deleteProduct: rxMethod<string>(
      pipe(
        switchMap((id) =>
          productService.deleteProduct(id).pipe(
            tapResponse({
              next: () =>
                patchState(store, {
                  products: store.products().filter((p) => p.id !== id),
                }),
              error: (error: Error) =>
                patchState(store, { error: error.message }),
            }),
          ),
        ),
      ),
    ),
  })),
);
```

## Component Consuming a Signal Store

```typescript
// feature/product/product-page.component.ts
import { Component, inject, OnInit } from '@angular/core';
import { ProductStore } from './product.store';
import { ProductListComponent } from './product-list.component';

@Component({
  selector: 'app-product-page',
  standalone: true,
  imports: [ProductListComponent],
  providers: [ProductStore],
  templateUrl: './product-page.component.html',
})
export class ProductPageComponent implements OnInit {
  protected readonly store = inject(ProductStore);

  ngOnInit() {
    this.store.loadProducts();
  }
}
```

```html
<!-- product-page.component.html -->
@if (store.loading()) {
  <p>Loading...</p>
} @else {
  <h2>Products ({{ store.productCount() }})</h2>
  <app-product-list [products]="store.filteredProducts()" />
}
```

## Angular Signals: signal(), computed(), effect()

### signal() -- Writable signal for local mutable state

```typescript
import { signal } from '@angular/core';

// Create
readonly count = signal(0);

// Read
console.log(this.count()); // 0

// Write
this.count.set(5);
this.count.update((current) => current + 1);
```

### computed() -- Derived read-only signal

```typescript
import { signal, computed } from '@angular/core';

readonly price = signal(100);
readonly quantity = signal(3);
readonly total = computed(() => this.price() * this.quantity());
// total() automatically recalculates when price or quantity changes
```

### effect() -- Side effect that runs when signals change

Use sparingly. Prefer computed signals or store methods.

```typescript
import { signal, effect } from '@angular/core';

readonly searchTerm = signal('');

constructor() {
  effect(() => {
    console.log('Search term changed to:', this.searchTerm());
  });
}
```

## When to Use Local Signal vs Signal Store

| Scenario | Solution |
| -------- | -------- |
| Toggle a dropdown open/closed | Local `signal()` in the component |
| Form field value during editing | Local `signal()` or reactive form control |
| Derived value from other local signals | Local `computed()` |
| Data shared across sibling components | NgRx Signal Store provided on a parent |
| Data shared across routes | NgRx Signal Store provided in root or route |
| Server data with loading/error states (single component) | `httpResource()` or `resource()` |
| Server data with loading/error states (shared across components) | NgRx Signal Store with `rxMethod` |
| Complex filtering, sorting, pagination | NgRx Signal Store with `withComputed` |
| Simple UI state (modal open, tab index) | Local `signal()` in the component |

**Rule of thumb**: If only one component reads and writes the state, use a local signal. For reactive HTTP data in a single component, use `httpResource()`. If multiple components need the same state, or the state involves async operations, use a signal store. See `references/http.md` for data fetching patterns.

## Quick Reference

| API | Purpose |
| --- | ------- |
| `signal(initialValue)` | Create a writable signal |
| `computed(() => ...)` | Derive a read-only signal from other signals |
| `effect(() => ...)` | Run side effects when signals change |
| `input()` / `input.required()` | Signal-based component input |
| `output()` | Component output (EventEmitter replacement) |
| `signalStore(...)` | Create an NgRx Signal Store |
| `withState(initialState)` | Define the store state shape |
| `withComputed((state) => ...)` | Add computed (derived) signals to the store |
| `withMethods((store) => ...)` | Add methods that can patch state |
| `patchState(store, partial)` | Update store state immutably |
| `rxMethod<T>(pipe(...))` | Bridge RxJS into the store for async operations |
| `tapResponse({ next, error })` | Handle observable success/error in store pipes |

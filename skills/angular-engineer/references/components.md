# Angular v21 Component Patterns

## Standalone Component with inject() and Signals

```typescript
// feature/dashboard/dashboard.component.ts
import { Component, inject, signal } from '@angular/core';
import { DashboardService } from './dashboard.service';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [],
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.scss',
})
export class DashboardComponent {
  private readonly dashboardService = inject(DashboardService);

  readonly title = signal('Dashboard');
  readonly loading = signal(false);

  refresh() {
    this.loading.set(true);
    this.dashboardService.loadData().subscribe({
      next: () => this.loading.set(false),
      error: () => this.loading.set(false),
    });
  }
}
```

## Component with Signal-Based Inputs and Outputs

Angular v21 uses `input()` and `output()` functions instead of decorators.

```typescript
// feature/product/product-card.component.ts
import { Component, input, output } from '@angular/core';
import { Product } from './product.model';

@Component({
  selector: 'app-product-card',
  standalone: true,
  imports: [],
  templateUrl: './product-card.component.html',
  styleUrl: './product-card.component.scss',
})
export class ProductCardComponent {
  // Required input
  readonly product = input.required<Product>();

  // Optional input with default
  readonly showActions = input<boolean>(true);

  // Output
  readonly selected = output<Product>();

  onSelect() {
    this.selected.emit(this.product());
  }
}
```

```html
<!-- product-card.component.html -->
<div class="product-card">
  <h3>{{ product().name }}</h3>
  <p>{{ product().description }}</p>
  @if (showActions()) {
    <button type="button" (click)="onSelect()">
      Select
    </button>
  }
</div>
```

## Smart vs Dumb Component Pattern

### Smart Component (Container)

Owns state, calls services, passes data down.

```typescript
// feature/order/order-page.component.ts
import { Component, inject, OnInit } from '@angular/core';
import { OrderStore } from './order.store';
import { OrderService } from './order.service';
import { OrderListComponent } from './order-list.component';
import { OrderFilterComponent } from './order-filter.component';

@Component({
  selector: 'app-order-page',
  standalone: true,
  imports: [OrderListComponent, OrderFilterComponent],
  providers: [OrderStore],
  templateUrl: './order-page.component.html',
  styleUrl: './order-page.component.scss',
})
export class OrderPageComponent implements OnInit {
  protected readonly store = inject(OrderStore);
  private readonly orderService = inject(OrderService);

  ngOnInit() {
    this.store.setLoading();
    this.orderService.getOrders().subscribe((orders) => {
      this.store.setOrders(orders);
    });
  }

  onOrderSelected(orderId: string) {
    // navigate or open detail
  }
}
```

```html
<!-- order-page.component.html -->
<app-order-filter
  [currentFilter]="store.filter()"
  (filterChanged)="store.setFilter($event)"
/>
<app-order-list
  [orders]="store.filteredOrders()"
  [loading]="store.loading()"
  (orderSelected)="onOrderSelected($event)"
/>
```

### Dumb Component (Presentational)

Receives data via inputs, emits events via outputs. No injected services. No side effects.

```typescript
// feature/order/order-list.component.ts
import { Component, input, output } from '@angular/core';
import { Order } from './order.model';

@Component({
  selector: 'app-order-list',
  standalone: true,
  imports: [],
  templateUrl: './order-list.component.html',
  styleUrl: './order-list.component.scss',
})
export class OrderListComponent {
  readonly orders = input.required<Order[]>();
  readonly loading = input<boolean>(false);
  readonly orderSelected = output<string>();
}
```

## Template Signal Caching with @let

When a signal is referenced multiple times in a template, use `@let` to evaluate it once per change detection cycle:

```html
<!-- WRONG: signal called twice -->
<button [icon]="icon()" [attr.aria-label]="icon()">Toggle</button>

<!-- RIGHT: signal evaluated once via @let -->
@let iconName = icon();
<button [icon]="iconName" [attr.aria-label]="iconName">Toggle</button>
```

Apply this proactively during implementation whenever a signal appears more than once in the same template.

## New Control Flow

### @if / @else

```html
@if (user(); as user) {
  <span>Welcome, {{ user.name }}</span>
} @else {
  <span>Please log in</span>
}
```

### @for with track

`track` is mandatory in `@for`. Always track by a unique identifier.

```html
@for (item of items(); track item.id) {
  <app-item-card [item]="item" />
} @empty {
  <p>No items available.</p>
}
```

### @switch

```html
@switch (status()) {
  @case ('pending') {
    <span class="badge warning">Pending</span>
  }
  @case ('active') {
    <span class="badge success">Active</span>
  }
  @case ('archived') {
    <span class="badge neutral">Archived</span>
  }
  @default {
    <span class="badge">Unknown</span>
  }
}
```

## Component-Scoped SCSS Styles

Each component has its own `.scss` file. Use `:host` for component-level styling.

```scss
// product-card.component.scss
:host {
  display: block;
  padding: 1rem;
}

.product-card {
  border: 1px solid var(--app-border-normal);
  border-radius: 0.5rem;
  padding: 1.5rem;

  h3 {
    margin: 0 0 0.5rem;
    font: var(--app-font-heading-6);
  }

  p {
    color: var(--app-text-secondary);
  }
}
```

## Package-Per-Feature Structure

```
src/app/
  feature/
    product/
      product.model.ts
      product.service.ts
      product.store.ts
      product-list.component.ts
      product-list.component.html
      product-list.component.scss
      product-list.component.spec.ts
      product-card.component.ts
      product-card.component.html
      product-card.component.scss
      product-card.component.spec.ts
      product.routes.ts
    order/
      order.model.ts
      order.service.ts
      order.store.ts
      ...
  shared/
    ui/
      confirmation-dialog.component.ts
    util/
      date.util.ts
  core/
    auth/
      auth.service.ts
      auth.interceptor.ts
    layout/
      shell.component.ts
      header.component.ts
```

## Quick Reference

| Pattern | When to Use |
| ------- | ----------- |
| `input()` / `input.required()` | Pass data from parent to child |
| `output()` | Emit events from child to parent |
| `signal()` | Local component state |
| `computed()` | Derived values from signals |
| Smart component | Owns state, calls services, provides stores |
| Dumb component | Receives inputs, emits outputs, no injected services |
| `@if` / `@for` / `@switch` | Template control flow (replaces `*ngIf` / `*ngFor`) |
| `:host` in SCSS | Style the component element itself |
| `providers: [Store]` | Scope a signal store to a component subtree |

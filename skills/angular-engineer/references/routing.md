# Routing Patterns

## Basic Setup

```typescript
// app.routes.ts
import { Routes } from '@angular/router';

export const routes: Routes = [
  { path: '', redirectTo: 'home', pathMatch: 'full' },  // ALWAYS relative — never '/home'
  { path: 'home', component: HomeComponent },
  { path: '**', component: NotFoundComponent },
];

// app.config.ts
import { provideRouter, withComponentInputBinding } from '@angular/router';

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes, withComponentInputBinding()),
  ],
};

// app.component.ts
@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, RouterLink, RouterLinkActive],
  templateUrl: './app.component.html',
})
export class AppComponent {}
```

```html
<!-- app.component.html -->
<nav>
  <a routerLink="/home" routerLinkActive="active">Home</a>
</nav>
<router-outlet />
```

## Lazy Loading

```typescript
export const routes: Routes = [
  // Lazy load entire feature
  {
    path: 'admin',
    loadChildren: () => import('./admin/admin.routes').then(m => m.adminRoutes),
  },

  // Lazy load single component
  {
    path: 'settings',
    loadComponent: () => import('./settings/settings.component').then(m => m.SettingsComponent),
  },
];

// admin/admin.routes.ts
export const adminRoutes: Routes = [
  { path: '', component: AdminDashboardComponent },
  { path: 'users', component: AdminUsersComponent },
];
```

## Route Parameters with Signal Inputs

Requires `withComponentInputBinding()` in app config.

```typescript
// Route: { path: 'products/:id', component: ProductDetailComponent }

@Component({
  selector: 'app-product-detail',
  standalone: true,
  templateUrl: './product-detail.component.html',
})
export class ProductDetailComponent {
  // Route param as signal input
  id = input.required<string>();

  // Computed based on route param
  productId = computed(() => parseInt(this.id(), 10));
}
```

```html
<!-- product-detail.component.html -->
<h1>Product {{ id() }}</h1>
```

### Query Parameters

```typescript
// Route: /search?q=angular&page=1

@Component({...})
export class SearchComponent {
  q = input<string>('');
  page = input<string>('1');

  currentPage = computed(() => parseInt(this.page(), 10));
}
```

### With ActivatedRoute (Alternative)

```typescript
import { toSignal } from '@angular/core/rxjs-interop';

@Component({...})
export class ProductDetailComponent {
  private readonly route = inject(ActivatedRoute);

  id = toSignal(
    this.route.paramMap.pipe(map(params => params.get('id'))),
    { initialValue: null }
  );
}
```

## Functional Guards

### Auth Guard

```typescript
// core/auth/auth.guard.ts
import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';

export const authGuard: CanActivateFn = (route, state) => {
  const authService = inject(AuthService);
  const router = inject(Router);

  if (authService.isAuthenticated()) {
    return true;
  }

  return router.createUrlTree(['/login'], {
    queryParams: { returnUrl: state.url },
  });
};

// Usage in routes
{
  path: 'dashboard',
  component: DashboardComponent,
  canActivate: [authGuard],
}
```

### Role Guard

```typescript
export const roleGuard = (allowedRoles: string[]): CanActivateFn => {
  return (route, state) => {
    const authService = inject(AuthService);
    const router = inject(Router);

    const userRole = authService.currentUser()?.role;

    if (userRole && allowedRoles.includes(userRole)) {
      return true;
    }

    return router.createUrlTree(['/unauthorized']);
  };
};

// Usage
{
  path: 'admin',
  component: AdminComponent,
  canActivate: [authGuard, roleGuard(['admin', 'superadmin'])],
}
```

### Unsaved Changes Guard

```typescript
export interface HasUnsavedChanges {
  canDeactivate: () => boolean | Promise<boolean>;
}

export const unsavedChangesGuard: CanDeactivateFn<HasUnsavedChanges> = (component) => {
  if (component.canDeactivate()) {
    return true;
  }
  return confirm('You have unsaved changes. Leave anyway?');
};

// Component implementation
@Component({...})
export class ProductEditComponent implements HasUnsavedChanges {
  readonly form = inject(NonNullableFormBuilder).group({...});

  canDeactivate(): boolean {
    return !this.form.dirty;
  }
}

// Route
{
  path: 'edit/:id',
  component: ProductEditComponent,
  canDeactivate: [unsavedChangesGuard],
}
```

## Resolvers

Pre-fetch data before route activation:

```typescript
// resolvers/product.resolver.ts
import { inject } from '@angular/core';
import { ResolveFn } from '@angular/router';

export const productResolver: ResolveFn<Product> = (route) => {
  const productService = inject(ProductService);
  const id = route.paramMap.get('id')!;
  return productService.getProduct(id);
};

// Route config
{
  path: 'products/:id',
  component: ProductDetailComponent,
  resolve: { product: productResolver },
}

// Component — access resolved data via input
@Component({...})
export class ProductDetailComponent {
  product = input.required<Product>();
}
```

## Nested Routes

```typescript
export const routes: Routes = [
  {
    path: 'products',
    component: ProductsLayoutComponent,
    children: [
      { path: '', component: ProductListComponent },
      { path: ':id', component: ProductDetailComponent },
      { path: ':id/edit', component: ProductEditComponent },
    ],
  },
];

@Component({
  standalone: true,
  imports: [RouterOutlet],
  templateUrl: './products-layout.component.html',
})
export class ProductsLayoutComponent {}
```

```html
<!-- products-layout.component.html -->
<h1>Products</h1>
<router-outlet />
```

## Programmatic Navigation

```typescript
@Component({...})
export class ProductComponent {
  private readonly router = inject(Router);

  goToProducts() {
    this.router.navigate(['/products']);
  }

  goToProduct(id: string) {
    this.router.navigate(['/products', id]);
  }

  search(query: string) {
    this.router.navigate(['/search'], {
      queryParams: { q: query, page: 1 },
    });
  }

  replaceUrl() {
    this.router.navigate(['/new-page'], { replaceUrl: true });
  }
}
```

## Route Data and Dynamic Titles

```typescript
// Static route data
{
  path: 'admin',
  component: AdminComponent,
  data: { title: 'Admin Dashboard', roles: ['admin'] },
  title: 'Admin Dashboard',
}

// Dynamic title resolver
export const productTitleResolver: ResolveFn<string> = (route) => {
  const productService = inject(ProductService);
  const id = route.paramMap.get('id')!;
  return productService.getProduct(id).pipe(
    map(product => `${product.name} — Product Detail`)
  );
};

// Usage
{
  path: 'products/:id',
  component: ProductDetailComponent,
  title: productTitleResolver,
}
```

## Preloading Strategies

```typescript
import { provideRouter, withPreloading, PreloadAllModules } from '@angular/router';

// Preload all lazy modules after initial load
provideRouter(routes, withPreloading(PreloadAllModules))

// Custom selective preloading
@Injectable({ providedIn: 'root' })
export class SelectivePreloadStrategy implements PreloadingStrategy {
  preload(route: Route, load: () => Observable<any>): Observable<any> {
    if (route.data?.['preload']) {
      return load();
    }
    return of(null);
  }
}

// Mark routes for preloading
{
  path: 'dashboard',
  loadComponent: () => import('./dashboard.component'),
  data: { preload: true },
}

provideRouter(routes, withPreloading(SelectivePreloadStrategy))
```

## Scroll Position Restoration

```typescript
import { provideRouter, withInMemoryScrolling } from '@angular/router';

provideRouter(
  routes,
  withComponentInputBinding(),
  withInMemoryScrolling({
    scrollPositionRestoration: 'enabled',
    anchorScrolling: 'enabled',
  })
)
```

## Full Route Configuration Reference

```typescript
{
  path: 'products/:id',
  component: ProductDetailComponent,

  // Lazy loading alternatives
  loadComponent: () => import('./product.component').then(m => m.ProductDetailComponent),
  loadChildren: () => import('./product.routes').then(m => m.productRoutes),

  // Guards
  canActivate: [authGuard],
  canActivateChild: [authGuard],
  canDeactivate: [unsavedChangesGuard],
  canMatch: [featureFlagGuard],

  // Data
  resolve: { product: productResolver },
  data: { title: 'Product Detail', breadcrumb: 'Product' },
  title: productTitleResolver,

  // Children
  children: [...],

  // Path matching
  pathMatch: 'full', // or 'prefix'
}
```

## Rules

| Rule | Rationale |
| ---- | --------- |
| ALWAYS use relative `redirectTo` in child routes (`'dashboard'`, not `'/dashboard'`) | Absolute redirects bypass parent guard context and break when parent gets a path prefix |
| ALWAYS use allowlist for URL validation (`url.startsWith('/') && !url.startsWith('//')`) | Blocklists miss dangerous schemes (`javascript:`, `data:`, `blob:`) — allowlists are simpler and future-proof |
| Sanitize `returnUrl` by stripping query params and fragments | Prevents leaking sensitive params via browser history and Referer headers |

## Quick Reference

| Pattern | When to Use |
| ------- | ----------- |
| `input()` for route params | Read `:id` params as signals (with `withComponentInputBinding`) |
| `loadComponent` | Lazy load a single standalone component |
| `loadChildren` | Lazy load a set of child routes |
| `canActivate` | Protect routes from unauthorized access |
| `canDeactivate` | Warn users about unsaved changes |
| `resolve` | Pre-fetch data before route activation |
| `withPreloading(PreloadAllModules)` | Eagerly load lazy routes in background |
| `withInMemoryScrolling` | Restore scroll position on navigation |
| `router.navigate([...])` | Navigate programmatically |
| `routerLink` / `routerLinkActive` | Template-based navigation with active state |

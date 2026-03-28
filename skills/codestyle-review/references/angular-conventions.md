# Angular Conventions Reference

## Tooling

- Prettier for formatting (auto-applied).
- ESLint for linting.

## Component Style

- Standalone components only. No `NgModules` for feature components. Flag any new `@NgModule`.
- Use Angular signals for reactive state. Flag new usage of `BehaviorSubject` for state management.
- Signal Forms (new code) or Reactive Forms (existing code). Both are acceptable. Flag template-driven forms (`ngModel` used for form binding).

## Naming Conventions

| Element          | Convention                  | Example                           |
|------------------|-----------------------------|-----------------------------------|
| Component selectors | kebab-case with prefix   | `app-product-list`                |
| Class names      | PascalCase                  | `ProductListComponent`            |
| Services         | PascalCase + Service suffix | `ProductService`                  |
| Signal Stores    | PascalCase + Store suffix   | `ProductStore`                    |
| Files            | kebab-case                  | `product-list.component.ts`       |
| Interfaces       | PascalCase, no I prefix     | `Product`, not `IProduct`         |
| Enums            | PascalCase                  | `OrderStatus`                     |
| Constants        | UPPER_SNAKE_CASE or camelCase | `MAX_RETRIES` or `defaultConfig` |

## Testing

- Use Vitest for unit tests: `vi.fn()`, `vi.spyOn()`, `vi.mock()`.
- Flag new test files using Jasmine patterns (`jasmine.createSpy`, `jasmine.createSpyObj`).
- Import test utilities from `vitest`: `describe`, `it`, `expect`, `vi`, `beforeEach`.

## Formatting

- Single quotes for strings.
- Trailing commas in multi-line arrays, objects, and function parameters.
- No unused variables or imports.
- No `any` type. Flag every occurrence. Use proper typing, `unknown`, or generics instead.
- Prefer `const` over `let`. Flag `let` when the variable is never reassigned.
- Use strict template typing.

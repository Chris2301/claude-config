# Frontend Architecture Patterns Reference

## Component Architecture

- Standalone components only. No `NgModules` for feature components.
- Package-per-feature structure mirroring the backend where applicable.
- Components should be thin — display logic only. Delegate business logic to services or signal stores.

## State Management

- Use Angular Signals as the primary reactivity model.
- Use NgRx Signal Store for complex or shared state that spans multiple components.
- Do NOT use `BehaviorSubject` or RxJS-based state management for new code. Signals are the project standard.
- Local component state via signals. Shared/global state via NgRx Signal Store.

## UI Library

- Spartan UI (Brain + Helm) is the primary component library with Tailwind CSS.
- Use Spartan UI components before building custom UI.
- Flag custom UI components that duplicate existing Spartan UI functionality.

## Forms

- Signal Forms (recommended for new code) or Reactive Forms. Both are acceptable.
- Flag any use of template-driven forms (`ngModel` for form inputs).
- Signal Forms: validation via schema validators (`required`, `validate`, `validateHttp`).
- Reactive Forms: validation via `Validators` and custom `ValidatorFn`.

## HTTP & Data Fetching

- Use `httpResource()` for signal-based reactive GET requests (auto-refetch on param change).
- Use `resource()` for non-HTTP async data with signal reactivity.
- Use `HttpClient` in services for mutations (POST, PUT, DELETE) and complex RxJS pipelines.
- Use NgRx Signal Store `rxMethod` when state is shared across components and involves async.
- Flag duplicate data fetching — prefer `httpResource` or a shared store over multiple identical HTTP calls.

## General Principles

- Prefer `computed()` signals over template expressions for derived state.
- Lazy load feature routes.
- Use the `OnPush` change detection strategy on all components.
- Use `track` in `@for` blocks for list rendering.
- Use Vitest for unit tests (`vi.fn()`, `vi.spyOn()`). Do not use Jasmine/Karma for new tests.

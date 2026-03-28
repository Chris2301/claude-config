# Frontend Performance Reference

## Bundle Size

- Flag large third-party library imports (e.g., importing all of lodash instead of specific functions).
- Flag missing lazy loading on feature routes. All non-essential routes should be lazy loaded.
- Flag barrel files (`index.ts`) that re-export everything from a feature — this prevents tree-shaking.
- Suggest dynamic `import()` for heavy components or libraries that are not needed on initial load.
- Flag duplicate dependencies or libraries that overlap in functionality.

## Change Detection and Rendering

- Flag components missing `ChangeDetectionStrategy.OnPush`. All components should use OnPush.
- Flag expensive computations in templates (method calls, complex expressions). Suggest `computed()` signals instead.
- Flag missing `track` expression in `@for` loops. Every `@for` block must have a `track` clause.
- Flag large lists rendered without virtual scrolling (consider for lists over ~100 items).
- Flag unnecessary re-renders caused by object reference changes (prefer immutable updates).

## Network

- Flag missing error handling on HTTP calls (no `catchError`, no retry logic).
- Flag duplicate API calls (same data fetched multiple times without caching or sharing).
- Flag missing HTTP caching headers or client-side cache strategies for stable data.
- Flag large payloads fetched without pagination or filtering.
- Flag missing loading states or optimistic UI updates for better perceived performance.

## Assets

- Flag unoptimized images (large PNGs/JPGs that could be WebP/AVIF, missing width/height attributes).
- Flag missing `preload` for critical resources (fonts, above-the-fold images).
- Flag missing `prefetch` for likely next navigations.
- Flag inline SVGs that are large and could be external files with caching.

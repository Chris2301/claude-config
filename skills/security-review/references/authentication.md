# Authentication and Authorization Reference

## Context

- Authentication provider: OAuth2/OIDC via Auth0 (startup phase), migration to Keycloak planned for later.
- Sessions: Stateless only. JWT-based authentication. No server-side sessions allowed.

## Backend — Spring Security

- Every endpoint MUST have explicit authorization. Flag any endpoint missing `@PreAuthorize` or `@Secured` annotations.
- Custom `JwtAuthenticationFilter` extending `OncePerRequestFilter` is the PROJECT STANDARD. Do NOT flag this as a custom security anti-pattern.
- Flag JWT implementations that do not validate:
  - Token expiry (`exp` claim)
  - Token signature
  - Token issuer (`iss` claim)
- Flag JWT secrets that are hardcoded in source code or shorter than 256 bits.
- Flag missing rate limiting on authentication endpoints (`/login`, `/token`, `/register`, `/forgot-password`).
- Flag missing CSRF protection unless the application is a purely token-based API with no cookie-based authentication.

## Frontend

- Flag tokens stored in `localStorage` or `sessionStorage`. Recommend HttpOnly cookies or in-memory token storage.
- Flag missing route guards on protected routes.
- Flag missing token refresh logic (silent refresh or refresh token rotation).
- Flag authentication state leaked into URLs (tokens in query parameters or fragments).

## General

- Flag any authentication flow that transmits credentials over plain HTTP.
- Flag any endpoint that returns different error messages for "user not found" vs "wrong password" (user enumeration risk).

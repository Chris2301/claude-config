# Docker -- Dockerfile Patterns

Multi-stage builds, pinned base images, non-root user, optimized layers.

## Spring Boot Backend -- Multi-Stage Build

```dockerfile
# Stage 1: Build
FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /app

# Copy dependency files first for layer caching
COPY pom.xml .
COPY .mvn .mvn
COPY mvnw .
RUN chmod +x mvnw && ./mvnw dependency:go-offline -B

# Copy source and build
COPY src ./src
RUN ./mvnw package -DskipTests -B

# Stage 2: Runtime
FROM eclipse-temurin:21-jre-alpine AS runtime
WORKDIR /app

# Create non-root user
RUN addgroup -g 1000 appgroup && \
    adduser -u 1000 -G appgroup -D appuser

# Copy built artifact
COPY --from=build /app/target/*.jar app.jar

# Set ownership
RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health/liveness || exit 1

ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75.0", "-jar", "app.jar"]
```

## Angular Frontend -- Multi-Stage Build

```dockerfile
# Stage 1: Build
FROM node:22-alpine AS build
WORKDIR /app

# Copy dependency files first for layer caching
COPY package.json package-lock.json ./
RUN npm ci

# Copy source and build
COPY . .
RUN npm run build -- --configuration=production

# Stage 2: Serve with Nginx
FROM nginx:1.27-alpine AS runtime

# Remove default config
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/app.conf

# Copy built assets
COPY --from=build /app/dist/web-configurator/browser /usr/share/nginx/html

# Create non-root user and set permissions
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/run/nginx.pid

USER nginx

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:80/ || exit 1
```

### Nginx Config for Angular SPA

```nginx
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    # SPA fallback -- serve index.html for all routes
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # No cache for index.html
    location = /index.html {
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }

    # Health check endpoint
    location /health {
        return 200 'ok';
        add_header Content-Type text/plain;
    }
}
```

## Layer Ordering for Cache Optimization

Order layers from least to most frequently changed:

1. Base image (changes rarely)
2. System packages / runtime setup (changes rarely)
3. Dependency files (`pom.xml`, `package.json`) -- changes when deps update
4. Dependency download (`mvn dependency:go-offline`, `npm ci`) -- cached if deps unchanged
5. Source code -- changes on every build
6. Build step -- runs only when source changes

This ensures Docker layer cache is maximally effective.

## Non-Root User Setup

### Alpine-based images

```dockerfile
RUN addgroup -g 1000 appgroup && \
    adduser -u 1000 -G appgroup -D appuser
USER appuser
```

### Debian-based images

```dockerfile
RUN groupadd -g 1000 appgroup && \
    useradd -u 1000 -g appgroup -m appuser
USER appuser
```

Always use UID/GID 1000 for consistency with Kubernetes `securityContext.runAsUser`.

## .dockerignore

### Backend (.dockerignore)

```
target/
.git/
.gitignore
.idea/
*.iml
.vscode/
*.md
docker-compose*.yml
helm/
.github/
.gitlab-ci.yml
Makefile
scripts/
```

### Frontend (.dockerignore)

```
node_modules/
dist/
.git/
.gitignore
.idea/
.vscode/
*.md
docker-compose*.yml
helm/
.github/
.gitlab-ci.yml
Makefile
scripts/
e2e/
coverage/
.angular/
```

## Quick Reference

| Topic | Detail |
|-------|--------|
| Backend base (build) | `eclipse-temurin:21-jdk-alpine` |
| Backend base (runtime) | `eclipse-temurin:21-jre-alpine` |
| Frontend base (build) | `node:22-alpine` |
| Frontend base (runtime) | `nginx:1.27-alpine` |
| Non-root UID/GID | 1000 / 1000 |
| JVM heap | `-XX:MaxRAMPercentage=75.0` |
| Build caching | Dependencies before source code |
| Health check | `HEALTHCHECK` instruction in Dockerfile |
| Image tagging | Never use `latest` -- use git SHA or semantic version |
| Registry | `harbor.local/web-configurator/<service>:<tag>` |

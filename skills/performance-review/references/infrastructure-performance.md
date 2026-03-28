# Infrastructure Performance Reference

## Container Images

- Flag missing multi-stage Docker builds. Build and runtime stages must be separate to reduce final image size.
- Flag full OS base images (e.g., `ubuntu`, `debian`) in production. Prefer Alpine-based or distroless images.
- Flag unnecessary files included in the image (source code, build tools, test files, documentation). Use `.dockerignore`.
- Flag images without a pinned version tag (using `latest` instead of specific version or digest).

## Kubernetes Resources

- Flag missing resource `requests` and `limits` on containers. Both must be defined.
- Flag resource limits that are too high for a single-replica, single-node setup (~32GB RAM total). Be resource-conscious.
- Flag resource limits that are too low — will cause OOM kills or CPU throttling under normal load.
- Flag missing liveness and readiness probes. Both must be configured.
- Flag excessive logging that could fill disk or consume significant I/O.
- Flag missing `terminationGracePeriodSeconds` or values that are too short for graceful shutdown.

## Startup Time

- Suggest Spring Boot lazy initialization (`spring.main.lazy-initialization=true`) for development profiles to speed up startup.
- Flag large Docker images that slow down pod scheduling and startup.
- Flag missing JVM container-aware tuning flags:
  - `-XX:MaxRAMPercentage` (recommended over fixed `-Xmx` in containers)
  - `-XX:+UseContainerSupport` (enabled by default in modern JVMs but verify)
- Flag missing JVM warmup considerations for latency-sensitive endpoints.
- Flag Spring Boot fat JARs that could benefit from layered JAR extraction for better Docker layer caching.

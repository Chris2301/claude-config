# Makefile -- Local Development Patterns

One flat Makefile in the project root. All targets idempotent. Complex logic in `scripts/`.

## Variables

```makefile
# Configuration
REGISTRY     := harbor.local
PROJECT      := web-configurator
BACKEND_IMG  := $(REGISTRY)/$(PROJECT)/backend
FRONTEND_IMG := $(REGISTRY)/$(PROJECT)/frontend
TAG          := $(shell git rev-parse --short HEAD)
NAMESPACE    := default
CLUSTER_NAME := web-configurator
HELM_CHART   := helm/web-configurator
```

## Standard Targets

```makefile
.PHONY: dev destroy build push deploy test lint status logs

# Start k3d cluster and deploy all services
dev: cluster-up build deploy
	@echo "Development environment ready"

# Tear down k3d cluster
destroy:
	k3d cluster delete $(CLUSTER_NAME) 2>/dev/null || true
	@echo "Cluster destroyed"

# Build all container images
build: build-backend build-frontend

# Build backend image
build-backend:
	docker build -t $(BACKEND_IMG):$(TAG) -f backend/Dockerfile backend/

# Build frontend image
build-frontend:
	docker build -t $(FRONTEND_IMG):$(TAG) -f frontend/Dockerfile frontend/

# Push images to Harbor
push:
	docker push $(BACKEND_IMG):$(TAG)
	docker push $(FRONTEND_IMG):$(TAG)

# Helm install/upgrade into k3d
deploy:
	helm upgrade --install $(PROJECT) $(HELM_CHART) \
		-n $(NAMESPACE) \
		--set backend.image.tag=$(TAG) \
		--set frontend.image.tag=$(TAG) \
		--wait --timeout 120s

# Run all tests
test: test-backend test-frontend

# Run backend tests
test-backend:
	cd backend && ./mvnw verify -B

# Run frontend tests
test-frontend:
	cd frontend && npm test -- --watch=false

# Lint Dockerfiles, Helm charts, YAML
lint: lint-helm lint-docker

# Lint Helm charts
lint-helm:
	helm lint $(HELM_CHART)

# Lint Dockerfiles
lint-docker:
	docker run --rm -i hadolint/hadolint < backend/Dockerfile
	docker run --rm -i hadolint/hadolint < frontend/Dockerfile

# Show cluster and pod status
status:
	@echo "=== Nodes ==="
	kubectl get nodes
	@echo ""
	@echo "=== Pods ==="
	kubectl get pods -n $(NAMESPACE) -o wide
	@echo ""
	@echo "=== Services ==="
	kubectl get svc -n $(NAMESPACE)

# Tail logs from all pods
logs:
	kubectl logs -n $(NAMESPACE) -l app.kubernetes.io/instance=$(PROJECT) --all-containers -f --tail=100
```

## Helper Targets

```makefile
.PHONY: cluster-up cluster-status import-images

# Create k3d cluster if it does not exist
cluster-up:
	@k3d cluster list | grep -q $(CLUSTER_NAME) || \
		k3d cluster create $(CLUSTER_NAME) \
			--api-port 6550 \
			--port "80:80@loadbalancer" \
			--port "443:443@loadbalancer" \
			--agents 0
	@echo "Cluster $(CLUSTER_NAME) is running"

# Import images into k3d (avoids needing a registry for local dev)
import-images: build
	k3d image import $(BACKEND_IMG):$(TAG) -c $(CLUSTER_NAME)
	k3d image import $(FRONTEND_IMG):$(TAG) -c $(CLUSTER_NAME)

# Show cluster info
cluster-status:
	k3d cluster list
	kubectl cluster-info
```

## Complex Logic Delegation

When a target exceeds 5 lines of shell, move it to `scripts/`:

```makefile
# Run database migrations
migrate:
	./scripts/migrate.sh $(NAMESPACE)

# Seed development data
seed:
	./scripts/seed.sh $(NAMESPACE)

# Full integration test suite
test-e2e:
	./scripts/run-e2e.sh $(NAMESPACE)
```

Scripts must be:
- Executable (`chmod +x scripts/*.sh`)
- Idempotent (safe to run multiple times)
- Documented with a comment header explaining purpose and arguments

### Example script header

```bash
#!/usr/bin/env bash
# scripts/migrate.sh -- Run database migrations
# Usage: ./scripts/migrate.sh <namespace>
# Idempotent: yes (Flyway handles migration state)

set -euo pipefail

NAMESPACE="${1:?Usage: migrate.sh <namespace>}"
# ...
```

## Quick Reference

| Target | Purpose |
|--------|---------|
| `make dev` | Start k3d cluster + build + deploy |
| `make destroy` | Tear down k3d cluster |
| `make build` | Build all container images |
| `make push` | Push images to Harbor |
| `make deploy` | Helm install/upgrade into k3d |
| `make test` | Run all tests |
| `make lint` | Lint Dockerfiles, Helm charts |
| `make status` | Show cluster and pod status |
| `make logs` | Tail logs from all pods |
| `make import-images` | Import images into k3d without registry |
| Scripts dir | `scripts/` for logic >5 lines |
| Idempotency | All targets safe to run multiple times |

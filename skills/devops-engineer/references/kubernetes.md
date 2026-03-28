# Kubernetes -- k3s/k3d Patterns

Single-node k3s cluster with namespace separation for staging and production. k3d for local development.

## k3d Local Cluster Setup

```bash
# Create cluster with Traefik ingress and port mapping
k3d cluster create web-configurator \
  --api-port 6550 \
  --port "80:80@loadbalancer" \
  --port "443:443@loadbalancer" \
  --agents 0 \
  --k3s-arg "--disable=metrics-server@server:0"

# Verify cluster
kubectl cluster-info
kubectl get nodes
```

### k3d with Local Registry

```bash
# Create registry first
k3d registry create registry.localhost --port 5000

# Create cluster connected to registry
k3d cluster create web-configurator \
  --api-port 6550 \
  --port "80:80@loadbalancer" \
  --port "443:443@loadbalancer" \
  --registry-use k3d-registry.localhost:5000 \
  --agents 0
```

## k3s Staging/Production -- Namespace Separation

Staging and production share a single k3s cluster, separated by namespaces.

```bash
# Create namespaces
kubectl create namespace staging
kubectl create namespace production

# Label namespaces for monitoring/filtering
kubectl label namespace staging environment=staging
kubectl label namespace production environment=production
```

### Namespace Resource Quotas

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: resource-quota
  namespace: staging
spec:
  hard:
    requests.cpu: "2"
    requests.memory: "4Gi"
    limits.cpu: "4"
    limits.memory: "8Gi"
    pods: "20"
```

## Traefik IngressRoute CRD

```yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: backend-ingress
  namespace: staging
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`api.staging.web-configurator.example.com`)
      kind: Rule
      services:
        - name: backend
          port: 8080
  tls:
    certResolver: letsencrypt
```

### Traefik IngressRoute with Path Prefix

```yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: app-ingress
  namespace: staging
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`staging.web-configurator.example.com`) && PathPrefix(`/api`)
      kind: Rule
      services:
        - name: backend
          port: 8080
    - match: Host(`staging.web-configurator.example.com`)
      kind: Rule
      services:
        - name: frontend
          port: 80
  tls:
    certResolver: letsencrypt
```

## Standard Ingress Resource

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: backend-ingress
  namespace: staging
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
spec:
  rules:
    - host: api.staging.web-configurator.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: backend
                port:
                  number: 8080
  tls:
    - hosts:
        - api.staging.web-configurator.example.com
```

## Pod Security Context

All pods must run as non-root with restricted capabilities.

```yaml
spec:
  containers:
    - name: app
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        runAsGroup: 1000
        readOnlyRootFilesystem: true
        allowPrivilegeEscalation: false
        capabilities:
          drop:
            - ALL
      volumeMounts:
        - name: tmp
          mountPath: /tmp
  volumes:
    - name: tmp
      emptyDir:
        sizeLimit: 100Mi
```

Note: Spring Boot needs a writable `/tmp` for Tomcat work directory. Mount an `emptyDir` for this.

## Resource Requests and Limits -- Spring Boot

```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

### Resource Guidelines

| Component | Memory Request | Memory Limit | CPU Request | CPU Limit |
|-----------|---------------|-------------|-------------|-----------|
| Spring Boot backend | 256Mi | 512Mi | 100m | 500m |
| Angular frontend (Nginx) | 32Mi | 64Mi | 25m | 100m |
| PostgreSQL | 256Mi | 512Mi | 100m | 500m |

Set JVM heap to 75% of memory limit via `-XX:MaxRAMPercentage=75.0`.

## Liveness and Readiness Probes -- Spring Boot

```yaml
livenessProbe:
  httpGet:
    path: /actuator/health/liveness
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 3
  failureThreshold: 3
readinessProbe:
  httpGet:
    path: /actuator/health/readiness
    port: 8080
  initialDelaySeconds: 15
  periodSeconds: 5
  timeoutSeconds: 3
  failureThreshold: 3
```

Spring Boot must enable probes in `application.yml`:

```yaml
management:
  endpoint:
    health:
      probes:
        enabled: true
  health:
    livenessState:
      enabled: true
    readinessState:
      enabled: true
```

## Quick Reference

| Topic | Detail |
|-------|--------|
| Local dev cluster | `k3d cluster create` with port mapping |
| Staging namespace | `staging` with `environment=staging` label |
| Production namespace | `production` with `environment=production` label |
| Ingress controller | Traefik (k3s default) -- do not replace |
| Ingress CRD | `traefik.io/v1alpha1 IngressRoute` |
| Liveness probe | `GET /actuator/health/liveness` |
| Readiness probe | `GET /actuator/health/readiness` |
| Non-root user | `runAsUser: 1000`, `runAsNonRoot: true` |
| Spring Boot /tmp | Mount `emptyDir` at `/tmp` for Tomcat work dir |
| JVM heap sizing | `-XX:MaxRAMPercentage=75.0` |
| Backend memory | 256Mi request / 512Mi limit |
| Frontend memory | 32Mi request / 64Mi limit |

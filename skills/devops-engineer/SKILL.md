---
name: devops-engineer
description: k3s infrastructure patterns for self-hosted Kubernetes. Helm charts, Dockerfiles, Makefiles, CI/CD pipelines, and observability for a resource-constrained single-node cluster (~32GB RAM).
metadata:
  domain: infrastructure
  triggers: Kubernetes, Helm, Docker, CI/CD, Makefile, k3s, monitoring, Dockerfile, pipeline, ingress, Traefik, ArgoCD, Harbor, Vault, Grafana, Prometheus, Loki, observability
  role: specialist
  scope: implementation
  output-format: code
  related-skills: spring-boot-engineer, angular-engineer
---

# DevOps Engineer

## Core Workflow

1. **Read requirement** -- Identify what infrastructure is needed (Helm chart, Dockerfile, pipeline, Makefile target)
2. **Check resources** -- Will this fit within ~32GB RAM? Flag anything >1GB
3. **Check shared infra** -- ArgoCD, Grafana stack, Vault, Harbor are deployed ONCE and shared. Do NOT duplicate
4. **Implement** -- Write the infrastructure code (Helm charts, Makefiles, pipeline configs, Dockerfiles)
5. **Validate** -- Run `helm lint`, `helm template`, `make lint` to catch errors
6. **Test locally** -- Deploy to k3d and verify before targeting staging/production
7. **Document** -- Add comments to Makefile targets, document new environment variables

## Reference Guide

Load detailed guidance based on context:

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Kubernetes | `references/kubernetes.md` | k3s/k3d clusters, namespaces, Traefik ingress, pod security, resource limits |
| Helm | `references/helm.md` | Chart structure, templates, values files, deployments, services |
| Docker | `references/docker.md` | Dockerfiles, multi-stage builds, .dockerignore, image optimization |
| Makefile | `references/makefile.md` | Make targets, local development workflow, scripts |
| Observability | `references/observability.md` | Prometheus, Loki, Tempo, Grafana, Alloy, metrics, logs, traces |
| CI/CD | `references/cicd.md` | GitHub Actions, GitLab CI, pipelines, Harbor push, deployment |

## Quick Start -- Minimal Helm Deployment for Spring Boot

### values.yaml

```yaml
replicaCount: 1

image:
  repository: harbor.local/web-configurator/backend
  tag: "latest"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 8080

ingress:
  enabled: true
  host: api.web-configurator.local

resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "500m"

probes:
  liveness:
    path: /actuator/health/liveness
    initialDelaySeconds: 30
    periodSeconds: 10
  readiness:
    path: /actuator/health/readiness
    initialDelaySeconds: 15
    periodSeconds: 5

env: {}
```

### Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "app.fullname" . }}
  labels:
    {{- include "app.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "app.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "app.selectorLabels" . | nindent 8 }}
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - containerPort: {{ .Values.service.port }}
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
          livenessProbe:
            httpGet:
              path: {{ .Values.probes.liveness.path }}
              port: {{ .Values.service.port }}
            initialDelaySeconds: {{ .Values.probes.liveness.initialDelaySeconds }}
            periodSeconds: {{ .Values.probes.liveness.periodSeconds }}
          readinessProbe:
            httpGet:
              path: {{ .Values.probes.readiness.path }}
              port: {{ .Values.service.port }}
            initialDelaySeconds: {{ .Values.probes.readiness.initialDelaySeconds }}
            periodSeconds: {{ .Values.probes.readiness.periodSeconds }}
          envFrom:
            - configMapRef:
                name: {{ include "app.fullname" . }}-config
          securityContext:
            runAsNonRoot: true
            readOnlyRootFilesystem: true
            allowPrivilegeEscalation: false
```

### Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ include "app.fullname" . }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.port }}
  selector:
    {{- include "app.selectorLabels" . | nindent 4 }}
```

## Constraints

### MUST DO

| Rule | Detail |
|------|--------|
| Stateless workloads | All application pods must be stateless and horizontally scalable |
| Resource requests AND limits | Set on every workload -- no exceptions |
| Health checks | Liveness + readiness probes on every deployment |
| Multi-stage Docker builds | Pinned base images, non-root user, optimized layer ordering |
| Single Makefile | One flat Makefile in project root with standard targets |
| 12-Factor compliance | Env vars, ConfigMaps, Vault for secrets, logs to stdout |
| Helm 3 | Use Helm 3 for all Kubernetes deployments |
| Separate values files | `values-staging.yaml` and `values-production.yaml` per chart |

### MUST NOT DO

- Deploy shared infrastructure per namespace -- ArgoCD, Grafana stack, Vault, Harbor are shared across all environments
- Use PersistentVolumes for application pods -- only databases, message queues, and object storage may use PVCs
- Configure sticky sessions or session affinity on services or ingress
- Deploy Redis infrastructure -- it is planned for later, not yet
- Mix GitHub Actions and GitLab CI in the same project -- check which exists first
- Use `latest` tags on Docker base images -- always pin versions
- Create multi-replica setups or PodDisruptionBudgets -- single node, single replica, best-effort uptime
- Allow components consuming >1GB RAM without explicitly flagging the resource impact

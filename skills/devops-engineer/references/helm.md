# Helm -- Chart Patterns

Helm 3 for all Kubernetes deployments. Separate values files per environment.

## Chart.yaml

```yaml
apiVersion: v2
name: web-configurator
description: Web Configurator application
type: application
version: 0.1.0
appVersion: "1.0.0"
```

For an umbrella chart with subcharts:

```yaml
apiVersion: v2
name: web-configurator
description: Web Configurator umbrella chart
type: application
version: 0.1.0
dependencies:
  - name: backend
    version: "0.1.0"
    repository: "file://charts/backend"
  - name: frontend
    version: "0.1.0"
    repository: "file://charts/frontend"
```

## Chart Directory Structure

```
helm/
  web-configurator/
    Chart.yaml
    values.yaml
    values-staging.yaml
    values-production.yaml
    templates/
      _helpers.tpl
      deployment.yaml
      service.yaml
      ingress.yaml
      configmap.yaml
      NOTES.txt
```

## _helpers.tpl

```yaml
{{- define "app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "app.labels" -}}
helm.sh/chart: {{ include "app.name" . }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: {{ include "app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
```

## Deployment Template

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
      annotations:
        checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: {{ .Values.service.port }}
              protocol: TCP
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
          livenessProbe:
            httpGet:
              path: {{ .Values.probes.liveness.path }}
              port: http
            initialDelaySeconds: {{ .Values.probes.liveness.initialDelaySeconds }}
            periodSeconds: {{ .Values.probes.liveness.periodSeconds }}
            timeoutSeconds: 3
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: {{ .Values.probes.readiness.path }}
              port: http
            initialDelaySeconds: {{ .Values.probes.readiness.initialDelaySeconds }}
            periodSeconds: {{ .Values.probes.readiness.periodSeconds }}
            timeoutSeconds: 3
            failureThreshold: 3
          envFrom:
            - configMapRef:
                name: {{ include "app.fullname" . }}-config
          {{- if .Values.secrets.enabled }}
          env:
            {{- range $key, $value := .Values.secrets.env }}
            - name: {{ $key }}
              valueFrom:
                secretKeyRef:
                  name: {{ include "app.fullname" $ }}-secret
                  key: {{ $key }}
            {{- end }}
          {{- end }}
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

## Service Template

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ include "app.fullname" . }}
  labels:
    {{- include "app.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: http
      protocol: TCP
      name: http
  selector:
    {{- include "app.selectorLabels" . | nindent 4 }}
```

Do NOT set `sessionAffinity`. Services must be stateless.

## IngressRoute Template (Traefik CRD)

```yaml
{{- if .Values.ingress.enabled }}
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: {{ include "app.fullname" . }}
  labels:
    {{- include "app.labels" . | nindent 4 }}
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`{{ .Values.ingress.host }}`)
      kind: Rule
      services:
        - name: {{ include "app.fullname" . }}
          port: {{ .Values.service.port }}
  {{- if .Values.ingress.tls.enabled }}
  tls:
    certResolver: {{ .Values.ingress.tls.certResolver }}
  {{- end }}
{{- end }}
```

## ConfigMap Template

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "app.fullname" . }}-config
  labels:
    {{- include "app.labels" . | nindent 4 }}
data:
  {{- range $key, $value := .Values.env }}
  {{ $key }}: {{ $value | quote }}
  {{- end }}
```

## values.yaml -- Sensible Defaults

```yaml
replicaCount: 1

image:
  repository: harbor.local/web-configurator/backend
  tag: "1.0.0"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 8080

ingress:
  enabled: true
  host: api.web-configurator.local
  tls:
    enabled: false
    certResolver: letsencrypt

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

env:
  SPRING_PROFILES_ACTIVE: "default"
  JAVA_TOOL_OPTIONS: "-XX:MaxRAMPercentage=75.0"

secrets:
  enabled: false
  env: {}
```

## values-staging.yaml

```yaml
image:
  tag: "staging"

ingress:
  host: api.staging.web-configurator.example.com
  tls:
    enabled: true
    certResolver: letsencrypt

env:
  SPRING_PROFILES_ACTIVE: "staging"
  JAVA_TOOL_OPTIONS: "-XX:MaxRAMPercentage=75.0"

secrets:
  enabled: true
  env:
    DATABASE_URL: ""
    DATABASE_USERNAME: ""
    DATABASE_PASSWORD: ""
```

## values-production.yaml

```yaml
image:
  tag: "production"

resources:
  requests:
    memory: "512Mi"
    cpu: "200m"
  limits:
    memory: "1Gi"
    cpu: "1000m"

ingress:
  host: api.web-configurator.example.com
  tls:
    enabled: true
    certResolver: letsencrypt

env:
  SPRING_PROFILES_ACTIVE: "production"
  JAVA_TOOL_OPTIONS: "-XX:MaxRAMPercentage=75.0"

secrets:
  enabled: true
  env:
    DATABASE_URL: ""
    DATABASE_USERNAME: ""
    DATABASE_PASSWORD: ""
```

## Helm Commands

```bash
# Lint chart
helm lint helm/web-configurator/

# Render templates without installing
helm template web-configurator helm/web-configurator/ -f helm/web-configurator/values-staging.yaml

# Install/upgrade to staging
helm upgrade --install web-configurator helm/web-configurator/ \
  -n staging \
  -f helm/web-configurator/values-staging.yaml

# Install/upgrade to production
helm upgrade --install web-configurator helm/web-configurator/ \
  -n production \
  -f helm/web-configurator/values-production.yaml

# Rollback
helm rollback web-configurator -n staging

# Uninstall
helm uninstall web-configurator -n staging
```

## Quick Reference

| Topic | Detail |
|-------|--------|
| Chart API version | `apiVersion: v2` (Helm 3) |
| Replicas | Always `1` -- single node, single replica |
| Values per env | `values-staging.yaml`, `values-production.yaml` |
| Config checksum | Annotation triggers pod restart on ConfigMap change |
| Secret injection | Via Vault Agent or `secretKeyRef` -- never in git |
| Service type | `ClusterIP` -- Traefik handles external access |
| Session affinity | Never set -- stateless services |
| Lint before deploy | `helm lint` then `helm template` to validate |

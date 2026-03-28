# Observability -- Monitoring Patterns

Grafana stack deployed ONCE, shared across staging and production. Grafana Alloy collects everything as a DaemonSet.

## Architecture Overview

```
Pods (stdout logs, /metrics, traces)
  |
  v
Grafana Alloy (DaemonSet) -- collects from all namespaces
  |
  +---> Prometheus (metrics)
  +---> Loki (logs)
  +---> Tempo (traces)
  |
  v
Grafana (dashboards) -- namespace labels distinguish environments
```

All observability components are deployed in a dedicated `monitoring` namespace. Never deploy per-application namespace.

## Grafana Alloy -- DaemonSet Collector

Alloy replaces per-pod sidecars. One DaemonSet collects metrics, logs, and traces from all namespaces.

```yaml
# Alloy Helm values overlay
alloy:
  mode: flow
  resources:
    requests:
      memory: "128Mi"
      cpu: "50m"
    limits:
      memory: "256Mi"
      cpu: "200m"

  config: |
    // Scrape Prometheus metrics from all pods with annotation
    prometheus.scrape "pods" {
      targets = discovery.kubernetes.pods.targets
      forward_to = [prometheus.remote_write.default.receiver]

      scrape_interval = "30s"
    }

    // Collect logs from all containers
    loki.source.kubernetes "pods" {
      targets = discovery.kubernetes.pods.targets
      forward_to = [loki.write.default.receiver]
    }

    // Receive traces via OTLP
    otelcol.receiver.otlp "default" {
      grpc { endpoint = "0.0.0.0:4317" }
      http { endpoint = "0.0.0.0:4318" }

      output {
        traces = [otelcol.exporter.otlp.tempo.input]
      }
    }
```

## Spring Boot Actuator + Micrometer for Prometheus

### Dependencies (pom.xml)

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>
```

### Application Configuration

```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
  endpoint:
    health:
      show-details: always
      probes:
        enabled: true
  health:
    livenessState:
      enabled: true
    readinessState:
      enabled: true
  metrics:
    export:
      prometheus:
        enabled: true
    tags:
      application: ${spring.application.name}
      environment: ${ENVIRONMENT:local}
```

### Pod Annotations for Prometheus Scraping

```yaml
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
    prometheus.io/path: "/actuator/prometheus"
```

### Custom Business Metrics

```java
@Service
@RequiredArgsConstructor
public class ConfigurationService {

    private final MeterRegistry meterRegistry;

    public Configuration create(CreateConfigurationRequest request) {
        Timer.Sample sample = Timer.start(meterRegistry);
        try {
            // business logic...
            meterRegistry.counter("configurations.created",
                "type", request.type()).increment();
            return configuration;
        } finally {
            sample.stop(meterRegistry.timer("configurations.create.duration"));
        }
    }
}
```

## Structured JSON Logging for Loki

### Logback Configuration (logback-spring.xml)

```xml
<configuration>
    <springProfile name="!local">
        <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
            <encoder class="net.logstash.logback.encoder.LogstashEncoder">
                <includeMdcKeyName>traceId</includeMdcKeyName>
                <includeMdcKeyName>spanId</includeMdcKeyName>
            </encoder>
        </appender>
    </springProfile>

    <springProfile name="local">
        <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
            <encoder>
                <pattern>%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n</pattern>
            </encoder>
        </appender>
    </springProfile>

    <root level="INFO">
        <appender-ref ref="STDOUT" />
    </root>
</configuration>
```

### Dependency for JSON Logging

```xml
<dependency>
    <groupId>net.logstash.logback</groupId>
    <artifactId>logstash-logback-encoder</artifactId>
    <version>8.0</version>
</dependency>
```

Logs go to stdout. Alloy collects them. JSON structure enables Loki label extraction.

## Distributed Tracing with Tempo

### Dependencies

```xml
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-tracing-bridge-otel</artifactId>
</dependency>
<dependency>
    <groupId>io.opentelemetry</groupId>
    <artifactId>opentelemetry-exporter-otlp</artifactId>
</dependency>
```

### Configuration

```yaml
management:
  tracing:
    sampling:
      probability: 1.0  # 100% in staging, reduce in production
  otlp:
    tracing:
      endpoint: http://alloy.monitoring.svc.cluster.local:4318/v1/traces
```

### Tracing Sampling by Environment

```yaml
# values-staging.yaml
env:
  MANAGEMENT_TRACING_SAMPLING_PROBABILITY: "1.0"

# values-production.yaml
env:
  MANAGEMENT_TRACING_SAMPLING_PROBABILITY: "0.1"
```

## Namespace Labels and Filters

All dashboards must support filtering by namespace/environment.

### Grafana Dashboard Variables

```json
{
  "templating": {
    "list": [
      {
        "name": "namespace",
        "type": "query",
        "query": "label_values(kube_namespace_labels, namespace)",
        "multi": true,
        "includeAll": true
      }
    ]
  }
}
```

### PromQL with Namespace Filter

```promql
# Request rate by namespace
rate(http_server_requests_seconds_count{namespace="$namespace"}[5m])

# Memory usage by pod in namespace
container_memory_usage_bytes{namespace="$namespace", container!=""}

# Error rate
rate(http_server_requests_seconds_count{namespace="$namespace", status=~"5.."}[5m])
```

### LogQL with Namespace Filter

```logql
{namespace="$namespace"} | json | level="ERROR"

{namespace="$namespace", app="backend"} | json | status >= 500
```

## Quick Reference

| Topic | Detail |
|-------|--------|
| Metrics endpoint | `GET /actuator/prometheus` |
| Liveness probe | `GET /actuator/health/liveness` |
| Readiness probe | `GET /actuator/health/readiness` |
| Log format | JSON (logstash-logback-encoder) to stdout |
| Trace exporter | OTLP to Alloy at `alloy.monitoring.svc.cluster.local:4318` |
| Trace sampling (staging) | 100% (`probability: 1.0`) |
| Trace sampling (production) | 10% (`probability: 0.1`) |
| Alloy memory | 128Mi request / 256Mi limit |
| Monitoring namespace | `monitoring` -- shared, deployed once |
| Pod annotations | `prometheus.io/scrape`, `/port`, `/path` |
| Dashboard filtering | Namespace variable in all Grafana dashboards |
| No sidecars | Alloy DaemonSet collects everything -- no per-pod agents |

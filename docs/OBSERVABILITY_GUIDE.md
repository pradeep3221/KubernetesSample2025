# Observability Guide

> **Complete Logging, Monitoring, and Tracing Implementation**

---

## Table of Contents

1. [Overview](#overview)
2. [Logging with Serilog](#logging-with-serilog)
3. [Metrics with Prometheus](#metrics-with-prometheus)
4. [Traces with Tempo](#traces-with-tempo)
5. [Logs with Loki](#logs-with-loki)
6. [Visualization with Grafana](#visualization-with-grafana)
7. [OpenTelemetry Collector](#opentelemetry-collector)
8. [Viewing Observability Data](#viewing-observability-data)
9. [Best Practices](#best-practices)

---

## Overview

The system provides **full observability** through:

✅ **Structured Logging** (Serilog → Loki)  
✅ **Metrics Collection** (OpenTelemetry → Prometheus)  
✅ **Distributed Tracing** (OpenTelemetry → Tempo)  
✅ **Unified Visualization** (Grafana)  
✅ **Trace-to-Logs Correlation** (Automatic)  
✅ **Trace-to-Metrics Correlation** (Automatic)  

### Data Flow

```
Application Code
    ↓
OpenTelemetry SDK (instrumentation)
    ↓
OTLP Exporter
    ↓
OpenTelemetry Collector
    ├─→ Tempo (traces)
    ├─→ Prometheus (metrics)
    └─→ Loki (logs)
         ↓
    Grafana (visualization)
```

---

## Logging with Serilog

### Configuration

**Shared.Observability Library** provides centralized logging configuration:

```csharp
.MinimumLevel.Information()
.MinimumLevel.Override("Microsoft", LogEventLevel.Warning)
.MinimumLevel.Override("Microsoft.Hosting.Lifetime", LogEventLevel.Information)
.MinimumLevel.Override("System", LogEventLevel.Warning)
.Enrich.FromLogContext()
.Enrich.WithProperty("ServiceName", serviceName)
.Enrich.WithProperty("ServiceVersion", serviceVersion)
.Enrich.WithEnvironmentName()
.Enrich.WithMachineName()
.Enrich.WithThreadId()
.Enrich.WithSpan()
.Enrich.WithProperty("Application", "KubernetesSamples")
```

### Log Levels

| Level | Usage |
|-------|-------|
| `Verbose` | Detailed diagnostic information |
| `Debug` | Internal system events |
| `Information` | General informational messages |
| `Warning` | Abnormal or unexpected events |
| `Error` | Errors and exceptions |
| `Fatal` | Critical failures causing shutdown |

### Sinks

#### Console Sink
```
[2025-01-26 14:30:45.123 +00:00] [INF] [orders-api] Order created successfully 
{"OrderId": "abc-123", "CustomerId": "xyz-789"}
```

#### Grafana Loki Sink
- **Labels**: service, environment, application
- **Format**: JSON
- **Endpoint**: http://loki:3100

### Request Logging

All ASP.NET Core services use `UseSerilogRequestLogging` middleware:

```csharp
app.UseSerilogRequestLogging(options =>
{
    options.EnrichDiagnosticContext = (diagnosticContext, httpContext) =>
    {
        diagnosticContext.Set("RequestHost", httpContext.Request.Host.Value);
        diagnosticContext.Set("RequestScheme", httpContext.Request.Scheme);
        diagnosticContext.Set("UserAgent", httpContext.Request.Headers["User-Agent"].ToString());
    };
});
```

### Structured Logging Best Practices

✅ **DO:**
```csharp
Log.Information("Order created with ID {OrderId} for customer {CustomerId}", orderId, customerId);
```

❌ **DON'T:**
```csharp
Log.Information($"Order created with ID {orderId} for customer {customerId}");
```

---

## Metrics with Prometheus

### Configuration

**File**: `infra/prometheus/prometheus.yml`

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'orders-api'
    static_configs:
      - targets: ['orders-api:8080']
    metrics_path: '/metrics'

  - job_name: 'inventory-api'
    static_configs:
      - targets: ['inventory-api:8080']
    metrics_path: '/metrics'

  - job_name: 'notifications-api'
    static_configs:
      - targets: ['notifications-api:8080']
    metrics_path: '/metrics'

  - job_name: 'audit-api'
    static_configs:
      - targets: ['audit-api:8080']
    metrics_path: '/metrics'

  - job_name: 'api-gateway'
    static_configs:
      - targets: ['api-gateway:8080']
    metrics_path: '/metrics'
```

### Collected Metrics

**Application Metrics**
- HTTP request rate (requests/second)
- HTTP request duration (p50, p95, p99)
- HTTP error rate (%)
- Active requests

**Runtime Metrics**
- CPU usage (%)
- Memory usage (%)
- Garbage collection stats
- Thread count

**Database Metrics**
- Query performance
- Connection pool stats
- Transaction duration

**Business Metrics**
- Orders created per hour
- Inventory adjustments
- Low stock alerts
- Notification delivery rate

### Accessing Prometheus

```
URL: http://localhost:9090
```

**Query Examples:**
```promql
# Request rate
rate(http_requests_total[5m])

# Error rate
rate(http_requests_total{status=~"5.."}[5m])

# Request duration (p95)
histogram_quantile(0.95, http_request_duration_seconds_bucket)

# Memory usage
process_resident_memory_bytes
```

---

## Traces with Tempo

### Configuration

**File**: `infra/tempo/tempo.yml`

```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:
    timeout: 10s
    send_batch_size: 1024

exporters:
  logging:
    loglevel: debug

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [logging]
```

### Trace Features

✅ **End-to-End Request Tracking** - Follow requests across services  
✅ **Service Dependency Graphs** - Visualize service interactions  
✅ **Trace-to-Metrics Correlation** - Link traces to metrics  
✅ **Trace-to-Logs Correlation** - Link traces to logs  
✅ **Span Metrics** - Generate metrics from traces  

### Accessing Tempo

Through Grafana:
1. Go to http://localhost:3000
2. Select Tempo datasource
3. Use TraceQL to query traces

---

## Logs with Loki

### Configuration

**File**: `infra/loki/loki-config.yml`

```yaml
auth_enabled: false

ingester:
  chunk_idle_period: 3m
  max_chunk_age: 1h
  max_streams_per_user: 10000

limits_config:
  enforce_metric_name: false
  reject_old_samples: true
  reject_old_samples_max_age: 168h

schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

server:
  http_listen_port: 3100
```

### Log Labels

| Label | Description | Example |
|-------|-------------|---------|
| `service` | Service name | `orders-api` |
| `environment` | Environment | `development` |
| `application` | Application name | `kubernetes-samples` |

### LogQL Queries

```logql
# All logs from orders-api
{service="orders-api"}

# Error logs across all services
{service=~".+"} |= "error"

# Logs for a specific trace
{service="orders-api"} | json | trace_id="abc123"

# Logs from last 5 minutes
{service="orders-api"} [5m]

# Count errors by service
sum by (service) (count_over_time({service=~".+", level="Error"}[1h]))
```

---

## Visualization with Grafana

### Access

```
URL: http://localhost:3000
Username: admin
Password: admin
```

### Pre-configured Datasources

| Datasource | Type | URL |
|-----------|------|-----|
| Prometheus | Prometheus | http://prometheus:9090 |
| Loki | Loki | http://loki:3100 |
| Tempo | Tempo | http://tempo:3200 |

### Features

✅ **Dashboards** - Pre-built dashboards for metrics  
✅ **Log Exploration** - Query and explore logs  
✅ **Trace Visualization** - View distributed traces  
✅ **Correlation** - Jump between traces, logs, and metrics  
✅ **Alerting** - Set up alerts based on metrics  

---

## OpenTelemetry Collector

### Configuration

**File**: `infra/otel-collector/otel-collector-config.yml`

```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:
    timeout: 10s
    send_batch_size: 1024
  memory_limiter:
    check_interval: 1s
    limit_mib: 512

exporters:
  prometheus:
    endpoint: "0.0.0.0:8888"
  otlp:
    endpoint: tempo:4317
    tls:
      insecure: true
  logging:
    loglevel: debug

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [otlp, logging]
    metrics:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [prometheus, logging]
    logs:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [logging]
```

---

## Viewing Observability Data

### Console Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f orders-api

# Last 100 lines
docker-compose logs --tail=100 orders-api
```

### Grafana Dashboards

1. Open http://localhost:3000
2. Login with admin/admin
3. Explore pre-configured dashboards
4. Create custom dashboards

### Prometheus Queries

1. Open http://localhost:9090
2. Use PromQL to query metrics
3. Create graphs and alerts

### Loki Logs

1. In Grafana, select Loki datasource
2. Use LogQL to query logs
3. Explore log patterns

### Tempo Traces

1. In Grafana, select Tempo datasource
2. Search for traces by service, span name, or duration
3. View trace details and correlations

---

## Best Practices

### Logging

✅ Use structured logging with named parameters  
✅ Include correlation IDs for request tracking  
✅ Log at appropriate levels (not everything as INFO)  
✅ Include context in error logs  
✅ Use consistent log formatting  

### Metrics

✅ Use meaningful metric names  
✅ Include relevant labels  
✅ Monitor business metrics, not just technical  
✅ Set up alerts for critical metrics  
✅ Use appropriate aggregation intervals  

### Tracing

✅ Instrument all external calls  
✅ Include relevant span attributes  
✅ Use consistent naming conventions  
✅ Sample traces appropriately  
✅ Correlate traces with logs  

---

**Observability is production-ready and comprehensive!** 📊


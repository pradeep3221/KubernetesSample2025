# .NET Microservices on Kubernetes — Sample Architecture

> Goal: a sample microservice architecture using the latest .NET stack, orchestrated on Kubernetes, event-driven (RabbitMQ), with multiple service types (API, Console, Worker), polyglot persistence (SQL Server + PostgreSQL + Redis + Marten), **Ocelot API Gateway**, **Keycloak as IAM**, **Open-source observability (OpenTelemetry + Prometheus + Grafana + Loki/Tempo)**, and two Angular frontends — a **Customer SPA** and an **Admin PWA**.

---

## 1) High-level overview

* Microservices (examples):

  * **Orders API** — manages customer orders, uses **SQL Server (EF Core)**.
  * **Inventory API** — manages product stock, uses **PostgreSQL (Dapper/EF Core)**.
  * **Notifications API** — manages system and user notifications, uses **Redis**.
  * **Audit API** — captures domain events and document data using **Marten (PostgreSQL)**.
  * **Ocelot API Gateway** — routes requests to backend APIs, integrates with Keycloak for authentication and authorization.
  * **Inventory Worker** — background service consuming RabbitMQ events to update inventory.
  * **Notifications Console** — console app publishing or testing events.
* Messaging: **RabbitMQ (MassTransit)** for asynchronous communication between services.
* Identity and Access Management: **Keycloak** integrated via OpenID Connect / OAuth2.
* Observability (open-source): **OpenTelemetry** (traces/metrics/logs), **Prometheus** (metrics), **Grafana** (dashboards), **Loki** (logs), **Tempo** (traces).
* Frontends:

  * **Customer SPA (Angular)** — for customer interactions (placing orders, tracking) using Keycloak public client.
  * **Admin Console (Angular PWA)** — for administrators (order/inventory management) using Keycloak confidential client.
* Orchestration: **Kubernetes** with Helm charts per service and a central `values.yaml` for environment configuration.
* Persistence: each microservice uses its own database (polyglot persistence).

---

## 2) Open-source Observability Stack (Recommended)

### Core Components

* **OpenTelemetry (OTel)**: instrument .NET services for tracing, metrics and logs. Use OTel SDK + exporters.
* **Prometheus**: scrape metrics from instrumented services and OTel Collector (metrics receiver).
* **Grafana**: visualize dashboards and connect to Prometheus, Loki and Tempo.
* **Loki**: centralized log aggregation (push logs via Promtail or Fluent Bit).
* **Tempo** (or Jaeger): store and query distributed traces (ingested from OTel Collector).
* **OpenTelemetry Collector**: receive telemetry (OTLP), process and export to Prometheus/Tempo/Loki.
* **Alertmanager**: for Prometheus alerting rules and notifications.

### Deployment Strategy

* Deploy the **OpenTelemetry Collector** as a Deployment/DaemonSet (collector + gateway) in Kubernetes.
* Deploy **Prometheus** and **Alertmanager** via the Prometheus community Helm chart (kube-prometheus-stack).
* Deploy **Grafana**, **Loki**, and **Promtail** (or Fluent Bit) via Helm.
* Instrument all services (APIs, Workers, Gateway) with OpenTelemetry SDK and export to the Collector via OTLP/gRPC.

### Service annotations for Prometheus scraping

In each Service/Deployment add Prometheus scrape annotations for metrics endpoints (if using Prometheus scraping directly):

```yaml
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "80"
    prometheus.io/path: "/metrics"
```

---

## 3) Instrumenting .NET services with OpenTelemetry

### NuGet packages

* `OpenTelemetry.Extensions.Hosting`
* `OpenTelemetry.Instrumentation.AspNetCore`
* `OpenTelemetry.Instrumentation.Http`
* `OpenTelemetry.Instrumentation.SqlClient` (optional)
* `OpenTelemetry.Exporter.Otlp`
* `OpenTelemetry.Exporter.Prometheus` (or expose `/metrics` endpoint via Prometheus exporter)
* `Serilog.AspNetCore` + `Serilog.Sinks.Grafana.Loki` or `Serilog.Sinks.Console` + OTel log exporter

### Example `Program.cs` (Orders API)

```csharp
using OpenTelemetry.Metrics;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;
using OpenTelemetry.Logs;

var builder = WebApplication.CreateBuilder(args);

var serviceName = "orders-api";
var serviceVersion = "1.0.0";

builder.Services.AddOpenTelemetry()
    .WithTracing(tracerProviderBuilder => tracerProviderBuilder
        .SetResourceBuilder(ResourceBuilder.CreateDefault().AddService(serviceName: serviceName, serviceVersion: serviceVersion))
        .AddAspNetCoreInstrumentation()
        .AddHttpClientInstrumentation()
        .AddSqlClientInstrumentation()
        .AddMassTransitInstrumentation() // if available
        .AddOtlpExporter(opt => { opt.Endpoint = new Uri(builder.Configuration["Otlp:Endpoint"] ?? "http://otel-collector:4317"); }))
    .WithMetrics(metricsBuilder => metricsBuilder
        .AddAspNetCoreInstrumentation()
        .AddHttpClientInstrumentation()
        .AddRuntimeInstrumentation()
        .AddOtlpExporter(opt => { opt.Endpoint = new Uri(builder.Configuration["Otlp:Endpoint"] ?? "http://otel-collector:4317"); }))
    ;

// Optionally configure logs to OTel
builder.Logging.ClearProviders();
builder.Logging.AddOpenTelemetry(options =>
{
    options.SetResourceBuilder(ResourceBuilder.CreateDefault().AddService(serviceName));
    options.AddOtlpExporter(otlpOptions => otlpOptions.Endpoint = new Uri(builder.Configuration["Otlp:Endpoint"] ?? "http://otel-collector:4317"));
});

var app = builder.Build();

app.MapGet("/metrics", () => Results.Ok("Prometheus will scrape metrics from the collector or service exporter"));

app.Run();
```

> Notes: configure `Otlp:Endpoint` to point to the collector's OTLP endpoint (e.g., `otel-collector:4317`). Use secure connections (mTLS/TLS) in production.

### Serilog + Loki example (logs)

```csharp
Log.Logger = new LoggerConfiguration()
    .Enrich.FromLogContext()
    .WriteTo.Console()
    .WriteTo.GrafanaLoki("http://loki:3100")
    .CreateLogger();

builder.Host.UseSerilog();
```

---

## 4) OpenTelemetry Collector configuration

Deploy a collector that receives OTLP and exports to Prometheus, Loki, and Tempo. Example `collector-config.yaml` snippet:

```yaml
receivers:
  otlp:
    protocols:
      grpc:
      http:

exporters:
  prometheusremotewrite:
    endpoint: "http://prometheus:9090"
  loki:
    endpoint: "http://loki:3100/loki/api/v1/push"
  otlp/tempo:
    endpoint: "tempo:4317"

service:
  pipelines:
    traces:
      receivers: [otlp]
      exporters: [otlp/tempo]
    metrics:
      receivers: [otlp]
      exporters: [prometheusremotewrite]
    logs:
      receivers: [otlp]
      exporters: [loki]
```

> You can run the collector as a Deployment and provide a `Service` exposing a `/metrics` endpoint for Prometheus if needed.

---

## 5) Prometheus & Alertmanager

* Use the **kube-prometheus-stack** Helm chart (Prometheus Operator) to deploy Prometheus, Alertmanager, node exporters and service monitors.
* Create `ServiceMonitor` resources to scrape the OTel Collector and instrumented services.
* Example Prometheus alert rule (high error rate):

```yaml
groups:
- name: application.rules
  rules:
  - alert: HighErrorRate
    expr: increase(http_server_requests_failed_total[5m]) > 10
    for: 2m
    labels:
      severity: critical
    annotations:
      summary: "High application error rate"
      description: "{{ $labels.job }} has more than 10 errors in the last 5 minutes."
```

---

## 6) Grafana dashboards

* Provision dashboards with Helm or Grafana provisioning (JSON files stored in repo).
* Useful dashboards:

  * Service overview (latency, requests, errors)
  * RabbitMQ metrics (queue depths, consumers)
  * Database performance (connections, queries)
  * Kubernetes cluster (pods, CPU, memory)
  * Loki log query panels
* Example data sources: Prometheus, Loki, Tempo.

---

## 7) Logs collection (Loki + Promtail/Fluent Bit)

* Use **Promtail** or **Fluent Bit** as a DaemonSet to collect pod logs and push to **Loki**.
* Annotate pods with labels so Promtail can route logs appropriately.
* Alternatively use `Serilog` with a Loki sink from applications for structured logs.

---

## 8) Tracing (Tempo)

* Tempo stores traces ingested from the OTel Collector.
* Connect Grafana to Tempo to visualize traces and link traces to logs (Loki) and metrics (Prometheus).

---

## 9) Repo layout updates (observability)

```
repo-root/
├─ charts/
│  ├─ ocelot-chart/
│  ├─ orders-chart/
│  ├─ inventory-chart/
│  ├─ notifications-chart/
│  ├─ audit-chart/
│  ├─ keycloak-chart/
│  ├─ observability/
│  │  ├─ prometheus/
│  │  ├─ grafana/
│  │  ├─ loki/
│  │  ├─ tempo/
│  │  └─ otel-collector/
│  └─ frontend-chart/
├─ services/
│  ├─ orders.api/
│  ├─ inventory.api/
│  ├─ notifications.api/
│  ├─ audit.api/
│  ├─ inventory.worker/
│  └─ notifications.console/
├─ gateway/
│  └─ ocelot.api/
├─ frontend/
│  ├─ customer-app/
│  └─ admin-console/
├─ infra/
│  ├─ rabbitmq-helm/
│  └─ postgres-audit-helm/
├─ observability/
│  ├─ collector-config.yaml
│  ├─ grafana/provisioning/
│  └─ prometheus/rules/
├─ docker-compose.yml
└─ README.md
```

---

## 10) Quick instrumentation checklist

* Add OpenTelemetry SDK and exporters to each .NET service.
* Expose Prometheus scrape metrics (either from service or collector).
* Configure Serilog for structured logs; push to Loki via sink or use Promtail to collect stdout.
* Deploy OTel Collector and configure pipelines to Prometheus, Loki, Tempo.
* Deploy kube-prometheus-stack, Grafana, Loki (plus Promtail), and Tempo.
* Provision Grafana dashboards and Prometheus alerting rules.

---

## 11) Example: Add instrumentation to MassTransit consumer

```csharp
public class OrderCreatedConsumer : IConsumer<OrderCreated>
{
    private readonly ILogger<OrderCreatedConsumer> _logger;

    public OrderCreatedConsumer(ILogger<OrderCreatedConsumer> logger) => _logger = logger;

    public async Task Consume(ConsumeContext<OrderCreated> context)
    {
        using var activity = OpenTelemetry.Trace.ActivitySource.StartActivity("Consume OrderCreated");
        activity?.SetTag("order.id", context.Message.OrderId);

        _logger.LogInformation("Consuming OrderCreated {OrderId}", context.Message.OrderId);
        // process
        await Task.CompletedTask;
    }
}
```

---

## 12) Security & scaling notes

* Secure OTel endpoints and Grafana with network policies and RBAC.
* Use resource requests/limits, HPA for collector and Prometheus components where appropriate.
* Use retention policies in Prometheus & Loki and lifecycle management for Tempo.

---

## 13) Summary

You now have a full-stack open-source observability plan integrated into the microservices architecture: **OpenTelemetry** for instrumentation, **OTel Collector** for processing, **Prometheus + Alertmanager** for metrics and alerts, **Grafana** for visualization, **Loki** for logs, and **Tempo** for traces.

---

*Next step suggestion:* I can scaffold the `collector-config.yaml`, Helm chart values for the observability stack, and a sample Grafana dashboard JSON for the Orders API. Which of these should I generate first?

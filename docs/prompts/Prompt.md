# .NET Microservices on Kubernetes — Sample Architecture

> Goal: a sample microservice architecture using the latest .NET stack, orchestrated on Kubernetes, event-driven (RabbitMQ), with multiple service types (API, Console, Worker), polyglot persistence (SQL Server + PostgreSQL + Redis + Marten), **Ocelot API Gateway**, **Keycloak as IAM**, and two Angular frontends — a **Customer SPA** and an **Admin PWA**.

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
* Use Serilog for structured logging and  Use OpenTelemetry for distributed tracing and metrics.
* use service monitors to scrape metrics from instrumented services and OTel Collector.
* Observability: **OpenTelemetry** (traces/metrics/logs), **Prometheus** (metrics), **Grafana** (dashboards), **Loki** (logs), **Tempo** (traces).
* Alerting: **Prometheus** with alert rules and notifications via **Alertmanager**.
* Messaging: **RabbitMQ (MassTransit)** for asynchronous communication between services.
* Dependency checks: ensure database, Redis, and RabbitMQ connectivity.
* Identity and Access Management: **Keycloak** integrated via OpenID Connect / OAuth2.
* API Gateway: **Ocelot** for routing and Keycloak integration.
* Health checks: **Liveness** (is the service running?) and **Readiness** (is the service ready to handle requests?) probes.
* Use service mesh patterns: retries, circuit breakers, timeouts, bulkheads. If time permits, consider Istio and kiali.
* Frontends: **Customer SPA (Angular)** and **Admin Console (Angular PWA)**.
* Optional: Local development: **Docker Compose** for all services.

* Frontends:

  * **Customer SPA (Angular)** — for customer interactions (placing orders, tracking) using Keycloak public client.
  * **Admin Console (Angular PWA)** — for administrators (order/inventory management) using Keycloak confidential client.
* Orchestration: **Kubernetes** with Helm charts per service and a central `values.yaml` for environment configuration.
* Persistence: each microservice uses its own database (polyglot persistence).

---

## 2) Audit API — Marten (Document + Event Store)

### Purpose

* Central event and document store for the platform.
* Stores domain events from RabbitMQ (e.g., `OrderCreated`, `InventoryAdjusted`).
* Provides APIs to query audit trails, replay events, and inspect domain changes.

### Tech stack

* .NET 9 Web API
* Marten + PostgreSQL
* MassTransit + RabbitMQ consumer

### Example `Program.cs`

```csharp
using Marten;
using MassTransit;

var builder = WebApplication.CreateBuilder(args);

// Configure Marten (Document & Event Store)
builder.Services.AddMarten(options =>
{
    options.Connection(builder.Configuration.GetConnectionString("AuditDb"));
    options.AutoCreateSchemaObjects = Weasel.Core.AutoCreate.All;
    options.Events.DatabaseSchemaName = "events";
    options.DatabaseSchemaName = "documents";
});

// Configure MassTransit to consume audit events
builder.Services.AddMassTransit(x =>
{
    x.AddConsumer<OrderCreatedConsumer>();
    x.UsingRabbitMq((context, cfg) =>
    {
        cfg.Host(builder.Configuration["RabbitMQ:Host"], h =>
        {
            h.Username(builder.Configuration["RabbitMQ:User"]);
            h.Password(builder.Configuration["RabbitMQ:Password"]);
        });
        cfg.ConfigureEndpoints(context);
    });
});

var app = builder.Build();
app.MapGet("/api/audit/events", async (IDocumentSession session) =>
{
    var events = await session.Events.FetchStreamAsync("order-stream");
    return Results.Ok(events);
});

app.Run();
```

### Example Event Consumer

```csharp
public class OrderCreatedConsumer : IConsumer<OrderCreated>
{
    private readonly IDocumentSession _session;

    public OrderCreatedConsumer(IDocumentSession session)
    {
        _session = session;
    }

    public async Task Consume(ConsumeContext<OrderCreated> context)
    {
        _session.Events.Append(context.Message.OrderId, context.Message);
        await _session.SaveChangesAsync();
    }
}
```

### Example Marten Document

```csharp
public record AuditDocument(Guid Id, string Entity, string Action, DateTime Timestamp, string Payload);
```

### API Routes

* `GET /api/audit/events` — fetch event streams.
* `GET /api/audit/documents/{entity}` — query documents by entity type.
* `POST /api/audit/replay` — replay events for a specific stream.

---

## 3) API Gateway (Ocelot)

### Example Ocelot configuration (routes)

```json
{
  "Routes": [
    {
      "DownstreamPathTemplate": "/api/orders/{everything}",
      "DownstreamScheme": "http",
      "DownstreamHostAndPorts": [ { "Host": "orders-api", "Port": 80 } ],
      "UpstreamPathTemplate": "/orders/{everything}",
      "AuthenticationOptions": {
        "AuthenticationProviderKey": "Keycloak",
        "AllowedScopes": ["orders.read"]
      }
    },
    {
      "DownstreamPathTemplate": "/api/audit/{everything}",
      "DownstreamScheme": "http",
      "DownstreamHostAndPorts": [ { "Host": "audit-api", "Port": 80 } ],
      "UpstreamPathTemplate": "/audit/{everything}",
      "AuthenticationOptions": {
        "AuthenticationProviderKey": "Keycloak",
        "AllowedScopes": ["audit.read"]
      }
    }
  ]
}
```

---

## 4) Suggested repo layout

```
repo-root/
├─ charts/
│  ├─ ocelot-chart/
│  ├─ orders-chart/
│  ├─ inventory-chart/
│  ├─ notifications-chart/
│  ├─ audit-chart/                # new chart for Marten Audit API
│  ├─ keycloak-chart/
│  └─ frontend-chart/
├─ services/
│  ├─ orders.api/
│  ├─ inventory.api/
│  ├─ notifications.api/
│  ├─ audit.api/                  # new microservice
│  ├─ inventory.worker/
│  └─ notifications.console/
├─ gateway/
│  └─ ocelot.api/
├─ frontend/
│  ├─ customer-app/
│  └─ admin-console/
├─ infra/
│  ├─ rabbitmq-helm/
│  └─ postgres-audit-helm/       # Postgres instance for Marten
├─ docker-compose.yml
└─ README.md
```

---

## 5) Summary

✅ 4 sample APIs — Orders, Inventory, Notifications, and **Audit** (Marten + PostgreSQL).
✅ Event-driven with RabbitMQ and MassTransit.
✅ Ocelot as API Gateway with Keycloak IAM integration.
✅ Angular SPA (Customer) and PWA (Admin) for frontend experiences.
✅ Polyglot persistence: SQL Server, PostgreSQL, Redis, and Marten (Document/Event Store).
✅ Fully deployable to Kubernetes via Helm with local dev via Docker Compose.

---

*Next step suggestion:* Scaffold **Audit API Helm chart** and **RabbitMQ event consumers** for all domain events (Orders + Inventory).

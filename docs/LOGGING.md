# Logging with Serilog

This document describes the comprehensive Serilog logging implementation across all .NET projects in the microservices architecture.

## Overview

All .NET projects in this solution use **Serilog** for structured logging with the following features:

- ✅ **Structured Logging** - JSON-formatted logs with rich context
- ✅ **Multiple Sinks** - Console and Grafana Loki
- ✅ **Request Logging** - Automatic HTTP request/response logging
- ✅ **Enrichers** - Service name, version, environment, machine name, thread ID
- ✅ **Trace Correlation** - Logs correlated with OpenTelemetry traces
- ✅ **Centralized Configuration** - Shared configuration via Shared.Observability library

---

## Architecture

### Shared.Observability Library

The `Shared.Observability` library provides centralized logging configuration for all services:

**Location:** `src/Shared/Shared.Observability/OpenTelemetryExtensions.cs`

**Key Features:**
- Configures Serilog with Console and Loki sinks
- Adds enrichers for service metadata
- Integrates with OpenTelemetry for trace correlation
- Provides consistent log formatting across all services

**NuGet Packages:**
```xml
<PackageReference Include="Serilog" Version="4.1.0" />
<PackageReference Include="Serilog.AspNetCore" Version="8.0.3" />
<PackageReference Include="Serilog.Sinks.Console" Version="6.0.0" />
<PackageReference Include="Serilog.Sinks.Grafana.Loki" Version="8.3.0" />
<PackageReference Include="Serilog.Enrichers.Environment" Version="3.0.1" />
<PackageReference Include="Serilog.Enrichers.Thread" Version="4.0.0" />
```

---

## Configuration

### Log Levels

Default log levels configured in `OpenTelemetryExtensions.cs`:

```csharp
.MinimumLevel.Information()
.MinimumLevel.Override("Microsoft", LogEventLevel.Warning)
.MinimumLevel.Override("Microsoft.Hosting.Lifetime", LogEventLevel.Information)
.MinimumLevel.Override("System", LogEventLevel.Warning)
```

### Enrichers

All logs are enriched with:

| Enricher | Description | Example |
|----------|-------------|---------|
| `ServiceName` | Name of the service | `orders-api` |
| `ServiceVersion` | Version of the service | `1.0.0` |
| `EnvironmentName` | Environment (dev/staging/prod) | `development` |
| `MachineName` | Host machine name | `container-abc123` |
| `ThreadId` | Thread ID | `42` |
| `Span` | OpenTelemetry span context | `trace_id`, `span_id` |
| `Application` | Application name | `KubernetesSamples` |

### Sinks

#### 1. Console Sink

**Format:**
```
[2025-01-26 14:30:45.123 +00:00] [INF] [orders-api] Order created successfully {"OrderId": "abc-123", "CustomerId": "xyz-789"}
```

**Configuration:**
```csharp
.WriteTo.Console(
    outputTemplate: "[{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz}] [{Level:u3}] [{ServiceName}] {Message:lj} {Properties:j}{NewLine}{Exception}")
```

#### 2. Grafana Loki Sink

**Labels:**
- `service` - Service name (e.g., `orders-api`)
- `environment` - Environment (e.g., `development`)
- `application` - Application name (`kubernetes-samples`)

**Format:** JSON

**Configuration:**
```csharp
.WriteTo.GrafanaLoki(
    lokiEndpoint,
    labels: new[]
    {
        new LokiLabel { Key = "service", Value = serviceName },
        new LokiLabel { Key = "environment", Value = configuration["Environment"] ?? "development" },
        new LokiLabel { Key = "application", Value = "kubernetes-samples" }
    },
    textFormatter: new JsonFormatter())
```

---

## Implementation by Project

### 1. Orders API

**File:** `src/Services/Orders.API/Program.cs`

**Features:**
- Serilog request logging middleware
- Database migration logging
- Startup/shutdown logging
- Request enrichment (Host, Scheme, UserAgent)

**Example Logs:**
```csharp
Log.Information("Starting Orders API...");
Log.Information("Running database migrations...");
Log.Information("Database migrations completed");
Log.Information("Orders API started successfully on {Urls}", app.Urls);
```

### 2. Inventory API

**File:** `src/Services/Inventory.API/Program.cs`

**Features:**
- Serilog request logging middleware
- Database migration logging
- Startup/shutdown logging

**Example Logs:**
```csharp
Log.Information("Starting Inventory API...");
Log.Information("Running database migrations...");
Log.Information("Inventory API started successfully");
```

### 3. Notifications API

**File:** `src/Services/Notifications.API/Program.cs`

**Features:**
- Serilog request logging middleware
- Startup/shutdown logging

**Example Logs:**
```csharp
Log.Information("Starting Notifications API...");
Log.Information("Notifications API started successfully");
```

### 4. Audit API

**File:** `src/Services/Audit.API/Program.cs`

**Features:**
- Serilog request logging middleware
- Startup/shutdown logging
- Marten event store logging

**Example Logs:**
```csharp
Log.Information("Starting Audit API...");
Log.Information("Audit API started successfully");
```

### 5. API Gateway (Ocelot)

**File:** `src/Gateway/Ocelot.Gateway/Program.cs`

**Features:**
- Serilog request logging middleware
- Request path enrichment
- Ocelot startup logging

**Example Logs:**
```csharp
Log.Information("Starting API Gateway...");
Log.Information("API Gateway configured, starting Ocelot...");
Log.Information("API Gateway started successfully");
```

### 6. Inventory Worker

**File:** `src/Workers/Inventory.Worker/Program.cs`

**Features:**
- Background service logging
- Event consumption logging

**Example Logs:**
```csharp
Log.Information("Starting Inventory Worker...");
```

### 7. Notifications Console

**File:** `src/Console/Notifications.Console/Program.cs`

**Features:**
- Console application logging
- Event publishing logging

**Configuration:**
```csharp
Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Information()
    .Enrich.FromLogContext()
    .WriteTo.Console(outputTemplate: "[{Timestamp:HH:mm:ss} {Level:u3}] {Message:lj}{NewLine}{Exception}")
    .CreateLogger();
```

---

## Request Logging

All ASP.NET Core services use `UseSerilogRequestLogging` middleware for automatic HTTP request logging.

**Example Configuration:**
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

**Example Log Output:**
```json
{
  "Timestamp": "2025-01-26T14:30:45.123Z",
  "Level": "Information",
  "MessageTemplate": "HTTP {RequestMethod} {RequestPath} responded {StatusCode} in {Elapsed:0.0000} ms",
  "Properties": {
    "RequestMethod": "GET",
    "RequestPath": "/api/orders",
    "StatusCode": 200,
    "Elapsed": 45.67,
    "RequestHost": "localhost:5001",
    "RequestScheme": "http",
    "UserAgent": "Mozilla/5.0...",
    "ServiceName": "orders-api",
    "TraceId": "abc123...",
    "SpanId": "def456..."
  }
}
```

---

## Viewing Logs

### 1. Console Output

View logs in real-time using Docker Compose:

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f orders-api

# Last 100 lines
docker-compose logs --tail=100 orders-api
```

### 2. Grafana Loki

Access Loki logs through Grafana:

**URL:** http://localhost:3000

**Query Examples:**

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

## Best Practices

### 1. Structured Logging

✅ **DO:**
```csharp
Log.Information("Order created with ID {OrderId} for customer {CustomerId}", orderId, customerId);
```

❌ **DON'T:**
```csharp
Log.Information($"Order created with ID {orderId} for customer {customerId}");
```

### 2. Log Levels

| Level | Usage |
|-------|-------|
| `Verbose` | Detailed diagnostic information |
| `Debug` | Internal system events |
| `Information` | General informational messages |
| `Warning` | Abnormal or unexpected events |
| `Error` | Errors and exceptions |
| `Fatal` | Critical failures causing shutdown |

### 3. Exception Logging

```csharp
try
{
    // Code that might throw
}
catch (Exception ex)
{
    Log.Error(ex, "Failed to process order {OrderId}", orderId);
    throw;
}
```

### 4. Startup/Shutdown Logging

```csharp
Log.Information("Starting {ServiceName}...", serviceName);

try
{
    app.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "{ServiceName} terminated unexpectedly", serviceName);
}
finally
{
    Log.CloseAndFlush();
}
```

---

## Trace Correlation

Logs are automatically correlated with OpenTelemetry traces using the `WithSpan()` enricher.

**Example:**
1. A request comes in with trace ID `abc123`
2. All logs for that request include `trace_id: abc123`
3. In Grafana, click on a trace span
4. Click "Logs for this span"
5. See all logs for that specific request

---

## Environment Variables

Configure logging behavior via environment variables:

```yaml
# docker-compose.yml
environment:
  - Loki__Endpoint=http://loki:3100
  - Environment=development
  - ASPNETCORE_ENVIRONMENT=Development
```

---

## Troubleshooting

### Logs not appearing in Loki

1. Check Loki is running: `docker-compose ps loki`
2. Check Loki endpoint: `curl http://localhost:3100/ready`
3. Verify environment variable: `Loki__Endpoint=http://loki:3100`
4. Check service logs for Serilog errors

### High log volume

Adjust log levels in `appsettings.json`:

```json
{
  "Serilog": {
    "MinimumLevel": {
      "Default": "Warning",
      "Override": {
        "Microsoft": "Error",
        "System": "Error"
      }
    }
  }
}
```

---

## Summary

✅ All .NET projects use Serilog for structured logging  
✅ Centralized configuration via Shared.Observability  
✅ Logs sent to Console and Grafana Loki  
✅ Automatic trace correlation with OpenTelemetry  
✅ Rich context with multiple enrichers  
✅ Request logging for all HTTP requests  
✅ Consistent formatting across all services  

**Serilog provides production-ready, observable logging for the entire microservices architecture!**


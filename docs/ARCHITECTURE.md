# Architecture Documentation

## System Architecture Overview

This document describes the architecture of the .NET Microservices platform with full observability.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         API Gateway (Ocelot)                     │
│                    + Keycloak Authentication                     │
└────────────┬────────────────────────────────────────────────────┘
             │
    ┌────────┴────────┬──────────────┬──────────────┐
    │                 │              │              │
┌───▼────┐      ┌────▼─────┐   ┌───▼──────┐  ┌───▼──────┐
│Orders  │      │Inventory │   │Notifica- │  │  Audit   │
│  API   │      │   API    │   │tions API │  │   API    │
└───┬────┘      └────┬─────┘   └────┬─────┘  └────┬─────┘
    │                │              │              │
    │  ┌─────────────┴──────────────┴──────────────┘
    │  │                 RabbitMQ
    │  │              (Event Bus)
    │  │
┌───▼──▼────────────────────────────────────────────────┐
│              OpenTelemetry Collector                   │
│         (Traces, Metrics, Logs Collection)            │
└───┬────────────┬────────────────┬─────────────────────┘
    │            │                │
┌───▼────┐  ┌───▼────┐      ┌───▼────┐
│ Tempo  │  │Prometheus│     │  Loki  │
│(Traces)│  │(Metrics) │     │ (Logs) │
└───┬────┘  └───┬──────┘     └───┬────┘
    │           │                │
    └───────────┴────────────────┴──────────┐
                                             │
                                        ┌────▼────┐
                                        │ Grafana │
                                        │(Unified │
                                        │  View)  │
                                        └─────────┘
```

## Component Details

### Microservices

#### 1. Orders API
- **Technology**: .NET 9, ASP.NET Core, EF Core
- **Database**: SQL Server
- **Responsibilities**:
  - Create and manage customer orders
  - Publish order events (Created, Confirmed, Cancelled, Shipped)
  - Validate order data
  - Calculate order totals

#### 2. Inventory API
- **Technology**: .NET 9, ASP.NET Core, Dapper + EF Core
- **Database**: PostgreSQL
- **Responsibilities**:
  - Manage product inventory
  - Track stock levels
  - Reserve/release inventory
  - Publish inventory events (Adjusted, Reserved, Released)
  - Alert on low stock

#### 3. Notifications API
- **Technology**: .NET 9, ASP.NET Core, Redis
- **Database**: Redis (in-memory)
- **Responsibilities**:
  - Send notifications to users
  - Store notification history
  - Support multiple notification types (Email, SMS, Push, InApp)
  - Consume events from other services

#### 4. Audit API
- **Technology**: .NET 9, ASP.NET Core, Marten
- **Database**: PostgreSQL (with Marten)
- **Responsibilities**:
  - Event sourcing - store all domain events
  - Document store - audit trail
  - Event replay capability
  - Query historical data

### Infrastructure Components

#### API Gateway (Ocelot)
- Routes requests to backend services
- Handles authentication via Keycloak
- Rate limiting and throttling
- Request/response transformation
- Load balancing

#### Keycloak (IAM)
- OpenID Connect / OAuth2 provider
- User authentication and authorization
- Token management
- Role-based access control (RBAC)
- Client credentials flow

#### RabbitMQ + MassTransit
- Message broker for async communication
- Publish/Subscribe pattern
- Event-driven architecture
- Guaranteed message delivery
- Dead letter queues

### Observability Stack

#### OpenTelemetry Collector
- **Purpose**: Unified telemetry collection
- **Receives**: Traces, Metrics, Logs via OTLP
- **Processes**: Batching, filtering, enrichment
- **Exports**: To Tempo, Prometheus, Loki

#### Prometheus
- **Purpose**: Metrics storage and querying
- **Collects**:
  - HTTP request metrics (rate, duration, errors)
  - Runtime metrics (CPU, memory, GC)
  - Database metrics (query performance)
  - Custom business metrics
- **Retention**: Configurable (default 15 days)

#### Loki
- **Purpose**: Log aggregation
- **Features**:
  - Structured logging
  - Label-based indexing
  - Log correlation with traces
  - Efficient storage
- **Retention**: Configurable (default 7 days)

#### Tempo
- **Purpose**: Distributed tracing
- **Features**:
  - Trace storage and querying
  - Service dependency graphs
  - Trace-to-metrics correlation
  - Trace-to-logs correlation

#### Grafana
- **Purpose**: Unified observability platform
- **Features**:
  - Dashboards for metrics
  - Log exploration
  - Trace visualization
  - Correlation between signals
  - Alerting

## Data Flow

### Order Creation Flow

```
1. Client → API Gateway → Orders API
2. Orders API → Validates order
3. Orders API → Saves to SQL Server
4. Orders API → Publishes OrderCreated event to RabbitMQ
5. RabbitMQ → Routes event to:
   - Audit API (stores event)
   - Inventory Worker (reserves stock)
   - Notifications API (sends confirmation)
6. Each service emits telemetry to OpenTelemetry Collector
7. Collector exports to Tempo, Prometheus, Loki
8. Grafana visualizes the entire flow
```

### Observability Data Flow

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

## Database Schema

### Orders Database (SQL Server)

```sql
Orders
- Id (PK)
- OrderNumber
- CustomerId
- CreatedAt
- ConfirmedAt
- CancelledAt
- ShippedAt
- Status
- TotalAmount
- CancellationReason
- TrackingNumber

OrderItems
- Id (PK)
- OrderId (FK)
- ProductId
- ProductName
- Quantity
- UnitPrice
```

### Inventory Database (PostgreSQL)

```sql
products
- id (PK)
- sku (unique)
- name
- description
- quantity
- reserved_quantity
- low_stock_threshold
- price
- created_at
- updated_at

reservations
- id (PK)
- product_id (FK)
- order_id
- quantity
- reserved_at
- released_at
- status
```

### Audit Database (PostgreSQL + Marten)

```sql
events schema:
- mt_events (event store)
- mt_streams (event streams)

documents schema:
- mt_doc_auditdocument (audit documents)
```

### Notifications (Redis)

```
Keys:
- notification:{id} → JSON document
- user:{userId}:notifications → List of notification IDs
```

## Event Contracts

### Order Events
- `OrderCreated` - When a new order is created
- `OrderConfirmed` - When an order is confirmed
- `OrderCancelled` - When an order is cancelled
- `OrderShipped` - When an order is shipped

### Inventory Events
- `InventoryAdjusted` - When stock quantity changes
- `InventoryReserved` - When stock is reserved for an order
- `InventoryReleased` - When reserved stock is released
- `LowStockAlert` - When stock falls below threshold

### Notification Events
- `NotificationRequested` - Request to send a notification
- `NotificationSent` - Confirmation that notification was sent

## Security

### Authentication Flow

```
1. Client → Requests token from Keycloak
2. Keycloak → Returns JWT access token
3. Client → Sends request with Bearer token to API Gateway
4. API Gateway → Validates token with Keycloak
5. API Gateway → Routes to backend service
6. Backend Service → Validates token (optional)
7. Backend Service → Processes request
```

### Authorization

- **Scopes**: Each API has read/write scopes
  - `orders.read`, `orders.write`
  - `inventory.read`, `inventory.write`
  - `notifications.read`, `notifications.write`
  - `audit.read`, `audit.write`

- **Policies**: Defined in each API
  - Require specific scopes for endpoints
  - Role-based access control

## Scalability Considerations

### Horizontal Scaling
- All microservices are stateless
- Can scale independently based on load
- Load balancing via API Gateway or Kubernetes

### Database Scaling
- Read replicas for read-heavy workloads
- Sharding for large datasets
- Connection pooling

### Message Queue Scaling
- RabbitMQ clustering
- Multiple consumers per queue
- Partitioned queues for high throughput

### Observability Scaling
- OpenTelemetry Collector can be scaled horizontally
- Prometheus federation for large deployments
- Loki distributed mode for high log volume
- Tempo distributed mode for high trace volume

## Resilience Patterns

### Implemented
- Health checks (liveness, readiness)
- Graceful shutdown
- Database connection retry
- Message queue retry with exponential backoff

### Recommended for Production
- Circuit breaker (Polly)
- Bulkhead isolation
- Timeout policies
- Rate limiting
- Saga pattern for distributed transactions

## Monitoring and Alerting

### Key Metrics to Monitor

**Application Metrics**
- Request rate (requests/second)
- Request duration (p50, p95, p99)
- Error rate (%)
- Active requests

**Infrastructure Metrics**
- CPU usage (%)
- Memory usage (%)
- Disk I/O
- Network I/O

**Business Metrics**
- Orders created per hour
- Inventory adjustments
- Low stock alerts
- Notification delivery rate

### Recommended Alerts

- High error rate (> 5%)
- High latency (p95 > 1s)
- Low stock alerts
- Database connection failures
- Message queue backlog
- Service unavailability

## Deployment

### Local Development
- Docker Compose for all services
- Hot reload for code changes
- Local databases and message queues

### Kubernetes (Production)
- Helm charts for each service
- ConfigMaps for configuration
- Secrets for sensitive data
- Horizontal Pod Autoscaling
- Ingress for external access
- Service mesh (optional: Istio, Linkerd)

## Future Enhancements

1. **API Gateway Enhancements**
   - Rate limiting per client
   - Request caching
   - API versioning

2. **Additional Services**
   - Payment service
   - Shipping service
   - Customer service

3. **Advanced Observability**
   - Custom Grafana dashboards
   - Automated alerting
   - SLO/SLI tracking
   - Error tracking (Sentry)

4. **Performance**
   - Redis caching layer
   - CQRS with read models
   - Event sourcing for all aggregates

5. **Security**
   - mTLS between services
   - API key management
   - Secrets rotation
   - Vulnerability scanning

## References

- [OpenTelemetry Documentation](https://opentelemetry.io/docs/)
- [Prometheus Best Practices](https://prometheus.io/docs/practices/)
- [Grafana Documentation](https://grafana.com/docs/)
- [MassTransit Documentation](https://masstransit.io/)
- [Marten Documentation](https://martendb.io/)


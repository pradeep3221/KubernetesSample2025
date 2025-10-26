# .NET Microservices on Kubernetes with Full Observability

A comprehensive sample microservices architecture built with .NET 9, demonstrating modern cloud-native patterns with complete observability using OpenTelemetry, Prometheus, Grafana, Loki, and Tempo.

## 🏗️ Architecture Overview

### Microservices
- **Orders API** - Manages customer orders using SQL Server + EF Core
- **Inventory API** - Manages product stock using PostgreSQL + Dapper
- **Notifications API** - Handles notifications using Redis
- **Audit API** - Event sourcing and audit trails using Marten (PostgreSQL)

### Infrastructure Components
- **Ocelot API Gateway** - Routes requests with Keycloak authentication
- **Keycloak** - Identity and Access Management (OpenID Connect/OAuth2)
- **RabbitMQ + MassTransit** - Event-driven async messaging
- **Kubernetes + Helm** - Container orchestration

### Observability Stack
- **OpenTelemetry Collector** - Unified telemetry collection
- **Prometheus** - Metrics storage and querying
- **Grafana** - Visualization and dashboards
- **Loki** - Log aggregation
- **Tempo** - Distributed tracing

## 📊 Key Features

✅ **Polyglot Persistence** - SQL Server, PostgreSQL, Redis, Marten  
✅ **Event Sourcing** - Complete audit trail with Marten  
✅ **CQRS Pattern** - Command/Query separation  
✅ **Event-Driven Architecture** - RabbitMQ + MassTransit  
✅ **Full Observability** - Traces, Metrics, Logs (OpenTelemetry)  
✅ **API Gateway Pattern** - Ocelot with authentication  
✅ **Service Mesh Ready** - Health checks, retries, circuit breakers  
✅ **Cloud-Native** - Kubernetes deployment with Helm  
✅ **Local Development** - Docker Compose for easy setup  

## 🚀 Quick Start

### Prerequisites
- Docker Desktop with Kubernetes enabled
- .NET 9 SDK
- kubectl
- Helm 3
- (Optional) Visual Studio 2022 or VS Code

### Local Development with Docker Compose

1. **Clone the repository**
```bash
git clone <repository-url>
cd kubernetes Samples
```

2. **Make the PostgreSQL init script executable (Linux/Mac)**
```bash
chmod +x infra/postgres/init-multiple-databases.sh
```

3. **Start all services**
```bash
docker-compose up -d
```

4. **Wait for services to be healthy**
```bash
docker-compose ps
```

5. **Access the services**

| Service | URL | Credentials |
|---------|-----|-------------|
| Grafana | http://localhost:3000 | admin/admin |
| Prometheus | http://localhost:9090 | - |
| Keycloak | http://localhost:8080 | admin/admin |
| RabbitMQ Management | http://localhost:15672 | guest/guest |
| Orders API | http://localhost:5001 | - |
| Inventory API | http://localhost:5002 | - |
| Notifications API | http://localhost:5003 | - |
| Audit API | http://localhost:5004 | - |

### Observability Dashboards

**Grafana** (http://localhost:3000)
- Pre-configured datasources for Prometheus, Loki, and Tempo
- Explore traces, metrics, and logs in one place
- Correlation between traces and logs

**Prometheus** (http://localhost:9090)
- Query metrics from all microservices
- View service health and performance

**Tempo** (via Grafana)
- Distributed tracing across all services
- Trace visualization and analysis

## 📁 Project Structure

```
kubernetes Samples/
├── src/
│   ├── Services/
│   │   ├── Orders.API/              # Orders microservice
│   │   ├── Inventory.API/           # Inventory microservice
│   │   ├── Notifications.API/       # Notifications microservice
│   │   └── Audit.API/               # Audit & Event Store
│   ├── Gateway/
│   │   └── Ocelot.Gateway/          # API Gateway
│   ├── Workers/
│   │   └── Inventory.Worker/        # Background worker
│   ├── Console/
│   │   └── Notifications.Console/   # Console app
│   └── Shared/
│       ├── Shared.Contracts/        # Event contracts
│       └── Shared.Observability/    # OpenTelemetry + Serilog
├── frontend/
│   ├── customer-spa/                # Angular SPA
│   └── admin-pwa/                   # Angular PWA
├── charts/                          # Helm charts
│   ├── orders-api/
│   ├── inventory-api/
│   ├── notifications-api/
│   ├── audit-api/
│   └── api-gateway/
├── infra/
│   ├── observability/               # Observability configs
│   │   ├── otel-collector-config.yaml
│   │   ├── prometheus.yml
│   │   ├── loki-config.yaml
│   │   ├── tempo-config.yaml
│   │   ├── grafana-datasources.yaml
│   │   └── grafana-dashboards.yaml
│   └── postgres/
│       └── init-multiple-databases.sh
├── docs/                            # Documentation
│   ├── QUICKSTART.md
│   ├── ARCHITECTURE.md
│   ├── LOGGING.md
│   ├── PROJECT_SUMMARY.md
│   ├── CHANGELOG.md
│   └── prompts/
├── docker-compose.yml
└── README.md
```

## 🔍 Observability Features

### Distributed Tracing
- **Automatic instrumentation** for ASP.NET Core, HttpClient, EF Core, SQL Client
- **Custom spans** for business operations
- **Trace context propagation** across services via RabbitMQ
- **Service dependency mapping** in Grafana

### Metrics
- **Application metrics**: Request rate, duration, error rate
- **Runtime metrics**: CPU, memory, GC, thread pool
- **Custom business metrics**: Orders created, inventory adjustments
- **Database metrics**: Query performance, connection pool

### Logging (Serilog)
- **Structured logging** with Serilog across all .NET projects
- **Multiple sinks**: Console and Grafana Loki
- **Request logging**: Automatic HTTP request/response logging
- **Rich enrichers**: Service name, version, environment, machine name, thread ID
- **Log correlation** with OpenTelemetry trace IDs and span IDs
- **Centralized logs** in Grafana Loki
- **JSON formatting** for easy parsing and querying
- **Consistent configuration** via Shared.Observability library
- 📖 **See [LOGGING.md](LOGGING.md) for detailed documentation**

### Health Checks
- **Liveness probes** - Is the service running?
- **Readiness probes** - Can the service handle requests?
- **Dependency checks** - Database, Redis, RabbitMQ connectivity

## 🎯 API Endpoints

### Orders API (Port 5001)
```
GET    /api/orders                    # Get all orders
GET    /api/orders/{id}               # Get order by ID
POST   /api/orders                    # Create new order
POST   /api/orders/{id}/confirm       # Confirm order
POST   /api/orders/{id}/cancel        # Cancel order
POST   /api/orders/{id}/ship          # Ship order
GET    /health                        # Health check
GET    /metrics                       # Prometheus metrics
```

### Inventory API (Port 5002)
```
GET    /api/inventory/products        # Get all products
GET    /api/inventory/products/{id}   # Get product by ID
GET    /api/inventory/products/sku/{sku}  # Get by SKU
GET    /api/inventory/products/low-stock  # Low stock products
POST   /api/inventory/products        # Create product
PUT    /api/inventory/products/{id}   # Update product
POST   /api/inventory/products/{id}/adjust  # Adjust quantity
DELETE /api/inventory/products/{id}   # Delete product
```

### Notifications API (Port 5003)
```
GET    /api/notifications/user/{userId}  # Get user notifications
GET    /api/notifications/{id}           # Get notification
POST   /api/notifications                # Send notification
POST   /api/notifications/{id}/mark-read # Mark as read
```

### Audit API (Port 5004)
```
GET    /api/audit/events              # Get all events
GET    /api/audit/events/{streamId}   # Get events by stream
GET    /api/audit/documents           # Get all documents
GET    /api/audit/documents/{entity}  # Get documents by entity
POST   /api/audit/replay/{streamId}   # Replay events
```

## 🔐 Authentication & Authorization

All APIs are protected with Keycloak JWT Bearer authentication.

### Setup Keycloak (First Time)

1. Access Keycloak admin console: http://localhost:8080
2. Login with `admin/admin`
3. Create a new realm: `microservices`
4. Create clients for each API:
   - `orders-api`
   - `inventory-api`
   - `notifications-api`
   - `audit-api`
5. Create scopes:
   - `orders.read`, `orders.write`
   - `inventory.read`, `inventory.write`
   - `notifications.read`, `notifications.write`
   - `audit.read`, `audit.write`

## 📈 Monitoring Best Practices

### Viewing Traces
1. Open Grafana (http://localhost:3000)
2. Go to Explore → Select Tempo datasource
3. Search for traces by service name, operation, or trace ID
4. Click on a trace to see the full span timeline
5. Jump to logs for specific spans

### Querying Metrics
1. Open Grafana → Explore → Select Prometheus
2. Example queries:
```promql
# Request rate per service
rate(http_server_requests_total[5m])

# 95th percentile latency
histogram_quantile(0.95, rate(http_server_request_duration_seconds_bucket[5m]))

# Error rate
rate(http_server_requests_total{status=~"5.."}[5m])
```

### Searching Logs
1. Open Grafana → Explore → Select Loki
2. Example queries:
```logql
# All logs from orders-api
{service="orders-api"}

# Error logs across all services
{service=~".+"} |= "error" | json

# Logs for a specific trace
{service="orders-api"} | json | trace_id="abc123"
```

## 🛠️ Development

### Build Services Locally
```bash
dotnet build src/Services/Orders.API/Orders.API.csproj
dotnet build src/Services/Inventory.API/Inventory.API.csproj
dotnet build src/Services/Notifications.API/Notifications.API.csproj
dotnet build src/Services/Audit.API/Audit.API.csproj
```

### Run Individual Service
```bash
cd src/Services/Orders.API
dotnet run
```

### Database Migrations
```bash
# Orders API (SQL Server)
cd src/Services/Orders.API
dotnet ef migrations add InitialCreate
dotnet ef database update

# Inventory API (PostgreSQL)
cd src/Services/Inventory.API
dotnet ef migrations add InitialCreate
dotnet ef database update
```

## 🐳 Docker Commands

```bash
# Build all services
docker-compose build

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f orders-api

# Stop all services
docker-compose down

# Remove volumes (clean slate)
docker-compose down -v
```

## ☸️ Kubernetes Deployment

Coming soon: Helm charts for Kubernetes deployment

## 🧪 Testing

### Create a Test Order
```bash
curl -X POST http://localhost:5001/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "customerId": "123e4567-e89b-12d3-a456-426614174000",
    "items": [
      {
        "productId": "223e4567-e89b-12d3-a456-426614174000",
        "productName": "Test Product",
        "quantity": 2,
        "unitPrice": 29.99
      }
    ]
  }'
```

### View the Trace
1. Copy the order ID from the response
2. Open Grafana → Explore → Tempo
3. Search for traces containing the order ID
4. See the full distributed trace across services

## 📚 Technologies Used

- **.NET 9** - Latest .NET framework
- **ASP.NET Core** - Web API framework
- **Entity Framework Core** - ORM for SQL Server
- **Dapper** - Micro-ORM for PostgreSQL
- **Marten** - Event Store and Document DB
- **MassTransit** - Distributed application framework
- **RabbitMQ** - Message broker
- **Redis** - In-memory data store
- **Keycloak** - Identity and Access Management
- **OpenTelemetry** - Observability framework
- **Prometheus** - Metrics and monitoring
- **Grafana** - Visualization platform
- **Loki** - Log aggregation
- **Tempo** - Distributed tracing backend
- **Docker** - Containerization
- **Kubernetes** - Container orchestration
- **Helm** - Kubernetes package manager

## 📚 Documentation

Comprehensive documentation is available in the `docs/` folder:

- **[Quick Start Guide](docs/QUICKSTART.md)** - Step-by-step setup instructions
- **[Architecture Overview](docs/ARCHITECTURE.md)** - Detailed architecture and design decisions
- **[Project Summary](docs/PROJECT_SUMMARY.md)** - Complete feature list and capabilities
- **[Logging Guide](docs/LOGGING.md)** - Serilog implementation and best practices
- **[Serilog Implementation](docs/SERILOG_IMPLEMENTATION_SUMMARY.md)** - Logging implementation details
- **[Implementation Complete](docs/IMPLEMENTATION_COMPLETE.md)** - Full implementation checklist
- **[Changelog](docs/CHANGELOG.md)** - Version history and changes
- **[Original Prompts](docs/prompts/)** - Project requirements and specifications

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License.

## 🙏 Acknowledgments

This project demonstrates best practices for building production-ready microservices with complete observability.


# Quick Start Guide

This guide will help you get the complete microservices architecture up and running in minutes.

## Prerequisites

- **Docker Desktop** (with at least 8GB RAM allocated, 16GB recommended)
- **.NET 9 SDK** (optional, for local development outside Docker)
- **Node.js 18+** (optional, for running Angular frontends)
- **Git**

## Step 1: Clone and Setup

```bash
# Clone the repository
git clone <your-repo-url>
cd KubernetesSample2025

# On Linux/Mac: Make the PostgreSQL init script executable
chmod +x infra/postgres/init-multiple-databases.sh
```

## Step 2: Start All Services

```bash
# Start all services with Docker Compose
docker-compose up -d

# This will start 15 containers:
# ✅ 4 Microservices (Orders, Inventory, Notifications, Audit)
# ✅ 1 Background Worker (Inventory.Worker)
# ✅ 1 API Gateway (Ocelot)
# ✅ 3 Databases (SQL Server, PostgreSQL, Redis)
# ✅ 1 Message Broker (RabbitMQ)
# ✅ 1 Identity Provider (Keycloak)
# ✅ 4 Observability Tools (OpenTelemetry Collector, Prometheus, Loki, Tempo)
# ✅ 1 Visualization Platform (Grafana)

# Rebuild and restart all services
docker-compose up -d --build
```

## Step 3: Wait for Services to be Ready

```bash
# Check service status
docker-compose ps

# View logs for a specific service
docker-compose logs -f orders-api

# Wait until all services show as "healthy" or "running"
# This may take 2-3 minutes on first startup
```

## Step 4: Access the Services

### 🎯 API Gateway (Recommended Entry Point)

| Service | URL | Description |
|---------|-----|-------------|
| **API Gateway** | http://localhost:5000 | Unified entry point with Keycloak auth |

### 📊 Observability Dashboards

| Service | URL | Credentials |
|---------|-----|-------------|
| **Grafana** | http://localhost:3000 | admin / admin |
| **Prometheus** | http://localhost:9090 | - |
| **Keycloak** | http://localhost:8080 | admin / admin |
| **RabbitMQ Management** | http://localhost:15672 | guest / guest |

### 🔧 Microservices APIs (Direct Access)

| Service | URL | Swagger |
|---------|-----|---------|
| **Orders API** | http://localhost:5001 | http://localhost:5001/swagger |
| **Inventory API** | http://localhost:5002 | http://localhost:5002/swagger |
| **Notifications API** | http://localhost:5003 | http://localhost:5003/swagger |
| **Audit API** | http://localhost:5004 | http://localhost:5004/swagger |

### 🌐 Frontend Applications (Optional)

The project includes two Angular applications that can be run separately:

```bash
# Customer SPA (Public Client)
cd frontend/customer-spa
npm install
npm start
# Access at http://localhost:4200

# Admin PWA (Confidential Client with Offline Support)
cd frontend/admin-pwa
npm install
npm start
# Access at http://localhost:4201
```

## Step 5: Test the System

### Option A: Via API Gateway (Recommended)

```bash
# Create a Product via Gateway
curl -X POST http://localhost:5000/api/inventory/products \
  -H "Content-Type: application/json" \
  -d '{
    "sku": "PROD-001",
    "name": "Sample Product",
    "description": "A test product",
    "quantity": 100,
    "lowStockThreshold": 10,
    "price": 29.99
  }'

# Create an Order via Gateway
curl -X POST http://localhost:5000/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "customerId": "123e4567-e89b-12d3-a456-426614174000",
    "items": [
      {
        "productId": "223e4567-e89b-12d3-a456-426614174000",
        "productName": "Sample Product",
        "quantity": 2,
        "unitPrice": 29.99
      }
    ]
  }'
```

### Option B: Direct Service Access

```bash
# Create a Product (Direct to Inventory API)
curl -X POST http://localhost:5002/api/inventory/products \
  -H "Content-Type: application/json" \
  -d '{
    "sku": "PROD-001",
    "name": "Sample Product",
    "description": "A test product",
    "quantity": 100,
    "lowStockThreshold": 10,
    "price": 29.99
  }'

# Create an Order (Direct to Orders API)
curl -X POST http://localhost:5001/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "customerId": "123e4567-e89b-12d3-a456-426614174000",
    "items": [
      {
        "productId": "223e4567-e89b-12d3-a456-426614174000",
        "productName": "Sample Product",
        "quantity": 2,
        "unitPrice": 29.99
      }
    ]
  }'
```

### View the Results

1. **Check RabbitMQ Management UI** (http://localhost:15672)
   - Login with `guest/guest`
   - Navigate to **Queues** tab to see message flow
   - See events being published and consumed in real-time
   - Check **Exchanges** to see event routing

2. **Check Audit API Event Store** (http://localhost:5004/api/audit/events)
   - See all events captured in the Marten event store
   - View complete audit trail with event sourcing

3. **View Distributed Traces in Grafana**
   - Open http://localhost:3000
   - Go to **Explore** → Select **Tempo** datasource
   - Click "Search" to see recent traces
   - Click on a trace to see the distributed trace timeline
   - See service-to-service calls, database queries, and message queue operations

4. **View Metrics in Grafana**
   - Go to **Explore** → Select **Prometheus** datasource
   - Try these queries:
     ```promql
     # Request rate per service
     rate(http_server_requests_total[5m])

     # 95th percentile latency
     histogram_quantile(0.95, rate(http_server_request_duration_seconds_bucket[5m]))

     # Error rate
     rate(http_server_requests_total{status=~"5.."}[5m])
     ```

5. **View Structured Logs in Grafana**
   - Go to **Explore** → Select **Loki** datasource
   - Try these queries:
     ```logql
     # All logs from orders-api
     {service="orders-api"}

     # Error logs across all services
     {service=~".+"} |= "error" | json

     # Logs for a specific trace (replace with actual trace_id)
     {service="orders-api"} | json | trace_id="abc123"
     ```
   - See logs correlated with traces via OpenTelemetry

## Step 6: Explore Full Observability

### 🔍 View Service Dependencies & Distributed Traces

1. Open Grafana → **Explore** → Select **Tempo** datasource
2. Click **Search** to see recent traces
3. Click on any trace to see:
   - **Service-to-service calls** - How requests flow through the system
   - **Database queries** - SQL Server, PostgreSQL operations
   - **Message queue operations** - RabbitMQ publish/consume
   - **Timing information** - Latency breakdown per operation
   - **Error tracking** - Failed operations with stack traces

### 📊 Create Custom Dashboards

1. Open Grafana → **Dashboards** → **New Dashboard**
2. Add panels with these example queries:

**Request Rate Panel:**
```promql
rate(http_server_requests_total{service="orders-api"}[5m])
```

**Latency Panel:**
```promql
histogram_quantile(0.95, rate(http_server_request_duration_seconds_bucket[5m]))
```

**Error Rate Panel:**
```promql
rate(http_server_requests_total{status=~"5.."}[5m])
```

3. Save the dashboard for future use

### 🔗 Correlate Logs and Traces (Powerful Feature!)

1. In Grafana, view a trace in **Tempo**
2. Click on any span in the trace
3. Click **"Logs for this span"** button
4. See the exact logs for that operation with full context
5. This correlation is powered by OpenTelemetry trace IDs in Serilog logs

### 📈 Monitor Background Workers

The **Inventory.Worker** processes events asynchronously:

1. Create an order (triggers inventory reservation)
2. Check RabbitMQ to see the event consumed
3. View worker logs in Loki: `{service="inventory-worker"}`
4. See traces showing the complete flow from API → RabbitMQ → Worker

## Common Docker Commands

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f orders-api

# Multiple services
docker-compose logs -f orders-api inventory-api

# Last 100 lines
docker-compose logs --tail=100 orders-api

# Follow logs with timestamps
docker-compose logs -f -t orders-api
```

### Check Service Status
```bash
# View all running containers
docker-compose ps

# Check health status
docker-compose ps | grep healthy
```

### Restart Services
```bash
# Restart a specific service
docker-compose restart orders-api

# Restart all services
docker-compose restart
```

### Rebuild and Restart
```bash
# Rebuild and restart a specific service
docker-compose up -d --build orders-api

# Rebuild all services
docker-compose up -d --build
```

### Stop Services
```bash
# Stop all services (keeps containers)
docker-compose stop

# Stop specific service
docker-compose stop orders-api

# Stop and remove containers
docker-compose down
```

### Clean Everything
```bash
# Remove containers and networks (keeps volumes)
docker-compose down

# Remove everything including volumes (CAUTION: deletes all data!)
docker-compose down -v

# Remove everything and images
docker-compose down -v --rmi all
```

### Scale Services (if needed)
```bash
# Scale a service to multiple instances
docker-compose up -d --scale inventory-worker=3
```

## Troubleshooting

### ❌ Services Not Starting

**Symptoms:** Containers keep restarting or exit immediately

**Solutions:**
1. Check Docker Desktop has enough resources:
   - **Minimum:** 8GB RAM, 4 CPUs
   - **Recommended:** 16GB RAM, 6 CPUs
2. Check logs for specific service:
   ```bash
   docker-compose logs orders-api
   docker-compose logs sqlserver
   ```
3. Restart Docker Desktop
4. Clean and restart:
   ```bash
   docker-compose down -v
   docker-compose up -d
   ```

### 🗄️ Database Connection Errors

**Symptoms:** Services show "Cannot connect to database" errors

**Solutions:**
1. Wait 2-3 minutes - databases take time to initialize on first run
2. Check database health:
   ```bash
   docker-compose ps postgres
   docker-compose ps sqlserver
   docker-compose ps redis
   ```
3. Verify databases are healthy before services start:
   ```bash
   # Wait for healthy status
   docker-compose logs postgres | grep "ready to accept connections"
   docker-compose logs sqlserver | grep "SQL Server is now ready"
   ```
4. If still failing, restart databases:
   ```bash
   docker-compose restart postgres sqlserver redis
   ```

### 🔌 Port Conflicts

**Symptoms:** "Port already in use" or "bind: address already in use"

**Solutions:**
1. Check which process is using the port:
   ```bash
   # Windows
   netstat -ano | findstr :5001

   # Linux/Mac
   lsof -i :5001
   ```
2. Stop the conflicting process or modify ports in `docker-compose.yml`:
   ```yaml
   ports:
     - "5001:8080"  # Change 5001 to another available port (e.g., 5101)
   ```

### 🔐 Keycloak Not Ready

**Symptoms:** Services fail with "Unable to connect to Keycloak"

**Solutions:**
1. Keycloak takes 1-2 minutes to start on first run
2. Check Keycloak logs:
   ```bash
   docker-compose logs keycloak
   ```
3. Wait for this message: `Keycloak 23.0 started`
4. Verify Keycloak is accessible: http://localhost:8080
5. If stuck, restart Keycloak:
   ```bash
   docker-compose restart keycloak
   ```

### 📊 Grafana Shows No Data

**Symptoms:** Grafana dashboards are empty or show "No data"

**Solutions:**
1. Verify datasources are configured:
   - Go to Grafana → Configuration → Data Sources
   - Check Prometheus, Loki, and Tempo are listed
2. Generate some traffic:
   ```bash
   # Create test requests
   curl http://localhost:5001/api/orders
   curl http://localhost:5002/api/inventory/products
   ```
3. Wait 30 seconds for metrics to be scraped
4. Check OpenTelemetry Collector is running:
   ```bash
   docker-compose logs otel-collector
   ```

### 🐰 RabbitMQ Connection Issues

**Symptoms:** Services can't connect to RabbitMQ

**Solutions:**
1. Check RabbitMQ is healthy:
   ```bash
   docker-compose ps rabbitmq
   docker-compose logs rabbitmq
   ```
2. Verify RabbitMQ Management UI is accessible: http://localhost:15672
3. Restart RabbitMQ:
   ```bash
   docker-compose restart rabbitmq
   ```

### 🔧 Build Failures

**Symptoms:** `docker-compose up` fails to build images

**Solutions:**
1. Clean Docker build cache:
   ```bash
   docker-compose build --no-cache
   ```
2. Remove old images:
   ```bash
   docker system prune -a
   ```
3. Check .NET SDK version in Dockerfiles matches installed version
4. Ensure all NuGet packages are accessible

## Next Steps

### 1. 🔐 Configure Keycloak (Optional but Recommended)

```bash
# Access Keycloak Admin Console
# URL: http://localhost:8080
# Login: admin/admin
```

**Setup Steps:**
1. Create a new realm called `microservices`
2. Create clients for each API:
   - `orders-api`
   - `inventory-api`
   - `notifications-api`
   - `audit-api`
   - `api-gateway`
3. Create client scopes:
   - `orders.read`, `orders.write`
   - `inventory.read`, `inventory.write`
   - `notifications.read`, `notifications.write`
   - `audit.read`, `audit.write`
4. Create roles and assign to users
5. Create test users for authentication

### 2. 💻 Explore the Code

**Microservices:**
```bash
# Check out the microservices
src/Services/Orders.API/          # SQL Server + EF Core
src/Services/Inventory.API/       # PostgreSQL + Dapper
src/Services/Notifications.API/   # Redis
src/Services/Audit.API/           # Marten Event Store
```

**Shared Libraries:**
```bash
# OpenTelemetry + Serilog configuration
src/Shared/Shared.Observability/

# Event contracts for RabbitMQ
src/Shared/Shared.Contracts/
```

**Infrastructure:**
```bash
# API Gateway with Ocelot
src/Gateway/Ocelot.Gateway/

# Background worker
src/Workers/Inventory.Worker/

# Console app for testing
src/Console/Notifications.Console/
```

### 3. 🏗️ Build Locally (Outside Docker)

```bash
# Build entire solution
dotnet build KubernetesSample2025.sln

# Build specific service
dotnet build src/Services/Orders.API/Orders.API.csproj

# Run a service locally (requires infrastructure running in Docker)
cd src/Services/Orders.API
dotnet run
```

### 4. 🧪 Run Tests (When Implemented)

```bash
# Run all tests
dotnet test

# Run tests with coverage
dotnet test /p:CollectCoverage=true
```

### 5. 🌐 Run Frontend Applications

```bash
# Customer SPA (Angular)
cd frontend/customer-spa
npm install
npm start
# Access at http://localhost:4200

# Admin PWA (Angular with offline support)
cd frontend/admin-pwa
npm install
npm start
# Access at http://localhost:4201
```

### 6. ☸️ Deploy to Kubernetes

```bash
# Use Helm charts (coming soon)
cd charts/
helm install orders-api ./orders-api
helm install inventory-api ./inventory-api
helm install notifications-api ./notifications-api
helm install audit-api ./audit-api
helm install api-gateway ./api-gateway
```

### 7. 📚 Read Documentation

- **[Architecture Overview](ARCHITECTURE.md)** - Detailed architecture and design decisions
- **[Logging Guide](LOGGING.md)** - Serilog implementation and best practices
- **[Project Summary](PROJECT_SUMMARY.md)** - Complete feature list and capabilities
- **[Changelog](CHANGELOG.md)** - Version history and changes

## Architecture Highlights

### 🔄 Event-Driven Flow Example

When you create an order, here's what happens:

1. **Order Created**
   - Orders API receives HTTP POST request
   - Creates order in SQL Server database
   - Publishes `OrderCreated` event to RabbitMQ

2. **Event Distribution via RabbitMQ**
   - RabbitMQ routes event to multiple subscribers
   - Each subscriber processes independently

3. **Audit API**
   - Consumes `OrderCreated` event
   - Stores event in Marten event store (PostgreSQL)
   - Maintains complete audit trail

4. **Inventory Worker**
   - Consumes `OrderCreated` event
   - Reserves inventory in PostgreSQL
   - Publishes `InventoryReserved` event

5. **Notifications API**
   - Consumes `OrderCreated` event
   - Stores notification in Redis
   - Sends notification to customer

**All of this is traced end-to-end with OpenTelemetry!**

### 📊 Observability Flow

The complete observability pipeline:

1. **Application Layer**
   - Emits traces (distributed tracing)
   - Emits metrics (counters, histograms, gauges)
   - Emits structured logs (Serilog → JSON)

2. **OpenTelemetry Collector**
   - Receives telemetry via OTLP (gRPC/HTTP)
   - Processes and enriches data
   - Routes to appropriate backends

3. **Storage Backends**
   - **Tempo** → Stores distributed traces
   - **Prometheus** → Stores time-series metrics
   - **Loki** → Stores structured logs

4. **Grafana Visualization**
   - Unified interface for all telemetry
   - Correlates traces, metrics, and logs
   - Provides dashboards and alerting

**Key Feature:** Trace IDs are automatically injected into logs, allowing you to jump from a trace span directly to the related logs!

## Development Workflow Tips

### 🔧 Hybrid Development (Recommended)

Run infrastructure in Docker, develop services locally:

```bash
# Start only infrastructure
docker-compose up -d sqlserver postgres redis rabbitmq keycloak otel-collector prometheus loki tempo grafana

# Stop the service you want to develop
docker-compose stop orders-api

# Run the service locally with hot reload
cd src/Services/Orders.API
dotnet watch run

# The service will connect to infrastructure in Docker
# You get fast iteration with full observability!
```

### 🔍 Debugging with Observability

1. **Set correlation IDs** in your requests:
   ```bash
   curl -H "X-Correlation-ID: my-test-123" http://localhost:5001/api/orders
   ```

2. **Find the trace** in Grafana using the correlation ID

3. **Jump to logs** from the trace to see detailed execution

4. **Check metrics** to see performance impact

### 📝 Adding Custom Metrics

The `Shared.Observability` library makes it easy:

```csharp
// In your service
var meter = new Meter("Orders.API");
var orderCounter = meter.CreateCounter<long>("orders.created");

// Increment when order is created
orderCounter.Add(1, new KeyValuePair<string, object?>("customer_id", customerId));
```

### 🎯 Testing Event Flow

Use the **Notifications.Console** app to publish test events:

```bash
cd src/Console/Notifications.Console
dotnet run

# Follow prompts to publish events
# Watch them flow through RabbitMQ to consumers
# See traces in Grafana showing the complete flow
```

## Performance Tips

### 🚀 Docker Desktop Configuration

**Minimum Requirements:**
- **RAM:** 8GB
- **CPUs:** 4 cores
- **Disk:** 50GB

**Recommended for Best Performance:**
- **RAM:** 16GB (allocate 12GB to Docker)
- **CPUs:** 6-8 cores
- **Disk:** 100GB SSD
- **Swap:** 2GB

**Windows Users:**
- Use **WSL2 backend** for 2-3x better performance
- Store project files in WSL2 filesystem (not Windows filesystem)
- Enable **VirtIO** in Docker Desktop settings

**Mac Users:**
- Use **VirtioFS** file sharing (Docker Desktop → Settings → General)
- Enable **Use Rosetta for x86/amd64 emulation** on Apple Silicon

### ⚡ Performance Optimization

```bash
# Reduce log verbosity in production
# Edit docker-compose.yml environment variables:
- Logging__LogLevel__Default=Warning

# Disable unnecessary services during development
docker-compose up -d sqlserver postgres redis rabbitmq orders-api

# Use BuildKit for faster builds
export DOCKER_BUILDKIT=1
docker-compose build
```

### 🧹 Regular Maintenance

```bash
# Clean up unused Docker resources weekly
docker system prune -a --volumes

# Remove old images
docker image prune -a

# Check disk usage
docker system df
```

## Support & Resources

### 📖 Documentation

- **[README.md](../README.md)** - Project overview and quick start
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Detailed architecture documentation
- **[LOGGING.md](LOGGING.md)** - Logging implementation guide
- **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** - Complete feature list

### 🔍 Troubleshooting

1. **Check Docker Compose logs:**
   ```bash
   docker-compose logs -f
   ```

2. **Check service health in Grafana:**
   - Open http://localhost:3000
   - Go to Explore → Prometheus
   - Query: `up{job=~".+"}`

3. **Verify all containers are running:**
   ```bash
   docker-compose ps
   ```

4. **Check resource usage:**
   ```bash
   docker stats
   ```

### 🐛 Common Issues

- **Slow startup?** → Increase Docker Desktop RAM allocation
- **Services crashing?** → Check logs for specific error messages
- **No metrics in Grafana?** → Verify OpenTelemetry Collector is running
- **Database connection errors?** → Wait for databases to be fully initialized
- **Port conflicts?** → Change ports in docker-compose.yml

---

## 🎉 You're All Set!

You now have a complete, production-ready microservices architecture running locally with:

✅ **4 Microservices** with polyglot persistence
✅ **Event-driven architecture** with RabbitMQ
✅ **Full observability** with OpenTelemetry, Prometheus, Grafana, Loki, Tempo
✅ **API Gateway** with Keycloak authentication
✅ **Background workers** for async processing
✅ **Angular frontends** (Customer SPA + Admin PWA)

**Next:** Start creating orders, explore traces in Grafana, and see the magic of distributed tracing! 🚀

---

**Happy coding!** 💻✨



# Get token
curl -X POST http://localhost:8080/realms/microservices/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&client_id=orders-api&username=admin&password=Admin@123"

# Via API Gateway (Recommended)
curl http://localhost:5000/api/orders/health
curl http://localhost:5000/api/inventory/health
curl http://localhost:5000/api/notifications/health
curl http://localhost:5000/api/audit/health

# Direct API Access
curl http://localhost:5001/health  # Orders
curl http://localhost:5002/health  # Inventory
curl http://localhost:5003/health  # Notifications
curl http://localhost:5004/health  # Audit


# Access frontends
Customer SPA: http://localhost:4200
Admin PWA: http://localhost:4201
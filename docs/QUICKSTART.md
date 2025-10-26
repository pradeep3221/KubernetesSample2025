# Quick Start Guide

This guide will help you get the microservices architecture up and running in minutes.

## Prerequisites

- **Docker Desktop** (with at least 8GB RAM allocated)
- **.NET 9 SDK** (optional, for local development)
- **Git**

## Step 1: Clone and Setup

```bash
# Clone the repository
git clone <your-repo-url>
cd kubernetes Samples

# On Linux/Mac: Make the PostgreSQL init script executable
chmod +x infra/postgres/init-multiple-databases.sh
```

## Step 2: Start All Services

```bash
# Start all services with Docker Compose
docker-compose up -d

# This will start:
# - 4 Microservices (Orders, Inventory, Notifications, Audit)
# - SQL Server, PostgreSQL, Redis
# - RabbitMQ
# - Keycloak
# - OpenTelemetry Collector
# - Prometheus, Loki, Tempo
# - Grafana
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

### Observability Dashboards

| Service | URL | Credentials |
|---------|-----|-------------|
| **Grafana** | http://localhost:3000 | admin / admin |
| **Prometheus** | http://localhost:9090 | - |
| **Keycloak** | http://localhost:8080 | admin / admin |
| **RabbitMQ** | http://localhost:15672 | guest / guest |

### Microservices APIs

| Service | URL | Swagger |
|---------|-----|---------|
| **Orders API** | http://localhost:5001 | http://localhost:5001/swagger |
| **Inventory API** | http://localhost:5002 | http://localhost:5002/swagger |
| **Notifications API** | http://localhost:5003 | http://localhost:5003/swagger |
| **Audit API** | http://localhost:5004 | http://localhost:5004/swagger |

## Step 5: Test the System

### Create a Product (Inventory)

```bash
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
```

### Create an Order

```bash
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

1. **Check RabbitMQ** (http://localhost:15672)
   - See the events being published and consumed
   - Navigate to "Queues" to see message flow

2. **Check Audit API** (http://localhost:5004/api/audit/events)
   - See all events captured in the event store

3. **View Traces in Grafana**
   - Open http://localhost:3000
   - Go to **Explore** → Select **Tempo** datasource
   - Click "Search" to see recent traces
   - Click on a trace to see the distributed trace timeline

4. **View Metrics in Grafana**
   - Go to **Explore** → Select **Prometheus** datasource
   - Try this query: `rate(http_server_requests_total[5m])`
   - See request rates across all services

5. **View Logs in Grafana**
   - Go to **Explore** → Select **Loki** datasource
   - Try this query: `{service="orders-api"}`
   - See structured logs with trace correlation

## Step 6: Explore Observability

### View Service Dependencies

1. Open Grafana → Explore → Tempo
2. Search for any trace
3. Click on the trace to see:
   - Service-to-service calls
   - Database queries
   - Message queue operations
   - Timing information

### Create a Dashboard

1. Open Grafana → Dashboards → New Dashboard
2. Add a panel with this query:
```promql
rate(http_server_requests_total{service="orders-api"}[5m])
```
3. Save the dashboard

### Correlate Logs and Traces

1. In Grafana, view a trace in Tempo
2. Click on any span
3. Click "Logs for this span"
4. See the exact logs for that operation

## Common Commands

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f orders-api

# Last 100 lines
docker-compose logs --tail=100 orders-api
```

### Restart a Service
```bash
docker-compose restart orders-api
```

### Rebuild and Restart
```bash
docker-compose up -d --build orders-api
```

### Stop All Services
```bash
docker-compose down
```

### Clean Everything (including volumes)
```bash
docker-compose down -v
```

## Troubleshooting

### Services Not Starting

1. Check Docker Desktop has enough resources (8GB RAM minimum)
2. Check logs: `docker-compose logs`
3. Restart Docker Desktop

### Database Connection Errors

Wait a bit longer - databases take time to initialize on first run.

```bash
# Check database health
docker-compose ps postgres
docker-compose ps sqlserver
```

### Port Conflicts

If ports are already in use, you can modify them in `docker-compose.yml`:

```yaml
ports:
  - "5001:8080"  # Change 5001 to another port
```

### Keycloak Not Ready

Keycloak takes 1-2 minutes to start. Check:
```bash
docker-compose logs keycloak
```

## Next Steps

1. **Configure Keycloak**
   - Create a realm called `microservices`
   - Create clients for each API
   - Set up scopes and roles

2. **Explore the Code**
   - Check out the microservices in `src/Services/`
   - See how OpenTelemetry is configured in `src/Shared/Shared.Observability/`
   - Review event contracts in `src/Shared/Shared.Contracts/`

3. **Build Locally**
   ```bash
   dotnet build kubernetes Samples.sln
   ```

4. **Run Tests** (when implemented)
   ```bash
   dotnet test
   ```

5. **Deploy to Kubernetes** (coming soon)
   - Use the Helm charts in `charts/` directory

## Architecture Highlights

### Event Flow Example

1. **Order Created** → Orders API publishes `OrderCreated` event
2. **RabbitMQ** → Routes event to subscribers
3. **Audit API** → Consumes event and stores in Marten event store
4. **Inventory Worker** → Consumes event and reserves inventory
5. **Notifications API** → Sends notification to customer

### Observability Flow

1. **Application** → Emits traces, metrics, logs
2. **OpenTelemetry Collector** → Receives and processes telemetry
3. **Tempo** → Stores traces
4. **Prometheus** → Stores metrics
5. **Loki** → Stores logs
6. **Grafana** → Visualizes everything with correlation

## Support

For issues or questions:
- Check the main [README.md](README.md)
- Review Docker Compose logs
- Check Grafana for service health metrics

## Performance Tips

- Allocate at least 8GB RAM to Docker Desktop
- Use SSD for Docker volumes
- On Windows, use WSL2 backend for better performance
- Close unnecessary applications to free up resources

Enjoy exploring the microservices architecture! 🚀


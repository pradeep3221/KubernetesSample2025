# Setup Guide

> **Complete Installation and Deployment Instructions**

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Docker Compose Setup](#docker-compose-setup)
4. [Seed Data](#seed-data)
5. [Service Endpoints](#service-endpoints)
6. [Kubernetes Deployment](#kubernetes-deployment)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### System Requirements

- **Docker Desktop** (8GB+ RAM, 16GB recommended)
- **.NET 9 SDK** (optional, for local development)
- **Node.js 18+** (optional, for Angular frontends)
- **Git**
- **PowerShell** (for scripts)

### Ports Required

| Port | Service |
|------|---------|
| 4200 | Customer SPA |
| 4201 | Admin PWA |
| 3000 | Grafana |
| 3100 | Loki |
| 3200 | Tempo |
| 5000 | API Gateway |
| 5001 | Orders API |
| 5002 | Inventory API |
| 5003 | Notifications API |
| 5004 | Audit API |
| 5432 | PostgreSQL |
| 5672 | RabbitMQ |
| 8080 | Keycloak |
| 9090 | Prometheus |
| 15672 | RabbitMQ Management |

---

## Quick Start

### Step 1: Clone Repository

```bash
git clone <your-repo-url>
cd KubernetesSample2025

# On Linux/Mac: Make PostgreSQL init script executable
chmod +x infra/postgres/init-multiple-databases.sh
```

### Step 2: Start All Services

```bash
# Start all services with Docker Compose
docker-compose up -d

# This starts 19 containers:
# ✅ 4 Microservices (Orders, Inventory, Notifications, Audit)
# ✅ 1 API Gateway (Ocelot)
# ✅ 3 Databases (SQL Server, PostgreSQL, Redis)
# ✅ 1 Message Broker (RabbitMQ)
# ✅ 1 Identity Provider (Keycloak)
# ✅ 2 Angular Frontends (Customer SPA, Admin PWA)
# ✅ 5 Observability Tools (OTel, Prometheus, Loki, Tempo, Grafana)
```

### Step 3: Wait for Services

```bash
# Check service status
docker-compose ps

# View logs for a specific service
docker-compose logs -f orders-api

# Wait until all services show as "healthy" or "running"
# This may take 2-3 minutes on first startup
```

### Step 4: Access Services

| Service | URL | Credentials |
|---------|-----|-------------|
| **Grafana** | http://localhost:3000 | admin/admin |
| **Keycloak** | http://localhost:8080 | admin/admin |
| **API Gateway** | http://localhost:5000 | - |
| **RabbitMQ** | http://localhost:15672 | guest/guest |
| **Prometheus** | http://localhost:9090 | - |

---

## Docker Compose Setup

### Configuration Files

**docker-compose.yml** - Main orchestration file

**Key Services:**

```yaml
# Microservices
orders-api:
  build: src/Services/Orders.API
  ports: ["5001:8080"]
  depends_on: [sql-server, rabbitmq, keycloak]

inventory-api:
  build: src/Services/Inventory.API
  ports: ["5002:8080"]
  depends_on: [postgres, rabbitmq, keycloak]

notifications-api:
  build: src/Services/Notifications.API
  ports: ["5003:8080"]
  depends_on: [redis, rabbitmq, keycloak]

audit-api:
  build: src/Services/Audit.API
  ports: ["5004:8080"]
  depends_on: [postgres, rabbitmq, keycloak]

# API Gateway
api-gateway:
  build: src/Gateway/Ocelot.Gateway
  ports: ["5000:8080"]
  depends_on: [orders-api, inventory-api, notifications-api, audit-api, keycloak]

# Databases
sql-server:
  image: mcr.microsoft.com/mssql/server:2022-latest
  ports: ["1433:1433"]
  environment:
    SA_PASSWORD: "YourPassword123!"

postgres:
  image: postgres:16-alpine
  ports: ["5432:5432"]
  environment:
    POSTGRES_PASSWORD: postgres

redis:
  image: redis:7-alpine
  ports: ["6379:6379"]

# Message Broker
rabbitmq:
  image: rabbitmq:3.13-management-alpine
  ports: ["5672:5672", "15672:15672"]

# Identity Provider
keycloak:
  image: keycloak/keycloak:23.0
  ports: ["8080:8080"]
  environment:
    KEYCLOAK_ADMIN: admin
    KEYCLOAK_ADMIN_PASSWORD: admin

# Observability
prometheus:
  image: prom/prometheus:latest
  ports: ["9090:9090"]

grafana:
  image: grafana/grafana:latest
  ports: ["3000:3000"]

loki:
  image: grafana/loki:latest
  ports: ["3100:3100"]

tempo:
  image: grafana/tempo:latest
  ports: ["3200:3200"]

otel-collector:
  image: otel/opentelemetry-collector:latest
  ports: ["4317:4317", "4318:4318"]
```

### Common Commands

```bash
# Start all services
docker-compose up -d

# Rebuild and start
docker-compose up -d --build

# Stop all services
docker-compose stop

# Stop and remove containers
docker-compose down

# Remove volumes (WARNING: deletes data)
docker-compose down -v

# View logs
docker-compose logs -f

# View logs for specific service
docker-compose logs -f orders-api

# View last 100 lines
docker-compose logs --tail=100 orders-api

# Restart a service
docker-compose restart orders-api

# Scale a service
docker-compose up -d --scale orders-api=3
```

---

## Seed Data

### Automatic Seeding

Seed data is automatically created on first startup:

**Inventory API** - 8 products seeded
- Dell XPS 13 (LAPTOP-001) - $1,299.99
- Logitech MX Master 3S (MOUSE-001) - $99.99
- Mechanical Keyboard RGB (KEYBOARD-001) - $149.99
- LG UltraWide 34" (MONITOR-001) - $799.99
- Sony WH-1000XM5 (HEADPHONES-001) - $399.99
- Logitech C920 Pro (WEBCAM-001) - $79.99
- USB-C Docking Station (DOCK-001) - $129.99
- HDMI 2.1 Cable 6ft (CABLE-001) - $19.99

**Orders API** - 4 sample orders seeded
- ORD-2025-001 (Confirmed) - $1,399.98
- ORD-2025-002 (Shipped) - $949.98
- ORD-2025-003 (Pending) - $799.99
- ORD-2025-004 (Pending) - $129.99

### Idempotent Seeding

Seed functions check if data exists before seeding:

```csharp
if (await db.Products.AnyAsync())
{
    Log.Information("Inventory data already exists, skipping seed");
    return;
}
```

This means you can safely restart services without duplicate data.

---

## Service Endpoints

### API Gateway (Recommended)

```
Base URL: http://localhost:5000
Authentication: Keycloak JWT Bearer token
```

### Direct Service Access

| Service | URL | Swagger |
|---------|-----|---------|
| Orders API | http://localhost:5001 | http://localhost:5001/swagger |
| Inventory API | http://localhost:5002 | http://localhost:5002/swagger |
| Notifications API | http://localhost:5003 | http://localhost:5003/swagger |
| Audit API | http://localhost:5004 | http://localhost:5004/swagger |

### Frontend Applications

```bash
# Customer SPA (Docker)
http://localhost:4200

# Admin PWA (Docker)
http://localhost:4201

# Or run locally
cd frontend/customer-spa
npm install
npm start
# Access at http://localhost:4200
```

---

## Kubernetes Deployment

### Prerequisites

- Kubernetes cluster (1.24+)
- Helm 3+
- kubectl configured

### Install Infrastructure

```bash
# Add Helm repositories
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install databases
helm install postgresql bitnami/postgresql
helm install rabbitmq bitnami/rabbitmq
helm install keycloak bitnami/keycloak

# Install observability
helm install prometheus prometheus-community/prometheus
helm install grafana grafana/grafana
helm install loki grafana/loki-stack
helm install tempo grafana/tempo
```

### Deploy Microservices

```bash
# Install microservices
helm install orders-api ./charts/orders-api
helm install inventory-api ./charts/inventory-api
helm install notifications-api ./charts/notifications-api
helm install audit-api ./charts/audit-api
helm install api-gateway ./charts/api-gateway

# Check deployment status
kubectl get pods
kubectl get svc
```

### Verify Deployment

```bash
# Check pod status
kubectl get pods -w

# View logs
kubectl logs -f deployment/orders-api

# Port forward to access services
kubectl port-forward svc/api-gateway 5000:80
kubectl port-forward svc/grafana 3000:80
```

---

## Troubleshooting

### Services Not Starting

```bash
# Check Docker daemon
docker ps

# Check logs
docker-compose logs

# Rebuild images
docker-compose build --no-cache

# Restart services
docker-compose restart
```

### Port Already in Use

```bash
# Find process using port
lsof -i :5000

# Kill process
kill -9 <PID>

# Or change port in docker-compose.yml
```

### Database Connection Issues

```bash
# Check database is running
docker-compose ps postgres
docker-compose ps sql-server

# Check logs
docker-compose logs postgres
docker-compose logs sql-server

# Verify connection string
docker-compose exec orders-api env | grep CONNECTION
```

### Keycloak Not Ready

```bash
# Check Keycloak logs
docker-compose logs keycloak

# Wait for startup
docker-compose logs -f keycloak | grep "Keycloak.*started"

# Access admin console
http://localhost:8080/admin
```

---

**Setup is complete and ready for development!** 🚀


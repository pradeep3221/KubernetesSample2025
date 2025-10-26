# Kubernetes Deployment Guide

Complete guide for deploying the microservices architecture to Kubernetes using Helm.

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Architecture Overview](#architecture-overview)
- [Deployment Steps](#deployment-steps)
- [Configuration](#configuration)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Tools

- **Kubernetes Cluster** (1.24+)
  - Local: Minikube, Kind, Docker Desktop
  - Cloud: AKS, EKS, GKE
- **Helm** 3.8+
- **kubectl** configured for your cluster
- **Container Registry** access (Docker Hub, ACR, ECR, GCR)

### Cluster Requirements

**Minimum:**
- 3 nodes
- 8 vCPUs total
- 16 GB RAM total
- 100 GB storage

**Recommended:**
- 5+ nodes
- 16 vCPUs total
- 32 GB RAM total
- 200 GB SSD storage

### Install Required Tools

```bash
# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify installation
helm version
kubectl version --client

# Add required Helm repositories
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
```

## Architecture Overview

### Components

```
┌─────────────────────────────────────────────────────────────┐
│                        Ingress (NGINX)                       │
│                     api.example.com                          │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                      API Gateway (Ocelot)                    │
│                    + Keycloak Auth                           │
└─────┬──────────┬──────────┬──────────┬─────────────────────┘
      │          │          │          │
      ▼          ▼          ▼          ▼
┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
│ Orders   │ │Inventory │ │Notifica- │ │  Audit   │
│   API    │ │   API    │ │tions API │ │   API    │
└────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘
     │            │            │            │
     ▼            ▼            ▼            ▼
┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
│   SQL    │ │PostgreSQL│ │  Redis   │ │PostgreSQL│
│  Server  │ │          │ │          │ │ (Marten) │
└──────────┘ └──────────┘ └──────────┘ └──────────┘
     │            │            │            │
     └────────────┴────────────┴────────────┘
                  │
                  ▼
          ┌──────────────┐
          │   RabbitMQ   │
          └──────┬───────┘
                 │
                 ▼
          ┌──────────────┐
          │  Inventory   │
          │   Worker     │
          └──────────────┘

┌─────────────────────────────────────────────────────────────┐
│              Observability Stack                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │OpenTelem-│→ │Prometheus│  │   Loki   │  │  Tempo   │   │
│  │  etry    │  │          │  │          │  │          │   │
│  └──────────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘   │
│                     └──────────────┴─────────────┘          │
│                              │                               │
│                              ▼                               │
│                        ┌──────────┐                         │
│                        │ Grafana  │                         │
│                        └──────────┘                         │
└─────────────────────────────────────────────────────────────┘
```

## Deployment Steps

### Step 1: Create Namespace

```bash
# Create dedicated namespace
kubectl create namespace microservices

# Set as default namespace (optional)
kubectl config set-context --current --namespace=microservices
```

### Step 2: Build and Push Images

```bash
# Set your container registry
export REGISTRY="your-registry.azurecr.io"
# Or for Docker Hub: export REGISTRY="yourusername"

# Navigate to project root
cd ..

# Build all images
docker build -t $REGISTRY/orders-api:1.0.0 -f src/Services/Orders.API/Dockerfile .
docker build -t $REGISTRY/inventory-api:1.0.0 -f src/Services/Inventory.API/Dockerfile .
docker build -t $REGISTRY/notifications-api:1.0.0 -f src/Services/Notifications.API/Dockerfile .
docker build -t $REGISTRY/audit-api:1.0.0 -f src/Services/Audit.API/Dockerfile .
docker build -t $REGISTRY/api-gateway:1.0.0 -f src/Gateway/Ocelot.Gateway/Dockerfile .
docker build -t $REGISTRY/inventory-worker:1.0.0 -f src/Workers/Inventory.Worker/Dockerfile .

# Push to registry
docker push $REGISTRY/orders-api:1.0.0
docker push $REGISTRY/inventory-api:1.0.0
docker push $REGISTRY/notifications-api:1.0.0
docker push $REGISTRY/audit-api:1.0.0
docker push $REGISTRY/api-gateway:1.0.0
docker push $REGISTRY/inventory-worker:1.0.0

# Return to charts directory
cd charts
```

### Step 3: Install Infrastructure

```bash
# Install PostgreSQL (for Inventory, Audit, and Keycloak)
helm install postgresql bitnami/postgresql \
  --namespace microservices \
  --set auth.username=postgres \
  --set auth.password=postgres \
  --set auth.database=inventory_db \
  --set primary.persistence.size=10Gi

# Create additional databases
kubectl exec -it postgresql-0 -n microservices -- \
  psql -U postgres -c "CREATE DATABASE audit_db;"
kubectl exec -it postgresql-0 -n microservices -- \
  psql -U postgres -c "CREATE DATABASE keycloak;"

# Install SQL Server (for Orders)
helm install sqlserver bitnami/mssql \
  --namespace microservices \
  --set auth.saPassword="YourStrong@Passw0rd" \
  --set auth.enableSqlAuth=true \
  --set persistence.size=10Gi

# Install Redis (for Notifications)
helm install redis bitnami/redis \
  --namespace microservices \
  --set auth.enabled=false \
  --set master.persistence.size=5Gi

# Install RabbitMQ (Message Broker)
helm install rabbitmq bitnami/rabbitmq \
  --namespace microservices \
  --set auth.username=guest \
  --set auth.password=guest \
  --set persistence.size=5Gi \
  --set metrics.enabled=true

# Install Keycloak (Identity Provider)
helm install keycloak bitnami/keycloak \
  --namespace microservices \
  --set auth.adminUser=admin \
  --set auth.adminPassword=admin \
  --set postgresql.enabled=false \
  --set externalDatabase.host=postgresql \
  --set externalDatabase.database=keycloak \
  --set externalDatabase.user=postgres \
  --set externalDatabase.password=postgres

# Wait for all infrastructure to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=postgresql --timeout=300s -n microservices
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=redis --timeout=300s -n microservices
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=rabbitmq --timeout=300s -n microservices
```

### Step 4: Install Observability Stack

```bash
# Install Prometheus + Grafana
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace microservices \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.retention=7d \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=20Gi

# Install Loki
helm install loki grafana/loki-stack \
  --namespace microservices \
  --set loki.persistence.enabled=true \
  --set loki.persistence.size=10Gi

# Install Tempo
helm install tempo grafana/tempo \
  --namespace microservices \
  --set tempo.persistence.enabled=true \
  --set tempo.persistence.size=10Gi

# Install OpenTelemetry Collector
helm install opentelemetry-collector open-telemetry/opentelemetry-collector \
  --namespace microservices \
  --set mode=deployment
```

### Step 5: Generate Missing Charts (if needed)

```bash
# Make script executable
chmod +x generate-charts.sh

# Run the script
./generate-charts.sh

# Review generated charts
ls -la
```

### Step 6: Install Microservices

```bash
# Install Orders API
helm install orders-api ./orders-api \
  --namespace microservices \
  --set image.repository=$REGISTRY/orders-api \
  --set image.tag=1.0.0

# Install Inventory API
helm install inventory-api ./inventory-api \
  --namespace microservices \
  --set image.repository=$REGISTRY/inventory-api \
  --set image.tag=1.0.0

# Install Notifications API
helm install notifications-api ./notifications-api \
  --namespace microservices \
  --set image.repository=$REGISTRY/notifications-api \
  --set image.tag=1.0.0

# Install Audit API
helm install audit-api ./audit-api \
  --namespace microservices \
  --set image.repository=$REGISTRY/audit-api \
  --set image.tag=1.0.0

# Install Inventory Worker
helm install inventory-worker ./inventory-worker \
  --namespace microservices \
  --set image.repository=$REGISTRY/inventory-worker \
  --set image.tag=1.0.0

# Install API Gateway
helm install api-gateway ./api-gateway \
  --namespace microservices \
  --set image.repository=$REGISTRY/api-gateway \
  --set image.tag=1.0.0
```

### Step 7: Verify Deployment

```bash
# Check all pods are running
kubectl get pods -n microservices

# Check services
kubectl get svc -n microservices

# Check Helm releases
helm list -n microservices

# View logs
kubectl logs -n microservices -l app.kubernetes.io/name=orders-api --tail=50
```

## Configuration

### Access Services Locally

```bash
# API Gateway
kubectl port-forward -n microservices svc/api-gateway 5000:80

# Grafana
kubectl port-forward -n microservices svc/prometheus-grafana 3000:80

# Prometheus
kubectl port-forward -n microservices svc/prometheus-kube-prometheus-prometheus 9090:9090

# RabbitMQ Management
kubectl port-forward -n microservices svc/rabbitmq 15672:15672

# Keycloak
kubectl port-forward -n microservices svc/keycloak 8080:80
```

### Get Grafana Password

```bash
kubectl get secret --namespace microservices prometheus-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

## Monitoring

### View Metrics in Grafana

1. Port forward Grafana: `kubectl port-forward -n microservices svc/prometheus-grafana 3000:80`
2. Open http://localhost:3000
3. Login with `admin` / `<password from above>`
4. Navigate to **Explore** → **Prometheus**
5. Try queries like: `rate(http_server_requests_total[5m])`

### View Logs in Loki

1. In Grafana, navigate to **Explore** → **Loki**
2. Try queries like: `{namespace="microservices", app="orders-api"}`

### View Traces in Tempo

1. In Grafana, navigate to **Explore** → **Tempo**
2. Search for traces by service name or trace ID

## Troubleshooting

See the main [README.md](README.md) for comprehensive troubleshooting guide.

### Quick Checks

```bash
# Check pod status
kubectl get pods -n microservices

# Describe problematic pod
kubectl describe pod <pod-name> -n microservices

# View logs
kubectl logs <pod-name> -n microservices

# Check events
kubectl get events -n microservices --sort-by='.lastTimestamp'
```

## Next Steps

1. **Configure Ingress** - Expose API Gateway externally
2. **Set up SSL/TLS** - Use cert-manager for automatic certificates
3. **Configure Secrets** - Use External Secrets Operator
4. **Set up CI/CD** - Automate deployments
5. **Configure Alerts** - Set up Prometheus alerts
6. **Implement Backups** - Database backup strategies
7. **Load Testing** - Verify autoscaling works

---

For more information, see the main [README.md](README.md) in this directory.


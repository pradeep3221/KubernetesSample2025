# Helm Charts for Microservices

This directory contains Helm charts for deploying the complete microservices architecture to Kubernetes.

## 📦 Available Charts

### Microservices
- **orders-api** - Orders microservice (SQL Server + EF Core)
- **inventory-api** - Inventory microservice (PostgreSQL + Dapper)
- **notifications-api** - Notifications microservice (Redis)
- **audit-api** - Audit & Event Store microservice (Marten + PostgreSQL)

### Gateway & Workers
- **api-gateway** - Ocelot API Gateway with Keycloak authentication
- **inventory-worker** - Background worker for async inventory processing

## Prerequisites

- **Kubernetes** 1.24+ (tested with 1.28+)
- **Helm** 3.8+
- **kubectl** configured to access your cluster
- **Container Registry** (Docker Hub, ACR, ECR, GCR, etc.) for storing images

## 🚀 Quick Start

### Step 1: Build and Push Docker Images

Before deploying to Kubernetes, build and push your images to a container registry:

```bash
# Set your container registry (replace with your registry)
export REGISTRY=your-registry.azurecr.io
# Or for Docker Hub: export REGISTRY=yourusername

# Build all images
docker build -t $REGISTRY/orders-api:1.0.0 -f src/Services/Orders.API/Dockerfile .
docker build -t $REGISTRY/inventory-api:1.0.0 -f src/Services/Inventory.API/Dockerfile .
docker build -t $REGISTRY/notifications-api:1.0.0 -f src/Services/Notifications.API/Dockerfile .
docker build -t $REGISTRY/audit-api:1.0.0 -f src/Services/Audit.API/Dockerfile .
docker build -t $REGISTRY/api-gateway:1.0.0 -f src/Gateway/Ocelot.Gateway/Dockerfile .
docker build -t $REGISTRY/inventory-worker:1.0.0 -f src/Workers/Inventory.Worker/Dockerfile .

# Push all images
docker push $REGISTRY/orders-api:1.0.0
docker push $REGISTRY/inventory-api:1.0.0
docker push $REGISTRY/notifications-api:1.0.0
docker push $REGISTRY/audit-api:1.0.0
docker push $REGISTRY/api-gateway:1.0.0
docker push $REGISTRY/inventory-worker:1.0.0
```

### Step 2: Install Infrastructure Dependencies

```bash
# Add required Helm repositories
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update

# Create namespace for microservices
kubectl create namespace microservices

# Install PostgreSQL (for Inventory and Audit services)
helm install postgresql bitnami/postgresql \
  --namespace microservices \
  --set auth.username=postgres \
  --set auth.password=postgres \
  --set auth.database=inventory_db \
  --set primary.initdb.scripts."init-multiple-databases\.sh"="#!/bin/bash
set -e
set -u

function create_database() {
    local database=\$1
    echo \"Creating database '\$database'\"
    psql -v ON_ERROR_STOP=1 --username \"\$POSTGRES_USER\" <<-EOSQL
        CREATE DATABASE \$database;
        GRANT ALL PRIVILEGES ON DATABASE \$database TO \$POSTGRES_USER;
EOSQL
}

create_database \"inventory_db\"
create_database \"audit_db\"
create_database \"keycloak\""

# Install SQL Server (for Orders service)
helm install sqlserver bitnami/mssql \
  --namespace microservices \
  --set auth.saPassword=YourStrong@Passw0rd \
  --set auth.enableSqlAuth=true

# Install Redis (for Notifications service)
helm install redis bitnami/redis \
  --namespace microservices \
  --set auth.enabled=false

# Install RabbitMQ (Message Broker)
helm install rabbitmq bitnami/rabbitmq \
  --namespace microservices \
  --set auth.username=guest \
  --set auth.password=guest \
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
```

### Step 3: Install Observability Stack

```bash
# Install Prometheus (Metrics)
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace microservices \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false

# Install Loki (Logs)
helm install loki grafana/loki-stack \
  --namespace microservices \
  --set loki.persistence.enabled=true \
  --set loki.persistence.size=10Gi

# Install Tempo (Traces)
helm install tempo grafana/tempo \
  --namespace microservices \
  --set tempo.persistence.enabled=true \
  --set tempo.persistence.size=10Gi

# Install OpenTelemetry Collector
helm install opentelemetry-collector open-telemetry/opentelemetry-collector \
  --namespace microservices \
  --set mode=deployment \
  --set config.exporters.otlp.endpoint=tempo:4317 \
  --set config.exporters.prometheus.endpoint=prometheus-server:9090

# Grafana is already installed with kube-prometheus-stack
# Get Grafana admin password:
kubectl get secret --namespace microservices prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode
```

### Step 4: Install Microservices

```bash
# Set your container registry
export REGISTRY=your-registry.azurecr.io

# Install Orders API
helm install orders-api ./charts/orders-api \
  --namespace microservices \
  --set image.repository=$REGISTRY/orders-api \
  --set image.tag=1.0.0

# Install Inventory API
helm install inventory-api ./charts/inventory-api \
  --namespace microservices \
  --set image.repository=$REGISTRY/inventory-api \
  --set image.tag=1.0.0

# Install Notifications API
helm install notifications-api ./charts/notifications-api \
  --namespace microservices \
  --set image.repository=$REGISTRY/notifications-api \
  --set image.tag=1.0.0

# Install Audit API
helm install audit-api ./charts/audit-api \
  --namespace microservices \
  --set image.repository=$REGISTRY/audit-api \
  --set image.tag=1.0.0

# Install Inventory Worker
helm install inventory-worker ./charts/inventory-worker \
  --namespace microservices \
  --set image.repository=$REGISTRY/inventory-worker \
  --set image.tag=1.0.0

# Install API Gateway
helm install api-gateway ./charts/api-gateway \
  --namespace microservices \
  --set image.repository=$REGISTRY/api-gateway \
  --set image.tag=1.0.0
```

### Step 5: Verify Deployment

```bash
# Check all pods are running
kubectl get pods -n microservices

# Check services
kubectl get svc -n microservices

# Check ingress (if enabled)
kubectl get ingress -n microservices

# View logs
kubectl logs -n microservices -l app.kubernetes.io/name=orders-api --tail=100

# Port forward to access services locally
kubectl port-forward -n microservices svc/api-gateway 5000:80
kubectl port-forward -n microservices svc/prometheus-grafana 3000:80
```

## ⚙️ Configuration

Each chart can be customized using values.yaml or by passing values via command line:

```bash
# Example: Customize Orders API deployment
helm install orders-api ./charts/orders-api \
  --namespace microservices \
  --set replicaCount=3 \
  --set image.tag=2.0.0 \
  --set resources.limits.memory=1Gi \
  --set autoscaling.maxReplicas=20 \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=orders.example.com
```

### Common Configuration Options

| Parameter | Description | Default | Notes |
|-----------|-------------|---------|-------|
| `replicaCount` | Number of replicas | `2` | Ignored if autoscaling enabled |
| `image.repository` | Image repository | Service name | Must include registry |
| `image.tag` | Image tag | `1.0.0` | Use semantic versioning |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` | Use `Always` for `latest` tag |
| `service.type` | Service type | `ClusterIP` | Use `LoadBalancer` for external access |
| `service.port` | Service port | `80` | External port |
| `service.targetPort` | Container port | `8080` | Must match ASPNETCORE_URLS |
| `autoscaling.enabled` | Enable HPA | `true` | Requires metrics-server |
| `autoscaling.minReplicas` | Minimum replicas | `2` | For high availability |
| `autoscaling.maxReplicas` | Maximum replicas | `10` | Adjust based on load |
| `resources.limits.cpu` | CPU limit | `500m` | Adjust based on profiling |
| `resources.limits.memory` | Memory limit | `512Mi` | Adjust based on profiling |
| `resources.requests.cpu` | CPU request | `250m` | Guaranteed CPU |
| `resources.requests.memory` | Memory request | `256Mi` | Guaranteed memory |
| `ingress.enabled` | Enable ingress | `false` | Requires ingress controller |
| `ingress.className` | Ingress class | `nginx` | nginx, traefik, etc. |

## 🔐 Secrets Management

### Development/Testing (Not for Production!)

The charts include default secrets in `values.yaml` for quick testing. **Never use these in production!**

### Production: External Secrets

For production deployments, use Kubernetes secrets or external secret managers:

#### Option 1: Kubernetes Secrets

```bash
# Create namespace secret for database connections
kubectl create secret generic orders-db-secret \
  --namespace microservices \
  --from-literal=connection-string='Server=sqlserver;Database=orders_db;User Id=sa;Password=YourStrong@Passw0rd;TrustServerCertificate=True;'

kubectl create secret generic inventory-db-secret \
  --namespace microservices \
  --from-literal=connection-string='Host=postgresql;Database=inventory_db;Username=postgres;Password=postgres'

kubectl create secret generic rabbitmq-secret \
  --namespace microservices \
  --from-literal=host=rabbitmq \
  --from-literal=user=guest \
  --from-literal=password=guest

kubectl create secret generic keycloak-secret \
  --namespace microservices \
  --from-literal=authority='http://keycloak:8080/realms/microservices'
```

Then update your Helm values to reference these secrets:

```yaml
secrets:
  connectionStrings:
    ordersDb:
      existingSecret: orders-db-secret
      key: connection-string
  rabbitmq:
    existingSecret: rabbitmq-secret
    hostKey: host
    userKey: user
    passwordKey: password
```

#### Option 2: Sealed Secrets

```bash
# Install Sealed Secrets controller
helm install sealed-secrets sealed-secrets/sealed-secrets \
  --namespace kube-system

# Create a sealed secret
kubectl create secret generic orders-db-secret \
  --namespace microservices \
  --from-literal=connection-string='Server=...' \
  --dry-run=client -o yaml | \
  kubeseal -o yaml > sealed-orders-db-secret.yaml

# Apply the sealed secret
kubectl apply -f sealed-orders-db-secret.yaml
```

#### Option 3: External Secret Operator (Recommended for Production)

```bash
# Install External Secrets Operator
helm install external-secrets external-secrets/external-secrets \
  --namespace external-secrets-system \
  --create-namespace

# Configure SecretStore (example for Azure Key Vault)
kubectl apply -f - <<EOF
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: azure-keyvault
  namespace: microservices
spec:
  provider:
    azurekv:
      authType: ManagedIdentity
      vaultUrl: "https://your-keyvault.vault.azure.net"
EOF

# Create ExternalSecret
kubectl apply -f - <<EOF
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: orders-db-secret
  namespace: microservices
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: azure-keyvault
    kind: SecretStore
  target:
    name: orders-db-secret
  data:
  - secretKey: connection-string
    remoteRef:
      key: orders-db-connection-string
EOF
```

## 📊 Monitoring & Observability

All services are configured with full observability:
- **Prometheus metrics** endpoint at `/metrics`
- **Health checks** at `/health` (liveness and readiness)
- **OpenTelemetry instrumentation** for distributed tracing
- **Structured logging** with Serilog to Loki
- **Trace correlation** between logs and traces

### Access Grafana

```bash
# Get Grafana admin password
kubectl get secret --namespace microservices prometheus-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

# Port forward to access Grafana
kubectl port-forward --namespace microservices svc/prometheus-grafana 3000:80

# Open http://localhost:3000
# Login with admin / <password from above>
```

### Pre-configured Datasources

Grafana comes pre-configured with:
- **Prometheus** - Metrics from all services
- **Loki** - Centralized logs
- **Tempo** - Distributed traces

### Example Queries

**Prometheus (Metrics):**
```promql
# Request rate per service
rate(http_server_requests_total{namespace="microservices"}[5m])

# 95th percentile latency
histogram_quantile(0.95, rate(http_server_request_duration_seconds_bucket[5m]))

# Error rate
rate(http_server_requests_total{status=~"5..",namespace="microservices"}[5m])
```

**Loki (Logs):**
```logql
# All logs from orders-api
{namespace="microservices", app="orders-api"}

# Error logs across all services
{namespace="microservices"} |= "error" | json

# Logs for a specific trace
{namespace="microservices"} | json | trace_id="abc123"
```

**Tempo (Traces):**
- Search by service name, operation, or trace ID
- Click on spans to see correlated logs
- View service dependency graph

## 🌐 Ingress Configuration

### Install NGINX Ingress Controller

```bash
# Install NGINX Ingress Controller
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.metrics.enabled=true \
  --set controller.podAnnotations."prometheus\.io/scrape"=true \
  --set controller.podAnnotations."prometheus\.io/port"=10254
```

### Enable Ingress for API Gateway

The recommended approach is to expose only the API Gateway externally:

```yaml
# values-production.yaml for api-gateway
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/rate-limit: "100"
  hosts:
    - host: api.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: api-gateway-tls
      hosts:
        - api.example.com
```

Deploy with custom values:

```bash
helm upgrade api-gateway ./charts/api-gateway \
  --namespace microservices \
  --values values-production.yaml
```

### SSL/TLS with cert-manager

```bash
# Install cert-manager
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true

# Create ClusterIssuer for Let's Encrypt
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

## 🔄 Upgrading Services

### Rolling Update (Zero Downtime)

```bash
# Update to new version
helm upgrade orders-api ./charts/orders-api \
  --namespace microservices \
  --set image.tag=2.0.0 \
  --wait \
  --timeout 5m

# Watch the rollout
kubectl rollout status deployment/orders-api -n microservices

# Check rollout history
helm history orders-api -n microservices
```

### Rollback if Needed

```bash
# Rollback to previous version
helm rollback orders-api -n microservices

# Rollback to specific revision
helm rollback orders-api 3 -n microservices

# Check status
kubectl get pods -n microservices -l app.kubernetes.io/name=orders-api
```

### Blue-Green Deployment

```bash
# Deploy new version with different release name
helm install orders-api-v2 ./charts/orders-api \
  --namespace microservices \
  --set image.tag=2.0.0

# Test the new version
kubectl port-forward -n microservices svc/orders-api-v2 5001:80

# Switch traffic by updating API Gateway configuration
# Then uninstall old version
helm uninstall orders-api -n microservices
helm upgrade orders-api-v2 orders-api -n microservices
```

## 🗑️ Uninstalling

### Uninstall Microservices

```bash
# Uninstall all microservices
helm uninstall orders-api -n microservices
helm uninstall inventory-api -n microservices
helm uninstall notifications-api -n microservices
helm uninstall audit-api -n microservices
helm uninstall inventory-worker -n microservices
helm uninstall api-gateway -n microservices
```

### Uninstall Infrastructure

```bash
# Uninstall infrastructure (WARNING: This will delete data!)
helm uninstall postgresql -n microservices
helm uninstall sqlserver -n microservices
helm uninstall redis -n microservices
helm uninstall rabbitmq -n microservices
helm uninstall keycloak -n microservices
```

### Uninstall Observability Stack

```bash
# Uninstall observability tools
helm uninstall prometheus -n microservices
helm uninstall loki -n microservices
helm uninstall tempo -n microservices
helm uninstall opentelemetry-collector -n microservices
```

### Complete Cleanup

```bash
# Delete namespace (WARNING: This deletes everything!)
kubectl delete namespace microservices

# Delete PVCs if needed
kubectl delete pvc --all -n microservices
```

## 🔧 Troubleshooting

### Pod Issues

```bash
# Check pod status
kubectl get pods -n microservices
kubectl get pods -n microservices -w  # Watch mode

# Describe pod for events
kubectl describe pod <pod-name> -n microservices

# View logs
kubectl logs <pod-name> -n microservices
kubectl logs <pod-name> -n microservices --previous  # Previous container logs
kubectl logs <pod-name> -n microservices -f  # Follow logs

# Execute commands in pod
kubectl exec -it <pod-name> -n microservices -- /bin/sh
```

### Service & Networking Issues

```bash
# Check services
kubectl get svc -n microservices

# Check endpoints (should match number of pods)
kubectl get endpoints -n microservices

# Test service connectivity from another pod
kubectl run -it --rm debug --image=busybox --restart=Never -n microservices -- sh
# Inside the pod:
wget -O- http://orders-api/health
```

### Database Connection Issues

```bash
# Check if databases are running
kubectl get pods -n microservices | grep -E 'postgres|sqlserver|redis'

# Test database connectivity
kubectl run -it --rm psql --image=postgres:16-alpine --restart=Never -n microservices -- \
  psql -h postgresql -U postgres -d inventory_db

# Check database secrets
kubectl get secret -n microservices
kubectl describe secret orders-db-secret -n microservices
```

### HPA (Horizontal Pod Autoscaler) Issues

```bash
# Check HPA status
kubectl get hpa -n microservices
kubectl describe hpa orders-api -n microservices

# Check metrics server is installed
kubectl get deployment metrics-server -n kube-system

# View current metrics
kubectl top pods -n microservices
kubectl top nodes
```

### Helm Issues

```bash
# List all releases
helm list -n microservices

# Get release status
helm status orders-api -n microservices

# View release history
helm history orders-api -n microservices

# Render templates without installing (dry run)
helm template orders-api ./charts/orders-api

# Dry run with debug
helm install orders-api ./charts/orders-api \
  --namespace microservices \
  --dry-run --debug

# Validate chart
helm lint ./charts/orders-api
```

### Observability Issues

```bash
# Check if OpenTelemetry Collector is running
kubectl logs -n microservices -l app.kubernetes.io/name=opentelemetry-collector

# Check Prometheus targets
kubectl port-forward -n microservices svc/prometheus-server 9090:80
# Open http://localhost:9090/targets

# Check Loki is receiving logs
kubectl port-forward -n microservices svc/loki 3100:3100
# curl http://localhost:3100/ready

# Check Grafana datasources
kubectl port-forward -n microservices svc/prometheus-grafana 3000:80
# Open http://localhost:3000 → Configuration → Data Sources
```

### Common Issues & Solutions

| Issue | Symptom | Solution |
|-------|---------|----------|
| **ImagePullBackOff** | Pod can't pull image | Check image name, tag, and registry credentials |
| **CrashLoopBackOff** | Pod keeps restarting | Check logs with `kubectl logs` |
| **Pending** | Pod stuck in Pending | Check resource requests, node capacity, PVC binding |
| **0/1 Ready** | Pod running but not ready | Check readiness probe, application startup |
| **No metrics in Grafana** | Empty dashboards | Verify OpenTelemetry Collector, check service annotations |
| **Database connection failed** | App can't connect to DB | Check secrets, service names, network policies |
| **HPA not scaling** | Pods not autoscaling | Install metrics-server, check HPA configuration |

## 🏭 Production Considerations

### 1. Resource Planning

```bash
# Perform load testing to determine resource requirements
# Use tools like k6, JMeter, or Locust

# Monitor resource usage
kubectl top pods -n microservices
kubectl top nodes

# Adjust resource requests/limits based on actual usage
# Example: 80% of limit should be the target for requests
```

**Recommended Starting Points:**

| Service | CPU Request | CPU Limit | Memory Request | Memory Limit |
|---------|-------------|-----------|----------------|--------------|
| Orders API | 250m | 500m | 256Mi | 512Mi |
| Inventory API | 250m | 500m | 256Mi | 512Mi |
| Notifications API | 100m | 250m | 128Mi | 256Mi |
| Audit API | 250m | 500m | 256Mi | 512Mi |
| API Gateway | 250m | 500m | 256Mi | 512Mi |
| Inventory Worker | 100m | 250m | 128Mi | 256Mi |

### 2. High Availability

```yaml
# Configure pod anti-affinity to spread pods across nodes
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchExpressions:
          - key: app.kubernetes.io/name
            operator: In
            values:
            - orders-api
        topologyKey: kubernetes.io/hostname

# Set pod disruption budgets
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: orders-api-pdb
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: orders-api
```

### 3. Security Hardening

```yaml
# Enable Pod Security Standards
apiVersion: v1
kind: Namespace
metadata:
  name: microservices
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted

# Network Policies (example)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: orders-api-netpol
  namespace: microservices
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: orders-api
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app.kubernetes.io/name: api-gateway
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: sqlserver
    ports:
    - protocol: TCP
      port: 1433
  - to:
    - podSelector:
        matchLabels:
          app: rabbitmq
    ports:
    - protocol: TCP
      port: 5672
```

### 4. Database Persistence & Backup

```bash
# Use persistent volumes for databases
# Configure backup strategies

# Example: PostgreSQL backup with CronJob
apiVersion: batch/v1
kind: CronJob
metadata:
  name: postgres-backup
  namespace: microservices
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: postgres:16-alpine
            command:
            - /bin/sh
            - -c
            - |
              pg_dump -h postgresql -U postgres inventory_db | \
              gzip > /backup/inventory_db_$(date +%Y%m%d_%H%M%S).sql.gz
            volumeMounts:
            - name: backup
              mountPath: /backup
          volumes:
          - name: backup
            persistentVolumeClaim:
              claimName: postgres-backup-pvc
          restartPolicy: OnFailure
```

### 5. Monitoring & Alerting

```yaml
# Configure Prometheus alerts
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-alerts
  namespace: microservices
data:
  alerts.yml: |
    groups:
    - name: microservices
      rules:
      - alert: HighErrorRate
        expr: rate(http_server_requests_total{status=~"5.."}[5m]) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate detected"
          description: "{{ $labels.service }} has error rate above 5%"

      - alert: HighLatency
        expr: histogram_quantile(0.95, rate(http_server_request_duration_seconds_bucket[5m])) > 1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High latency detected"
          description: "{{ $labels.service }} 95th percentile latency is above 1s"

      - alert: PodCrashLooping
        expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Pod is crash looping"
          description: "Pod {{ $labels.pod }} is restarting frequently"
```

### 6. Secrets Management (Production)

- **Use External Secrets Operator** with Azure Key Vault, AWS Secrets Manager, or HashiCorp Vault
- **Rotate secrets regularly** (every 90 days minimum)
- **Use separate secrets** for each environment (dev, staging, prod)
- **Enable audit logging** for secret access
- **Never commit secrets** to version control

### 7. Multi-Region Deployment

```bash
# Deploy to multiple regions for disaster recovery
# Use global load balancer (Azure Front Door, AWS Global Accelerator, etc.)

# Example: Deploy to multiple clusters
helm install orders-api ./charts/orders-api \
  --kube-context us-east-cluster \
  --namespace microservices

helm install orders-api ./charts/orders-api \
  --kube-context eu-west-cluster \
  --namespace microservices
```

### 8. Cost Optimization

- **Use node autoscaling** (Cluster Autoscaler or Karpenter)
- **Right-size resources** based on actual usage
- **Use spot/preemptible instances** for non-critical workloads
- **Implement pod autoscaling** (HPA and VPA)
- **Monitor costs** with tools like Kubecost

## 📁 Chart Structure

Each chart follows the standard Helm structure:

```
charts/orders-api/
├── Chart.yaml              # Chart metadata (name, version, description)
├── values.yaml             # Default configuration values
├── README.md               # Chart-specific documentation (optional)
└── templates/
    ├── deployment.yaml     # Deployment manifest
    ├── service.yaml        # Service manifest
    ├── configmap.yaml      # ConfigMap for app settings
    ├── secret.yaml         # Secret for sensitive data
    ├── hpa.yaml            # HorizontalPodAutoscaler
    ├── serviceaccount.yaml # ServiceAccount
    ├── ingress.yaml        # Ingress (optional)
    ├── pdb.yaml            # PodDisruptionBudget (optional)
    ├── networkpolicy.yaml  # NetworkPolicy (optional)
    └── _helpers.tpl        # Template helpers
```

## 🔨 Creating Missing Charts

Currently, only the `orders-api` chart is fully implemented. To create the remaining charts:

### Quick Method: Copy and Modify

```bash
# Create Inventory API chart
cp -r charts/orders-api charts/inventory-api

# Update Chart.yaml
sed -i 's/orders-api/inventory-api/g' charts/inventory-api/Chart.yaml
sed -i 's/Orders API/Inventory API/g' charts/inventory-api/Chart.yaml

# Update values.yaml
# Change database connection string to PostgreSQL
# Update image repository name

# Update all template files
find charts/inventory-api/templates -type f -exec sed -i 's/orders-api/inventory-api/g' {} +
find charts/inventory-api/templates -type f -exec sed -i 's/ordersDb/inventoryDb/g' {} +
```

### Service-Specific Configurations

**Inventory API (PostgreSQL):**
```yaml
# values.yaml
secrets:
  connectionStrings:
    inventoryDb: "Host=postgresql;Database=inventory_db;Username=postgres;Password=postgres"
```

**Notifications API (Redis):**
```yaml
# values.yaml
secrets:
  redis:
    connectionString: "redis:6379"
# No database connection string needed
```

**Audit API (Marten + PostgreSQL):**
```yaml
# values.yaml
secrets:
  connectionStrings:
    auditDb: "Host=postgresql;Database=audit_db;Username=postgres;Password=postgres"
```

**API Gateway (Ocelot):**
```yaml
# values.yaml
service:
  type: LoadBalancer  # Or use Ingress
  port: 80
ingress:
  enabled: true  # Recommended for production
```

**Inventory Worker (Background Service):**
```yaml
# values.yaml
# No service needed (worker doesn't expose HTTP endpoints)
# Remove service.yaml and ingress.yaml from templates
# Keep deployment.yaml, configmap.yaml, secret.yaml

# deployment.yaml - remove ports and probes
# Use different health check strategy or remove probes
```

### Automated Chart Generation Script

Create a script to generate all charts:

```bash
#!/bin/bash
# generate-charts.sh

SERVICES=("inventory-api" "notifications-api" "audit-api" "api-gateway" "inventory-worker")

for service in "${SERVICES[@]}"; do
  echo "Creating chart for $service..."

  # Copy template
  cp -r charts/orders-api "charts/$service"

  # Update Chart.yaml
  sed -i "s/orders-api/$service/g" "charts/$service/Chart.yaml"

  # Update templates
  find "charts/$service/templates" -type f -exec sed -i "s/orders-api/$service/g" {} +

  echo "✅ Created charts/$service"
  echo "⚠️  Please manually update values.yaml for service-specific configuration"
done
```

## 📚 Additional Resources

### Official Documentation
- **[Helm Documentation](https://helm.sh/docs/)** - Complete Helm guide
- **[Kubernetes Documentation](https://kubernetes.io/docs/)** - Kubernetes concepts and API
- **[Helm Best Practices](https://helm.sh/docs/chart_best_practices/)** - Chart development guidelines

### Observability
- **[Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator)** - Kubernetes-native Prometheus
- **[Grafana Dashboards](https://grafana.com/grafana/dashboards/)** - Pre-built dashboards
- **[OpenTelemetry Docs](https://opentelemetry.io/docs/)** - Observability framework

### Security
- **[External Secrets Operator](https://external-secrets.io/)** - Kubernetes secrets from external sources
- **[Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)** - Encrypted secrets in Git
- **[cert-manager](https://cert-manager.io/)** - Automated TLS certificate management

### Tools
- **[Helm Diff Plugin](https://github.com/databus23/helm-diff)** - Preview changes before upgrade
- **[Helmfile](https://github.com/helmfile/helmfile)** - Declarative Helm chart management
- **[Kubecost](https://www.kubecost.com/)** - Kubernetes cost monitoring
- **[k9s](https://k9scli.io/)** - Terminal UI for Kubernetes

## 🎯 Next Steps

1. **Create remaining charts** using the copy method or script above
2. **Customize values.yaml** for each service based on their specific requirements
3. **Test locally** using Minikube or Kind before deploying to production
4. **Set up CI/CD pipeline** to automate chart deployment
5. **Configure monitoring alerts** in Prometheus/Grafana
6. **Implement backup strategies** for databases
7. **Enable ingress** and configure SSL/TLS certificates
8. **Review security policies** and implement network policies

## 📝 Contributing

When creating or modifying charts:

1. Follow [Helm best practices](https://helm.sh/docs/chart_best_practices/)
2. Use semantic versioning for chart versions
3. Document all values in values.yaml with comments
4. Test charts with `helm lint` and `helm template`
5. Include README.md for each chart
6. Keep secrets out of version control

---

**Happy Helming!** ⛵ 🚀


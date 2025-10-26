# Helm Charts for Microservices

This directory contains Helm charts for deploying the microservices architecture to Kubernetes.

## Available Charts

- **orders-api** - Orders microservice
- **inventory-api** - Inventory microservice (similar structure to orders-api)
- **notifications-api** - Notifications microservice (similar structure to orders-api)
- **audit-api** - Audit microservice (similar structure to orders-api)
- **api-gateway** - Ocelot API Gateway (similar structure to orders-api)

## Prerequisites

- Kubernetes 1.24+
- Helm 3.0+
- kubectl configured to access your cluster

## Quick Start

### 1. Install Infrastructure Dependencies

```bash
# Add Bitnami repository
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Install PostgreSQL
helm install postgresql bitnami/postgresql \
  --set auth.username=postgres \
  --set auth.password=postgres \
  --set auth.database=inventory_db

# Install SQL Server (using custom values)
helm install sqlserver \
  --set acceptEula.value=Y \
  --set edition.value=Developer \
  --set sapassword=YourStrong@Passw0rd \
  mcr.microsoft.com/mssql/server:2022-latest

# Install Redis
helm install redis bitnami/redis \
  --set auth.enabled=false

# Install RabbitMQ
helm install rabbitmq bitnami/rabbitmq \
  --set auth.username=guest \
  --set auth.password=guest

# Install Keycloak
helm install keycloak bitnami/keycloak \
  --set auth.adminUser=admin \
  --set auth.adminPassword=admin
```

### 2. Install Observability Stack

```bash
# Add Prometheus Community repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install Prometheus
helm install prometheus prometheus-community/prometheus

# Install Grafana
helm install grafana grafana/grafana \
  --set adminPassword=admin

# Install Loki
helm install loki grafana/loki-stack

# Install Tempo
helm install tempo grafana/tempo

# Install OpenTelemetry Collector
helm install opentelemetry-collector open-telemetry/opentelemetry-collector
```

### 3. Install Microservices

```bash
# Install Orders API
helm install orders-api ./charts/orders-api

# Install Inventory API
helm install inventory-api ./charts/inventory-api

# Install Notifications API
helm install notifications-api ./charts/notifications-api

# Install Audit API
helm install audit-api ./charts/audit-api

# Install API Gateway
helm install api-gateway ./charts/api-gateway
```

## Configuration

Each chart can be customized using values.yaml or by passing values via command line:

```bash
helm install orders-api ./charts/orders-api \
  --set replicaCount=3 \
  --set image.tag=2.0.0 \
  --set resources.limits.memory=1Gi
```

### Common Configuration Options

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `2` |
| `image.repository` | Image repository | Service name |
| `image.tag` | Image tag | `1.0.0` |
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `80` |
| `autoscaling.enabled` | Enable HPA | `true` |
| `autoscaling.minReplicas` | Minimum replicas | `2` |
| `autoscaling.maxReplicas` | Maximum replicas | `10` |
| `resources.limits.cpu` | CPU limit | `500m` |
| `resources.limits.memory` | Memory limit | `512Mi` |

## Secrets Management

For production deployments, use Kubernetes secrets or external secret managers:

```bash
# Create secrets from files
kubectl create secret generic orders-db-secret \
  --from-literal=connection-string='Server=sqlserver;...'

# Or use Sealed Secrets
kubectl apply -f sealed-secrets/orders-db-sealed-secret.yaml
```

Update values.yaml to reference external secrets:

```yaml
secrets:
  connectionStrings:
    ordersDb:
      existingSecret: orders-db-secret
      key: connection-string
```

## Monitoring

All services are configured with:
- Prometheus metrics endpoint at `/metrics`
- Health checks at `/health`
- OpenTelemetry instrumentation

### Access Grafana

```bash
# Get Grafana password
kubectl get secret grafana -o jsonpath="{.data.admin-password}" | base64 --decode

# Port forward to access Grafana
kubectl port-forward svc/grafana 3000:80

# Open http://localhost:3000
```

## Ingress

To expose services externally, enable ingress in values.yaml:

```yaml
ingress:
  enabled: true
  className: nginx
  hosts:
    - host: orders-api.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: orders-api-tls
      hosts:
        - orders-api.example.com
```

## Upgrading

```bash
# Upgrade a release
helm upgrade orders-api ./charts/orders-api \
  --set image.tag=2.0.0

# Rollback if needed
helm rollback orders-api 1
```

## Uninstalling

```bash
# Uninstall microservices
helm uninstall orders-api
helm uninstall inventory-api
helm uninstall notifications-api
helm uninstall audit-api
helm uninstall api-gateway

# Uninstall infrastructure
helm uninstall postgresql
helm uninstall redis
helm uninstall rabbitmq
helm uninstall keycloak

# Uninstall observability
helm uninstall prometheus
helm uninstall grafana
helm uninstall loki
helm uninstall tempo
helm uninstall opentelemetry-collector
```

## Troubleshooting

### Check pod status
```bash
kubectl get pods
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Check service endpoints
```bash
kubectl get svc
kubectl get endpoints
```

### Check HPA status
```bash
kubectl get hpa
kubectl describe hpa orders-api
```

### Debug configuration
```bash
# Render templates without installing
helm template orders-api ./charts/orders-api

# Dry run
helm install orders-api ./charts/orders-api --dry-run --debug
```

## Production Considerations

1. **Resource Limits**: Adjust CPU and memory limits based on load testing
2. **Replicas**: Set appropriate min/max replicas for autoscaling
3. **Secrets**: Use external secret management (Vault, AWS Secrets Manager, etc.)
4. **Persistence**: Configure persistent volumes for databases
5. **Backup**: Implement backup strategies for databases
6. **Monitoring**: Set up alerts in Prometheus/Grafana
7. **Security**: Enable network policies, pod security policies
8. **High Availability**: Deploy across multiple availability zones

## Chart Structure

Each chart follows the standard Helm structure:

```
charts/orders-api/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Default configuration values
└── templates/
    ├── deployment.yaml     # Deployment manifest
    ├── service.yaml        # Service manifest
    ├── configmap.yaml      # ConfigMap for app settings
    ├── secret.yaml         # Secret for sensitive data
    ├── hpa.yaml            # HorizontalPodAutoscaler
    ├── serviceaccount.yaml # ServiceAccount
    └── _helpers.tpl        # Template helpers
```

## Additional Resources

- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator)
- [Grafana Dashboards](https://grafana.com/grafana/dashboards/)


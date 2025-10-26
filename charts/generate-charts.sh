#!/bin/bash

# Script to generate Helm charts for all microservices
# Based on the orders-api template chart

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Services to create charts for
SERVICES=(
  "inventory-api:Inventory API microservice:inventoryDb:Host=postgresql;Database=inventory_db;Username=postgres;Password=postgres"
  "notifications-api:Notifications API microservice:redis:redis:6379"
  "audit-api:Audit API microservice:auditDb:Host=postgresql;Database=audit_db;Username=postgres;Password=postgres"
  "api-gateway:Ocelot API Gateway:none:none"
  "inventory-worker:Inventory background worker:inventoryDb:Host=postgresql;Database=inventory_db;Username=postgres;Password=postgres"
)

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Helm Chart Generator${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if orders-api chart exists
if [ ! -d "orders-api" ]; then
  echo -e "${RED}❌ Error: orders-api chart not found!${NC}"
  echo -e "${YELLOW}Please run this script from the charts/ directory${NC}"
  exit 1
fi

# Function to create a chart
create_chart() {
  local service_name=$1
  local description=$2
  local db_key=$3
  local connection_string=$4
  
  echo -e "${BLUE}📦 Creating chart for ${service_name}...${NC}"
  
  # Check if chart already exists
  if [ -d "$service_name" ]; then
    echo -e "${YELLOW}⚠️  Chart ${service_name} already exists. Skipping...${NC}"
    return
  fi
  
  # Copy template
  cp -r orders-api "$service_name"
  
  # Update Chart.yaml
  cat > "$service_name/Chart.yaml" <<EOF
apiVersion: v2
name: $service_name
description: A Helm chart for $description
type: application
version: 1.0.0
appVersion: "1.0.0"
EOF
  
  # Update _helpers.tpl
  sed -i.bak "s/orders-api/$service_name/g" "$service_name/templates/_helpers.tpl"
  rm "$service_name/templates/_helpers.tpl.bak" 2>/dev/null || true
  
  # Update all template files
  for file in "$service_name/templates"/*.yaml; do
    if [ -f "$file" ]; then
      sed -i.bak "s/orders-api/$service_name/g" "$file"
      rm "$file.bak" 2>/dev/null || true
    fi
  done
  
  # Update values.yaml based on service type
  if [ "$service_name" == "inventory-worker" ]; then
    # Worker doesn't need service or ingress
    rm -f "$service_name/templates/service.yaml"
    rm -f "$service_name/templates/ingress.yaml"
    
    # Update values.yaml for worker
    cat > "$service_name/values.yaml" <<EOF
replicaCount: 1

image:
  repository: inventory-worker
  pullPolicy: IfNotPresent
  tag: "1.0.0"

imagePullSecrets: []
nameOverride: ""
fullnameOverride: ""

serviceAccount:
  create: true
  annotations: {}
  name: ""

podAnnotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "8080"
  prometheus.io/path: "/metrics"

podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000

securityContext:
  capabilities:
    drop:
    - ALL
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false

resources:
  limits:
    cpu: 250m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi

autoscaling:
  enabled: false

nodeSelector: {}
tolerations: []
affinity: {}

env:
  - name: DOTNET_ENVIRONMENT
    value: "Production"

configMap:
  data:
    appsettings.Production.json: |
      {
        "Logging": {
          "LogLevel": {
            "Default": "Information",
            "Microsoft": "Warning"
          }
        },
        "OpenTelemetry": {
          "OtlpEndpoint": "http://otel-collector:4317"
        },
        "Loki": {
          "Endpoint": "http://loki:3100"
        },
        "Environment": "production"
      }

secrets:
  connectionStrings:
    $db_key: "$connection_string"
  rabbitmq:
    host: "rabbitmq"
    user: "guest"
    password: "guest"
EOF
  else
    # Update values.yaml for API services
    sed -i.bak "s/orders-api/$service_name/g" "$service_name/values.yaml"
    sed -i.bak "s/ordersDb/$db_key/g" "$service_name/values.yaml"
    
    if [ "$db_key" != "none" ]; then
      sed -i.bak "s|Server=sqlserver;Database=orders_db;User Id=sa;Password=YourStrong@Passw0rd;TrustServerCertificate=True;|$connection_string|g" "$service_name/values.yaml"
    fi
    
    rm "$service_name/values.yaml.bak" 2>/dev/null || true
  fi
  
  # Update deployment.yaml for worker (remove probes and service)
  if [ "$service_name" == "inventory-worker" ]; then
    # Remove liveness and readiness probes from deployment
    sed -i.bak '/livenessProbe:/,/failureThreshold:/d' "$service_name/templates/deployment.yaml"
    sed -i.bak '/readinessProbe:/,/failureThreshold:/d' "$service_name/templates/deployment.yaml"
    sed -i.bak '/ports:/,/protocol: TCP/d' "$service_name/templates/deployment.yaml"
    rm "$service_name/templates/deployment.yaml.bak" 2>/dev/null || true
  fi
  
  # Update deployment.yaml connection string references
  if [ "$db_key" != "none" ] && [ "$service_name" != "api-gateway" ]; then
    sed -i.bak "s/ordersDb/$db_key/g" "$service_name/templates/deployment.yaml"
    rm "$service_name/templates/deployment.yaml.bak" 2>/dev/null || true
  fi
  
  # Update secret.yaml
  if [ "$db_key" != "none" ]; then
    sed -i.bak "s/ordersDb/$db_key/g" "$service_name/templates/secret.yaml"
    rm "$service_name/templates/secret.yaml.bak" 2>/dev/null || true
  fi
  
  echo -e "${GREEN}✅ Created chart: $service_name${NC}"
}

# Create charts for all services
for service_info in "${SERVICES[@]}"; do
  IFS=':' read -r service_name description db_key connection_string <<< "$service_info"
  create_chart "$service_name" "$description" "$db_key" "$connection_string"
  echo ""
done

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Chart generation complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}⚠️  Next steps:${NC}"
echo -e "1. Review and customize values.yaml for each chart"
echo -e "2. Update connection strings and secrets"
echo -e "3. Test charts with: ${BLUE}helm lint <chart-name>${NC}"
echo -e "4. Dry run: ${BLUE}helm install <name> ./<chart-name> --dry-run --debug${NC}"
echo ""


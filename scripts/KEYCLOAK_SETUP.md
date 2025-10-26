# Keycloak Automated Setup Guide

This guide explains how to automatically configure Keycloak for the microservices architecture.

## Prerequisites

- Keycloak must be running (part of docker-compose stack)
- PowerShell (for Windows) or Bash (for Linux/Mac)
- `curl` command-line tool (for Bash script)

## Quick Start

### Windows (PowerShell)

```powershell
# Navigate to the project root
cd e:\DotNetWorld\2025Projects\KubernetesSample2025

# Run the setup script
.\scripts\setup-keycloak.ps1

# Or with custom parameters
.\scripts\setup-keycloak.ps1 -KeycloakUrl "http://localhost:8080" -AdminUser "admin" -AdminPassword "admin" -RealmName "microservices"
```

### Linux/Mac (Bash)

```bash
# Navigate to the project root
cd /path/to/KubernetesSample2025

# Make script executable
chmod +x scripts/setup-keycloak.sh

# Run the setup script
./scripts/setup-keycloak.sh

# Or with custom parameters
./scripts/setup-keycloak.sh http://localhost:8080 admin admin microservices
```

## What Gets Configured

### 1. **Realm: `microservices`**
   - Display Name: "Microservices Realm"
   - Access Token Lifespan: 1 hour
   - Refresh Token Lifespan: 24 hours
   - SSL Required: None (for development)

### 2. **Client Scopes** (8 scopes)
   - `orders.read` - Read orders
   - `orders.write` - Write orders
   - `inventory.read` - Read inventory
   - `inventory.write` - Write inventory
   - `notifications.read` - Read notifications
   - `notifications.write` - Write notifications
   - `audit.read` - Read audit logs
   - `audit.write` - Write audit logs

### 3. **Clients** (5 clients)

#### Orders API
- **Client ID**: `orders-api`
- **Scopes**: `orders.read`, `orders.write`
- **Audience**: `orders-api`

#### Inventory API
- **Client ID**: `inventory-api`
- **Scopes**: `inventory.read`, `inventory.write`
- **Audience**: `inventory-api`

#### Notifications API
- **Client ID**: `notifications-api`
- **Scopes**: `notifications.read`, `notifications.write`
- **Audience**: `notifications-api`

#### Audit API
- **Client ID**: `audit-api`
- **Scopes**: `audit.read`, `audit.write`
- **Audience**: `audit-api`

#### API Gateway
- **Client ID**: `api-gateway`
- **Scopes**: All scopes (read/write for all services)
- **Audience**: None (gateway validates issuer only)

### 4. **Roles** (4 roles)
   - `admin` - Administrator role
   - `user` - Regular user role
   - `orders-manager` - Orders manager role
   - `inventory-manager` - Inventory manager role

### 5. **Test Users** (4 users)

| Username | Email | Password | Roles |
|----------|-------|----------|-------|
| admin | admin@microservices.local | Admin@123 | admin |
| user | user@microservices.local | User@123 | user |
| orders-manager | orders@microservices.local | Orders@123 | orders-manager |
| inventory-manager | inventory@microservices.local | Inventory@123 | inventory-manager |

## Testing the Setup

### 1. Access Keycloak Admin Console
```
URL: http://localhost:8080/admin
Username: admin
Password: admin
```

### 2. Get Access Token

```bash
# Using curl
curl -X POST http://localhost:8080/realms/microservices/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&client_id=orders-api&username=admin&password=Admin@123"
```

### 3. Test API with Token

```bash
# Get token
TOKEN=$(curl -s -X POST http://localhost:8080/realms/microservices/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&client_id=orders-api&username=admin&password=Admin@123" | jq -r '.access_token')

# Call Orders API through gateway
curl -X GET http://localhost:5000/orders/api/orders \
  -H "Authorization: Bearer $TOKEN"
```

## Troubleshooting

### Script Fails with "Keycloak is not accessible"

**Solution**: Ensure Keycloak is running
```bash
docker-compose up -d keycloak
docker-compose logs keycloak --tail 50
```

### "Failed to obtain admin token"

**Possible causes**:
1. Keycloak not fully initialized (wait 30-60 seconds)
2. Wrong admin credentials
3. Keycloak database not ready

**Solution**:
```bash
# Wait for Keycloak to be ready
docker-compose exec keycloak curl -f http://localhost:8080/health/ready

# Check logs
docker-compose logs keycloak --tail 100
```

### Realm/Client Already Exists

This is normal! The script will skip existing resources and continue.

### Users Already Exist

If users already exist, the script will retrieve their IDs and assign roles.

## Manual Configuration (Alternative)

If you prefer to configure Keycloak manually:

1. Open http://localhost:8080/admin
2. Login with admin/admin
3. Create realm "microservices"
4. Create client scopes (see section 2 above)
5. Create clients (see section 3 above)
6. Create roles (see section 4 above)
7. Create users (see section 5 above)
8. Assign roles to users

## API Integration

The microservices are already configured to use Keycloak:

### Orders API
```csharp
options.Authority = "http://keycloak:8080/realms/microservices";
options.Audience = "orders-api";
```

### Inventory API
```csharp
options.Authority = "http://keycloak:8080/realms/microservices";
options.Audience = "inventory-api";
```

### Notifications API
```csharp
options.Authority = "http://keycloak:8080/realms/microservices";
options.Audience = "notifications-api";
```

### Audit API
```csharp
options.Authority = "http://keycloak:8080/realms/microservices";
options.Audience = "audit-api";
```

### API Gateway
```csharp
options.Authority = "http://keycloak:8080/realms/microservices";
// Validates issuer only, no audience validation
```

## Authorization Policies

Each API has authorization policies based on scopes:

### Orders API
- `OrdersRead` - Requires `orders.read` scope
- `OrdersWrite` - Requires `orders.write` scope

### Inventory API
- `InventoryRead` - Requires `inventory.read` scope
- `InventoryWrite` - Requires `inventory.write` scope

### Notifications API
- `NotificationsRead` - Requires `notifications.read` scope
- `NotificationsWrite` - Requires `notifications.write` scope

### Audit API
- `AuditRead` - Requires `audit.read` scope
- `AuditWrite` - Requires `audit.write` scope

## Resetting Keycloak

To reset Keycloak to a clean state:

```bash
# Stop Keycloak
docker-compose stop keycloak

# Remove Keycloak database
docker volume rm kubernetessample2025_postgres-data

# Start fresh
docker-compose up -d keycloak

# Wait for initialization
sleep 60

# Run setup script again
./scripts/setup-keycloak.ps1  # Windows
# or
./scripts/setup-keycloak.sh   # Linux/Mac
```

## Additional Resources

- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [Keycloak Admin REST API](https://www.keycloak.org/docs/latest/server_admin/#admin-rest-api)
- [OpenID Connect Protocol](https://openid.net/connect/)
- [OAuth 2.0 Scopes](https://tools.ietf.org/html/rfc6749#section-3.3)

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Keycloak logs: `docker-compose logs keycloak`
3. Check microservice logs: `docker-compose logs orders-api`
4. Verify network connectivity: `docker-compose ps`


## 🔗 Access Points
Keycloak Admin	http://localhost:8080/admin
Realm	http://localhost:8080/realms/microservices
Token Endpoint	http://localhost:8080/realms/microservices/protocol/openid-connect/token

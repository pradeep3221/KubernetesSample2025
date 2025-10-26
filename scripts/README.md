# Keycloak Manager - Unified Script

## Overview

`keycloak-manager.ps1` is a comprehensive PowerShell script that consolidates all Keycloak configuration tasks into a single, easy-to-use tool. It replaces multiple individual scripts with one unified solution.

## Replaced Scripts

This unified script replaces the following individual scripts:

- ✅ `setup-keycloak.ps1` - Complete Keycloak setup
- ✅ `configure-frontends-keycloak.ps1` - Frontend client configuration
- ✅ `add-scope-mappers.ps1` - Scope mapper configuration
- ✅ `fix-keycloak-scopes.ps1` - Add scopes to frontend clients
- ✅ `fix-keycloak-roles.ps1` - Role assignment fixes
- ✅ `test-token.ps1` - Token generation testing
- ✅ `debug-users.ps1` - Debug user information
- ✅ `enable-password-grant.ps1` - Enable password grant flow

## Features

### 🎯 Single Entry Point
- One script for all Keycloak management tasks
- Consistent parameter handling
- Unified error handling and logging

### 🔧 Multiple Actions
- **Setup** - Complete Keycloak setup (realm, clients, scopes, roles, users)
- **ConfigureFrontends** - Configure Angular frontend clients
- **AddScopes** - Add microservice scopes to frontend clients
- **TestToken** - Test token generation and display claims
- **Debug** - Display all Keycloak configuration
- **EnablePasswordGrant** - Enable password grant for API clients
- **All** - Run all setup actions in sequence

### 🎨 Enhanced Output
- Color-coded messages (Success, Info, Warning, Error)
- Formatted headers and sections
- Clear progress indicators

### ⚙️ Configurable Parameters
- Keycloak URL
- Admin credentials
- Realm name
- Test user credentials

## Usage

### Basic Syntax

```powershell
.\keycloak-manager.ps1 -Action <action> [parameters]
```

### Available Actions

| Action | Description |
|--------|-------------|
| `Setup` | Complete Keycloak setup (realm, clients, scopes, roles, users) |
| `ConfigureFrontends` | Configure Angular frontend clients (customer-spa, admin-pwa) |
| `AddScopes` | Add microservice scopes to frontend clients |
| `TestToken` | Test token generation and display claims |
| `Debug` | Display all Keycloak configuration (users, clients, scopes, roles) |
| `EnablePasswordGrant` | Enable password grant for API clients |
| `All` | Run all setup actions (Setup + ConfigureFrontends + AddScopes) |
| `Help` | Display help message |

### Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `-KeycloakUrl` | `http://localhost:8080` | Keycloak server URL |
| `-AdminUser` | `admin` | Keycloak admin username |
| `-AdminPassword` | `admin` | Keycloak admin password |
| `-RealmName` | `microservices` | Realm name to configure |
| `-TestUsername` | `admin` | Test user for token generation |
| `-TestPassword` | `Admin@123` | Test password for token generation |

## Examples

### 1. Complete Setup (Recommended for First Time)

```powershell
.\keycloak-manager.ps1 -Action All
```

This will:
- Create the microservices realm
- Create all client scopes (orders, inventory, notifications, audit)
- Create API clients (orders-api, inventory-api, etc.)
- Create frontend clients (customer-spa, admin-pwa)
- Create roles (admin, user, orders-manager, inventory-manager)
- Create test users with assigned roles
- Add scopes to frontend clients
- Configure scope mappers

### 2. Setup Backend Only

```powershell
.\keycloak-manager.ps1 -Action Setup
```

Creates realm, API clients, scopes, roles, and users.

### 3. Configure Frontend Clients

```powershell
.\keycloak-manager.ps1 -Action ConfigureFrontends
```

Registers Angular frontend applications as OAuth2 clients.

### 4. Add Scopes to Frontend Clients

```powershell
.\keycloak-manager.ps1 -Action AddScopes
```

Adds microservice scopes to frontend clients so they can access APIs.

### 5. Test Token Generation

```powershell
.\keycloak-manager.ps1 -Action TestToken
```

Tests authentication by generating a token and displaying its claims.

### 6. Debug Configuration

```powershell
.\keycloak-manager.ps1 -Action Debug
```

Displays all users, clients, scopes, and roles for troubleshooting.

### 7. Enable Password Grant

```powershell
.\keycloak-manager.ps1 -Action EnablePasswordGrant
```

Enables password grant flow for API clients (useful for testing).

### 8. Custom Keycloak URL

```powershell
.\keycloak-manager.ps1 -Action Setup -KeycloakUrl "http://keycloak.example.com:8080"
```

### 9. Custom Realm Name

```powershell
.\keycloak-manager.ps1 -Action Setup -RealmName "production"
```

### 10. Test with Different User

```powershell
.\keycloak-manager.ps1 -Action TestToken -TestUsername "user" -TestPassword "User@123"
```

## What Gets Created

### Realm
- **Name**: microservices
- **Access Token Lifespan**: 3600 seconds (1 hour)
- **Refresh Token Lifespan**: 86400 seconds (24 hours)
- **SSL Required**: None (for development)

### Client Scopes
- `orders.read` - Read orders
- `orders.write` - Write orders
- `inventory.read` - Read inventory
- `inventory.write` - Write inventory
- `notifications.read` - Read notifications
- `notifications.write` - Write notifications
- `audit.read` - Read audit logs
- `audit.write` - Write audit logs

### API Clients (Confidential)
- `orders-api` - Orders microservice
- `inventory-api` - Inventory microservice
- `notifications-api` - Notifications microservice
- `audit-api` - Audit microservice
- `api-gateway` - API Gateway (all scopes)

### Frontend Clients (Public)
- `customer-spa` - Customer Angular SPA (http://localhost:4200)
- `admin-pwa` - Admin Angular PWA (http://localhost:4201)

### Roles
- `admin` - Administrator role
- `user` - Regular user role
- `orders-manager` - Orders manager role
- `inventory-manager` - Inventory manager role

### Test Users

| Username | Password | Email | Roles |
|----------|----------|-------|-------|
| admin | Admin@123 | admin@microservices.local | admin |
| user | User@123 | user@microservices.local | user |
| orders-manager | Orders@123 | orders@microservices.local | orders-manager |
| inventory-manager | Inventory@123 | inventory@microservices.local | inventory-manager |

## Workflow

### Initial Setup

```powershell
# 1. Start Keycloak
docker-compose up -d keycloak

# 2. Wait for Keycloak to be ready (about 30 seconds)
Start-Sleep -Seconds 30

# 3. Run complete setup
.\keycloak-manager.ps1 -Action All
```

### Adding Frontend Clients Later

```powershell
# If you already ran Setup but need to add frontends
.\keycloak-manager.ps1 -Action ConfigureFrontends
.\keycloak-manager.ps1 -Action AddScopes
```

### Troubleshooting

```powershell
# Check configuration
.\keycloak-manager.ps1 -Action Debug

# Test authentication
.\keycloak-manager.ps1 -Action TestToken
```

## Output Examples

### Success Output
```
[SUCCESS] Admin token obtained
[SUCCESS] Realm 'microservices' created
[SUCCESS] Client scope 'orders.read' created
[SUCCESS] Client 'orders-api' created
```

### Warning Output
```
[WARNING] Realm 'microservices' already exists
[WARNING] Client scope 'orders.read' already exists
```

### Error Output
```
[ERROR] Failed to obtain admin token: Connection refused
[ERROR] Keycloak is not accessible at http://localhost:8080
```

## Migration from Old Scripts

If you were using the old individual scripts, simply replace them with the new unified script:

| Old Script | New Command |
|------------|-------------|
| `.\setup-keycloak.ps1` | `.\keycloak-manager.ps1 -Action Setup` |
| `.\configure-frontends-keycloak.ps1` | `.\keycloak-manager.ps1 -Action ConfigureFrontends` |
| `.\fix-keycloak-scopes.ps1` | `.\keycloak-manager.ps1 -Action AddScopes` |
| `.\test-token.ps1` | `.\keycloak-manager.ps1 -Action TestToken` |
| `.\debug-users.ps1` | `.\keycloak-manager.ps1 -Action Debug` |
| `.\enable-password-grant.ps1` | `.\keycloak-manager.ps1 -Action EnablePasswordGrant` |

## Benefits

✅ **Single Script** - One file instead of 8+ separate scripts  
✅ **Consistent Interface** - Same parameters and output format  
✅ **Better Error Handling** - Unified error messages and recovery  
✅ **Easier Maintenance** - Update one file instead of many  
✅ **Comprehensive Help** - Built-in help with examples  
✅ **Idempotent** - Safe to run multiple times  
✅ **Modular Actions** - Run only what you need  

## Requirements

- PowerShell 5.1 or higher
- Keycloak 23.0 or higher running and accessible
- Network access to Keycloak server

## Support

For issues or questions:
1. Run `.\keycloak-manager.ps1 -Action Debug` to check configuration
2. Run `.\keycloak-manager.ps1 -Action TestToken` to verify authentication
3. Check Keycloak logs: `docker logs keycloak`
4. Access Keycloak Admin Console: http://localhost:8080/admin

## License

Part of the KubernetesSample2025 project.


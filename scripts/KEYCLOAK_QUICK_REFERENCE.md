# Keycloak Quick Reference Guide

## Quick Start

### Run Setup (Windows)
```powershell
.\scripts\setup-keycloak.ps1
```

### Run Setup (Linux/Mac)
```bash
./scripts/setup-keycloak.sh
```

## Test Credentials

```
Admin User:
  Username: admin
  Password: Admin@123

Regular User:
  Username: user
  Password: User@123

Orders Manager:
  Username: orders-manager
  Password: Orders@123

Inventory Manager:
  Username: inventory-manager
  Password: Inventory@123
```

## Important URLs

| Service | URL |
|---------|-----|
| Keycloak Home | http://localhost:8080 |
| Admin Console | http://localhost:8080/admin |
| Realm | http://localhost:8080/realms/microservices |
| Token Endpoint | http://localhost:8080/realms/microservices/protocol/openid-connect/token |
| JWKS Endpoint | http://localhost:8080/realms/microservices/protocol/openid-connect/certs |

## Get Access Token

### Using curl
```bash
curl -X POST http://localhost:8080/realms/microservices/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&client_id=orders-api&username=admin&password=Admin@123"
```

### Using PowerShell
```powershell
$body = @{
    grant_type = "password"
    client_id = "orders-api"
    username = "admin"
    password = "Admin@123"
}

$response = Invoke-RestMethod -Uri "http://localhost:8080/realms/microservices/protocol/openid-connect/token" `
    -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"

$response.access_token
```

## Call API with Token

### Using curl
```bash
TOKEN="<your-token-here>"

curl -X GET http://localhost:5000/orders/api/orders \
  -H "Authorization: Bearer $TOKEN"
```

### Using PowerShell
```powershell
$token = "<your-token-here>"
$headers = @{
    Authorization = "Bearer $token"
}

Invoke-RestMethod -Uri "http://localhost:5000/orders/api/orders" `
    -Method Get -Headers $headers
```

## Client Scopes

| Scope | Purpose |
|-------|---------|
| orders.read | Read orders |
| orders.write | Create/update orders |
| inventory.read | Read inventory |
| inventory.write | Create/update inventory |
| notifications.read | Read notifications |
| notifications.write | Send notifications |
| audit.read | Read audit logs |
| audit.write | Write audit logs |

## Clients

| Client ID | Purpose | Scopes |
|-----------|---------|--------|
| orders-api | Orders microservice | orders.read, orders.write |
| inventory-api | Inventory microservice | inventory.read, inventory.write |
| notifications-api | Notifications microservice | notifications.read, notifications.write |
| audit-api | Audit microservice | audit.read, audit.write |
| api-gateway | API Gateway | All scopes |

## Roles

| Role | Purpose |
|------|---------|
| admin | Full access to all services |
| user | Basic user access |
| orders-manager | Manage orders |
| inventory-manager | Manage inventory |

## Common Tasks

### Check Keycloak Status
```bash
docker-compose ps keycloak
```

### View Keycloak Logs
```bash
docker-compose logs keycloak --tail 50
```

### Restart Keycloak
```bash
docker-compose restart keycloak
```

### Reset Keycloak (Delete All Data)
```bash
docker-compose down
docker volume rm kubernetessample2025_postgres-data
docker-compose up -d keycloak
sleep 60
./scripts/setup-keycloak.ps1  # or .sh for Linux/Mac
```

### Access Admin Console
1. Open http://localhost:8080/admin
2. Login with admin/admin
3. Select "microservices" realm

## Decode JWT Token

### Using PowerShell
```powershell
$token = "<your-token-here>"
$parts = $token.Split('.')
$payload = $parts[1]

# Add padding if needed
while ($payload.Length % 4) { $payload += "=" }

$decoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($payload))
$decoded | ConvertFrom-Json | Format-Table
```

### Using Online Tool
- https://jwt.io (paste token to decode)

## Verify Token Claims

Look for these claims in the JWT:
- `sub` - Subject (user ID)
- `preferred_username` - Username
- `scope` - Granted scopes
- `aud` - Audience (client ID)
- `iss` - Issuer (Keycloak realm)
- `exp` - Expiration time
- `iat` - Issued at time

## API Authorization

### Orders API
- GET /api/orders - Requires `orders.read`
- POST /api/orders - Requires `orders.write`
- PUT /api/orders/{id} - Requires `orders.write`
- DELETE /api/orders/{id} - Requires `orders.write`

### Inventory API
- GET /api/inventory - Requires `inventory.read`
- POST /api/inventory - Requires `inventory.write`
- PUT /api/inventory/{id} - Requires `inventory.write`
- DELETE /api/inventory/{id} - Requires `inventory.write`

### Notifications API
- GET /api/notifications - Requires `notifications.read`
- POST /api/notifications - Requires `notifications.write`

### Audit API
- GET /api/audit - Requires `audit.read`
- POST /api/audit - Requires `audit.write`

## Troubleshooting

### "Invalid token" Error
- Token may have expired (1 hour lifespan)
- Get a new token using credentials
- Check token expiration: `exp` claim in JWT

### "Insufficient permissions" Error
- User doesn't have required scope
- Check user roles in Keycloak admin console
- Verify scope is assigned to client

### "Keycloak not accessible" Error
- Keycloak container may not be running
- Check: `docker-compose ps keycloak`
- Start: `docker-compose up -d keycloak`
- Wait 30-60 seconds for initialization

### "Realm not found" Error
- Run setup script: `./scripts/setup-keycloak.ps1`
- Or manually create realm in admin console

## Performance Tips

1. **Token Caching**
   - Cache tokens until expiration
   - Reduce token requests

2. **Connection Pooling**
   - Reuse HTTP connections
   - Reduce connection overhead

3. **Rate Limiting**
   - API Gateway has rate limiting enabled
   - 10 requests per second per client

## Security Checklist

- [ ] Change admin password in production
- [ ] Enable HTTPS/SSL
- [ ] Set up email verification
- [ ] Configure user federation
- [ ] Enable audit logging
- [ ] Set appropriate token lifespans
- [ ] Use strong passwords
- [ ] Restrict admin console access
- [ ] Enable rate limiting
- [ ] Monitor failed login attempts

## Additional Resources

- **Keycloak Documentation**: https://www.keycloak.org/documentation
- **Admin REST API**: https://www.keycloak.org/docs/latest/server_admin/#admin-rest-api
- **OpenID Connect**: https://openid.net/connect/
- **OAuth 2.0**: https://tools.ietf.org/html/rfc6749
- **JWT**: https://jwt.io

## Support

For issues:
1. Check Keycloak logs: `docker-compose logs keycloak`
2. Check microservice logs: `docker-compose logs orders-api`
3. Review KEYCLOAK_SETUP.md for detailed troubleshooting
4. Check Keycloak admin console for configuration


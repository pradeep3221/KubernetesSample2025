# Authentication Disabled in All Microservices

## Summary

Authentication and authorization have been **disabled** in all microservices for development purposes. All API endpoints are now publicly accessible without requiring JWT tokens.

## Changes Made

### 1. Orders API (`src/Services/Orders.API/Program.cs`)

**Authentication Configuration** - Commented out:
- JWT Bearer authentication setup
- Authorization policies (OrdersRead, OrdersWrite)
- `app.UseAuthentication()` middleware
- `app.UseAuthorization()` middleware

**Endpoint Authorization** - Removed from:
- `GET /api/orders` - Get all orders
- `GET /api/orders/{id}` - Get order by ID
- `POST /api/orders` - Create order
- `POST /api/orders/{id}/confirm` - Confirm order
- `POST /api/orders/{id}/cancel` - Cancel order
- `POST /api/orders/{id}/ship` - Ship order

---

### 2. Inventory API (`src/Services/Inventory.API/Program.cs`)

**Authentication Configuration** - Commented out:
- JWT Bearer authentication setup
- Authorization policies (InventoryRead, InventoryWrite)
- `app.UseAuthentication()` middleware
- `app.UseAuthorization()` middleware

**Endpoint Authorization** - Removed from:
- `GET /api/inventory/products` - Get all products
- `GET /api/inventory/products/{id}` - Get product by ID
- `GET /api/inventory/products/sku/{sku}` - Get product by SKU
- `GET /api/inventory/products/low-stock` - Get low stock products
- `POST /api/inventory/products` - Create product
- `PUT /api/inventory/products/{id}` - Update product
- `POST /api/inventory/products/{id}/adjust` - Adjust quantity
- `DELETE /api/inventory/products/{id}` - Delete product

---

### 3. Notifications API (`src/Services/Notifications.API/Program.cs`)

**Authentication Configuration** - Commented out:
- JWT Bearer authentication setup
- Authorization policies (NotificationsRead, NotificationsWrite)
- `app.UseAuthentication()` middleware
- `app.UseAuthorization()` middleware

**Endpoint Authorization** - Removed from:
- `GET /api/notifications/user/{userId}` - Get user notifications
- `GET /api/notifications/{id}` - Get notification by ID
- `POST /api/notifications` - Send notification
- `POST /api/notifications/{id}/mark-read` - Mark notification as read

---

### 4. Audit API (`src/Services/Audit.API/Program.cs`)

**Authentication Configuration** - Commented out:
- JWT Bearer authentication setup
- Authorization policies (AuditRead, AuditWrite)
- `app.UseAuthentication()` middleware
- `app.UseAuthorization()` middleware

**Endpoint Authorization** - Removed from:
- `GET /api/audit/events` - Get all events
- `GET /api/audit/events/{streamId}` - Get events by stream
- `GET /api/audit/documents` - Get all documents
- `GET /api/audit/documents/{entity}` - Get documents by entity
- `POST /api/audit/replay/{streamId}` - Replay events

---

## Implementation Details

All authentication code has been **commented out** rather than deleted, making it easy to re-enable if needed:

```csharp
// Authentication disabled for development
// builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
//     .AddJwtBearer(options =>
//     {
//         var keycloakUrl = builder.Configuration["Keycloak:Authority"] ?? "http://localhost:8080/realms/microservices";
//         options.Authority = keycloakUrl;
//         options.RequireHttpsMetadata = false;
//     });

// builder.Services.AddAuthorization(options =>
// {
//     options.AddPolicy("PolicyName", policy => policy.RequireClaim("scope", "scope.name"));
// });
```

Endpoint authorization:
```csharp
app.MapGet("/api/endpoint", async () =>
{
    // Handler code
})
// .RequireAuthorization("PolicyName")  // Commented out
.WithName("EndpointName")
.WithOpenApi();
```

---

## Deployment Status

✅ **All microservices rebuilt and restarted**

| Service | Status | Authentication |
|---------|--------|----------------|
| Orders API | ✅ Running | Disabled |
| Inventory API | ✅ Running | Disabled |
| Notifications API | ✅ Running | Disabled |
| Audit API | ✅ Running | Disabled |

---

## Testing

All API endpoints are now accessible without authentication:

### Orders API
```bash
# Get all orders
curl http://localhost:5000/orders

# Create order
curl -X POST http://localhost:5000/orders \
  -H "Content-Type: application/json" \
  -d '{"customerId":"guid","items":[...]}'
```

### Inventory API
```bash
# Get all products
curl http://localhost:5000/inventory/products

# Create product
curl -X POST http://localhost:5000/inventory/products \
  -H "Content-Type: application/json" \
  -d '{"sku":"SKU001","name":"Product","quantity":100}'
```

### Notifications API
```bash
# Get user notifications
curl http://localhost:5000/notifications/user/{userId}

# Send notification
curl -X POST http://localhost:5000/notifications \
  -H "Content-Type: application/json" \
  -d '{"userId":"guid","type":"Info","title":"Test","message":"Test message"}'
```

### Audit API
```bash
# Get all events
curl http://localhost:5000/audit/events

# Get documents
curl http://localhost:5000/audit/documents
```

---

## Re-enabling Authentication

To re-enable authentication in the future:

1. **Uncomment authentication configuration** in each `Program.cs`:
   - `AddAuthentication()` and `AddJwtBearer()`
   - `AddAuthorization()` with policies
   - `app.UseAuthentication()` and `app.UseAuthorization()`

2. **Uncomment endpoint authorization**:
   - Uncomment `.RequireAuthorization("PolicyName")` on each endpoint

3. **Rebuild and restart** the microservices:
   ```bash
   docker-compose build orders-api inventory-api notifications-api audit-api
   docker-compose up -d orders-api inventory-api notifications-api audit-api
   ```

---

## Security Considerations

⚠️ **WARNING**: This configuration is for **development only**!

- All API endpoints are publicly accessible
- No user authentication or authorization
- No access control or permissions
- Suitable only for local development and testing

**DO NOT deploy to production with authentication disabled!**

---

## Related Files

- `src/Services/Orders.API/Program.cs` - Orders API configuration
- `src/Services/Inventory.API/Program.cs` - Inventory API configuration
- `src/Services/Notifications.API/Program.cs` - Notifications API configuration
- `src/Services/Audit.API/Program.cs` - Audit API configuration

---

## Previous Authentication Setup

For reference, the previous authentication setup included:

- **Keycloak** as OAuth2/OIDC provider
- **JWT Bearer tokens** for authentication
- **OAuth2 scopes** for fine-grained authorization:
  - `orders.read`, `orders.write`
  - `inventory.read`, `inventory.write`
  - `notifications.read`, `notifications.write`
  - `audit.read`, `audit.write`
- **Authorization policies** enforcing scope requirements
- **API Gateway** forwarding tokens to microservices

All of this has been disabled for simplified development.

---

## Date

**Disabled on**: 2025-10-26

**Reason**: Simplified development and testing without authentication complexity


# Frontend API Gateway Endpoints - Complete Summary

## ✅ Status: All Endpoints Configured and Working

Both frontend applications are **already correctly configured** to call all APIs through the API Gateway at `http://localhost:5000`.

## Quick Reference

### Frontend Applications
| App | Port | URL | API Service |
|-----|------|-----|-------------|
| **Customer SPA** | 4200 | http://localhost:4200 | `api.service.ts` |
| **Admin PWA** | 4201 | http://localhost:4201 | `admin-api.service.ts` |

### API Gateway
| Component | URL | Port |
|-----------|-----|------|
| **API Gateway** | http://localhost:5000 | 5000 |
| **Keycloak** | http://localhost:8080 | 8080 |

## API Endpoints Configuration

### All Endpoints Use API Gateway
```
Frontend → API Gateway (5000) → Microservices
```

### Orders API Endpoints
```
GET    /orders                    # Get all orders
GET    /orders/{id}               # Get order by ID
POST   /orders                    # Create order
POST   /orders/{id}/confirm       # Confirm order
POST   /orders/{id}/cancel        # Cancel order
POST   /orders/{id}/ship          # Ship order
```

### Inventory API Endpoints
```
GET    /inventory/products                    # Get all products
GET    /inventory/products/{id}               # Get product by ID
GET    /inventory/products/sku/{sku}          # Get by SKU
GET    /inventory/products/low-stock          # Low stock products
POST   /inventory/products                    # Create product
PUT    /inventory/products/{id}               # Update product
POST   /inventory/products/{id}/adjust        # Adjust quantity
DELETE /inventory/products/{id}               # Delete product
```

### Audit API Endpoints
```
GET    /audit/events                         # Get all events
GET    /audit/events/{streamId}              # Get events by stream
GET    /audit/documents                      # Get all documents
GET    /audit/documents/{entity}             # Get documents by entity
POST   /audit/replay/{streamId}              # Replay events
```

### Notifications API Endpoints
```
GET    /notifications/user/{userId}          # Get user notifications
GET    /notifications/{id}                   # Get notification
POST   /notifications                        # Send notification
POST   /notifications/{id}/mark-read         # Mark as read
```

## Frontend Service Files

### Customer SPA
**File**: `src/frontend/customer-spa/src/app/services/api.service.ts`

```typescript
private apiUrl = 'http://localhost:5000'; // API Gateway URL

// Methods:
getProducts(): Observable<any[]>
getProduct(id: string): Observable<any>
getOrders(): Promise<Observable<any[]>>
getOrder(id: string): Promise<Observable<any>>
createOrder(order: any): Promise<Observable<any>>
cancelOrder(id: string, reason: string): Promise<Observable<any>>
```

### Admin PWA
**File**: `src/frontend/admin-pwa/src/app/services/admin-api.service.ts`

```typescript
private apiUrl = 'http://localhost:5000'; // API Gateway URL

// Methods:
getAllOrders(): Promise<Observable<any[]>>
getOrder(id: string): Promise<Observable<any>>
confirmOrder(id: string): Promise<Observable<any>>
shipOrder(id: string, trackingNumber: string): Promise<Observable<any>>
cancelOrder(id: string, reason: string): Promise<Observable<any>>
getAllProducts(): Observable<any[]>
getProduct(id: string): Promise<Observable<any>>
createProduct(product: any): Promise<Observable<any>>
updateProduct(id: string, product: any): Promise<Observable<any>>
adjustInventory(id: string, quantityChange: number, reason: string): Promise<Observable<any>>
getAuditLogs(): Promise<Observable<any[]>>
getAuditLogsByEntity(entity: string): Promise<Observable<any[]>>
getEventStream(streamId: string): Promise<Observable<any[]>>
```

## Authentication

### HTTP Interceptor
Both frontends have HTTP interceptors that automatically add JWT tokens:

**Customer SPA**: `src/frontend/customer-spa/src/app/interceptors/auth.interceptor.ts`
**Admin PWA**: `src/frontend/admin-pwa/src/app/interceptors/auth.interceptor.ts`

### Token Flow
1. User logs in via Keycloak
2. Keycloak returns JWT token
3. HTTP Interceptor adds token to all requests
4. API Gateway validates token
5. Microservice validates token and scopes

### Test Credentials
```
Username: admin
Password: Admin@123
```

## API Gateway Routes (Ocelot Configuration)

**File**: `src/Gateway/Ocelot.Gateway/ocelot.json`

### Route Mapping
| Upstream | Downstream | Service |
|----------|-----------|---------|
| `/orders/{everything}` | `/api/orders/{everything}` | orders-api:8080 |
| `/inventory/{everything}` | `/api/inventory/{everything}` | inventory-api:8080 |
| `/audit/{everything}` | `/api/audit/{everything}` | audit-api:8080 |
| `/notifications/{everything}` | `/api/notifications/{everything}` | notifications-api:8080 |

### Gateway Features
- ✅ JWT Authentication
- ✅ Rate Limiting (10 requests/second per route)
- ✅ Service Discovery
- ✅ Request Routing
- ✅ Metrics Collection

## Testing the Endpoints

### 1. Get Authentication Token
```bash
curl -X POST http://localhost:8080/realms/microservices/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&client_id=orders-api&username=admin&password=Admin@123"
```

### 2. Get All Orders
```bash
curl -X GET http://localhost:5000/orders \
  -H "Authorization: Bearer <token>"
```

### 3. Create an Order
```bash
curl -X POST http://localhost:5000/orders \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "customerId": "00000000-0000-0000-0000-000000000000",
    "items": [{
      "productId": "00000000-0000-0000-0000-000000000000",
      "productName": "Test Product",
      "quantity": 1,
      "unitPrice": 29.99
    }]
  }'
```

### 4. Get All Products
```bash
curl -X GET http://localhost:5000/inventory/products \
  -H "Authorization: Bearer <token>"
```

## Verification Checklist

- ✅ Customer SPA configured to use `http://localhost:5000`
- ✅ Admin PWA configured to use `http://localhost:5000`
- ✅ HTTP Interceptors add JWT tokens automatically
- ✅ API Gateway routes all requests correctly
- ✅ Keycloak authentication working
- ✅ Rate limiting enabled
- ✅ All microservices accessible via gateway

## Next Steps

1. **Access Customer SPA**: http://localhost:4200
2. **Login** with admin/Admin@123
3. **Create an Order** - Test the complete flow
4. **Check Admin PWA**: http://localhost:4201
5. **Monitor Logs**: `docker logs api-gateway`

## Files Modified/Created

### HTTP Interceptors (NEW)
- `src/frontend/customer-spa/src/app/interceptors/auth.interceptor.ts`
- `src/frontend/admin-pwa/src/app/interceptors/auth.interceptor.ts`

### App Modules (UPDATED)
- `src/frontend/customer-spa/src/app/app.module.ts`
- `src/frontend/admin-pwa/src/app/app.module.ts`

### API Services (EXISTING - Already Configured)
- `src/frontend/customer-spa/src/app/services/api.service.ts`
- `src/frontend/admin-pwa/src/app/services/admin-api.service.ts`

---

**Status**: ✅ **COMPLETE** - All frontend endpoints are correctly configured to call APIs via the API Gateway

**Last Updated**: 2025-10-26


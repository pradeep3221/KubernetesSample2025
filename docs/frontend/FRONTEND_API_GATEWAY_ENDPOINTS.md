# ✅ Frontend API Gateway Endpoints Configuration

## Overview

Both frontend applications (Customer SPA and Admin PWA) are correctly configured to call all APIs through the **API Gateway** at `http://localhost:5000` instead of calling microservices directly.

## Current Configuration

### API Gateway Base URL
```
http://localhost:5000
```

### Frontend Services

#### Customer SPA (`src/frontend/customer-spa/src/app/services/api.service.ts`)
- **Base URL**: `http://localhost:5000`
- **Location**: `src/frontend/customer-spa/src/app/services/api.service.ts`

#### Admin PWA (`src/frontend/admin-pwa/src/app/services/admin-api.service.ts`)
- **Base URL**: `http://localhost:5000`
- **Location**: `src/frontend/admin-pwa/src/app/services/admin-api.service.ts`

## API Endpoints via Gateway

### Orders API
| Method | Endpoint | Frontend Call | Description |
|--------|----------|---------------|-------------|
| GET | `/orders` | `getOrders()` | Get all orders |
| GET | `/orders/{id}` | `getOrder(id)` | Get order by ID |
| POST | `/orders` | `createOrder(order)` | Create new order |
| POST | `/orders/{id}/confirm` | `confirmOrder(id)` | Confirm order |
| POST | `/orders/{id}/cancel` | `cancelOrder(id, reason)` | Cancel order |
| POST | `/orders/{id}/ship` | `shipOrder(id, trackingNumber)` | Ship order |

**Gateway Route**: `/orders/{everything}` → `orders-api:8080/api/orders/{everything}`

### Inventory API
| Method | Endpoint | Frontend Call | Description |
|--------|----------|---------------|-------------|
| GET | `/inventory/products` | `getProducts()` | Get all products |
| GET | `/inventory/products/{id}` | `getProduct(id)` | Get product by ID |
| POST | `/inventory/products` | `createProduct(product)` | Create product |
| PUT | `/inventory/products/{id}` | `updateProduct(id, product)` | Update product |
| POST | `/inventory/products/{id}/adjust` | `adjustInventory(id, qty, reason)` | Adjust inventory |
| DELETE | `/inventory/products/{id}` | - | Delete product |

**Gateway Route**: `/inventory/{everything}` → `inventory-api:8080/api/inventory/{everything}`

### Audit API
| Method | Endpoint | Frontend Call | Description |
|--------|----------|---------------|-------------|
| GET | `/audit/events` | - | Get all events |
| GET | `/audit/events/{streamId}` | `getEventStream(streamId)` | Get events by stream |
| GET | `/audit/documents` | `getAuditLogs()` | Get all audit documents |
| GET | `/audit/documents/{entity}` | `getAuditLogsByEntity(entity)` | Get documents by entity |
| POST | `/audit/replay/{streamId}` | - | Replay events |

**Gateway Route**: `/audit/{everything}` → `audit-api:8080/api/audit/{everything}`

### Notifications API
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/notifications/user/{userId}` | Get user notifications |
| GET | `/notifications/{id}` | Get notification |
| POST | `/notifications` | Send notification |
| POST | `/notifications/{id}/mark-read` | Mark as read |

**Gateway Route**: `/notifications/{everything}` → `notifications-api:8080/api/notifications/{everything}`

## Authentication Flow

### 1. User Login
- User clicks "Login" button on frontend
- Redirected to Keycloak login page
- Keycloak returns JWT token to frontend

### 2. HTTP Interceptor
- **File**: `src/frontend/customer-spa/src/app/interceptors/auth.interceptor.ts`
- **File**: `src/frontend/admin-pwa/src/app/interceptors/auth.interceptor.ts`
- Automatically adds JWT token to all API requests
- Header: `Authorization: Bearer <token>`

### 3. API Gateway Authentication
- API Gateway validates JWT token
- Routes request to appropriate microservice
- Microservice validates token again

### 4. Microservice Authorization
- Each microservice checks JWT scopes
- Enforces role-based access control
- Returns 401 if unauthorized

## Request Flow Example

### Creating an Order

```
1. Frontend (Customer SPA)
   ↓
2. HTTP Interceptor adds JWT token
   ↓
3. POST http://localhost:5000/orders
   ↓
4. API Gateway (Ocelot)
   - Validates JWT token
   - Routes to orders-api
   ↓
5. Orders API (orders-api:8080)
   - Validates JWT token
   - Checks "orders.write" scope
   - Creates order in SQL Server
   - Publishes OrderCreated event to RabbitMQ
   ↓
6. Response returned to frontend
```

## Keycloak Clients Configuration

### Customer SPA Client
- **Client ID**: `customer-spa`
- **Type**: Public (SPA)
- **Redirect URI**: `http://localhost:4200/*`
- **Web Origins**: `http://localhost:4200`

### Admin PWA Client
- **Client ID**: `admin-pwa`
- **Type**: Public (SPA)
- **Redirect URI**: `http://localhost:4201/*`
- **Web Origins**: `http://localhost:4201`

## Testing the Endpoints

### 1. Get All Orders
```bash
curl -X GET http://localhost:5000/orders \
  -H "Authorization: Bearer <token>"
```

### 2. Create an Order
```bash
curl -X POST http://localhost:5000/orders \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "customerId": "00000000-0000-0000-0000-000000000000",
    "items": [
      {
        "productId": "00000000-0000-0000-0000-000000000000",
        "productName": "Test Product",
        "quantity": 1,
        "unitPrice": 29.99
      }
    ]
  }'
```

### 3. Get All Products
```bash
curl -X GET http://localhost:5000/inventory/products \
  -H "Authorization: Bearer <token>"
```

### 4. Get Audit Logs
```bash
curl -X GET http://localhost:5000/audit/documents \
  -H "Authorization: Bearer <token>"
```

## Frontend Service Methods

### Customer SPA API Service
```typescript
// Products
getProducts(): Observable<any[]>
getProduct(id: string): Observable<any>

// Orders
getOrders(): Promise<Observable<any[]>>
getOrder(id: string): Promise<Observable<any>>
createOrder(order: any): Promise<Observable<any>>
cancelOrder(id: string, reason: string): Promise<Observable<any>>
```

### Admin PWA API Service
```typescript
// Orders
getAllOrders(): Promise<Observable<any[]>>
getOrder(id: string): Promise<Observable<any>>
confirmOrder(id: string): Promise<Observable<any>>
shipOrder(id: string, trackingNumber: string): Promise<Observable<any>>
cancelOrder(id: string, reason: string): Promise<Observable<any>>

// Inventory
getAllProducts(): Observable<any[]>
getProduct(id: string): Promise<Observable<any>>
createProduct(product: any): Promise<Observable<any>>
updateProduct(id: string, product: any): Promise<Observable<any>>
adjustInventory(id: string, quantityChange: number, reason: string): Promise<Observable<any>>

// Audit
getAuditLogs(): Promise<Observable<any[]>>
getAuditLogsByEntity(entity: string): Promise<Observable<any[]>>
getEventStream(streamId: string): Promise<Observable<any[]>>
```

## Benefits of Using API Gateway

✅ **Single Entry Point** - All requests go through one gateway
✅ **Authentication** - Centralized JWT validation
✅ **Rate Limiting** - Protect backend services
✅ **Load Balancing** - Distribute requests
✅ **Service Discovery** - Gateway handles routing
✅ **Monitoring** - Centralized logging and metrics
✅ **Security** - Hide internal service details

## Verification

### Check API Gateway is Running
```bash
docker-compose ps api-gateway
```

### Check API Gateway Logs
```bash
docker logs api-gateway
```

### Test Gateway Health
```bash
curl http://localhost:5000/health
```

### Test Orders API via Gateway
```bash
curl http://localhost:5000/orders/health
```

## Status

✅ **COMPLETE** - All frontend endpoints are correctly configured to use the API Gateway

---

**Last Updated**: 2025-10-26
**Status**: Production Ready


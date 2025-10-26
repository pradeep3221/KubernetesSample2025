# Complete API Endpoint Mapping

## Frontend → API Gateway → Microservices

### Architecture
```
┌─────────────────────────────────────────────────────────────────┐
│                    Frontend Applications                         │
│  ┌──────────────────────┐      ┌──────────────────────┐         │
│  │  Customer SPA        │      │  Admin PWA           │         │
│  │  (Port 4200)         │      │  (Port 4201)         │         │
│  │  api.service.ts      │      │  admin-api.service.ts│         │
│  └──────────────────────┘      └──────────────────────┘         │
└─────────────────────────────────────────────────────────────────┘
                                 ↓
                    HTTP Interceptor (JWT Token)
                                 ↓
┌─────────────────────────────────────────────────────────────────┐
│                    API Gateway (Ocelot)                          │
│                    (Port 5000)                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  • JWT Authentication                                    │   │
│  │  • Rate Limiting                                         │   │
│  │  • Request Routing                                       │   │
│  │  • Service Discovery                                     │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
        ↓              ↓              ↓              ↓
    ┌────────┐   ┌──────────┐   ┌──────────┐   ┌──────────────┐
    │ Orders │   │Inventory │   │  Audit   │   │Notifications│
    │  API   │   │   API    │   │   API    │   │    API       │
    │(5001)  │   │  (5002)  │   │  (5004)  │   │   (5003)     │
    └────────┘   └──────────┘   └──────────┘   └──────────────┘
        ↓              ↓              ↓              ↓
    ┌────────┐   ┌──────────┐   ┌──────────┐   ┌──────────────┐
    │SQL Srv │   │PostgreSQL│   │PostgreSQL│   │   Redis      │
    │        │   │(Dapper)  │   │(Marten)  │   │              │
    └────────┘   └──────────┘   └──────────┘   └──────────────┘
```

## Endpoint Mapping Table

### Orders API

| Frontend Method | HTTP Method | Frontend URL | Gateway URL | Backend URL | Backend Endpoint |
|-----------------|-------------|--------------|-------------|-------------|------------------|
| `getOrders()` | GET | `/orders` | `http://localhost:5000/orders` | `http://orders-api:8080/api/orders` | `GET /api/orders` |
| `getOrder(id)` | GET | `/orders/{id}` | `http://localhost:5000/orders/{id}` | `http://orders-api:8080/api/orders/{id}` | `GET /api/orders/{id}` |
| `createOrder()` | POST | `/orders` | `http://localhost:5000/orders` | `http://orders-api:8080/api/orders` | `POST /api/orders` |
| `confirmOrder()` | POST | `/orders/{id}/confirm` | `http://localhost:5000/orders/{id}/confirm` | `http://orders-api:8080/api/orders/{id}/confirm` | `POST /api/orders/{id}/confirm` |
| `cancelOrder()` | POST | `/orders/{id}/cancel` | `http://localhost:5000/orders/{id}/cancel` | `http://orders-api:8080/api/orders/{id}/cancel` | `POST /api/orders/{id}/cancel` |
| `shipOrder()` | POST | `/orders/{id}/ship` | `http://localhost:5000/orders/{id}/ship` | `http://orders-api:8080/api/orders/{id}/ship` | `POST /api/orders/{id}/ship` |

### Inventory API

| Frontend Method | HTTP Method | Frontend URL | Gateway URL | Backend URL | Backend Endpoint |
|-----------------|-------------|--------------|-------------|-------------|------------------|
| `getProducts()` | GET | `/inventory/products` | `http://localhost:5000/inventory/products` | `http://inventory-api:8080/api/inventory/products` | `GET /api/inventory/products` |
| `getProduct(id)` | GET | `/inventory/products/{id}` | `http://localhost:5000/inventory/products/{id}` | `http://inventory-api:8080/api/inventory/products/{id}` | `GET /api/inventory/products/{id}` |
| `createProduct()` | POST | `/inventory/products` | `http://localhost:5000/inventory/products` | `http://inventory-api:8080/api/inventory/products` | `POST /api/inventory/products` |
| `updateProduct()` | PUT | `/inventory/products/{id}` | `http://localhost:5000/inventory/products/{id}` | `http://inventory-api:8080/api/inventory/products/{id}` | `PUT /api/inventory/products/{id}` |
| `adjustInventory()` | POST | `/inventory/products/{id}/adjust` | `http://localhost:5000/inventory/products/{id}/adjust` | `http://inventory-api:8080/api/inventory/products/{id}/adjust` | `POST /api/inventory/products/{id}/adjust` |

### Audit API

| Frontend Method | HTTP Method | Frontend URL | Gateway URL | Backend URL | Backend Endpoint |
|-----------------|-------------|--------------|-------------|-------------|------------------|
| `getAuditLogs()` | GET | `/audit/documents` | `http://localhost:5000/audit/documents` | `http://audit-api:8080/api/audit/documents` | `GET /api/audit/documents` |
| `getAuditLogsByEntity()` | GET | `/audit/documents/{entity}` | `http://localhost:5000/audit/documents/{entity}` | `http://audit-api:8080/api/audit/documents/{entity}` | `GET /api/audit/documents/{entity}` |
| `getEventStream()` | GET | `/audit/events/{streamId}` | `http://localhost:5000/audit/events/{streamId}` | `http://audit-api:8080/api/audit/events/{streamId}` | `GET /api/audit/events/{streamId}` |

## Request Flow Example: Create Order

### Step 1: Frontend Makes Request
```typescript
// Customer SPA
const order = {
  customerId: '00000000-0000-0000-0000-000000000000',
  items: [...]
};
this.apiService.createOrder(order).subscribe(...);
```

### Step 2: HTTP Interceptor Adds Token
```
POST http://localhost:5000/orders
Headers:
  Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
  Content-Type: application/json
Body: { customerId: '...', items: [...] }
```

### Step 3: API Gateway Receives Request
```
Ocelot Gateway (Port 5000)
- Validates JWT token
- Checks rate limit
- Routes to orders-api
```

### Step 4: API Gateway Routes to Microservice
```
POST http://orders-api:8080/api/orders
Headers:
  Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
  Content-Type: application/json
Body: { customerId: '...', items: [...] }
```

### Step 5: Orders API Processes Request
```
Orders API (Port 8080)
- Validates JWT token
- Checks "orders.write" scope
- Creates order in SQL Server
- Publishes OrderCreated event to RabbitMQ
- Returns 201 Created with order details
```

### Step 6: Response Returned to Frontend
```
201 Created
{
  id: 'guid',
  customerId: '...',
  items: [...],
  status: 'Created',
  createdAt: '2025-10-26T...'
}
```

## Configuration Files

### Frontend Service Configuration
**Customer SPA**: `src/frontend/customer-spa/src/app/services/api.service.ts`
```typescript
private apiUrl = 'http://localhost:5000'; // API Gateway URL
```

**Admin PWA**: `src/frontend/admin-pwa/src/app/services/admin-api.service.ts`
```typescript
private apiUrl = 'http://localhost:5000'; // API Gateway URL
```

### API Gateway Configuration
**File**: `src/Gateway/Ocelot.Gateway/ocelot.json`
```json
{
  "Routes": [
    {
      "DownstreamPathTemplate": "/api/orders/{everything}",
      "DownstreamHostAndPorts": [{ "Host": "orders-api", "Port": 8080 }],
      "UpstreamPathTemplate": "/orders/{everything}"
    },
    {
      "DownstreamPathTemplate": "/api/inventory/{everything}",
      "DownstreamHostAndPorts": [{ "Host": "inventory-api", "Port": 8080 }],
      "UpstreamPathTemplate": "/inventory/{everything}"
    },
    {
      "DownstreamPathTemplate": "/api/audit/{everything}",
      "DownstreamHostAndPorts": [{ "Host": "audit-api", "Port": 8080 }],
      "UpstreamPathTemplate": "/audit/{everything}"
    },
    {
      "DownstreamPathTemplate": "/api/notifications/{everything}",
      "DownstreamHostAndPorts": [{ "Host": "notifications-api", "Port": 8080 }],
      "UpstreamPathTemplate": "/notifications/{everything}"
    }
  ]
}
```

## Summary

✅ **All frontend endpoints are correctly configured to use the API Gateway**

- Frontend applications call `http://localhost:5000`
- API Gateway routes requests to appropriate microservices
- HTTP Interceptors automatically add JWT tokens
- All requests are authenticated and authorized
- Rate limiting protects backend services

---

**Status**: Production Ready
**Last Updated**: 2025-10-26


# Frontend API Gateway Endpoints - Complete Guide

## ✅ Status: All Endpoints Configured and Ready

Both frontend applications are **fully configured** to call all APIs through the **API Gateway** at `http://localhost:5000`.

---

## 🎯 Quick Start

### 1. Access Customer SPA
```
URL: http://localhost:4200
Login: admin / Admin@123
```

### 2. Access Admin PWA
```
URL: http://localhost:4201
Login: admin / Admin@123
```

### 3. API Gateway
```
URL: http://localhost:5000
All requests go through this gateway
```

---

## 📊 Architecture Overview

```
Frontend Apps (4200, 4201)
        ↓
HTTP Interceptor (adds JWT token)
        ↓
API Gateway (5000)
        ↓
Microservices (5001-5004)
```

---

## 🔗 API Endpoints

### Orders API
```
GET    /orders                    # Get all orders
GET    /orders/{id}               # Get order by ID
POST   /orders                    # Create order
POST   /orders/{id}/confirm       # Confirm order
POST   /orders/{id}/cancel        # Cancel order
POST   /orders/{id}/ship          # Ship order
```

### Inventory API
```
GET    /inventory/products                    # Get all products
GET    /inventory/products/{id}               # Get product by ID
POST   /inventory/products                    # Create product
PUT    /inventory/products/{id}               # Update product
POST   /inventory/products/{id}/adjust        # Adjust quantity
DELETE /inventory/products/{id}               # Delete product
```

### Audit API
```
GET    /audit/events                         # Get all events
GET    /audit/events/{streamId}              # Get events by stream
GET    /audit/documents                      # Get all documents
GET    /audit/documents/{entity}             # Get documents by entity
POST   /audit/replay/{streamId}              # Replay events
```

### Notifications API
```
GET    /notifications/user/{userId}          # Get user notifications
GET    /notifications/{id}                   # Get notification
POST   /notifications                        # Send notification
POST   /notifications/{id}/mark-read         # Mark as read
```

---

## 📁 Frontend Service Files

### Customer SPA
**File**: `src/frontend/customer-spa/src/app/services/api.service.ts`

**Methods**:
- `getProducts()` - Get all products
- `getProduct(id)` - Get product by ID
- `getOrders()` - Get all orders
- `getOrder(id)` - Get order by ID
- `createOrder(order)` - Create new order
- `cancelOrder(id, reason)` - Cancel order

### Admin PWA
**File**: `src/frontend/admin-pwa/src/app/services/admin-api.service.ts`

**Methods**:
- `getAllOrders()` - Get all orders
- `getOrder(id)` - Get order by ID
- `confirmOrder(id)` - Confirm order
- `shipOrder(id, trackingNumber)` - Ship order
- `cancelOrder(id, reason)` - Cancel order
- `getAllProducts()` - Get all products
- `getProduct(id)` - Get product by ID
- `createProduct(product)` - Create product
- `updateProduct(id, product)` - Update product
- `adjustInventory(id, qty, reason)` - Adjust inventory
- `getAuditLogs()` - Get audit logs
- `getAuditLogsByEntity(entity)` - Get logs by entity
- `getEventStream(streamId)` - Get event stream

---

## 🔐 Authentication

### HTTP Interceptors
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

---

## 🧪 Testing Endpoints

### Get Authentication Token
```bash
curl -X POST http://localhost:8080/realms/microservices/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&client_id=orders-api&username=admin&password=Admin@123"
```

### Get All Orders
```bash
curl -X GET http://localhost:5000/orders \
  -H "Authorization: Bearer <token>"
```

### Create an Order
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

### Get All Products
```bash
curl -X GET http://localhost:5000/inventory/products \
  -H "Authorization: Bearer <token>"
```

### Get Audit Logs
```bash
curl -X GET http://localhost:5000/audit/documents \
  -H "Authorization: Bearer <token>"
```

---

## 📋 Configuration Files

### Frontend Services
- `src/frontend/customer-spa/src/app/services/api.service.ts`
  - Base URL: `http://localhost:5000`
  
- `src/frontend/admin-pwa/src/app/services/admin-api.service.ts`
  - Base URL: `http://localhost:5000`

### HTTP Interceptors
- `src/frontend/customer-spa/src/app/interceptors/auth.interceptor.ts`
- `src/frontend/admin-pwa/src/app/interceptors/auth.interceptor.ts`

### API Gateway
- `src/Gateway/Ocelot.Gateway/ocelot.json`
  - Routes all requests to microservices
  - Enforces JWT authentication
  - Implements rate limiting

---

## ✅ Verification Checklist

- ✅ Customer SPA configured to use `http://localhost:5000`
- ✅ Admin PWA configured to use `http://localhost:5000`
- ✅ HTTP Interceptors add JWT tokens automatically
- ✅ API Gateway routes all requests correctly
- ✅ Keycloak authentication working
- ✅ Rate limiting enabled
- ✅ All microservices accessible via gateway
- ✅ JWT token validation on all endpoints
- ✅ Scope-based authorization working

---

## 🚀 Next Steps

1. **Start All Services**
   ```bash
   docker-compose up -d
   ```

2. **Access Customer SPA**
   - URL: http://localhost:4200
   - Login: admin / Admin@123

3. **Test Order Creation**
   - Click "Create Order"
   - Fill in order details
   - Submit and verify success

4. **Access Admin PWA**
   - URL: http://localhost:4201
   - Login: admin / Admin@123

5. **Monitor Logs**
   ```bash
   docker logs api-gateway
   docker logs orders-api
   ```

---

## 📚 Related Documentation

- `FRONTEND_API_GATEWAY_ENDPOINTS.md` - Detailed endpoint configuration
- `FRONTEND_ENDPOINTS_SUMMARY.md` - Quick reference guide
- `API_ENDPOINT_MAPPING.md` - Complete endpoint mapping
- `AUTHENTICATION_INTERCEPTOR_FIXED.md` - HTTP interceptor details

---

## 🎉 Summary

All frontend endpoints are **correctly configured** to call APIs through the **API Gateway**:

✅ **Customer SPA** → API Gateway → Microservices
✅ **Admin PWA** → API Gateway → Microservices
✅ **HTTP Interceptors** → Automatic JWT token injection
✅ **API Gateway** → Request routing and authentication
✅ **Microservices** → Protected with JWT and scopes

**Status**: Production Ready
**Last Updated**: 2025-10-26


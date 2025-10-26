# Fixing 404 Errors - API Gateway Authentication

## Problem
When making requests to the API Gateway, you may see **404 Not Found** errors:
```
Request URL: http://localhost:5000/inventory/products
Request Method: POST
Status Code: 404 Not Found
```

## Root Cause
The API Gateway requires **JWT authentication** for all routes. Requests without a valid token are rejected.

---

## Solution: Add Authentication Token

### Step 1: Get Authentication Token

```bash
curl -X POST http://localhost:8080/realms/microservices/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&client_id=orders-api&username=admin&password=Admin@123"
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cC...",
  "expires_in": 300,
  "refresh_expires_in": 1800,
  "token_type": "Bearer"
}
```

### Step 2: Use Token in API Requests

```bash
# Get all products
curl -X GET http://localhost:5000/inventory/products \
  -H "Authorization: Bearer <your_token_here>"

# Create new product
curl -X POST http://localhost:5000/inventory/products \
  -H "Authorization: Bearer <your_token_here>" \
  -H "Content-Type: application/json" \
  -d '{
    "sku": "TEST-001",
    "name": "Test Product",
    "description": "A test product",
    "quantity": 100,
    "lowStockThreshold": 10,
    "price": 99.99
  }'

# Get all orders
curl -X GET http://localhost:5000/orders \
  -H "Authorization: Bearer <your_token_here>"

# Create new order
curl -X POST http://localhost:5000/orders \
  -H "Authorization: Bearer <your_token_here>" \
  -H "Content-Type: application/json" \
  -d '{
    "customerId": "00000000-0000-0000-0000-000000000001",
    "items": [
      {
        "productId": "10000000-0000-0000-0000-000000000001",
        "productName": "Dell XPS 13",
        "quantity": 1,
        "unitPrice": 1299.99
      }
    ]
  }'
```

---

## Why This Happens

### API Gateway Configuration
The Ocelot API Gateway is configured to require authentication:

```json
{
  "Routes": [
    {
      "UpstreamPathTemplate": "/inventory/{everything}",
      "AuthenticationOptions": {
        "AuthenticationProviderKey": "Keycloak",
        "AllowedScopes": []
      }
    }
  ]
}
```

### Authentication Flow
```
1. Client makes request without token
   ↓
2. API Gateway checks for Authorization header
   ↓
3. No token found → 401 Unauthorized
   ↓
4. Browser/Client redirects to Keycloak login
   ↓
5. User logs in and gets JWT token
   ↓
6. Client includes token in Authorization header
   ↓
7. API Gateway validates token
   ↓
8. Request forwarded to microservice
   ↓
9. Microservice validates token and processes request
```

---

## Frontend Applications (Automatic)

The Angular frontends handle authentication automatically:

1. **HTTP Interceptor** automatically adds JWT token to all requests
2. **Keycloak Angular Module** handles login/logout
3. **Silent SSO** redirects to Keycloak if not authenticated

### How It Works in Frontend

```typescript
// HTTP Interceptor automatically adds token
intercept(request: HttpRequest<unknown>, next: HttpHandler) {
  const token = this.keycloakService.getToken();
  if (token) {
    request = request.clone({
      setHeaders: {
        Authorization: `Bearer ${token}`
      }
    });
  }
  return next.handle(request);
}
```

---

## Testing with Postman

### 1. Get Token
- **Method**: POST
- **URL**: `http://localhost:8080/realms/microservices/protocol/openid-connect/token`
- **Headers**: `Content-Type: application/x-www-form-urlencoded`
- **Body**:
  ```
  grant_type=password
  client_id=orders-api
  username=admin
  password=Admin@123
  ```

### 2. Use Token
- **Method**: GET
- **URL**: `http://localhost:5000/inventory/products`
- **Headers**: `Authorization: Bearer <token>`

---

## Test Credentials

| Role | Username | Password |
|------|----------|----------|
| Admin | admin | Admin@123 |
| User | user | User@123 |
| Orders Manager | orders-manager | Orders@123 |
| Inventory Manager | inventory-manager | Inventory@123 |

---

## Common Issues

### Issue 1: Invalid Credentials
```
Error: Invalid user credentials
```
**Solution**: Check username and password are correct

### Issue 2: Token Expired
```
Error: Token expired
```
**Solution**: Get a new token (tokens expire after 5 minutes)

### Issue 3: Invalid Scope
```
Error: Insufficient permissions
```
**Solution**: User doesn't have required scope for the operation

### Issue 4: CORS Error
```
Error: CORS policy blocked request
```
**Solution**: This is normal for browser requests - frontends handle it automatically

---

## Direct API Access (Bypass Gateway)

If you need to bypass the gateway for testing:

```bash
# Direct to Orders API (no gateway)
curl -X GET http://localhost:5001/api/orders \
  -H "Authorization: Bearer <token>"

# Direct to Inventory API (no gateway)
curl -X GET http://localhost:5002/api/inventory/products \
  -H "Authorization: Bearer <token>"
```

---

## Summary

✅ **Always include JWT token** in Authorization header
✅ **Token format**: `Bearer <token>`
✅ **Get token from Keycloak** at `/realms/microservices/protocol/openid-connect/token`
✅ **Frontends handle automatically** via HTTP Interceptor
✅ **Tokens expire after 5 minutes** - get new one if needed

---

**Status**: Ready for Testing
**Last Updated**: 2025-10-26


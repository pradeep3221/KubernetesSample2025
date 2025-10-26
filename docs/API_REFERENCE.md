# API Reference

> **Complete API Endpoints and Integration Guide**

---

## Table of Contents

1. [Overview](#overview)
2. [API Gateway](#api-gateway)
3. [Orders API](#orders-api)
4. [Inventory API](#inventory-api)
5. [Notifications API](#notifications-api)
6. [Audit API](#audit-api)
7. [Request/Response Examples](#requestresponse-examples)
8. [Error Handling](#error-handling)

---

## Overview

### Base URLs

| Service | URL | Port |
|---------|-----|------|
| **API Gateway** | http://localhost:5000 | 5000 |
| Orders API | http://localhost:5001 | 5001 |
| Inventory API | http://localhost:5002 | 5002 |
| Notifications API | http://localhost:5003 | 5003 |
| Audit API | http://localhost:5004 | 5004 |

### Authentication

All endpoints require JWT Bearer token in Authorization header:

```
Authorization: Bearer <token>
```

### Content Type

All requests and responses use JSON:

```
Content-Type: application/json
```

---

## API Gateway

**Base URL**: `http://localhost:5000`

The API Gateway routes all requests to appropriate microservices.

### Routes

| Path | Service | Description |
|------|---------|-------------|
| `/orders/*` | Orders API | Order management |
| `/inventory/*` | Inventory API | Product and inventory management |
| `/notifications/*` | Notifications API | Notification management |
| `/audit/*` | Audit API | Audit logs and event sourcing |

---

## Orders API

**Base URL**: `http://localhost:5001/api/orders`

### Endpoints

#### Get All Orders
```
GET /api/orders
```

**Response:**
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "orderNumber": "ORD-2025-001",
    "customerId": "550e8400-e29b-41d4-a716-446655440001",
    "status": "Confirmed",
    "totalAmount": 1399.98,
    "createdAt": "2025-01-20T10:30:00Z",
    "confirmedAt": "2025-01-20T10:35:00Z",
    "items": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440002",
        "productId": "550e8400-e29b-41d4-a716-446655440003",
        "productName": "Dell XPS 13",
        "quantity": 1,
        "unitPrice": 1299.99
      }
    ]
  }
]
```

#### Get Order by ID
```
GET /api/orders/{id}
```

#### Create Order
```
POST /api/orders
Content-Type: application/json

{
  "customerId": "550e8400-e29b-41d4-a716-446655440001",
  "items": [
    {
      "productId": "550e8400-e29b-41d4-a716-446655440003",
      "productName": "Dell XPS 13",
      "quantity": 1,
      "unitPrice": 1299.99
    }
  ]
}
```

#### Confirm Order
```
POST /api/orders/{id}/confirm
```

#### Cancel Order
```
POST /api/orders/{id}/cancel
Content-Type: application/json

{
  "reason": "Customer requested cancellation"
}
```

#### Ship Order
```
POST /api/orders/{id}/ship
Content-Type: application/json

{
  "trackingNumber": "TRACK-2025-001"
}
```

---

## Inventory API

**Base URL**: `http://localhost:5002/api/inventory`

### Endpoints

#### Get All Products
```
GET /api/inventory/products
```

#### Get Product by ID
```
GET /api/inventory/products/{id}
```

#### Get Product by SKU
```
GET /api/inventory/products/sku/{sku}
```

#### Get Low Stock Products
```
GET /api/inventory/products/low-stock
```

#### Create Product
```
POST /api/inventory/products
Content-Type: application/json

{
  "sku": "LAPTOP-002",
  "name": "MacBook Pro",
  "description": "High-performance laptop",
  "quantity": 25,
  "lowStockThreshold": 5,
  "price": 1999.99
}
```

#### Update Product
```
PUT /api/inventory/products/{id}
Content-Type: application/json

{
  "name": "MacBook Pro M3",
  "description": "Updated description",
  "price": 2099.99
}
```

#### Adjust Inventory
```
POST /api/inventory/products/{id}/adjust
Content-Type: application/json

{
  "quantity": -5,
  "reason": "Sold 5 units"
}
```

#### Delete Product
```
DELETE /api/inventory/products/{id}
```

---

## Notifications API

**Base URL**: `http://localhost:5003/api/notifications`

### Endpoints

#### Get User Notifications
```
GET /api/notifications/user/{userId}
```

#### Get Notification by ID
```
GET /api/notifications/{id}
```

#### Send Notification
```
POST /api/notifications
Content-Type: application/json

{
  "userId": "550e8400-e29b-41d4-a716-446655440001",
  "type": "Email",
  "title": "Order Confirmation",
  "message": "Your order has been confirmed",
  "data": {
    "orderId": "550e8400-e29b-41d4-a716-446655440000"
  }
}
```

#### Mark Notification as Read
```
POST /api/notifications/{id}/mark-read
```

---

## Audit API

**Base URL**: `http://localhost:5004/api/audit`

### Endpoints

#### Get All Events
```
GET /api/audit/events
```

#### Get Events by Stream
```
GET /api/audit/events/{streamId}
```

#### Get All Audit Documents
```
GET /api/audit/documents
```

#### Get Audit Documents by Entity
```
GET /api/audit/documents/{entity}
```

#### Replay Events
```
POST /api/audit/replay/{streamId}
```

---

## Request/Response Examples

### Example 1: Create Order via API Gateway

**Request:**
```bash
curl -X POST http://localhost:5000/orders \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "customerId": "550e8400-e29b-41d4-a716-446655440001",
    "items": [
      {
        "productId": "550e8400-e29b-41d4-a716-446655440003",
        "productName": "Dell XPS 13",
        "quantity": 1,
        "unitPrice": 1299.99
      }
    ]
  }'
```

**Response (201 Created):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "orderNumber": "ORD-2025-001",
  "customerId": "550e8400-e29b-41d4-a716-446655440001",
  "status": "Pending",
  "totalAmount": 1299.99,
  "createdAt": "2025-01-26T14:30:00Z",
  "items": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440002",
      "productId": "550e8400-e29b-41d4-a716-446655440003",
      "productName": "Dell XPS 13",
      "quantity": 1,
      "unitPrice": 1299.99
    }
  ]
}
```

### Example 2: Get Products

**Request:**
```bash
curl -X GET http://localhost:5000/inventory/products \
  -H "Authorization: Bearer <token>"
```

**Response (200 OK):**
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440003",
    "sku": "LAPTOP-001",
    "name": "Dell XPS 13",
    "description": "High-performance ultrabook",
    "quantity": 50,
    "reservedQuantity": 5,
    "lowStockThreshold": 10,
    "price": 1299.99,
    "createdAt": "2025-01-20T10:00:00Z"
  }
]
```

---

## Error Handling

### HTTP Status Codes

| Code | Meaning |
|------|---------|
| 200 | OK - Request successful |
| 201 | Created - Resource created |
| 204 | No Content - Successful, no response body |
| 400 | Bad Request - Invalid input |
| 401 | Unauthorized - Missing or invalid token |
| 403 | Forbidden - Insufficient permissions |
| 404 | Not Found - Resource not found |
| 409 | Conflict - Resource conflict |
| 500 | Internal Server Error - Server error |

### Error Response Format

```json
{
  "type": "https://tools.ietf.org/html/rfc7231#section-6.5.1",
  "title": "Bad Request",
  "status": 400,
  "detail": "The request body is invalid",
  "instance": "/api/orders"
}
```

### Common Errors

#### 401 Unauthorized
```json
{
  "status": 401,
  "title": "Unauthorized",
  "detail": "Missing or invalid authentication token"
}
```

#### 404 Not Found
```json
{
  "status": 404,
  "title": "Not Found",
  "detail": "Order with ID 'abc-123' not found"
}
```

#### 409 Conflict
```json
{
  "status": 409,
  "title": "Conflict",
  "detail": "Cannot confirm order that is already shipped"
}
```

---

**API Reference is complete and production-ready!** 🚀


# 🚀 Quick Reference: Frontends & Keycloak

## 🌐 Access URLs

| Service | URL | Purpose |
|---------|-----|---------|
| **Customer SPA** | http://localhost:4200 | Customer-facing application |
| **Admin PWA** | http://localhost:4201 | Admin management console |
| **Keycloak Admin** | http://localhost:8080/admin | Identity management |
| **API Gateway** | http://localhost:5000 | Backend API entry point |

---

## 🔐 Test Credentials

| User | Username | Password | Role |
|------|----------|----------|------|
| Admin | `admin` | `Admin@123` | admin |
| Regular User | `user` | `User@123` | user |
| Orders Manager | `orders-manager` | `Orders@123` | orders-manager |
| Inventory Manager | `inventory-manager` | `Inventory@123` | inventory-manager |

---

## 🎯 Quick Start

### 1. Start All Services
```bash
docker-compose up -d
```

### 2. Access Customer SPA
```
http://localhost:4200
```

### 3. Login
- Click "Login" button
- Enter credentials: `admin` / `Admin@123`
- You'll be redirected to Keycloak login page
- After login, you'll return to the app with a JWT token

### 4. Access Admin PWA
```
http://localhost:4201
```

### 5. Manage Users in Keycloak
```
http://localhost:8080/admin
```
- Username: `admin`
- Password: `admin`

---

## 📋 Keycloak Clients

### Customer SPA
- **Client ID**: `customer-spa`
- **Type**: Public (SPA)
- **Redirect URI**: `http://localhost:4200/*`
- **Status**: ✅ Configured

### Admin PWA
- **Client ID**: `admin-pwa`
- **Type**: Public (SPA)
- **Redirect URI**: `http://localhost:4201/*`
- **Status**: ✅ Configured

### API Clients
- **orders-api** - Orders microservice
- **inventory-api** - Inventory microservice
- **notifications-api** - Notifications microservice
- **audit-api** - Audit microservice
- **api-gateway** - Ocelot API Gateway

---

## 🔄 OAuth2 Flow

```
1. User clicks "Login" on frontend
   ↓
2. Frontend redirects to Keycloak
   ↓
3. User enters credentials
   ↓
4. Keycloak validates and returns JWT token
   ↓
5. Frontend stores token (localStorage/sessionStorage)
   ↓
6. Frontend redirects back to app
   ↓
7. Frontend includes token in API requests
   Authorization: Bearer <JWT_TOKEN>
   ↓
8. API Gateway validates token with Keycloak
   ↓
9. API Gateway routes to microservice
   ↓
10. Microservice checks authorization scopes
```

---

## 🛠️ Common Tasks

### View Keycloak Logs
```bash
docker logs keycloak -f
```

### View Frontend Logs
```bash
docker logs customer-spa -f
docker logs admin-pwa -f
```

### View API Gateway Logs
```bash
docker logs api-gateway -f
```

### Restart Services
```bash
docker-compose restart customer-spa admin-pwa keycloak
```

### Rebuild Frontends
```bash
docker-compose build --no-cache customer-spa admin-pwa
docker-compose up -d customer-spa admin-pwa
```

---

## 🔍 Troubleshooting

### "Realm not enabled" Error
**Solution**: Run the setup script
```bash
.\scripts\setup-keycloak.ps1
```

### "Invalid redirect URI" Error
**Solution**: Check Keycloak client configuration
1. Go to http://localhost:8080/admin
2. Select realm: `microservices`
3. Go to Clients
4. Select `customer-spa` or `admin-pwa`
5. Verify Redirect URIs match your frontend URL

### Frontend Can't Connect to API
**Solution**: Check API Gateway
1. Verify API Gateway is running: `docker-compose ps api-gateway`
2. Check logs: `docker logs api-gateway`
3. Verify Keycloak is running: `docker-compose ps keycloak`

### Token Expired
**Solution**: Logout and login again
- Tokens expire after 1 hour
- Refresh tokens expire after 24 hours
- Frontend should handle token refresh automatically

---

## 📊 Service Status

Check all services:
```bash
docker-compose ps
```

Expected output:
```
NAME                COMMAND                  SERVICE             STATUS
customer-spa        "nginx -g daemon off"    customer-spa        Up
admin-pwa           "nginx -g daemon off"    admin-pwa           Up
api-gateway         "dotnet Ocelot.Gate..."  api-gateway         Up
keycloak            "start-dev"              keycloak            Up
postgres            "docker-entrypoint..."   postgres            Up
rabbitmq            "docker-entrypoint..."   rabbitmq            Up
...
```

---

## 🎓 Learn More

- **Keycloak Docs**: https://www.keycloak.org/documentation
- **OAuth2 Flow**: https://tools.ietf.org/html/rfc6749
- **Angular Security**: https://angular.io/guide/security
- **JWT Tokens**: https://jwt.io

---

## ✅ Checklist

- [ ] All services running (`docker-compose ps`)
- [ ] Keycloak accessible (http://localhost:8080)
- [ ] Customer SPA accessible (http://localhost:4200)
- [ ] Admin PWA accessible (http://localhost:4201)
- [ ] Can login with test credentials
- [ ] API Gateway accessible (http://localhost:5000)
- [ ] Can call APIs with JWT token

---

**Last Updated**: 2025-10-26  
**Status**: ✅ All systems operational


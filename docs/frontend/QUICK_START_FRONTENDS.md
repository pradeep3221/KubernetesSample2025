# Quick Start - Frontends

## 🚀 Start Everything

```bash
# Start all services (microservices + frontends + infrastructure)
docker-compose up -d

# Wait for services to be ready (~30-60 seconds)
```

## 🌐 Access Frontends

### Customer SPA
- **URL**: http://localhost:4200
- **Purpose**: Customer-facing application
- **Type**: Single Page Application (SPA)

### Admin PWA
- **URL**: http://localhost:4201
- **Purpose**: Admin dashboard
- **Type**: Progressive Web App (PWA)

### API Gateway
- **URL**: http://localhost:5000
- **Purpose**: API routing and authentication

### Keycloak
- **URL**: http://localhost:8080
- **Admin Console**: http://localhost:8080/admin
- **Username**: admin
- **Password**: admin

## 📊 Monitor Services

```bash
# View all running services
docker-compose ps

# View logs for specific service
docker-compose logs -f customer-spa
docker-compose logs -f admin-pwa

# View all logs
docker-compose logs -f
```

## 🔧 Build Commands

```bash
# Build all services
docker-compose build

# Build only frontends
docker-compose build customer-spa admin-pwa

# Build specific frontend
docker-compose build customer-spa
docker-compose build admin-pwa

# Rebuild without cache
docker-compose build --no-cache customer-spa
docker-compose build --no-cache admin-pwa
```

## 🛑 Stop Services

```bash
# Stop all services
docker-compose stop

# Stop specific services
docker-compose stop customer-spa admin-pwa

# Stop and remove containers
docker-compose down

# Stop and remove everything (including volumes)
docker-compose down -v
```

## 🔄 Restart Services

```bash
# Restart all services
docker-compose restart

# Restart specific services
docker-compose restart customer-spa admin-pwa

# Restart with rebuild
docker-compose up -d --build customer-spa admin-pwa
```

## 📝 Test Users

### Admin User
- **Username**: admin
- **Password**: Admin@123
- **Role**: admin

### Regular User
- **Username**: user
- **Password**: User@123
- **Role**: user

### Orders Manager
- **Username**: orders-manager
- **Password**: Orders@123
- **Role**: orders-manager

### Inventory Manager
- **Username**: inventory-manager
- **Password**: Inventory@123
- **Role**: inventory-manager

## 🔐 Authentication Flow

1. Open frontend (http://localhost:4200 or http://localhost:4201)
2. Click "Login" button
3. Redirected to Keycloak login page
4. Enter credentials (e.g., admin / Admin@123)
5. Redirected back to frontend with JWT token
6. Token stored in browser (localStorage/sessionStorage)
7. API calls include token in Authorization header

## 📱 Frontend Features

### Customer SPA
- Browse products/orders
- View order history
- Track shipments
- Manage profile

### Admin PWA
- Dashboard with analytics
- Order management
- Inventory management
- Audit logs
- User management
- Works offline (PWA)

## 🐛 Troubleshooting

### Frontends not accessible
```bash
# Check if containers are running
docker-compose ps

# Check logs
docker-compose logs customer-spa
docker-compose logs admin-pwa

# Restart containers
docker-compose restart customer-spa admin-pwa
```

### Port already in use
```bash
# Find process using port
netstat -ano | findstr :4200
netstat -ano | findstr :4201

# Kill process (Windows)
taskkill /PID <PID> /F

# Or change ports in docker-compose.yml
```

### Build fails
```bash
# Clear Docker cache
docker system prune -a

# Rebuild
docker-compose build --no-cache customer-spa admin-pwa
```

### Nginx configuration error
```bash
# Test nginx config
docker exec customer-spa nginx -t
docker exec admin-pwa nginx -t

# View nginx logs
docker logs customer-spa
docker logs admin-pwa
```

## 📊 Service Ports

| Service | Port | URL |
|---------|------|-----|
| Customer SPA | 4200 | http://localhost:4200 |
| Admin PWA | 4201 | http://localhost:4201 |
| API Gateway | 5000 | http://localhost:5000 |
| Keycloak | 8080 | http://localhost:8080 |
| Prometheus | 9090 | http://localhost:9090 |
| Grafana | 3000 | http://localhost:3000 |
| Loki | 3100 | http://localhost:3100 |
| Tempo | 3200 | http://localhost:3200 |

## 🔗 API Endpoints

### Orders API
- Base: http://api-gateway:8080/orders
- Requires: orders.read, orders.write scopes

### Inventory API
- Base: http://api-gateway:8080/inventory
- Requires: inventory.read, inventory.write scopes

### Notifications API
- Base: http://api-gateway:8080/notifications
- Requires: notifications.read, notifications.write scopes

### Audit API
- Base: http://api-gateway:8080/audit
- Requires: audit.read, audit.write scopes

## 📚 Documentation

- **Keycloak Setup**: See `KEYCLOAK_SETUP_COMPLETE.md`
- **Frontends Details**: See `FRONTENDS_ADDED_TO_DOCKER_COMPOSE.md`
- **Microservices**: See `README.md` in each service folder
- **Docker Compose**: See `docker-compose.yml`

## ✅ Verification Checklist

- [ ] All services started: `docker-compose ps`
- [ ] Customer SPA accessible: http://localhost:4200
- [ ] Admin PWA accessible: http://localhost:4201
- [ ] Keycloak accessible: http://localhost:8080
- [ ] Can login with test user
- [ ] API calls working
- [ ] Logs show no errors

## 🎯 Next Steps

1. Start the full stack
2. Access frontends
3. Login with test credentials
4. Test API integration
5. Monitor with Grafana
6. Deploy to Kubernetes (optional)

---

**Total Services**: 19 containers  
**Total Ports**: 8 exposed ports  
**Status**: ✅ Ready for Development


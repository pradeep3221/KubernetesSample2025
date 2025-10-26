# Troubleshooting Guide

> **Common Issues and Solutions**

---

## Table of Contents

1. [Docker Issues](#docker-issues)
2. [Service Startup Issues](#service-startup-issues)
3. [Database Issues](#database-issues)
4. [API Issues](#api-issues)
5. [Authentication Issues](#authentication-issues)
6. [Observability Issues](#observability-issues)
7. [Performance Issues](#performance-issues)
8. [Getting Help](#getting-help)

---

## Docker Issues

### Issue: Docker Daemon Not Running

**Error:**
```
Cannot connect to Docker daemon
```

**Solution:**
```bash
# Start Docker Desktop (on Windows/Mac)
# Or start Docker daemon (on Linux)
sudo systemctl start docker

# Verify Docker is running
docker ps
```

### Issue: Port Already in Use

**Error:**
```
Error response from daemon: Ports are not available: exposing port TCP 0.0.0.0:5000 -> 0.0.0.0:0: listen tcp 0.0.0.0:5000: bind: address already in use
```

**Solution:**
```bash
# Find process using port
lsof -i :5000

# Kill process
kill -9 <PID>

# Or change port in docker-compose.yml
# Change "5000:8080" to "5001:8080"
```

### Issue: Out of Disk Space

**Error:**
```
no space left on device
```

**Solution:**
```bash
# Clean up Docker
docker system prune -a

# Remove unused volumes
docker volume prune

# Check disk space
df -h
```

### Issue: Out of Memory

**Error:**
```
OOMKilled
```

**Solution:**
```bash
# Increase Docker memory allocation
# Docker Desktop → Preferences → Resources → Memory: 16GB

# Or reduce number of services
docker-compose up -d orders-api inventory-api
```

---

## Service Startup Issues

### Issue: Services Not Starting

**Error:**
```
docker-compose up -d
# Services exit immediately
```

**Solution:**
```bash
# Check logs
docker-compose logs

# Rebuild images
docker-compose build --no-cache

# Restart services
docker-compose restart

# Check specific service logs
docker-compose logs orders-api
```

### Issue: Service Stuck in Starting State

**Error:**
```
docker-compose ps
# Service shows "starting" for 5+ minutes
```

**Solution:**
```bash
# Check logs
docker-compose logs -f orders-api

# Stop and remove container
docker-compose stop orders-api
docker-compose rm orders-api

# Restart
docker-compose up -d orders-api
```

### Issue: Health Check Failing

**Error:**
```
docker-compose ps
# Service shows "unhealthy"
```

**Solution:**
```bash
# Check logs
docker-compose logs orders-api

# Verify dependencies are running
docker-compose ps

# Restart dependencies first
docker-compose restart postgres sql-server redis rabbitmq

# Then restart service
docker-compose restart orders-api
```

---

## Database Issues

### Issue: PostgreSQL Connection Failed

**Error:**
```
Npgsql.NpgsqlException: Unable to connect to any of the specified hosts
```

**Solution:**
```bash
# Check PostgreSQL is running
docker-compose ps postgres

# Check logs
docker-compose logs postgres

# Verify connection string
docker-compose exec orders-api env | grep CONNECTION

# Restart PostgreSQL
docker-compose restart postgres

# Wait for startup
sleep 10
docker-compose restart inventory-api audit-api
```

### Issue: SQL Server Connection Failed

**Error:**
```
System.Data.SqlClient.SqlException: A network-related or instance-specific error
```

**Solution:**
```bash
# Check SQL Server is running
docker-compose ps sql-server

# Check logs
docker-compose logs sql-server

# Verify connection string
docker-compose exec orders-api env | grep CONNECTION

# Restart SQL Server
docker-compose restart sql-server

# Wait for startup (SQL Server takes longer)
sleep 30
docker-compose restart orders-api
```

### Issue: Database Migrations Failed

**Error:**
```
[ERR] Running database migrations...
[ERR] Database migrations failed
```

**Solution:**
```bash
# Check logs for specific error
docker-compose logs orders-api | grep -i migration

# Verify database exists
docker-compose exec postgres psql -U postgres -l

# Recreate database
docker-compose exec postgres dropdb inventory_db
docker-compose exec postgres createdb inventory_db

# Restart service
docker-compose restart inventory-api
```

---

## API Issues

### Issue: 404 Not Found

**Error:**
```
GET http://localhost:5000/orders
Response: 404 Not Found
```

**Solution:**
```bash
# Check API Gateway is running
docker-compose ps api-gateway

# Check route configuration
docker-compose exec api-gateway cat /app/ocelot.json

# Verify microservice is running
docker-compose ps orders-api

# Check API Gateway logs
docker-compose logs api-gateway

# Try direct service access
curl http://localhost:5001/api/orders
```

### Issue: 500 Internal Server Error

**Error:**
```
GET http://localhost:5000/orders
Response: 500 Internal Server Error
```

**Solution:**
```bash
# Check service logs
docker-compose logs orders-api

# Look for specific error message
docker-compose logs orders-api | grep -i error

# Check database connectivity
docker-compose logs orders-api | grep -i database

# Restart service
docker-compose restart orders-api
```

### Issue: Timeout

**Error:**
```
Request timeout after 30 seconds
```

**Solution:**
```bash
# Check service is responding
curl -v http://localhost:5001/health

# Check service logs for slow operations
docker-compose logs orders-api

# Check resource usage
docker stats

# Increase timeout in client code
# Or restart service
docker-compose restart orders-api
```

---

## Authentication Issues

### Issue: 401 Unauthorized

**Error:**
```
GET http://localhost:5000/orders
Response: 401 Unauthorized
```

**Solution:**
```bash
# Get token from Keycloak
TOKEN=$(curl -s -X POST http://localhost:8080/realms/microservices/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&client_id=orders-api&username=admin&password=Admin@123" | jq -r '.access_token')

# Use token in request
curl -H "Authorization: Bearer $TOKEN" http://localhost:5000/orders

# Check Keycloak is running
docker-compose ps keycloak

# Check Keycloak logs
docker-compose logs keycloak
```

### Issue: Invalid Credentials

**Error:**
```
Error: Invalid user credentials
```

**Solution:**
```bash
# Verify test user exists in Keycloak
# Go to http://localhost:8080/admin
# Login with admin/admin
# Check Users section

# Verify credentials
# Username: admin
# Password: Admin@123

# Create user if missing
# Users → Add user → Set password
```

### Issue: Token Expired

**Error:**
```
Error: Token expired
```

**Solution:**
```bash
# Get new token
TOKEN=$(curl -s -X POST http://localhost:8080/realms/microservices/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&client_id=orders-api&username=admin&password=Admin@123" | jq -r '.access_token')

# Use new token
curl -H "Authorization: Bearer $TOKEN" http://localhost:5000/orders
```

---

## Observability Issues

### Issue: Logs Not Appearing in Loki

**Error:**
```
No logs in Grafana Loki
```

**Solution:**
```bash
# Check Loki is running
docker-compose ps loki

# Check Loki endpoint
curl http://localhost:3100/ready

# Verify environment variable
docker-compose exec orders-api env | grep LOKI

# Check service logs
docker-compose logs orders-api | grep -i loki

# Restart Loki
docker-compose restart loki
```

### Issue: Metrics Not Appearing in Prometheus

**Error:**
```
No metrics in Prometheus
```

**Solution:**
```bash
# Check Prometheus is running
docker-compose ps prometheus

# Check Prometheus config
docker-compose exec prometheus cat /etc/prometheus/prometheus.yml

# Verify scrape targets
curl http://localhost:9090/api/v1/targets

# Check service metrics endpoint
curl http://localhost:5001/metrics

# Restart Prometheus
docker-compose restart prometheus
```

### Issue: Traces Not Appearing in Tempo

**Error:**
```
No traces in Grafana Tempo
```

**Solution:**
```bash
# Check Tempo is running
docker-compose ps tempo

# Check OpenTelemetry Collector is running
docker-compose ps otel-collector

# Verify OTLP endpoint
curl http://localhost:4317

# Check service logs for OTLP errors
docker-compose logs orders-api | grep -i otlp

# Restart services
docker-compose restart otel-collector tempo
```

---

## Performance Issues

### Issue: Slow API Responses

**Error:**
```
API responses taking > 5 seconds
```

**Solution:**
```bash
# Check resource usage
docker stats

# Check service logs for slow queries
docker-compose logs orders-api | grep -i slow

# Check database performance
docker-compose exec postgres psql -U postgres -d inventory_db -c "SELECT * FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;"

# Restart service
docker-compose restart orders-api

# Scale service
docker-compose up -d --scale orders-api=3
```

### Issue: High Memory Usage

**Error:**
```
Service using > 1GB memory
```

**Solution:**
```bash
# Check memory usage
docker stats

# Check for memory leaks in logs
docker-compose logs orders-api | grep -i memory

# Restart service
docker-compose restart orders-api

# Increase Docker memory allocation
# Docker Desktop → Preferences → Resources → Memory: 16GB
```

---

## Getting Help

### Useful Commands

```bash
# View all logs
docker-compose logs

# View logs for specific service
docker-compose logs -f orders-api

# View last 100 lines
docker-compose logs --tail=100 orders-api

# Check service status
docker-compose ps

# Check resource usage
docker stats

# Execute command in container
docker-compose exec orders-api bash

# View environment variables
docker-compose exec orders-api env

# Check network connectivity
docker-compose exec orders-api ping inventory-api
```

### Debug Mode

```bash
# Enable debug logging
docker-compose exec orders-api env | grep LOG_LEVEL

# Set log level to Debug
docker-compose exec orders-api bash
export ASPNETCORE_ENVIRONMENT=Development
```

### Support Resources

1. **Check Documentation**
   - ARCHITECTURE_GUIDE.md - System design
   - SETUP_GUIDE.md - Installation
   - API_REFERENCE.md - API endpoints

2. **Check Logs**
   - Docker logs: `docker-compose logs`
   - Service logs: `docker-compose logs <service>`
   - Grafana Loki: http://localhost:3000

3. **Check Health**
   - Service status: `docker-compose ps`
   - Health endpoints: `curl http://localhost:5001/health`
   - Prometheus: http://localhost:9090

---

**Troubleshooting guide is comprehensive and helpful!** 🔧


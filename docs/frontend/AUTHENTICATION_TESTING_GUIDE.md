# 🔐 Authentication Testing Guide

## Overview

This guide walks you through testing the complete OAuth2/OIDC authentication flow with Keycloak and the Angular frontends.

---

## 🚀 Quick Start

### 1. Verify All Services Are Running
```bash
docker-compose ps
```

Expected services:
- ✅ customer-spa (port 4200)
- ✅ admin-pwa (port 4201)
- ✅ keycloak (port 8080)
- ✅ api-gateway (port 5000)
- ✅ postgres, rabbitmq, redis, etc.

### 2. Test Customer SPA
```
http://localhost:4200
```

### 3. Test Admin PWA
```
http://localhost:4201
```

---

## 🔐 Test Credentials

| User | Username | Password | Role | Purpose |
|------|----------|----------|------|---------|
| Admin | `admin` | `Admin@123` | admin | Full access |
| User | `user` | `User@123` | user | Limited access |
| Orders Manager | `orders-manager` | `Orders@123` | orders-manager | Orders management |
| Inventory Manager | `inventory-manager` | `Inventory@123` | inventory-manager | Inventory management |

---

## 📋 Test Scenarios

### Scenario 1: Customer SPA Login (Optional SSO)

**Steps:**
1. Open http://localhost:4200
2. You should see the Customer Portal homepage
3. Click "Login" button
4. You'll be redirected to Keycloak login page
5. Enter credentials: `admin` / `Admin@123`
6. Click "Sign In"
7. You'll be redirected back to http://localhost:4200
8. You should see authenticated user interface

**Expected Results:**
- ✅ Login page loads
- ✅ Credentials accepted
- ✅ Redirect back to app
- ✅ User info displayed
- ✅ JWT token stored in browser

**Verification:**
- Open browser DevTools (F12)
- Go to Application → Local Storage
- Look for `keycloak-token` or similar
- Check Console for any errors

---

### Scenario 2: Admin PWA Login (Required SSO)

**Steps:**
1. Open http://localhost:4201
2. You'll be immediately redirected to Keycloak login
3. Enter credentials: `admin` / `Admin@123`
4. Click "Sign In"
5. You'll be redirected back to http://localhost:4201
6. You should see the Admin Dashboard

**Expected Results:**
- ✅ Immediate redirect to login
- ✅ Login page loads
- ✅ Credentials accepted
- ✅ Dashboard loads
- ✅ All admin features accessible

**Verification:**
- Check browser console for errors
- Verify dashboard components load
- Check network tab for API calls

---

### Scenario 3: API Integration

**Steps:**
1. Login to Customer SPA (http://localhost:4200)
2. Navigate to Orders section
3. Try to fetch orders
4. Check if data loads

**Expected Results:**
- ✅ API calls include JWT token
- ✅ API Gateway validates token
- ✅ Microservice returns data
- ✅ Data displayed in UI

**Verification:**
- Open DevTools Network tab
- Look for API calls to http://localhost:5000
- Check Authorization header contains Bearer token
- Verify response status is 200

---

### Scenario 4: Token Expiration

**Steps:**
1. Login to app
2. Wait for token to expire (1 hour)
3. Try to make API call
4. App should refresh token automatically

**Expected Results:**
- ✅ Token refreshed automatically
- ✅ API call succeeds
- ✅ No manual re-login needed

**Verification:**
- Check browser console
- Look for token refresh requests
- Verify new token is obtained

---

### Scenario 5: Logout

**Steps:**
1. Login to app
2. Click "Logout" button
3. You should be logged out
4. Try to access protected page
5. You should be redirected to login

**Expected Results:**
- ✅ Logout successful
- ✅ Token cleared
- ✅ Redirect to login
- ✅ Protected pages inaccessible

**Verification:**
- Check Local Storage is cleared
- Verify redirect to login page
- Check Keycloak logs for logout event

---

## 🔍 Debugging

### Check Keycloak Logs
```bash
docker logs keycloak -f
```

Look for:
- Login attempts
- Token generation
- Realm configuration
- Client validation

### Check Frontend Logs
```bash
docker logs customer-spa -f
docker logs admin-pwa -f
```

Look for:
- Keycloak initialization
- Token storage
- API calls
- Errors

### Check API Gateway Logs
```bash
docker logs api-gateway -f
```

Look for:
- Token validation
- Authorization checks
- Route forwarding
- Errors

### Browser Console
Press F12 and check:
- JavaScript errors
- Network requests
- Local Storage
- Session Storage

---

## 🛠️ Troubleshooting

### Issue: White Screen on Frontend
**Solution:**
1. Check browser console for errors
2. Verify Keycloak is running
3. Check frontend logs
4. Clear browser cache and reload

### Issue: "Client not found" Error
**Solution:**
1. Go to http://localhost:8080/admin
2. Login with admin / admin
3. Verify clients exist in microservices realm
4. Run: `.\scripts\configure-frontends-keycloak.ps1`

### Issue: Login Redirect Loop
**Solution:**
1. Clear browser cookies
2. Check Keycloak logs for errors
3. Verify redirect URIs in client settings
4. Check CORS configuration

### Issue: API Calls Failing
**Solution:**
1. Verify API Gateway is running
2. Check JWT token in Authorization header
3. Verify token is valid
4. Check microservice logs

### Issue: Token Not Stored
**Solution:**
1. Check browser Local Storage
2. Verify Keycloak initialization
3. Check browser console for errors
4. Verify silent-check-sso.html exists

---

## 📊 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Browser                                   │
├─────────────────────────────────────────────────────────────┤
│  Customer SPA (4200) / Admin PWA (4201)                     │
│  - Keycloak Angular Module                                  │
│  - JWT Token Storage                                        │
│  - HTTP Interceptor for Bearer Token                        │
└──────────┬────────────────────────────────────────────────┘
           │
           ├─────────────────────────────────────────────────┐
           │                                                 │
           ▼                                                 ▼
    ┌──────────────────┐                          ┌──────────────────┐
    │  Keycloak (8080) │                          │ API Gateway(5000)│
    │  - OAuth2/OIDC   │                          │ - JWT Validation │
    │  - Token Gen     │                          │ - Route Forward  │
    │  - User Mgmt     │                          │ - Auth Check     │
    └──────────────────┘                          └────────┬─────────┘
                                                           │
                                    ┌──────────────────────┼──────────────────────┐
                                    │                      │                      │
                                    ▼                      ▼                      ▼
                            ┌──────────────┐      ┌──────────────┐      ┌──────────────┐
                            │ Orders API   │      │ Inventory API│      │ Audit API    │
                            │ (5001)       │      │ (5002)       │      │ (5004)       │
                            └──────────────┘      └──────────────┘      └──────────────┘
```

---

## ✅ Checklist

- [ ] All services running (`docker-compose ps`)
- [ ] Keycloak accessible (http://localhost:8080)
- [ ] Customer SPA accessible (http://localhost:4200)
- [ ] Admin PWA accessible (http://localhost:4201)
- [ ] Can login with test credentials
- [ ] JWT token stored in browser
- [ ] API calls include Bearer token
- [ ] API Gateway validates token
- [ ] Microservices return data
- [ ] Logout works correctly
- [ ] Protected pages redirect to login
- [ ] No console errors

---

## 📚 Resources

- **Keycloak Docs**: https://www.keycloak.org/documentation
- **OAuth2 RFC**: https://tools.ietf.org/html/rfc6749
- **OpenID Connect**: https://openid.net/connect/
- **Angular Security**: https://angular.io/guide/security
- **JWT.io**: https://jwt.io

---

## 🎯 Success Criteria

✅ **Authentication Flow**
- User can login with credentials
- JWT token is generated
- Token is stored in browser
- Token is sent with API requests

✅ **Authorization**
- API Gateway validates token
- Microservices check scopes
- Protected resources require auth
- Unauthorized requests are rejected

✅ **User Experience**
- Login/logout works smoothly
- No manual token management
- Automatic token refresh
- Clear error messages

✅ **Security**
- Tokens are secure (HTTPS in production)
- Tokens expire after 1 hour
- Refresh tokens expire after 24 hours
- CORS properly configured

---

**Last Updated**: 2025-10-26  
**Status**: ✅ Ready for testing


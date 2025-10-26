# Frontend Authentication Fix - 401 Unauthorized Issue

## Problem
Frontend applications (Customer SPA and Admin PWA) were receiving 401 Unauthorized responses from the API Gateway even after successful login to Keycloak. Users were being redirected to the login page repeatedly.

## Root Causes Identified

### 1. **API Gateway Not Forwarding Authorization Header**
The API Gateway was validating the JWT token correctly but **not forwarding it to downstream microservices**. Ocelot by default does not automatically forward the Authorization header to downstream services.

### 2. **Synchronous Token Retrieval in HTTP Interceptor**
The auth interceptor was using synchronous `getToken()` call:
```typescript
const token = this.keycloak.getToken();  // Synchronous - may return undefined
```
This could return `undefined` if the token wasn't immediately available, resulting in requests without Authorization headers.

### 2. **Mixed Token Handling Approaches**
- API Service was manually adding headers with async `getHeaders()` method
- HTTP Interceptor was also trying to add headers
- This created conflicts and inconsistent behavior

### 3. **Inconsistent API Service Methods**
- Some methods (like `getProducts()`) didn't use the async `getHeaders()` method
- Some methods were async, others were not
- This led to unpredictable token injection

## Solutions Implemented

### 1. **Configured API Gateway to Forward Authorization Header**

**File**: `src/Gateway/Ocelot.Gateway/Program.cs`

Created a custom `DelegatingHandler` that extracts the Authorization header from incoming requests and forwards it to downstream microservices:

```csharp
// Add HttpContextAccessor for accessing the current HTTP context
builder.Services.AddHttpContextAccessor();

// Add custom delegating handler for token forwarding
builder.Services.AddTransient<AuthTokenHandler>();

// Add Ocelot with rate limiting and custom handler
builder.Services.AddOcelot()
    .AddPolly()
    .AddDelegatingHandler<AuthTokenHandler>(true);

// ... later in the file:

// Delegation handler to forward JWT token to downstream services
public class AuthTokenHandler : DelegatingHandler
{
    private readonly IHttpContextAccessor _httpContextAccessor;

    public AuthTokenHandler(IHttpContextAccessor httpContextAccessor)
    {
        _httpContextAccessor = httpContextAccessor;
    }

    protected override async Task<HttpResponseMessage> SendAsync(
        HttpRequestMessage request,
        CancellationToken cancellationToken)
    {
        var httpContext = _httpContextAccessor.HttpContext;

        if (httpContext != null)
        {
            // Get the Authorization header from the incoming request
            var authHeader = httpContext.Request.Headers["Authorization"].ToString();

            if (!string.IsNullOrEmpty(authHeader))
            {
                // Add it to the outgoing request to the downstream service
                request.Headers.TryAddWithoutValidation("Authorization", authHeader);
                Log.Information($"Forwarding Authorization header to downstream: {request.RequestUri}");
            }
        }

        return await base.SendAsync(request, cancellationToken);
    }
}
```

**Key Points**:
- `IHttpContextAccessor` provides access to the current HTTP context
- Handler is registered with Ocelot using `.AddDelegatingHandler<AuthTokenHandler>(true)`
- The `true` parameter means it applies globally to all routes
- Handler extracts Authorization header from incoming request
- Handler adds it to the outgoing request to downstream service

### 2. **Fixed HTTP Interceptor - Async Token Retrieval**

**File**: `src/frontend/customer-spa/src/app/interceptors/auth.interceptor.ts`

Changed from synchronous to asynchronous token retrieval using RxJS:

```typescript
// Before (synchronous - unreliable)
const token = this.keycloak.getToken();
if (token) {
  request = request.clone({
    setHeaders: { Authorization: `Bearer ${token}` }
  });
}

// After (asynchronous - reliable)
return from(this.keycloak.getToken()).pipe(
  switchMap((token: string) => {
    if (token) {
      request = request.clone({
        setHeaders: { Authorization: `Bearer ${token}` }
      });
    }
    return next.handle(request);
  }),
  catchError((error: HttpErrorResponse) => {
    if (error.status === 401) {
      this.keycloak.logout();
    }
    return throwError(() => error);
  })
);
```

**Key Changes**:
- Used `from()` to convert Promise to Observable
- Used `switchMap()` to wait for token before making request
- Properly handles async token retrieval
- Maintains error handling for 401 responses

### 3. **Simplified API Services**

**Files**:
- `src/frontend/customer-spa/src/app/services/api.service.ts`
- `src/frontend/admin-pwa/src/app/services/admin-api.service.ts`

Removed manual header management and relied on HTTP Interceptor:

```typescript
// Before (manual headers)
async getOrders(): Promise<Observable<any[]>> {
  const headers = await this.getHeaders();
  return this.http.get<any[]>(`${this.apiUrl}/orders`, { headers });
}

// After (interceptor handles it)
getOrders(): Observable<any[]> {
  return this.http.get<any[]>(`${this.apiUrl}/orders`);
}
```

**Benefits**:
- Single responsibility: Interceptor handles authentication
- Consistent behavior across all methods
- Simpler, more maintainable code
- No async/await complexity in service methods

### 4. **Applied Same Fix to Admin PWA**

**File**: `src/frontend/admin-pwa/src/app/interceptors/auth.interceptor.ts`

Applied identical async token retrieval fix to ensure consistent behavior across both frontends.

## Authentication Flow (Fixed)

```
1. User logs in via Keycloak
   ↓
2. Keycloak returns JWT token
   ↓
3. Frontend makes API request
   ↓
4. HTTP Interceptor intercepts request
   ↓
5. Interceptor calls keycloak.getToken() asynchronously
   ↓
6. Token is retrieved and added to Authorization header
   ↓
7. Request sent to API Gateway with Bearer token
   ↓
8. API Gateway validates token with Keycloak
   ↓
9. AuthTokenHandler extracts Authorization header
   ↓
10. AuthTokenHandler adds header to downstream request
   ↓
11. Microservice receives request with token
   ↓
12. Microservice validates token scopes and processes request
```

## Files Modified

1. **src/Gateway/Ocelot.Gateway/Program.cs**
   - Added IHttpContextAccessor to services
   - Created AuthTokenHandler DelegatingHandler
   - Registered handler with Ocelot pipeline

2. **src/frontend/customer-spa/src/app/interceptors/auth.interceptor.ts**
   - Changed to async token retrieval using RxJS
   - Added proper error handling

3. **src/frontend/customer-spa/src/app/services/api.service.ts**
   - Removed manual header management
   - Simplified all methods to rely on interceptor
   - Made all methods synchronous and consistent

4. **src/frontend/admin-pwa/src/app/interceptors/auth.interceptor.ts**
   - Changed to async token retrieval using RxJS
   - Added proper error handling

5. **src/frontend/admin-pwa/src/app/services/admin-api.service.ts**
   - Removed manual header management
   - Simplified all methods to rely on interceptor
   - Made all methods synchronous and consistent

## Testing

After the fix:
1. User logs in to Keycloak
2. Frontend receives JWT token
3. HTTP Interceptor properly adds token to all API requests
4. API Gateway validates token
5. Microservices process authenticated requests
6. No more 401 Unauthorized errors

## Key Improvements

✅ **Token Forwarding**: API Gateway now forwards Authorization header to microservices
✅ **Reliable Token Injection**: Async token retrieval ensures token is always available
✅ **Consistent Behavior**: All API methods work the same way
✅ **Simplified Code**: Removed duplicate header management
✅ **Better Error Handling**: Proper 401 handling with logout
✅ **Maintainability**: Single point of authentication logic (interceptor and handler)

## Deployment

1. Rebuilt API Gateway:
   ```bash
   docker-compose build api-gateway
   ```

2. Rebuilt frontend containers:
   ```bash
   docker-compose build customer-spa admin-pwa
   ```

3. Restarted all services:
   ```bash
   docker-compose up -d api-gateway customer-spa admin-pwa
   ```

## Result

✅ Frontend applications now properly authenticate with Keycloak
✅ JWT tokens are reliably injected into API requests
✅ API Gateway successfully validates tokens
✅ Microservices receive authenticated requests
✅ No more 401 Unauthorized redirects to login page


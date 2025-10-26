# Admin PWA (Progressive Web App)

Angular Progressive Web Application for administrative management of the microservices platform.

## Features

- **Keycloak Authentication** - Secure login with OAuth2/OIDC (confidential client)
- **Dashboard** - Overview of system metrics and health
- **Order Management** - View, confirm, ship, and cancel orders
- **Inventory Management** - Manage products and stock levels
- **Audit Logs** - View complete audit trail of all system events
- **PWA Support** - Installable app with offline capabilities
- **Service Worker** - Caching and offline functionality

## Prerequisites

- Node.js 18+ and npm
- Angular CLI 18+

## Installation

```bash
cd frontend/admin-pwa
npm install
```

## Development

```bash
npm start
```

Navigate to `http://localhost:4201/`

## Build

```bash
npm run build
```

Build artifacts will be stored in the `dist/` directory.

## PWA Features

### Service Worker

The app includes a service worker that:
- Caches static assets for offline access
- Implements cache-first strategy for assets
- Implements network-first strategy for API calls
- Provides offline fallback

### Installation

Users can install the app on their device:
1. Visit the app in a supported browser
2. Click the "Install" button in the address bar
3. The app will be added to the home screen/app drawer

### Offline Support

The app works offline with cached data:
- Static assets are cached on first load
- API responses are cached for 1 hour
- Offline indicator shows when network is unavailable

## Configuration

### Keycloak

Update Keycloak configuration in `src/app/app.module.ts`:

```typescript
config: {
  url: 'http://localhost:8080',
  realm: 'microservices',
  clientId: 'admin-console'
}
```

### API Gateway

Update API Gateway URL in `src/app/services/admin-api.service.ts`:

```typescript
private apiUrl = 'http://localhost:5000';
```

## Keycloak Setup

1. Create a new client in Keycloak:
   - Client ID: `admin-console`
   - Client Protocol: `openid-connect`
   - Access Type: `confidential`
   - Valid Redirect URIs: `http://localhost:4201/*`
   - Web Origins: `http://localhost:4201`

2. Create an `admin` role and assign to admin users

3. Configure client scopes as needed

## Docker Build

```bash
docker build -t admin-pwa:1.0.0 .
docker run -p 4201:80 admin-pwa:1.0.0
```

## Project Structure

```
src/
├── app/
│   ├── components/       # UI components
│   │   ├── dashboard/
│   │   ├── order-management/
│   │   ├── inventory-management/
│   │   ├── audit-logs/
│   │   ├── navbar/
│   │   └── sidebar/
│   ├── guards/           # Route guards
│   ├── services/         # API services
│   ├── app.module.ts     # Main module
│   └── app-routing.module.ts
├── assets/               # Static assets
│   └── icons/            # PWA icons
├── manifest.webmanifest  # PWA manifest
├── ngsw-config.json      # Service worker config
└── index.html            # Main HTML
```

## Available Routes

- `/dashboard` - Dashboard with system overview
- `/orders` - Order management
- `/inventory` - Inventory management
- `/audit` - Audit logs

All routes require authentication and admin role.

## PWA Manifest

The app includes a web manifest (`manifest.webmanifest`) that defines:
- App name and short name
- Theme colors
- Display mode (standalone)
- Icons for various sizes
- Start URL

## Service Worker Configuration

The service worker is configured in `ngsw-config.json`:
- **App shell**: Prefetched on install
- **Assets**: Lazy loaded and cached
- **API calls**: Cached with freshness strategy (1 hour max age)

## Testing PWA Features

### Test Installation

1. Build the app for production: `npm run build`
2. Serve the production build: `npx http-server dist/admin-pwa`
3. Open in Chrome and check for install prompt

### Test Offline

1. Open Chrome DevTools
2. Go to Application > Service Workers
3. Check "Offline" checkbox
4. Reload the app - it should work offline

### Test Caching

1. Open Chrome DevTools
2. Go to Application > Cache Storage
3. Verify cached assets and API responses

## Security Considerations

- Uses confidential client for enhanced security
- Requires admin role for access
- All API calls include JWT bearer token
- HTTPS required in production for PWA features

## Production Deployment

1. Build for production: `npm run build`
2. Deploy to HTTPS-enabled server (required for PWA)
3. Configure Keycloak with production URLs
4. Update API Gateway URL in environment config
5. Test PWA installation and offline functionality

## Browser Support

- Chrome/Edge 90+
- Firefox 88+
- Safari 14+
- Opera 76+

PWA features require HTTPS in production.


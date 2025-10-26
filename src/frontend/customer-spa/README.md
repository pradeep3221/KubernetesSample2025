# Customer SPA

Angular Single Page Application for customer interactions with the microservices platform.

## Features

- **Keycloak Authentication** - Secure login with OAuth2/OIDC
- **Product Browsing** - View available products
- **Order Management** - Create and track orders
- **Responsive Design** - Works on desktop and mobile

## Prerequisites

- Node.js 18+ and npm
- Angular CLI 18+

## Installation

```bash
cd frontend/customer-spa
npm install
```

## Development

```bash
npm start
```

Navigate to `http://localhost:4200/`

## Build

```bash
npm run build
```

Build artifacts will be stored in the `dist/` directory.

## Configuration

Update Keycloak configuration in `src/app/app.module.ts`:

```typescript
config: {
  url: 'http://localhost:8080',
  realm: 'microservices',
  clientId: 'customer-spa'
}
```

Update API Gateway URL in `src/app/services/api.service.ts`:

```typescript
private apiUrl = 'http://localhost:5000';
```

## Keycloak Setup

1. Create a new client in Keycloak:
   - Client ID: `customer-spa`
   - Client Protocol: `openid-connect`
   - Access Type: `public`
   - Valid Redirect URIs: `http://localhost:4200/*`
   - Web Origins: `http://localhost:4200`

2. Create roles and assign to users as needed

## Docker Build

```bash
docker build -t customer-spa:1.0.0 .
docker run -p 4200:80 customer-spa:1.0.0
```

## Project Structure

```
src/
├── app/
│   ├── components/       # UI components
│   ├── guards/           # Route guards
│   ├── services/         # API services
│   ├── app.module.ts     # Main module
│   └── app-routing.module.ts
├── assets/               # Static assets
├── styles.scss           # Global styles
└── index.html            # Main HTML
```

## Available Routes

- `/` - Home page
- `/products` - Product listing
- `/orders` - My orders (requires authentication)
- `/orders/create` - Create new order (requires authentication)
- `/orders/:id` - Order details (requires authentication)


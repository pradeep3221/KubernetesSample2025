# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY src/frontend/admin-pwa/package*.json ./

# Install dependencies
RUN npm install --legacy-peer-deps

# Copy source code
COPY src/frontend/admin-pwa/ .

# Build the application
RUN npm run build

# Production stage
FROM nginx:alpine

# Copy nginx configuration
COPY src/frontend/admin-pwa/nginx.conf /etc/nginx/nginx.conf

# Copy built application from builder stage
COPY --from=builder /app/dist/admin-pwa/browser /usr/share/nginx/html

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost/index.html || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]


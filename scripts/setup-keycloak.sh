#!/bin/bash

# Keycloak Automated Setup Script
# This script configures Keycloak with realms, clients, scopes, roles, and test users
# Prerequisites: Keycloak must be running on http://localhost:8080

set -e

# Configuration
KEYCLOAK_URL="${1:-http://localhost:8080}"
ADMIN_USER="${2:-admin}"
ADMIN_PASSWORD="${3:-admin}"
REALM_NAME="${4:-microservices}"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Output functions
success() {
    echo -e "${GREEN}✅ $1${NC}"
}

info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Get admin token
get_admin_token() {
    info "Obtaining admin token..."
    
    local token_url="$KEYCLOAK_URL/realms/master/protocol/openid-connect/token"
    
    local response=$(curl -s -X POST "$token_url" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "grant_type=password&client_id=admin-cli&username=$ADMIN_USER&password=$ADMIN_PASSWORD")
    
    local token=$(echo "$response" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)
    
    if [ -z "$token" ]; then
        error "Failed to obtain admin token"
        error "Response: $response"
        exit 1
    fi
    
    success "Admin token obtained"
    echo "$token"
}

# Create realm
create_realm() {
    local token=$1
    local realm_name=$2
    
    info "Creating realm: $realm_name"
    
    local url="$KEYCLOAK_URL/admin/realms"
    
    local body=$(cat <<EOF
{
    "realm": "$realm_name",
    "enabled": true,
    "displayName": "Microservices Realm",
    "displayNameHtml": "<b>Microservices Realm</b>",
    "accessTokenLifespan": 3600,
    "refreshTokenLifespan": 86400,
    "sslRequired": "none",
    "registrationAllowed": false,
    "registrationEmailAsUsername": false
}
EOF
)
    
    local response=$(curl -s -w "\n%{http_code}" -X POST "$url" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -d "$body")
    
    local http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "201" ]; then
        success "Realm '$realm_name' created"
    elif [ "$http_code" = "409" ]; then
        warning "Realm '$realm_name' already exists"
    else
        error "Failed to create realm (HTTP $http_code)"
    fi
}

# Create client scope
create_client_scope() {
    local token=$1
    local scope_name=$2
    local description=$3
    
    local url="$KEYCLOAK_URL/admin/realms/$REALM_NAME/client-scopes"
    
    local body=$(cat <<EOF
{
    "name": "$scope_name",
    "description": "$description",
    "protocol": "openid-connect"
}
EOF
)
    
    local response=$(curl -s -w "\n%{http_code}" -X POST "$url" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -d "$body")
    
    local http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "201" ]; then
        success "Client scope '$scope_name' created"
    elif [ "$http_code" = "409" ]; then
        warning "Client scope '$scope_name' already exists"
    else
        error "Failed to create client scope '$scope_name' (HTTP $http_code)"
    fi
}

# Create client
create_client() {
    local token=$1
    local client_id=$2
    local client_name=$3
    shift 3
    local scopes=("$@")
    
    info "Creating client: $client_id"
    
    local url="$KEYCLOAK_URL/admin/realms/$REALM_NAME/clients"
    
    # Build scopes array
    local scopes_json="["
    for scope in "${scopes[@]}"; do
        scopes_json="$scopes_json\"$scope\","
    done
    scopes_json="${scopes_json%,}]"
    
    local body=$(cat <<EOF
{
    "clientId": "$client_id",
    "name": "$client_name",
    "enabled": true,
    "publicClient": false,
    "protocol": "openid-connect",
    "standardFlowEnabled": true,
    "implicitFlowEnabled": false,
    "directAccessGrantsEnabled": true,
    "serviceAccountsEnabled": true,
    "authorizationServicesEnabled": true,
    "redirectUris": ["http://localhost:*/*", "http://127.0.0.1:*/*"],
    "webOrigins": ["*"],
    "defaultClientScopes": $scopes_json,
    "optionalClientScopes": $scopes_json
}
EOF
)
    
    local response=$(curl -s -w "\n%{http_code}" -X POST "$url" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -d "$body")
    
    local http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "201" ]; then
        success "Client '$client_id' created"
    elif [ "$http_code" = "409" ]; then
        warning "Client '$client_id' already exists"
    else
        error "Failed to create client '$client_id' (HTTP $http_code)"
    fi
}

# Create role
create_role() {
    local token=$1
    local role_name=$2
    local description=$3
    
    local url="$KEYCLOAK_URL/admin/realms/$REALM_NAME/roles"
    
    local body=$(cat <<EOF
{
    "name": "$role_name",
    "description": "$description"
}
EOF
)
    
    local response=$(curl -s -w "\n%{http_code}" -X POST "$url" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -d "$body")
    
    local http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "201" ]; then
        success "Role '$role_name' created"
    elif [ "$http_code" = "409" ]; then
        warning "Role '$role_name' already exists"
    else
        error "Failed to create role '$role_name' (HTTP $http_code)"
    fi
}

# Create user
create_user() {
    local token=$1
    local username=$2
    local email=$3
    local password=$4
    
    info "Creating user: $username"
    
    local url="$KEYCLOAK_URL/admin/realms/$REALM_NAME/users"
    
    local body=$(cat <<EOF
{
    "username": "$username",
    "email": "$email",
    "emailVerified": true,
    "enabled": true,
    "firstName": "$username",
    "lastName": "User",
    "credentials": [
        {
            "type": "password",
            "value": "$password",
            "temporary": false
        }
    ]
}
EOF
)
    
    local response=$(curl -s -w "\n%{http_code}" -X POST "$url" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -d "$body")
    
    local http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "201" ]; then
        success "User '$username' created"
        # Extract user ID from location header
        echo "$response" | grep -o '"id":"[^"]*' | cut -d'"' -f4 | head -1
    elif [ "$http_code" = "409" ]; then
        warning "User '$username' already exists"
        # Get existing user ID
        local get_url="$KEYCLOAK_URL/admin/realms/$REALM_NAME/users?username=$username"
        curl -s -X GET "$get_url" \
            -H "Authorization: Bearer $token" | grep -o '"id":"[^"]*' | cut -d'"' -f4 | head -1
    else
        error "Failed to create user '$username' (HTTP $http_code)"
    fi
}

# Assign role to user
assign_role_to_user() {
    local token=$1
    local user_id=$2
    local role_name=$3
    
    # Get role ID
    local roles_url="$KEYCLOAK_URL/admin/realms/$REALM_NAME/roles?search=$role_name"
    local role_id=$(curl -s -X GET "$roles_url" \
        -H "Authorization: Bearer $token" | grep -o '"id":"[^"]*' | cut -d'"' -f4 | head -1)
    
    if [ -z "$role_id" ]; then
        error "Role '$role_name' not found"
        return
    fi
    
    local url="$KEYCLOAK_URL/admin/realms/$REALM_NAME/users/$user_id/role-mappings/realm"
    
    local body=$(cat <<EOF
[
    {
        "id": "$role_id",
        "name": "$role_name"
    }
]
EOF
)
    
    curl -s -X POST "$url" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -d "$body" > /dev/null
    
    success "Role '$role_name' assigned to user"
}

# Main execution
echo -e "\n${MAGENTA}🔐 Keycloak Automated Setup${NC}\n"

# Check if Keycloak is running
info "Checking Keycloak availability at $KEYCLOAK_URL..."
if ! curl -s "$KEYCLOAK_URL/health" > /dev/null 2>&1; then
    error "Keycloak is not accessible at $KEYCLOAK_URL"
    error "Please ensure Keycloak is running: docker-compose up -d keycloak"
    exit 1
fi
success "Keycloak is running"

# Get admin token
TOKEN=$(get_admin_token)

# Create realm
create_realm "$TOKEN" "$REALM_NAME"

# Create client scopes
echo -e "\n${YELLOW}📋 Creating Client Scopes...${NC}"
create_client_scope "$TOKEN" "orders.read" "Read orders"
create_client_scope "$TOKEN" "orders.write" "Write orders"
create_client_scope "$TOKEN" "inventory.read" "Read inventory"
create_client_scope "$TOKEN" "inventory.write" "Write inventory"
create_client_scope "$TOKEN" "notifications.read" "Read notifications"
create_client_scope "$TOKEN" "notifications.write" "Write notifications"
create_client_scope "$TOKEN" "audit.read" "Read audit logs"
create_client_scope "$TOKEN" "audit.write" "Write audit logs"

# Create clients
echo -e "\n${YELLOW}🔑 Creating Clients...${NC}"
create_client "$TOKEN" "orders-api" "Orders API" "orders.read" "orders.write"
create_client "$TOKEN" "inventory-api" "Inventory API" "inventory.read" "inventory.write"
create_client "$TOKEN" "notifications-api" "Notifications API" "notifications.read" "notifications.write"
create_client "$TOKEN" "audit-api" "Audit API" "audit.read" "audit.write"
create_client "$TOKEN" "api-gateway" "API Gateway" "orders.read" "orders.write" "inventory.read" "inventory.write" "notifications.read" "notifications.write" "audit.read" "audit.write"

# Create roles
echo -e "\n${YELLOW}👥 Creating Roles...${NC}"
create_role "$TOKEN" "admin" "Administrator role"
create_role "$TOKEN" "user" "Regular user role"
create_role "$TOKEN" "orders-manager" "Orders manager role"
create_role "$TOKEN" "inventory-manager" "Inventory manager role"

# Create test users
echo -e "\n${YELLOW}👤 Creating Test Users...${NC}"

ADMIN_ID=$(create_user "$TOKEN" "admin" "admin@microservices.local" "Admin@123")
assign_role_to_user "$TOKEN" "$ADMIN_ID" "admin"

USER_ID=$(create_user "$TOKEN" "user" "user@microservices.local" "User@123")
assign_role_to_user "$TOKEN" "$USER_ID" "user"

ORDERS_ID=$(create_user "$TOKEN" "orders-manager" "orders@microservices.local" "Orders@123")
assign_role_to_user "$TOKEN" "$ORDERS_ID" "orders-manager"

INVENTORY_ID=$(create_user "$TOKEN" "inventory-manager" "inventory@microservices.local" "Inventory@123")
assign_role_to_user "$TOKEN" "$INVENTORY_ID" "inventory-manager"

echo -e "\n${GREEN}✅ Keycloak setup completed successfully!${NC}\n"
echo -e "${CYAN}📝 Test Credentials:${NC}"
echo -e "   Admin:              admin / Admin@123"
echo -e "   User:               user / User@123"
echo -e "   Orders Manager:     orders-manager / Orders@123"
echo -e "   Inventory Manager:  inventory-manager / Inventory@123"
echo -e "\n${CYAN}🔗 Access Keycloak Admin Console: $KEYCLOAK_URL/admin${NC}\n"


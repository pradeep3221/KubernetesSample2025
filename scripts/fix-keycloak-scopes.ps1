# Fix Keycloak Scopes - Add microservice scopes to frontend clients
# This script adds the required scopes to customer-spa and admin-pwa clients

param(
    [string]$KeycloakUrl = "http://localhost:8080",
    [string]$AdminUser = "admin",
    [string]$AdminPassword = "admin",
    [string]$RealmName = "microservices"
)

# Color output functions
function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-InfoMsg {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-ErrorMsg {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Get admin token
function Get-AdminToken {
    Write-InfoMsg "Obtaining admin token..."
    
    $tokenUrl = "$KeycloakUrl/realms/master/protocol/openid-connect/token"
    $body = @{
        grant_type    = "password"
        client_id     = "admin-cli"
        username      = $AdminUser
        password      = $AdminPassword
    }
    
    try {
        $response = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"
        Write-Success "Admin token obtained"
        return $response.access_token
    }
    catch {
        Write-ErrorMsg "Failed to obtain admin token: $_"
        exit 1
    }
}

Write-Host "`n=== Fixing Keycloak Scopes for Frontend Clients ===" -ForegroundColor Magenta

# Get admin token
$token = Get-AdminToken

$headers = @{
    Authorization = "Bearer $token"
    "Content-Type" = "application/json"
}

# Get all client scopes
Write-InfoMsg "Getting client scopes..."
$scopesUrl = "$KeycloakUrl/admin/realms/$RealmName/client-scopes"
$allScopes = Invoke-RestMethod -Uri $scopesUrl -Method Get -Headers $headers

# Find the microservice scopes
$microserviceScopes = @(
    "orders.read", "orders.write",
    "inventory.read", "inventory.write",
    "notifications.read", "notifications.write",
    "audit.read", "audit.write"
)

$scopeIds = @{}
foreach ($scopeName in $microserviceScopes) {
    $scope = $allScopes | Where-Object { $_.name -eq $scopeName }
    if ($scope) {
        $scopeIds[$scopeName] = $scope.id
        Write-Success "Found scope: $scopeName (ID: $($scope.id))"
    }
    else {
        Write-ErrorMsg "Scope not found: $scopeName"
    }
}

# Get frontend clients
$clientsUrl = "$KeycloakUrl/admin/realms/$RealmName/clients"
$allClients = Invoke-RestMethod -Uri $clientsUrl -Method Get -Headers $headers

$frontendClients = @("customer-spa", "admin-pwa")

foreach ($clientId in $frontendClients) {
    Write-Host "`n--- Processing client: $clientId ---" -ForegroundColor Yellow
    
    $client = $allClients | Where-Object { $_.clientId -eq $clientId }
    
    if ($client) {
        Write-Success "Found client: $clientId (ID: $($client.id))"
        
        # Add each scope as a default client scope
        foreach ($scopeName in $microserviceScopes) {
            if ($scopeIds.ContainsKey($scopeName)) {
                $scopeId = $scopeIds[$scopeName]
                $addScopeUrl = "$KeycloakUrl/admin/realms/$RealmName/clients/$($client.id)/default-client-scopes/$scopeId"
                
                try {
                    Invoke-RestMethod -Uri $addScopeUrl -Method Put -Headers $headers | Out-Null
                    Write-Success "Added scope '$scopeName' to client '$clientId'"
                }
                catch {
                    if ($_.Exception.Response.StatusCode -eq 409 -or $_.Exception.Response.StatusCode -eq 204) {
                        Write-InfoMsg "Scope '$scopeName' already assigned to '$clientId'"
                    }
                    else {
                        Write-ErrorMsg "Failed to add scope '$scopeName' to '$clientId': $_"
                    }
                }
            }
        }
    }
    else {
        Write-ErrorMsg "Client not found: $clientId"
    }
}

Write-Host "`n=== Scope assignment completed! ===" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Log out from the frontend applications" -ForegroundColor White
Write-Host "2. Log in again to get a new token with the scopes" -ForegroundColor White
Write-Host "3. Test API calls - they should now work!" -ForegroundColor White


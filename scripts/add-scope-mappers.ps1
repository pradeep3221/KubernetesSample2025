# Add Scope Mappers to Keycloak Client Scopes
# This script adds protocol mappers to include scopes in the JWT token

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

Write-Host "`n=== Adding Scope Mappers to Keycloak ===" -ForegroundColor Magenta

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

# Microservice scopes to configure
$microserviceScopes = @(
    "orders.read", "orders.write",
    "inventory.read", "inventory.write",
    "notifications.read", "notifications.write",
    "audit.read", "audit.write"
)

foreach ($scopeName in $microserviceScopes) {
    Write-Host "`n--- Processing scope: $scopeName ---" -ForegroundColor Yellow
    
    $scope = $allScopes | Where-Object { $_.name -eq $scopeName }
    
    if ($scope) {
        Write-Success "Found scope: $scopeName (ID: $($scope.id))"
        
        # Add a protocol mapper to include this scope in the token
        $mapperUrl = "$KeycloakUrl/admin/realms/$RealmName/client-scopes/$($scope.id)/protocol-mappers/models"
        
        $mapper = @{
            name            = "$scopeName-mapper"
            protocol        = "openid-connect"
            protocolMapper  = "oidc-audience-mapper"
            consentRequired = $false
            config          = @{
                "included.client.audience" = $scopeName
                "id.token.claim"           = "true"
                "access.token.claim"       = "true"
            }
        } | ConvertTo-Json -Depth 10
        
        try {
            Invoke-RestMethod -Uri $mapperUrl -Method Post -Headers $headers -Body $mapper | Out-Null
            Write-Success "Added mapper for scope: $scopeName"
        }
        catch {
            if ($_.Exception.Response.StatusCode -eq 409) {
                Write-InfoMsg "Mapper already exists for scope: $scopeName"
            }
            else {
                Write-ErrorMsg "Failed to add mapper for scope '$scopeName': $_"
            }
        }
    }
    else {
        Write-ErrorMsg "Scope not found: $scopeName"
    }
}

Write-Host "`n=== Scope mappers added! ===" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Log out from the frontend applications" -ForegroundColor White
Write-Host "2. Log in again to get a new token with the scopes" -ForegroundColor White
Write-Host "3. Decode the new JWT token to verify scopes are included" -ForegroundColor White
Write-Host "4. Test API calls - they should now work!" -ForegroundColor White


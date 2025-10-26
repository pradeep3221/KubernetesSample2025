# Configure Frontends in Keycloak
# This script registers the Angular frontends as OAuth2 clients in Keycloak

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

function Write-WarningMsg {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

# Get admin token
function Get-AdminToken {
    Write-InfoMsg "Obtaining admin token..."
    
    $url = "$KeycloakUrl/realms/master/protocol/openid-connect/token"
    $body = @{
        grant_type = "password"
        client_id = "admin-cli"
        username = $AdminUser
        password = $AdminPassword
    }
    
    try {
        $response = Invoke-RestMethod -Uri $url -Method Post -Body $body -ErrorAction Stop
        Write-Success "Admin token obtained"
        return $response.access_token
    }
    catch {
        Write-ErrorMsg "Failed to obtain admin token: $_"
        exit 1
    }
}

# Create or update client
function New-Client {
    param(
        [string]$Token,
        [string]$ClientId,
        [string]$ClientName,
        [string]$RedirectUri,
        [string]$WebOrigin
    )
    
    $url = "$KeycloakUrl/admin/realms/$RealmName/clients"
    $headers = @{
        Authorization = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    # Check if client exists
    $existingClients = Invoke-RestMethod -Uri "$url?clientId=$ClientId" -Method Get -Headers $headers
    
    if ($existingClients.Count -gt 0) {
        Write-WarningMsg "Client '$ClientId' already exists"
        return $existingClients[0].id
    }
    
    Write-InfoMsg "Creating client: $ClientId"
    
    $body = @{
        clientId = $ClientId
        name = $ClientName
        enabled = $true
        publicClient = $true
        directAccessGrantsEnabled = $false
        standardFlowEnabled = $true
        implicitFlowEnabled = $false
        redirectUris = @($RedirectUri)
        webOrigins = @($WebOrigin, "+")
        rootUrl = $WebOrigin
        baseUrl = "/"
        protocol = "openid-connect"
        attributes = @{
            "post.logout.redirect.uris" = "$WebOrigin/*"
        }
    } | ConvertTo-Json -Depth 10
    
    try {
        $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body -ErrorAction Stop
        Write-Success "Client '$ClientId' created"
        return $response
    }
    catch {
        Write-ErrorMsg "Failed to create client '$ClientId': $_"
        return $null
    }
}

# Add client scopes to client
function Add-ClientScopes {
    param(
        [string]$Token,
        [string]$ClientId,
        [string[]]$Scopes
    )
    
    # Get client ID
    $url = "$KeycloakUrl/admin/realms/$RealmName/clients"
    $headers = @{
        Authorization = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    $clients = Invoke-RestMethod -Uri "$url?clientId=$ClientId" -Method Get -Headers $headers
    if ($clients.Count -eq 0) {
        Write-ErrorMsg "Client '$ClientId' not found"
        return
    }
    
    $internalClientId = $clients[0].id
    
    # Get available scopes
    $scopesUrl = "$KeycloakUrl/admin/realms/$RealmName/client-scopes"
    $availableScopes = Invoke-RestMethod -Uri $scopesUrl -Method Get -Headers $headers
    
    # Add scopes to client
    foreach ($scope in $Scopes) {
        $scopeObj = $availableScopes | Where-Object { $_.name -eq $scope }
        if ($scopeObj) {
            $scopeId = $scopeObj.id
            $assignUrl = "$KeycloakUrl/admin/realms/$RealmName/clients/$internalClientId/default-client-scopes/$scopeId"
            
            try {
                Invoke-RestMethod -Uri $assignUrl -Method Put -Headers $headers -ErrorAction Stop | Out-Null
                Write-Success "Scope '$scope' added to client '$ClientId'"
            }
            catch {
                Write-WarningMsg "Failed to add scope '$scope': $_"
            }
        }
    }
}

# Enable realm
function Enable-Realm {
    param([string]$Token)
    
    Write-InfoMsg "Enabling realm..."
    
    $url = "$KeycloakUrl/admin/realms/$RealmName"
    $headers = @{
        Authorization = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    try {
        $realmInfo = Invoke-RestMethod -Uri $url -Method Get -Headers $headers
        
        if ($realmInfo.enabled -eq $false) {
            $realmInfo.enabled = $true
            $body = $realmInfo | ConvertTo-Json -Depth 10
            
            Invoke-RestMethod -Uri $url -Method Put -Headers $headers -Body $body -ErrorAction Stop | Out-Null
            Write-Success "Realm enabled"
        }
        else {
            Write-Success "Realm is already enabled"
        }
    }
    catch {
        Write-ErrorMsg "Failed to enable realm: $_"
    }
}

# Main execution
Write-Host "`n=== Configure Frontends in Keycloak ===" -ForegroundColor Magenta

# Check if Keycloak is running
Write-InfoMsg "Checking Keycloak availability at $KeycloakUrl..."
try {
    $response = Invoke-RestMethod -Uri "$KeycloakUrl/" -Method Get -ErrorAction Stop
    Write-Success "Keycloak is running"
}
catch {
    Write-ErrorMsg "Keycloak is not accessible at $KeycloakUrl"
    exit 1
}

# Get admin token
$token = Get-AdminToken

# Enable realm
Enable-Realm -Token $token

# Configure Customer SPA
Write-Host "`n--- Configuring Customer SPA ---" -ForegroundColor Yellow
New-Client -Token $token `
    -ClientId "customer-spa" `
    -ClientName "Customer SPA" `
    -RedirectUri "http://localhost:4200/*" `
    -WebOrigin "http://localhost:4200"

# Configure Admin PWA
Write-Host "`n--- Configuring Admin PWA ---" -ForegroundColor Yellow
New-Client -Token $token `
    -ClientId "admin-pwa" `
    -ClientName "Admin PWA" `
    -RedirectUri "http://localhost:4201/*" `
    -WebOrigin "http://localhost:4201"

Write-Host "`n=== Frontends Configuration Complete ===" -ForegroundColor Green
Write-Host "`nFrontend Clients:" -ForegroundColor Cyan
Write-Host "  Customer SPA: http://localhost:4200" -ForegroundColor Yellow
Write-Host "  Admin PWA:    http://localhost:4201" -ForegroundColor Yellow
Write-Host "`nKeycloak Admin Console: $KeycloakUrl/admin" -ForegroundColor Cyan
Write-Host ""


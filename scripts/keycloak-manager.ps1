# Keycloak Manager - Comprehensive Keycloak Configuration Script
# This script provides a complete solution for managing Keycloak configuration
# Usage: .\keycloak-manager.ps1 -Action <action> [parameters]
# Actions: Setup, ConfigureFrontends, AddScopes, TestToken, Debug, EnablePasswordGrant, All

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Setup", "ConfigureFrontends", "AddScopes", "TestToken", "Debug", "EnablePasswordGrant", "All", "Help")]
    [string]$Action = "Help",
    
    [string]$KeycloakUrl = "http://localhost:8080",
    [string]$AdminUser = "admin",
    [string]$AdminPassword = "admin",
    [string]$RealmName = "microservices",
    [string]$TestUsername = "admin",
    [string]$TestPassword = "Admin@123"
)

#region Color Output Functions
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

function Write-Header {
    param([string]$Message)
    Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║  $Message" -ForegroundColor Magenta
    Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Magenta
}

function Write-Section {
    param([string]$Message)
    Write-Host "`n--- $Message ---" -ForegroundColor Yellow
}
#endregion

#region Core Functions
function Test-KeycloakAvailability {
    Write-InfoMsg "Checking Keycloak availability at $KeycloakUrl..."
    try {
        $response = Invoke-RestMethod -Uri "$KeycloakUrl/" -Method Get -ErrorAction Stop
        Write-Success "Keycloak is running"
        return $true
    }
    catch {
        Write-ErrorMsg "Keycloak is not accessible at $KeycloakUrl"
        Write-ErrorMsg "Please ensure Keycloak is running: docker-compose up -d keycloak"
        return $false
    }
}

function Get-AdminToken {
    Write-InfoMsg "Obtaining admin token..."
    
    $tokenUrl = "$KeycloakUrl/realms/master/protocol/openid-connect/token"
    $body = @{
        grant_type = "password"
        client_id  = "admin-cli"
        username   = $AdminUser
        password   = $AdminPassword
    }
    
    try {
        $response = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"
        Write-Success "Admin token obtained"
        return $response.access_token
    }
    catch {
        Write-ErrorMsg "Failed to obtain admin token: $_"
        return $null
    }
}

function New-Realm {
    param([string]$Token)
    
    Write-InfoMsg "Creating realm: $RealmName"
    
    $url = "$KeycloakUrl/admin/realms"
    $headers = @{
        Authorization  = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    $body = @{
        realm                       = $RealmName
        enabled                     = $true
        displayName                 = "Microservices Realm"
        displayNameHtml             = "<b>Microservices Realm</b>"
        accessTokenLifespan         = 3600
        refreshTokenLifespan        = 86400
        sslRequired                 = "none"
        registrationAllowed         = $false
        registrationEmailAsUsername = $false
    } | ConvertTo-Json
    
    try {
        Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body | Out-Null
        Write-Success "Realm '$RealmName' created"
    }
    catch {
        if ($_.Exception.Response.StatusCode -eq 409) {
            Write-WarningMsg "Realm '$RealmName' already exists"
        }
        else {
            Write-ErrorMsg "Failed to create realm: $_"
        }
    }
}

function Enable-Realm {
    param([string]$Token)
    
    Write-InfoMsg "Enabling realm..."
    
    $url = "$KeycloakUrl/admin/realms/$RealmName"
    $headers = @{
        Authorization  = "Bearer $Token"
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

function New-ClientScope {
    param(
        [string]$Token,
        [string]$ScopeName,
        [string]$Description
    )
    
    $url = "$KeycloakUrl/admin/realms/$RealmName/client-scopes"
    $headers = @{
        Authorization  = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    $body = @{
        name        = $ScopeName
        description = $Description
        protocol    = "openid-connect"
    } | ConvertTo-Json
    
    try {
        Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body | Out-Null
        Write-Success "Client scope '$ScopeName' created"
    }
    catch {
        if ($_.Exception.Response.StatusCode -eq 409) {
            Write-WarningMsg "Client scope '$ScopeName' already exists"
        }
        else {
            Write-ErrorMsg "Failed to create client scope '$ScopeName': $_"
        }
    }
}

function Add-ScopeMapper {
    param(
        [string]$Token,
        [string]$ScopeId,
        [string]$ScopeName
    )
    
    $mapperUrl = "$KeycloakUrl/admin/realms/$RealmName/client-scopes/$ScopeId/protocol-mappers/models"
    $headers = @{
        Authorization  = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    $mapper = @{
        name            = "$ScopeName-mapper"
        protocol        = "openid-connect"
        protocolMapper  = "oidc-audience-mapper"
        consentRequired = $false
        config          = @{
            "included.client.audience" = $ScopeName
            "id.token.claim"           = "true"
            "access.token.claim"       = "true"
        }
    } | ConvertTo-Json -Depth 10
    
    try {
        Invoke-RestMethod -Uri $mapperUrl -Method Post -Headers $headers -Body $mapper | Out-Null
        Write-Success "Added mapper for scope: $ScopeName"
    }
    catch {
        if ($_.Exception.Response.StatusCode -eq 409) {
            Write-InfoMsg "Mapper already exists for scope: $ScopeName"
        }
        else {
            Write-ErrorMsg "Failed to add mapper for scope '$ScopeName': $_"
        }
    }
}

function New-Client {
    param(
        [string]$Token,
        [string]$ClientId,
        [string]$ClientName,
        [string[]]$Scopes,
        [bool]$PublicClient = $false,
        [string[]]$RedirectUris = @("http://localhost:*/*", "http://127.0.0.1:*/*"),
        [string[]]$WebOrigins = @("*")
    )
    
    Write-InfoMsg "Creating client: $ClientId"
    
    $url = "$KeycloakUrl/admin/realms/$RealmName/clients"
    $headers = @{
        Authorization  = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    $body = @{
        clientId                      = $ClientId
        name                          = $ClientName
        enabled                       = $true
        publicClient                  = $PublicClient
        protocol                      = "openid-connect"
        standardFlowEnabled           = $true
        implicitFlowEnabled           = $false
        directAccessGrantsEnabled     = $true
        serviceAccountsEnabled        = -not $PublicClient
        authorizationServicesEnabled  = -not $PublicClient
        redirectUris                  = $RedirectUris
        webOrigins                    = $WebOrigins
        defaultClientScopes           = $Scopes
        optionalClientScopes          = $Scopes
    }
    
    if ($PublicClient) {
        $body.rootUrl = $WebOrigins[0]
        $body.baseUrl = "/"
        $body.attributes = @{
            "post.logout.redirect.uris" = "$($WebOrigins[0])/*"
        }
    }
    
    $bodyJson = $body | ConvertTo-Json -Depth 10
    
    try {
        $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $bodyJson
        Write-Success "Client '$ClientId' created"
        return $response.id
    }
    catch {
        if ($_.Exception.Response.StatusCode -eq 409) {
            Write-WarningMsg "Client '$ClientId' already exists"
            $getUrl = "$KeycloakUrl/admin/realms/$RealmName/clients?clientId=$ClientId"
            $clients = Invoke-RestMethod -Uri $getUrl -Method Get -Headers $headers
            return $clients[0].id
        }
        else {
            Write-ErrorMsg "Failed to create client '$ClientId': $_"
            return $null
        }
    }
}

function Add-ScopesToClient {
    param(
        [string]$Token,
        [string]$ClientId,
        [string[]]$Scopes
    )

    $headers = @{
        Authorization  = "Bearer $Token"
        "Content-Type" = "application/json"
    }

    # Get client internal ID
    $clientsUrl = "$KeycloakUrl/admin/realms/$RealmName/clients?clientId=$ClientId"
    $clients = Invoke-RestMethod -Uri $clientsUrl -Method Get -Headers $headers

    if ($clients.Count -eq 0) {
        Write-ErrorMsg "Client '$ClientId' not found"
        return
    }

    $internalClientId = $clients[0].id

    # Get available scopes
    $scopesUrl = "$KeycloakUrl/admin/realms/$RealmName/client-scopes"
    $availableScopes = Invoke-RestMethod -Uri $scopesUrl -Method Get -Headers $headers

    # Add scopes to client
    foreach ($scopeName in $Scopes) {
        $scopeObj = $availableScopes | Where-Object { $_.name -eq $scopeName }
        if ($scopeObj) {
            $scopeId = $scopeObj.id
            $assignUrl = "$KeycloakUrl/admin/realms/$RealmName/clients/$internalClientId/default-client-scopes/$scopeId"

            try {
                Invoke-RestMethod -Uri $assignUrl -Method Put -Headers $headers -ErrorAction Stop | Out-Null
                Write-Success "Scope '$scopeName' added to client '$ClientId'"
            }
            catch {
                if ($_.Exception.Response.StatusCode -eq 204) {
                    Write-InfoMsg "Scope '$scopeName' already assigned to '$ClientId'"
                }
                else {
                    Write-WarningMsg "Failed to add scope '$scopeName': $_"
                }
            }
        }
    }
}

function New-Role {
    param(
        [string]$Token,
        [string]$RoleName,
        [string]$Description
    )

    $url = "$KeycloakUrl/admin/realms/$RealmName/roles"
    $headers = @{
        Authorization  = "Bearer $Token"
        "Content-Type" = "application/json"
    }

    $body = @{
        name        = $RoleName
        description = $Description
    } | ConvertTo-Json

    try {
        Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body | Out-Null
        Write-Success "Role '$RoleName' created"
    }
    catch {
        if ($_.Exception.Response.StatusCode -eq 409) {
            Write-WarningMsg "Role '$RoleName' already exists"
        }
        else {
            Write-ErrorMsg "Failed to create role '$RoleName': $_"
        }
    }
}

function New-User {
    param(
        [string]$Token,
        [string]$Username,
        [string]$Email,
        [string]$Password,
        [string[]]$Roles
    )

    Write-InfoMsg "Creating user: $Username"

    $url = "$KeycloakUrl/admin/realms/$RealmName/users"
    $headers = @{
        Authorization  = "Bearer $Token"
        "Content-Type" = "application/json"
    }

    $body = @{
        username      = $Username
        email         = $Email
        emailVerified = $true
        enabled       = $true
        firstName     = $Username
        lastName      = "User"
        credentials   = @(
            @{
                type      = "password"
                value     = $Password
                temporary = $false
            }
        )
    } | ConvertTo-Json -Depth 10

    try {
        $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body
        Write-Success "User '$Username' created"
        return $response.id
    }
    catch {
        if ($_.Exception.Response.StatusCode -eq 409) {
            Write-WarningMsg "User '$Username' already exists"
            $getUrl = "$KeycloakUrl/admin/realms/$RealmName/users?username=$Username"
            $users = Invoke-RestMethod -Uri $getUrl -Method Get -Headers $headers
            return $users[0].id
        }
        else {
            Write-ErrorMsg "Failed to create user '$Username': $_"
            return $null
        }
    }
}

function Add-RoleToUser {
    param(
        [string]$Token,
        [string]$UserId,
        [string]$RoleName
    )

    $headers = @{
        Authorization  = "Bearer $Token"
        "Content-Type" = "application/json"
    }

    try {
        # Get the role ID
        $rolesUrl = "$KeycloakUrl/admin/realms/$RealmName/roles?search=$RoleName"
        $roles = Invoke-RestMethod -Uri $rolesUrl -Method Get -Headers $headers -ErrorAction Stop

        if ($roles -and $roles.Count -gt 0) {
            $roleId = $roles[0].id

            # Check if role is already assigned
            $userRolesUrl = "$KeycloakUrl/admin/realms/$RealmName/users/$UserId/role-mappings/realm"
            $userRoles = Invoke-RestMethod -Uri $userRolesUrl -Method Get -Headers $headers -ErrorAction Stop

            $roleExists = $userRoles | Where-Object { $_.id -eq $roleId }

            if ($roleExists) {
                Write-WarningMsg "Role '$RoleName' already assigned to user"
                return
            }

            # Assign the role - must be in array format
            $roleArray = @(
                @{
                    id   = $roleId
                    name = $RoleName
                }
            )

            # Force array JSON output
            if ($roleArray.Count -eq 1) {
                $body = "[" + ($roleArray[0] | ConvertTo-Json -Depth 10) + "]"
            }
            else {
                $body = $roleArray | ConvertTo-Json -Depth 10
            }

            Invoke-RestMethod -Uri $userRolesUrl -Method Post -Headers $headers -Body $body -ErrorAction Stop | Out-Null
            Write-Success "Role '$RoleName' assigned to user"
        }
        else {
            Write-ErrorMsg "Role '$RoleName' not found"
        }
    }
    catch {
        Write-ErrorMsg "Failed to assign role '$RoleName': $_"
    }
}
#endregion

#region Action Functions
function Invoke-Setup {
    param([string]$Token)

    Write-Header "KEYCLOAK COMPLETE SETUP"

    # Create realm
    New-Realm -Token $Token
    Enable-Realm -Token $Token

    # Create client scopes
    Write-Section "Creating Client Scopes"
    $scopes = @(
        @{ name = "orders.read"; desc = "Read orders" },
        @{ name = "orders.write"; desc = "Write orders" },
        @{ name = "inventory.read"; desc = "Read inventory" },
        @{ name = "inventory.write"; desc = "Write inventory" },
        @{ name = "notifications.read"; desc = "Read notifications" },
        @{ name = "notifications.write"; desc = "Write notifications" },
        @{ name = "audit.read"; desc = "Read audit logs" },
        @{ name = "audit.write"; desc = "Write audit logs" }
    )

    foreach ($scope in $scopes) {
        New-ClientScope -Token $Token -ScopeName $scope.name -Description $scope.desc
    }

    # Create API clients
    Write-Section "Creating API Clients"
    $clients = @(
        @{ id = "orders-api"; name = "Orders API"; scopes = @("orders.read", "orders.write") },
        @{ id = "inventory-api"; name = "Inventory API"; scopes = @("inventory.read", "inventory.write") },
        @{ id = "notifications-api"; name = "Notifications API"; scopes = @("notifications.read", "notifications.write") },
        @{ id = "audit-api"; name = "Audit API"; scopes = @("audit.read", "audit.write") },
        @{ id = "api-gateway"; name = "API Gateway"; scopes = @("orders.read", "orders.write", "inventory.read", "inventory.write", "notifications.read", "notifications.write", "audit.read", "audit.write") }
    )

    foreach ($client in $clients) {
        New-Client -Token $Token -ClientId $client.id -ClientName $client.name -Scopes $client.scopes
    }

    # Create roles
    Write-Section "Creating Roles"
    $roles = @(
        @{ name = "admin"; desc = "Administrator role" },
        @{ name = "user"; desc = "Regular user role" },
        @{ name = "orders-manager"; desc = "Orders manager role" },
        @{ name = "inventory-manager"; desc = "Inventory manager role" }
    )

    foreach ($role in $roles) {
        New-Role -Token $Token -RoleName $role.name -Description $role.desc
    }

    # Create test users
    Write-Section "Creating Test Users"
    $users = @(
        @{ username = "admin"; email = "admin@microservices.local"; password = "Admin@123"; roles = @("admin") },
        @{ username = "user"; email = "user@microservices.local"; password = "User@123"; roles = @("user") },
        @{ username = "orders-manager"; email = "orders@microservices.local"; password = "Orders@123"; roles = @("orders-manager") },
        @{ username = "inventory-manager"; email = "inventory@microservices.local"; password = "Inventory@123"; roles = @("inventory-manager") }
    )

    foreach ($user in $users) {
        $userId = New-User -Token $Token -Username $user.username -Email $user.email -Password $user.password -Roles $user.roles

        if ($userId) {
            foreach ($role in $user.roles) {
                Add-RoleToUser -Token $Token -UserId $userId -RoleName $role
            }
        }
    }

    Write-Host "`n✅ Keycloak setup completed successfully!" -ForegroundColor Green
    Write-Host "`nTest Credentials:" -ForegroundColor Cyan
    Write-Host "   Admin:              admin / Admin@123" -ForegroundColor White
    Write-Host "   User:               user / User@123" -ForegroundColor White
    Write-Host "   Orders Manager:     orders-manager / Orders@123" -ForegroundColor White
    Write-Host "   Inventory Manager:  inventory-manager / Inventory@123" -ForegroundColor White
    Write-Host "`nAccess Keycloak Admin Console: $KeycloakUrl/admin`n" -ForegroundColor Cyan
}

function Invoke-ConfigureFrontends {
    param([string]$Token)

    Write-Header "CONFIGURE FRONTEND CLIENTS"

    Enable-Realm -Token $Token

    # Configure Customer SPA
    Write-Section "Configuring Customer SPA"
    New-Client -Token $Token `
        -ClientId "customer-spa" `
        -ClientName "Customer SPA" `
        -Scopes @() `
        -PublicClient $true `
        -RedirectUris @("http://localhost:4200/*") `
        -WebOrigins @("http://localhost:4200")

    # Configure Admin PWA
    Write-Section "Configuring Admin PWA"
    New-Client -Token $Token `
        -ClientId "admin-pwa" `
        -ClientName "Admin PWA" `
        -Scopes @() `
        -PublicClient $true `
        -RedirectUris @("http://localhost:4201/*") `
        -WebOrigins @("http://localhost:4201")

    Write-Host "`n✅ Frontend clients configured!" -ForegroundColor Green
    Write-Host "`nFrontend Clients:" -ForegroundColor Cyan
    Write-Host "  Customer SPA: http://localhost:4200" -ForegroundColor Yellow
    Write-Host "  Admin PWA:    http://localhost:4201" -ForegroundColor Yellow
}

function Invoke-AddScopes {
    param([string]$Token)

    Write-Header "ADD SCOPES TO FRONTEND CLIENTS"

    $headers = @{
        Authorization  = "Bearer $Token"
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

    # Add scope mappers
    Write-Section "Adding Scope Mappers"
    foreach ($scopeName in $microserviceScopes) {
        $scope = $allScopes | Where-Object { $_.name -eq $scopeName }

        if ($scope) {
            Write-Success "Found scope: $scopeName (ID: $($scope.id))"
            Add-ScopeMapper -Token $Token -ScopeId $scope.id -ScopeName $scopeName
        }
        else {
            Write-ErrorMsg "Scope not found: $scopeName"
        }
    }

    # Add scopes to frontend clients
    Write-Section "Adding Scopes to Frontend Clients"
    $frontendClients = @("customer-spa", "admin-pwa")

    foreach ($clientId in $frontendClients) {
        Write-InfoMsg "Processing client: $clientId"
        Add-ScopesToClient -Token $Token -ClientId $clientId -Scopes $microserviceScopes
    }

    Write-Host "`n✅ Scopes added to frontend clients!" -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "1. Log out from the frontend applications" -ForegroundColor White
    Write-Host "2. Log in again to get a new token with the scopes" -ForegroundColor White
    Write-Host "3. Test API calls - they should now work!" -ForegroundColor White
}

function Invoke-TestToken {
    Write-Header "TEST TOKEN GENERATION"

    $body = @{
        grant_type = "password"
        client_id  = "orders-api"
        username   = $TestUsername
        password   = $TestPassword
    }

    Write-InfoMsg "Getting token for user: $TestUsername"

    try {
        $response = Invoke-RestMethod -Uri "$KeycloakUrl/realms/$RealmName/protocol/openid-connect/token" `
            -Method Post `
            -Body $body `
            -ContentType "application/x-www-form-urlencoded" `
            -ErrorAction Stop

        Write-Success "Token obtained!"
        Write-Host ""
        Write-Host "Token Details:" -ForegroundColor Cyan
        Write-Host "  Access Token: $($response.access_token.Substring(0, 50))..." -ForegroundColor White
        Write-Host "  Token Type: $($response.token_type)" -ForegroundColor White
        Write-Host "  Expires In: $($response.expires_in) seconds" -ForegroundColor White
        Write-Host "  Refresh Token: $($response.refresh_token.Substring(0, 50))..." -ForegroundColor White

        # Decode token to show claims
        Write-Host ""
        Write-Host "Token Claims (decoded):" -ForegroundColor Cyan

        $parts = $response.access_token.Split(".")
        $payload = $parts[1]

        # Add padding if needed
        $padding = 4 - ($payload.Length % 4)
        if ($padding -ne 4) {
            $payload += "=" * $padding
        }

        $decoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($payload))
        $claims = $decoded | ConvertFrom-Json

        Write-Host "  Subject (sub): $($claims.sub)" -ForegroundColor White
        Write-Host "  Username: $($claims.preferred_username)" -ForegroundColor White
        Write-Host "  Scopes: $($claims.scope)" -ForegroundColor White
        Write-Host "  Roles: $($claims.realm_access.roles -join ', ')" -ForegroundColor White

        Write-Host ""
        Write-Host "✅ Authentication is working correctly!" -ForegroundColor Green
    }
    catch {
        Write-ErrorMsg "Failed to get token"
        Write-ErrorMsg $_.Exception.Message
    }
}

function Invoke-Debug {
    param([string]$Token)

    Write-Header "DEBUG KEYCLOAK CONFIGURATION"

    $headers = @{
        Authorization = "Bearer $Token"
    }

    # Get users
    Write-Section "Users"
    $usersUrl = "$KeycloakUrl/admin/realms/$RealmName/users"
    $users = Invoke-RestMethod -Uri $usersUrl -Method Get -Headers $headers

    Write-InfoMsg "Found $($users.Count) users:"
    foreach ($user in $users) {
        Write-Host "  - Username: $($user.username), ID: $($user.id), Email: $($user.email)" -ForegroundColor White

        # Get user roles
        $userRolesUrl = "$KeycloakUrl/admin/realms/$RealmName/users/$($user.id)/role-mappings/realm"
        $userRoles = Invoke-RestMethod -Uri $userRolesUrl -Method Get -Headers $headers
        $customRoles = $userRoles | Where-Object { $_.name -notin @("default-roles-$RealmName", "offline_access", "uma_authorization") }

        if ($customRoles.Count -gt 0) {
            Write-Host "    Roles: $($customRoles.name -join ', ')" -ForegroundColor Yellow
        }
    }

    # Get clients
    Write-Section "Clients"
    $clientsUrl = "$KeycloakUrl/admin/realms/$RealmName/clients"
    $clients = Invoke-RestMethod -Uri $clientsUrl -Method Get -Headers $headers

    $customClients = $clients | Where-Object { $_.clientId -notlike "realm-*" -and $_.clientId -notlike "account*" -and $_.clientId -notlike "broker" -and $_.clientId -notlike "security-admin-console" }

    Write-InfoMsg "Found $($customClients.Count) custom clients:"
    foreach ($client in $customClients) {
        Write-Host "  - Client ID: $($client.clientId), Name: $($client.name), Public: $($client.publicClient)" -ForegroundColor White
    }

    # Get client scopes
    Write-Section "Client Scopes"
    $scopesUrl = "$KeycloakUrl/admin/realms/$RealmName/client-scopes"
    $scopes = Invoke-RestMethod -Uri $scopesUrl -Method Get -Headers $headers

    $customScopes = $scopes | Where-Object { $_.name -like "*.*" }

    Write-InfoMsg "Found $($customScopes.Count) custom scopes:"
    foreach ($scope in $customScopes) {
        Write-Host "  - Scope: $($scope.name), Description: $($scope.description)" -ForegroundColor White
    }

    # Get roles
    Write-Section "Roles"
    $rolesUrl = "$KeycloakUrl/admin/realms/$RealmName/roles"
    $roles = Invoke-RestMethod -Uri $rolesUrl -Method Get -Headers $headers

    $customRoles = $roles | Where-Object { $_.name -notin @("default-roles-$RealmName", "offline_access", "uma_authorization") }

    Write-InfoMsg "Found $($customRoles.Count) custom roles:"
    foreach ($role in $customRoles) {
        Write-Host "  - Role: $($role.name), Description: $($role.description)" -ForegroundColor White
    }

    Write-Host "`n✅ Debug information displayed!" -ForegroundColor Green
}

function Invoke-EnablePasswordGrant {
    param([string]$Token)

    Write-Header "ENABLE PASSWORD GRANT"

    $headers = @{
        Authorization  = "Bearer $Token"
        "Content-Type" = "application/json"
    }

    $clientsUrl = "$KeycloakUrl/admin/realms/$RealmName/clients"
    $clients = Invoke-RestMethod -Uri $clientsUrl -Method Get -Headers $headers

    $apiClients = @("orders-api", "inventory-api", "notifications-api", "audit-api", "api-gateway")

    foreach ($clientName in $apiClients) {
        $client = $clients | Where-Object { $_.clientId -eq $clientName }

        if ($client) {
            Write-InfoMsg "Updating client: $clientName"

            $client.directAccessGrantsEnabled = $true
            $client.standardFlowEnabled = $true
            $client.implicitFlowEnabled = $false

            $updateBody = $client | ConvertTo-Json -Depth 10

            try {
                $uri = "$KeycloakUrl/admin/realms/$RealmName/clients/$($client.id)"
                Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -Body $updateBody -ErrorAction Stop | Out-Null
                Write-Success "Password grant enabled for '$clientName'"
            }
            catch {
                Write-ErrorMsg "Failed to update '$clientName': $_"
            }
        }
        else {
            Write-WarningMsg "Client not found: $clientName"
        }
    }

    Write-Host "`n✅ Password grant enabled for all API clients!" -ForegroundColor Green
}

function Show-Help {
    Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║           KEYCLOAK MANAGER - HELP                              ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

    Write-Host "USAGE:" -ForegroundColor Yellow
    Write-Host "  .\keycloak-manager.ps1 -Action <action> [parameters]`n" -ForegroundColor White

    Write-Host "ACTIONS:" -ForegroundColor Yellow
    Write-Host "  Setup                 - Complete Keycloak setup (realm, clients, scopes, roles, users)" -ForegroundColor White
    Write-Host "  ConfigureFrontends    - Configure Angular frontend clients (customer-spa, admin-pwa)" -ForegroundColor White
    Write-Host "  AddScopes             - Add microservice scopes to frontend clients" -ForegroundColor White
    Write-Host "  TestToken             - Test token generation and display claims" -ForegroundColor White
    Write-Host "  Debug                 - Display all Keycloak configuration (users, clients, scopes, roles)" -ForegroundColor White
    Write-Host "  EnablePasswordGrant   - Enable password grant for API clients" -ForegroundColor White
    Write-Host "  All                   - Run all setup actions (Setup + ConfigureFrontends + AddScopes)" -ForegroundColor White
    Write-Host "  Help                  - Display this help message`n" -ForegroundColor White

    Write-Host "PARAMETERS:" -ForegroundColor Yellow
    Write-Host "  -KeycloakUrl          - Keycloak URL (default: http://localhost:8080)" -ForegroundColor White
    Write-Host "  -AdminUser            - Admin username (default: admin)" -ForegroundColor White
    Write-Host "  -AdminPassword        - Admin password (default: admin)" -ForegroundColor White
    Write-Host "  -RealmName            - Realm name (default: microservices)" -ForegroundColor White
    Write-Host "  -TestUsername         - Test user for token generation (default: admin)" -ForegroundColor White
    Write-Host "  -TestPassword         - Test password for token generation (default: Admin@123)`n" -ForegroundColor White

    Write-Host "EXAMPLES:" -ForegroundColor Yellow
    Write-Host "  # Complete setup" -ForegroundColor Green
    Write-Host "  .\keycloak-manager.ps1 -Action Setup`n" -ForegroundColor White

    Write-Host "  # Configure frontends only" -ForegroundColor Green
    Write-Host "  .\keycloak-manager.ps1 -Action ConfigureFrontends`n" -ForegroundColor White

    Write-Host "  # Add scopes to frontend clients" -ForegroundColor Green
    Write-Host "  .\keycloak-manager.ps1 -Action AddScopes`n" -ForegroundColor White

    Write-Host "  # Test token generation" -ForegroundColor Green
    Write-Host "  .\keycloak-manager.ps1 -Action TestToken -TestUsername admin -TestPassword Admin@123`n" -ForegroundColor White

    Write-Host "  # Debug configuration" -ForegroundColor Green
    Write-Host "  .\keycloak-manager.ps1 -Action Debug`n" -ForegroundColor White

    Write-Host "  # Run everything" -ForegroundColor Green
    Write-Host "  .\keycloak-manager.ps1 -Action All`n" -ForegroundColor White
}
#endregion

#region Main Execution
if ($Action -eq "Help") {
    Show-Help
    exit 0
}

# Check Keycloak availability
if (-not (Test-KeycloakAvailability)) {
    exit 1
}

# Get admin token (not needed for TestToken action)
$token = $null
if ($Action -ne "TestToken") {
    $token = Get-AdminToken
    if (-not $token) {
        exit 1
    }
}

# Execute action
switch ($Action) {
    "Setup" {
        Invoke-Setup -Token $token
    }
    "ConfigureFrontends" {
        Invoke-ConfigureFrontends -Token $token
    }
    "AddScopes" {
        Invoke-AddScopes -Token $token
    }
    "TestToken" {
        Invoke-TestToken
    }
    "Debug" {
        Invoke-Debug -Token $token
    }
    "EnablePasswordGrant" {
        Invoke-EnablePasswordGrant -Token $token
    }
    "All" {
        Invoke-Setup -Token $token
        Invoke-ConfigureFrontends -Token $token
        Invoke-AddScopes -Token $token
        Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║     ✅ ALL KEYCLOAK CONFIGURATION COMPLETED!                   ║" -ForegroundColor Green
        Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Green
    }
}
#endregion

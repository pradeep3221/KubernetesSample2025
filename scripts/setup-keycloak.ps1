# Keycloak Automated Setup Script
# This script configures Keycloak with realms, clients, scopes, roles, and test users
# Prerequisites: Keycloak must be running on http://localhost:8080

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

# Create realm
function New-Realm {
    param(
        [string]$Token,
        [string]$RealmName
    )
    
    Write-InfoMsg "Creating realm: $RealmName"
    
    $url = "$KeycloakUrl/admin/realms"
    $headers = @{
        Authorization = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    $body = @{
        realm                   = $RealmName
        enabled                 = $true
        displayName             = "Microservices Realm"
        displayNameHtml         = "<b>Microservices Realm</b>"
        accessTokenLifespan     = 3600
        refreshTokenLifespan    = 86400
        sslRequired             = "none"
        registrationAllowed     = $false
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

# Create client scope
function New-ClientScope {
    param(
        [string]$Token,
        [string]$ScopeName,
        [string]$Description
    )
    
    $url = "$KeycloakUrl/admin/realms/$RealmName/client-scopes"
    $headers = @{
        Authorization = "Bearer $Token"
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

# Create client
function New-Client {
    param(
        [string]$Token,
        [string]$ClientId,
        [string]$ClientName,
        [string[]]$Scopes
    )
    
    Write-InfoMsg "Creating client: $ClientId"
    
    $url = "$KeycloakUrl/admin/realms/$RealmName/clients"
    $headers = @{
        Authorization = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    $body = @{
        clientId                = $ClientId
        name                    = $ClientName
        enabled                 = $true
        publicClient            = $false
        protocol                = "openid-connect"
        standardFlowEnabled     = $true
        implicitFlowEnabled     = $false
        directAccessGrantsEnabled = $true
        serviceAccountsEnabled  = $true
        authorizationServicesEnabled = $true
        redirectUris            = @("http://localhost:*/*", "http://127.0.0.1:*/*")
        webOrigins              = @("*")
        defaultClientScopes     = $Scopes
        optionalClientScopes    = $Scopes
    } | ConvertTo-Json -Depth 10
    
    try {
        $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body
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

# Create role
function New-Role {
    param(
        [string]$Token,
        [string]$RoleName,
        [string]$Description
    )
    
    $url = "$KeycloakUrl/admin/realms/$RealmName/roles"
    $headers = @{
        Authorization = "Bearer $Token"
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

# Create user
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
        Authorization = "Bearer $Token"
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
                type  = "password"
                value = $Password
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

# Assign role to user
function Add-RoleToUser {
    param(
        [string]$Token,
        [string]$UserId,
        [string]$RoleName
    )

    $headers = @{
        Authorization = "Bearer $Token"
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

# Main execution
Write-Host "`n=== Keycloak Automated Setup ===" -ForegroundColor Magenta

# Check if Keycloak is running
Write-InfoMsg "Checking Keycloak availability at $KeycloakUrl..."
try {
    $response = Invoke-RestMethod -Uri "$KeycloakUrl/" -Method Get -ErrorAction Stop
    Write-Success "Keycloak is running"
}
catch {
    Write-ErrorMsg "Keycloak is not accessible at $KeycloakUrl"
    Write-ErrorMsg "Please ensure Keycloak is running: docker-compose up -d keycloak"
    exit 1
}

# Get admin token
$token = Get-AdminToken

# Create realm
New-Realm -Token $token -RealmName $RealmName

# Create client scopes
Write-Host "`n--- Creating Client Scopes ---" -ForegroundColor Yellow
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
    New-ClientScope -Token $token -ScopeName $scope.name -Description $scope.desc
}

# Create clients
Write-Host "`n--- Creating Clients ---" -ForegroundColor Yellow
$clients = @(
    @{ id = "orders-api"; name = "Orders API"; scopes = @("orders.read", "orders.write") },
    @{ id = "inventory-api"; name = "Inventory API"; scopes = @("inventory.read", "inventory.write") },
    @{ id = "notifications-api"; name = "Notifications API"; scopes = @("notifications.read", "notifications.write") },
    @{ id = "audit-api"; name = "Audit API"; scopes = @("audit.read", "audit.write") },
    @{ id = "api-gateway"; name = "API Gateway"; scopes = @("orders.read", "orders.write", "inventory.read", "inventory.write", "notifications.read", "notifications.write", "audit.read", "audit.write") }
)

foreach ($client in $clients) {
    New-Client -Token $token -ClientId $client.id -ClientName $client.name -Scopes $client.scopes
}

# Create roles
Write-Host "`n--- Creating Roles ---" -ForegroundColor Yellow
$roles = @(
    @{ name = "admin"; desc = "Administrator role" },
    @{ name = "user"; desc = "Regular user role" },
    @{ name = "orders-manager"; desc = "Orders manager role" },
    @{ name = "inventory-manager"; desc = "Inventory manager role" }
)

foreach ($role in $roles) {
    New-Role -Token $token -RoleName $role.name -Description $role.desc
}

# Create test users
Write-Host "`n--- Creating Test Users ---" -ForegroundColor Yellow
$users = @(
    @{ username = "admin"; email = "admin@microservices.local"; password = "Admin@123"; roles = @("admin") },
    @{ username = "user"; email = "user@microservices.local"; password = "User@123"; roles = @("user") },
    @{ username = "orders-manager"; email = "orders@microservices.local"; password = "Orders@123"; roles = @("orders-manager") },
    @{ username = "inventory-manager"; email = "inventory@microservices.local"; password = "Inventory@123"; roles = @("inventory-manager") }
)

foreach ($user in $users) {
    $userId = New-User -Token $token -Username $user.username -Email $user.email -Password $user.password -Roles $user.roles
    
    if ($userId) {
        foreach ($role in $user.roles) {
            Add-RoleToUser -Token $token -UserId $userId -RoleName $role
        }
    }
}

Write-Host "`n=== Keycloak setup completed successfully! ===" -ForegroundColor Green
Write-Host "`nTest Credentials:" -ForegroundColor Cyan
Write-Host "   Admin:              admin / Admin@123" -ForegroundColor White
Write-Host "   User:               user / User@123" -ForegroundColor White
Write-Host "   Orders Manager:     orders-manager / Orders@123" -ForegroundColor White
Write-Host "   Inventory Manager:  inventory-manager / Inventory@123" -ForegroundColor White
Write-Host "`nAccess Keycloak Admin Console: $KeycloakUrl/admin`n" -ForegroundColor Cyan


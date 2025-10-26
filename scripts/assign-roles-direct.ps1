# Direct Role Assignment using Keycloak Admin API
# This uses the correct endpoint format

param(
    [string]$KeycloakUrl = "http://localhost:8080",
    [string]$AdminUser = "admin",
    [string]$AdminPassword = "admin",
    [string]$RealmName = "microservices"
)

Write-Host "=== Direct Role Assignment ===" -ForegroundColor Magenta

# Get admin token
$tokenUrl = "$KeycloakUrl/realms/master/protocol/openid-connect/token"
$body = @{
    grant_type    = "password"
    client_id     = "admin-cli"
    username      = $AdminUser
    password      = $AdminPassword
}

$response = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"
$token = $response.access_token

$headers = @{
    Authorization = "Bearer $token"
    "Content-Type" = "application/json"
}

# Get users
$usersUrl = "$KeycloakUrl/admin/realms/$RealmName/users"
$users = Invoke-RestMethod -Uri $usersUrl -Method Get -Headers $headers

# Get roles
$rolesUrl = "$KeycloakUrl/admin/realms/$RealmName/roles"
$roles = Invoke-RestMethod -Uri $rolesUrl -Method Get -Headers $headers

# Test with admin user and admin role
$adminUser = $users | Where-Object { $_.username -eq "admin" }
$adminRole = $roles | Where-Object { $_.name -eq "admin" }

if ($adminUser -and $adminRole) {
    Write-Host "[INFO] Admin User ID: $($adminUser.id)" -ForegroundColor Cyan
    Write-Host "[INFO] Admin Role ID: $($adminRole.id)" -ForegroundColor Cyan
    
    # Try different endpoint formats
    $endpoints = @(
        "$KeycloakUrl/admin/realms/$RealmName/users/$($adminUser.id)/role-mappings/realm",
        "$KeycloakUrl/admin/realms/$RealmName/users/$($adminUser.id)/role-mappings/realm/$($adminRole.id)",
        "$KeycloakUrl/admin/realms/$RealmName/users/$($adminUser.id)/role-mappings"
    )
    
    foreach ($endpoint in $endpoints) {
        Write-Host "[INFO] Trying endpoint: $endpoint" -ForegroundColor Cyan
        
        $roleBody = @(
            @{
                id   = $adminRole.id
                name = $adminRole.name
            }
        ) | ConvertTo-Json -Depth 10
        
        try {
            $result = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body $roleBody -ErrorAction Stop
            Write-Host "[SUCCESS] Role assigned!" -ForegroundColor Green
            Write-Host $result
            break
        }
        catch {
            Write-Host "[ERROR] Failed: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
            Write-Host $_.Exception.Message
        }
    }
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Magenta


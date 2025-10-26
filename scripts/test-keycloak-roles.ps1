# Test Keycloak Role Assignment
param(
    [string]$KeycloakUrl = "http://localhost:8080",
    [string]$AdminUser = "admin",
    [string]$AdminPassword = "admin",
    [string]$RealmName = "microservices"
)

Write-Host "=== Testing Keycloak Role Assignment ===" -ForegroundColor Magenta

# Get admin token
Write-Host "[INFO] Getting admin token..." -ForegroundColor Cyan
$tokenUrl = "$KeycloakUrl/realms/master/protocol/openid-connect/token"
$body = @{
    grant_type    = "password"
    client_id     = "admin-cli"
    username      = $AdminUser
    password      = $AdminPassword
}

try {
    $response = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"
    $token = $response.access_token
    Write-Host "[SUCCESS] Admin token obtained" -ForegroundColor Green
}
catch {
    Write-Host "[ERROR] Failed to obtain admin token: $_" -ForegroundColor Red
    exit 1
}

$headers = @{
    Authorization = "Bearer $token"
    "Content-Type" = "application/json"
}

# Get users
Write-Host "[INFO] Getting users..." -ForegroundColor Cyan
$usersUrl = "$KeycloakUrl/admin/realms/$RealmName/users"
$users = Invoke-RestMethod -Uri $usersUrl -Method Get -Headers $headers

Write-Host "[SUCCESS] Found $($users.Count) users" -ForegroundColor Green
$users | ForEach-Object {
    Write-Host "  - $($_.username) (ID: $($_.id))" -ForegroundColor White
}

# Get roles
Write-Host "[INFO] Getting roles..." -ForegroundColor Cyan
$rolesUrl = "$KeycloakUrl/admin/realms/$RealmName/roles"
$roles = Invoke-RestMethod -Uri $rolesUrl -Method Get -Headers $headers

Write-Host "[SUCCESS] Found $($roles.Count) roles" -ForegroundColor Green
$roles | ForEach-Object {
    Write-Host "  - $($_.name) (ID: $($_.id))" -ForegroundColor White
}

# Test role assignment for each user
Write-Host "[INFO] Testing role assignment..." -ForegroundColor Cyan

$testAssignments = @(
    @{ username = "admin"; role = "admin" },
    @{ username = "user"; role = "user" },
    @{ username = "orders-manager"; role = "orders-manager" },
    @{ username = "inventory-manager"; role = "inventory-manager" }
)

foreach ($assignment in $testAssignments) {
    $user = $users | Where-Object { $_.username -eq $assignment.username }
    $role = $roles | Where-Object { $_.name -eq $assignment.role }
    
    if ($user -and $role) {
        Write-Host "[INFO] Assigning role '$($assignment.role)' to user '$($assignment.username)'..." -ForegroundColor Cyan
        
        $assignUrl = "$KeycloakUrl/admin/realms/$RealmName/users/$($user.id)/role-mappings/realm"
        
        $roleBody = @(
            @{
                id   = $role.id
                name = $role.name
            }
        ) | ConvertTo-Json -Depth 10
        
        try {
            Invoke-RestMethod -Uri $assignUrl -Method Post -Headers $headers -Body $roleBody -ErrorAction Stop | Out-Null
            Write-Host "[SUCCESS] Role assigned successfully" -ForegroundColor Green
        }
        catch {
            Write-Host "[ERROR] Failed to assign role: $_" -ForegroundColor Red
            
            # Try to get more details
            Write-Host "[INFO] Checking current role assignments..." -ForegroundColor Cyan
            try {
                $currentRoles = Invoke-RestMethod -Uri $assignUrl -Method Get -Headers $headers
                Write-Host "[INFO] Current roles for user: $($currentRoles.Count)" -ForegroundColor Cyan
                $currentRoles | ForEach-Object {
                    Write-Host "  - $($_.name)" -ForegroundColor White
                }
            }
            catch {
                Write-Host "[ERROR] Failed to get current roles: $_" -ForegroundColor Red
            }
        }
    }
    else {
        if (-not $user) {
            Write-Host "[ERROR] User '$($assignment.username)' not found" -ForegroundColor Red
        }
        if (-not $role) {
            Write-Host "[ERROR] Role '$($assignment.role)' not found" -ForegroundColor Red
        }
    }
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Magenta


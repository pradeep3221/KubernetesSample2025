# Fix Keycloak Role Assignment - Alternative Approach
# This script uses a different method to assign roles

param(
    [string]$KeycloakUrl = "http://localhost:8080",
    [string]$AdminUser = "admin",
    [string]$AdminPassword = "admin",
    [string]$RealmName = "microservices"
)

Write-Host "=== Fixing Keycloak Role Assignment ===" -ForegroundColor Magenta

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

# Get roles
Write-Host "[INFO] Getting roles..." -ForegroundColor Cyan
$rolesUrl = "$KeycloakUrl/admin/realms/$RealmName/roles"
$roles = Invoke-RestMethod -Uri $rolesUrl -Method Get -Headers $headers

# Filter out default roles
$customRoles = $roles | Where-Object { $_.name -notin @("default-roles-microservices", "offline_access", "uma_authorization") }

Write-Host "[SUCCESS] Found $($customRoles.Count) custom roles" -ForegroundColor Green

# Assign roles using a PUT request instead of POST
Write-Host "[INFO] Assigning roles to users..." -ForegroundColor Cyan

$roleAssignments = @(
    @{ username = "admin"; roles = @("admin") },
    @{ username = "user"; roles = @("user") },
    @{ username = "orders-manager"; roles = @("orders-manager") },
    @{ username = "inventory-manager"; roles = @("inventory-manager") }
)

foreach ($assignment in $roleAssignments) {
    $user = $users | Where-Object { $_.username -eq $assignment.username }
    
    if ($user) {
        Write-Host "[INFO] Processing user: $($assignment.username)" -ForegroundColor Cyan
        
        foreach ($roleName in $assignment.roles) {
            $role = $customRoles | Where-Object { $_.name -eq $roleName }
            
            if ($role) {
                Write-Host "  [INFO] Assigning role: $roleName" -ForegroundColor Cyan
                
                # Try using PUT with the role object
                $assignUrl = "$KeycloakUrl/admin/realms/$RealmName/users/$($user.id)/role-mappings/realm"
                
                $roleBody = @(
                    @{
                        id   = $role.id
                        name = $role.name
                    }
                ) | ConvertTo-Json -Depth 10
                
                try {
                    # First, check if role is already assigned
                    $currentRoles = Invoke-RestMethod -Uri $assignUrl -Method Get -Headers $headers
                    $roleExists = $currentRoles | Where-Object { $_.id -eq $role.id }
                    
                    if ($roleExists) {
                        Write-Host "  [WARNING] Role already assigned" -ForegroundColor Yellow
                    }
                    else {
                        # Try POST
                        Invoke-RestMethod -Uri $assignUrl -Method Post -Headers $headers -Body $roleBody -ErrorAction Stop | Out-Null
                        Write-Host "  [SUCCESS] Role assigned" -ForegroundColor Green
                    }
                }
                catch {
                    Write-Host "  [ERROR] POST failed: $_" -ForegroundColor Red
                    
                    # Try alternative: Update user with roles
                    Write-Host "  [INFO] Trying alternative method..." -ForegroundColor Cyan
                    try {
                        $userUrl = "$KeycloakUrl/admin/realms/$RealmName/users/$($user.id)"
                        $userBody = @{
                            realmRoles = @($roleName)
                        } | ConvertTo-Json
                        
                        Invoke-RestMethod -Uri $userUrl -Method Put -Headers $headers -Body $userBody -ErrorAction Stop | Out-Null
                        Write-Host "  [SUCCESS] Role assigned via alternative method" -ForegroundColor Green
                    }
                    catch {
                        Write-Host "  [ERROR] Alternative method also failed: $_" -ForegroundColor Red
                    }
                }
            }
            else {
                Write-Host "  [ERROR] Role not found: $roleName" -ForegroundColor Red
            }
        }
    }
    else {
        Write-Host "[ERROR] User not found: $($assignment.username)" -ForegroundColor Red
    }
}

# Verify role assignments
Write-Host "`n[INFO] Verifying role assignments..." -ForegroundColor Cyan
foreach ($user in $users) {
    $assignUrl = "$KeycloakUrl/admin/realms/$RealmName/users/$($user.id)/role-mappings/realm"
    try {
        $userRoles = Invoke-RestMethod -Uri $assignUrl -Method Get -Headers $headers
        $customUserRoles = $userRoles | Where-Object { $_.name -notin @("default-roles-microservices", "offline_access", "uma_authorization") }
        
        if ($customUserRoles.Count -gt 0) {
            Write-Host "[SUCCESS] User '$($user.username)' has roles:" -ForegroundColor Green
            $customUserRoles | ForEach-Object {
                Write-Host "  - $($_.name)" -ForegroundColor White
            }
        }
        else {
            Write-Host "[WARNING] User '$($user.username)' has no custom roles" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "[ERROR] Failed to get roles for user '$($user.username)': $_" -ForegroundColor Red
    }
}

Write-Host "`n=== Fix Complete ===" -ForegroundColor Magenta


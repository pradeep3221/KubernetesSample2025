# Working Role Assignment Script

$KeycloakUrl = "http://localhost:8080"
$RealmName = "microservices"

# Get token
$body = @{
    grant_type = "password"
    client_id = "admin-cli"
    username = "admin"
    password = "admin"
}

Write-Host "Getting admin token..." -ForegroundColor Cyan
$response = Invoke-RestMethod -Uri "$KeycloakUrl/realms/master/protocol/openid-connect/token" -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"
$token = $response.access_token
Write-Host "Token obtained" -ForegroundColor Green

$headers = @{
    Authorization = "Bearer $token"
    "Content-Type" = "application/json"
}

# Get users
Write-Host "Getting users..." -ForegroundColor Cyan
$users = Invoke-RestMethod -Uri "$KeycloakUrl/admin/realms/$RealmName/users" -Method Get -Headers $headers

# Get roles
Write-Host "Getting roles..." -ForegroundColor Cyan
$roles = Invoke-RestMethod -Uri "$KeycloakUrl/admin/realms/$RealmName/roles" -Method Get -Headers $headers

# Define role assignments
$assignments = @(
    @{ username = "admin"; role = "admin" },
    @{ username = "user"; role = "user" },
    @{ username = "orders-manager"; role = "orders-manager" },
    @{ username = "inventory-manager"; role = "inventory-manager" }
)

# Assign roles
foreach ($assignment in $assignments) {
    $user = $users | Where-Object { $_.username -eq $assignment.username }
    $role = $roles | Where-Object { $_.name -eq $assignment.role }
    
    if ($user -and $role) {
        Write-Host "Assigning role '$($assignment.role)' to user '$($assignment.username)'..." -ForegroundColor Cyan
        
        $url = "$KeycloakUrl/admin/realms/$RealmName/users/$($user.id)/role-mappings/realm"

        $roleArray = @(
            @{
                id   = $role.id
                name = $role.name
            }
        )

        # Force array JSON output
        if ($roleArray.Count -eq 1) {
            $body = "[" + ($roleArray[0] | ConvertTo-Json -Depth 10) + "]"
        }
        else {
            $body = $roleArray | ConvertTo-Json -Depth 10
        }

        Write-Host "URL: $url" -ForegroundColor Gray
        Write-Host "Body: $body" -ForegroundColor Gray
        
        try {
            $result = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body -ErrorAction Stop
            Write-Host "SUCCESS" -ForegroundColor Green
        }
        catch {
            Write-Host "FAILED: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "Response: $($_.Exception.Response)" -ForegroundColor Red
        }
    }
}

Write-Host "`nDone" -ForegroundColor Magenta


# Enable Password Grant for Clients

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

# Get clients
Write-Host "Getting clients..." -ForegroundColor Cyan
$clients = Invoke-RestMethod -Uri "$KeycloakUrl/admin/realms/$RealmName/clients" -Method Get -Headers $headers

# Enable password grant for each client
$clientNames = @("orders-api", "inventory-api", "notifications-api", "audit-api", "api-gateway")

foreach ($clientName in $clientNames) {
    $client = $clients | Where-Object { $_.clientId -eq $clientName }

    if ($client) {
        Write-Host "Updating client: $clientName" -ForegroundColor Cyan

        # Enable password grant
        $client.directAccessGrantsEnabled = $true
        $client.standardFlowEnabled = $true
        $client.implicitFlowEnabled = $false
        $client.serviceAccountsEnabled = $false

        $updateBody = $client | ConvertTo-Json -Depth 10

        try {
            $uri = "$KeycloakUrl/admin/realms/$RealmName/clients/$($client.id)"
            Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -Body $updateBody -ErrorAction Stop | Out-Null
            Write-Host "  [SUCCESS] Password grant enabled" -ForegroundColor Green
        }
        catch {
            Write-Host "  [ERROR] Failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    else {
        Write-Host "Client not found: $clientName" -ForegroundColor Red
    }
}

Write-Host "Done" -ForegroundColor Magenta

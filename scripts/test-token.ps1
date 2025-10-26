# Test Token Generation and Claims

$body = @{
    grant_type = "password"
    client_id = "orders-api"
    username = "admin"
    password = "Admin@123"
}

Write-Host "Getting token for admin user..." -ForegroundColor Cyan

try {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/realms/microservices/protocol/openid-connect/token" `
        -Method Post `
        -Body $body `
        -ContentType "application/x-www-form-urlencoded" `
        -ErrorAction Stop
    
    Write-Host "SUCCESS: Token obtained!" -ForegroundColor Green
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
    Write-Host "FAILED: Could not get token" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}


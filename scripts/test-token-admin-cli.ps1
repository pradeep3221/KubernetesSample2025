# Test Token Generation with admin-cli

$body = @{
    grant_type = "password"
    client_id = "admin-cli"
    username = "admin"
    password = "admin"
}

Write-Host "Getting token for admin user using admin-cli..." -ForegroundColor Cyan

try {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/realms/master/protocol/openid-connect/token" `
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
    
    Write-Host ""
    Write-Host "✅ Authentication is working correctly!" -ForegroundColor Green
}
catch {
    Write-Host "FAILED: Could not get token" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}


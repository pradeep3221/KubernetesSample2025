# Debug Users Script

$body = @{
    grant_type = "password"
    client_id = "admin-cli"
    username = "admin"
    password = "admin"
}

Write-Host "Getting token..." -ForegroundColor Cyan
$response = Invoke-RestMethod -Uri "http://localhost:8080/realms/master/protocol/openid-connect/token" -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"
$token = $response.access_token
Write-Host "Token obtained" -ForegroundColor Green

$headers = @{
    Authorization = "Bearer $token"
}

Write-Host "Getting users..." -ForegroundColor Cyan
$users = Invoke-RestMethod -Uri "http://localhost:8080/admin/realms/microservices/users" -Method Get -Headers $headers

Write-Host "Users found: $($users.Count)" -ForegroundColor Green

for ($i = 0; $i -lt $users.Count; $i++) {
    $user = $users[$i]
    Write-Host "User $i : Username=$($user.username), ID=$($user.id)" -ForegroundColor White
}


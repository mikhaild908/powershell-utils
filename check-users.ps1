param([string]$server = "SERVER-NAME")

Write-Host "Getting logged-in users for Server [$server]`n" -ForegroundColor Green

try {
    # quser /server:$server 2>$null
    $query = quser /server:$server 2>&1

    if ($LASTEXITCODE -ne 0 -or $query -match "No User exists for") {
        Write-Output "No logged-on users found."
    } else {
        $query
    }
}
catch {
    Write-Error "Unable to query $server"
}

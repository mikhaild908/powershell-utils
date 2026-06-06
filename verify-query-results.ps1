param(
    [Parameter(Mandatory = $false)]   
    [string]$server = "SERVER-NAME",

    [Parameter(Mandatory = $false)]
    [string]$filePath = "./query.sql"
)

Write-Host "Executing  query from '$filePath' on server '$server'..." -ForegroundColor Cyan

$output = @(sqlcmd -S $server -E -i $filePath 2>&1)
$output | ForEach-Object { Write-Output $_ }

if ($LASTEXITCODE -ne 0) {
    Write-Error "sqlcmd failed with exit code $LASTEXITCODE."
    exit $LASTEXITCODE
}

$rowsAffected = $null
$lastIndex = $output.Count - 1
for ($i = $lastIndex; $i -ge 0; $i--) {
    $line = $output[$i]
    if ($line -match '^\((\d+) rows affected\)$') {
        $rowsAffected = [int]$Matches[1]
        break
    }
}

if ($null -eq $rowsAffected) {
    Write-Error "Unable to determine row count from sqlcmd output."
}
elseif ($rowsAffected -eq 0) {
    Write-Error "Query returned no rows for the requested date range."
}
else {
    Write-Host "Query verification passed. Rows returned: $rowsAffected" -ForegroundColor Green
}

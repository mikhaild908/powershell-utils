param([string]$server = "SRPSVN07")
$credentials = Get-Credential -UserName USER-NAME

Write-Host "Getting services for StackVision Server [$server]`n" -ForegroundColor Green

Invoke-Command -ComputerName $server -Credential $credentials -ScriptBlock {
    Get-Service | Where-Object {
        $_.DisplayName -eq "SQL Server" `
        -or $_.DisplayName -like "SQL Server Reporting Services"        
    }    
}

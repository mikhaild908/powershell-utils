param(
    [Parameter(Mandatory = $false)]
    [string]$RemoteComputer = "REMOTE-COMPUTER",

    [Parameter(Mandatory = $false)]
    [string]$TaskPath = "\FOLDER\SUB-FOLDER",

    [Parameter(Mandatory = $false)]
    [string]$TaskName = "TASK-NAME"
)

$credentials = Get-Credential -UserName "USER-NAME"

try {
    $session = New-CimSession -ComputerName $RemoteComputer -Credential $credentials -ErrorAction Stop

    Write-Host "Getting task details for '$TaskName' on '$RemoteComputer'" -ForegroundColor Green
    $task = Get-ScheduledTask -CimSession $session | Where-Object { $_.TaskName -eq $TaskName }
    $taskInfo = Get-ScheduledTaskInfo -InputObject $task
    $actions = $task | Select-Object -ExpandProperty Actions

    Write-Host "`nTask details:" -ForegroundColor Green
    $actions
    $taskInfo
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    if($session) {
        Write-Host "`nClosing CIM session to '$RemoteComputer'." -ForegroundColor Yellow
        Remove-CimSession $session
    }
}
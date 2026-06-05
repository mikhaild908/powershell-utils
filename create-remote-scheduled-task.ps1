param(
    [Parameter(Mandatory = $false)]
    [string]$RemoteServer = "REMOTE-SERVER",

    [Parameter(Mandatory = $false)]
    [string]$TaskPath = "\FOLDER\SUB-FOLDER",

    [Parameter(Mandatory = $false)]
    [string]$TaskName = "TASK-NAME",

    [Parameter(Mandatory = $false)]
    [string]$ScriptPathOnRemoteServer = "C:\applications\app.exe",

    [Parameter(Mandatory = $false)]
    [string]$ActionArguments = "",

    [Parameter(Mandatory = $false)]
    [string]$TaskUser = "DOMAIN\USER" # "SYSTEM or USER-GMSA$"
)

$credential = Get-Credential -UserName "USERNAME" -Message "Enter credentials for $RemoteServer"
$cimSession = New-CimSession -ComputerName $RemoteServer -Credential $credential

try {
    # define action (what runs)
    $action = ($ActionArguments -eq "") ? (New-ScheduledTaskAction -Execute $ScriptPathOnRemoteServer)
        : (New-ScheduledTaskAction -Execute $ScriptPathOnRemoteServer -Argument $ActionArguments)

    # define principal/security context
    if($TaskUser -eq "SYSTEM") {
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount
    }
    elseif ($TaskUser -like "*$") {
        # gMSA account, example: DOMAIN\USER-GMSA$
        $principal = New-ScheduledTaskPrincipal -UserId $TaskUser -LogonType Password
    }
    else { 
        # passwordless user mode (S4U): no password stored, but limited for networ access
        $principal = New-ScheduledTaskPrincipal -UserId $TaskUser -LogonType S4U
    }

    #build task object with NO trigger (manual run only)
    $task = New-ScheduledTask -Action $action -Principal $principal

    # register task remotely (overwrite if exists)
    Register-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName -InputObject $task -CimSession $cimSession -Force

    Write-Host "Scheduled task '$TaskName' created on $RemoteServer (manual run only)." -ForegroundColor Green
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    if($cimSession) {
        Remove-CimSession $cimSession
    }
}
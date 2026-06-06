param([string]$server = "SERVER-NAME")
$credentials = Get-Credential -UserName USER-NAME

Write-Host "Getting Software Updates for Server [$server]`n" -ForegroundColor Green

try {
    # Test if the remote computer is reachable
    if (-not (Test-Connection -ComputerName $server -Count 1 -Quiet)) {
        Write-Error "Computer $server is not reachable."
        return
    }

    # Get pending software updates from SCCM WMI
    $updates = Get-WmiObject -Namespace "root\ccm\ClientSDK" `
                             -Class "CCM_SoftwareUpdate" `
                             -ComputerName $server `
                             -Credential $credentials `
                             -ErrorAction Stop |
               Where-Object { $_.EvaluationState -ne 0 }  # 0 = Not required

    if (-not $updates) {
        Write-Host "No pending updates found on $server."
        return
    }

    # Display update details
    $updates | Select-Object `
        @{Name="ArticleID"; Expression={$_.ArticleID}},
        @{Name="Title"; Expression={$_.Name}},
        @{Name="Status"; Expression={
            switch ($_.EvaluationState) {
                0 {"Not Required"}
                1 {"Required"}
                2 {"Installed"}
                3 {"Downloading"}
                4 {"Installing"}
                default {"Unknown ($($_.EvaluationState))"}
            }
        }},
        @{Name="Deadline"; Expression={$_.Deadline}}
}
catch {
    Write-Error "Failed to query updates from $server. $_"
}

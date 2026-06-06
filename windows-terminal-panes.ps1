param(
    [string]$environment = "DEV",
    [string]$serviceLogsFileName = "service.log",
    [string]$consoleLogsFileName = "console-application.log",
    [string]$scheduledTasksPath = "C:\Tasks\",
    [string]$logsPath = "\\Logs\Path\",    
    [string]$verifierScriptsFolder = "C:\Scripts",
    [string[]]$verifierScripts = @(
        (Join-Path $verifierScriptsFolder "first.ps1"),
        (Join-Path $verifierScriptsFolder "second.ps1")
    ),
    [ValidateRange(1, 100000)]
    [int]$tailLines = 100
)

$serviceLogPath = Join-Path $logsPath $serviceLogsFileName
$consoleLogPath = Join-Path $logsPath $consoleLogsFileName
$serviceTailCommand = "Get-Content -Path $serviceLogPath -Tail $tailLines"
$consoleTailCommand = "Get-Content -Path $consoleLogPath -Tail $tailLines"

# open windows explorer to the logs directory
explorer $logsPath

$tabs = @(
    @{
        Title     = "[$environment] $serviceLogsFileName"
        TabColor  = "#3A86FF"
        Directory = $logsPath
        Command   = "$serviceTailCommand\; Write-Host ''\; Write-Host ('Ran: ' + '$serviceTailCommand') -ForegroundColor Green"
    }
    @{
        Title     = "[$environment] $consoleLogsFileName"
        TabColor  = "#FFB900"
        Directory = $logsPath
        Command   = "$consoleTailCommand\; Write-Host ''\; Write-Host ('Ran: ' + '$consoleTailCommand') -ForegroundColor Green"
    }
    @{
        Title     = "[$environment] Scheduled Task Details"
        TabColor  = "#2ECC71"
        Directory = $scheduledTasksPath
        Command   = "ls"
    }
    @{
        Title     = "[$environment] Run Scheduled Task"
        TabColor  = "#FF006E"
        Directory = $scheduledTasksPath
        Command   = "ls"
    }
)

foreach ($verifierScript in $verifierScripts) {
    $scriptPath = if ([System.IO.Path]::IsPathRooted($verifierScript)) {
        $verifierScript
    }
    else {
        Join-Path $scheduledTasksPath $verifierScript
    }

    if ([System.IO.Path]::GetExtension($scriptPath) -ne ".ps1") {
        Write-Warning "Skipping non-ps1 verifier script: $verifierScript"
        continue
    }

    if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
        Write-Warning "Verifier script not found: $scriptPath"
        continue
    }

    $escapedScriptPath = $scriptPath -replace "'", "''"

    $tabs += @{
        Title     = "[$environment] Verifier: $(Split-Path $scriptPath -Leaf)"
        TabColor  = "#118AB2"
        Directory = (Split-Path $scriptPath -Parent)
        Command   = "& '$escapedScriptPath'"
    }
}

$wtArgs = @("-M")

for ($i = 0; $i -lt $tabs.Count; $i++) {
    $tab = $tabs[$i]

    if ($i -gt 0) {
        $wtArgs += ";"
    }

    $wtArgs += @(
        "new-tab"
        "--title";    $tab.Title
        "--tabColor"; $tab.TabColor
        "-d";         $tab.Directory
        "pwsh"
        "-NoExit"
    )

    if ($tab.Command) {
        $wtArgs += @(
            "-Command"; $tab.Command
        )
    }
}

& wt @wtArgs

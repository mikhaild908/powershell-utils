Import-Module Microsoft.PowerShell.ConsoleGuiTools
$module = (Get-Module Microsoft.Powershell.ConsoleGuiTools -List).ModuleBase
Add-Type -Path (Join-Path $module "Terminal.Gui.dll")

[Terminal.Gui.Application]::Init()

$gitServers = @(
    @{
        Name = "DEV"
        HostName = "DEV-SERVER"
    },
    @{
        Name = "TEST"
        HostName = "TEST-SERVER"
    }
)

$Window = [Terminal.Gui.Window]::new()
$Window.Title = "RDP"

$gitServersFrame = [Terminal.Gui.FrameView]::new()
$gitServerItems = [Terminal.Gui.ListView]::new()

function LaunchServer {
    param (
        [object[]]$servers,
        [Terminal.Gui.ListView]$listViewItems
    )

    if (-not $servers -or $servers.Count -eq 0) {
        [Terminal.Gui.MessageBox]::Query("No Servers", "No servers are configured.", @("Ok")) | Out-Null
        return
    }

    $selectedIndex = [int]$listViewItems.SelectedItem
    if ($selectedIndex -lt 0 -or $selectedIndex -ge $servers.Count) {
        [Terminal.Gui.MessageBox]::Query("No Selection", "Select a server first.", @("Ok")) | Out-Null
        return
    }

    $selectedName = $servers[$selectedIndex].Name
    $selectedHostName = $servers[$selectedIndex].HostName

    $rdpMessage = "Connect to " + $selectedHostName + " (" + $selectedName + ")"
    $result = [Terminal.Gui.MessageBox]::Query($selectedName, $rdpMessage, @("Ok", "Cancel"))

    if ($result -eq 0) {
        $command = "mstsc /v:$selectedHostName"
        Invoke-Expression $command
    }
    else {
        [Terminal.Gui.Application]::RequestStop()
    }
}

function BuildGitServersListView {
    $gitServersFrame.Width = [Terminal.Gui.Dim]::Percent(33)
    $gitServersFrame.Height = [Terminal.Gui.Dim]::Fill()
    $gitServersFrame.Title = "Git Servers"
    $Window.Add($gitServersFrame)

    $gitServerItems.SetSource(($gitServers | Select-Object -ExpandProperty Name))
    $gitServerItems.Width = [Terminal.Gui.Dim]::Fill()
    $gitServerItems.Height = [Terminal.Gui.Dim]::Percent(90)
    $gitServersFrame.Add($gitServerItems)

    $gitGoButton = [Terminal.Gui.Button]::new()
    $gitGoButton.Text = "CONNECT"
    $gitGoButton.Y = [Terminal.Gui.Pos]::Bottom($gitServerItems)

    $gitGoButton.add_Clicked({
        LaunchServer -servers $gitServers -listViewItems $gitServerItems        
    })

    $gitServersFrame.Add($gitGoButton)

    $exitButton = [Terminal.Gui.Button]::new()
    $exitButton.Text = "EXIT"
    $exitButton.Y = [Terminal.Gui.Pos]::Bottom($gitServerItems)
    $exitButton.X = [Terminal.Gui.Pos]::Bottom($gitServerItems) + 1
    $exitButton.add_Clicked({
        [Terminal.Gui.Application]::RequestStop()
    })

    $gitServersFrame.Add($exitButton)
}

BuildGitServersListView

[Terminal.Gui.Application]::Top.Add($Window)
[Terminal.Gui.Application]::Run()
[Terminal.Gui.Application]::Shutdown()

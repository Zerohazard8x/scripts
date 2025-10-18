<#
  Script: Purge-TokenBroker.ps1
  Purpose: Rename the Windows account broker’s token & cache folders and the WebView2 user data folder,
           to force a fresh rebuild of the Microsoft account sign-in broker environment.
  Usage: Run in PowerShell as your user. Close all Microsoft apps (Settings, OneDrive, Xbox, Edge WebView) first.
#>

# Define folder list (rename targets)
$FoldersToRename = @(
    "$env:LOCALAPPDATA\Packages\Microsoft.AAD.BrokerPlugin_cw5n1h2txyewy\AC\TokenBroker\Accounts",
    "$env:LOCALAPPDATA\Packages\Microsoft.Windows.CloudExperienceHost_cw5n1h2txyewy\AC\TokenBroker\Accounts",
    "$env:LOCALAPPDATA\Microsoft\TokenBroker\Cache",
    "$env:LOCALAPPDATA\Microsoft\EdgeWebView\User Data",
    "$env:LOCALAPPDATA\Microsoft\EdgeWebView"
)

foreach ($path in $FoldersToRename) {
    if (Test-Path $path) {
        try {
            $newName = $path + ".old_" + (Get-Date -Format "yyyyMMdd_HHmmss")
            Rename-Item -LiteralPath $path -NewName $newName -ErrorAction Stop
            Write-Host "Renamed `"$path`" → `"$newName`""
        }
        catch {
            Write-Host "Failed to rename `"$path`": $_"
        }
    }
    else {
        Write-Host "Path not found (skipped): `"$path`""
    }
}

Write-Host "`n** Rename complete. Please reboot your system now and retry the sign-in. **"

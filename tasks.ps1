# Ensure the script runs with administrative privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "run this script as admin"
    exit
}

# microsoft store
Get-AppxPackage -AllUsers Microsoft.WindowsStore* | ForEach-Object {Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"}

try {
    # https://github.com/SimonCropp/WinDebloat
    # winget uninstall "OneDrive"
    # winget uninstall --name "Microsoft To Do" --exact
    # winget uninstall --name "Microsoft Whiteboard" --exact
    # winget uninstall --name "Windows Calculator" --exact
    # winget uninstall --name "Windows Camera" --exact
    # winget uninstall --name "Xbox Accessories" --exact
    # winget uninstall --name "Xbox Game Bar Plugin" --exact
    # winget uninstall --name "Xbox Game Bar" --exact
    # winget uninstall --name "Xbox Identity Provider" --exact
    # winget uninstall --name "Xbox TCUI" --exact
    # winget uninstall --name "Xbox" --exact
    winget uninstall --name "3D Viewer" --exact
    winget uninstall --name "Clipchamp" --exact
    winget uninstall --name "Cortana" --exact
    winget uninstall --name "Feedback Hub" --exact
    winget uninstall --name "Get Help" --exact
    winget uninstall --name "HPHelp" --exact
    winget uninstall --name "MSN Weather" --exact
    winget uninstall --name "Mail and Calendar" --exact
    winget uninstall --name "Microsoft News" --exact
    winget uninstall --name "Microsoft Pay" --exact
    winget uninstall --name "Microsoft People" --exact
    winget uninstall --name "Microsoft Photos" --exact
    winget uninstall --name "Microsoft Solitaire Collection" --exact
    winget uninstall --name "Microsoft Sticky Notes" --exact
    winget uninstall --name "Microsoft Tips" --exact
    winget uninstall --name "Mixed Reality Portal" --exact
    winget uninstall --name "Movies & TV" --exact
    winget uninstall --name "News" --exact
    winget uninstall --name "OneNote for Windows 10" --exact
    winget uninstall --name "Paint 3D" --exact
    winget uninstall --name "Power Automate" --exact
    winget uninstall --name "Print 3D" --exact
    winget uninstall --name "SharedAccess" --exact
    winget uninstall --name "Skype" --exact
    winget uninstall --name "Solitaire & Casual Games" --exact
    winget uninstall --name "Teams Machine-Wide Installer" --exact
    winget uninstall --name "Windows Alarms & Clock" --exact
    winget uninstall --name "Windows Clock" --exact
    winget uninstall --name "Windows Maps" --exact
    winget uninstall --name "Windows Media Player" --exact
    winget uninstall --name "Windows Web Experience Pack" --exact
    winget uninstall --name "Xbox Console Companion" --exact
    winget uninstall --name "Xbox Game Speech Window" --exact

    winget upgrade --all --accept-source-agreements --accept-package-agreements
    # winget upgrade --all --accept-source-agreements --accept-package-agreements --include-unknown
}
catch {
    Write-Warning "Error: $_"
}

# Set-ItemProperty -Path "Registry::HKCU\Software\Microsoft\Windows\CurrentVersion\Search"`
#                  -Name "SearchboxTaskbarMode"`
#                  -Type "DWord"`
#                  -Value "0"

# Set-ItemProperty -Path "Registry::HKLM\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell"`
#                  -Name "ExecutionPolicy"`
#                  -Type "String"`
#                  -Value "Unrestricted"

# Set-ItemProperty -Path "Registry::HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer"`
#                  -Name "DisableSearchBoxSuggestions"`
#                  -Type "DWord"`
#                  -Value "1"

# Stop-Service -Name "Spooler"
# Set-Service -Name "Spooler"`
#             -StartupType "Disabled"

# network
Add-DnsClientDohServerAddress -ServerAddress 2606:4700:4700::1112 -DohTemplate https://security.cloudflare-dns.com/dns-query -AutoUpgrade $True
Add-DnsClientDohServerAddress -ServerAddress 2606:4700:4700::1002 -DohTemplate https://security.cloudflare-dns.com/dns-query -AutoUpgrade $True
Add-DnsClientDohServerAddress -ServerAddress 1.1.1.2 -DohTemplate https://security.cloudflare-dns.com/dns-query -AutoUpgrade $True
Add-DnsClientDohServerAddress -ServerAddress 1.0.0.2 -DohTemplate https://security.cloudflare-dns.com/dns-query -AutoUpgrade $True

Add-DnsClientDohServerAddress -ServerAddress 2001:4860:4860::8888 -DohTemplate https://dns.google/dns-query -AutoUpgrade $True
Add-DnsClientDohServerAddress -ServerAddress 2001:4860:4860::8844 -DohTemplate https://dns.google/dns-query -AutoUpgrade $True
Add-DnsClientDohServerAddress -ServerAddress 8.8.8.8 -DohTemplate https://dns.google/dns-query -AutoUpgrade $True
Add-DnsClientDohServerAddress -ServerAddress 8.8.4.4 -DohTemplate https://dns.google/dns-query -AutoUpgrade $True

Add-DnsClientDohServerAddress -ServerAddress 2606:1a40::2 -DohTemplate https://freedns.controld.com/p2 -AutoUpgrade $True
Add-DnsClientDohServerAddress -ServerAddress 2606:1a40:1::2 -DohTemplate https://freedns.controld.com/p2 -AutoUpgrade $True
Add-DnsClientDohServerAddress -ServerAddress 76.76.2.2 -DohTemplate https://freedns.controld.com/p2 -AutoUpgrade $True
Add-DnsClientDohServerAddress -ServerAddress 76.76.10.2 -DohTemplate https://freedns.controld.com/p2 -AutoUpgrade $True

Add-DnsClientDohServerAddress -ServerAddress 9.9.9.11 -DohTemplate https://dns11.quad9.net/dns-query -AutoUpgrade $True
Add-DnsClientDohServerAddress -ServerAddress 149.112.112.11 -DohTemplate https://dns11.quad9.net/dns-query -AutoUpgrade $True
Add-DnsClientDohServerAddress -ServerAddress 2620:fe::11 -DohTemplate https://dns11.quad9.net/dns-query -AutoUpgrade $True
Add-DnsClientDohServerAddress -ServerAddress 2620:fe::fe:11 -DohTemplate https://dns11.quad9.net/dns-query -AutoUpgrade $True

# Add-DnsClientDohServerAddress -ServerAddress 8.8.8.8 -DohTemplate https://dns.google/dns-query -AutoUpgrade $False
# Remove-DnsClientDohServerAddress -ServerAddress 8.8.8.8,8.8.4.4,2001:4860:4860::8888,2001:4860:4860::8844

$adapters = Get-NetAdapter
foreach ($adapter in $adapters) {
    $alias = $adapter.InterfaceAlias
    
    Set-DnsClientServerAddress -InterfaceAlias $alias -ServerAddresses ("2606:4700:4700::1112", "2606:4700:4700::1002")
    Set-DnsClientServerAddress -InterfaceAlias $alias -ServerAddresses ('1.1.1.2','1.0.0.2')

    # Set-DnsClientServerAddress -InterfaceAlias $alias -ServerAddresses ("2001:4860:4860::8888", "2001:4860:4860::8844")
    # Set-DnsClientServerAddress -InterfaceAlias $alias -ServerAddresses ('8.8.8.8','8.8.4.4')

    # Set-DnsClientServerAddress -InterfaceAlias $alias -ServerAddresses ("2606:1a40::2", "2606:1a40:1::2")
    # Set-DnsClientServerAddress -InterfaceAlias $alias -ServerAddresses ('76.76.2.2','76.76.10.2')

    # Set-DnsClientServerAddress -InterfaceAlias $alias -ServerAddresses ("2620:fe::11", "2620:fe::fe:11")
    # Set-DnsClientServerAddress -InterfaceAlias $alias -ServerAddresses ('9.9.9.11','149.112.112.11')

    # Set-DnsClientServerAddress -InterfaceAlias $alias -ResetServerAddresses

    # set to obtain an IP address automatically (DHCP)
    # Set-NetIPInterface -InterfaceAlias $alias -Dhcp Enabled
    # Set-NetIPInterface -InterfaceAlias $alias -AddressFamily IPv6 -Dhcp Enabled

    # Restart the network adapter to apply changes
    # Restart-NetAdapter -InterfaceAlias $alias
}

# make all taskschd.msc tasks run manually
# $scheduledTasks = Get-ScheduledTask
# foreach ($task in $scheduledTasks) {
#     try {
#         $taskName = $task.TaskName
#         $taskPath = $task.TaskPath

#         # Retrieve the full task details
#         $fullTask = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath

#         # Extract actions, principal, and settings
#         $actions = $fullTask.Actions
#         $principal = $fullTask.Principal
#         $settings = $fullTask.Settings

#         # Create a new scheduled task definition without triggers
#         $newTask = New-ScheduledTask -Action $actions -Principal $principal -Settings $settings

#         # Register the new task, effectively removing all triggers
#         Register-ScheduledTask -TaskName $taskName -TaskPath $taskPath -InputObject $newTask -Force

#         Write-Output "Updated task: $taskPath$taskName"
#     }
#     catch {
#         Write-Warning "Failed: $taskPath$taskName. Error: $_"
#     }
# }

# # Attempts to repair all drives
# defrag /o /c /m
# $drives = Get-Disk | Select-Object -ExpandProperty Number
# foreach ($drive in $drives) {
#     try {
#         mbr2gpt /allowfullos /convert /disk=$drive
#     }
#     catch {
#         Write-Warning "Error converting drive $drive`: $_"
#     }
# }

# $drives = Get-Volume | Select-Object -ExpandProperty DriveLetter
# foreach ($drive in $drives) {
#     try {
#         # clean and repair
#         Repair-Volume -DriveLetter $drive -OfflineScanAndFix -ErrorAction Stop
#         cleanmgr /verylowdisk /d $drive
#         cleanmgr /sagerun:0 /d $drive
#         Repair-Volume -DriveLetter $drive -SpotFix -ErrorAction Stop

#         # re-register all applications
#         Get-ChildItem -Path $drive`:\ -Filter "AppxManifest.xml" -Recurse -File | ForEach-Object {
#             try {
#                 Add-AppxPackage -DisableDevelopmentMode -Register $_.FullName -ErrorAction Stop
#             }
#             catch {
#                 Write-Warning "Error: $_"
#             }
#         }

#         # reset shadow storage
#         vssadmin Resize ShadowStorage /For=$drive`: /On=$drive`: /MaxSize=3%
#     }
#     catch {
#         Write-Warning "Error repairing drive $drive`: $_"
#     }
# }

# # Re-registers all UWP apps on Windows drive
# $appxManifestPaths = @(
#     "$Env:ProgramFiles\WindowsApps",
#     "$Env:WINDIR\SystemApps"
# )
# foreach ($path in $appxManifestPaths) {
#     Get-ChildItem -Path $path -Filter "AppxManifest.xml" -Recurse -File | ForEach-Object {
#         try {
#             Add-AppxPackage -DisableDevelopmentMode -Register $_.FullName -ErrorAction Stop
#         }
#         catch {
#             Write-Warning "Error registering app package: $_"
#         }
#     }
# }

# windows defender
try {
    Set-MpPreference -DisableRealtimeMonitoring $false
    Set-MpPreference -EnableControlledFolderAccess Disabled
}
catch {
    Write-Warning "Error: $_"
}

# try {
#     dism /online /cleanup-image /restorehealth /startcomponentcleanup
#     sfc /scannow
# }
# catch {
#     Write-Warning "Error running DISM or SFC: $_"
# }

try {
    bcdedit.exe /debug off
    bcdedit.exe /set loadoptions ENABLE_INTEGRITY_CHECKS
    bcdedit.exe /set TESTSIGNING OFF
    bcdedit.exe /set NOINTEGRITYCHECKS OFF
    bcdedit /set hypervisorlaunchtype auto
}
catch {
    Write-Warning "Error running bcdedit: $_"
}

try {
    if (Get-Command Get-WindowsUpdate -ErrorAction SilentlyContinue) {
        # Add-WUServiceManager -MicrosoftUpdate -Confirm:$false
        Get-WindowsUpdate -Download -AcceptAll -Confirm:$false
        Get-WindowsUpdate -Install -AcceptAll -IgnoreReboot -Confirm:$false
    }
    else {
        Install-Module PSWindowsUpdate -Force -Confirm:$false
    }
}
catch {
    Write-Warning "Error installing or running Windows updates: $_"
}

# PSWindowsUpdate module is still not available
# use the wuauclt command as a fallback
if (-not(Get-Command Get-WindowsUpdate -ErrorAction SilentlyContinue)) {
    try {
        wuauclt /detectnow
        wuauclt /updatenow
    }
    catch {
        Write-Warning "Error running wuauclt: $_"
    }
}

try {
    control update
}
catch {
    Write-Warning "Error opening Windows Update control panel: $_"
}


# Installs chocolatey
# if (-not(Get-Command choco -ErrorAction SilentlyContinue)) {
#     # Negation of (Get-Command choco -ErrorAction SilentlyContinue)
#     powershell.exe -c Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
#     refreshenv
# }

exit
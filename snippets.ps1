# 2001:4860:4860::8888 -DohTemplate https://dns.google/dns-query
# 2001:4860:4860::8844 -DohTemplate https://dns.google/dns-query
# 8.8.8.8 -DohTemplate https://dns.google/dns-query
# 8.8.4.4 -DohTemplate https://dns.google/dns-query

# 2606:1a40::2 -DohTemplate https://freedns.controld.com/p2
# 2606:1a40:1::2 -DohTemplate https://freedns.controld.com/p2
# 76.76.2.2 -DohTemplate https://freedns.controld.com/p2
# 76.76.10.2 -DohTemplate https://freedns.controld.com/p2

# 9.9.9.11 -DohTemplate https://dns11.quad9.net/dns-query
# 149.112.112.11 -DohTemplate https://dns11.quad9.net/dns-query
# 2620:fe::11 -DohTemplate https://dns11.quad9.net/dns-query
# 2620:fe::fe:11 -DohTemplate https://dns11.quad9.net/dns-query


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

# Make all taskschd.msc tasks run manually
$scheduledTasks = Get-ScheduledTask
foreach ($task in $scheduledTasks) {
    try {
        $taskName = $task.TaskName
        $taskPath = $task.TaskPath
        # Retrieve the full task details
        $fullTask = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath
        # Extract actions, principal, and settings
        $actions = $fullTask.Actions
        $principal = $fullTask.Principal
        $settings = $fullTask.Settings
        # Create a new scheduled task definition without triggers
        $newTask = New-ScheduledTask -Action $actions -Principal $principal -Settings $settings
        # Register the new task, effectively removing all triggers
        Register-ScheduledTask -TaskName $taskName -TaskPath $taskPath -InputObject $newTask -Force
        Write-Output "Updated task: $taskPath$taskName"
    }
    catch {
        Write-Warning "Failed: $taskPath$taskName. Error: $_"
    }
}

# Attempts to repair all drives
defrag /o /c /m
$drives = Get-Disk | Select-Object -ExpandProperty Number
foreach ($drive in $drives) {
    try {
        mbr2gpt /allowfullos /convert /disk=$drive
    }
    catch {
        Write-Warning "Error converting drive $drive`: $_"
    }
}

$drives = Get-Volume | Select-Object -ExpandProperty DriveLetter
foreach ($drive in $drives) {
    try {
        # clean and repair
        Repair-Volume -DriveLetter $drive -OfflineScanAndFix -ErrorAction Stop
        cleanmgr /verylowdisk /d $drive
        cleanmgr /sagerun:0 /d $drive
        Repair-Volume -DriveLetter $drive -SpotFix -ErrorAction Stop
        # re-register all applications
        Get-ChildItem -Path $drive`:\ -Filter "AppxManifest.xml" -Recurse -File | ForEach-Object {
            try {
                Add-AppxPackage -DisableDevelopmentMode -Register $_.FullName -ErrorAction Stop
            }
            catch {
                Write-Warning "Error: $_"
            }
        }
        # reset shadow storage
        vssadmin Resize ShadowStorage /For=$drive`: /On=$drive`: /MaxSize=3%
    }
    catch {
        Write-Warning "Error repairing drive $drive`: $_"
    }
}

# Re-registers all UWP apps on Windows drive
$appxManifestPaths = @(
    "$Env:ProgramFiles\WindowsApps",
    "$Env:WINDIR\SystemApps"
)
foreach ($path in $appxManifestPaths) {
    Get-ChildItem -Path $path -Filter "AppxManifest.xml" -Recurse -File | ForEach-Object {
        try {
            Add-AppxPackage -DisableDevelopmentMode -Register $_.FullName -ErrorAction Stop
        }
        catch {
            Write-Warning "Error registering app package: $_"
        }
    }
}

try {
    dism /online /cleanup-image /restorehealth /startcomponentcleanup
    sfc /scannow
}
catch {
    Write-Warning "Error running DISM or SFC: $_"
}

# Installs chocolatey
# if (-not(Get-Command choco -ErrorAction SilentlyContinue)) {
#     # Negation of (Get-Command choco -ErrorAction SilentlyContinue)
#     powershell.exe -c Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
#     refreshenv
# }
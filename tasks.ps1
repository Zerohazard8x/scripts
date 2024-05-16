# network
Get-NetAdapter | set-DnsClientServerAddress -ServerAddresses ('208.67.222.222','208.67.220.220')

# Attempts to repair all drives
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
        Repair-Volume -DriveLetter $drive -OfflineScanAndFix -ErrorAction Stop
        cleanmgr /verylowdisk /d $drive
        cleanmgr /sagerun:0 /d $drive
        Repair-Volume -DriveLetter $drive -SpotFix -ErrorAction Stop

        # Get-ChildItem -Path $drive`:\ -Filter "AppxManifest.xml" -Recurse -File | ForEach-Object {
        #     try {
        #         Add-AppxPackage -DisableDevelopmentMode -Register $_.FullName -ErrorAction Stop
        #     }
        #     catch {
        #         Write-Warning "Error registering app package: $_"
        #     }
        # }

        $disk = Get-PhysicalDisk | Where-Object {
            $_.DeviceID -eq (Get-Partition -DriveLetter $drive).DiskNumber
        }
        if ($disk.MediaType -ne 'SSD') {
            Optimize-Volume -DriveLetter $drive -Defrag -Verbose
        } else {
            Optimize-Volume -DriveLetter $drive -ReTrim -Verbose
        }

        vssadmin Resize ShadowStorage /For=$drive`: /On=$drive`: /MaxSize=100%
    }
    catch {
        Write-Warning "Error repairing drive $drive`: $_"
    }
}

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

# # Update UWP apps??
# $params = @{
#     Namespace = "root\cimv2\mdm\dmmap"
#     ClassName = "MDM_EnterpriseModernAppManagement_AppManagement01"
# }
# try {
#     $cimObj = Get-CimInstance @params -ErrorAction Stop
#     Invoke-CimMethod -InputObject $cimObj -MethodName UpdateScanMethod
# }
# catch {
#     Write-Warning "Error invoking CIM method: $_"
# }

try {
    dism /online /cleanup-image /restorehealth /startcomponentcleanup
    sfc /scannow
}
catch {
    Write-Warning "Error running DISM or SFC: $_"
}

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
        Add-WUServiceManager -MicrosoftUpdate -Confirm:$false
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
if (-not(Get-Command Get-WindowsUpdate -ErrorAction SilentlyContinue) -and (Get-Command wuauclt -ErrorAction SilentlyContinue)) {
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
cmd.exe /c 'start "" "%WINDIR%\System32\SystemPropertiesProtection.exe"'
# Get all the drive letters
$drives = Get-Volume | Select-Object -ExpandProperty DriveLetter

# Loop through each drive letter and run the commands
foreach ($drive in $drives) {
    Repair-Volume -DriveLetter $drive -OfflineScanAndFix
    cleanmgr /verylowdisk /d $drive
    Repair-Volume -DriveLetter $drive -SpotFix
    vssadmin Resize ShadowStorage /For=$ { drive }: /On=$ { drive }: /MaxSize=100%
}

# Use -Path and -Filter parameters to specify the location and pattern of the files
# Use -Recurse parameter to search all subdirectories
# Use -File parameter to return only files and not directories
# Use ForEach-Object to loop through each file and pipe it to Add-AppxPackage
# Use -ErrorAction SilentlyContinue to suppress any errors that may occur
Get-ChildItem -Path "$Env:Programfiles\WindowsApps" -Filter "*AppxManifest.xml" -Recurse -File | ForEach-Object {
    Add-AppxPackage -DisableDevelopmentMode -Register $_.FullName -ErrorAction SilentlyContinue
}
Get-ChildItem -Path "$Env:WINDIR\SystemApps" -Filter "*AppxManifest.xml" -Recurse -File | ForEach-Object {
    Add-AppxPackage -DisableDevelopmentMode -Register $_.FullName -ErrorAction SilentlyContinue
}

# Use the CIM cmdlets instead of the WMI cmdlets
# Use splatting to pass the parameters
$params = @{
    Namespace = "root\cimv2\mdm\dmmap"
    ClassName = "MDM_EnterpriseModernAppManagement_AppManagement01"
}
$cimObj = Get-CimInstance @params
$result = Invoke-CimMethod -InputObject $cimObj -MethodName UpdateScanMethod

dism /online /cleanup-image /restorehealth /startcomponentcleanup; sfc /scannow

if (Get-Command Get-WindowsUpdate -ErrorAction SilentlyContinue) { 
    Add-WUServiceManager -MicrosoftUpdate -Confirm:$false
    Get-WindowsUpdate -Download -AcceptAll -Confirm:$false 
    Get-WindowsUpdate -Install -AcceptAll -IgnoreReboot -Confirm:$false 
}
else {
    Install-Module PSWindowsUpdate -Force -Confirm:$false
}

# If the PSWindowsUpdate module is not available, use the wuauclt command as a fallback
if (-not(Get-Command Get-WindowsUpdate -ErrorAction SilentlyContinue) -and (Get-Command wuauclt -ErrorAction SilentlyContinue)) { 
    wuauclt /detectnow
    wuauclt /updatenow 
}

cmd.exe /c control update

cmd.exe /c net stop "SysMain" /y
cmd.exe /c net stop "Superfetch" /y
cmd.exe /c net stop "svsvc" /y

cmd.exe /c sc config "SysMain" start=disabled
cmd.exe /c sc config "Superfetch" start=disabled
cmd.exe /c sc config "svsvc" start=disabled

# cmd.exe /c powercfg -restoredefaultschemes

cmd.exe /c w32tm /config /update
cmd.exe /c w32tm /resync

# if (-not(Get-Command choco -ErrorAction SilentlyContinue)) {
#     # Negation of (Get-Command choco -ErrorAction SilentlyContinue)
#     powershell.exe -c Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
#     refreshenv
# }

# if (Get-Command choco -ErrorAction SilentlyContinue) { 
#     #TODO
# }

# if (Get-Command python -ErrorAction SilentlyContinue) {
#     if (Get-Command python3 -ErrorAction SilentlyContinue) { 
#         python3 -m pip uninstall -y notebook youtube-dl yt-dlp
#     } 
#     if (-not(Get-Command pip -ErrorAction SilentlyContinue) -and (Get-Command aria2c -ErrorAction SilentlyContinue)) { 
#         aria2c -x16 -s32 -R --allow-overwrite=true https://bootstrap.pypa.io/get-pip.py
#         python get-pip.py
#     }
#     python -m pip install --pre -U pip setuptools wheel youtube-dl
#     python -m pip install -U --force-reinstall https://github.com/yt-dlp/yt-dlp/archive/master.tar.gz
# }

Get-NetAdapter | set-DnsClientServerAddress -ServerAddresses ('94.140.14.14', '94.140.15.15')
cmd.exe /c ipconfig /flushdns
Get-NetAdapter | Restart-NetAdapter

shutdown /r /f /t 0
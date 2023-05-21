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

cmd.exe /c "SET DEVMGR_SHOW_NONPRESENT_DEVICES=1" # then devmgmt.msc delete all greyed out in safe mode

cmd.exe /c sc config "BDESVC" start=auto
cmd.exe /c sc config "BFE" start=auto
cmd.exe /c sc config "BluetoothUserService_48486de" start=auto
cmd.exe /c sc config "BrokerInfrastructure" start=auto
cmd.exe /c sc config "Dnscache" start=auto
cmd.exe /c sc config "EntAppSvc" start=auto
cmd.exe /c sc config "FrameServer" start=auto
cmd.exe /c sc config "LicenseManager" start=auto
cmd.exe /c sc config "MacType" start=auto
cmd.exe /c sc config "NVDisplay.ContainerLocalSystem" start=auto
cmd.exe /c sc config "OpenVPNServiceInteractive" start=auto
cmd.exe /c sc config "PNRPsvc" start=auto
cmd.exe /c sc config "ProcessGovernor" start=auto
cmd.exe /c sc config "W32Time" start=auto
cmd.exe /c sc config "WdNisSvc" start=auto
cmd.exe /c sc config "WlanSvc" start=auto
cmd.exe /c sc config "audiosrv" start=auto
cmd.exe /c sc config "hidusbf" start=auto
cmd.exe /c sc config "iphlpsvc" start=auto
cmd.exe /c sc config "ndu" start=auto
cmd.exe /c sc config "p2pimsvc" start=auto
cmd.exe /c sc config "p2psvc" start=auto
cmd.exe /c sc config "wscsvc" start=auto

cmd.exe /c net start "BDESVC"
cmd.exe /c net start "BFE"
cmd.exe /c net start "BluetoothUserService_48486de"
cmd.exe /c net start "BrokerInfrastructure"
cmd.exe /c net start "Dnscache"
cmd.exe /c net start "EntAppSvc"
cmd.exe /c net start "FrameServer"
cmd.exe /c net start "LicenseManager"
cmd.exe /c net start "MacType"
cmd.exe /c net start "NVDisplay.ContainerLocalSystem"
cmd.exe /c net start "OpenVPNServiceInteractive"
cmd.exe /c net start "PNRPsvc"
cmd.exe /c net start "ProcessGovernor"
cmd.exe /c net start "W32Time"
cmd.exe /c net start "WdNisSvc"
cmd.exe /c net start "WlanSvc"
cmd.exe /c net start "audiosrv"
cmd.exe /c net start "hidusbf"
cmd.exe /c net start "iphlpsvc"
cmd.exe /c net start "ndu"
cmd.exe /c net start "p2pimsvc"
cmd.exe /c net start "p2psvc"
cmd.exe /c net start "wscsvc"

cmd.exe /c net stop "SysMain" /y
cmd.exe /c net stop "Superfetch" /y
cmd.exe /c net stop "svsvc" /y

cmd.exe /c sc config "SysMain" start=disabled
cmd.exe /c sc config "Superfetch" start=disabled
cmd.exe /c sc config "svsvc" start=disabled

# cmd.exe /c powercfg -restoredefaultschemes

cmd.exe /c w32tm /config /update
cmd.exe /c w32tm /resync

if (-not(Get-Command choco -ErrorAction SilentlyContinue)) {
    # Negation of (Get-Command choco -ErrorAction SilentlyContinue)
    powershell.exe -c Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    refreshenv
}

if (Get-Command choco -ErrorAction SilentlyContinue) { 
    choco upgrade chocolatey 7zip adb aria2 dos2unix firefox ffmpeg git jq mpv nano nomacs openvpn powershell phantomjs rsync scrcpy smplayer unison vlc -y
    choco uninstall python2 python -y; choco upgrade python3 -y
}

if (Get-Command python -ErrorAction SilentlyContinue) { 
    if (-not(Get-Command pip -ErrorAction SilentlyContinue) -and (Get-Command aria2c -ErrorAction SilentlyContinue)) { 
        aria2c -x16 -s32 -R --allow-overwrite=true --disable-ipv6 https://bootstrap.pypa.io/get-pip.py
        python get-pip.py
    }
    python -m pip install --pre -U pip wheel yt-dlp youtube-dl
    # python -m pip install -U git+https://github.com/samloader/samloader.git
}

# cmd.exe /c netsh int tcp set global autotuninglevel=disabled
Get-NetAdapter | set-DnsClientServerAddress -ServerAddresses ('1.1.1.2', '9.9.9.9')
Get-NetAdapter | Set-DnsClientServerAddress -AddressFamily IPv6 -ServerAddresses (‘2606:4700:4700::1112’, ‘2620:fe::fe’)
cmd.exe /c ipconfig /flushdns
Get-NetAdapter | Restart-NetAdapter

shutdown /r /f /t 0

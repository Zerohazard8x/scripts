$namespaceName = "root\cimv2\mdm\dmmap"
$className = "MDM_EnterpriseModernAppManagement_AppManagement01"
$wmiObj = Get-WmiObject -Namespace $namespaceName -Class $className

$result = $wmiObj.UpdateScanMethod()
cmd.exe /c sc config "SysMain" start=disabled
cmd.exe /c sc config "Superfetch" start=disabled
cmd.exe /c sc config "WlanSvc" start=auto
cmd.exe /c sc config "W32Time" start=auto
net stop "SysMain"
net stop "Superfetch"
net start "WlanSvc"
net start "W32Time"

powershell.exe -c Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
powershell.exe -c choco upgrade chocolatey python3 pip ffmpeg mpv aria2 rsync git python3 nomacs atom audacity deluge vlc chromium doublecmd obs-studio filezilla 7zip smplayer -y
powershell.exe -c choco install python3 pip ffmpeg mpv aria2 rsync git python3 nomacs atom audacity deluge vlc chromium doublecmd obs-studio filezilla 7zip smplayer -y
# powershell.exe -c choco upgrade okular openvpn picard adb retroarch kodi pdfsam
# powershell.exe -c choco install okular openvpn picard adb retroarch kodi pdfsam

aria2c -R -x16 https://bootstrap.pypa.io/get-pip.py
python3 get-pip.py
python3 -m pip install -U wheel
python3 -m pip install -U pip
python3 -m pip install -U git+https://github.com/yt-dlp/yt-dlp.git git+https://github.com/nlscc/samloader.git

w32tm /config /syncfromflags:manual
w32tm /resync /nowait
wuauclt /detectnow
wuauclt /updatenow
Get-NetAdapter | set-DnsClientServerAddress -ServerAddresses ('1.1.1.2','9.9.9.9')
cmd.exe /c dir "$Env:Programfiles\WindowsApps\*AppxManifest.xml" /b /s | Add-AppxPackage -DisableDevelopmentMode -Register
cmd.exe /c dir "%WINDIR%\SystemApps\*AppxManifest.xml" /b /s | Add-AppxPackage -DisableDevelopmentMode -Register
cmd.exe /c dir "$Env:Programfiles\WindowsApps\*AppxManifest.xml" /b /s | Add-AppxPackage -DisableDevelopmentMode -Register
cmd.exe /c dir "%WINDIR%\SystemApps\*AppxManifest.xml" /b /s | Add-AppxPackage -DisableDevelopmentMode -Register
cmd.exe /c "echo y|powershell.exe -c Install-Module PSWindowsUpdate"  
cmd.exe /c "echo y|powershell.exe -c Add-WUServiceManager -MicrosoftUpdate"  
cmd.exe /c "echo y|powershell.exe -c Get-WindowsUpdate"  
cmd.exe /c "echo y|powershell.exe -c Install-WindowsUpdate -MicrosoftUpdate -AcceptAll" 

netsh int tcp set global autotuninglevel=disabled
netsh winsock reset
netsh int ip reset
ipconfig /release
ipconfig /renew
ipconfig /flushdns
gpupdate /force

shutdown /r /f /t 0

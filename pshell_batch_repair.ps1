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
powershell.exe -c choco upgrade chocolatey ffmpeg mpv aria2 rsync git python3 nomacs atom okular audacity deluge audacious chromium doublecmd obs-studio filezilla kdenlive openvpn picard 7zip parsec adb retroarch -y
powershell.exe -c choco install ffmpeg mpv aria2 rsync git python3 nomacs atom okular audacity deluge audacious chromium doublecmd obs-studio filezilla kdenlive openvpn picard parsec 7zip adb retroarch -y
aria2c -c -R -x16 https://bootstrap.pypa.io/get-pip.py
python3 get-pip.py
pip3 install wheel --upgrade
pip3 install pip --upgrade
pip3 install yt-dlp git+https://github.com/nlscc/samloader.git --upgrade
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

$namespaceName = "root\cimv2\mdm\dmmap"
$className = "MDM_EnterpriseModernAppManagement_AppManagement01"
$wmiObj = Get-WmiObject -Namespace $namespaceName -Class $className
$result = $wmiObj.UpdateScanMethod()

cmd.exe /c sc config "SysMain" start=disabled
cmd.exe /c sc config "Superfetch" start=disabled
cmd.exe /c sc config "WlanSvc" start=auto
net stop "SysMain"
net stop "Superfetch"
net start "WlanSvc"

powershell.exe -c Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
choco upgrade chocolatey ffmpeg mpv aria2 rsync git nomacs deluge vlc firefox doublecmd filezilla 7zip dos2unix openvpn okular adb scrcpy -y
# choco upgrade picard audacity kdenlive retroarch kodi pdfsam obs-studio atom foobar2000 parsec darktable chromium antimicro qemu fontforge doomsday ioquake3 steam meld czkawka libreoffice virtualbox smplayer python3 -y

# aria2c -R -x16 -s32 https://bootstrap.pypa.io/get-pip.py
# python3 get-pip.py
# python3 -m pip install -U wheel
# python3 -m pip install -U pip
# python3 -m pip install -U spleeter git+https://github.com/arkrow/PyMusicLooper.git git+https://github.com/nlscc/samloader.git git+https://github.com/yt-dlp/yt-dlp.git beautysh

wuauclt /detectnow
wuauclt /updatenow
cmd.exe /c dir "$Env:Programfiles\WindowsApps\*AppxManifest.xml" /b /s | Add-AppxPackage -DisableDevelopmentMode -Register
cmd.exe /c dir "%WINDIR%\SystemApps\*AppxManifest.xml" /b /s | Add-AppxPackage -DisableDevelopmentMode -Register
cmd.exe /c dir "$Env:Programfiles\WindowsApps\*AppxManifest.xml" /b /s | Add-AppxPackage -DisableDevelopmentMode -Register
cmd.exe /c dir "%WINDIR%\SystemApps\*AppxManifest.xml" /b /s | Add-AppxPackage -DisableDevelopmentMode -Register
cmd.exe /c "echo y|powershell.exe -c Install-Module PSWindowsUpdate"  
cmd.exe /c "echo y|powershell.exe -c Add-WUServiceManager -MicrosoftUpdate"  
cmd.exe /c "echo y|powershell.exe -c Get-WindowsUpdate"  
cmd.exe /c "echo y|powershell.exe -c Install-WindowsUpdate -MicrosoftUpdate -AcceptAll" 

netsh int tcp set global autotuninglevel=disabled
Get-NetAdapter | set-DnsClientServerAddress -ServerAddresses ('1.1.1.2','9.9.9.9')

shutdown /r /f /t 0

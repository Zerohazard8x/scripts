cmd.exe /c dir "$Env:Programfiles\WindowsApps\*AppxManifest.xml" /b /s | Add-AppxPackage -DisableDevelopmentMode -Register
cmd.exe /c dir "%WINDIR%\SystemApps\*AppxManifest.xml" /b /s | Add-AppxPackage -DisableDevelopmentMode -Register
cmd.exe /c dir "$Env:Programfiles\WindowsApps\*AppxManifest.xml" /b /s | Add-AppxPackage -DisableDevelopmentMode -Register
cmd.exe /c dir "%WINDIR%\SystemApps\*AppxManifest.xml" /b /s | Add-AppxPackage -DisableDevelopmentMode -Register

cmd.exe /c 'start "" "%WINDIR%\System32\SystemPropertiesProtection.exe"'
cmd.exe /c "echo y|chkntfs /x A:"; cmd.exe /c "cleanmgr /verylowdisk /d A:"; cmd.exe /c "echo y|chkdsk A: /f"; vssadmin Resize ShadowStorage /For=A: /On=A: /MaxSize=100%
cmd.exe /c "echo y|chkntfs /x B:"; cmd.exe /c "cleanmgr /verylowdisk /d B:"; cmd.exe /c "echo y|chkdsk B: /f"; vssadmin Resize ShadowStorage /For=B: /On=B: /MaxSize=100%
cmd.exe /c "echo y|chkntfs /x C:"; cmd.exe /c "cleanmgr /verylowdisk /d C:"; cmd.exe /c "echo y|chkdsk C: /f"; vssadmin Resize ShadowStorage /For=C: /On=C: /MaxSize=100%
cmd.exe /c "echo y|chkntfs /x D:"; cmd.exe /c "cleanmgr /verylowdisk /d D:"; cmd.exe /c "echo y|chkdsk D: /f"; vssadmin Resize ShadowStorage /For=D: /On=D: /MaxSize=100%
cmd.exe /c "echo y|chkntfs /x E:"; cmd.exe /c "cleanmgr /verylowdisk /d E:"; cmd.exe /c "echo y|chkdsk E: /f"; vssadmin Resize ShadowStorage /For=E: /On=E: /MaxSize=100%
cmd.exe /c "echo y|chkntfs /x F:"; cmd.exe /c "cleanmgr /verylowdisk /d F:"; cmd.exe /c "echo y|chkdsk F: /f"; vssadmin Resize ShadowStorage /For=F: /On=F: /MaxSize=100%
cmd.exe /c "echo y|chkntfs /x G:"; cmd.exe /c "cleanmgr /verylowdisk /d G:"; cmd.exe /c "echo y|chkdsk G: /f"; vssadmin Resize ShadowStorage /For=G: /On=G: /MaxSize=100%
cmd.exe /c "echo y|chkntfs /x H:"; cmd.exe /c "cleanmgr /verylowdisk /d H:"; cmd.exe /c "echo y|chkdsk H: /f"; vssadmin Resize ShadowStorage /For=H: /On=H: /MaxSize=100%
cmd.exe /c "echo y|chkntfs /x I:"; cmd.exe /c "cleanmgr /verylowdisk /d I:"; cmd.exe /c "echo y|chkdsk I: /f"; vssadmin Resize ShadowStorage /For=I: /On=I: /MaxSize=100%
cmd.exe /c "echo y|chkntfs /x J:"; cmd.exe /c "cleanmgr /verylowdisk /d J:"; cmd.exe /c "echo y|chkdsk J: /f"; vssadmin Resize ShadowStorage /For=J: /On=J: /MaxSize=100%
cmd.exe /c "echo y|chkntfs /x K:"; cmd.exe /c "cleanmgr /verylowdisk /d K:"; cmd.exe /c "echo y|chkdsk K: /f"; vssadmin Resize ShadowStorage /For=K: /On=K: /MaxSize=100%
cmd.exe /c "echo y|chkntfs /x L:"; cmd.exe /c "cleanmgr /verylowdisk /d L:"; cmd.exe /c "echo y|chkdsk L: /f"; vssadmin Resize ShadowStorage /For=L: /On=L: /MaxSize=100%
cmd.exe /c "echo y|chkntfs /x M:"; cmd.exe /c "cleanmgr /verylowdisk /d M:"; cmd.exe /c "echo y|chkdsk M: /f"; vssadmin Resize ShadowStorage /For=M: /On=M: /MaxSize=100%
cmd.exe /c "echo y|chkntfs /x N:"; cmd.exe /c "cleanmgr /verylowdisk /d N:"; cmd.exe /c "echo y|chkdsk N: /f"; vssadmin Resize ShadowStorage /For=N: /On=N: /MaxSize=100%
cmd.exe /c "echo y|chkntfs /x O:"; cmd.exe /c "cleanmgr /verylowdisk /d O:"; cmd.exe /c "echo y|chkdsk O: /f"; vssadmin Resize ShadowStorage /For=O: /On=O: /MaxSize=100%
cmd.exe /c "echo y|chkntfs /x P:"; cmd.exe /c "cleanmgr /verylowdisk /d P:"; cmd.exe /c "echo y|chkdsk P: /f"; vssadmin Resize ShadowStorage /For=P: /On=P: /MaxSize=100%
cmd.exe /c "echo y|chkntfs /x Q:"; cmd.exe /c "cleanmgr /verylowdisk /d Q:"; cmd.exe /c "echo y|chkdsk Q: /f"; vssadmin Resize ShadowStorage /For=Q: /On=Q: /MaxSize=100%
cmd.exe /c "echo y|chkntfs /x R:"; cmd.exe /c "cleanmgr /verylowdisk /d R:"; cmd.exe /c "echo y|chkdsk R: /f"; vssadmin Resize ShadowStorage /For=R: /On=R: /MaxSize=100%
cmd.exe /c "echo y|chkntfs /x S:"; cmd.exe /c "cleanmgr /verylowdisk /d S:"; cmd.exe /c "echo y|chkdsk S: /f"; vssadmin Resize ShadowStorage /For=S: /On=S: /MaxSize=100%
cmd.exe /c "echo y|chkntfs /x T:"; cmd.exe /c "cleanmgr /verylowdisk /d T:"; cmd.exe /c "echo y|chkdsk T: /f"; vssadmin Resize ShadowStorage /For=T: /On=T: /MaxSize=100%
cmd.exe /c "echo y|chkntfs /x U:"; cmd.exe /c "cleanmgr /verylowdisk /d U:"; cmd.exe /c "echo y|chkdsk U: /f"; vssadmin Resize ShadowStorage /For=U: /On=U: /MaxSize=100%
cmd.exe /c "echo y|chkntfs /x V:"; cmd.exe /c "cleanmgr /verylowdisk /d V:"; cmd.exe /c "echo y|chkdsk V: /f"; vssadmin Resize ShadowStorage /For=V: /On=V: /MaxSize=100%
cmd.exe /c "echo y|chkntfs /x W:"; cmd.exe /c "cleanmgr /verylowdisk /d W:"; cmd.exe /c "echo y|chkdsk W: /f"; vssadmin Resize ShadowStorage /For=W: /On=W: /MaxSize=100%
cmd.exe /c "echo y|chkntfs /x X:"; cmd.exe /c "cleanmgr /verylowdisk /d X:"; cmd.exe /c "echo y|chkdsk X: /f"; vssadmin Resize ShadowStorage /For=X: /On=X: /MaxSize=100%
cmd.exe /c "echo y|chkntfs /x Y:"; cmd.exe /c "cleanmgr /verylowdisk /d Y:"; cmd.exe /c "echo y|chkdsk Y: /f"; vssadmin Resize ShadowStorage /For=Y: /On=Y: /MaxSize=100%
cmd.exe /c "echo y|chkntfs /x Z:"; cmd.exe /c "cleanmgr /verylowdisk /d Z:"; cmd.exe /c "echo y|chkdsk Z: /f"; vssadmin Resize ShadowStorage /For=Z: /On=Z: /MaxSize=100%
dism /online /cleanup-image /restorehealth /startcomponentcleanup; sfc /scannow

cmd.exe /c sc config "SysMain" start=disabled
cmd.exe /c sc config "Superfetch" start=disabled
cmd.exe /c sc config "WlanSvc" start=auto
net stop "SysMain"
net stop "Superfetch"
net start "WlanSvc"

powershell.exe -c Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
choco upgrade chocolatey ffmpeg mpv aria2 rsync git nomacs vlc firefox unison filezilla 7zip dos2unix openvpn okular adb scrcpy youtube-dl -y
# choco upgrade picard audacity kdenlive retroarch kodi pdfsam obs-studio foobar2000 parsec darktable chromium antimicro qemu fontforge doomsday ioquake3 steam meld czkawka libreoffice virtualbox smplayer unetbootin qbittorrent -y

# choco uninstall python2 python -y; choco upgrade python3 -y; aria2c -R -x16 -s32 https://bootstrap.pypa.io/get-pip.py
# python get-pip.py
# python -m pip install -U wheel
# python -m pip install -U pip
# python -m pip install -U spleeter git+https://github.com/arkrow/PyMusicLooper.git git+https://github.com/nlscc/samloader.git git+https://github.com/yt-dlp/yt-dlp.git beautysh

$namespaceName = "root\cimv2\mdm\dmmap"
$className = "MDM_EnterpriseModernAppManagement_AppManagement01"
$wmiObj = Get-WmiObject -Namespace $namespaceName -Class $className
$result = $wmiObj.UpdateScanMethod()

wuauclt /detectnow
wuauclt /updatenow
cmd.exe /c "echo y|powershell.exe -c Install-Module PSWindowsUpdate"  
cmd.exe /c "echo y|powershell.exe -c Add-WUServiceManager -MicrosoftUpdate"  
cmd.exe /c "echo y|powershell.exe -c Get-WindowsUpdate"  
cmd.exe /c "echo y|powershell.exe -c Install-WindowsUpdate -MicrosoftUpdate -AcceptAll" 

netsh int tcp set global autotuninglevel=disabled
Get-NetAdapter | set-DnsClientServerAddress -ServerAddresses ('1.1.1.2','9.9.9.9')

shutdown /r /f /t 0

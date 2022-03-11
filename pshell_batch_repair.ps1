sc config "SysMain" start=disabled
sc config "Superfetch" start=disabled
sc config "WlanSvc" start=auto
sc config "W32Time" start=auto
net stop "SysMain"
net stop "Superfetch"
net start "WlanSvc"
net start "W32Time"
powershell.exe -c Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
powershell.exe -c choco upgrade chocolatey ffmpeg mpv aria2 rsync git python3 nomacs kate okular audacity -y
powershell.exe -c choco install ffmpeg mpv aria2 rsync git python3 nomacs kate okular audacity -y
aria2c -c -R -x16 https://bootstrap.pypa.io/get-pip.py
python3 get-pip.py
pip3 install wheel --upgrade
pip3 install pip --upgrade
pip3 install yt-dlp git+https://github.com/nlscc/samloader.git --upgrade
w32tm /config /syncfromflags:manual
w32tm /resync /nowait
wuauclt /detectnow
wuauclt /updatenow
Get-NetAdapter | set-DnsClientServerAddress -ServerAddresses ('1.1.1.1','1.0.0.1')
Get-AppxPackage -AllUsers | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"} 
cmd.exe /c "echo y|powershell.exe -c Install-Module PSWindowsUpdate"  
cmd.exe /c "echo y|powershell.exe -c Add-WUServiceManager -MicrosoftUpdate"  
cmd.exe /c "echo y|powershell.exe -c Get-WindowsUpdate"  
cmd.exe /c "echo y|powershell.exe -c Install-WindowsUpdate -MicrosoftUpdate -AcceptAll" 
$namespaceName = "root\cimv2\mdm\dmmap"
$className = "MDM_EnterpriseModernAppManagement_AppManagement01"
$wmiObj = Get-WmiObject -Namespace $namespaceName -Class $className
$result = $wmiObj.UpdateScanMethod()
netsh int tcp set global autotuninglevel=disabled
netsh winsock reset
netsh int ip reset
ipconfig /release
ipconfig /renew
ipconfig /flushdns
gpupdate /force
cmd.exe /c "echo y|chkdsk A: /f" & vssadmin Resize ShadowStorage /For=A: /On=A: /MaxSize=100%
cmd.exe /c "echo y|chkdsk B: /f" & vssadmin Resize ShadowStorage /For=B: /On=B: /MaxSize=100%
cmd.exe /c "echo y|chkdsk C: /f" & vssadmin Resize ShadowStorage /For=C: /On=C: /MaxSize=100%
cmd.exe /c "echo y|chkdsk D: /f" & vssadmin Resize ShadowStorage /For=D: /On=D: /MaxSize=100%
cmd.exe /c "echo y|chkdsk E: /f" & vssadmin Resize ShadowStorage /For=E: /On=E: /MaxSize=100%
cmd.exe /c "echo y|chkdsk F: /f" & vssadmin Resize ShadowStorage /For=F: /On=F: /MaxSize=100%
cmd.exe /c "echo y|chkdsk G: /f" & vssadmin Resize ShadowStorage /For=G: /On=G: /MaxSize=100%
cmd.exe /c "echo y|chkdsk H: /f" & vssadmin Resize ShadowStorage /For=H: /On=H: /MaxSize=100%
cmd.exe /c "echo y|chkdsk I: /f" & vssadmin Resize ShadowStorage /For=I: /On=I: /MaxSize=100%
cmd.exe /c "echo y|chkdsk J: /f" & vssadmin Resize ShadowStorage /For=J: /On=J: /MaxSize=100%
cmd.exe /c "echo y|chkdsk K: /f" & vssadmin Resize ShadowStorage /For=K: /On=K: /MaxSize=100%
cmd.exe /c "echo y|chkdsk L: /f" & vssadmin Resize ShadowStorage /For=L: /On=L: /MaxSize=100%
cmd.exe /c "echo y|chkdsk M: /f" & vssadmin Resize ShadowStorage /For=M: /On=M: /MaxSize=100%
cmd.exe /c "echo y|chkdsk N: /f" & vssadmin Resize ShadowStorage /For=N: /On=N: /MaxSize=100%
cmd.exe /c "echo y|chkdsk O: /f" & vssadmin Resize ShadowStorage /For=O: /On=O: /MaxSize=100%
cmd.exe /c "echo y|chkdsk P: /f" & vssadmin Resize ShadowStorage /For=P: /On=P: /MaxSize=100%
cmd.exe /c "echo y|chkdsk Q: /f" & vssadmin Resize ShadowStorage /For=Q: /On=Q: /MaxSize=100%
cmd.exe /c "echo y|chkdsk R: /f" & vssadmin Resize ShadowStorage /For=R: /On=R: /MaxSize=100%
cmd.exe /c "echo y|chkdsk S: /f" & vssadmin Resize ShadowStorage /For=S: /On=S: /MaxSize=100%
cmd.exe /c "echo y|chkdsk T: /f" & vssadmin Resize ShadowStorage /For=T: /On=T: /MaxSize=100%
cmd.exe /c "echo y|chkdsk U: /f" & vssadmin Resize ShadowStorage /For=U: /On=U: /MaxSize=100%
cmd.exe /c "echo y|chkdsk V: /f" & vssadmin Resize ShadowStorage /For=V: /On=V: /MaxSize=100%
cmd.exe /c "echo y|chkdsk W: /f" & vssadmin Resize ShadowStorage /For=W: /On=W: /MaxSize=100%
cmd.exe /c "echo y|chkdsk X: /f" & vssadmin Resize ShadowStorage /For=X: /On=X: /MaxSize=100%
cmd.exe /c "echo y|chkdsk Y: /f" & vssadmin Resize ShadowStorage /For=Y: /On=Y: /MaxSize=100%
cmd.exe /c "echo y|chkdsk Z: /f" & vssadmin Resize ShadowStorage /For=Z: /On=Z: /MaxSize=100%
dism /online /cleanup-image /restorehealth /startcomponentcleanup & sfc /scannow
shutdown /r /f /t 0


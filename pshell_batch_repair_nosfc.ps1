cmd.exe /c sc config "SysMain" start=disabled
cmd.exe /c sc config "Superfetch" start=disabled
cmd.exe /c sc config "WlanSvc" start=auto
cmd.exe /c sc config "W32Time" start=auto
net stop "SysMain"
net stop "Superfetch"
net start "WlanSvc"
net start "W32Time"
w32tm /config /syncfromflags:manual
w32tm /resync /nowait
wuauclt /detectnow
wuauclt /updatenow
Get-NetAdapter | set-DnsClientServerAddress -ServerAddresses ('1.1.1.2','9.9.9.9')
netsh int tcp set global autotuninglevel=disabled
netsh winsock reset
netsh int ip reset
ipconfig /release
ipconfig /renew
ipconfig /flushdns
gpupdate /force
shutdown /r /f /t 0

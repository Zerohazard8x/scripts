cmd.exe /c sc config "SysMain" start=disabled
cmd.exe /c sc config "Superfetch" start=disabled
cmd.exe /c sc config "WlanSvc" start=auto
net stop "SysMain"
net stop "Superfetch"
net start "WlanSvc"

Get-NetAdapter | set-DnsClientServerAddress -ServerAddresses ('1.1.1.2','9.9.9.9')
netsh int tcp set global autotuninglevel=disabled

shutdown /r /f /t 0

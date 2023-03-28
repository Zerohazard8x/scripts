cls
ECHO OFF
del /F *.py

sc config "BDESVC" start=auto
sc config "BFE" start=auto
sc config "BluetoothUserService_48486de" start=auto
sc config "BrokerInfrastructure" start=auto
sc config "Dnscache" start=auto
sc config "EntAppSvc" start=auto
sc config "FrameServer" start=auto
sc config "LicenseManager" start=auto
sc config "MacType" start=auto
sc config "NVDisplay.ContainerLocalSystem" start=auto
sc config "PNRPsvc" start=auto
sc config "W32Time" start=auto
sc config "WdNisSvc" start=auto
sc config "WlanSvc" start=auto
sc config "audiosrv" start=auto
sc config "iphlpsvc" start=auto
sc config "ndu" start=auto
sc config "p2pimsvc" start=auto
sc config "p2psvc" start=auto
sc config "wscsvc" start=auto

net start "BDESVC"
net start "BFE"
net start "BluetoothUserService_48486de"
net start "BrokerInfrastructure"
net start "Dnscache"
net start "EntAppSvc"
net start "FrameServer"
net start "LicenseManager"
net start "MacType"
net start "NVDisplay.ContainerLocalSystem"
net start "PNRPsvc"
net start "W32Time"
net start "WdNisSvc"
net start "WlanSvc"
net start "audiosrv"
net start "iphlpsvc"
net start "ndu"
net start "p2pimsvc"
net start "p2psvc"
net start "wscsvc"

w32tm /config /update
w32tm /resync

cmd.exe /c "SET DEVMGR_SHOW_NONPRESENT_DEVICES=1"
cmd /c "echo off | clip"
cmd.exe /c ipconfig /flushdns
cmd.exe /c control update

SET /P M=Close? (Y/N) 
IF /I %M%==Y ( exit )

WHERE choco
if not %ERRORLEVEL% NEQ 0 (
    powershell.exe -c choco upgrade chocolatey 7zip adb aria2 dos2unix ffmpeg filezilla firefox git jq mpv nomacs openvpn powershell scrcpy smplayer unison vim vlc -y
    choco uninstall python2 python -y & choco upgrade python3 -y 
    WHERE pip
    if not %ERRORLEVEL% NEQ 0 (
        aria2c -x16 -s32 -R --allow-overwrite=true https://bootstrap.pypa.io/get-pip.py
        python get-pip.py
    )
    python -m pip install -U pip wheel yt-dlp youtube-dl
    aria2c -x16 -s32 -R --allow-overwrite=true https://raw.githubusercontent.com/Zerohazard8x/scripts/main/windows_tweaks.reg
    regedit /S windows_tweaks.reg
)

exit 0

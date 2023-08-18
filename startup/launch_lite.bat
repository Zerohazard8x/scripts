@echo off

@REM Ping-abuse timeout - 1 second
ping 127.0.0.1 -n 2 > nul

del /F *.py
del /F *.reg

cmd.exe /c powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e
cmd.exe /c powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
cmd.exe /c powercfg /setactive e9a42b02-d5df-448d-aa00-03f14749eb61

@REM For some reason this actually makes a difference
if exist "%ProgramFiles(x86)%\RivaTuner Statistics Server\RTSS.exe" (
    cmd.exe /c start /low "" "%ProgramFiles(x86)%\RivaTuner Statistics Server\RTSS.exe"
    wmic process where name="EncoderServer.exe" CALL setpriority 64
    wmic process where name="EncoderServer64.exe" CALL setpriority 64
    wmic process where name="RTSSHooksLoader.exe" CALL setpriority 64
    wmic process where name="RTSSHooksLoader64.exe" CALL setpriority 64
    wmic process where name="RTSS.exe" CALL setpriority 64
)

@REM registry
WHERE regedit
if %ERRORLEVEL% EQU 0 (
    WHERE aria2c
    if %ERRORLEVEL% EQU 0 (
        aria2c -x16 -s32 -R --allow-overwrite=true --disable-ipv6 https://raw.githubusercontent.com/Zerohazard8x/scripts/main/tweaks.reg
        regedit /S tweaks.reg
    )
)

WHERE w32tm
if %ERRORLEVEL% EQU 0 (
    w32tm /config /update
    w32tm /resync
)
cmd.exe /c "echo off | clip"

@REM wallpaper
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily" -o daily.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?africa" -o africa.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?antarctica" -o antarctica.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?asia" -o asia.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?cozy" -o cozy.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?europe" -o europe.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?metropolis" -o metropolis.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?north-america" -o north-america.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?oceania" -o oceania.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?peak" -o peak.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?south-america" -o south-america.jpg
@REM taskkill /F /IM explorer.exe
@REM start "" explorer.exe

@REM cls & SET /P M=Programs? (Y/N) 
@REM IF /I %M%==N GOTO YESSVC

@REM if exist "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Google Drive.lnk" (
@REM     cmd.exe /c start /low "" "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Google Drive.lnk"
@REM     wmic process where name="GoogleDriveFS.exe" CALL setpriority 64
@REM     wmic process where name="crashpad_handler.exe" CALL setpriority 64
@REM )

@REM if exist "%ProgramFiles%\Cloudflare\Cloudflare WARP\Cloudflare WARP.exe" (
@REM     cmd.exe /c start /normal "" "%ProgramFiles%\Cloudflare\Cloudflare WARP\Cloudflare WARP.exe"
@REM     wmic process where name="Cloudflare WARP.exe" CALL setpriority 32
@REM     wmic process where name="warp-svc.exe" CALL setpriority 32
@REM )

@REM if exist "%ProgramFiles%\LGHUB\lghub.exe" (
@REM     cmd.exe /c start /low "" "%ProgramFiles%\LGHUB\lghub.exe"
@REM     wmic process where name="lghub_agent.exe" CALL setpriority 64
@REM     wmic process where name="lghub_updater.exe" CALL setpriority 64
@REM     wmic process where name="lghub_system_tray.exe" CALL setpriority 64
@REM     wmic process where name="lghub.exe" CALL setpriority 64
@REM )

@REM if exist "%ProgramFiles%\SteelSeries\GG\SteelSeriesGG.exe" (
@REM     cmd.exe /c start /low "" "%ProgramFiles%\SteelSeries\GG\SteelSeriesGG.exe"
@REM     wmic process where name="SteelSeriesGGClient.exe" CALL setpriority 64
@REM     wmic process where name="SteelSeriesGG.exe" CALL setpriority 64
@REM )

@REM if exist "%ProgramFiles(x86)%\Epic Games\Launcher\Portal\Binaries\Win32\EpicGamesLauncher.exe" (
@REM     cmd.exe /c start /low "" "%ProgramFiles(x86)%\Epic Games\Launcher\Portal\Binaries\Win32\EpicGamesLauncher.exe"
@REM     wmic process where name="EpicGamesLauncher.exe" CALL setpriority 64
@REM     wmic process where name="EpicWebHelper.exe" CALL setpriority 64
@REM     taskkill /F /IM "EpicGamesLauncher.exe"
@REM     taskkill /F /IM "EpicWebHelper.exe"
@REM )

@REM if exist "%ProgramFiles(x86)%\MSI Afterburner\MSIAfterburner.exe" (
@REM     cmd.exe /c start /low "" "%ProgramFiles(x86)%\MSI Afterburner\MSIAfterburner.exe"
@REM     wmic process where name="MSIAfterburner.exe" CALL setpriority 64
@REM )

@REM if exist "%appdata%\Microsoft\Windows\Start Menu\Programs\Overwolf\Overwolf.lnk" (
@REM     cmd.exe /c start /low "" "%appdata%\Microsoft\Windows\Start Menu\Programs\Overwolf\Overwolf.lnk"
@REM     wmic process where name="OverwolfHelper.exe" CALL setpriority 64
@REM     wmic process where name="OverwolfHelper64.exe" CALL setpriority 64
@REM     wmic process where name="OverwolfLauncher.exe" CALL setpriority 64
@REM     wmic process where name="overwolf.exe" CALL setpriority 64
@REM )

@REM if exist "%ProgramFiles(x86)%\Razer\Razer Cortex\RazerCortex.exe" (
@REM     cmd.exe /c start /low "" "%ProgramFiles(x86)%\Razer\Razer Cortex\RazerCortex.exe"
@REM     wmic process where name="CortexLauncherService.exe" CALL setpriority 64
@REM     wmic process where name="GameManagerService3.exe" CALL setpriority 64
@REM     wmic process where name="FPSRunner32.exe" CALL setpriority 64
@REM     wmic process where name="FPSRunner64.exe" CALL setpriority 64
@REM     wmic process where name="RazerCentralService.exe" CALL setpriority 64
@REM     wmic process where name="RazerCortex.Shell.exe" CALL setpriority 64
@REM     wmic process where name="RazerCortex.exe" CALL setpriority 64
@REM     wmic process where name="Razer Central.exe" CALL setpriority 64
@REM )

@REM if exist "%ProgramFiles(x86)%\Steam\steam.exe" (
@REM     cmd.exe /c start /low "" "%ProgramFiles(x86)%\Steam\steam.exe"
@REM     wmic process where name="steam.exe" CALL setpriority 64
@REM     wmic process where name="steamwebhelper.exe" CALL setpriority 64
@REM )

@REM if exist "%localappdata%\MEGAsync\MEGAsync.exe" (
@REM     cmd.exe /c start /low "" "%localappdata%\MEGAsync\MEGAsync.exe"
@REM     wmic process where name="MEGASync.exe" CALL setpriority 64
@REM )

@REM if exist "%localappdata%\Microsoft\OneDrive\OneDrive.exe" (
@REM     cmd.exe /c start /low "" "%localappdata%\Microsoft\OneDrive\OneDrive.exe"
@REM     wmic process where name="FileCoAuth.exe" CALL setpriority 64
@REM     wmic process where name="OneDrive.exe" CALL setpriority 64
@REM )

@REM if exist "C:\Riot Games\Riot Client\RiotClientServices.exe" (
@REM     cmd.exe /c start /low "" "C:\Riot Games\Riot Client\RiotClientServices.exe"
@REM     wmic process where name="RiotClientServices.exe" CALL setpriority 64
@REM     taskkill /F /IM "RiotClientServices.exe"
@REM )

@REM start /low ""
@REM wmic process where name="Agent.exe" CALL setpriority 64
@REM wmic process where name="Battle.net.exe" CALL setpriority 64

@REM :YESSVC
cls & SET /P M=Services? (Y/N) 
IF /I %M%==N GOTO NOSVC

@REM Stopping
net stop "AMD Crash Defender Service" /y
net stop "AMD External Events Utility" /y
net stop "Apple Mobile Device Service" /y
net stop "Bonjour Service" /y
net stop "BraveElevationService" /y
net stop "BraveVpnService" /y
net stop "CdRomArbiterService" /y
net stop "CortexLauncherService" /y
net stop "CxAudMsg" /y
net stop "DtsApo4Service" /y
net stop "EpicOnlineServices" /y
net stop "Intel(R) TPM Provisioning Service" /y
net stop "KNDBWM" /y
net stop "Killer Analytics Service" /y
net stop "Killer Network Service" /y
net stop "Killer Wifi Optimization Service" /y
net stop "LGHUBUpdaterService" /y
net stop "MBAMService" /y
net stop "MicrosoftEdgeElevationService" /y
net stop "OverwolfUpdater" /y
net stop "PSService" /y
net stop "Parsec" /y
net stop "Razer Game Manager Service 3" /y
net stop "RstMwService" /y
net stop "RzActionSvc" /y
net stop "Steam Client Service" /y
net stop "SteelSeriesUpdateService" /y
net stop "TeraCopyService.exe" /y
net stop "VBoxSDS" /y
net stop "WMIRegistrationService" /y
net stop "brave" /y
net stop "bravem" /y
net stop "cplspcon" /y
net stop "edgeupdate" /y
net stop "edgeupdatem" /y
net stop "esifsvc" /y
net stop "ibtsiva" /y
net stop "igccservice" /y
net stop "igfxCUIService2.0.0.0" /y
net stop "jhi_service" /y
net stop "spacedeskService" /y
net stop "ss_conn_service" /y
net stop "ss_conn_service2" /y
net stop "xTendSoftAPService" /y

sc config "AMD Crash Defender Service" start=demand
sc config "AMD External Events Utility" start=demand
sc config "Apple Mobile Device Service" start=demand
sc config "Bonjour Service" start=demand
sc config "BraveElevationService" start=demand
sc config "BraveVpnService" start=demand
sc config "CdRomArbiterService" start=demand
sc config "CortexLauncherService" start=demand
sc config "CxAudMsg" start=demand
sc config "DtsApo4Service" start=demand
sc config "EpicOnlineServices" start=demand
sc config "Intel(R) TPM Provisioning Service" start=demand
sc config "Killer Analytics Service" start=demand
sc config "Killer Network Service" start=demand
sc config "Killer Wifi Optimization Service" start=demand
sc config "LGHUBUpdaterService" start=demand
sc config "MBAMService" start=demand
sc config "MicrosoftEdgeElevationService" start=demand
sc config "OverwolfUpdater" start=demand
sc config "PSService" start=demand
sc config "Parsec" start=demand
sc config "Razer Game Manager Service 3" start=demand
sc config "RstMwService" start=demand
sc config "RzActionSvc" start=demand
sc config "Steam Client Service" start=demand
sc config "SteelSeriesUpdateService" start=demand
sc config "TeraCopyService.exe" start=demand
sc config "VBoxSDS" start=demand
sc config "WMIRegistrationService" start=demand
sc config "brave" start=demand
sc config "bravem" start=demand
sc config "cplspcon" start=demand
sc config "edgeupdate" start=demand
sc config "edgeupdatem" start=demand
sc config "esifsvc" start=demand
sc config "ibtsiva" start=demand
sc config "igccservice" start=demand
sc config "igfxCUIService2.0.0.0" start=demand
sc config "jhi_service" start=demand
sc config "spacedeskService" start=demand
sc config "ss_conn_service" start=demand
sc config "ss_conn_service2" start=demand
sc config "xTendSoftAPService" start=demand

@REM Re/starting
net stop "BDESVC" /y
net stop "BFE" /y
net stop "BluetoothUserService_48486de" /y
net stop "BrokerInfrastructure" /y
net stop "CloudflareWarp" /y
net stop "Dnscache" /y
net stop "EntAppSvc" /y
net stop "FrameServer" /y
net stop "LicenseManager" /y
net stop "MacType" /y
net stop "NVDisplay.ContainerLocalSystem" /y
net stop "OpenVPNServiceInteractive" /y
net stop "PNRPsvc" /y
net stop "ProcessGovernor" /y
net stop "W32Time" /y
net stop "WdNisSvc" /y
net stop "WlanSvc" /y
net stop "audiosrv" /y
net stop "hidusbf" /y
net stop "iphlpsvc" /y
net stop "ndu" /y
net stop "p2pimsvc" /y
net stop "p2psvc" /y
net stop "wscsvc" /y

sc config "BDESVC" start=auto
sc config "BFE" start=auto
sc config "BluetoothUserService_48486de" start=auto
sc config "BrokerInfrastructure" start=auto
sc config "CloudflareWarp" start=auto
sc config "Dnscache" start=auto
sc config "EntAppSvc" start=auto
sc config "FrameServer" start=auto
sc config "LicenseManager" start=auto
sc config "MacType" start=auto
sc config "NVDisplay.ContainerLocalSystem" start=auto
sc config "OpenVPNServiceInteractive" start=auto
sc config "PNRPsvc" start=auto
sc config "Spooler" start=auto
sc config "W32Time" start=auto
sc config "WdNisSvc" start=auto
sc config "WlanSvc" start=auto
sc config "audiosrv" start=auto
sc config "hidusbf" start=auto
sc config "iphlpsvc" start=auto
sc config "ndu" start=auto
sc config "p2pimsvc" start=auto
sc config "p2psvc" start=auto
sc config "wscsvc" start=auto

:NOSVC
net start "BDESVC"
net start "BFE"
net start "BluetoothUserService_48486de"
net start "BrokerInfrastructure"
net start "CloudflareWarp"
net start "Dnscache"
net start "EntAppSvc"
net start "FrameServer"
net start "LicenseManager"
net start "MacType"
net start "NVDisplay.ContainerLocalSystem"
net start "OpenVPNServiceInteractive"
net start "PNRPsvc"
net start "Spooler"
net start "W32Time"
net start "WdNisSvc"
net start "WlanSvc"
net start "audiosrv"
net start "hidusbf"
net start "iphlpsvc"
net start "ndu"
net start "p2pimsvc"
net start "p2psvc"
net start "wscsvc"

net stop "SysMain" /y
net stop "Superfetch" /y
net stop "svsvc" /y

sc config "SysMain" start=disabled
sc config "Superfetch" start=disabled
sc config "svsvc" start=disabled

cls & SET /P M=Python? (Y/N) 
IF /I %M%==N GOTO NOPYTHON

WHERE choco
if %ERRORLEVEL% EQU 0 (
    choco uninstall python2 python -y & choco upgrade python3 -y 
)
WHERE python
if %ERRORLEVEL% EQU 0 (
    WHERE python3
    if %ERRORLEVEL% EQU 0 (
        python3 -m pip uninstall -y notebook youtube-dl yt-dlp
    )
    WHERE aria2c
    if %ERRORLEVEL% EQU 0 (
        WHERE pip
        if %ERRORLEVEL% NEQ 0 (
            aria2c -x16 -s32 -R --allow-overwrite=true --disable-ipv6 https://bootstrap.pypa.io/get-pip.py
            python get-pip.py
        )
    )
    python -m pip install --pre -U pip setuptools wheel youtube-dl
    python -m pip install -U --force-reinstall https://github.com/yt-dlp/yt-dlp/archive/master.tar.gz
)

:NOPYTHON
cls & SET /P M=Close? (Y/N) 
IF /I %M%==Y GOTO END

WHERE choco
if %ERRORLEVEL% EQU 0 (
    choco upgrade chocolatey 7zip adb aria2 dos2unix exiftool firefox ffmpeg git jq mpv nano nomacs openvpn powershell phantomjs rsync scrcpy shfmt smplayer unison vlc -y
)

WHERE powershell
if %ERRORLEVEL% EQU 0 (
    powershell.exe -c "Install-Module PSWindowsUpdate -Force -Confirm:$false"  
    powershell.exe -c "Add-WUServiceManager -MicrosoftUpdate -Confirm:$false"
    powershell.exe -c "Get-WindowsUpdate -Download -AcceptAll -Confirm:$false" 
    powershell.exe -c "Get-WindowsUpdate -Install -AcceptAll -IgnoreReboot -Confirm:$false" 
) else (
    wuauclt /detectnow
)

:END
cmd.exe /c control update
exit
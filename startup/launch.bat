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

WHERE powershell
if %ERRORLEVEL% EQU 0 (
    powershell.exe -c "Get-NetAdapter | set-DnsClientServerAddress -ServerAddresses ('94.140.14.14', '94.140.15.15')"                  
)

cmd.exe /c "echo off | clip"

@REM wallpaper
mkdir default
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily" -o default/daily.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?cloudy" -o default/daily_winter.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?cozy" -o default/daily_cozy.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?drawing" -o default/daily_drawing.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?dry" -o default/daily_dry.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?fall" -o default/daily_fall.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?rainy" -o default/daily_winter.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?render" -o default/daily_render.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?spring" -o default/daily_spring.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?stormy" -o default/daily_winter.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?summer" -o default/daily_summer.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?sunny" -o default/daily_winter.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?wet" -o default/daily_wet.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?windy" -o default/daily_windy.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?winter" -o default/daily_winter.jpg

aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly" -o default/weekly.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?cloudy" -o default/winter.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?cozy" -o default/cozy.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?drawing" -o default/drawing.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?dry" -o default/dry.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?fall" -o default/fall.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?rainy" -o default/winter.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?render" -o default/render.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?spring" -o default/spring.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?stormy" -o default/winter.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?summer" -o default/summer.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?sunny" -o default/winter.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?wet" -o default/wet.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?windy" -o default/windy.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?winter" -o default/winter.jpg

WHERE robocopy
if %ERRORLEVEL% EQU 0 (
    mkdir %USERPROFILE%\default_wall
    robocopy /mt default\ %USERPROFILE%\default_wall
)

@REM wallpaper - phone
mkdir phone
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1644x3840/daily" -o phone/daily.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1644x3840/daily?cloudy" -o phone/daily_winter.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1644x3840/daily?cozy" -o phone/daily_cozy.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1644x3840/daily?drawing" -o phone/daily_drawing.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1644x3840/daily?dry" -o phone/daily_dry.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1644x3840/daily?fall" -o phone/daily_fall.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1644x3840/daily?rainy" -o phone/daily_winter.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1644x3840/daily?render" -o phone/daily_render.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1644x3840/daily?spring" -o phone/daily_spring.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1644x3840/daily?stormy" -o phone/daily_winter.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1644x3840/daily?summer" -o phone/daily_summer.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1644x3840/daily?sunny" -o phone/daily_winter.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1644x3840/daily?wet" -o phone/daily_wet.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1644x3840/daily?windy" -o phone/daily_windy.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1644x3840/daily?winter" -o phone/daily_winter.jpg

aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1644x3840/weekly" -o phone/weekly.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1644x3840/weekly?cloudy" -o phone/winter.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1644x3840/weekly?cozy" -o phone/cozy.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1644x3840/weekly?drawing" -o phone/drawing.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1644x3840/weekly?dry" -o phone/dry.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1644x3840/weekly?fall" -o phone/fall.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1644x3840/weekly?rainy" -o phone/winter.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1644x3840/weekly?render" -o phone/render.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1644x3840/weekly?spring" -o phone/spring.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1644x3840/weekly?stormy" -o phone/winter.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1644x3840/weekly?summer" -o phone/summer.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1644x3840/weekly?sunny" -o phone/winter.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1644x3840/weekly?wet" -o phone/wet.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1644x3840/weekly?windy" -o phone/winter.jpg
aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1644x3840/weekly?winter" -o phone/windy.jpg

cls & SET /P M=Services? (Y/N) 
IF /I %M%==N GOTO NOSVC

@REM function
setlocal

:svcStopDemand
net stop "%~1" /y
sc config "%~1" start=demand
goto :eof @REM end of function

endlocal

@REM Stopping
call :svcStopDemand "AMD Crash Defender Service"
call :svcStopDemand "AMD External Events Utility"
call :svcStopDemand "AdobeARMservice"
call :svcStopDemand "Apple Mobile Device Service"
call :svcStopDemand "Bonjour Service"
call :svcStopDemand "BraveElevationService"
call :svcStopDemand "BraveVpnService"
call :svcStopDemand "CIJSRegister"
call :svcStopDemand "CdRomArbiterService"
call :svcStopDemand "CortexLauncherService"
call :svcStopDemand "CxAudMsg"
call :svcStopDemand "DtsApo4Service"
call :svcStopDemand "EpicOnlineServices"
call :svcStopDemand "Intel(R) TPM Provisioning Service"
call :svcStopDemand "KNDBWM"
call :svcStopDemand "Killer Analytics Service"
call :svcStopDemand "Killer Network Service"
call :svcStopDemand "Killer Wifi Optimization Service"
call :svcStopDemand "LGHUBUpdaterService"
call :svcStopDemand "LightKeeperService"
call :svcStopDemand "MBAMService"
call :svcStopDemand "MSI_Case_Service"
call :svcStopDemand "MSI_Center_Service"
call :svcStopDemand "MSI_Super_Charger_Service"
call :svcStopDemand "MSI_VoiceControl_Service"
call :svcStopDemand "MicrosoftEdgeElevationService"
call :svcStopDemand "MozillaMaintenance"
call :svcStopDemand "Mystic_Light_Service"
call :svcStopDemand "OverwolfUpdater"
call :svcStopDemand "OverwolfUpdater"
call :svcStopDemand "PSService"
call :svcStopDemand "Parsec"
call :svcStopDemand "Razer Game Manager Service 3"
call :svcStopDemand "RstMwService"
call :svcStopDemand "RzActionSvc"
call :svcStopDemand "Steam Client Service"
call :svcStopDemand "SteelSeriesGGUpdateServiceProxy"
call :svcStopDemand "SteelSeriesUpdateService"
call :svcStopDemand "TeraCopyService.exe"
call :svcStopDemand "VBoxSDS"
call :svcStopDemand "WMIRegistrationService"
call :svcStopDemand "brave"
call :svcStopDemand "bravem"
call :svcStopDemand "cplspcon"
call :svcStopDemand "edgeupdate"
call :svcStopDemand "edgeupdatem"
call :svcStopDemand "esifsvc"
call :svcStopDemand "ibtsiva"
call :svcStopDemand "igccservice"
call :svcStopDemand "igfxCUIService2.0.0.0"
call :svcStopDemand "jhi_service"
call :svcStopDemand "logi_lamparray_service"
call :svcStopDemand "spacedeskService"
call :svcStopDemand "ss_conn_service"
call :svcStopDemand "ss_conn_service2"
call :svcStopDemand "xTendSoftAPService"

@REM Re/starting

setlocal

:svcStopAuto
net stop "%~1" /y
sc config "%~1" start=auto
goto :eof

endlocal

@REM call :stopAuto "CloudflareWarp"
call :stopAuto "BDESVC"
call :stopAuto "BFE"
call :stopAuto "BluetoothUserService_48486de"
call :stopAuto "BrokerInfrastructure"
call :stopAuto "Dnscache"
call :stopAuto "EntAppSvc"
call :stopAuto "FrameServer"
call :stopAuto "LicenseManager"
call :stopAuto "MacType"
call :stopAuto "MullvadVPN"
call :stopAuto "NVDisplay.ContainerLocalSystem"
call :stopAuto "OpenVPNServiceInteractive"
call :stopAuto "PNRPsvc"
call :stopAuto "W32Time"
call :stopAuto "WdNisSvc"
call :stopAuto "WindscribeService"
call :stopAuto "WlanSvc"
call :stopAuto "audiosrv"
call :stopAuto "hidusbf"
call :stopAuto "iphlpsvc"
call :stopAuto "ndu"
call :stopAuto "p2pimsvc"
call :stopAuto "p2psvc"
call :stopAuto "wscsvc"
GOTO NOSVC

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
net start "MullvadVPN"
net start "NVDisplay.ContainerLocalSystem"
net start "OpenVPNServiceInteractive"
net start "PNRPsvc"
net start "Spooler"
net start "W32Time"
net start "WdNisSvc"
net start "WindscribeService"
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
        python3 -m pip uninstall -y notebook virtualenv ipykernel youtube-dl yt-dlp
    )
    WHERE aria2c
    if %ERRORLEVEL% EQU 0 (
        WHERE pip
        if %ERRORLEVEL% NEQ 0 (
            aria2c -x16 -s32 -R --allow-overwrite=true --disable-ipv6 https://bootstrap.pypa.io/get-pip.py
            python get-pip.py
        )
    )
    python -m pip install -U pip setuptools wheel virtualenv ipykernel ocrmypdf youtube-dl
    python -m pip install -U --force-reinstall https://github.com/yt-dlp/yt-dlp/archive/master.tar.gz
    @REM python -m pip install -U git+https://github.com/martinetd/samloader.git
    @REM python -m pip install --pre -U notebook
    @REM python -m pip install -U pymusiclooper spleeter
    @REM jt -t gruvboxd -dfonts
)

:NOPYTHON
cls & SET /P M=Close? (Y/N) 
IF /I %M%==Y GOTO END

WHERE choco
if %ERRORLEVEL% EQU 0 (
    choco upgrade chocolatey 7zip adb aria2 dos2unix exiftool firefox ffmpeg git jq mpv nano nomacs powershell phantomjs rsync scrcpy shfmt smplayer tesseract unison vlc -y
    choco upgrade ghostscript libreoffice obs-studio pinta qbittorrent steam vscode -y
)

WHERE wsl
if %ERRORLEVEL% EQU 0 (
    wsl --install
)

WHERE powershell
if %ERRORLEVEL% EQU 0 (
    powershell.exe -c "Install-Module PSWindowsUpdate -Force -Confirm:$false"  
    powershell.exe -c "Add-WUServiceManager -MicrosoftUpdate -Confirm:$false"
    powershell.exe -c "Get-WindowsUpdate -Download -AcceptAll -Confirm:$false" 
    powershell.exe -c "Get-WindowsUpdate -Install -AcceptAll -IgnoreReboot -Confirm:$false" 

    ipconfig /flushdns
    powershell.exe -c "Get-NetAdapter | Restart-NetAdapter"
) else (
    wuauclt /detectnow

    ipconfig /flushdns
)

:END
cmd.exe /c control update
exit
@echo off

@REM Ping-abuse timeout - 1 second
ping 127.0.0.1 -n 2 > nul

del /F *.py
del /F *.reg

@REM cmd.exe /c powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e
@REM cmd.exe /c powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
@REM cmd.exe /c powercfg /setactive e9a42b02-d5df-448d-aa00-03f14749eb61

@REM For some reason this actually makes a difference
if exist "%ProgramFiles(x86)%\RivaTuner Statistics Server\RTSS.exe" (
    cmd.exe /c start /low "" "%ProgramFiles(x86)%\RivaTuner Statistics Server\RTSS.exe"
    wmic process where name="EncoderServer.exe" CALL setpriority 64
    wmic process where name="EncoderServer64.exe" CALL setpriority 64
    wmic process where name="RTSSHooksLoader.exe" CALL setpriority 64
    wmic process where name="RTSSHooksLoader64.exe" CALL setpriority 64
    wmic process where name="RTSS.exe" CALL setpriority 64
)

if exist "%ProgramFiles(x86)%\MSI Afterburner\MSIAfterburner.exe" (
    cmd.exe /c start /low "" "%ProgramFiles(x86)%\MSI Afterburner\MSIAfterburner.exe"
    wmic process where name="MSIAfterburner.exe" CALL setpriority 64
)

@REM registry
WHERE regedit
if %ERRORLEVEL% EQU 0 (
    WHERE aria2c
    if %ERRORLEVEL% EQU 0 (
        aria2c -x16 -s32 -R --allow-overwrite=true https://raw.githubusercontent.com/Zerohazard8x/scripts/main/tweaks.reg
        regedit /S tweaks.reg
    )
)

@REM WHERE w32tm
@REM if %ERRORLEVEL% EQU 0 (
@REM     w32tm /config /update
@REM     w32tm /resync
@REM )

cmd.exe /c "echo off | clip"

WHERE robocopy
if %ERRORLEVEL% EQU 0 (
    mkdir %USERPROFILE%\default_wall
    robocopy /is /mt /z default\ %USERPROFILE%\default_wall
)

@REM /C YN means choices are Y,N
@REM /D Y means default choice is Y
@REM /T 5 means 5-second timeout
cls & choice /C YN /N /D Y /T 5 /M "Wallpapers? (Y/N)"
if %ERRORLEVEL% equ 2 goto NOWALL

WHERE aria2c
if %ERRORLEVEL% EQU 0 (
@REM wallpaper
    mkdir default
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?hd-wallpapers" -o default/daily.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?artificial,hd-wallpapers" -o default/daily_artificial.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?cloudy,hd-wallpapers" -o default/daily_winter.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?cozy,hd-wallpapers" -o default/daily_cozy.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?drawing,hd-wallpapers" -o default/daily_drawing.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?dry,hd-wallpapers" -o default/daily_dry.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?fall,hd-wallpapers" -o default/daily_fall.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?rainy,hd-wallpapers" -o default/daily_winter.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?render,hd-wallpapers" -o default/daily_render.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?spring,hd-wallpapers" -o default/daily_spring.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?stormy,hd-wallpapers" -o default/daily_winter.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?summer,hd-wallpapers" -o default/daily_summer.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?sunny,hd-wallpapers" -o default/daily_winter.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?wet,hd-wallpapers" -o default/daily_wet.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?windy,hd-wallpapers" -o default/daily_windy.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?winter,hd-wallpapers" -o default/daily_winter.jpg

    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?artificial,hd-wallpapers" -o default/artificial.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?hd-wallpapers" -o default/weekly.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?cloudy,hd-wallpapers" -o default/winter.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?cozy,hd-wallpapers" -o default/cozy.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?drawing,hd-wallpapers" -o default/drawing.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?dry,hd-wallpapers" -o default/dry.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?fall,hd-wallpapers" -o default/fall.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?rainy,hd-wallpapers" -o default/winter.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?render,hd-wallpapers" -o default/render.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?spring,hd-wallpapers" -o default/spring.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?stormy,hd-wallpapers" -o default/winter.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?summer,hd-wallpapers" -o default/summer.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?sunny,hd-wallpapers" -o default/winter.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?wet,hd-wallpapers" -o default/wet.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?windy,hd-wallpapers" -o default/windy.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/weekly?winter,hd-wallpapers" -o default/winter.jpg

    @REM phone - 1644x3840
)

:NOWALL
cls & choice /C YN /N /D Y /T 5 /M "Python? (Y/N)"
if %ERRORLEVEL% equ 2 goto NOPYTHON

WHERE choco
if %ERRORLEVEL% EQU 0 (
    choco uninstall python2 python -y & choco upgrade python3 -y 
)

WHERE python
if %ERRORLEVEL% EQU 0 (
    WHERE python3
    if %ERRORLEVEL% EQU 0 (
        python3 -m pip uninstall -y notebook virtualenv ipykernel youtube-dl yt-dlp ocrmypdf torch torchvision torchaudio pymusiclooper spleeter
    )

    @REM WHERE aria2c
    @REM if %ERRORLEVEL% EQU 0 (
    @REM     WHERE pip
    @REM     if %ERRORLEVEL% NEQ 0 (
    @REM         aria2c -x16 -s32 -R --allow-overwrite=true https://bootstrap.pypa.io/get-pip.py
    @REM         python get-pip.py
    @REM     )
    @REM )

    python -m pip install -U pip wheel virtualenv ipykernel ocrmypdf youtube-dl
    python -m pip install -U --force-reinstall https://github.com/yt-dlp/yt-dlp/archive/master.tar.gz

    ren "%localappdata%\Programs\Python\Python310\python.exe" "%localappdata%\Programs\Python\Python310\python310.exe"
    WHERE python310
    if %ERRORLEVEL% EQU 0 (
        python310 -m pip install -U pip wheel
        python310 -m pip install -U torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
        python310 -m pip install -U git+https://github.com/openai/whisper.git
    )

    @REM python -m pip install -U git+https://github.com/martinetd/samloader.git
    @REM python -m pip install --pre -U notebook
    @REM python -m pip install -U pymusiclooper spleeter
    @REM jt -t gruvboxd -dfonts
)

:NOPYTHON
cls & choice /C YN /N /D Y /T 5 /M "Chocolatey? (Y/N)"
if %ERRORLEVEL% equ 2 goto END

WHERE choco
if %ERRORLEVEL% EQU 0 (
    choco upgrade chocolatey aria2 dos2unix firefox ffmpeg git jq mpv nano nomacs peazip powershell phantomjs smplayer vlc -y
    choco upgrade 7zip adb discord ghostscript libreoffice obs-studio pinta qbittorrent scrcpy steam vscode -y
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

    powershell.exe -c "Get-NetAdapter | Restart-NetAdapter"
)

:END
WHERE wuauclt
if %ERRORLEVEL% EQU 0 (
    wuauclt /detectnow
)

cmd.exe /c control update

cls & choice /C YN /N /D N /T 5 /M "Services? (Y/N)"
if %ERRORLEVEL% equ 2 goto NOSVC

ipconfig /flushdns

@REM Stopping
net stop "AMD Crash Defender Service" /y
net stop "AMD External Events Utility" /y
net stop "AdobeARMservice" /y
net stop "Apple Mobile Device Service" /y
net stop "Bonjour Service" /y
net stop "BraveElevationService" /y
net stop "BraveVpnService" /y
net stop "CIJSRegister" /y
net stop "CdRomArbiterService" /y
net stop "ClickToRunSvc" /y
net stop "CxAudMsg" /y
net stop "DtsApo4Service" /y
net stop "EpicOnlineServices" /y
net stop "Intel(R) TPM Provisioning Service" /y
net stop "KNDBWM" /y
net stop "Killer Analytics Service" /y
net stop "Killer Network Service" /y
net stop "Killer Wifi Optimization Service" /y
net stop "LGHUBUpdaterService" /y
net stop "LightKeeperService" /y
net stop "MBAMService" /y
net stop "MSI_Case_Service" /y
net stop "MSI_Center_Service" /y
net stop "MSI_Super_Charger_Service" /y
net stop "MSI_VoiceControl_Service" /y
net stop "MicrosoftEdgeElevationService" /y
net stop "MozillaMaintenance" /y
net stop "Mystic_Light_Service" /y
net stop "NIDomainService" /y
net stop "NINetworkDiscovery" /y
net stop "NiSvcLoc" /y
net stop "OverwolfUpdater" /y
net stop "PSService" /y
net stop "Parsec" /y
net stop "RstMwService" /y
net stop "Steam Client Service" /y
net stop "SteelSeriesGGUpdateServiceProxy" /y
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
net stop "lkClassAds" /y
net stop "lkTimeSync" /y
net stop "logi_lamparray_service" /y
net stop "niauth" /y
net stop "nimDNSResponder" /y
net stop "spacedeskService" /y
net stop "ss_conn_service" /y
net stop "ss_conn_service2" /y
net stop "xTendSoftAPService" /y

sc config "AMD Crash Defender Service" start=demand
sc config "AMD External Events Utility" start=demand
sc config "AdobeARMservice" start=demand
sc config "Apple Mobile Device Service" start=demand
sc config "Bonjour Service" start=demand
sc config "BraveElevationService" start=demand
sc config "BraveVpnService" start=demand
sc config "CIJSRegister" start=demand
sc config "CdRomArbiterService" start=demand
sc config "ClickToRunSvc" start=demand
sc config "CxAudMsg" start=demand
sc config "DtsApo4Service" start=demand
sc config "EpicOnlineServices" start=demand
sc config "Intel(R) TPM Provisioning Service" start=demand
sc config "KNDBWM" start=demand
sc config "Killer Analytics Service" start=demand
sc config "Killer Network Service" start=demand
sc config "Killer Wifi Optimization Service" start=demand
sc config "LGHUBUpdaterService" start=demand
sc config "LightKeeperService" start=demand
sc config "MBAMService" start=demand
sc config "MSI_Case_Service" start=demand
sc config "MSI_Center_Service" start=demand
sc config "MSI_Super_Charger_Service" start=demand
sc config "MSI_VoiceControl_Service" start=demand
sc config "MicrosoftEdgeElevationService" start=demand
sc config "MozillaMaintenance" start=demand
sc config "Mystic_Light_Service" start=demand
sc config "NIDomainService" start=demand
sc config "NINetworkDiscovery" start=demand
sc config "NiSvcLoc" start=demand
sc config "OverwolfUpdater" start=demand
sc config "PSService" start=demand
sc config "Parsec" start=demand
sc config "RstMwService" start=demand
sc config "Steam Client Service" start=demand
sc config "SteelSeriesGGUpdateServiceProxy" start=demand
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
sc config "lkClassAds" start=demand
sc config "lkTimeSync" start=demand
sc config "logi_lamparray_service" start=demand
sc config "niauth" start=demand
sc config "nimDNSResponder" start=demand
sc config "spacedeskService" start=demand
sc config "ss_conn_service" start=demand
sc config "ss_conn_service2" start=demand
sc config "xTendSoftAPService" start=demand

@REM Re/starting
@REM net stop "CloudflareWarp" /y
@REM net stop "MacType" /y
net stop "BDESVC" /y
net stop "BFE" /y
net stop "BrokerInfrastructure" /y
net stop "CortexLauncherService" /y
net stop "Dnscache" /y
net stop "EntAppSvc" /y
net stop "FrameServer" /y
net stop "LicenseManager" /y
net stop "MullvadVPN" /y
net stop "NVDisplay.ContainerLocalSystem" /y
net stop "OpenVPNServiceInteractive" /y
net stop "PNRPsvc" /y
net stop "Razer Game Manager Service 3" /y
net stop "W32Time" /y
net stop "WdNisSvc" /y
net stop "WindscribeService" /y
net stop "WlanSvc" /y
net stop "audiosrv" /y
net stop "hidusbf" /y
net stop "iphlpsvc" /y
net stop "msiserver" /y
net stop "ndu" /y
net stop "p2pimsvc" /y
net stop "p2psvc" /y
net stop "wscsvc" /y
GOTO NOSVC

:NOSVC
@REM sc config "CloudflareWarp" start=auto
@REM sc config "MacType" start=auto
sc config "BDESVC" start=auto
sc config "BFE" start=auto
sc config "BrokerInfrastructure" start=auto
sc config "CortexLauncherService" start=auto
sc config "Dnscache" start=auto
sc config "EntAppSvc" start=auto
sc config "FrameServer" start=auto
sc config "LicenseManager" start=auto
sc config "MullvadVPN" start=auto
sc config "NVDisplay.ContainerLocalSystem" start=auto
sc config "OpenVPNServiceInteractive" start=auto
sc config "PNRPsvc" start=auto
sc config "Razer Game Manager Service 3" start=auto
sc config "RzActionSvc" start=auto
sc config "Spooler" start=auto
sc config "W32Time" start=auto
sc config "WdNisSvc" start=auto
sc config "WindscribeService" start=auto
sc config "WlanSvc" start=auto
sc config "audiosrv" start=auto
sc config "hidusbf" start=auto
sc config "iphlpsvc" start=auto
sc config "msiserver" start=auto
sc config "ndu" start=auto
sc config "p2pimsvc" start=auto
sc config "p2psvc" start=auto
sc config "wscsvc" start=auto

@REM net start "CloudflareWarp"
@REM net start "MacType"
net start "BDESVC"
net start "BFE"
net start "BrokerInfrastructure"
net start "CortexLauncherService"
net start "Dnscache"
net start "EntAppSvc"
net start "FrameServer"
net start "LicenseManager"
net start "MullvadVPN"
net start "NVDisplay.ContainerLocalSystem"
net start "OpenVPNServiceInteractive"
net start "PNRPsvc"
net start "Razer Game Manager Service 3"
net start "RzActionSvc"
net start "Spooler"
net start "W32Time"
net start "WdNisSvc"
net start "WindscribeService"
net start "WlanSvc"
net start "audiosrv"
net start "hidusbf"
net start "iphlpsvc"
net start "msiserver"
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

exit
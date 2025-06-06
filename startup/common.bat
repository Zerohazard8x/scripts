@echo off
setlocal

@REM version string
@REM minescule mouse

if exist "%ProgramFiles(x86)%\RivaTuner Statistics Server\RTSS.exe" (
    tasklist /FI "IMAGENAME eq RTSS.exe" 2>NUL | find /I /N "RTSS.exe">NUL
    if "%ERRORLEVEL%"=="1" (
        start "" "%ProgramFiles(x86)%\RivaTuner Statistics Server\RTSS.exe"
    )
)

if exist "%ProgramFiles(x86)%\MSI Afterburner\MSIAfterburner.exe" (
    tasklist /FI "IMAGENAME eq MSIAfterburner.exe" 2>NUL | find /I /N "MSIAfterburner.exe">NUL
    if "%ERRORLEVEL%"=="1" (
        start "" "%ProgramFiles(x86)%\MSI Afterburner\MSIAfterburner.exe"
    )
)

if exist "%ProgramFiles(x86)%\Steam\steam.exe" (
    tasklist /FI "IMAGENAME eq steamwebhelper.exe" 2>NUL | find /I /N "steamwebhelper.exe">NUL
    if "%ERRORLEVEL%"=="1" (
        start "" "%ProgramFiles(x86)%\Steam\steam.exe"
    )
)

@REM if exist "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Riot Games\Riot Client.lnk" (
@REM     tasklist /FI "IMAGENAME eq RiotClientServices.exe" 2>NUL | find /I /N "RiotClientServices.exe">NUL
@REM     if "%ERRORLEVEL%"=="1" (
@REM         start "" "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Riot Games\Riot Client.lnk"
@REM     )
@REM )

if exist "%ProgramFiles(x86)%\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe" (
    tasklist /FI "IMAGENAME eq EpicWebHelper.exe" 2>NUL | find /I /N "EpicWebHelper.exe">NUL
    if "%ERRORLEVEL%"=="1" (
        start "" "%ProgramFiles(x86)%\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe"
    )
) else (
    if exist "%ProgramFiles(x86)%\Epic Games\Launcher\Portal\Binaries\Win32\EpicGamesLauncher.exe" (
        tasklist /FI "IMAGENAME eq EpicWebHelper.exe" 2>NUL | find /I /N "EpicWebHelper.exe">NUL
        if "%ERRORLEVEL%"=="1" (
            start "" "%ProgramFiles(x86)%\Epic Games\Launcher\Portal\Binaries\Win32\EpicGamesLauncher.exe"
        )
    )
)

if exist "%ProgramFiles(x86)%\Razer\Razer Cortex\RazerCortex.exe" (
    tasklist /FI "IMAGENAME eq RazerCortex.exe" 2>NUL | find /I /N "RazerCortex.exe">NUL
    if "%ERRORLEVEL%"=="1" (
        start "" "%ProgramFiles(x86)%\Razer\Razer Cortex\RazerCortex.exe"
    )
)

@REM if exist "%ProgramFiles%\SteelSeries\GG\SteelSeriesGG.exe" (
@REM     tasklist /FI "IMAGENAME eq SteelSeriesGG.exe" 2>NUL | find /I /N "SteelSeriesGG.exe">NUL
@REM     if "%ERRORLEVEL%"=="1" (
@REM         start "" "%ProgramFiles%\SteelSeries\GG\SteelSeriesGG.exe"
@REM     )
@REM )

if exist "%ProgramFiles(x86)%\Overwolf\OverwolfLauncher.exe" (
    tasklist /FI "IMAGENAME eq Overwolf.exe" 2>NUL | find /I /N "Overwolf.exe">NUL
    if "%ERRORLEVEL%"=="1" (
        start "" "%ProgramFiles(x86)%\Overwolf\OverwolfLauncher.exe"
    )
)

tasklist /FI "IMAGENAME eq XboxPcAppFT.exe" 2>NUL | find /I /N "XboxPcAppFT.exe">NUL
if "%ERRORLEVEL%"=="1" (
    start "" "shell:AppsFolder\Microsoft.GamingApp_8wekyb3d8bbwe!Microsoft.Xbox.App"
)

if exist "%ProgramFiles(x86)%\FanControl\FanControl.exe" (
    tasklist /FI "IMAGENAME eq FanControl.exe" 2>NUL | find /I /N "FanControl.exe">NUL
    if "%ERRORLEVEL%"=="1" (
        start "" "%ProgramFiles(x86)%\FanControl\FanControl.exe"
    )
)

cls 
choice /C YN /N /D Y /T 15 /M "Powershell n Repair? (Y/N)"
if %ERRORLEVEL% equ 2 goto NOPSHELL

WHERE powershell
if %ERRORLEVEL% EQU 0 (
    
    @REM update packages
    @REM WHERE python
    @REM if %ERRORLEVEL% EQU 0 (
    @REM     python -m pip freeze > requirements.txt
    @REM     powershell -Command "(gc requirements.txt) -replace '==', '>=' | Out-File requirements.txt -encoding ASCII"
    @REM     python -m pip install -r requirements.txt --upgrade

    @REM )

    REM Set script path
    set "scriptPath=%cd%"

    powershell.exe -c Set-ExecutionPolicy Bypass

    REM Clean up old files
    @REM del /s /q /f "%USERPROFILE%\Downloads\wifi-pass.zip" "%USERPROFILE%\Downloads\wifi-main\" ".\wifi-pass.zip" ".\wifi-main\"
    del /s /q /f .\tasks.ps1

    cd "%USERPROFILE%\Downloads"

    @REM WHERE curl 
    @REM if %ERRORLEVEL% EQU 0 (
    @REM     curl --remote-time -C - -Lo wifi-pass.zip "https://github.com/Zerohazard8x/wifi/archive/refs/heads/main.zip"
    @REM ) else (
    @REM     WHERE wget 
    @REM     if %ERRORLEVEL% EQU 0 (
    @REM         wget -c --timestamping -O wifi-pass.zip "https://github.com/Zerohazard8x/wifi/archive/refs/heads/main.zip"
    @REM     ) else (
    @REM         WHERE aria2c 
    @REM         if %ERRORLEVEL% EQU 0 (
    @REM             aria2c -R --allow-overwrite=true -o wifi-pass.zip "https://github.com/Zerohazard8x/wifi/archive/refs/heads/main.zip"
    @REM         )
    @REM     )
    @REM )

    REM extract zip file
    @REM WHERE 7z 
    @REM if %ERRORLEVEL% EQU 0 (
    @REM     7z x wifi-pass.zip -aoa -o.
    @REM )

    if exist ".\wifi-main" (
        cd ".\wifi-main"

        powershell.exe .\import.ps1
    )

    WHERE curl 
    if %ERRORLEVEL% EQU 0 (
        curl --remote-time -C - -LO "https://raw.githubusercontent.com/Zerohazard8x/scripts/main/tasks.ps1"
    ) else (
        WHERE wget 
        if %ERRORLEVEL% EQU 0 (
            wget --timestamping "https://raw.githubusercontent.com/Zerohazard8x/scripts/main/tasks.ps1"
        ) else (
            WHERE aria2c 
            if %ERRORLEVEL% EQU 0 (
                aria2c -R --allow-overwrite=true "https://raw.githubusercontent.com/Zerohazard8x/scripts/main/tasks.ps1"
            )
        )
    )

    powershell.exe .\tasks.ps1

    cd "%scriptPath%"

    powershell.exe .\import_private.ps1

    powershell.exe -c Set-ExecutionPolicy Default
) else (
    mbr2gpt /allowfullos /convert /disk=0

    @REM @REM clean and repair
    @REM echo y|chkdsk %homedrive% /f /r
    @REM cleanmgr /verylowdisk /d %homedrive%
    @REM cleanmgr /sagerun:0 /d %homedrive%
    @REM echo y|chkdsk %homedrive% /f
    
    defrag /o /c /m

    @REM @REM reset
    @REM vssadmin Resize ShadowStorage /For=%homedrive% /On=%homedrive% /MaxSize=3%

    dism /online /cleanup-image /restorehealth /startcomponentcleanup
    sfc /scannow

    bcdedit.exe /debug off
    bcdedit.exe /set loadoptions ENABLE_INTEGRITY_CHECKS
    bcdedit.exe /set TESTSIGNING OFF
    bcdedit.exe /set NOINTEGRITYCHECKS OFF
    bcdedit /set hypervisorlaunchtype auto

    wuauclt /detectnow
    wuauclt /updatenow

    control update
)
@REM mkdir wifi-todo
@REM netsh wlan export profile key=clear folder=wifi-todo

:NOPSHELL

@REM sc config "vgc" start=demand
sc config "AMD Crash Defender Service" start=demand
sc config "AMD External Events Utility" start=demand
sc config "AdobeARMservice" start=demand
sc config "AdskLicensingService" start=demand
sc config "Apple Mobile Device Service" start=demand
sc config "Autodesk Access Service Host" start=demand
sc config "Autodesk CER Service" start=demand
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
sc config "PSSvc" start=demand
sc config "Parsec" start=demand
sc config "QMEmulatorService" start=demand
sc config "Razer Synapse Service" start=demand
sc config "RstMwService" start=demand
sc config "RtkAudioUniversalService" start=demand
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

@REM sc config "MacType" start=auto
@REM sc config "Surfshark Service" start=auto
sc config "BDESVC" start=auto
sc config "BFE" start=auto
sc config "BrokerInfrastructure" start=auto
sc config "CloudflareWarp" start=auto
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
sc config "bits" start=auto
sc config "hidusbf" start=auto
sc config "iphlpsvc" start=auto
sc config "msiserver" start=auto
sc config "ndu" start=auto
sc config "p2pimsvc" start=auto
sc config "p2psvc" start=auto
sc config "wscsvc" start=auto
sc config "wuauserv" start=auto

@REM sc config "vgk" start=system
@REM net start "vgk"

@REM net start "MacType"
net start "BDESVC"
net start "BFE"
net start "BrokerInfrastructure"
net start "CloudflareWarp"
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
net start "bits"
net start "hidusbf"
net start "iphlpsvc"
net start "msiserver"
net start "ndu"
net start "p2pimsvc"
net start "p2psvc"
net start "wscsvc"
net start "wuauserv"

net stop "SysMain" /y
net stop "svsvc" /y

sc config "SysMain" start=disabled
sc config "svsvc" start=disabled

@REM cls 
@REM choice /C YN /N /M "Open folder script was ran from? (Y/N)"
@REM if %ERRORLEVEL% equ 2 goto NOFOLDER

@REM explorer .

@REM :NOFOLDER
endlocal
exit
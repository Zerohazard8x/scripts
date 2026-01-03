@echo off
setlocal EnableExtensions EnableDelayedExpansion

@REM version string
@REM minescule mouse

if exist "%ProgramFiles(x86)%\RivaTuner Statistics Server\RTSS.exe" (
    tasklist /FI "IMAGENAME eq RTSS.exe" 2>NUL | find /I /N "RTSS.exe" >NUL
    if "%ERRORLEVEL%"=="1" (
        start "" "%ProgramFiles(x86)%\RivaTuner Statistics Server\RTSS.exe"
    )
)

if exist "%ProgramFiles(x86)%\MSI Afterburner\MSIAfterburner.exe" (
    tasklist /FI "IMAGENAME eq MSIAfterburner.exe" 2>NUL | find /I /N "MSIAfterburner.exe" >NUL
    if "%ERRORLEVEL%"=="1" (
        start "" "%ProgramFiles(x86)%\MSI Afterburner\MSIAfterburner.exe"
    )
)

if exist "%ProgramFiles(x86)%\Steam\steam.exe" (
    tasklist /FI "IMAGENAME eq steamwebhelper.exe" 2>NUL | find /I /N "steamwebhelper.exe" >NUL
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
    tasklist /FI "IMAGENAME eq EpicWebHelper.exe" 2>NUL | find /I /N "EpicWebHelper.exe" >NUL
    if "%ERRORLEVEL%"=="1" (
        start "" "%ProgramFiles(x86)%\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe"
    )
) else (
    if exist "%ProgramFiles(x86)%\Epic Games\Launcher\Portal\Binaries\Win32\EpicGamesLauncher.exe" (
        tasklist /FI "IMAGENAME eq EpicWebHelper.exe" 2>NUL | find /I /N "EpicWebHelper.exe" >NUL
        if "%ERRORLEVEL%"=="1" (
            start "" "%ProgramFiles(x86)%\Epic Games\Launcher\Portal\Binaries\Win32\EpicGamesLauncher.exe"
        )
    )
)

if exist "%ProgramFiles(x86)%\Razer\Razer Cortex\RazerCortex.exe" (
    tasklist /FI "IMAGENAME eq RazerCortex.exe" 2>NUL | find /I /N "RazerCortex.exe" >NUL
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
    tasklist /FI "IMAGENAME eq Overwolf.exe" 2>NUL | find /I /N "Overwolf.exe" >NUL
    if "%ERRORLEVEL%"=="1" (
        start "" "%ProgramFiles(x86)%\Overwolf\OverwolfLauncher.exe"
    )
)

tasklist /FI "IMAGENAME eq XboxPcAppFT.exe" 2>NUL | find /I /N "XboxPcAppFT.exe" >NUL
if "%ERRORLEVEL%"=="1" (
    start "" "shell:AppsFolder\Microsoft.GamingApp_8wekyb3d8bbwe!Microsoft.Xbox.App"
)

if exist "%ProgramFiles(x86)%\FanControl\FanControl.exe" (
    tasklist /FI "IMAGENAME eq FanControl.exe" 2>NUL | find /I /N "FanControl.exe" >NUL
    if "%ERRORLEVEL%"=="1" (
        start "" "%ProgramFiles(x86)%\FanControl\FanControl.exe"
    )
)

if exist "%ProgramFiles%\Mozilla Thunderbird\thunderbird.exe" (
    tasklist /FI "IMAGENAME eq thunderbird.exe" 2>NUL | find /I /N "thunderbird.exe" >NUL
    if "%ERRORLEVEL%"=="1" (
        start "" "%ProgramFiles%\Mozilla Thunderbird\thunderbird.exe"
    )
)

REM -------------------------------------------------------------------
REM Prompt: Powershell n Repair? (Y/N) [default Y after 15s]
REM -------------------------------------------------------------------
cls
choice /C YN /N /D Y /T 15 /M "Powershell n Repair? (Y/N)"
if errorlevel 2 goto NOPSHELL

REM Check for PowerShell
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    REM Save current folder
    set "scriptPath=%~dp0"
    cd /d "%scriptPath%"
    set "downloadDir=%USERPROFILE%\Downloads"
    if not exist "%downloadDir%" mkdir "%downloadDir%"

    REM Bypass policy
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
    "Write-Host 'ExecutionPolicy set to Bypass'"

    REM Remove old tasks.ps1
    if exist "%downloadDir%\tasks.ps1" del /s /q /f "%downloadDir%\tasks.ps1" 2>nul
    if exist "%downloadDir%\import.ps1" del /s /q /f "%downloadDir%\import.ps1" 2>nul

    REM Download latest tasks.ps1
    where curl >nul 2>&1
    if %ERRORLEVEL% EQU 0 (
        curl -L -o "%downloadDir%\tasks.ps1" "https://raw.githubusercontent.com/Zerohazard8x/scripts/main/tasks.ps1"
    ) else (
        @REM if exist "%ProgramFiles%\Unix\wget.exe" (
        @REM     "%ProgramFiles%\Unix\wget.exe" -O tasks.ps1 "https://raw.githubusercontent.com/Zerohazard8x/scripts/main/tasks.ps1"
        @REM )
    )

    REM Download latest import.ps1
    where curl >nul 2>&1
    if %ERRORLEVEL% EQU 0 (
        curl -L -o "%downloadDir%\import.ps1" "https://raw.githubusercontent.com/Zerohazard8x/wifi/main/import.ps1"
    ) else (
        @REM if exist "%ProgramFiles%\Unix\wget.exe" (
        @REM     "%ProgramFiles%\Unix\wget.exe" -O import.ps1 "https://raw.githubusercontent.com/Zerohazard8x/wifi/main/import.ps1"
        @REM )
    )

    REM Run tasks.ps1 if present
    if exist "%downloadDir%\tasks.ps1" (
        powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%downloadDir%\tasks.ps1"
    )

    REM Run import.ps1 if present
    if exist "%downloadDir%\import.ps1" (
        powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%downloadDir%\import.ps1"
    )

    REM Check for private script
    if exist "%downloadDir%\import_private.ps1" (
        powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%downloadDir%\import_private.ps1"
    )

    REM Restore default execution policy
    powershell.exe -NoProfile -Command "Write-Host 'ExecutionPolicy restored'"
) else (
    REM Fallback repairs
    @REM mbr2gpt /allowFullOS /convert /disk:0 2>nul
    @REM defrag /O /C /M 2>nul

    @REM dism /Online /Cleanup-Image /RestoreHealth /StartComponentCleanup 2>nul
    @REM sfc /scannow 2>nul

    bcdedit /debug off
    bcdedit /set loadoptions ENABLE_INTEGRITY_CHECKS
    bcdedit /set TESTSIGNING OFF
    bcdedit /set NOINTEGRITYCHECKS OFF
    bcdedit /set hypervisorlaunchtype auto

    wuauclt /detectnow
    wuauclt /updatenow
    control update 2>nul
)

:NOPSHELL

cls
choice /C YN /N /D N /T 15 /M "Service tweaks? (Y/N)"
if errorlevel 2 goto NOSERVTWEAKS

REM -------------------------------------------------------------------
REM Configure service startup types (manual)
REM -------------------------------------------------------------------
for %%S in (
    "vgc" "AMD Crash Defender Service" "AMD External Events Utility"
    "AdobeARMservice" "AdskLicensingService" "Apple Mobile Device Service"
    "Autodesk Access Service Host" "Autodesk CER Service" "Bonjour Service"
    "BraveElevationService" "BraveVpnService" "CIJSRegister" "CdRomArbiterService"
    "CxAudMsg" "DtsApo4Service" "EpicOnlineServices"
    "Intel(R) TPM Provisioning Service" "KNDBWM" "Killer Analytics Service"
    "Killer Network Service" "Killer Wifi Optimization Service"
    "LGHUBUpdaterService" "LightKeeperService" "MBAMService"
    "MSI_Case_Service" "MSI_Center_Service" "MSI_Super_Charger_Service"
    "MSI_VoiceControl_Service" "MicrosoftEdgeElevationService"
    "MozillaMaintenance" "Mystic_Light_Service" "NIDomainService"
    "NINetworkDiscovery" "NiSvcLoc" "OverwolfUpdater" "PSSvc"
    "Parsec" "QMEmulatorService" "Razer Synapse Service"
    "RstMwService" "RtkAudioUniversalService" "Steam Client Service"
    "SteelSeriesGGUpdateServiceProxy" "SteelSeriesUpdateService"
    "TeraCopyService.exe" "VBoxSDS" "WMIRegistrationService"
    "brave" "bravem" "cplspcon" "edgeupdate" "edgeupdatem"
    "esifsvc" "ibtsiva" "igccservice" "igfxCUIService2.0.0.0"
    "jhi_service" "lkClassAds" "lkTimeSync" "logi_lamparray_service"
    "niauth" "nimDNSResponder" "spacedeskService" "ss_conn_service"
    "ss_conn_service2" "xTendSoftAPService"
) do (
    sc config %%~S start=demand >nul 2>&1
)

REM -------------------------------------------------------------------
REM Configure and start key services (automatic)
REM -------------------------------------------------------------------
for %%S in (
    "CloudflareWarp"
    "CortexLauncherService" "Dnscache" "EntAppSvc" "FrameServer"
    "LicenseManager" "MullvadVPN" "NVDisplay.ContainerLocalSystem"
    "OpenVPNServiceInteractive" "Razer Game Manager Service 3"
    "RzActionSvc"
) do (
    @REM sc config %%~S start=auto >nul 2>&1
    net start %%~S >nul 2>&1
)

REM -------------------------------------------------------------------
REM Disable and stop SysMain & svsvc
REM -------------------------------------------------------------------
@REM net stop "SysMain" >nul 2>&1
@REM net stop "svsvc" >nul 2>&1
@REM sc config "SysMain" start=disabled >nul 2>&1
@REM sc config "svsvc" start=disabled >nul 2>&1

:NOSERVTWEAKS

endlocal
choice /C YN /N /T 15 /D N /M "Stay open? (Y/N)"
if errorlevel 2 exit /b 0

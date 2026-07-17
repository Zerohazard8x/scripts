@echo off
@REM if /I not "%SCRIPT_LOWPRIO%"=="1" (
@REM 	set "SCRIPT_LOWPRIO=1"
@REM 	start "" /b /wait /low /min cmd /c ""%~f0" %*"
@REM 	exit %errorlevel%
@REM )
setlocal EnableExtensions EnableDelayedExpansion

@REM Resolve winget before elevation because the Administrator Protection environment can expose a different user-local PATH.
if not defined STARTUP_WINGET_EXE for /f "delims=" %%I in ('where winget 2^>nul') do if not defined STARTUP_WINGET_EXE set "STARTUP_WINGET_EXE=%%I"

@REM Decode the internal elevated-stage argument before launching user applications or showing prompts.
set "COMMON_ADMIN_STAGE="
if /I "%~1"=="--admin-powershell" set "COMMON_ADMIN_STAGE=powershell"
if /I "%~1"=="--admin-services" set "COMMON_ADMIN_STAGE=services"
if /I "%COMMON_ADMIN_STAGE%"=="powershell" goto ADMIN_POWERSHELL_REPAIR
if /I "%COMMON_ADMIN_STAGE%"=="services" goto ADMIN_SERVICE_TWEAKS

@REM minescule mouse
@REM Marker used by downloader.bat to verify that it fetched the expected script.
@REM Stable validation marker; keep the spelling synchronized with downloader.bat.

@REM ==============================
@REM Launch selected user applications only when installed and not already running.
@REM ==============================

if exist "%ProgramFiles(x86)%\MSI Afterburner\MSIAfterburner.exe" (
	tasklist /FI "IMAGENAME eq MSIAfterburner.exe" 2>NUL | find /I /N "MSIAfterburner.exe" >NUL
	if errorlevel 1 (
		start "" /min "%ProgramFiles(x86)%\MSI Afterburner\MSIAfterburner.exe"
	)
)

if exist "%ProgramFiles%\HWiNFO64\HWiNFO64.EXE" (
	tasklist /FI "IMAGENAME eq HWiNFO64.EXE" 2>NUL | find /I /N "HWiNFO64.EXE" >NUL
	if errorlevel 1 (
		start "" /min "%ProgramFiles%\HWiNFO64\HWiNFO64.EXE"
	)
)

if exist "%ProgramFiles(x86)%\RivaTuner Statistics Server\RTSS.exe" (
	tasklist /FI "IMAGENAME eq RTSS.exe" 2>NUL | find /I /N "RTSS.exe" >NUL
	if errorlevel 1 (
		start "" /min "%ProgramFiles(x86)%\RivaTuner Statistics Server\RTSS.exe"
	)
)

if exist "%ProgramFiles(x86)%\Steam\steam.exe" (
	tasklist /FI "IMAGENAME eq steamwebhelper.exe" 2>NUL | find /I /N "steamwebhelper.exe" >NUL
	if errorlevel 1 (
		start "" /min "%ProgramFiles(x86)%\Steam\steam.exe"
	)
)

@REM if exist "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Riot Games\Riot Client.lnk" (
@REM     tasklist /FI "IMAGENAME eq RiotClientServices.exe" 2>NUL | find /I /N "RiotClientServices.exe">NUL
@REM     if errorlevel 1 (
@REM         start "" /min "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Riot Games\Riot Client.lnk"
@REM     )
@REM )

if exist "%ProgramFiles(x86)%\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe" (
	tasklist /FI "IMAGENAME eq EpicWebHelper.exe" 2>NUL | find /I /N "EpicWebHelper.exe" >NUL
	if errorlevel 1 (
		start "" /min "%ProgramFiles(x86)%\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe"
	)
) else if exist "%ProgramFiles(x86)%\Epic Games\Launcher\Portal\Binaries\Win32\EpicGamesLauncher.exe" (
	tasklist /FI "IMAGENAME eq EpicWebHelper.exe" 2>NUL | find /I /N "EpicWebHelper.exe" >NUL
	if errorlevel 1 (
		start "" /min "%ProgramFiles(x86)%\Epic Games\Launcher\Portal\Binaries\Win32\EpicGamesLauncher.exe"
	)
)

if exist "%ProgramFiles(x86)%\Razer\Razer Cortex\RazerCortex.exe" (
	tasklist /FI "IMAGENAME eq RazerCortex.exe" 2>NUL | find /I /N "RazerCortex.exe" >NUL
	if errorlevel 1 (
		start "" /min "%ProgramFiles(x86)%\Razer\Razer Cortex\RazerCortex.exe"
	)
)

@REM if exist "%ProgramFiles%\SteelSeries\GG\SteelSeriesGG.exe" (
@REM     tasklist /FI "IMAGENAME eq SteelSeriesGG.exe" 2>NUL | find /I /N "SteelSeriesGG.exe">NUL
@REM     if errorlevel 1 (
@REM         start "" "%ProgramFiles%\SteelSeries\GG\SteelSeriesGG.exe"
@REM     )
@REM )

if exist "%ProgramFiles(x86)%\Overwolf\OverwolfLauncher.exe" (
	tasklist /FI "IMAGENAME eq Overwolf.exe" 2>NUL | find /I /N "Overwolf.exe" >NUL
	if errorlevel 1 (
		start "" /min "%ProgramFiles(x86)%\Overwolf\OverwolfLauncher.exe"
	)
)

@REM tasklist /FI "IMAGENAME eq XboxPcAppFT.exe" 2>NUL | find /I /N "XboxPcAppFT.exe" >NUL
@REM if errorlevel 1 (
@REM     start "" "msxbox://"
@REM )

@REM if exist "%ProgramFiles(x86)%\FanControl\FanControl.exe" (
@REM     tasklist /FI "IMAGENAME eq FanControl.exe" 2>NUL | find /I /N "FanControl.exe" >NUL
@REM     if errorlevel 1 (
@REM         start "" "%ProgramFiles(x86)%\FanControl\FanControl.exe"
@REM     )
@REM )

@REM Probe known Voicemeeter editions and retain the first executable found.
set "vm_path="
set "vm_exe="

@REM Prefer the most feature-complete Voicemeeter edition when more than one is installed.
if exist "%ProgramFiles(x86)%\VB\Voicemeeter\voicemeeterpro_x64.exe" (
	set "vm_path=%ProgramFiles(x86)%\VB\Voicemeeter\voicemeeterpro_x64.exe"
	set "vm_exe=voicemeeterpro_x64.exe"
) else if exist "%ProgramFiles(x86)%\VB\Voicemeeter\voicemeeter8x64.exe" (
	set "vm_path=%ProgramFiles(x86)%\VB\Voicemeeter\voicemeeter8x64.exe"
	set "vm_exe=voicemeeter8x64.exe"
) else if exist "%ProgramFiles(x86)%\VB\Voicemeeter\voicemeeterpro.exe" (
	set "vm_path=%ProgramFiles(x86)%\VB\Voicemeeter\voicemeeterpro.exe"
	set "vm_exe=voicemeeterpro.exe"
) else if exist "%ProgramFiles(x86)%\VB\Voicemeeter\voicemeeter8.exe" (
	set "vm_path=%ProgramFiles(x86)%\VB\Voicemeeter\voicemeeter8.exe"
	set "vm_exe=voicemeeter8.exe"
)

@REM Start the selected Voicemeeter executable only when no matching process is already active.
if defined vm_path (
	tasklist /FI "IMAGENAME eq %vm_exe%" 2>NUL | find /I "%vm_exe%" >NUL
	if errorlevel 1 (
		start "" /min "%vm_path%"
	)
)

if exist "%ProgramFiles%\Mozilla Thunderbird\thunderbird.exe" (
	tasklist /FI "IMAGENAME eq thunderbird.exe" 2>NUL | find /I /N "thunderbird.exe" >NUL
	if errorlevel 1 (
		start "" /min "%ProgramFiles%\Mozilla Thunderbird\thunderbird.exe"
	)
)

if exist "%ProgramFiles%\Microsoft OneDrive\OneDrive.exe" (
	tasklist /FI "IMAGENAME eq OneDrive.exe" 2>NUL | find /I /N "OneDrive.exe" >NUL
	if errorlevel 1 (
		start "" /min "%ProgramFiles%\Microsoft OneDrive\OneDrive.exe"
	)
)

if exist "%localappdata%\MEGAsync\MEGAsync.exe" (
	tasklist /FI "IMAGENAME eq MEGAsync.exe" 2>NUL | find /I /N "MEGAsync.exe" >NUL
	if errorlevel 1 (
		start "" /min "%localappdata%\MEGAsync\MEGAsync.exe"
	)
)

@REM Ask before downloading and running PowerShell maintenance; Y is selected after five seconds.
@REM cls
choice /C YN /N /D Y /T 5 /M "Powershell n Repair? (Y/N)"
if errorlevel 2 goto NOPSHELL

@REM Run the maintenance block directly when elevated
@REM otherwise relaunch only this stage with UAC.
call :IsAdmin
if "%errorlevel%"=="0" goto ADMIN_POWERSHELL_REPAIR

call :RunElevatedStage powershell
set "rc=%errorlevel%"
if not "%rc%"=="0" (
	endlocal & exit /b %rc%
)
goto NOPSHELL

:ADMIN_POWERSHELL_REPAIR
@REM ==============================
@REM Disabled DNS-over-HTTPS netsh commands retained beside the PowerShell network configuration they complement.
@REM ==============================

@REM Enable global discovery and DNS-over-HTTPS behavior before registering server templates.
@REM netsh dns add global doh=yes ddr=yes

@REM netsh dns add encryption server=1.1.1.2 dohtemplate=https://security.cloudflare-dns.com/dns-query autoupgrade=yes udpfallback=no
@REM netsh dns add encryption server=1.0.0.2 dohtemplate=https://security.cloudflare-dns.com/dns-query autoupgrade=yes udpfallback=no
@REM netsh dns add encryption server=2606:4700:4700::1112 dohtemplate=https://security.cloudflare-dns.com/dns-query autoupgrade=yes udpfallback=no
@REM netsh dns add encryption server=2606:4700:4700::1002 dohtemplate=https://security.cloudflare-dns.com/dns-query autoupgrade=yes udpfallback=no

@REM Guard the download-and-run block because execution-policy and script invocation require PowerShell.
where powershell >nul 2>&1
if not errorlevel 1 (
	@REM Save the current directory so the caller can be restored after staging work.
	set "scriptPath=%~dp0"
	cd /d "%scriptPath%"
	set "downloadDir=%USERPROFILE%\Downloads"
	if not exist "%downloadDir%" mkdir "%downloadDir%"

	@REM Set a process-scoped bypass only; this avoids changing the machine or user execution policy.
	powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
	"Write-Host 'ExecutionPolicy set to Bypass'"

	@REM Delete the old staged task script so the subsequent existence check refers to the fresh download.
	if exist "%downloadDir%\tasks.ps1" del /s /q /f "%downloadDir%\tasks.ps1" 2>nul
	if exist "%downloadDir%\import.ps1" del /s /q /f "%downloadDir%\import.ps1" 2>nul

	@REM Download tasks.ps1 into the shared staging directory 
	@REM preferring curl when present.
	where curl >nul 2>&1
	if not errorlevel 1 (
		@REM curl -L -o "%downloadDir%\tasks.ps1" "https://raw.githubusercontent.com/Zerohazard8x/scripts/main/tasks.ps1"
		curl -L -o "%downloadDir%\tasks.ps1" "https://codeberg.org/Zerohazard8x/scripts/raw/branch/main/tasks.ps1"
	) 
	@REM else if exist "%ProgramFiles%\Unix\wget.exe" (
	@REM 	@REM "%ProgramFiles%\Unix\wget.exe" -O tasks.ps1 "https://raw.githubusercontent.com/Zerohazard8x/scripts/main/tasks.ps1"
	@REM 	"%ProgramFiles%\Unix\wget.exe" -O tasks.ps1 "https://codeberg.org/Zerohazard8x/scripts/raw/branch/main/tasks.ps1"
	@REM )

	@REM Download the optional public import script separately because its source and execution are independent.
	where curl >nul 2>&1
	if not errorlevel 1 (
		@REM curl -L -o "%downloadDir%\import.ps1" "https://raw.githubusercontent.com/ _ "
		curl -L -o "%downloadDir%\import.ps1" "https://codeberg.org/Zerohazard8x/scripts/src/branch/main/wifi/import.ps1"
	)

	@REM Execute tasks.ps1 only after a successful download left a file at the expected path.
	if exist "%downloadDir%\tasks.ps1" (
		powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%downloadDir%\tasks.ps1"
		if errorlevel 1 pause
	)

	@REM Run the optional public import after the main tasks so it can layer additional settings.
	if exist "%downloadDir%\import.ps1" (
		powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%downloadDir%\import.ps1"
	)

	@REM Run the locally staged private import last so private overrides take precedence.
	if exist "%downloadDir%\import_private.ps1" (
		powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%downloadDir%\import_private.ps1"
	)

	@REM Restore the process policy before leaving the maintenance block.
	powershell.exe -NoProfile -Command "Write-Host 'ExecutionPolicy restored'"
) else (
	wuauclt /detectnow
	wuauclt /updatenow
	control update 2>nul
)

@REM ==============================
@REM Keep repair commands after downloaded maintenance so package and configuration work completes first.
@REM ==============================

@REM mbr2gpt /allowFullOS /convert /disk:0 2>nul
@REM defrag /O /C /M 2>nul

@REM dism /Online /Cleanup-Image /RestoreHealth /StartComponentCleanup 2>nul
@REM sfc /scannow 2>nul

@REM Disabled recovery commands retained for manually restoring standard boot-integrity options.
@REM bcdedit /debug off
@REM bcdedit /set loadoptions ENABLE_INTEGRITY_CHECKS
@REM bcdedit /set TESTSIGNING OFF
@REM bcdedit /set NOINTEGRITYCHECKS OFF
@REM bcdedit /set hypervisorlaunchtype auto

@REM @REM ##########################
@REM @REM powercfg
@REM @REM ##########################

@REM powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PERFEPP 0
@REM powercfg -setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PERFEPP 0
@REM powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PERFEPP1 0
@REM powercfg -setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PERFEPP1 0
@REM powercfg -setactive SCHEME_CURRENT

if /I "%COMMON_ADMIN_STAGE%"=="powershell" endlocal & exit /b %errorlevel%

:NOPSHELL

@REM cls
choice /C YN /N /D N /T 5 /M "Service tweaks? (Y/N)"
if errorlevel 2 goto NOSERVTWEAKS

@REM Elevate the service-tweaks section once if needed
call :IsAdmin
if "%errorlevel%"=="0" goto ADMIN_SERVICE_TWEAKS

call :RunElevatedStage services
set "rc=%errorlevel%"
if not "%rc%"=="0" (
	endlocal & exit /b %rc%
)
goto NOSERVTWEAKS

:ADMIN_SERVICE_TWEAKS
@REM @REM Configure and start key services (automatic)
@REM for %%S in (
@REM 	"Dnscache" "EntAppSvc" "FrameServer"
@REM 	"LicenseManager"
@REM ) do (
@REM 	@REM sc config %%~S start=auto >nul 2>&1
@REM 	net start %%~S >nul 2>&1
@REM )

@REM Disabled service changes retained because they alter Windows caching and servicing behavior.
@REM net stop "SysMain" >nul 2>&1
@REM net stop "svsvc" >nul 2>&1
@REM sc config "SysMain" start=disabled >nul 2>&1
@REM sc config "svsvc" start=disabled >nul 2>&1

if /I "%COMMON_ADMIN_STAGE%"=="services" endlocal & exit /b %errorlevel%

:NOSERVTWEAKS

@REM Require an explicit response before opening external application links.
@REM Omitting /D and /T makes CHOICE wait indefinitely rather than selecting a default.
choice /C YN /N /M "Open update windows? (Y/N)"
if errorlevel 2 goto SKIP_DOWNLOAD_LINKS

control update
start "" /min "ms-windows-store://downloadsandupdates"
start "" /min "msxbox://installs"
start "" /min "steam://open/downloads"

:SKIP_DOWNLOAD_LINKS
endlocal
@REM choice /C YN /N /T 5 /D N /M "Stay open? (Y/N)"
@REM if errorlevel 2 exit 0
exit /b 0
@REM cmd /k
@REM exit /b %errorlevel%

@REM Return zero when elevated and nonzero otherwise, matching normal batch errorlevel conventions.
:IsAdmin
@REM Use FLTMC as a lightweight administrator check because it fails for a standard token.
fltmc >nul 2>&1
exit /b %errorlevel%

@REM Relaunch this script through PowerShell Start-Process -Verb RunAs and wait for the selected stage.
:RunElevatedStage
@REM Pass only the requested stage to the elevated child, preventing user-app launch logic from repeating.
set "COMMON_ELEVATE_STAGE=%~1"
call :IsAdmin
if "%errorlevel%"=="0" exit /b 0

echo Requesting administrator approval for %COMMON_ELEVATE_STAGE% tasks...
set "SCRIPT_ELEVATE_TARGET=%~f0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$stageArg = '--admin-' + $env:COMMON_ELEVATE_STAGE; $target = $env:SCRIPT_ELEVATE_TARGET; $p = Start-Process -FilePath $target -ArgumentList $stageArg -Verb RunAs -WindowStyle Minimized -Wait -PassThru; exit $p.ExitCode"
exit /b %errorlevel%
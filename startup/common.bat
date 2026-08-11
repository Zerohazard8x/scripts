@echo off
@REM if /I not "%SCRIPT_LOWPRIO%"=="1" (
@REM 	set "SCRIPT_LOWPRIO=1"
@REM 	start "" /b /wait /low /min cmd /c ""%~f0" %*"
@REM 	exit %errorlevel%
@REM )
setlocal EnableExtensions EnableDelayedExpansion
call :Status "launching startup applications"
if not defined downloadDir set "downloadDir=%USERPROFILE%\Downloads"
if not exist "%downloadDir%" mkdir "%downloadDir%"

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
call :Status "downloading maintenance scripts"
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
	@REM Enter the script directory before staging work.
	cd /d "%~dp0"

	@REM Set a process-scoped bypass only; this avoids changing the machine or user execution policy.
	powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
	"Write-Host 'ExecutionPolicy set to Bypass'"

	@REM Delete the old staged task script so the subsequent existence check refers to the fresh download.
	if exist "%downloadDir%\tasks.ps1" del /q /f "%downloadDir%\tasks.ps1" 2>nul
	if exist "%downloadDir%\import.ps1" del /q /f "%downloadDir%\import.ps1" 2>nul

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
		curl -L -o "%downloadDir%\import.ps1" "https://codeberg.org/Zerohazard8x/scripts/raw/branch/main/wifi/import.ps1"
	)

	@REM Execute tasks.ps1 only after a successful download left a file at the expected path.
	if exist "%downloadDir%\tasks.ps1" (
		call :Status "PowerShell maintenance"
		powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%downloadDir%\tasks.ps1"
		if errorlevel 1 pause
	) else echo Skipping PowerShell maintenance: tasks.ps1 was not downloaded.

	@REM Run the optional public import after the main tasks so it can layer additional settings.
	if exist "%downloadDir%\import.ps1" (
		call :Status "WiFi import"
		powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%downloadDir%\import.ps1"
	) else echo Skipping public WiFi import: import.ps1 was not downloaded.

	@REM Run the locally staged private import last so private overrides take precedence.
	if exist "%downloadDir%\import_private.ps1" (
		call :Status "private WiFi import"
		powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%downloadDir%\import_private.ps1"
	) else echo Skipping private WiFi import: import_private.ps1 was not found.

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
call :Status "service tweaks prompt"

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
call :Status "service tweaks"
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
call :Status "update windows prompt"

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

:Status
title Now running: %~1
echo.
echo === Now running: %~1 ===
exit /b 0

@REM Relaunch this script through PowerShell Start-Process -Verb RunAs and wait for the selected stage.
:RunElevatedStage
@REM Pass only the requested stage to the elevated child, preventing user-app launch logic from repeating.
set "COMMON_ELEVATE_STAGE=%~1"
call :IsAdmin
if "%errorlevel%"=="0" exit /b 0

echo Requesting administrator approval for %COMMON_ELEVATE_STAGE% tasks...
echo The elevated tasks will open in another window; this window will wait for them to finish.
call :Status "waiting for elevated %COMMON_ELEVATE_STAGE% tasks"
set "SCRIPT_ELEVATE_TARGET=%~f0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$stageArg = '--admin-' + $env:COMMON_ELEVATE_STAGE; $target = $env:SCRIPT_ELEVATE_TARGET; $cmdLine = 'call ' + [char]34 + $target + [char]34 + ' ' + $stageArg; try { $p = Start-Process -FilePath $env:ComSpec -ArgumentList @('/d', '/c', $cmdLine) -Verb RunAs -WindowStyle Normal -PassThru -ErrorAction Stop; $p.WaitForExit(); exit $p.ExitCode } catch { Write-Host $_.Exception.Message; exit 1 }"
exit /b %errorlevel%

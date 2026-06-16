@echo off
if /I not "%SCRIPT_LOWPRIO%"=="1" (
	set "SCRIPT_LOWPRIO=1"
	start "" /b /wait /low /min cmd /c ""%~f0" %*"
	exit %errorlevel%
)
setlocal EnableExtensions EnableDelayedExpansion

@REM Elevated stage entry points
set "COMMON_ADMIN_STAGE="
if /I "%~1"=="--admin-powershell" set "COMMON_ADMIN_STAGE=powershell"
if /I "%~1"=="--admin-services" set "COMMON_ADMIN_STAGE=services"
if /I "%COMMON_ADMIN_STAGE%"=="powershell" goto ADMIN_POWERSHELL_REPAIR
if /I "%COMMON_ADMIN_STAGE%"=="services" goto ADMIN_SERVICE_TWEAKS

@REM version string
@REM minescule mouse

@REM Launch background tray/game/cloud applications if installed

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
@REM         start "" "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Riot Games\Riot Client.lnk"
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

@REM Detect preferred Voicemeeter executable
set "vm_path="
set "vm_exe="

@REM pick executable (priority order)
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

@REM Launch Voicemeeter if found and not already running
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

@REM Prompt: Powershell n Repair? (Y/N) [default Y after 15s]
@REM cls
choice /C YN /N /D Y /T 15 /M "Powershell n Repair? (Y/N)"
if errorlevel 2 goto NOPSHELL

@REM Elevate the PowerShell and repair section once if needed
call :IsAdmin
if "%errorlevel%"=="0" goto ADMIN_POWERSHELL_REPAIR

call :RunElevatedStage powershell
set "rc=%errorlevel%"
if not "%rc%"=="0" (
	endlocal & exit /b %rc%
)
goto NOPSHELL

:ADMIN_POWERSHELL_REPAIR
@REM dns config part 1
@REM Enable DoH
netsh dns add global doh=yes ddr=yes

netsh dns add encryption server=1.1.1.2 dohtemplate=https://security.cloudflare-dns.com/dns-query autoupgrade=yes udpfallback=no
netsh dns add encryption server=1.0.0.2 dohtemplate=https://security.cloudflare-dns.com/dns-query autoupgrade=yes udpfallback=no
netsh dns add encryption server=2606:4700:4700::1112 dohtemplate=https://security.cloudflare-dns.com/dns-query autoupgrade=yes udpfallback=no
netsh dns add encryption server=2606:4700:4700::1002 dohtemplate=https://security.cloudflare-dns.com/dns-query autoupgrade=yes udpfallback=no

@REM Check for PowerShell
where powershell >nul 2>&1
if not errorlevel 1 (
	@REM Save current folder
	set "scriptPath=%~dp0"
	cd /d "%scriptPath%"
	set "downloadDir=%USERPROFILE%\Downloads"
	if not exist "%downloadDir%" mkdir "%downloadDir%"

	@REM Bypass policy
	powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
	"Write-Host 'ExecutionPolicy set to Bypass'"

	@REM Remove old tasks.ps1
	if exist "%downloadDir%\tasks.ps1" del /s /q /f "%downloadDir%\tasks.ps1" 2>nul
	if exist "%downloadDir%\import.ps1" del /s /q /f "%downloadDir%\import.ps1" 2>nul

	@REM Download latest tasks.ps1
	where curl >nul 2>&1
	if not errorlevel 1 (
		curl -L -o "%downloadDir%\tasks.ps1" "https://raw.githubusercontent.com/Zerohazard8x/scripts/main/tasks.ps1"
	) 
	@REM else if exist "%ProgramFiles%\Unix\wget.exe" (
	@REM 	"%ProgramFiles%\Unix\wget.exe" -O tasks.ps1 "https://raw.githubusercontent.com/Zerohazard8x/scripts/main/tasks.ps1"
	@REM )

	@REM Download latest import.ps1
	where curl >nul 2>&1
	if not errorlevel 1 (
		curl -L -o "%downloadDir%\import.ps1" "https://raw.githubusercontent.com/Zerohazard8x/wifi/main/import.ps1"
	) 
	@REM else if exist "%ProgramFiles%\Unix\wget.exe" (
	@REM 	"%ProgramFiles%\Unix\wget.exe" -O import.ps1 "https://raw.githubusercontent.com/Zerohazard8x/wifi/main/import.ps1"
	@REM )

	@REM Run tasks.ps1 if present
	if exist "%downloadDir%\tasks.ps1" (
		powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%downloadDir%\tasks.ps1"
	)

	@REM Run import.ps1 if present
	if exist "%downloadDir%\import.ps1" (
		powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%downloadDir%\import.ps1"
	)

	@REM Check for private script
	if exist "%downloadDir%\import_private.ps1" (
		powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%downloadDir%\import_private.ps1"
	)

	@REM Restore default execution policy
	powershell.exe -NoProfile -Command "Write-Host 'ExecutionPolicy restored'"
) else (
	wuauclt /detectnow
	wuauclt /updatenow
	control update 2>nul
)

@REM repairs
@REM mbr2gpt /allowFullOS /convert /disk:0 2>nul
@REM defrag /O /C /M 2>nul

@REM dism /Online /Cleanup-Image /RestoreHealth /StartComponentCleanup 2>nul
@REM sfc /scannow 2>nul

@REM Restore boot configuration integrity settings
bcdedit /debug off
bcdedit /set loadoptions ENABLE_INTEGRITY_CHECKS
bcdedit /set TESTSIGNING OFF
bcdedit /set NOINTEGRITYCHECKS OFF
bcdedit /set hypervisorlaunchtype auto

if /I "%COMMON_ADMIN_STAGE%"=="powershell" endlocal & exit /b %errorlevel%

:NOPSHELL

@REM cls
choice /C YN /N /D N /T 15 /M "Service tweaks? (Y/N)"
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
@REM Configure and start key services (automatic)
for %%S in (
	"Dnscache" "EntAppSvc" "FrameServer"
	"LicenseManager"
) do (
	@REM sc config %%~S start=auto >nul 2>&1
	net start %%~S >nul 2>&1
)

@REM Disable and stop SysMain & svsvc
@REM net stop "SysMain" >nul 2>&1
@REM net stop "svsvc" >nul 2>&1
@REM sc config "SysMain" start=disabled >nul 2>&1
@REM sc config "svsvc" start=disabled >nul 2>&1

if /I "%COMMON_ADMIN_STAGE%"=="services" endlocal & exit /b %errorlevel%

:NOSERVTWEAKS

@REM Open update/download pages for Windows, Microsoft Store, Xbox, and Steam
control update
start "" /min "ms-windows-store://downloadsandupdates"
start "" /min "msxbox://installs"
start "" /min "steam://open/downloads"

endlocal
@REM choice /C YN /N /T 15 /D N /M "Stay open? (Y/N)"
@REM if errorlevel 2 exit 0
exit 0
@REM cmd /k
@REM exit /b %errorlevel%

:IsAdmin
@REM fltmc succeeds only from an elevated command prompt
fltmc >nul 2>&1
exit /b %errorlevel%

:RunElevatedStage
@REM Relaunch this batch file for one selected elevated stage
set "COMMON_ELEVATE_STAGE=%~1"
call :IsAdmin
if "%errorlevel%"=="0" exit /b 0

echo Requesting administrator approval for %COMMON_ELEVATE_STAGE% tasks...
set "SCRIPT_ELEVATE_TARGET=%~f0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$stageArg = '--admin-' + $env:COMMON_ELEVATE_STAGE; $target = $env:SCRIPT_ELEVATE_TARGET; $p = Start-Process -FilePath $env:ComSpec -ArgumentList @('/d', '/s', '/c', [char]34 + $target + [char]34 + ' ' + $stageArg) -Verb RunAs -WindowStyle Minimized -Wait -PassThru; exit $p.ExitCode"
exit /b %errorlevel%

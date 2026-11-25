@echo off
@REM if /I not "%SCRIPT_LOWPRIO%"=="1" (
@REM 	set "SCRIPT_LOWPRIO=1"
@REM 	start "" /b /wait /low /min cmd /c ""%~f0" %*"
@REM 	exit %errorlevel%
@REM )
setlocal EnableExtensions EnableDelayedExpansion
if /I "%~1"=="--wait-for-idle" (
    call :WaitForIdle "%~2"
    exit /b !errorlevel!
)
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
@REM CHOICE can return 255 when Task Scheduler supplies no console input; treat that as the documented default.
if errorlevel 2 if not errorlevel 3 goto NOPSHELL

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
call :WaitForIdle
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
		if errorlevel 1 echo PowerShell maintenance reported an error; continuing unattended startup.
		) else (
		echo Skipping PowerShell maintenance: tasks.ps1 was not downloaded.
	)
	
	@REM Run the optional public import after the main tasks so it can layer additional settings.
	choice /C YN /N /D N /T 5 /M "Run public WiFi import? (Y/N)"
	if errorlevel 2 (
		echo Skipping public WiFi import.
		) else (
		if exist "%downloadDir%\import.ps1" (
			call :Status "WiFi import"
			call :WaitForIdle
			powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%downloadDir%\import.ps1"
			) else (
			echo Skipping public WiFi import: import.ps1 was not downloaded.
		)
	)
	
	@REM Run the locally staged private import last so private overrides take precedence.
	choice /C YN /N /D N /T 5 /M "Run private WiFi import? (Y/N)"
	if errorlevel 2 (
		echo Skipping private WiFi import.
		) else (
		if exist "%downloadDir%\import_private.ps1" (
			call :Status "private WiFi import"
			call :WaitForIdle
			powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%downloadDir%\import_private.ps1"
			) else (
			echo Skipping private WiFi import: import_private.ps1 was not found.
		)
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

if /I "%COMMON_ADMIN_STAGE%"=="powershell" (endlocal & exit /b %errorlevel%)

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
call :WaitForIdle
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

if /I "%COMMON_ADMIN_STAGE%"=="services" (endlocal & exit /b %errorlevel%)

:NOSERVTWEAKS
call :Status "update windows prompt"

@REM Require an explicit response for this final prompt; it intentionally has no timeout or default.
choice /C YN /N /M "Open update windows? (Y/N)"
if errorlevel 2 goto SKIP_DOWNLOAD_LINKS

call :WaitForIdle

@REM Route protocol URIs through the interactive Explorer shell so scheduled or elevated callers can activate user apps.
start "" control.exe /name Microsoft.WindowsUpdate
start "" "%SystemRoot%\explorer.exe" "ms-windows-store://downloadsandupdates"
start "" "%SystemRoot%\explorer.exe" "msxbox://installs"
start "" "%SystemRoot%\explorer.exe" "steam://open/downloads"

:SKIP_DOWNLOAD_LINKS
endlocal
@REM choice /C YN /N /T 5 /D N /M "Stay open? (Y/N)"
@REM if errorlevel 2 exit 0
exit /b 0
@REM cmd /k
@REM exit /b %errorlevel%

@REM Check CPU, average physical-disk queue length, and average disk transfer time in the same sampling loop.
@REM Raw disk samples preserve fractional queue length and subsecond transfer times.
:WaitForIdle
setlocal EnableExtensions
if not defined SCRIPT_STARTUP_IDLE_MAX_SECONDS set "SCRIPT_STARTUP_IDLE_MAX_SECONDS=%SCRIPT_STARTUP_DISK_WAIT_MAX_SECONDS%"
if not defined SCRIPT_STARTUP_IDLE_MAX_SECONDS set "SCRIPT_STARTUP_IDLE_MAX_SECONDS=600"
if "%SCRIPT_STARTUP_IDLE_MAX_SECONDS%"=="0" (endlocal & exit /b 0)
if not defined SCRIPT_STARTUP_IDLE_CPU_PERCENT set "SCRIPT_STARTUP_IDLE_CPU_PERCENT=25"
if not defined SCRIPT_STARTUP_IDLE_DISK_QUEUE_MAX set "SCRIPT_STARTUP_IDLE_DISK_QUEUE_MAX=1"
if not defined SCRIPT_STARTUP_DISK_RESPONSE_MAX_MS set "SCRIPT_STARTUP_DISK_RESPONSE_MAX_MS=20"
if not defined SCRIPT_STARTUP_IDLE_STABLE_SAMPLES set "SCRIPT_STARTUP_IDLE_STABLE_SAMPLES=2"
if not defined SCRIPT_STARTUP_IDLE_SAMPLE_SECONDS set "SCRIPT_STARTUP_IDLE_SAMPLE_SECONDS=2"

@REM Only the launch wait reads N, so task waits do not consume input for the next prompt.
set "SCRIPT_STARTUP_IDLE_ALLOW_CANCEL="
if /I "%~1"=="--allow-cancel" set "SCRIPT_STARTUP_IDLE_ALLOW_CANCEL=1"

where powershell.exe >nul 2>&1
if errorlevel 1 (
    echo PowerShell is unavailable. CPU and disk sampling are unavailable.
    if defined SCRIPT_STARTUP_IDLE_ALLOW_CANCEL (
        choice /C NY /N /T %SCRIPT_STARTUP_IDLE_MAX_SECONDS% /D Y /M "Startup tasks will wait. Press N to stop, or wait to continue."
        if not errorlevel 2 (endlocal & exit /b 2)
    )
    endlocal & exit /b 0
)

powershell.exe -NoProfile -Command ^
    "$maxMs = [Math]::Max(0, [int]$env:SCRIPT_STARTUP_IDLE_MAX_SECONDS) * 1000L;" ^
    "if ($maxMs -eq 0) { exit 0 };" ^
    "$cpuMax = [Math]::Max(1, [int]$env:SCRIPT_STARTUP_IDLE_CPU_PERCENT);" ^
    "$queueMax = [Math]::Max(0, [double]$env:SCRIPT_STARTUP_IDLE_DISK_QUEUE_MAX);" ^
    "$responseMax = [Math]::Max(0, [double]$env:SCRIPT_STARTUP_DISK_RESPONSE_MAX_MS);" ^
    "$needed = [Math]::Max(1, [int]$env:SCRIPT_STARTUP_IDLE_STABLE_SAMPLES);" ^
    "$sampleMs = [Math]::Max(1, [int]$env:SCRIPT_STARTUP_IDLE_SAMPLE_SECONDS) * 1000L;" ^
    "$allowCancel = $env:SCRIPT_STARTUP_IDLE_ALLOW_CANCEL -eq '1';" ^
    "$cancel = { if ($allowCancel) { try { if ($Host.UI.RawUI.KeyAvailable) { return $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown').Character -eq 'n' } } catch {} }; return $false };" ^
    "$activity = 'Waiting for CPU and disk idle';" ^
    "if ($allowCancel) { $activity += '. Press N to stop startup' };" ^
    "Write-Host ($activity + '...');" ^
    "$timer = [Diagnostics.Stopwatch]::StartNew(); $previous = $null; $stable = 0; $diskAvailable = $true;" ^
    "while ($timer.ElapsedMilliseconds -lt $maxMs) {" ^
    "    if (& $cancel) { exit 2 };" ^
    "    $cpu = $null;" ^
    "    try { $cpu = (Get-CimInstance Win32_Processor -OperationTimeoutSec 3 -ErrorAction Stop | Measure-Object -Property LoadPercentage -Average).Average } catch {};" ^
    "    $cpuStatus = 'CPU unavailable';" ^
    "    if ($null -ne $cpu) { $cpuStatus = 'CPU {0:N0}/{1} percent' -f $cpu,$cpuMax };" ^
    "    $diskOk = -not $diskAvailable; $diskStatus = 'disk counters unavailable';" ^
    "    if ($diskAvailable) {" ^
    "        try {" ^
    "            $disk = Get-CimInstance Win32_PerfRawData_PerfDisk_PhysicalDisk -OperationTimeoutSec 3 -ErrorAction Stop | Where-Object Name -eq '_Total';" ^
    "            if ($null -eq $disk -or $disk.Frequency_PerfTime -le 0) { throw 'Missing physical disk counters' };" ^
    "        } catch {" ^
    "            $diskAvailable = $false; $diskOk = $true;" ^
    "            Write-Warning 'Disk counters are unavailable. Checking CPU only.';" ^
    "        };" ^
    "    };" ^
    "    if ($diskAvailable) {" ^
    "        $diskStatus = 'collecting disk samples';" ^
    "        if ($null -ne $previous) {" ^
    "            $elapsed = [decimal]$disk.Timestamp_Sys100NS - [decimal]$previous.Timestamp_Sys100NS;" ^
    "            $queueTicks = [decimal]$disk.AvgDiskQueueLength - [decimal]$previous.AvgDiskQueueLength;" ^
    "            $transferTicks = [decimal]$disk.AvgDiskSecPerTransfer - [decimal]$previous.AvgDiskSecPerTransfer;" ^
    "            $transfers = [long]$disk.AvgDiskSecPerTransfer_Base - [long]$previous.AvgDiskSecPerTransfer_Base;" ^
    "            if ($elapsed -gt 0 -and $queueTicks -ge 0 -and $transferTicks -ge 0 -and $transfers -ge 0) {" ^
    "                $queue = $queueTicks / $elapsed; $responseMs = 0;" ^
    "                if ($transfers -gt 0) { $responseMs = 1000 * $transferTicks / [decimal]$disk.Frequency_PerfTime / $transfers };" ^
    "                $diskOk = $queue -le $queueMax -and $responseMs -le $responseMax;" ^
    "                $diskStatus = 'disk queue {0:N2}/{1:N2}, response {2:N1}/{3:N1} ms' -f $queue,$queueMax,$responseMs,$responseMax;" ^
    "            };" ^
    "        };" ^
    "        $previous = $disk;" ^
    "    };" ^
    "    if (& $cancel) { exit 2 };" ^
    "    if ($null -ne $cpu -and $cpu -le $cpuMax -and $diskOk) { $stable++ } else { $stable = 0 };" ^
    "    if ($stable -ge $needed) { exit 0 };" ^
    "    Write-Progress -Activity $activity -Status ('{0}, {1}, idle samples {2}/{3}' -f $cpuStatus,$diskStatus,$stable,$needed);" ^
    "    $next = [Math]::Min($maxMs, $timer.ElapsedMilliseconds + $sampleMs);" ^
    "    while (($remaining = $next - $timer.ElapsedMilliseconds) -gt 0) {" ^
    "        if (& $cancel) { exit 2 };" ^
    "        $delay = [Math]::Min([long][int]::MaxValue, $remaining);" ^
    "        if ($allowCancel) { $delay = [Math]::Min(100L, $delay) };" ^
    "        Start-Sleep -Milliseconds ([int]$delay);" ^
    "    };" ^
    "};" ^
    "Write-Warning 'Timed out waiting for CPU and disk idle. Continuing startup.'"
if "%errorlevel%"=="2" (endlocal & exit /b 2)
if errorlevel 1 echo Idle sampling failed. Continuing startup.
endlocal & exit /b 0

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
@REM WaitForExit tracks only the elevated cmd process; Start-Process -Wait also tracks long-lived GUI descendants.
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$stageArg = '--admin-' + $env:COMMON_ELEVATE_STAGE; $target = $env:SCRIPT_ELEVATE_TARGET; $cmdLine = 'call ' + [char]34 + $target + [char]34 + ' ' + $stageArg; $p = Start-Process -FilePath $env:ComSpec -ArgumentList @('/d', '/c', $cmdLine) -Verb RunAs -WindowStyle Normal -PassThru; $p.WaitForExit(); exit $p.ExitCode"
exit /b %errorlevel%

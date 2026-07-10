@echo off
@REM Relaunch this script at low priority
@REM if /I not "%SCRIPT_LOWPRIO%"=="1" (
@REM     set "SCRIPT_LOWPRIO=1"
@REM     start "" /b /wait /low /min cmd /c ""%~f0" %*"
@REM     exit %errorlevel%
@REM )
setlocal EnableExtensions

@REM Configure idle wait before starting network/download work
if not defined SCRIPT_STARTUP_IDLE_MAX_SECONDS set "SCRIPT_STARTUP_IDLE_MAX_SECONDS=600"
if not defined SCRIPT_STARTUP_IDLE_CPU_PERCENT set "SCRIPT_STARTUP_IDLE_CPU_PERCENT=25"
if not defined SCRIPT_STARTUP_IDLE_STABLE_SAMPLES set "SCRIPT_STARTUP_IDLE_STABLE_SAMPLES=3"
if not defined SCRIPT_STARTUP_IDLE_SAMPLE_SECONDS set "SCRIPT_STARTUP_IDLE_SAMPLE_SECONDS=10"

@REM Wait only once, then continue when idle or when the max wait expires
if /I not "%SCRIPT_STARTUP_IDLE_DONE%"=="1" (
    set "SCRIPT_STARTUP_IDLE_DONE=1"
    echo Startup tasks will wait for idle. Press N to stop, or wait to continue.
    choice /c YN /t 5 /d Y /m "Continue"
    if errorlevel 2 endlocal & exit /b 0
    call :WaitForStartupIdle
)

@REM Use Downloads as the temporary staging folder
set "downloadDir=%USERPROFILE%\Downloads"
if not exist "%downloadDir%" mkdir "%downloadDir%"

@REM set "github=https://raw.githubusercontent.com/Zerohazard8x/scripts/main/startup"
set "github=https://codeberg.org/Zerohazard8x/scripts/raw/branch/main/startup"

@REM Remove stale downloaded startup scripts before fetching fresh copies
del /s /q /f "%downloadDir%\common.bat"
del /s /q /f "%downloadDir%\startup_tasks_lite.bat"

@REM Stage optional private import script for common.bat
if exist "import_private.ps1" (
    copy .\import_private.ps1 "%downloadDir%\import_private.ps1"
)

@REM Download common.bat, preferring curl then wget then aria2c
call :Download common.bat

@REM Verify common.bat marker text before downloading startup_tasks_lite.bat
if exist "%downloadDir%\common.bat" (
    findstr /C:"minescule" /C:"mouse" "%downloadDir%\common.bat" >nul 2>&1
    if not errorlevel 1 (
        @REM Download startup_tasks_lite.bat with the same tool fallback order
        call :Download startup_tasks_lite.bat
        
        ```
        @REM Verify startup_tasks.bat marker text before running it
        findstr /C:"minescule" /C:"mouse" "%downloadDir%\startup_tasks_lite.bat" >nul 2>&1
        if not errorlevel 1 (
            call "%downloadDir%\startup_tasks_lite.bat"
            set "rc=%errorlevel%"
            goto :cleanup
        )
    )
    ```
    
)

@REM Treat missing or unverified downloads as failure
set "rc=1"

:cleanup
@REM Remove temporary downloaded scripts after the chain finishes
del /s /q /f "%downloadDir%\common.bat" 2>nul
del /s /q /f "%downloadDir%\startup_tasks_lite.bat" 2>nul
del /s /q /f "%downloadDir%\tasks.ps1" 2>nul
del /s /q /f "%downloadDir%\import.ps1" 2>nul
del /s /q /f "%downloadDir%\import_private.ps1" 2>nul
endlocal & exit /b %rc%

:Download
where curl >nul 2>&1
if not errorlevel 1 (
    curl -f --remote-time -C - -L --output-dir "%downloadDir%" -O "%github%/%~1"
    ) else (
    where wget >nul 2>&1
    if not errorlevel 1 (
        wget -c --timestamping -O "%downloadDir%%~1" "%github%/%~1"
        ) else (
        where aria2c >nul 2>&1
        if not errorlevel 1 (
            aria2c -R --allow-overwrite=true -d "%downloadDir%" -o "%~1" "%github%/%~1"
        )
    )
)
exit /b

:WaitForStartupIdle
@REM Wait for low CPU samples; disable by setting max seconds to 0
if "%SCRIPT_STARTUP_IDLE_MAX_SECONDS%"=="0" exit /b 0

@REM Fall back to a bounded timer if PowerShell is unavailable
where powershell >nul 2>&1
if errorlevel 1 (
    timeout /t %SCRIPT_STARTUP_IDLE_MAX_SECONDS% /nobreak >nul
    exit /b 0
)

@REM Sample CPU load until the system is idle enough or the max wait expires
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$max=[Math]::Max(0,[int]$env:SCRIPT_STARTUP_IDLE_MAX_SECONDS); $threshold=[Math]::Max(1,[int]$env:SCRIPT_STARTUP_IDLE_CPU_PERCENT); $needed=[Math]::Max(1,[int]$env:SCRIPT_STARTUP_IDLE_STABLE_SAMPLES); $sleep=[Math]::Max(1,[int]$env:SCRIPT_STARTUP_IDLE_SAMPLE_SECONDS); $deadline=(Get-Date).AddSeconds($max); $stable=0; while((Get-Date) -lt $deadline) { try { $values=@(Get-CimInstance Win32_Processor | ForEach-Object { $_.LoadPercentage }); if ($values.Count -gt 0) { $cpu=($values | Measure-Object -Average).Average } else { $cpu=100 } } catch { $cpu=100 }; if ($cpu -le $threshold) { $stable++ } else { $stable=0 }; if ($stable -ge $needed) { exit 0 }; Start-Sleep -Seconds $sleep }; exit 0"
exit /b 0
@echo off
@REM Disabled low-priority self-relaunch; keeping it here documents the intended wrapper without opening another console.
@REM if /I not "%SCRIPT_LOWPRIO%"=="1" (
@REM     set "SCRIPT_LOWPRIO=1"
@REM     start "" /b /wait /low /min cmd /c ""%~f0" %*"
@REM     exit %errorlevel%
@REM )
setlocal EnableExtensions

@REM Set overridable idle-detection defaults before any network or download work begins.
if not defined SCRIPT_STARTUP_IDLE_MAX_SECONDS set "SCRIPT_STARTUP_IDLE_MAX_SECONDS=600"
if not defined SCRIPT_STARTUP_IDLE_CPU_PERCENT set "SCRIPT_STARTUP_IDLE_CPU_PERCENT=25"
if not defined SCRIPT_STARTUP_IDLE_STABLE_SAMPLES set "SCRIPT_STARTUP_IDLE_STABLE_SAMPLES=3"
if not defined SCRIPT_STARTUP_IDLE_SAMPLE_SECONDS set "SCRIPT_STARTUP_IDLE_SAMPLE_SECONDS=10"

@REM Gate startup once per inherited environment; the flag prevents a relaunch or nested call from waiting twice.
if /I not "%SCRIPT_STARTUP_IDLE_DONE%"=="1" (
    set "SCRIPT_STARTUP_IDLE_DONE=1"
    echo Startup tasks will wait for idle. Press N to stop, or wait to continue.
    choice /c YN /t 5 /d Y /m "Continue"
    if errorlevel 2 endlocal & exit /b 0
    call :WaitForStartupIdle
)

@REM Use the user Downloads directory as a writable staging area shared by each script in the chain.
set "downloadDir=%USERPROFILE%\Downloads"
if not exist "%downloadDir%" mkdir "%downloadDir%"

@REM set "github=https://raw.githubusercontent.com/Zerohazard8x/scripts/main/startup"
set "github=https://codeberg.org/Zerohazard8x/scripts/raw/branch/main/startup"

@REM Delete stale staged copies so marker validation applies only to the newly downloaded files.
del /s /q /f "%downloadDir%\common.bat"
del /s /q /f "%downloadDir%\startup_tasks_lite.bat"

@REM Copy the optional private import beside the downloaded scripts because common.bat resolves it from the staging directory.
if exist "import_private.ps1" (
    copy .\import_private.ps1 "%downloadDir%\import_private.ps1"
)

@REM Fetch common.bat first because startup_tasks_lite.bat calls it later; :Download selects the first available downloader.
call :Download common.bat

@REM Require both marker strings before continuing, which rejects missing, empty, or unrelated downloads.
if exist "%downloadDir%\common.bat" (
    findstr /C:"minescule" /C:"mouse" "%downloadDir%\common.bat" >nul 2>&1
    if not errorlevel 1 (
        @REM Fetch the next script only after common.bat passes validation.
        call :Download startup_tasks_lite.bat
        
        @REM Validate the second staged script before CALL transfers control while retaining this batch context.
        findstr /C:"minescule" /C:"mouse" "%downloadDir%\startup_tasks_lite.bat" >nul 2>&1
        if not errorlevel 1 (
            call "%downloadDir%\startup_tasks_lite.bat"
            set "rc=%errorlevel%"
            goto :cleanup
        )
    )
)

@REM Use a nonzero default result when either download or marker check failed.
set "rc=1"

@REM Centralize cleanup so every success and failure path removes staged scripts before returning.
:cleanup
@REM Remove every staged public or private script on both success and failure.
del /s /q /f "%downloadDir%\common.bat" 2>nul
del /s /q /f "%downloadDir%\startup_tasks_lite.bat" 2>nul
del /s /q /f "%downloadDir%\tasks.ps1" 2>nul
del /s /q /f "%downloadDir%\import.ps1" 2>nul
del /s /q /f "%downloadDir%\import_private.ps1" 2>nul
if not "%rc%"=="0" pause
endlocal & exit /b %rc%

@REM Download the named file using curl, wget, or aria2c in that order; %~1 removes any surrounding quotes.
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

@REM Keep idle-wait implementation in a subroutine so the main download flow remains linear.
:WaitForStartupIdle
@REM Return immediately when the configured maximum is zero; otherwise wait for sustained low CPU or the deadline.
if "%SCRIPT_STARTUP_IDLE_MAX_SECONDS%"=="0" exit /b 0

@REM Use TIMEOUT as a bounded fallback because CPU sampling below depends on PowerShell and CIM.
where powershell >nul 2>&1
if errorlevel 1 (
    timeout /t %SCRIPT_STARTUP_IDLE_MAX_SECONDS% /nobreak >nul
    exit /b 0
)

@REM Average all processor load samples and require consecutive below-threshold readings to avoid reacting to one transient dip.
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$max=[Math]::Max(0,[int]$env:SCRIPT_STARTUP_IDLE_MAX_SECONDS); $threshold=[Math]::Max(1,[int]$env:SCRIPT_STARTUP_IDLE_CPU_PERCENT); $needed=[Math]::Max(1,[int]$env:SCRIPT_STARTUP_IDLE_STABLE_SAMPLES); $sleep=[Math]::Max(1,[int]$env:SCRIPT_STARTUP_IDLE_SAMPLE_SECONDS); $deadline=(Get-Date).AddSeconds($max); $stable=0; while((Get-Date) -lt $deadline) { try { $values=@(Get-CimInstance Win32_Processor | ForEach-Object { $_.LoadPercentage }); if ($values.Count -gt 0) { $cpu=($values | Measure-Object -Average).Average } else { $cpu=100 } } catch { $cpu=100 }; if ($cpu -le $threshold) { $stable++ } else { $stable=0 }; if ($stable -ge $needed) { exit 0 }; Start-Sleep -Seconds $sleep }; exit 0"
exit /b 0
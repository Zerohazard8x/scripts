@echo off

@REM Process priority relaunch
@REM commented bc spawning cmd.exe here creates another console window
@REM if /I not "%SCRIPT_LOWPRIO%"=="1" (
@REM     set "SCRIPT_LOWPRIO=1"
@REM     start "" /b /wait /low /min cmd /s /c ""%~f0" %*"
@REM     exit /b %errorlevel%
@REM )

setlocal EnableExtensions
set "PIP_BREAK_SYSTEM_PACKAGES=1"

@REM Elevated stage entry points
set "STARTUP_ADMIN_STAGE="
if /I "%~1"=="--admin-python" set "STARTUP_ADMIN_STAGE=python"
if /I "%~1"=="--admin-programs" set "STARTUP_ADMIN_STAGE=programs"
if /I "%STARTUP_ADMIN_STAGE%"=="python" goto ADMIN_PYTHON_TASKS
if /I "%STARTUP_ADMIN_STAGE%"=="programs" goto ADMIN_PROGRAM_TASKS

set "downloadDir=%USERPROFILE%\Downloads"
if not exist "%downloadDir%" mkdir "%downloadDir%"

@REM version string
@REM minescule mouse

@REM Ping-abuse timeout - ~1 second
ping 127.0.0.1 -n 2 >nul

@REM @REM Clear screen
@REM cls

@REM Prompt: Python? (Y/N) [default Y after 5s]
choice /C YN /N /D Y /T 5 /M "Python? (Y/N)"
if errorlevel 2 goto NOPYTHON

@REM Elevate the full Python section once if needed
call :IsAdmin
if "%errorlevel%"=="0" goto ADMIN_PYTHON_TASKS

call :RunElevatedStage python
set "rc=%errorlevel%"
if not "%rc%"=="0" (
    endlocal & exit /b %rc%
)
goto NOPYTHON

:ADMIN_PYTHON_TASKS
@REM If Chocolatey exists, upgrade Python via choco
where choco >nul 2>&1 && (
    choco uninstall python2 python -y && choco upgrade python3 -y
)

@REM If python in PATH, purge cache and upgrade packages
where python >nul 2>&1 && (
    python -m pip install --upgrade pip
    python -m pip install setuptools pyreadline3 yt-dlp[default,curl-cffi] mutagen
    @REM Regenerate requirements and upgrade via PowerShell
    where powershell >nul 2>&1 && (
        call :UpgradeFrozenRequirements python
    )
)

if /I "%STARTUP_ADMIN_STAGE%"=="python" endlocal & exit /b %errorlevel%

:NOPYTHON

@REM @REM Clear screen
@REM cls

@REM Prompt: Install programs? (Y/N) [default Y after 5s]
choice /C YN /N /D Y /T 5 /M "Install programs? (Y/N)"
if errorlevel 2 goto NOPROGRAMS

@REM Elevate the full program-upgrade section once if needed
call :IsAdmin
if "%errorlevel%"=="0" goto ADMIN_PROGRAM_TASKS

call :RunElevatedStage programs
set "rc=%errorlevel%"
if not "%rc%"=="0" (
    endlocal & exit /b %rc%
)
goto NOPROGRAMS

:ADMIN_PROGRAM_TASKS
@REM Upgrade Chocolatey packages
where choco >nul 2>&1 && (
    choco upgrade chocolatey curl firefox ffmpeg git jq mpv nomacs peazip phantomjs vlc -y
    choco upgrade all -y
)

if /I "%STARTUP_ADMIN_STAGE%"=="programs" endlocal & exit /b %errorlevel%

:NOPROGRAMS

@REM Finally, run common.bat in the current console, wait, and capture its exit code.
if exist "%downloadDir%\common.bat" (
    @REM Process priority relaunch
    @REM kept commented bc START /WAIT with cmd.exe creates another console window
    @REM start "" /wait /low /min cmd /c "%downloadDir%\common.bat"

    call "%downloadDir%\common.bat"
    set "rc=%errorlevel%"
) else (
    echo *** ERROR: common.bat not found! ***
    set "rc=1"
)

@REM If common.bat failed, keep console open
if not "%rc%"=="0" (
    echo.
    echo common.bat exited with code %rc%. Writing to %~dp0startup_tasks.log and closing.
    >>"%~dp0startup_tasks.log" echo [%date% %time%] common.bat exited with code %rc%
    endlocal & exit /b %rc%
)

@REM @REM Success path: auto-close unless user presses Y within 5 seconds
@REM choice /C YN /N /T 5 /D N /M "Stay open? (Y/N)"
@REM if errorlevel 2 endlocal & exit /b 0
endlocal & exit /b 0
@REM cmd /k
@REM endlocal & exit /b %errorlevel%

:IsAdmin
@REM fltmc succeeds only from an elevated command prompt
fltmc >nul 2>&1
exit /b %errorlevel%

:RunElevatedStage
@REM Relaunch this batch file for one selected elevated stage
set "STARTUP_ELEVATE_STAGE=%~1"
call :IsAdmin
if "%errorlevel%"=="0" exit /b 0

echo Requesting administrator approval for %STARTUP_ELEVATE_STAGE% tasks...
set "STARTUP_ELEVATE_TARGET=%~f0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$stageArg = '--admin-' + $env:STARTUP_ELEVATE_STAGE; $target = $env:STARTUP_ELEVATE_TARGET; $p = Start-Process -FilePath $env:ComSpec -ArgumentList @('/d', '/s', '/c', [char]34 + $target + [char]34 + ' ' + $stageArg) -Verb RunAs -WindowStyle Minimized -Wait -PassThru; exit $p.ExitCode"
exit /b %errorlevel%

:UpgradeFrozenRequirements
set "SCRIPT_PYTHON_EXE=%~1"
set "SCRIPT_ID=%RANDOM%-%RANDOM%"
set "SCRIPT_PACKAGES_JSON=%TEMP%\packages-%SCRIPT_ID%.json"
set "SCRIPT_UPGRADE_FILE=%TEMP%\requirements-upgrade-%SCRIPT_ID%.txt"
set "SCRIPT_REPORT_FILE=%TEMP%\pip-upgrade-report-%SCRIPT_ID%.json"

@REM Build package>=current-version requirements from installed distributions.
@REM Exclude editables and bootstrap packaging tools from the bulk upgrade.
"%SCRIPT_PYTHON_EXE%" -m pip list --format=json --exclude-editable --exclude pip --exclude setuptools --exclude wheel --exclude distribute > "%SCRIPT_PACKAGES_JSON%"
if errorlevel 1 (
    set "SCRIPT_UPGRADE_RC=1"
    goto :UpgradeFrozenRequirementsCleanup
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
  "$j = Get-Content -Raw -LiteralPath $env:SCRIPT_PACKAGES_JSON | ConvertFrom-Json; " ^
  "$j | ForEach-Object { '{0}>={1}' -f $_.name, $_.version } | Set-Content -LiteralPath $env:SCRIPT_UPGRADE_FILE -Encoding ASCII"

if errorlevel 1 (
    set "SCRIPT_UPGRADE_RC=1"
    goto :UpgradeFrozenRequirementsCleanup
)

@REM First resolve without installing.
"%SCRIPT_PYTHON_EXE%" -m pip install --dry-run --upgrade --upgrade-strategy eager -r "%SCRIPT_UPGRADE_FILE%" --report "%SCRIPT_REPORT_FILE%"
if errorlevel 1 (
    set "SCRIPT_UPGRADE_RC=1"
    goto :UpgradeFrozenRequirementsCleanup
)

@REM Install the resolved-compatible upgrade set.
"%SCRIPT_PYTHON_EXE%" -m pip install --upgrade --upgrade-strategy eager -r "%SCRIPT_UPGRADE_FILE%"

@REM Final declared-dependency compatibility gate.
"%SCRIPT_PYTHON_EXE%" -m pip check
set "SCRIPT_UPGRADE_RC=%errorlevel%"
if "%SCRIPT_UPGRADE_RC%"=="0" (
    goto :UpgradeFrozenRequirementsCleanup
)

:UpgradeFrozenRequirementsCleanup
del /q /f "%SCRIPT_PACKAGES_JSON%" 2>nul
del /q /f "%SCRIPT_UPGRADE_FILE%" 2>nul
del /q /f "%SCRIPT_REPORT_FILE%" 2>nul

"%SCRIPT_PYTHON_EXE%" -m pip cache purge

exit /b %SCRIPT_UPGRADE_RC%
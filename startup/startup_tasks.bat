@echo off
if /I not "%SCRIPT_LOWPRIO%"=="1" (
    set "SCRIPT_LOWPRIO=1"
    start "" /b /wait /low /min cmd /s /c ""%~f0" %*"
    exit /b %errorlevel%
)
setlocal EnableExtensions

REM -------------------------------------------------------------------
REM Elevated stage entry points
REM -------------------------------------------------------------------
set "STARTUP_ADMIN_STAGE="
if /I "%~1"=="--admin-python" set "STARTUP_ADMIN_STAGE=python"
if /I "%~1"=="--admin-programs" set "STARTUP_ADMIN_STAGE=programs"
if /I "%STARTUP_ADMIN_STAGE%"=="python" goto ADMIN_PYTHON_TASKS
if /I "%STARTUP_ADMIN_STAGE%"=="programs" goto ADMIN_PROGRAM_TASKS

set "downloadDir=%USERPROFILE%\Downloads"
if not exist "%downloadDir%" mkdir "%downloadDir%"

REM -------------------------------------------------------------------
REM version string
REM minescule mouse
REM -------------------------------------------------------------------

REM Ping-abuse timeout - ~1 second
ping 127.0.0.1 -n 2 >nul

REM Clear screen
cls

REM -------------------------------------------------------------------
REM Prompt: Python? (Y/N) [default Y after 15s]
REM -------------------------------------------------------------------
choice /C YN /N /D Y /T 15 /M "Python? (Y/N)"
if errorlevel 2 goto NOPYTHON

REM -------------------------------------------------------------------
REM Elevate the full Python section once if needed
REM -------------------------------------------------------------------
call :IsAdmin
if "%errorlevel%"=="0" goto ADMIN_PYTHON_TASKS

call :RunElevatedStage python
set "rc=%errorlevel%"
if not "%rc%"=="0" (
    endlocal & exit /b %rc%
)
goto NOPYTHON

:ADMIN_PYTHON_TASKS
REM -------------------------------------------------------------------
REM If Chocolatey exists, upgrade Python via choco
REM -------------------------------------------------------------------
where choco >nul 2>&1 && (
    choco uninstall python2 python -y && choco upgrade python3 -y
)

REM -------------------------------------------------------------------
REM If python in PATH, purge cache and upgrade packages
REM -------------------------------------------------------------------
where python >nul 2>&1 && (
    python -m pip cache purge
    python -m pip install --upgrade pip setuptools pyreadline3 yt-dlp[default,curl-cffi] mutagen

    REM ---------------------------------------------------------------
    REM Ensure Python 3.12 exists, using uv when available
    REM ---------------------------------------------------------------
    where python3.12 >nul 2>&1
    if errorlevel 1 (
        where uv >nul 2>&1
        if errorlevel 1 (
            python -m pip install -U uv
        ) else (
            uv python install 3.12
            uv python update-shell
        )
    ) else (
        python3.12 -m pip install -U pip whisperx
    )

    REM Install VapourSynth plugins if vsrepo script found
    if exist "%ProgramFiles%\vapoursynth\vsrepo\vsrepo.py" (
        python "%ProgramFiles%\vapoursynth\vsrepo\vsrepo.py" install havsfunc mvsfunc vsrife lsmas
    )

    REM Regenerate requirements and upgrade via PowerShell
    where powershell >nul 2>&1 && (
        call :UpgradeFrozenRequirements python

        REM Also upgrade for Python 3.12 if present
        where python3.12 >nul 2>&1 && (
            call :UpgradeFrozenRequirements python3.12
        )
    )
)

if /I "%STARTUP_ADMIN_STAGE%"=="python" endlocal & exit /b %errorlevel%

:NOPYTHON

REM Clear screen
cls

REM -------------------------------------------------------------------
REM Prompt: Install programs? (Y/N) [default Y after 15s]
REM -------------------------------------------------------------------
choice /C YN /N /D Y /T 15 /M "Install programs? (Y/N)"
if errorlevel 2 goto NOPROGRAMS

REM -------------------------------------------------------------------
REM Elevate the full program-upgrade section once if needed
REM -------------------------------------------------------------------
call :IsAdmin
if "%errorlevel%"=="0" goto ADMIN_PROGRAM_TASKS

call :RunElevatedStage programs
set "rc=%errorlevel%"
if not "%rc%"=="0" (
    endlocal & exit /b %rc%
)
goto NOPROGRAMS

:ADMIN_PROGRAM_TASKS
REM -------------------------------------------------------------------
REM Upgrade Chocolatey packages
REM -------------------------------------------------------------------
where choco >nul 2>&1 && (
    choco upgrade chocolatey curl firefox ffmpeg git jq mpv nomacs peazip phantomjs vlc -y
    choco upgrade 7zip aria2 adb dos2unix nano scrcpy vscode thunderbird -y
)

REM where wsl >nul 2>&1 && (
REM     wsl --install --no-launch
REM     wsl --update
REM )

if /I "%STARTUP_ADMIN_STAGE%"=="programs" endlocal & exit /b %errorlevel%

:NOPROGRAMS

REM -------------------------------------------------------------------
REM Finally, run common.bat (in a new window), wait, and capture its exit code
REM -------------------------------------------------------------------
if exist "%downloadDir%\common.bat" (
    REM Use START /WAIT with cmd /c so we get the real ERRORLEVEL from the child .bat
    start "" /wait /low /min cmd /c "%downloadDir%\common.bat"
    set "rc=%errorlevel%"
) else (
    echo *** ERROR: common.bat not found! ***
    set "rc=1"
)

REM If common.bat failed, keep console open
if not "%rc%"=="0" (
    echo.
    echo common.bat exited with code %rc%. Writing to %~dp0startup_tasks.log and closing.
    >>"%~dp0startup_tasks.log" echo [%date% %time%] common.bat exited with code %rc%
    endlocal & exit /b %rc%
)

REM =========================================================
REM Success path: auto-close unless user presses Y within 15 seconds
choice /C YN /N /T 15 /D N /M "Stay open? (Y/N)"
if errorlevel 2 endlocal & exit /b 0
cmd /k
endlocal & exit /b %errorlevel%
REM =========================================================

:IsAdmin
REM -------------------------------------------------------------------
REM fltmc succeeds only from an elevated command prompt
REM -------------------------------------------------------------------
fltmc >nul 2>&1
exit /b %errorlevel%

:RunElevatedStage
REM -------------------------------------------------------------------
REM Relaunch this batch file for one selected elevated stage
REM -------------------------------------------------------------------
set "STARTUP_ELEVATE_STAGE=%~1"
call :IsAdmin
if "%errorlevel%"=="0" exit /b 0

echo Requesting administrator approval for %STARTUP_ELEVATE_STAGE% tasks...
set "STARTUP_ELEVATE_TARGET=%~f0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$stageArg = '--admin-' + $env:STARTUP_ELEVATE_STAGE; $target = $env:STARTUP_ELEVATE_TARGET; $p = Start-Process -FilePath $env:ComSpec -ArgumentList @('/d', '/s', '/c', [char]34 + $target + [char]34 + ' ' + $stageArg) -Verb RunAs -WindowStyle Minimized -Wait -PassThru; exit $p.ExitCode"
exit /b %errorlevel%

:UpgradeFrozenRequirements
REM -------------------------------------------------------------------
REM Freeze installed packages, loosen pins, upgrade, and clean temp file
REM -------------------------------------------------------------------
set "SCRIPT_PYTHON_EXE=%~1"
set "SCRIPT_REQUIREMENTS_FILE=%TEMP%\requirements-%RANDOM%-%RANDOM%.txt"
%SCRIPT_PYTHON_EXE% -m pip freeze > "%SCRIPT_REQUIREMENTS_FILE%"
if errorlevel 1 (
    del /q /f "%SCRIPT_REQUIREMENTS_FILE%" 2>nul
    exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$r = $env:SCRIPT_REQUIREMENTS_FILE; (Get-Content -LiteralPath $r) -replace '==', '>=' | Set-Content -LiteralPath $r -Encoding ASCII"
if errorlevel 1 (
    del /q /f "%SCRIPT_REQUIREMENTS_FILE%" 2>nul
    exit /b 1
)
%SCRIPT_PYTHON_EXE% -m pip install --upgrade -r "%SCRIPT_REQUIREMENTS_FILE%"
set "SCRIPT_UPGRADE_RC=%errorlevel%"
del /q /f "%SCRIPT_REQUIREMENTS_FILE%" 2>nul
exit /b %SCRIPT_UPGRADE_RC%

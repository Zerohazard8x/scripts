@echo off

@REM Disabled low-priority launch retained near the call site it would replace.
@REM It remains disabled because STARTing cmd.exe here creates a second console window.
@REM if /I not "%SCRIPT_LOWPRIO%"=="1" (
@REM     set "SCRIPT_LOWPRIO=1"
@REM     start "" /b /wait /low /min cmd /s /c ""%~f0" %*"
@REM     exit /b %errorlevel%
@REM )

setlocal EnableExtensions EnableDelayedExpansion
set "PIP_BREAK_SYSTEM_PACKAGES=1"
set "USER_PATH=%PATH%"

@REM Decode the internal stage argument before normal prompts so an elevated child runs only its assigned section.
set "STARTUP_ADMIN_STAGE="
if /I "%~1"=="--admin-python" set "STARTUP_ADMIN_STAGE=python"
if /I "%~1"=="--admin-programs" set "STARTUP_ADMIN_STAGE=programs"
if /I "%STARTUP_ADMIN_STAGE%"=="python" goto ADMIN_PYTHON_TASKS
if /I "%STARTUP_ADMIN_STAGE%"=="programs" goto ADMIN_PROGRAM_TASKS

set "downloadDir=%USERPROFILE%\Downloads"
if not exist "%downloadDir%" mkdir "%downloadDir%"

@REM minescule mouse
@REM Marker used by downloader.bat to verify that it fetched the expected script.
@REM Stable validation marker; keep the spelling synchronized with downloader.bat.

@REM Use one extra loopback ping as a broadly available delay of roughly one second.
ping 127.0.0.1 -n 2 >nul

@REM @REM Clear screen
@REM cls

@REM Ask before Python maintenance; CHOICE returns 1 for Y and 2 for N, with Y selected after five seconds.
choice /C YN /N /D Y /T 5 /M "Python? (Y/N)"
if errorlevel 2 goto NOPYTHON

for /f "delims=" %%I in ('python -c "import sys;print(sys.executable)" 2^>nul') do set "PYEXE=%%I"
for /f "delims=" %%I in ('python3.12 -c "import sys;print(sys.executable)" 2^>nul') do set "PY312EXE=%%I"

@REM Run the Python block directly when already elevated; otherwise relaunch only that stage with UAC.
call :IsAdmin
if "%errorlevel%"=="0" goto ADMIN_PYTHON_TASKS

call :RunElevatedStage python
set "rc=%errorlevel%"
if not "%rc%"=="0" (
    echo Python stage exited with code %rc%.
    pause
)
goto NOPYTHON

@REM Elevated Python stage begins here; direct GOTO avoids replaying the initial prompt.
:ADMIN_PYTHON_TASKS
if not defined PYEXE for /f "delims=" %%I in ('python -c "import sys;print(sys.executable)" 2^>nul') do set "PYEXE=%%I"
if not exist "%PYEXE%" (
    @REM If Chocolatey exists, upgrade Python via choco
    where choco >nul 2>&1 && (
        choco upgrade python3 -y||pause
        for /f "delims=" %%I in ('set "PATH=!USER_PATH!" ^& python -c "import sys;print(sys.executable)" 2^>nul') do set "PYEXE=%%I"
    )

    if not exist "!PYEXE!" (
        echo Python executable was not found after the Chocolatey upgrade.
        pause
    )
)

if not defined PY312EXE for /f "delims=" %%I in ('python3.12 -c "import sys;print(sys.executable)" 2^>nul') do set "PY312EXE=%%I"

@REM If python in PATH, purge cache and upgrade packages
if exist "%PYEXE%" (
    "%PYEXE%" -m pip install --upgrade pip||pause
    "%PYEXE%" -m pip install setuptools pyreadline3 yt-dlp[default,curl-cffi] mutagen||pause

    @REM Install and resolve Python 3.12 through uv because WhisperX and Demucs are isolated to that interpreter.
    if not exist "%PY312EXE%" (
        where uv >nul 2>&1
        if errorlevel 1 (
            "%PYEXE%" -m pip install uv||pause
        )

        "%PYEXE%" -m uv python install 3.12||pause
        "%PYEXE%" -m uv python update-shell||pause

        for /f "delims=" %%I in ('"%PYEXE%" -m uv python find 3.12 2^>nul') do set "PY312EXE=%%I"
    )


    @REM Install the selected VapourSynth plugins only when the local vsrepo entry point exists.
    if exist "%ProgramFiles%\vapoursynth\vsrepo\vsrepo.py" (
        "%PYEXE%" "%ProgramFiles%\vapoursynth\vsrepo\vsrepo.py" install havsfunc mvsfunc vsrife lsmas||pause
    )

    @REM Freeze installed top-level packages, resolve compatible upgrades, then enforce pip dependency consistency.
    where powershell >nul 2>&1 && (
        call :UpgradeFrozenRequirements "%PYEXE%"||pause
    )

    @REM @REM packages not dependencies of any other package
    @REM python -m pip install pipdeptree
    @REM python -m pipdeptree --warn silence
    @REM findstr /R "^[A-Za-z0-9_-]"
)

@REM If python3.12 in PATH, purge cache and upgrade packages
if exist "%PY312EXE%" (
    "%PY312EXE%" -m pip install --upgrade pip||pause
    "%PY312EXE%" -m pip install whisperx demucs||pause
    where nvidia-smi >nul 2>&1 && "%PY312EXE%" -m pip install "torch==2.8.0" "torchvision==0.23.0" "torchaudio==2.8.0" --index-url https://download.pytorch.org/whl/cu128||pause

    @REM Freeze installed top-level packages, resolve compatible upgrades, then enforce pip dependency consistency.
    where powershell >nul 2>&1 && (
        call :UpgradeFrozenRequirements "%PY312EXE%"||pause
    )
)

set "rc=%errorlevel%"
if /I not "%STARTUP_ADMIN_STAGE%"=="python" goto NOPYTHON
if not "%rc%"=="0" (
    echo A stage exited with non-zero code %rc%.
    pause
)
endlocal & exit /b %rc%

:NOPYTHON

@REM @REM Clear screen
@REM cls

@REM Ask before package-manager upgrades; N skips directly to the shared startup stage.
choice /C YN /N /D Y /T 5 /M "Install programs? (Y/N)"
if errorlevel 2 goto NOPROGRAMS

@REM Keep all package-manager changes in one elevated child instead of prompting for each command.
call :IsAdmin
if "%errorlevel%"=="0" goto ADMIN_PROGRAM_TASKS

call :RunElevatedStage programs
set "rc=%errorlevel%"
if not "%rc%"=="0" (
    echo Programs stage exited with code %rc%.
    pause
)
goto NOPROGRAMS

@REM Elevated program-upgrade stage begins here; package managers generally require administrator rights.
:ADMIN_PROGRAM_TASKS
@REM Upgrade Chocolatey itself before upgrading its installed packages.
where choco >nul 2>&1
if errorlevel 1 (
    echo Chocolatey was not found in the elevated process PATH.
    pause
) else (
    choice /C YN /N /D Y /T 5 /M "Upgrade primary Chocolatey packages? (Y/N)"
    if not errorlevel 2 (
        choco upgrade chocolatey curl firefox ffmpeg git jq mpv nomacs peazip phantomjs vlc -y||pause
        choco upgrade 7zip aria2 adb dos2unix nano scrcpy vscode thunderbird -y||pause
    )
    
    choco upgrade all -y||pause

    @REM to update choco version without installing
    @REM choco upgrade <program> --skip-powershell
)

@REM where wsl >nul 2>&1 && (
@REM     wsl --install --no-launch
@REM     wsl --update
@REM )

if /I "%STARTUP_ADMIN_STAGE%"=="programs" endlocal & exit /b 0

:NOPROGRAMS

@REM Call common.bat in the current console so execution waits and its exit status can be propagated.
if exist "%~dp0common.bat" (
    @REM Disabled low-priority launch retained near the call site it would replace.
    @REM It remains disabled because START /WAIT through cmd.exe opens another console window.
    @REM start "" /wait /low /min cmd /c "%downloadDir%\common.bat"

    call "%~dp0common.bat"
    set "rc=%errorlevel%"
) else (
    echo *** ERROR: common.bat not found! ***
    set "rc=1"
)

@REM If common.bat failed
if not "%rc%"=="0" (
    echo.
    echo common.bat exited with code %rc%. Writing to %~dp0startup_tasks.log and closing.
    >>"%~dp0startup_tasks.log" echo [%date% %time%] common.bat exited with code %rc%
    pause
    endlocal & exit /b %rc%
)

@REM @REM Success path: auto-close unless user presses Y within 5 seconds
@REM choice /C YN /N /T 5 /D N /M "Stay open? (Y/N)"
@REM if errorlevel 2 endlocal & exit /b 0
endlocal & exit /b 0
@REM cmd /k
@REM endlocal & exit /b %errorlevel%

@REM Return zero when elevated and nonzero otherwise, matching normal batch errorlevel conventions.
:IsAdmin
@REM Use FLTMC as a lightweight administrator check because it fails for a standard token.
fltmc >nul 2>&1
exit /b %errorlevel%

@REM Relaunch this script through PowerShell Start-Process -Verb RunAs and wait for the selected stage.
:RunElevatedStage
@REM Pass only the requested stage to the elevated child, preventing completed sections from running twice.
set "STARTUP_ELEVATE_STAGE=%~1"
call :IsAdmin
if "%errorlevel%"=="0" exit /b 0

echo Requesting administrator approval for %STARTUP_ELEVATE_STAGE% tasks...
set "STARTUP_ELEVATE_TARGET=%~f0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$stageArg = '--admin-' + $env:STARTUP_ELEVATE_STAGE; $target = $env:STARTUP_ELEVATE_TARGET; $cmdLine = 'set ' + [char]34 + 'PYEXE=' + $env:PYEXE + [char]34 + ' & set ' + [char]34 + 'PY312EXE=' + $env:PY312EXE + [char]34 + ' & call ' + [char]34 + $target + [char]34 + ' ' + $stageArg; try { $p = Start-Process -FilePath $env:ComSpec -ArgumentList @('/d', '/c', $cmdLine) -Verb RunAs -WindowStyle Minimized -Wait -PassThru -ErrorAction Stop; exit $p.ExitCode } catch { Write-Host $_.Exception.Message; exit 1 }"
exit /b %errorlevel%

@REM Upgrade an interpreter from its current package inventory while preserving dependency compatibility.
:UpgradeFrozenRequirements
set "SCRIPT_PYTHON_EXE=%~1"
set "SCRIPT_ID=%RANDOM%-%RANDOM%"
set "SCRIPT_PACKAGES_JSON=%TEMP%\packages-%SCRIPT_ID%.json"
set "SCRIPT_UPGRADE_FILE=%TEMP%\requirements-upgrade-%SCRIPT_ID%.txt"
set "SCRIPT_REPORT_FILE=%TEMP%\pip-upgrade-report-%SCRIPT_ID%.json"

@REM Generate lower-bounded requirements from installed versions so upgrades never intentionally downgrade packages.
@REM Exclude editable installs and packaging bootstrap tools because they need separate ownership and upgrade handling.
"%SCRIPT_PYTHON_EXE%" -m pip list --format=json --exclude-editable --exclude pip --exclude setuptools --exclude wheel --exclude distribute > "%SCRIPT_PACKAGES_JSON%"
if errorlevel 1 (
    set "SCRIPT_UPGRADE_RC=1"
    goto :UpgradeFrozenRequirementsCleanup
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
  "$j = Get-Content -Raw -LiteralPath $env:SCRIPT_PACKAGES_JSON | ConvertFrom-Json; " ^
  "$j | Where-Object { $_.version -notmatch '\+' } | ForEach-Object { '{0}>={1}' -f $_.name, $_.version } | Set-Content -LiteralPath $env:SCRIPT_UPGRADE_FILE -Encoding ASCII"

if errorlevel 1 (
    set "SCRIPT_UPGRADE_RC=1"
    goto :UpgradeFrozenRequirementsCleanup
)

@REM Run pip in dry-run mode first so dependency conflicts are detected before modifying the environment.
"%SCRIPT_PYTHON_EXE%" -m pip install --dry-run --upgrade --upgrade-strategy eager -r "%SCRIPT_UPGRADE_FILE%" --report "%SCRIPT_REPORT_FILE%"
if errorlevel 1 (
    set "SCRIPT_UPGRADE_RC=1"
    goto :UpgradeFrozenRequirementsCleanup
)

@REM Install only after the resolver accepts the generated requirement set.
"%SCRIPT_PYTHON_EXE%" -m pip install --upgrade --upgrade-strategy eager -r "%SCRIPT_UPGRADE_FILE%"

@REM Run pip check last because a successful install can still leave incompatible declared dependencies.
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
@echo off

REM -------------------------------------------------------------------
REM version string
REM minescule mouse
REM -------------------------------------------------------------------

REM Ping-abuse timeout – ~1 second
ping 127.0.0.1 -n 2 >nul

REM -------------------------------------------------------------------
REM Launch Voicemeeter if installed
REM -------------------------------------------------------------------
if exist "%ProgramFiles(x86)%\VB\Voicemeeter\voicemeeterpro_x64.exe" (
    tasklist /FI "IMAGENAME eq voicemeeterpro_x64.exe" 2>NUL | find /I /N "voicemeeterpro_x64.exe">NUL
    if "%ERRORLEVEL%"=="1" (
        start "" "%ProgramFiles(x86)%\VB\Voicemeeter\voicemeeterpro_x64.exe"
    )
) else (
    if exist "%ProgramFiles(x86)%\VB\Voicemeeter\voicemeeter8x64.exe" (
        tasklist /FI "IMAGENAME eq voicemeeter8x64.exe" 2>NUL | find /I /N "voicemeeter8x64.exe">NUL
        if "%ERRORLEVEL%"=="1" (
            start "" "%ProgramFiles(x86)%\VB\Voicemeeter\voicemeeter8x64.exe"
        )
    )
)

REM Clear screen
cls

REM -------------------------------------------------------------------
REM Prompt: Python? (Y/N) [default Y after 15s]
REM -------------------------------------------------------------------
choice /C YN /N /D Y /T 15 /M "Python? (Y/N)"
if errorlevel 2 goto NOPYTHON

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
    python -m pip install --upgrade pip setuptools yt-dlp mutagen

    where python3.12 >nul 2>&1
    if errorlevel 0 (
        python3.12 -m pip install -U pip whisperx
    ) else (
        where uv >nul 2>&1
        if errorlevel 0 (
            uv python install 3.12
        ) else (
            python -m pip install -U uv
        )
    )

    REM Install VapourSynth plugins if vsrepo script found
    if exist "%ProgramFiles%\vapoursynth\vsrepo\vsrepo.py" (
        python "%ProgramFiles%\vapoursynth\vsrepo\vsrepo.py" install havsfunc mvsfunc vsrife lsmas
    )

    REM Regenerate requirements and upgrade via PowerShell
    where powershell >nul 2>&1 && (
        python -m pip freeze > requirements.txt
        powershell -Command ^
          "(Get-Content requirements.txt) | ForEach-Object { $_ -replace '==','>=' } | Set-Content requirements.txt"
        python -m pip install --upgrade -r requirements.txt
        del requirements.txt

        REM Also upgrade for Python 3.12 if present
        where python3.12 >nul 2>&1 && (
            python3.12 -m pip freeze > requirements.txt
            powershell -Command ^
              "(Get-Content requirements.txt) | ForEach-Object { $_ -replace '==','>=' } | Set-Content requirements.txt"
            python3.12 -m pip install --upgrade -r requirements.txt
            del requirements.txt
        )
    )
)

:NOPYTHON

REM Clear screen
cls

REM -------------------------------------------------------------------
REM Prompt: Install programs? (Y/N) [default Y after 15s]
REM -------------------------------------------------------------------
choice /C YN /N /D Y /T 15 /M "Install programs? (Y/N)"
if errorlevel 2 goto NOPROGRAMS

REM -------------------------------------------------------------------
REM Upgrade Chocolatey packages
REM -------------------------------------------------------------------
where choco >nul 2>&1 && (
    choco upgrade chocolatey curl firefox ffmpeg git jq mpv nomacs peazip phantomjs vlc -y
    choco upgrade 7zip aria2 adb discord dos2unix nano scrcpy vscode -y
)

REM where wsl >nul 2>&1 && (
REM     wsl --install --no-launch
REM     wsl --update
REM )

:NOPROGRAMS

REM -------------------------------------------------------------------
REM Finally, run common.bat and handle its exit code
REM -------------------------------------------------------------------
if exist "common.bat" (
    start "" common.bat
    if errorlevel 1 (
        REM If it failed, keep the console open
        cmd /k
    ) else (
        REM On success, exit cleanly
        exit /b 0
    )
) else (
    echo *** ERROR: common.bat not found! ***
    cmd /k
)

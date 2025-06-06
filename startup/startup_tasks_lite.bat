@echo off

@REM version string
@REM minescule mouse

ping 127.0.0.1 -n 2 > nul

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

cls 
@REM source.unsplash seems deprecated
@REM choice /C YN /N /D Y /T 15 /M "Wallpapers? (Y/N)"
@REM if %ERRORLEVEL% equ 2 goto NOWALL

WHERE curl 
if %ERRORLEVEL% EQU 0 (
    mkdir %USERPROFILE%\default_wall
    curl --remote-time -LJO --output-dir %USERPROFILE%\default_wall\ https://picsum.photos/1920/1080
) else (
    WHERE wget 
    if %ERRORLEVEL% EQU 0 (
        mkdir %USERPROFILE%\default_wall
        wget -c --timestamping --content-disposition -P "%USERPROFILE%\default_wall\" "https://picsum.photos/1920/1080"
    )
)

:NOWALL
cls 
choice /C YN /N /D Y /T 15 /M "Python? (Y/N)"
if %ERRORLEVEL% equ 2 goto NOPYTHON

where choco >nul 2>&1 && (
    choco uninstall python2 python -y & choco upgrade python3 -y 
)

where python >nul 2>&1 && (
    where python3 >nul 2>&1 && (
        python3 -m pip cache purge
        python3 -m pip freeze > requirements.txt
        python3 -m pip uninstall -y -r requirements.txt
    )

    python -m pip cache purge
    python -m pip install -U pip setuptools yt-dlp[default,curl-cffi] mutagen
)

:NOPYTHON
cls
choice /C YN /N /D Y /T 15 /M "Install programs? (Y/N)"
if %ERRORLEVEL% equ 2 goto NOPROGRAMS

where choco >nul 2>&1 && (
    choco upgrade chocolatey curl firefox ffmpeg git jq mpv nomacs peazip powershell phantomjs vlc -y
)

:NOPROGRAMS
if %ERRORLEVEL% EQU 0 (
    exit
) else (
    cmd /k
)
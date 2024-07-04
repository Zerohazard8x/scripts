@echo off

@REM version string
@REM lineage lick

@REM Ping-abuse timeout - 1 second
ping 127.0.0.1 -n 2 > nul

@REM powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e

@REM WHERE w32tm
@REM if %ERRORLEVEL% EQU 0 (
@REM     w32tm /config /update
@REM     w32tm /resync
@REM )

@REM Clear clipboard
@REM "echo off | clip"

cls 
@REM source.unsplash seems deprecated

@REM /C YN means choices are Y,N
@REM /D Y means default choice is Y
@REM /T 15 means 5-second timeout
@REM choice /C YN /N /D Y /T 15 /M "Wallpapers? (Y/N)"

@REM if %ERRORLEVEL% equ 2 goto NOWALL

@REM source.unsplash seems deprecated
@REM WHERE curl
@REM if %ERRORLEVEL% EQU 0 (
@REM     mkdir %USERPROFILE%\default_wall

@REM     artificial -output artificial.jpg
@REM     hd-wallpapers" -output weekly.jpg
@REM     cloudy -output winter.jpg
@REM     cozy -output cozy.jpg
@REM     drawing -output drawing.jpg
@REM     dry -output dry.jpg
@REM     fall -output fall.jpg
@REM     rainy -output winter.jpg
@REM     render -output render.jpg
@REM     spring -output spring.jpg
@REM     stormy -output winter.jpg
@REM     summer -output summer.jpg
@REM     sunny -output winter.jpg
@REM     wet -output wet.jpg
@REM     windy -output windy.jpg
@REM     winter -output winter.jpg

@REM     @REM phone - 1644x3840
@REM )

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
    python -m pip install -U pip setuptools youtube-dl mutagen
    python -m pip install -U https://github.com/yt-dlp/yt-dlp/archive/master.tar.gz

    if exist "%ProgramFiles%\vapoursynth\vsrepo\vsrepo.py" (
        python "%programfiles%\vapoursynth\vsrepo\vsrepo.py" install havsfunc mvsfunc vsrife lsmas
    )

    ren "%localappdata%\Programs\Python\Python310\python.exe" "%localappdata%\Programs\Python\Python310\python310.exe"
    ren "%homedrive%\Python310\python.exe" "%homedrive%\Python310\python310.exe"
    where python310 >nul 2>&1 && (
        python310 -m pip cache purge
        python310 -m pip freeze > requirements.txt
        python310 -m pip uninstall -y -r requirements.txt
        @REM python310 -m pip install -U pip
    )
)

:NOPYTHON
cls 
choice /C YN /N /D Y /T 15 /M "Install programs? (Y/N)"
if %ERRORLEVEL% equ 2 goto NOPROGRAMS

where choco >nul 2>&1 && (
    choco upgrade chocolatey curl firefox ffmpeg git jq mpv nomacs peazip powershell phantomjs vlc -y
    choco upgrade 7zip aria2 adb discord dos2unix libreoffice obs-studio nano pinta qbittorrent scrcpy steam vscode -y
)

where wsl >nul 2>&1 && (
    wsl --install --no-launch
    wsl --update
)

:NOPROGRAMS
start "" common.bat
exit
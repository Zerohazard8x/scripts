@echo off

@REM version string
@REM lineage lick

@REM Ping-abuse timeout - 1 second
ping 127.0.0.1 -n 2 > nul

@REM powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e

@REM WHERE w32tm
@REM if %ERRORLEVEL% EQU 0 (
@REM w32tm /config /update
@REM w32tm /resync
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
@REM mkdir %USERPROFILE%\default_wall

@REM call :download_file "daily?hd-wallpapers" %USERPROFILE%\default_wall\daily.jpg
@REM call :download_file "daily?artificial" %USERPROFILE%\default_wall\daily_artificial.jpg
@REM call :download_file "daily?cloudy" %USERPROFILE%\default_wall\daily_winter.jpg
@REM call :download_file "daily?cozy" %USERPROFILE%\default_wall\daily_cozy.jpg
@REM call :download_file "daily?drawing" %USERPROFILE%\default_wall\daily_drawing.jpg
@REM call :download_file "daily?dry" %USERPROFILE%\default_wall\daily_dry.jpg
@REM call :download_file "daily?fall" %USERPROFILE%\default_wall\daily_fall.jpg
@REM call :download_file "daily?rainy" %USERPROFILE%\default_wall\daily_winter.jpg
@REM call :download_file "daily?render" %USERPROFILE%\default_wall\daily_render.jpg
@REM call :download_file "daily?spring" %USERPROFILE%\default_wall\daily_spring.jpg
@REM call :download_file "daily?stormy" %USERPROFILE%\default_wall\daily_winter.jpg
@REM call :download_file "daily?summer" %USERPROFILE%\default_wall\daily_summer.jpg
@REM call :download_file "daily?sunny" %USERPROFILE%\default_wall\daily_winter.jpg
@REM call :download_file "daily?wet" %USERPROFILE%\default_wall\daily_wet.jpg
@REM call :download_file "daily?windy" %USERPROFILE%\default_wall\daily_windy.jpg
@REM call :download_file "daily?winter" %USERPROFILE%\default_wall\daily_winter.jpg

@REM call :download_file "weekly?artificial" %USERPROFILE%\default_wall\artificial.jpg
@REM call :download_file "weekly?hd-wallpapers" %USERPROFILE%\default_wall\weekly.jpg
@REM call :download_file "weekly?cloudy" %USERPROFILE%\default_wall\winter.jpg
@REM call :download_file "weekly?cozy" %USERPROFILE%\default_wall\cozy.jpg
@REM call :download_file "weekly?drawing" %USERPROFILE%\default_wall\drawing.jpg
@REM call :download_file "weekly?dry" %USERPROFILE%\default_wall\dry.jpg
@REM call :download_file "weekly?fall" %USERPROFILE%\default_wall\fall.jpg
@REM call :download_file "weekly?rainy" %USERPROFILE%\default_wall\winter.jpg
@REM call :download_file "weekly?render" %USERPROFILE%\default_wall\render.jpg
@REM call :download_file "weekly?spring" %USERPROFILE%\default_wall\spring.jpg
@REM call :download_file "weekly?stormy" %USERPROFILE%\default_wall\winter.jpg
@REM call :download_file "weekly?summer" %USERPROFILE%\default_wall\summer.jpg
@REM call :download_file "weekly?sunny" %USERPROFILE%\default_wall\winter.jpg
@REM call :download_file "weekly?wet" %USERPROFILE%\default_wall\wet.jpg
@REM call :download_file "weekly?windy" %USERPROFILE%\default_wall\windy.jpg
@REM call :download_file "weekly?winter" %USERPROFILE%\default_wall\winter.jpg

@REM @REM phone - 1644x3840

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
    WHERE python310
    if %ERRORLEVEL% EQU 0 (
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
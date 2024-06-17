@echo off

@REM Ping-abuse timeout - 1 second
ping 127.0.0.1 -n 2 > nul

del /s /q /f .\*.aria2
@REM del /s /q /f .\*.py
@REM del /s /q /f .\*.reg

@REM powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e

@REM WHERE w32tm
@REM if %ERRORLEVEL% EQU 0 (
@REM     w32tm /config /update
@REM     w32tm /resync
@REM )

@REM Clear clipboard
@REM "echo off | clip"

@REM /C YN means choices are Y,N
@REM /D Y means default choice is Y
@REM /T 15 means 5-second timeout
cls 
choice /C YN /N /D Y /T 15 /M "Wallpapers? (Y/N)"
if %ERRORLEVEL% equ 2 goto NOWALL

del /s /q /f .\wallpapers.sh

WHERE curl
if %ERRORLEVEL% EQU 0 (
    mkdir %USERPROFILE%\default_wall
    del /s /q /f %USERPROFILE%\default_wall\*.aria2

    curl --remote-time -C - "https://source.unsplash.com/featured/7680x2160/daily?hd-wallpapers" -Lo %USERPROFILE%\default_wall\daily.jpg
    curl --remote-time -C - "https://source.unsplash.com/featured/7680x2160/daily?artificial,hd-wallpapers" -Lo %USERPROFILE%\default_wall\daily_artificial.jpg
    curl --remote-time -C - "https://source.unsplash.com/featured/7680x2160/daily?cloudy,hd-wallpapers" -Lo %USERPROFILE%\default_wall\daily_winter.jpg
    curl --remote-time -C - "https://source.unsplash.com/featured/7680x2160/daily?cozy,hd-wallpapers" -Lo %USERPROFILE%\default_wall\daily_cozy.jpg
    curl --remote-time -C - "https://source.unsplash.com/featured/7680x2160/daily?drawing,hd-wallpapers" -Lo %USERPROFILE%\default_wall\daily_drawing.jpg
    curl --remote-time -C - "https://source.unsplash.com/featured/7680x2160/daily?dry,hd-wallpapers" -Lo %USERPROFILE%\default_wall\daily_dry.jpg
    curl --remote-time -C - "https://source.unsplash.com/featured/7680x2160/daily?fall,hd-wallpapers" -Lo %USERPROFILE%\default_wall\daily_fall.jpg
    curl --remote-time -C - "https://source.unsplash.com/featured/7680x2160/daily?rainy,hd-wallpapers" -Lo %USERPROFILE%\default_wall\daily_winter.jpg
    curl --remote-time -C - "https://source.unsplash.com/featured/7680x2160/daily?render,hd-wallpapers" -Lo %USERPROFILE%\default_wall\daily_render.jpg
    curl --remote-time -C - "https://source.unsplash.com/featured/7680x2160/daily?spring,hd-wallpapers" -Lo %USERPROFILE%\default_wall\daily_spring.jpg
    curl --remote-time -C - "https://source.unsplash.com/featured/7680x2160/daily?stormy,hd-wallpapers" -Lo %USERPROFILE%\default_wall\daily_winter.jpg
    curl --remote-time -C - "https://source.unsplash.com/featured/7680x2160/daily?summer,hd-wallpapers" -Lo %USERPROFILE%\default_wall\daily_summer.jpg
    curl --remote-time -C - "https://source.unsplash.com/featured/7680x2160/daily?sunny,hd-wallpapers" -Lo %USERPROFILE%\default_wall\daily_winter.jpg
    curl --remote-time -C - "https://source.unsplash.com/featured/7680x2160/daily?wet,hd-wallpapers" -Lo %USERPROFILE%\default_wall\daily_wet.jpg
    curl --remote-time -C - "https://source.unsplash.com/featured/7680x2160/daily?windy,hd-wallpapers" -Lo %USERPROFILE%\default_wall\daily_windy.jpg
    curl --remote-time -C - "https://source.unsplash.com/featured/7680x2160/daily?winter,hd-wallpapers" -Lo %USERPROFILE%\default_wall\daily_winter.jpg

    curl --remote-time -C - "https://source.unsplash.com/featured/7680x2160/weekly?artificial,hd-wallpapers" -Lo %USERPROFILE%\default_wall\artificial.jpg
    curl --remote-time -C - "https://source.unsplash.com/featured/7680x2160/weekly?hd-wallpapers" -Lo %USERPROFILE%\default_wall\weekly.jpg
    curl --remote-time -C - "https://source.unsplash.com/featured/7680x2160/weekly?cloudy,hd-wallpapers" -Lo %USERPROFILE%\default_wall\winter.jpg
    curl --remote-time -C - "https://source.unsplash.com/featured/7680x2160/weekly?cozy,hd-wallpapers" -Lo %USERPROFILE%\default_wall\cozy.jpg
    curl --remote-time -C - "https://source.unsplash.com/featured/7680x2160/weekly?drawing,hd-wallpapers" -Lo %USERPROFILE%\default_wall\drawing.jpg
    curl --remote-time -C - "https://source.unsplash.com/featured/7680x2160/weekly?dry,hd-wallpapers" -Lo %USERPROFILE%\default_wall\dry.jpg
    curl --remote-time -C - "https://source.unsplash.com/featured/7680x2160/weekly?fall,hd-wallpapers" -Lo %USERPROFILE%\default_wall\fall.jpg
    curl --remote-time -C - "https://source.unsplash.com/featured/7680x2160/weekly?rainy,hd-wallpapers" -Lo %USERPROFILE%\default_wall\winter.jpg
    curl --remote-time -C - "https://source.unsplash.com/featured/7680x2160/weekly?render,hd-wallpapers" -Lo %USERPROFILE%\default_wall\render.jpg
    curl --remote-time -C - "https://source.unsplash.com/featured/7680x2160/weekly?spring,hd-wallpapers" -Lo %USERPROFILE%\default_wall\spring.jpg
    curl --remote-time -C - "https://source.unsplash.com/featured/7680x2160/weekly?stormy,hd-wallpapers" -Lo %USERPROFILE%\default_wall\winter.jpg
    curl --remote-time -C - "https://source.unsplash.com/featured/7680x2160/weekly?summer,hd-wallpapers" -Lo %USERPROFILE%\default_wall\summer.jpg
    curl --remote-time -C - "https://source.unsplash.com/featured/7680x2160/weekly?sunny,hd-wallpapers" -Lo %USERPROFILE%\default_wall\winter.jpg
    curl --remote-time -C - "https://source.unsplash.com/featured/7680x2160/weekly?wet,hd-wallpapers" -Lo %USERPROFILE%\default_wall\wet.jpg
    curl --remote-time -C - "https://source.unsplash.com/featured/7680x2160/weekly?windy,hd-wallpapers" -Lo %USERPROFILE%\default_wall\windy.jpg
    curl --remote-time -C - "https://source.unsplash.com/featured/7680x2160/weekly?winter,hd-wallpapers" -Lo %USERPROFILE%\default_wall\winter.jpg

    @REM phone - 1644x3840
)

:NOWALL
cls 
choice /C YN /N /D Y /T 15 /M "Python? (Y/N)"
if %ERRORLEVEL% equ 2 goto NOPYTHON

WHERE choco
if %ERRORLEVEL% EQU 0 (
    choco uninstall python2 python -y & choco upgrade python3 -y 
)

WHERE python
if %ERRORLEVEL% EQU 0 (
    WHERE python3
    if %ERRORLEVEL% EQU 0 (
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

WHERE choco
if %ERRORLEVEL% EQU 0 (
    choco upgrade chocolatey curl firefox ffmpeg git jq mpv nomacs peazip powershell phantomjs vlc -y
    choco upgrade 7zip aria2 adb discord dos2unix libreoffice obs-studio nano pinta qbittorrent scrcpy steam vscode -y
)

WHERE wsl
if %ERRORLEVEL% EQU 0 (
    wsl --install --no-launch
    wsl --update
)

:NOPROGRAMS
start "" common.bat
exit
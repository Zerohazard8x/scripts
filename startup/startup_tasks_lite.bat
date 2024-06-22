@echo off

ping 127.0.0.1 -n 2 > nul

cls 
@REM source.unsplash seems deprecated
@REM choice /C YN /N /D Y /T 15 /M "Wallpapers? (Y/N)"
@REM if %ERRORLEVEL% equ 2 goto NOWALL

@REM WHERE curl
@REM if %ERRORLEVEL% EQU 0 (
@REM     mkdir .\lite
@REM     del /s /q /f .\lite\*.aria2
@REM     curl --remote-time -C - "https://source.unsplash.com/featured/1920x1080/daily" -Lo lite/daily.jpg
@REM     curl --remote-time -C - "https://source.unsplash.com/featured/1920x1080/daily?artificial,hd-wallpapers" -Lo default/daily_artificial.jpg
@REM     curl --remote-time -C - "https://source.unsplash.com/featured/1920x1080/daily?cloudy,hd-wallpapers" -Lo lite/daily_winter.jpg
@REM     curl --remote-time -C - "https://source.unsplash.com/featured/1920x1080/daily?cozy,hd-wallpapers" -Lo lite/daily_cozy.jpg
@REM     curl --remote-time -C - "https://source.unsplash.com/featured/1920x1080/daily?drawing,hd-wallpapers" -Lo lite/daily_drawing.jpg
@REM     curl --remote-time -C - "https://source.unsplash.com/featured/1920x1080/daily?dry,hd-wallpapers" -Lo lite/daily_dry.jpg
@REM     curl --remote-time -C - "https://source.unsplash.com/featured/1920x1080/daily?fall,hd-wallpapers" -Lo lite/daily_fall.jpg
@REM     curl --remote-time -C - "https://source.unsplash.com/featured/1920x1080/daily?rainy,hd-wallpapers" -Lo lite/daily_winter.jpg
@REM     curl --remote-time -C - "https://source.unsplash.com/featured/1920x1080/daily?render,hd-wallpapers" -Lo lite/daily_render.jpg
@REM     curl --remote-time -C - "https://source.unsplash.com/featured/1920x1080/daily?spring,hd-wallpapers" -Lo lite/daily_spring.jpg
@REM     curl --remote-time -C - "https://source.unsplash.com/featured/1920x1080/daily?stormy,hd-wallpapers" -Lo lite/daily_winter.jpg
@REM     curl --remote-time -C - "https://source.unsplash.com/featured/1920x1080/daily?summer,hd-wallpapers" -Lo lite/daily_summer.jpg
@REM     curl --remote-time -C - "https://source.unsplash.com/featured/1920x1080/daily?sunny,hd-wallpapers" -Lo lite/daily_winter.jpg
@REM     curl --remote-time -C - "https://source.unsplash.com/featured/1920x1080/daily?wet,hd-wallpapers" -Lo lite/daily_wet.jpg
@REM     curl --remote-time -C - "https://source.unsplash.com/featured/1920x1080/daily?windy,hd-wallpapers" -Lo lite/daily_windy.jpg
@REM     curl --remote-time -C - "https://source.unsplash.com/featured/1920x1080/daily?winter,hd-wallpapers" -Lo lite/daily_winter.jpg

@REM     curl --remote-time -C - "https://source.unsplash.com/featured/1920x1080/weekly,hd-wallpapers" -Lo lite/weekly.jpg
@REM     curl --remote-time -C - "https://source.unsplash.com/featured/1920x1080/daily?artificial,hd-wallpapers" -Lo default/daily_artificial.jpg
@REM     curl --remote-time -C - "https://source.unsplash.com/featured/1920x1080/weekly?cloudy,hd-wallpapers" -Lo lite/winter.jpg
@REM     curl --remote-time -C - "https://source.unsplash.com/featured/1920x1080/weekly?cozy,hd-wallpapers" -Lo lite/cozy.jpg
@REM     curl --remote-time -C - "https://source.unsplash.com/featured/1920x1080/weekly?drawing,hd-wallpapers" -Lo lite/drawing.jpg
@REM     curl --remote-time -C - "https://source.unsplash.com/featured/1920x1080/weekly?dry,hd-wallpapers" -Lo lite/dry.jpg
@REM     curl --remote-time -C - "https://source.unsplash.com/featured/1920x1080/weekly?fall,hd-wallpapers" -Lo lite/fall.jpg
@REM     curl --remote-time -C - "https://source.unsplash.com/featured/1920x1080/weekly?rainy,hd-wallpapers" -Lo lite/winter.jpg
@REM     curl --remote-time -C - "https://source.unsplash.com/featured/1920x1080/weekly?render,hd-wallpapers" -Lo lite/render.jpg
@REM     curl --remote-time -C - "https://source.unsplash.com/featured/1920x1080/weekly?spring,hd-wallpapers" -Lo lite/spring.jpg
@REM     curl --remote-time -C - "https://source.unsplash.com/featured/1920x1080/weekly?stormy,hd-wallpapers" -Lo lite/winter.jpg
@REM     curl --remote-time -C - "https://source.unsplash.com/featured/1920x1080/weekly?summer,hd-wallpapers" -Lo lite/summer.jpg
@REM     curl --remote-time -C - "https://source.unsplash.com/featured/1920x1080/weekly?sunny,hd-wallpapers" -Lo lite/winter.jpg
@REM     curl --remote-time -C - "https://source.unsplash.com/featured/1920x1080/weekly?wet,hd-wallpapers" -Lo lite/wet.jpg
@REM     curl --remote-time -C - "https://source.unsplash.com/featured/1920x1080/weekly?windy,hd-wallpapers" -Lo lite/windy.jpg
@REM     curl --remote-time -C - "https://source.unsplash.com/featured/1920x1080/weekly?winter,hd-wallpapers" -Lo lite/winter.jpg
@REM )

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
)

:NOPYTHON
cls
choice /C YN /N /D Y /T 15 /M "Install programs? (Y/N)"
if %ERRORLEVEL% equ 2 goto NOPROGRAMS

WHERE choco
if %ERRORLEVEL% EQU 0 (
    choco upgrade chocolatey curl firefox ffmpeg git jq mpv nomacs peazip powershell phantomjs vlc -y
)

:NOPROGRAMS
start "" common.bat
exit
@echo off

@REM version string
@REM lineage lick

ping 127.0.0.1 -n 2 > nul

cls 
@REM source.unsplash seems deprecated
@REM choice /C YN /N /D Y /T 15 /M "Wallpapers? (Y/N)"
@REM if %ERRORLEVEL% equ 2 goto NOWALL

@REM mkdir .\lite
@REM del /s /q /f .\lite\*.aria2
@REM curl -C - "daily" lite/daily.jpg
@REM curl -C - "daily?artificial" lite/daily_artificial.jpg
@REM curl -C - "daily?cloudy" lite/daily_winter.jpg
@REM curl -C - "daily?cozy" lite/daily_cozy.jpg
@REM curl -C - "daily?drawing" lite/daily_drawing.jpg
@REM curl -C - "daily?dry" lite/daily_dry.jpg
@REM curl -C - "daily?fall" lite/daily_fall.jpg
@REM curl -C - "daily?rainy" lite/daily_winter.jpg
@REM curl -C - "daily?render" lite/daily_render.jpg
@REM curl -C - "daily?spring" lite/daily_spring.jpg
@REM curl -C - "daily?stormy" lite/daily_winter.jpg
@REM curl -C - "daily?summer" lite/daily_summer.jpg
@REM curl -C - "daily?sunny" lite/daily_winter.jpg
@REM curl -C - "daily?wet" lite/daily_wet.jpg
@REM curl -C - "daily?windy" lite/daily_windy.jpg
@REM curl -C - "daily?winter" lite/daily_winter.jpg

@REM curl -C - "weekly" lite/weekly.jpg
@REM curl -C - "daily?artificial" lite/daily_artificial.jpg
@REM curl -C - "weekly?cloudy" lite/winter.jpg
@REM curl -C - "weekly?cozy" lite/cozy.jpg
@REM curl -C - "weekly?drawing" lite/drawing.jpg
@REM curl -C - "weekly?dry" lite/dry.jpg
@REM curl -C - "weekly?fall" lite/fall.jpg
@REM curl -C - "weekly?rainy" lite/winter.jpg
@REM curl -C - "weekly?render" lite/render.jpg
@REM curl -C - "weekly?spring" lite/spring.jpg
@REM curl -C - "weekly?stormy" lite/winter.jpg
@REM curl -C - "weekly?summer" lite/summer.jpg
@REM curl -C - "weekly?sunny" lite/winter.jpg
@REM curl -C - "weekly?wet" lite/wet.jpg
@REM curl -C - "weekly?windy" lite/windy.jpg
@REM curl -C - "weekly?winter" lite/winter.jpg

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
)

:NOPYTHON
cls
choice /C YN /N /D Y /T 15 /M "Install programs? (Y/N)"
if %ERRORLEVEL% equ 2 goto NOPROGRAMS

where choco >nul 2>&1 && (
    choco upgrade chocolatey curl firefox ffmpeg git jq mpv nomacs peazip powershell phantomjs vlc -y
)

:NOPROGRAMS
start "" common.bat
exit
@echo off

ping 127.0.0.1 -n 2 > nul

del /s /q /f .\*.aria2
del /s /q /f .\*.py
@REM del /s /q /f .\*.reg

@REM registry
WHERE reg
if %ERRORLEVEL% EQU 0 (
    del /s /q /f .\tweaks.reg

    WHERE aria2c
    if %ERRORLEVEL% EQU 0 (
        aria2c -x16 -s32 -R --allow-overwrite=true https://ghproxy.net/https://raw.githubusercontent.com/Zerohazard8x/scripts/main/tweaks.reg
    )

    reg import .\tweaks.reg
)

cls 
choice /C YN /N /D Y /T 15 /M "Wallpapers? (Y/N)"
if %ERRORLEVEL% equ 2 goto NOWALL

WHERE aria2c
if %ERRORLEVEL% EQU 0 (
    mkdir .\lite
    del /s /q /f .\lite\*.aria2
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1920x1080/daily" -o lite/daily.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1920x1080/daily?artificial,hd-wallpapers" -o default/daily_artificial.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1920x1080/daily?cloudy,hd-wallpapers" -o lite/daily_winter.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1920x1080/daily?cozy,hd-wallpapers" -o lite/daily_cozy.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1920x1080/daily?drawing,hd-wallpapers" -o lite/daily_drawing.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1920x1080/daily?dry,hd-wallpapers" -o lite/daily_dry.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1920x1080/daily?fall,hd-wallpapers" -o lite/daily_fall.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1920x1080/daily?rainy,hd-wallpapers" -o lite/daily_winter.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1920x1080/daily?render,hd-wallpapers" -o lite/daily_render.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1920x1080/daily?spring,hd-wallpapers" -o lite/daily_spring.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1920x1080/daily?stormy,hd-wallpapers" -o lite/daily_winter.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1920x1080/daily?summer,hd-wallpapers" -o lite/daily_summer.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1920x1080/daily?sunny,hd-wallpapers" -o lite/daily_winter.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1920x1080/daily?wet,hd-wallpapers" -o lite/daily_wet.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1920x1080/daily?windy,hd-wallpapers" -o lite/daily_windy.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1920x1080/daily?winter,hd-wallpapers" -o lite/daily_winter.jpg

    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1920x1080/weekly,hd-wallpapers" -o lite/weekly.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1920x1080/daily?artificial,hd-wallpapers" -o default/daily_artificial.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1920x1080/weekly?cloudy,hd-wallpapers" -o lite/winter.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1920x1080/weekly?cozy,hd-wallpapers" -o lite/cozy.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1920x1080/weekly?drawing,hd-wallpapers" -o lite/drawing.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1920x1080/weekly?dry,hd-wallpapers" -o lite/dry.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1920x1080/weekly?fall,hd-wallpapers" -o lite/fall.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1920x1080/weekly?rainy,hd-wallpapers" -o lite/winter.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1920x1080/weekly?render,hd-wallpapers" -o lite/render.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1920x1080/weekly?spring,hd-wallpapers" -o lite/spring.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1920x1080/weekly?stormy,hd-wallpapers" -o lite/winter.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1920x1080/weekly?summer,hd-wallpapers" -o lite/summer.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1920x1080/weekly?sunny,hd-wallpapers" -o lite/winter.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1920x1080/weekly?wet,hd-wallpapers" -o lite/wet.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1920x1080/weekly?windy,hd-wallpapers" -o lite/windy.jpg
    aria2c -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/1920x1080/weekly?winter,hd-wallpapers" -o lite/winter.jpg
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
    python -m pip install -U https://ghproxy.net/https://github.com/yt-dlp/yt-dlp/archive/master.tar.gz
)

:NOPYTHON
cls
choice /C YN /N /D Y /T 15 /M "Install programs? (Y/N)"
if %ERRORLEVEL% equ 2 goto NOPROGRAMS

WHERE choco
if %ERRORLEVEL% EQU 0 (
    choco upgrade chocolatey aria2 dos2unix firefox ffmpeg git jq mpv nano nomacs peazip powershell phantomjs vlc -y
)

:NOPROGRAMS
start "" common.bat
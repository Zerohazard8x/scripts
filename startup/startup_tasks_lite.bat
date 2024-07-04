@echo off

@REM version string
@REM lineage lick

ping 127.0.0.1 -n 2 > nul

cls 
@REM source.unsplash seems deprecated
@REM choice /C YN /N /D Y /T 15 /M "Wallpapers? (Y/N)"
@REM if %ERRORLEVEL% equ 2 goto NOWALL

@REM WHERE curl
@REM if %ERRORLEVEL% EQU 0 (
@REM     mkdir .\lite
@REM     del /s /q /f .\lite\*.aria2

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
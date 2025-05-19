@echo off

@REM version string
@REM minescule mouse

@REM Ping-abuse timeout - 1 second
ping 127.0.0.1 -n 2 > nul

cls 
@REM /C YN means choices are Y,N
@REM /D Y means default choice is Y
@REM /T 15 means 5-second timeout
@REM choice /C YN /N /D Y /T 15 /M "Wallpapers? (Y/N)"

@REM if %ERRORLEVEL% equ 2 goto NOWALL

@REM source.unsplash seems deprecated
WHERE curl 
if %ERRORLEVEL% EQU 0 (
    mkdir %USERPROFILE%\default_wall
    curl --remote-time -LJO --output-dir %USERPROFILE%\default_wall\ https://picsum.photos/3840/2160
) else (
    WHERE wget 
    if %ERRORLEVEL% EQU 0 (
        mkdir %USERPROFILE%\default_wall
        wget -c --timestamping --content-disposition -P "%USERPROFILE%\default_wall\" "https://picsum.photos/3840/2160"
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
    python -m pip cache purge
    python -m pip install -U pip setuptools yt-dlp[default,curl-cffi] mutagen uv

    WHERE uv 
    if %ERRORLEVEL% EQU 0 (
        @REM uv venv --python 3.12
        uv pip install --python 3.12 -U whisperx
        @REM uv pip install --python 3.12 -U openai-whisper
        @REM uv pip install --python 3.12 -U stable-ts faster-whisper demucs
    )

    if exist "%ProgramFiles%\vapoursynth\vsrepo\vsrepo.py" (
        python "%programfiles%\vapoursynth\vsrepo\vsrepo.py" install havsfunc mvsfunc vsrife lsmas
    )

    @REM upgrade
    WHERE powershell 
    if %ERRORLEVEL% EQU 0 (
        python -m pip freeze > requirements.txt
        powershell -Command "(Get-Content requirements.txt) | ForEach-Object { $_ -replace '==','>=' } | Set-Content requirements.txt"
        python -m pip install --upgrade -r requirements.txt
        del requirements.txt
    )
)

:NOPYTHON
cls 
choice /C YN /N /D Y /T 15 /M "Install programs? (Y/N)"
if %ERRORLEVEL% equ 2 goto NOPROGRAMS

where choco >nul 2>&1 && (
    choco upgrade chocolatey curl firefox ffmpeg git jq mpv nomacs peazip powershell phantomjs vlc -y
    choco upgrade 7zip aria2 adb discord dos2unix nano scrcpy vscode -y
)

@REM where wsl >nul 2>&1 && (
@REM     wsl --install --no-launch
@REM     wsl --update
@REM )

:NOPROGRAMS

start "" common.bat
if %ERRORLEVEL% EQU 0 (
    exit
) else (
    cmd /k
)
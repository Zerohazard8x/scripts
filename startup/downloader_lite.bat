@echo off
set "downloadDir=%USERPROFILE%\Downloads"
if not exist "%downloadDir%" mkdir "%downloadDir%"
del /s /q /f "%downloadDir%\common.bat"
del /s /q /f "%downloadDir%\startup_tasks_lite.bat"

where curl >nul 2>&1
if %errorlevel% equ 0 (
    curl --remote-time -C - -L --output-dir "%downloadDir%" -O "https://raw.githubusercontent.com/Zerohazard8x/scripts/main/startup/common.bat"
) else (
    where wget >nul 2>&1
    if %errorlevel% equ 0 (
        wget -c --timestamping -O "%downloadDir%\common.bat" "https://raw.githubusercontent.com/Zerohazard8x/scripts/main/startup/common.bat"
    ) else (
        where aria2c >nul 2>&1
        if %errorlevel% equ 0 (
            aria2c -R --allow-overwrite=true -d "%downloadDir%" -o "common.bat" "https://raw.githubusercontent.com/Zerohazard8x/scripts/main/startup/common.bat"
        )
    )
)

if exist "%downloadDir%\common.bat" (
    findstr /C:"minescule" /C:"mouse" "%downloadDir%\common.bat" >nul 2>&1
    if %errorlevel% equ 0 (
        where curl >nul 2>&1
        if %errorlevel% equ 0 (
            curl --remote-time -C - -L --output-dir "%downloadDir%" -O "https://raw.githubusercontent.com/Zerohazard8x/scripts/main/startup/startup_tasks_lite.bat"
        ) else (
            where wget >nul 2>&1
            if %errorlevel% equ 0 (
                wget -c --timestamping -O "%downloadDir%\startup_tasks_lite.bat" "https://raw.githubusercontent.com/Zerohazard8x/scripts/main/startup/startup_tasks_lite.bat"
            ) else (
                where aria2c >nul 2>&1
                if %errorlevel% equ 0 (
                    aria2c -R --allow-overwrite=true -d "%downloadDir%" -o "startup_tasks_lite.bat" "https://raw.githubusercontent.com/Zerohazard8x/scripts/main/startup/startup_tasks_lite.bat"
                )
            )
        )
        
        findstr /C:"minescule" /C:"mouse" "%downloadDir%\startup_tasks_lite.bat" >nul 2>&1
        if %errorlevel% equ 0 (
            call "%downloadDir%\startup_tasks_lite.bat"
            exit
        )
    )
)

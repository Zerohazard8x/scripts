@echo off
del /s /q /f .\common.bat
del /s /q /f .\startup_tasks.bat

where curl >nul 2>&1
if %errorlevel% equ 0 (
    curl --remote-time -C - -L --output-dir "." -O "https://raw.githubusercontent.com/Zerohazard8x/scripts/main/startup/common.bat"
) else (
    where wget >nul 2>&1
    if %errorlevel% equ 0 (
        wget -c --timestamping "https://raw.githubusercontent.com/Zerohazard8x/scripts/main/startup/common.bat"
    ) else (
        where aria2c >nul 2>&1
        if %errorlevel% equ 0 (
            aria2c -R --allow-overwrite=true "https://raw.githubusercontent.com/Zerohazard8x/scripts/main/startup/common.bat"
        )
    )
)

if exist ".\common.bat" (
    findstr /C:"minescule" /C:"mouse" ".\common.bat" >nul 2>&1
    if %errorlevel% equ 0 (
        where curl >nul 2>&1
        if %errorlevel% equ 0 (
            curl --remote-time -C - -LO "https://raw.githubusercontent.com/Zerohazard8x/scripts/main/startup/startup_tasks.bat"
        ) else (
            where wget >nul 2>&1
            if %errorlevel% equ 0 (
                wget -c --timestamping "https://raw.githubusercontent.com/Zerohazard8x/scripts/main/startup/startup_tasks.bat"
            ) else (
                where aria2c >nul 2>&1
                if %errorlevel% equ 0 (
                    aria2c -R --allow-overwrite=true "https://raw.githubusercontent.com/Zerohazard8x/scripts/main/startup/startup_tasks.bat"
                )
            )
        )
        
        findstr /C:"minescule" /C:"mouse" ".\startup_tasks.bat" >nul 2>&1
        if %errorlevel% equ 0 (
            start "" ".\startup_tasks.bat"
            exit
        )
    )
)

cmd /k
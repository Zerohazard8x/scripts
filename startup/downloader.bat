@echo off
if /I not "%SCRIPT_LOWPRIO%"=="1" (
    set "SCRIPT_LOWPRIO=1"
    start "" /b /wait /low /min cmd /c ""%~f0" %*"
    exit %errorlevel%
)
setlocal EnableExtensions

@REM Use Downloads as the temporary staging folder
set "downloadDir=%USERPROFILE%\Downloads"
if not exist "%downloadDir%" mkdir "%downloadDir%"
@REM Remove stale downloaded startup scripts before fetching fresh copies
del /s /q /f "%downloadDir%\common.bat"
del /s /q /f "%downloadDir%\startup_tasks.bat"

@REM Stage optional private import script for common.bat
if exist "import_private.ps1" (
    copy .\import_private.ps1 "%downloadDir%\import_private.ps1"
)

@REM Download common.bat, preferring curl then wget then aria2c
where curl >nul 2>&1
if not errorlevel 1 (
    curl --remote-time -C - -L --output-dir "%downloadDir%" -O "https://raw.githubusercontent.com/Zerohazard8x/scripts/main/startup/common.bat"
) else (
    where wget >nul 2>&1
    if not errorlevel 1 (
        wget -c --timestamping -O "%downloadDir%\common.bat" "https://raw.githubusercontent.com/Zerohazard8x/scripts/main/startup/common.bat"
    ) else (
        where aria2c >nul 2>&1
        if not errorlevel 1 (
            aria2c -R --allow-overwrite=true -d "%downloadDir%" -o "common.bat" "https://raw.githubusercontent.com/Zerohazard8x/scripts/main/startup/common.bat"
        )
    )
)

@REM Verify common.bat marker text before downloading startup_tasks.bat
if exist "%downloadDir%\common.bat" (
    findstr /C:"minescule" /C:"mouse" "%downloadDir%\common.bat" >nul 2>&1
    if not errorlevel 1 (
        @REM -----------------------------------------------------------
        @REM Download startup_tasks.bat with the same tool fallback order
        @REM -----------------------------------------------------------
        where curl >nul 2>&1
        if not errorlevel 1 (
            curl --remote-time -C - -L --output-dir "%downloadDir%" -O "https://raw.githubusercontent.com/Zerohazard8x/scripts/main/startup/startup_tasks.bat"
        ) else (
            where wget >nul 2>&1
            if not errorlevel 1 (
                wget -c --timestamping -O "%downloadDir%\startup_tasks.bat" "https://raw.githubusercontent.com/Zerohazard8x/scripts/main/startup/startup_tasks.bat"
            ) else (
                where aria2c >nul 2>&1
                if not errorlevel 1 (
                    aria2c -R --allow-overwrite=true -d "%downloadDir%" -o "startup_tasks.bat" "https://raw.githubusercontent.com/Zerohazard8x/scripts/main/startup/startup_tasks.bat"
                )
            )
        )

        @REM -----------------------------------------------------------
        @REM Verify startup_tasks.bat marker text before running it
        @REM -----------------------------------------------------------
        findstr /C:"minescule" /C:"mouse" "%downloadDir%\startup_tasks.bat" >nul 2>&1
        if not errorlevel 1 (
            call "%downloadDir%\startup_tasks.bat"
            set "rc=%errorlevel%"
            goto :cleanup
        )
    )
)

@REM Treat missing or unverified downloads as failure
set "rc=1"

:cleanup
@REM Remove temporary downloaded scripts after the chain finishes
del /s /q /f "%downloadDir%\common.bat" 2>nul
del /s /q /f "%downloadDir%\startup_tasks.bat" 2>nul
del /s /q /f "%downloadDir%\tasks.ps1" 2>nul
del /s /q /f "%downloadDir%\import.ps1" 2>nul
del /s /q /f "%downloadDir%\import_private.ps1" 2>nul
endlocal & exit %rc%

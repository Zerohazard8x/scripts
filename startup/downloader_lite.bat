@echo off
@REM Disabled low-priority self-relaunch; keeping it here documents the intended wrapper without opening another console.
@REM if /I not "%SCRIPT_LOWPRIO%"=="1" (
@REM     set "SCRIPT_LOWPRIO=1"
@REM     start "" /b /wait /low /min cmd /c ""%~f0" %*"
@REM     exit %errorlevel%
@REM )
setlocal EnableExtensions

@REM Use the user Downloads directory as a writable staging area shared by each script in the chain.
call :Status "preparing downloads"
set "downloadDir=%USERPROFILE%\Downloads"
if not exist "%downloadDir%" mkdir "%downloadDir%"

@REM set "github=https://raw.githubusercontent.com/Zerohazard8x/scripts/main/startup"
set "github=https://codeberg.org/Zerohazard8x/scripts/raw/branch/main/startup"

@REM Delete stale staged copies so marker validation applies only to the newly downloaded files.
if exist "%downloadDir%\common.bat" del /q /f "%downloadDir%\common.bat"
if exist "%downloadDir%\startup_tasks_lite.bat" del /q /f "%downloadDir%\startup_tasks_lite.bat"

@REM Copy the optional private import beside the downloaded scripts because common.bat resolves it from the staging directory.
if exist "import_private.ps1" (
    copy .\import_private.ps1 "%downloadDir%\import_private.ps1"
)

@REM Fetch common.bat first because startup_tasks_lite.bat calls it later; :Download selects the first available downloader.
call :Status "downloading common.bat"
call :Download common.bat

@REM Require both marker strings before continuing, which rejects missing, empty, or unrelated downloads.
if exist "%downloadDir%\common.bat" (
    findstr /C:"minescule" /C:"mouse" "%downloadDir%\common.bat" >nul 2>&1
    if not errorlevel 1 (
        @REM Gate startup once per inherited environment using the same check as the later task stages.
        if /I not "%SCRIPT_STARTUP_IDLE_DONE%"=="1" (
            findstr /X /L /C:":WaitForIdle" "%downloadDir%\common.bat" >nul 2>&1
            if not errorlevel 1 (
                call "%downloadDir%\common.bat" --wait-for-idle --allow-cancel
                if errorlevel 2 goto :cancelled
            )
            set "SCRIPT_STARTUP_IDLE_DONE=1"
        )

        @REM Fetch the next script only after common.bat passes validation.
        call :Status "downloading startup_tasks_lite.bat"
        call :Download startup_tasks_lite.bat
        
        @REM Validate the second staged script before CALL transfers control while retaining this batch context.
        findstr /C:"minescule" /C:"mouse" "%downloadDir%\startup_tasks_lite.bat" >nul 2>&1
        if not errorlevel 1 (
            call :Status "running startup_task_lite.bat"
            call "%downloadDir%\startup_tasks_lite.bat"
            set "rc=%errorlevel%"
            goto :cleanup
        )
    )
)

echo Download or validation failed; startup tasks cannot continue.

@REM Use a nonzero default result when either download or marker check failed.
set "rc=1"
goto :cleanup

:cancelled
echo Startup tasks cancelled.
set "rc=0"

@REM Centralize cleanup so every success and failure path removes staged scripts before returning.
:cleanup
call :Status "cleaning up"
@REM Remove every staged public or private script on both success and failure.
del /q /f "%downloadDir%\common.bat" 2>nul
del /q /f "%downloadDir%\startup_tasks_lite.bat" 2>nul
del /q /f "%downloadDir%\tasks.ps1" 2>nul
del /q /f "%downloadDir%\import.ps1" 2>nul
del /q /f "%downloadDir%\import_private.ps1" 2>nul
if not "%rc%"=="0" pause
endlocal & exit /b %rc%

@REM Download the named file using curl, wget, or aria2c in that order; %~1 removes any surrounding quotes.
:Download
where curl >nul 2>&1
if not errorlevel 1 (
    curl -f --remote-time -C - -L --output-dir "%downloadDir%" -O "%github%/%~1"
    ) else (
    where wget >nul 2>&1
    if not errorlevel 1 (
        wget -c --timestamping -O "%downloadDir%%~1" "%github%/%~1"
        ) else (
        where aria2c >nul 2>&1
        if not errorlevel 1 (
            aria2c -R --allow-overwrite=true -d "%downloadDir%" -o "%~1" "%github%/%~1"
        ) else echo No supported downloader found for %~1.
    )
)
exit /b

:Status
title Now running: %~1
echo.
echo === Now running: %~1 ===
exit /b 0

powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e

WHERE w32tm
if %ERRORLEVEL% EQU 0 (
    w32tm /config /update
    w32tm /resync
)

@REM @REM Clear clipboard
@REM echo off | clip


@REM registry
WHERE reg
if %ERRORLEVEL% EQU 0 (
    del /s /q /f "%USERPROFILE%\Downloads\tweaks.reg"

    WHERE curl 
    if %ERRORLEVEL% EQU 0 (
        curl --remote-time -C - -Lo "%USERPROFILE%\Downloads\tweaks.reg" https://raw.githubusercontent.com/Zerohazard8x/scripts/main/tweaks.reg
    ) else (
        WHERE wget 
        if %ERRORLEVEL% EQU 0 (
            wget -c --timestamping -O "%USERPROFILE%\Downloads\tweaks.reg" https://raw.githubusercontent.com/Zerohazard8x/scripts/main/tweaks.reg
        )
    )

    reg import "%USERPROFILE%\Downloads\tweaks.reg"
)

@REM reset gpedit
RD /S /Q "%windir%\System32\GroupPolicyUsers"
RD /S /Q "%windir%\System32\GroupPolicy"
gpupdate /force

secedit /configure /cfg %windir%\inf\defltbase.inf /db defltbase.sdb /verbose

@REM password expiry
wmic UserAccount set PasswordExpires=False

@REM reset windows search
taskkill /f /im explorer.exe
net stop "Windows Search"
taskkill /f /im SearchFilterHost.exe
taskkill /f /im SearchHost.exe
taskkill /f /im SearchIndexer.exe
taskkill /f /im SearchProtocolHost.exe
taskkill /f /im ShellExperienceHost.exe
taskkill /f /im StartMenuExperienceHost.exe

@REM windows 11
del "%ProgramData%\Microsoft\Search\Data\Applications\Windows\Windows.db" 
ren "%LocalAppData%\Packages\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\LocalState" LocalState.old

@REM windows 10
del "%ProgramData%\Microsoft\Search\Data\Applications\Windows\Windows.edb"
ren "%LocalAppData%\Packages\Microsoft.Windows.Search_cw5n1h2txyewy\LocalState" LocalState.old

net start "Windows Search"

@REM power options reset
powercfg -restoredefaultschemes

@REM change "turn off the display", etc
:: Plugged in (AC) — NEVER turn off display
powercfg /change monitor-timeout-ac 0

:: Plugged in (AC) — NEVER sleep
powercfg /change standby-timeout-ac 0

:: On battery (DC) — NEVER turn off display
powercfg /change monitor-timeout-dc 0
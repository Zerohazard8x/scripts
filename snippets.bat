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
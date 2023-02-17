del /F *.py

cmd.exe /c powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e
cmd.exe /c powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
cmd.exe /c powercfg /setactive e9a42b02-d5df-448d-aa00-03f14749eb61

sc config "BDESVC" start=auto
sc config "BFE" start=auto
sc config "BluetoothUserService_48486de" start=auto
sc config "BrokerInfrastructure" start=auto
sc config "Dnscache" start=auto
sc config "EntAppSvc" start=auto
sc config "FrameServer" start=auto
sc config "LicenseManager" start=auto
sc config "MacType" start=auto
sc config "NVDisplay.ContainerLocalSystem" start=auto
sc config "OpenVPNServiceInteractive" start=auto
sc config "PNRPsvc" start=auto
sc config "W32Time" start=auto
sc config "WdNisSvc" start=auto
sc config "WlanSvc" start=auto
sc config "audiosrv" start=auto
sc config "iphlpsvc" start=auto
sc config "ndu" start=auto
sc config "p2pimsvc" start=auto
sc config "p2psvc" start=auto
sc config "wscsvc" start=auto

net start "BDESVC"
net start "BFE"
net start "BluetoothUserService_48486de"
net start "BrokerInfrastructure"
net start "Dnscache"
net start "EntAppSvc"
net start "FrameServer"
net start "LicenseManager"
net start "MacType"
net start "NVDisplay.ContainerLocalSystem"
net start "OpenVPNServiceInteractive"
net start "PNRPsvc"
net start "W32Time"
net start "WdNisSvc"
net start "WlanSvc"
net start "audiosrv"
net start "iphlpsvc"
net start "ndu"
net start "p2pimsvc"
net start "p2psvc"
net start "wscsvc"

sc config "AMD External Events Utility" start=demand
sc config "Apple Mobile Device Service" start=demand
sc config "Bonjour Service" start=demand
sc config "CdRomArbiterService" start=demand
sc config "CxAudMsg" start=demand
sc config "DtsApo4Service" start=demand
sc config "EpicOnlineServices" start=demand
sc config "Intel(R) TPM Provisioning Service" start=demand
sc config "Killer Analytics Service" start=demand
sc config "Killer Network Service" start=demand
sc config "Killer Wifi Optimization Service" start=demand
sc config "LGHUBUpdaterService" start=demand
sc config "MBAMService" start=demand
sc config "OverwolfUpdater" start=demand
sc config "Parsec" start=demand
sc config "Razer Game Manager Service 3" start=demand
sc config "RstMwService" start=demand
sc config "RzActionSvc" start=demand
sc config "Steam Client Service" start=demand
sc config "SteelSeriesUpdateService" start=demand
sc config "VBoxSDS" start=demand
sc config "WMIRegistrationService" start=demand
sc config "cplspcon" start=demand
sc config "esifsvc" start=demand
sc config "ibtsiva" start=demand
sc config "igccservice" start=demand
sc config "igfxCUIService2.0.0.0" start=demand
sc config "jhi_service" start=demand
sc config "ss_conn_service" start=demand
sc config "ss_conn_service2" start=demand
sc config "xTendSoftAPService" start=demand
net stop "AMD External Events Utility"
net stop "Apple Mobile Device Service"
net stop "Bonjour Service"
net stop "CdRomArbiterService"
net stop "CxAudMsg"
net stop "DtsApo4Service"
net stop "EpicOnlineServices"
net stop "Intel(R) TPM Provisioning Service"
net stop "KNDBWM"
net stop "Killer Analytics Service"
net stop "Killer Network Service"
net stop "Killer Wifi Optimization Service"
net stop "LGHUBUpdaterService"
net stop "MBAMService"
net stop "OverwolfUpdater"
net stop "Parsec"
net stop "Razer Game Manager Service 3"
net stop "RstMwService"
net stop "RzActionSvc"
net stop "Steam Client Service"
net stop "SteelSeriesUpdateService"
net stop "VBoxSDS"
net stop "WMIRegistrationService"
net stop "cplspcon"
net stop "esifsvc"
net stop "ibtsiva"
net stop "igccservice"
net stop "igfxCUIService2.0.0.0"
net stop "jhi_service"
net stop "ss_conn_service"
net stop "ss_conn_service2"
net stop "xTendSoftAPService"

w32tm /config /update
w32tm /resync

start /low "" "%programdata%\Microsoft\Windows\Start Menu\Programs\Google Drive"
wmic process where name="GoogleDriveFS.exe" CALL setpriority 64

start /low "" "%localappdata%\MEGAsync\MEGAsync.exe"
wmic process where name="MEGASync.exe" CALL setpriority 64

start /low "" "%ProgramFiles(x86)%\MSI Afterburner\MSIAfterburner.exe""
wmic process where name="MSIAfterburner.exe" CALL setpriority 64

start /low "" "%ProgramFiles(x86)%\Overwolf\OverwolfLauncher.exe"
wmic process where name="OverwolfHelper.exe" CALL setpriority 64
wmic process where name="OverwolfHelper64.exe" CALL setpriority 64
wmic process where name="OverwolfLauncher.exe" CALL setpriority 64
wmic process where name="overwolf.exe" CALL setpriority 64

start /low "" "%ProgramFiles%\Process Lasso\ProcessLassoLauncher.exe"
wmic process where name="ProcessLasso.exe" CALL setpriority 64
wmic process where name="ProcessGovernor.exe" CALL setpriority 64
wmic process where name="bitsumsessionagent.exe" CALL setpriority 64

start /low "" "%ProgramFiles(x86)%\RivaTuner Statistics Server\RTSS.exe"
wmic process where name="EncoderServer.exe" CALL setpriority 64
wmic process where name="EncoderServer64.exe" CALL setpriority 64
wmic process where name="RTSSHooksLoader.exe" CALL setpriority 64
wmic process where name="RTSSHooksLoader64.exe" CALL setpriority 64
wmic process where name="RTSS.exe" CALL setpriority 64

start /low "" "%ProgramFiles(x86)%\Razer\Razer Cortex\RazerCortex.exe"
wmic process where name="CortexLauncherService.exe" CALL setpriority 64
wmic process where name="GameManagerService3.exe" CALL setpriority 64
wmic process where name="FPSRunner32.exe" CALL setpriority 64
wmic process where name="FPSRunner64.exe" CALL setpriority 64
wmic process where name="RazerCentralService.exe" CALL setpriority 64
wmic process where name="RazerCortex.Shell.exe" CALL setpriority 64
wmic process where name="RazerCortex.exe" CALL setpriority 64
wmic process where name="Razer Central.exe" CALL setpriority 64

wmic process where name="SteelSeriesGGClient.exe" CALL setpriority 64
wmic process where name="SteelSeriesGG.exe" CALL setpriority 64

start /low "" "%ProgramFiles%\LGHUB\lghub.exe"
wmic process where name="lghub_agent.exe" CALL setpriority 64
wmic process where name="lghub_system_tray.exe" CALL setpriority 64
wmic process where name="lghub.exe" CALL setpriority 64

REM start /low ""
wmic process where name="Agent.exe" CALL setpriority 64
wmic process where name="Battle.net.exe" CALL setpriority 64

REM start /low ""
wmic process where name="EpicGamesLauncher.exe" CALL setpriority 64
wmic process where name="EpicWebHelper.exe" CALL setpriority 64

REM start /low ""
wmic process where name="RiotClientServices.exe" CALL setpriority 64

REM start /low ""
wmic process where name="steam.exe" CALL setpriority 64
wmic process where name="steamwebhelper.exe" CALL setpriority 64

cmd.exe /c "SET DEVMGR_SHOW_NONPRESENT_DEVICES=1"
cmd /c "echo off | clip"
cmd.exe /c control update

powershell.exe -c choco upgrade chocolatey 7zip adb aria2 dos2unix ffmpeg firefox git jq mpv nomacs openvpn powershell rsync scrcpy smplayer unison vlc -y

choco uninstall python2 python -y & choco upgrade python3 -y
aria2c -x16 -s32 -R --allow-overwrite=true https://bootstrap.pypa.io/get-pip.py
python get-pip.py
python -m pip install -U pip
python -m pip install -U wheel

python -m pip install -U git+https://github.com/yt-dlp/yt-dlp.git
python -m pip install -U git+https://github.com/ytdl-org/youtube-dl.git

exit 0
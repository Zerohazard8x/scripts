[CmdletBinding(SupportsShouldProcess = $true)]
param(
	[switch]$IncludeRunningServices
)

# function Set-LowestProcessPriority {
# 	$signature = @"
# using System;
# using System.Runtime.InteropServices;
# public static class NativePriority {
# 	[DllImport("ntdll.dll")]
# 	public static extern int NtSetInformationProcess(IntPtr processHandle, int processInformationClass, ref int processInformation, int processInformationLength);
# }
# "@

# 	try {
# 		Add-Type -TypeDefinition $signature -ErrorAction SilentlyContinue | Out-Null
# 		$proc = [System.Diagnostics.Process]::GetCurrentProcess()
# 		$proc.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::Idle
# 		$proc.PriorityBoostEnabled = $false

# 		$ioPriorityVeryLow = 0
# 		$pagePriorityVeryLow = 1
# 		[void][NativePriority]::NtSetInformationProcess($proc.Handle, 33, [ref]$ioPriorityVeryLow, 4)
# 		[void][NativePriority]::NtSetInformationProcess($proc.Handle, 39, [ref]$pagePriorityVeryLow, 4)
# 	}
# 	catch {
# 		Write-Verbose "Could not force lowest process priority settings: $_"
# 	}
# }

# Set-LowestProcessPriority
function Test-IsAdministrator {
	$currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
	$currentPrincipal = [Security.Principal.WindowsPrincipal] $currentIdentity

	return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Start-ElevatedSelf {
	if ([string]::IsNullOrWhiteSpace($PSCommandPath)) {
		throw 'Cannot relaunch the current script because PSCommandPath is empty.'
	}

	$escapedScriptPath = $PSCommandPath.Replace('"', '\"')
	$argumentLine = '-NoProfile -ExecutionPolicy Bypass -File "{0}"' -f $escapedScriptPath
	if ($args.Count -gt 0) {
		$argumentLine = $argumentLine + ' ' + ($args -join ' ')
	}

	$process = Start-Process -FilePath 'powershell.exe' -ArgumentList $argumentLine -Verb RunAs -Wait -PassThru
	if ($null -ne $process.ExitCode) {
		exit $process.ExitCode
	}

	exit 0
}

function Safe-Invoke {
	param(
		[Parameter(Mandatory)] [string] $Command,
		[string[]] $Args
	)
	if (Get-Command $Command -ErrorAction SilentlyContinue) {
		try {
			& $Command @Args
		}
		catch {
			Write-Warning "Failed: $Command $($Args -join ' '): $_"
		}
	}
	else {
		Write-Warning "Command not found: $Command"
	}
}

function Prompt-YesNoDefaultN {
	param(
		[string]$Message = "App uninstallations? (Y/N)",
		[int]$TimeoutSeconds = 5
	)

	# If there is no interactive console, just default to No.
	if (-not $Host.UI -or -not $Host.UI.RawUI) {
		return $false
	}

	Write-Host "$Message (default: N in $TimeoutSeconds seconds) " -NoNewline

	$deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)

	while ([DateTime]::UtcNow -lt $deadline) {
		if ($Host.UI.RawUI.KeyAvailable) {
			$key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character
			Write-Host ""  # newline after keypress
			return ($key.ToString().ToUpperInvariant() -eq 'Y')
		}
		Start-Sleep -Milliseconds 50
	}

	Write-Host ""  # newline after timeout
	return $false   # default N
}

function Get-ExePathFromServicePath {
	param([string]$PathName)

	if ([string]::IsNullOrWhiteSpace($PathName)) { return $null }

	$expanded = [Environment]::ExpandEnvironmentVariables($PathName.Trim())

	if ($expanded -match '^\s*"([^"]+)"') {
		return $matches[1]
	}

	if ($expanded -match '^\s*([^\s]+)') {
		return $matches[1]
	}

	return $expanded
}

function Test-IsUnderWindowsDirectory {
	param([string]$ExePath)

	if ([string]::IsNullOrWhiteSpace($ExePath)) { return $false }

	$winDir = [Environment]::GetFolderPath('Windows')
	$full = [Environment]::ExpandEnvironmentVariables($ExePath)

	return $full.StartsWith($winDir, [System.StringComparison]::OrdinalIgnoreCase)
}

function Get-ScStartType {
	param([string]$ServiceName)

	$out = sc.exe qc $ServiceName 2>$null
	if (-not $out) { return $null }

	$text = $out | Out-String

	if ($text -match 'DELAYED_AUTO_START') { return 'AutomaticDelayedStart' }
	if ($text -match 'AUTO_START') { return 'Automatic' }
	if ($text -match 'DEMAND_START') { return 'Manual' }
	if ($text -match 'DISABLED') { return 'Disabled' }
	if ($text -match 'BOOT_START') { return 'Boot' }
	if ($text -match 'SYSTEM_START') { return 'System' }

	return 'Unknown'
}

function Invoke-ShouldProcess {
	param(
		[string]$Target,
		[string]$Action
	)

	if ($PSCmdlet) {
		return $PSCmdlet.ShouldProcess($Target, $Action)
	}

	return $true
}

function Get-TaskExecCommandsFromXml {
	param(
		[xml]$Xml
	)

	if (-not $Xml -or -not $Xml.NameTable) {
		return @()
	}

	$ns = [System.Xml.XmlNamespaceManager]::new($Xml.NameTable)
	$ns.AddNamespace('t', 'http://schemas.microsoft.com/windows/2004/02/mit/task')

	$Xml.SelectNodes('//t:Actions/t:Exec/t:Command', $ns) |
	ForEach-Object { $_.'#text' } |
	Where-Object { $_ }
}

function Resolve-TaskCommandPath {
	param(
		[string]$Command
	)

	if (-not $Command) {
		return $null
	}

	$expanded = [Environment]::ExpandEnvironmentVariables($Command.Trim('"'))

	$cmd = Get-Command $expanded -ErrorAction SilentlyContinue
	if ($cmd -and $cmd.Source) {
		return $cmd.Source
	}

	if (Test-Path -LiteralPath $expanded) {
		return (Resolve-Path -LiteralPath $expanded).Path
	}

	return $expanded
}

function Test-MicrosoftSignedFile {
	param(
		[string]$Path
	)

	if (-not $Path -or -not (Test-Path -LiteralPath $Path)) {
		return $false
	}

	$sig = Get-AuthenticodeSignature -LiteralPath $Path -ErrorAction SilentlyContinue

	if (-not $sig -or $sig.Status -ne 'Valid' -or -not $sig.SignerCertificate) {
		return $false
	}

	$sig.SignerCertificate.Subject -match 'CN=Microsoft (Windows|Corporation|Code Signing PCA|Publisher)'
}

function Test-UnderWindows {
	param(
		[string]$Path
	)

	if (-not $Path) {
		return $false
	}

	$expanded = [Environment]::ExpandEnvironmentVariables($Path)

	try {
		$resolved = if (Test-Path -LiteralPath $expanded) {
			(Resolve-Path -LiteralPath $expanded).Path
		}
		else {
			$expanded
		}

		$win = [IO.Path]::GetFullPath($env:WINDIR).TrimEnd('\') + '\'
		$full = [IO.Path]::GetFullPath($resolved)

		return $full.StartsWith($win, [StringComparison]::OrdinalIgnoreCase)
	}
	catch {
		return $false
	}
}

function Parse-PnpUtilBlocks {
	param(
		[string[]]$Lines,
		[hashtable]$Map,
		[string]$RequiredKey
	)

	$items = @()
	$current = [ordered]@{}

	foreach ($line in $Lines) {
		if ($line -match '^\s*$') {
			if ($current[$RequiredKey]) {
				$items += [pscustomobject]$current
			}
			$current = [ordered]@{}
			continue
		}

		foreach ($label in $Map.Keys) {
			if ($line -match "^\s*$([regex]::Escape($label))\s*:\s*(.+)$") {
				$value = $matches[1].Trim()

				if ($label -in 'Instance ID', 'Published Name', 'Driver Name') {
					$value = $value.ToLowerInvariant()
				}

				$current[$Map[$label]] = $value
				break
			}
		}
	}

	# pnputil output does not always end with a blank line
	if ($current[$RequiredKey]) {
		$items += [pscustomobject]$current
	}

	$items
}

function Get-StoreAppPackages {
	# Derived from https://christitus.com/installing-appx-without-msstore/ by LLM
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)][string] $ProductId,
		[ValidateSet('RP', 'WIF', 'Retail', 'Beta')][string] $Ring = 'RP',
		[string] $Lang = 'en-US'
	)

	# Check if installed
	try {
		$existing = Get-AppxPackage -AllUsers | Where-Object {
			($_.Name -like "*$ProductId*") -or
			($_.PackageFamilyName -like "*$ProductId*")
		}
	}
	catch {
		Write-Warning "Error checking existing packages: $_"
		$existing = $null
	}

	if ($existing) {
		Write-Verbose "Package matching '$ProductId' already installed (skipping)."
		return "Already installed: $ProductId"
	}

	# 1. Try winget first
	Write-Verbose "Attempting winget install for $ProductId"
	if (Get-Command winget -ErrorAction SilentlyContinue) {
		try {
			& winget install --id $ProductId --source msstore `
				--accept-source-agreements --accept-package-agreements
			if ($LASTEXITCODE -in 0, -1978335189) {
				Write-Verbose "Winget install succeeded for $ProductId"
				return "Installed via winget: $ProductId"
			}
			Write-Warning "winget exited with code $LASTEXITCODE; falling back to API download."
		}
		catch {
			Write-Warning "winget install error: $_"
		}
	}
	else {
		Write-Verbose "winget not available; skipping to API download."
	}

	# 2. Determine preferred architecture
	$is64 = [Environment]::Is64BitOperatingSystem
	if ($is64) {
		$preferredArch = 'x64'; $fallbackArch = 'x86'
	}
	else {
		$preferredArch = 'x86'; $fallbackArch = 'x64'
	}
	Write-Verbose "OS is $([Environment]::OSVersion); preferring $preferredArch"

	# 3. Set up download directory
	$apiUrl = 'https://store.rg-adguard.net/api/GetFiles'
	$productUrl = "https://www.microsoft.com/store/productId/$ProductId"
	$downloadDir = Join-Path $env:TEMP "StoreDownloads\$ProductId"
	if (-not (Test-Path $downloadDir)) {
		New-Item -Path $downloadDir -ItemType Directory -Force | Out-Null
	}

	# 4. Query RG-AdGuard API
	$body = @{ type = 'url'; url = $productUrl; ring = $Ring; lang = $Lang }
	try {
		$response = Invoke-RestMethod -Method Post -Uri $apiUrl `
			-ContentType 'application/x-www-form-urlencoded' `
			-Body $body
	}
	catch {
		Write-Warning "RG-AdGuard API call failed (continuing): $_"
		return
	}

	# 5. Parse all candidate URLs
	$pattern = '<tr style.*?<a href="(?<url>[^"]+)"[^>]*>(?<name>[^<]+)</a>'
	$matches = [regex]::Matches($response, $pattern)

	# 6. Filter into buckets
	$byArch = @{ Preferred = @(); Neutral = @(); Fallback = @() }
	foreach ($m in $matches) {
		$url = $m.Groups['url'].Value
		$name = $m.Groups['name'].Value
		if ($name -match '_(x86|x64|neutral).*?\.(appx|appxbundle)$') {
			switch -Regex ($name) {
				"_$preferredArch" { $byArch.Preferred += @{ Name = $name; Url = $url }; break }
				"_neutral" { $byArch.Neutral += @{ Name = $name; Url = $url }; break }
				"_$fallbackArch" { $byArch.Fallback += @{ Name = $name; Url = $url }; break }
			}
		}
	}

	# 7. Choose the first available in preference order
	$chosen = $byArch.Preferred + $byArch.Neutral + $byArch.Fallback
	if (-not $chosen) {
		Write-Warning "No suitable package found for $ProductId"
		return
	}
	$pkgInfo = $chosen[0]
	$outFile = Join-Path $downloadDir $pkgInfo.Name

	# 8. Download chosen package if not already present
	if (-not (Test-Path $outFile)) {
		try {
			Write-Verbose "Downloading $($pkgInfo.Name)"
			Invoke-WebRequest -Uri $pkgInfo.Url -OutFile $outFile -UseBasicParsing
		}
		catch {
			Write-Warning "Download failed for $($pkgInfo.Name) (continuing): $_"
			return
		}
	}

	# 9. Install the .appx/.appxbundle
	try {
		Write-Verbose "Installing $outFile"
		Add-AppxPackage -Path $outFile -ForceApplicationShutdown -Confirm:$false
		Write-Verbose "Installed $($pkgInfo.Name) successfully"
	}
	catch {
		Write-Warning "Installation failed for $($pkgInfo.Name): $_"
	}

	# 10. Cleanup
	try {
		Write-Verbose "Removing directory $downloadDir"
		Remove-Item -Path $downloadDir -Recurse -Force -ErrorAction SilentlyContinue
		Write-Verbose "Cleanup complete"
	}
	catch {
		Write-Warning "Cleanup error: $_"
	}

	return "Installed $($pkgInfo.Name) and cleaned up temporary files."
}

# Ensure the script runs with administrative privileges. 
# If it was launched from a non-elevated scheduled task, ask Windows for elevation instead of failing.
if (-not (Test-IsAdministrator)) {
	Write-Warning 'Requesting administrator approval for tasks.ps1...'
	try {
		Start-ElevatedSelf @args
	}
	catch {
		Write-Error "Could not relaunch tasks.ps1 as administrator: $_"
		exit 1
	}
}

# --- Error handling defaults ---
$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'
$PSDefaultParameterValues['*:ErrorAction'] = 'Continue'

Write-Host ""

# set processes to lowest priority
$DO_SET_LOW_PRIORITY = Prompt-YesNoDefaultN -Message "Set processes to lowest priority? (Y/N)" -TimeoutSeconds 5
if ($DO_SET_LOW_PRIORITY) {
	# set processes to lowest priority
	$processNames = @(
		'MSIAfterburner',
		'HWiNFO64',
		'RTSS',
		'RTSSHooksLoader64',
		'steam',
		'steamwebhelper',
		'RiotClientServices',
		'EpicGamesLauncher',
		'EpicWebHelper',
		'RazerCortex',
		'SteelSeriesGG',
		'OverwolfLauncher',
		'Overwolf',
		'FanControl',
		'voicemeeterpro_x64',
		'voicemeeter8x64',
		'voicemeeterpro',
		'voicemeeter8',
		'thunderbird',
		'OneDrive',
		'OneDrive.Sync.Service',
		'MEGAsync'
	)

	$packages = @(
		'Microsoft.GamingApp'
		'Microsoft.WindowsStore'
	)

	foreach ($package in $packages) {
		Get-AppxPackage $package -ErrorAction SilentlyContinue |
		ForEach-Object {
			if ($_.InstallLocation) {
				$processNames += Get-ChildItem $_.InstallLocation -Filter *.exe -File |
					ForEach-Object BaseName
			}
		}
	}

	foreach ($name in $processNames) {
		Get-Process -Name $name -ErrorAction SilentlyContinue |
		ForEach-Object {
			try {
				$_.PriorityClass = 'Idle'
			}
			catch {
				# Ignore processes that cannot be changed
			}
		}
		reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$name.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 1 /f
		reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$name.exe\PerfOptions" /v IoPriority /t REG_DWORD /d 0 /f
		reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$name.exe\PerfOptions" /v PagePriority /t REG_DWORD /d 1 /f
	}
}

# set non-stock services to manual start
$DO_SET_NONSTOCK_SERVICES = Prompt-YesNoDefaultN -Message "Set non-stock services to Manual startup? (Y/N)" -TimeoutSeconds 5

if ($DO_SET_NONSTOCK_SERVICES) {
	$services = Get-CimInstance Win32_Service | ForEach-Object {
		$exePath = Get-ExePathFromServicePath $_.PathName
		$scType = Get-ScStartType $_.Name

		[PSCustomObject]@{
			Name         = $_.Name
			DisplayName  = $_.DisplayName
			State        = $_.State
			ServiceType  = $_.ServiceType
			PathName     = $_.PathName
			ExePath      = $exePath
			Win32Start   = $_.StartMode
			ActualStart  = $scType
			UnderWindows = Test-IsUnderWindowsDirectory $exePath
		}
	}

	$nonSystemServices = $services | Where-Object {
		$_.ServiceType -notmatch 'Kernel Driver|File System Driver' -and
		-not $_.UnderWindows
	}

	if ($nonSystemServices) {
		foreach ($svc in $nonSystemServices) {
			if ($PSCmdlet.ShouldProcess($svc.Name, 'Set startup type to Manual')) {
				Set-Service -Name $svc.Name -StartupType Manual
			}

			# priority
			$exeName = [IO.Path]::GetFileName($svc.ExePath)
			reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$exeName\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 1 /f
			reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$exeName\PerfOptions" /v IoPriority /t REG_DWORD /d 0 /f
			reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$exeName\PerfOptions" /v PagePriority /t REG_DWORD /d 1 /f
		}
	}
}
else {
	Write-Host "Skipping non-stock service startup changes."
}

# scheduled tasks: disable non-Microsoft Exec tasks
$DO_SCHEDULED_TASKS = Prompt-YesNoDefaultN -Message "Disable non-Microsoft scheduled tasks? (Y/N)" -TimeoutSeconds 5
if ($DO_SCHEDULED_TASKS) {
	$ScheduledTaskMode = 'Disable' # Report | Disable # | Unregister

	$scheduledTasks = Get-ScheduledTask

	$nonMicrosoftTasks = foreach ($task in $scheduledTasks) {
		if ($task.TaskPath -like '\Microsoft\*') {
			continue
		}

		$xmlText = $null
		$xml = $null

		try {
			$xmlText = Export-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -ErrorAction Stop
			$xml = [xml]$xmlText
		}
		catch {
			Write-Warning "Could not export scheduled task: $($task.TaskPath)$($task.TaskName): $_"
			continue
		}

		$author = $xml.Task.RegistrationInfo.Author

		if ($author -match '^\s*(Microsoft|Microsoft Corporation|Windows)\b') {
			continue
		}

		$commands = @(Get-TaskExecCommandsFromXml -Xml $xml)

		if (-not $commands) {
			continue
		}

		$resolvedCommands = @($commands | ForEach-Object { Resolve-TaskCommandPath $_ })

		$hasWindowsCommand = $false
		$hasMicrosoftSignedCommand = $false

		foreach ($cmdPath in $resolvedCommands) {
			if (Test-UnderWindows -Path $cmdPath) {
				$hasWindowsCommand = $true
			}

			if (Test-MicrosoftSignedFile -Path $cmdPath) {
				$hasMicrosoftSignedCommand = $true
			}
		}

		if ($hasWindowsCommand -or $hasMicrosoftSignedCommand) {
			continue
		}

		[pscustomobject]@{
			TaskName = $task.TaskName
			TaskPath = $task.TaskPath
			State    = $task.State
			Author   = $author
			Command  = ($resolvedCommands -join ' | ')
			Task     = $task
		}
	}

	if (-not $nonMicrosoftTasks) {
		Write-Host "No non-Microsoft scheduled task candidates found."
	}
	else {
		$nonMicrosoftTasks |
		Select-Object TaskPath, TaskName, State, Author, Command |
		Format-Table -AutoSize

		foreach ($item in $nonMicrosoftTasks) {
			$fullName = "$($item.TaskPath)$($item.TaskName)"

			switch ($ScheduledTaskMode) {
				'Report' {
					Write-Host "Candidate scheduled task: $fullName"
				}

				'Disable' {
					if (Invoke-ShouldProcess -Target $fullName -Action 'Disable scheduled task') {
						Disable-ScheduledTask -TaskName $item.TaskName -TaskPath $item.TaskPath | Out-Null
					}
				}

				# 'Unregister' {
				# 	if (Invoke-ShouldProcess -Target $fullName -Action 'Unregister scheduled task') {
				# 		Unregister-ScheduledTask -TaskName $item.TaskName -TaskPath $item.TaskPath -Confirm:$false
				# 	}
				# }
			}
		}
	}
}

# remove disconnected devices as in device manager
$DO_REMOVE_DRIVERS = Prompt-YesNoDefaultN -Message "Remove disconnected devices and non-Microsoft drivers? (Y/N)" -TimeoutSeconds 5

if ($DO_REMOVE_DRIVERS) {
	$devices = Parse-PnpUtilBlocks `
		-Lines (pnputil /enum-devices /disconnected /drivers) `
		-RequiredKey InstanceId `
		-Map @{
		'Instance ID'        = 'InstanceId'
		'Device Description' = 'Description'
		'Driver Name'        = 'DriverName'
	}

	$drivers = Parse-PnpUtilBlocks `
		-Lines (pnputil /enum-drivers) `
		-RequiredKey PublishedName `
		-Map @{
		'Published Name'          = 'PublishedName'
		'Provider Name'           = 'ProviderName'
		'Driver Package Provider' = 'ProviderName'
	}

	$driverByInf = @{}
	foreach ($driver in $drivers) {
		$driverByInf[$driver.PublishedName] = $driver
	}

	if (-not $devices) {
		Write-Host "No disconnected devices found."
	}
	else {
		foreach ($device in $devices) {
			Write-Host "`nRemoving device: $($device.Description)"
			pnputil /remove-device "$($device.InstanceId)"

			$driver = $driverByInf[$device.DriverName]

			# Only exact "Microsoft" is treated as protected
			if ($driver -and $driver.ProviderName -notmatch '^\s*Microsoft\s*$') {
				Write-Host "Deleting driver package: $($device.DriverName)"
				pnputil /delete-driver "$($device.DriverName)" /uninstall
			}
			elseif ($device.DriverName) {
				Write-Host "Keeping driver package: $($device.DriverName)"
			}
		}
	}
}
else {
	Write-Host "Skipping disconnected device and driver removal."
}

$DO_UNINSTALL = Prompt-YesNoDefaultN -TimeoutSeconds 5

try {
	if ($DO_UNINSTALL) {
		$appsToRemove = @(
			# 3D / legacy inbox apps
			"3D Viewer", "Microsoft 3D Viewer",
			"Paint 3D",
			"Print 3D",

			# Clipchamp naming variants
			"Clipchamp", "Microsoft Clipchamp", "Clipchamp - Video Editor",

			# Feedback Hub
			"Feedback Hub", "Windows Feedback Hub",

			# HP OEM helper
			"HPHelp", "HP Help", "HP Help and Support",

			# Wallet / Pay
			"Microsoft Pay", "Microsoft Wallet", "Wallet",

			# People
			"Microsoft People", "People",

			# Photos
			"Microsoft Photos", "Photos", "Microsoft Photos Legacy",

			# Solitaire
			"Microsoft Solitaire Collection", "Solitaire & Casual Games",

			# Sticky Notes
			"Microsoft Sticky Notes", "Sticky Notes",

			# Tips (often “Tips”, sometimes under “Microsoft Tips”)
			"Microsoft Tips", "Tips",

			# Mixed Reality
			"Mixed Reality Portal", "Windows Mixed Reality",

			# Movies & TV
			"Movies & TV", "Films & TV",

			# News
			"News", "Microsoft News",

			"OneNote for Windows 10",

			# Power Automate
			"Power Automate", "Power Automate Desktop",

			# Skype
			"Skype",

			# Maps
			"Windows Maps", "Maps",

			# Media Player / audio-video app branding drift
			"Media Player", "Windows Media Player", "Groove Music",

			# Voice recorder naming drift (Win10 commonly “Windows Voice Recorder”)
			"Sound Recorder", "Windows Voice Recorder",

			# Family Safety=
			"Family", "Microsoft Family Safety",

			# Quick Assist
			"Quick Assist",

			# Outlook
			"Outlook", "Outlook for Windows", "Outlook for Windows (New)", "Microsoft Outlook",

			# Translator
			"Translator", "Microsoft Translator",

			# Teams
			"Microsoft Teams", "Microsoft Teams (work or school)", "Microsoft Teams (free)", "Microsoft Teams classic"
		)

		foreach ($app in $appsToRemove) {
			Safe-Invoke -Command "winget" -Args @("uninstall", "--name", $app, "--exact")
		}

		$idsToRemove = @(
			"9P7BP5VNWKX5", "9PDJDJS743XF", "9WZDNCRFHWKN", "9nblggh5r558"
		)

		foreach ($app in $idsToRemove) {
			Safe-Invoke -Command "winget" -Args @("uninstall", "--id", $app)
		}
	}
	else {
		Write-Host "Skipping app uninstallations."
	}
}
catch {
	Write-Warning "Error during bulk uninstall: $_"
}

# # chocolatey
# try {
# 	if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
# 		Write-Host "Chocolatey not detected. Installing..."

# 		Remove-Item -Force -r -v C:\ProgramData\chocolatey
# 		[Net.ServicePointManager]::SecurityProtocol =
# 		[Net.ServicePointManager]::SecurityProtocol -bor 3072
# 		Invoke-Expression ((New-Object System.Net.WebClient).DownloadString(
# 				'https://community.chocolatey.org/install.ps1'))
# 	}
# }
# catch {
# 	Write-Warning "Chocolatey install failed (continuing): $_"
# }

$DO_INSTALL_MAYBEREQUIRED_APPS = Prompt-YesNoDefaultN -Message "Install apps which might break Windows if removed? (Y/N)" -TimeoutSeconds 5
if ($DO_INSTALL_MAYBEREQUIRED_APPS) {
	Get-StoreAppPackages -ProductId '9WZDNCRFJBMP' # Microsoft Store

	# codecs
	Get-StoreAppPackages -ProductId '9MVZQVXJBQ9V' # AV1
	Get-StoreAppPackages -ProductId '9N4D0MSMP0PT' # VP9
	Get-StoreAppPackages -ProductId '9n4wgh0z6vhq' # HEVC (OEM)
	Get-StoreAppPackages -ProductId '9n95q1zzpmh4' # MPEG-2
	Get-StoreAppPackages -ProductId '9nmzlz57r3t7' # HEVC
	Get-StoreAppPackages -ProductId '9NVJQJBDKN97' # Dolby Plus (OEM)
	Get-StoreAppPackages -ProductId '9PB0TRCNRHFX' # AVC

	Get-StoreAppPackages -ProductId '9N5TDP8VCMHS' # Web Media
	Get-StoreAppPackages -ProductId '9NCTDW2W1BH8' # Raw Image
	Get-StoreAppPackages -ProductId '9PG2DK419DRG' # WebP Image
	Get-StoreAppPackages -ProductId '9PMMSR1CGPWG' # HEIF Image

	# Get-StoreAppPackages -ProductId '9NHT9RB2F4HD' # copilot
	# Get-StoreAppPackages -ProductId '9p7bp5vnwkx5' # microsoft news
	# Get-StoreAppPackages -ProductId '9wzdncrd29v9' # m365 copilot
	# Get-StoreAppPackages -ProductId '9wzdncrfj3q2' # msn weather
	Get-StoreAppPackages -ProductId '9MSMLRH6LZF3'
	Get-StoreAppPackages -ProductId '9mssgkg348sp' # Windows Web Experience Pack (Widgets / Web Experience Pack).
	Get-StoreAppPackages -ProductId '9mv0b5hzvk9z' # Xbox (the Xbox app / Xbox PC app).
	Get-StoreAppPackages -ProductId '9MWPM2CQNLHN'
	Get-StoreAppPackages -ProductId '9MZ95KL8MR0L'
	Get-StoreAppPackages -ProductId '9N0DX20HK701'
	Get-StoreAppPackages -ProductId '9N3RK8ZV2ZR8'
	Get-StoreAppPackages -ProductId '9N8MHTPHNGVV'
	Get-StoreAppPackages -ProductId '9nblggh1j27h' # Xbox Console Companion (Beta / Console Companion).
	Get-StoreAppPackages -ProductId '9NBLGGH4NNS1'
	Get-StoreAppPackages -ProductId '9NC184TX90WZ'
	Get-StoreAppPackages -ProductId '9nknc0ld5nn6' # Xbox TCUI.
	Get-StoreAppPackages -ProductId '9NMPJ99VJBWV'
	Get-StoreAppPackages -ProductId '9NTXGKQ8P7N0'
	Get-StoreAppPackages -ProductId '9NZBF4GT040C'
	Get-StoreAppPackages -ProductId '9nzkpstsnw4p' # Xbox Game Bar (also named Xbox Gaming Overlay / Game Bar).
	Get-StoreAppPackages -ProductId '9p086nhdnb9w' # Xbox Game Speech Window (Microsoft.XboxSpeechToTextOverlay).
	Get-StoreAppPackages -ProductId '9P9TQF7MRM4R' # Windows Camera.
	Get-StoreAppPackages -ProductId '9PC1H9VN18CM'
	Get-StoreAppPackages -ProductId '9PCFS5B6T72H'
	Get-StoreAppPackages -ProductId '9PCSD6N03BKV'
	Get-StoreAppPackages -ProductId '9PKDZBMV1H3T'
	Get-StoreAppPackages -ProductId '9PLJQ12FQ3CV'
	Get-StoreAppPackages -ProductId '9wzdncrd1hkw' # Xbox Identity Provider.
	Get-StoreAppPackages -ProductId '9wzdncrfhvn5' # Windows Calculator.
	Get-StoreAppPackages -ProductId '9wzdncrfj1p3' # OneDrive.
	Get-StoreAppPackages -ProductId '9wzdncrfj3pr'
	Get-StoreAppPackages -ProductId '9wzdncrfjbbg' # Windows Camera.

	# https://github.com/SimonCropp/WinDebloat

	Safe-Invoke -Command "winget" -Args @("install", "Microsoft.PowerShell", "--accept-source-agreements", "--accept-package-agreements")
}

# winget upgrade
Safe-Invoke -Command "winget" -Args @("upgrade", "--all", "--accept-source-agreements", "--accept-package-agreements")
# Safe-Invoke -Command "winget" -Args @("upgrade","--all","--accept-source-agreements","--accept-package-agreements","--include-unknown")

# configure dns
$DO_CONFIGURE_DNS = Prompt-YesNoDefaultN `
	-Message "Configure DNS? (Y/N)" `
	-TimeoutSeconds 5

if ($DO_CONFIGURE_DNS) {
	try {
		# Set DNS servers on all "Up" adapters
		$ifaces = Get-NetAdapter | Where-Object Status -eq "Up"
		$ipv4 = @("1.1.1.2", "1.0.0.2")
		$ipv6 = @("2606:4700:4700::1112", "2606:4700:4700::1002")

		foreach ($i in $ifaces) {
			Set-DnsClientServerAddress -InterfaceIndex $i.ifIndex -ServerAddresses ($ipv4 + $ipv6)
		}

		foreach ($i in $ifaces) {
			foreach ($ip in $ipv4) {
				$p = "HKLM:\System\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\$($i.InterfaceGuid)\DohInterfaceSettings\Doh\$ip"
				New-Item -Path $p -Force | Out-Null
				New-ItemProperty -Path $p -Name "DohFlags" -Value 1 -PropertyType QWord -Force | Out-Null
			}

			foreach ($ip in $ipv6) {
				$p = "HKLM:\System\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\$($i.InterfaceGuid)\DohInterfaceSettings\Doh6\$ip"
				New-Item -Path $p -Force | Out-Null
				New-ItemProperty -Path $p -Name "DohFlags" -Value 1 -PropertyType QWord -Force | Out-Null
			}
		}
	}
	catch {
		Write-Warning "DNS/DoH configuration failed (continuing): $_"
	}
}
else {
	Write-Host "Skipping DNS configuration."
}

# # Windows Defender
# try {
# 	Set-MpPreference -DisableRealtimeMonitoring $false
# 	Set-MpPreference -EnableControlledFolderAccess Disabled
# }
# catch {
# 	Write-Warning "Error: $_"
# }

# Windows Update
try {
	if (Get-Command Get-WindowsUpdate -ErrorAction SilentlyContinue) {
		Get-WindowsUpdate -Download -AcceptAll -Confirm:$false
		Get-WindowsUpdate -Install  -AcceptAll -IgnoreReboot -Confirm:$false
	}
	else {
		Install-Module PSWindowsUpdate -Force -Confirm:$false
	}
}
catch {
	Write-Warning "Error installing or running Windows updates: $_"
}

if (-not (Get-Command Get-WindowsUpdate -ErrorAction SilentlyContinue)) {
	try {
		if (Get-Command Get-WindowsUpdate -ErrorAction SilentlyContinue) {
			Get-WindowsUpdate -Download -AcceptAll -Confirm:$false
			Get-WindowsUpdate -Install  -AcceptAll -IgnoreReboot -Confirm:$false
		}
		else {
			# PSWindowsUpdate module is still not available
			# use the wuauclt command as a fallback
			wuauclt /detectnow
			wuauclt /updatenow
		}
	}
	catch {
		Write-Warning "Error: $_"
	}
}

# # unhide power settings
# # Get Power Settings entries and add/set 'Attributes' to 2 to unhide
# $PowerCfg = (Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings' -Recurse).Name -notmatch '\bDefaultPowerSchemeValues|(\\[0-9]|\b255)$'
# foreach ($item in $PowerCfg) {
# 	Set-ItemProperty -Path $item.Replace('HKEY_LOCAL_MACHINE', 'HKLM:') -Name 'Attributes' -Value 2 -Force
# }

exit
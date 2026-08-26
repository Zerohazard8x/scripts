[CmdletBinding(SupportsShouldProcess = $true)]
param(
	[switch]$IncludeRunningServices,
	[string]$WingetExe = $env:STARTUP_WINGET_EXE,
	[switch]$AdminPhase
)

$VerbosePreference = 'Continue'
$ProgressPreference = 'Continue'

function Write-Section([string]$Name) {
	$Host.UI.RawUI.WindowTitle = "Now running: $Name"
	Write-Host "`n=== Now running: $Name ==="
}

Write-Section "PowerShell setup"

# Reuse the initiating user's resolved winget executable because Administrator Protection elevation can change PATH and app-execution aliases.
if ($WingetExe -and (Test-Path -LiteralPath $WingetExe)) {
	Set-Alias -Name winget -Value $WingetExe -Scope Script
}

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

# Return whether the current Windows identity belongs to the built-in Administrators group.
function Test-IsAdministrator {
	$currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
	$currentPrincipal = [Security.Principal.WindowsPrincipal] $currentIdentity

	return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Relaunch this script once with UAC, forwarding the resolved winget path and original arguments.
function Start-ElevatedSelf {
	if ([string]::IsNullOrWhiteSpace($PSCommandPath)) {
		throw 'Cannot relaunch the current script because PSCommandPath is empty.'
	}

	$escapedScriptPath = $PSCommandPath.Replace('"', '\"')
	$argumentLine = '-NoProfile -ExecutionPolicy Bypass -File "{0}"' -f $escapedScriptPath
	if ($WingetExe) {
		$escapedWingetExe = $WingetExe.Replace('"', '\"')
		$argumentLine += ' -WingetExe "{0}"' -f $escapedWingetExe
	}

	if ($IncludeRunningServices) { $argumentLine += ' -IncludeRunningServices' }

	if ($args.Count -gt 0) {
		$argumentLine = $argumentLine + ' ' + ($args -join ' ')
	}

	Write-Section "waiting for elevated maintenance"
	Write-Host "Requesting administrator approval; this window will wait while maintenance runs in the elevated window."
	$process = Start-Process -FilePath 'powershell.exe' -ArgumentList $argumentLine -Verb RunAs -WindowStyle Minimized -PassThru
	
	$process.WaitForExit()
	exit $process.ExitCode
}

# Invoke an optional external command without terminating the remaining maintenance work on absence or failure.
function Safe-Invoke {
	param(
		[Parameter(Mandatory)] [string] $Command,
		[string[]] $Args
	)
	if (Get-Command $Command -ErrorAction SilentlyContinue) {
		try {
			Write-Host "Running: $Command $($Args -join ' ')"
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

# Read Y interactively until the deadline and choose No for timeout or a noninteractive host.
function Prompt-YesNoDefaultN {
	param(
		[string]$Message = "App uninstallations? (Y/N)",
		[int]$TimeoutSeconds = 5
	)

	# Return the safe default immediately when RawUI is unavailable, such as under a scheduled task.
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

# Extract the executable token from a service command line after expanding environment variables.
function Get-ExePathFromServicePath {
	param([string]$PathName)

	if ([string]::IsNullOrWhiteSpace($PathName)) { return $null }

	$expanded = [Environment]::ExpandEnvironmentVariables($PathName.Trim())

	if ($expanded -match '^\s*"([^"]+)"') {
		return $matches[1]
	}

	if ($expanded -match '^\s*(.+?\.exe)(?:\s|$)') {
		return $matches[1]
	}

	if ($expanded -match '^\s*([^\s]+)') {
		return $matches[1]
	}

	return $expanded
}

# Classify a service executable by a case-insensitive prefix comparison with the Windows directory.
function Test-IsUnderWindowsDirectory {
	param([string]$ExePath)

	if ([string]::IsNullOrWhiteSpace($ExePath)) { return $false }

	$winDir = [Environment]::GetFolderPath('Windows')
	$full = [Environment]::ExpandEnvironmentVariables($ExePath)

	return $full.StartsWith(($winDir + '\'), [System.StringComparison]::OrdinalIgnoreCase)
}

# Route destructive actions through the script cmdlet ShouldProcess contract when available.
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

# Read Exec action command nodes with the Task Scheduler XML namespace explicitly registered.
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

# Expand and resolve a scheduled-task command so path and signature checks inspect the actual executable.
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

# Accept only an existing file with a valid Authenticode signature issued under recognized Microsoft subjects.
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

# Resolve a path defensively and test whether it is contained beneath the Windows directory.
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

# Convert blank-line-delimited pnputil text into normalized objects using caller-supplied field mappings.
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

	# Flush the final record explicitly because pnputil does not always terminate its output with a blank separator.
	if ($current[$RequiredKey]) {
		$items += [pscustomobject]$current
	}

	$items
}

# Install a Store product through winget first, then fall back to direct package discovery and Appx installation.
function Get-StoreAppPackages {
	# Fallback Store-package retrieval adapted from https://christitus.com/installing-appx-without-msstore/ by LLM; winget remains the preferred path.
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)][string] $ProductId,
		[ValidateSet('RP', 'WIF', 'Retail', 'Beta')][string] $Ring = 'RP',
		[string] $Lang = 'en-US'
	)

	# Avoid a duplicate installation by checking both package name and package-family name first.
	try {
		$existing = Get-AppxPackage | Where-Object {
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

	# Try winget first because it handles Store acquisition, dependencies, and package registration.
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

	# Prefer the native OS architecture and retain the other architecture only as a compatibility fallback.
	$is64 = [Environment]::Is64BitOperatingSystem
	if ($is64) {
		$preferredArch = 'x64'; $fallbackArch = 'x86'
	}
	else {
		$preferredArch = 'x86'; $fallbackArch = 'x64'
	}
	Write-Verbose "OS is $([Environment]::OSVersion); preferring $preferredArch"

	# Create an isolated temporary directory so downloaded Appx artifacts can be removed as one unit.
	$apiUrl = 'https://store.rg-adguard.net/api/GetFiles'
	$productUrl = "https://www.microsoft.com/store/productId/$ProductId"
	$downloadDir = Join-Path $env:TEMP "StoreDownloads\$ProductId"
	if (-not (Test-Path $downloadDir)) {
		New-Item -Path $downloadDir -ItemType Directory -Force | Out-Null
	}

	# Query the package-link service only after winget fails, posting the Store product identifier and release ring.
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

	# Extract direct package URLs from the returned HTML before applying architecture and package-type filters.
	$pattern = '<tr style.*?<a href="(?<url>[^"]+)"[^>]*>(?<name>[^<]+)</a>'
	$matches = [regex]::Matches($response, $pattern)

	# Separate bundles, architecture-specific packages, and dependencies so selection order is deterministic.
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

	# Prefer a bundle, then the native architecture, then the fallback architecture.
	$chosen = $byArch.Preferred + $byArch.Neutral + $byArch.Fallback
	if (-not $chosen) {
		Write-Warning "No suitable package found for $ProductId"
		return
	}
	$pkgInfo = $chosen[0]
	$outFile = Join-Path $downloadDir $pkgInfo.Name

	# Reuse an existing artifact by filename; otherwise download exactly the selected package URL.
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

	# Register the selected Appx artifact after download rather than executing it as a conventional installer.
	try {
		Write-Verbose "Installing $outFile"
		Add-AppxPackage -Path $outFile -ForceApplicationShutdown -Confirm:$false
		Write-Verbose "Installed $($pkgInfo.Name) successfully"
	}
	catch {
		Write-Warning "Installation failed for $($pkgInfo.Name): $_"
	}

	# Remove the temporary package directory after installation to avoid retaining stale Store artifacts.
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

function Invoke-UserPhase {
	Write-Section "app removal"
	$DO_UNINSTALL = Prompt-YesNoDefaultN -TimeoutSeconds 5

	try {
		if ($DO_UNINSTALL) {
			Write-Host "Checking installed apps and removing requested matches..."
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

	Write-Section "app installation and upgrades"
	$DO_INSTALL_MAYBEREQUIRED_APPS = Prompt-YesNoDefaultN -Message "Install apps which might break Windows if removed? (Y/N)" -TimeoutSeconds 5
	if ($DO_INSTALL_MAYBEREQUIRED_APPS) {
		Write-Host "Checking and installing optional Store apps..."
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
	else {
		Write-Host "Skipping optional Store app installation."
	}

	# winget upgrade
	Write-Host "Checking all winget packages for upgrades..."
	Safe-Invoke -Command "winget" -Args @("upgrade", "--all", "--accept-source-agreements", "--accept-package-agreements", "--silent", "--disable-interactivity")
	Write-Host "winget upgrade processing finished; continuing startup tasks."
	# Safe-Invoke -Command "winget" -Args @("upgrade","--all","--accept-source-agreements","--accept-package-agreements","--include-unknown")
}

if (-not ("MemoryLimitedLauncher" -as [type])) {
	Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;

public static class MemoryLimitedLauncher
{
	private const uint JOB_OBJECT_LIMIT_JOB_MEMORY = 0x00000200;

	private const int JobObjectExtendedLimitInformation = 9;

	private const uint CREATE_SUSPENDED = 0x00000004;

	private const uint PROCESS_TERMINATE = 0x0001;
	private const uint PROCESS_SET_QUOTA = 0x0100;
	private const uint PROCESS_QUERY_LIMITED_INFORMATION = 0x1000;

	/*
		Keep handles open for the lifetime of this PowerShell process.
	*/
	private static readonly Dictionary<string, IntPtr> Jobs =
		new Dictionary<string, IntPtr>(
			StringComparer.OrdinalIgnoreCase
		);

	[StructLayout(LayoutKind.Sequential)]
	private struct JOBOBJECT_BASIC_LIMIT_INFORMATION
	{
		public long PerProcessUserTimeLimit;
		public long PerJobUserTimeLimit;

		public uint LimitFlags;

		public UIntPtr MinimumWorkingSetSize;
		public UIntPtr MaximumWorkingSetSize;

		public uint ActiveProcessLimit;

		public UIntPtr Affinity;

		public uint PriorityClass;
		public uint SchedulingClass;
	}

	[StructLayout(LayoutKind.Sequential)]
	private struct IO_COUNTERS
	{
		public ulong ReadOperationCount;
		public ulong WriteOperationCount;
		public ulong OtherOperationCount;

		public ulong ReadTransferCount;
		public ulong WriteTransferCount;
		public ulong OtherTransferCount;
	}

	[StructLayout(LayoutKind.Sequential)]
	private struct JOBOBJECT_EXTENDED_LIMIT_INFORMATION
	{
		public JOBOBJECT_BASIC_LIMIT_INFORMATION
			BasicLimitInformation;

		public IO_COUNTERS IoInfo;

		public UIntPtr ProcessMemoryLimit;
		public UIntPtr JobMemoryLimit;

		public UIntPtr PeakProcessMemoryUsed;
		public UIntPtr PeakJobMemoryUsed;
	}

	[StructLayout(
		LayoutKind.Sequential,
		CharSet = CharSet.Unicode
	)]
	private struct STARTUPINFO
	{
		public int cb;

		public string lpReserved;
		public string lpDesktop;
		public string lpTitle;

		public uint dwX;
		public uint dwY;
		public uint dwXSize;
		public uint dwYSize;

		public uint dwXCountChars;
		public uint dwYCountChars;

		public uint dwFillAttribute;
		public uint dwFlags;

		public short wShowWindow;
		public short cbReserved2;

		public IntPtr lpReserved2;

		public IntPtr hStdInput;
		public IntPtr hStdOutput;
		public IntPtr hStdError;
	}

	[StructLayout(LayoutKind.Sequential)]
	private struct PROCESS_INFORMATION
	{
		public IntPtr hProcess;
		public IntPtr hThread;

		public uint dwProcessId;
		public uint dwThreadId;
	}

	[DllImport(
		"kernel32.dll",
		CharSet = CharSet.Unicode,
		SetLastError = true
	)]
	private static extern IntPtr CreateJobObjectW(
		IntPtr lpJobAttributes,
		string lpName
	);

	[DllImport(
		"kernel32.dll",
		SetLastError = true
	)]
	private static extern bool SetInformationJobObject(
		IntPtr hJob,
		int JobObjectInformationClass,
		IntPtr lpJobObjectInformation,
		uint cbJobObjectInformationLength
	);

	[DllImport(
		"kernel32.dll",
		SetLastError = true
	)]
	private static extern bool AssignProcessToJobObject(
		IntPtr hJob,
		IntPtr hProcess
	);

	[DllImport(
		"kernel32.dll",
		SetLastError = true
	)]
	private static extern IntPtr OpenProcess(
		uint dwDesiredAccess,
		bool bInheritHandle,
		uint dwProcessId
	);

	[DllImport(
		"kernel32.dll",
		CharSet = CharSet.Unicode,
		SetLastError = true
	)]
	private static extern bool CreateProcessW(
		string lpApplicationName,
		StringBuilder lpCommandLine,
		IntPtr lpProcessAttributes,
		IntPtr lpThreadAttributes,
		bool bInheritHandles,
		uint dwCreationFlags,
		IntPtr lpEnvironment,
		string lpCurrentDirectory,
		ref STARTUPINFO lpStartupInfo,
		out PROCESS_INFORMATION lpProcessInformation
	);

	[DllImport(
		"kernel32.dll",
		SetLastError = true
	)]
	private static extern uint ResumeThread(
		IntPtr hThread
	);

	[DllImport(
		"kernel32.dll",
		SetLastError = true
	)]
	private static extern bool TerminateProcess(
		IntPtr hProcess,
		uint uExitCode
	);

	[DllImport("kernel32.dll")]
	private static extern bool CloseHandle(
		IntPtr hObject
	);

	private static IntPtr GetOrCreateJob(
		string jobName,
		ulong memoryLimitBytes
	)
	{
		lock (Jobs)
		{
			IntPtr existing;

			if (Jobs.TryGetValue(
				jobName,
				out existing
			))
			{
				ConfigureJob(
					existing,
					memoryLimitBytes
				);

				return existing;
			}

			/*
				CreateJobObject also opens an existing named
				Job Object if one with the same name already exists.
			*/
			IntPtr job = CreateJobObjectW(
				IntPtr.Zero,
				jobName
			);

			if (job == IntPtr.Zero)
			{
				throw new Win32Exception(
					Marshal.GetLastWin32Error(),
					"CreateJobObject failed."
				);
			}

			try
			{
				ConfigureJob(
					job,
					memoryLimitBytes
				);

				Jobs[jobName] = job;

				return job;
			}
			catch
			{
				CloseHandle(job);
				throw;
			}
		}
	}

	private static void ConfigureJob(
		IntPtr job,
		ulong memoryLimitBytes
	)
	{
		JOBOBJECT_EXTENDED_LIMIT_INFORMATION info =
			new JOBOBJECT_EXTENDED_LIMIT_INFORMATION();

		info.BasicLimitInformation.LimitFlags =
			JOB_OBJECT_LIMIT_JOB_MEMORY;

		info.JobMemoryLimit =
			new UIntPtr(memoryLimitBytes);

		int size =
			Marshal.SizeOf(
				typeof(
					JOBOBJECT_EXTENDED_LIMIT_INFORMATION
				)
			);

		IntPtr ptr =
			Marshal.AllocHGlobal(size);

		try
		{
			Marshal.StructureToPtr(
				info,
				ptr,
				false
			);

			if (!SetInformationJobObject(
				job,
				JobObjectExtendedLimitInformation,
				ptr,
				(uint)size
			))
			{
				throw new Win32Exception(
					Marshal.GetLastWin32Error(),
					"SetInformationJobObject failed."
				);
			}
		}
		finally
		{
			Marshal.FreeHGlobal(ptr);
		}
	}

	public static uint Start(
		string exePath,
		string jobName,
		ulong memoryLimitBytes
	)
	{
		IntPtr job =
			GetOrCreateJob(
				jobName,
				memoryLimitBytes
			);

		STARTUPINFO startup =
			new STARTUPINFO();

		startup.cb =
			Marshal.SizeOf(
				typeof(STARTUPINFO)
			);

		PROCESS_INFORMATION processInfo;

		StringBuilder commandLine =
			new StringBuilder(
				"\"" + exePath + "\""
			);

		bool created =
			CreateProcessW(
				exePath,
				commandLine,
				IntPtr.Zero,
				IntPtr.Zero,
				false,
				CREATE_SUSPENDED,
				IntPtr.Zero,
				Path.GetDirectoryName(exePath),
				ref startup,
				out processInfo
			);

		if (!created)
		{
			throw new Win32Exception(
				Marshal.GetLastWin32Error(),
				"CreateProcess failed."
			);
		}

		try
		{
			if (!AssignProcessToJobObject(
				job,
				processInfo.hProcess
			))
			{
				int error =
					Marshal.GetLastWin32Error();

				TerminateProcess(
					processInfo.hProcess,
					1
				);

				throw new Win32Exception(
					error,
					"AssignProcessToJobObject failed."
				);
			}

			uint result =
				ResumeThread(
					processInfo.hThread
				);

			if (result == 0xFFFFFFFF)
			{
				int error =
					Marshal.GetLastWin32Error();

				TerminateProcess(
					processInfo.hProcess,
					1
				);

				throw new Win32Exception(
					error,
					"ResumeThread failed."
				);
			}

			return processInfo.dwProcessId;
		}
		finally
		{
			CloseHandle(
				processInfo.hThread
			);

			CloseHandle(
				processInfo.hProcess
			);
		}
	}

	public static void Attach(
		uint processId,
		string jobName,
		ulong memoryLimitBytes
	)
	{
		IntPtr job =
			GetOrCreateJob(
				jobName,
				memoryLimitBytes
			);

		uint access =
			PROCESS_SET_QUOTA |
			PROCESS_TERMINATE |
			PROCESS_QUERY_LIMITED_INFORMATION;

		IntPtr process =
			OpenProcess(
				access,
				false,
				processId
			);

		if (process == IntPtr.Zero)
		{
			throw new Win32Exception(
				Marshal.GetLastWin32Error(),
				"OpenProcess failed for PID " +
				processId + "."
			);
		}

		try
		{
			if (!AssignProcessToJobObject(
				job,
				process
			))
			{
				throw new Win32Exception(
					Marshal.GetLastWin32Error(),
					"AssignProcessToJobObject failed for PID " +
					processId + "."
				);
			}
		}
		finally
		{
			CloseHandle(process);
		}
	}
}
'@
}

function Start-MemoryLimitedApp {
	[CmdletBinding()]
	param
	(
		[Parameter(
			Mandatory = $true,
			Position = 0
		)]
		[string]$Path,

		[double]$MemoryLimitGiB = 8,
		[switch]$Running
	)

	if ($Running -and -not ([IO.Path]::IsPathRooted($Path))) { 
		$Path = (Get-Process ([IO.Path]::GetFileNameWithoutExtension($Path)) -ea 0)[0].Path
		
		if (-not $Path) { 
			return 
		} 
	}

	$exePath =
	[Environment]::ExpandEnvironmentVariables(
		$Path
	)

	$exePath =
	[IO.Path]::GetFullPath(
		$exePath
	)

	if (-not (
			Test-Path `
				-LiteralPath $exePath `
				-PathType Leaf
		)) {
		throw "Executable not found: $exePath"
	}

	if ($MemoryLimitGiB -le 0) {
		throw "MemoryLimitGiB must be greater than zero."
	}

	$memoryLimitBytes =
	[uint64](
		$MemoryLimitGiB * 1GB
	)

	$processName =
	[IO.Path]::GetFileNameWithoutExtension(
		$exePath
	)

	$normalizedJobPart =
	$exePath `
		-replace '[^A-Za-z0-9_.-]', '_'

	$jobName =
	"Local\MemoryLimited_$normalizedJobPart"

	$alreadyRunning = @(
		Get-Process `
			-Name $processName `
			-ErrorAction SilentlyContinue |
		Where-Object {
			try {
				$_.Path -and
				(
					[IO.Path]::GetFullPath(
						$_.Path
					) -ieq $exePath
				)
			}
			catch {
				$false
			}
		}
	)

	if ($alreadyRunning.Count -gt 0) {
		Write-Host (
			"Found {0} existing {1} process(es)." -f
			$alreadyRunning.Count,
			$processName
		)

		Write-Host (
			"Applying a combined {0:N1} GiB Job Object memory limit..." -f
			$MemoryLimitGiB
		)

		$attached = @()
		$failed = @()

		foreach ($process in $alreadyRunning) {
			try {
				[MemoryLimitedLauncher]::Attach(
					[uint32]$process.Id,
					$jobName,
					$memoryLimitBytes
				)

				$attached += $process

				Write-Host (
					"Attached PID {0}" -f
					$process.Id
				)
			}
			catch {
				$failed +=
				[pscustomobject]@{
					Process = $process
					Error   = $_.Exception.Message
				}

				Write-Warning (
					"Could not attach PID {0}: {1}" -f
					$process.Id,
					$_.Exception.Message
				)
			}
		}

		Start-Sleep -Milliseconds 500

		$secondPass = @(
			Get-Process `
				-Name $processName `
				-ErrorAction SilentlyContinue |
			Where-Object {
				try {
					$_.Path -and
					(
						[IO.Path]::GetFullPath(
							$_.Path
						) -ieq $exePath
					)
				}
				catch {
					$false
				}
			}
		)

		foreach ($process in $secondPass) {
			if (
				$attached.Id -contains
				$process.Id
			) {
				continue
			}

			try {
				[MemoryLimitedLauncher]::Attach(
					[uint32]$process.Id,
					$jobName,
					$memoryLimitBytes
				)

				$attached += $process

				Write-Host (
					"Attached newly found PID {0}" -f
					$process.Id
				)
			}
			catch {
				Write-Warning (
					"Could not attach newly found PID {0}: {1}" -f
					$process.Id,
					$_.Exception.Message
				)
			}
		}

		Write-Host ""

		Write-Host (
			"Attached {0} existing process(es)." -f
			$attached.Count
		)

		if ($failed.Count -gt 0) {
			Write-Warning @"
One or more existing processes could not be attached.
"@
		}

		Write-Host (
			"Combined memory limit: {0:N1} GiB" -f
			$MemoryLimitGiB
		)

		return $attached
	}

	if ($Running) { 
		return 
	}

	Write-Host (
		"{0} is not currently running." -f
		$processName
	)

	Write-Host (
		"Starting it with a combined {0:N1} GiB memory limit..." -f
		$MemoryLimitGiB
	)

	try {
		$processId =
		[MemoryLimitedLauncher]::Start(
			$exePath,
			$jobName,
			$memoryLimitBytes
		)
	}
	catch {
		Write-Warning (
			"CreateProcess launch failed; retrying through ShellExecute: {0}" -f
			$_.Exception.GetBaseException().Message
		)

		$process =
		Start-Process `
			-FilePath $exePath `
			-PassThru

		[MemoryLimitedLauncher]::Attach(
			[uint32]$process.Id,
			$jobName,
			$memoryLimitBytes
		)

		$processId = $process.Id
	}

	Write-Host ""

	Write-Host (
		"Started {0}" -f
		$exePath
	)

	Write-Host (
		"PID: {0}" -f
		$processId
	)

	Write-Host (
		"Combined Job Object memory limit: {0:N1} GiB" -f
		$MemoryLimitGiB
	)

	Get-Process `
		-Id $processId `
		-ErrorAction SilentlyContinue
}

# Require elevation before certain changes.
# Relaunch through UAC when needed so a non-elevated interactive or scheduled invocation can continue.
if (-not $AdminPhase) {
	Invoke-UserPhase
}

if ($AdminPhase -and -not (Test-IsAdministrator)) {
	Write-Warning 'Requesting administrator approval for tasks.ps1...'
	try {
		Start-ElevatedSelf -AdminPhase @args
	}
	catch {
		Write-Error "Could not relaunch tasks.ps1 as administrator: $_"
		exit 1
	}
}

# Use nonterminating defaults globally, then apply local try/catch blocks where continuation behavior matters.
$ErrorActionPreference = 'Continue'
$PSDefaultParameterValues['*:ErrorAction'] = 'Continue'

Write-Host ""

# ==============================
# Launch selected user applications only when installed and not already running.
# ==============================

if (-not $AdminPhase) {
	if (Test-Path "${env:ProgramFiles(x86)}\MSI Afterburner\MSIAfterburner.exe") {
		Start-MemoryLimitedApp "${env:ProgramFiles(x86)}\MSI Afterburner\MSIAfterburner.exe"
	}

	if (Test-Path "$env:ProgramFiles\HWiNFO64\HWiNFO64.EXE") {
		Start-MemoryLimitedApp "$env:ProgramFiles\HWiNFO64\HWiNFO64.EXE"
	}

	if (Test-Path "${env:ProgramFiles(x86)}\RivaTuner Statistics Server\RTSS.exe") {
		Start-MemoryLimitedApp "${env:ProgramFiles(x86)}\RivaTuner Statistics Server\RTSS.exe"
		if (Get-Process -Name "RTSSHooksLoader64" -ErrorAction SilentlyContinue) {
			Start-MemoryLimitedApp "RTSSHooksLoader64.exe" -Running
		}
	}

	if (Test-Path "${env:ProgramFiles(x86)}\Steam\steam.exe") {
		Start-MemoryLimitedApp "${env:ProgramFiles(x86)}\Steam\steam.exe"
		if (Get-Process -Name "steamwebhelper" -ErrorAction SilentlyContinue) {
			Start-MemoryLimitedApp "steamwebhelper.exe" -Running
		}
	}

	if (Test-Path "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Riot Games\Riot Client.lnk") {
		if (-not (Get-Process -Name "RiotClientServices" -ErrorAction SilentlyContinue)) {
			Start-Process "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Riot Games\Riot Client.lnk"

			for ($i = 0; $i -lt 50 -and -not (Get-Process RiotClientServices -ea 0); $i++) { 
				Start-Sleep -Milliseconds 100 
			}
		}

		if (Get-Process -Name "RiotClientServices" -ErrorAction SilentlyContinue) {
			Start-MemoryLimitedApp "RiotClientServices.exe" -Running
		}
	}

	if (Test-Path "${env:ProgramFiles(x86)}\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe") {
		Start-MemoryLimitedApp "${env:ProgramFiles(x86)}\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe"
		if (Get-Process -Name "EpicWebHelper" -ErrorAction SilentlyContinue) {
			Start-MemoryLimitedApp "EpicWebHelper.exe" -Running
		}
	}
	elseif (Test-Path "${env:ProgramFiles(x86)}\Epic Games\Launcher\Portal\Binaries\Win32\EpicGamesLauncher.exe") {
		Start-MemoryLimitedApp "${env:ProgramFiles(x86)}\Epic Games\Launcher\Portal\Binaries\Win32\EpicGamesLauncher.exe"
		if (Get-Process -Name "EpicWebHelper" -ErrorAction SilentlyContinue) {
			Start-MemoryLimitedApp "EpicWebHelper.exe" -Running
		}
	}

	if (Test-Path "${env:ProgramFiles(x86)}\Razer\Razer Cortex\RazerCortex.exe") {
		Start-MemoryLimitedApp "${env:ProgramFiles(x86)}\Razer\Razer Cortex\RazerCortex.exe"
	}

	# if (Test-Path "$env:ProgramFiles\SteelSeries\GG\SteelSeriesGG.exe") {
	# 	if (-not (Get-Process -Name "SteelSeriesGG" -ErrorAction SilentlyContinue)) {
	# 		Start-MemoryLimitedApp "$env:ProgramFiles\SteelSeries\GG\SteelSeriesGG.exe"
	# 	}
	# }

	if (Test-Path "${env:ProgramFiles(x86)}\Overwolf\OverwolfLauncher.exe") {
		Start-MemoryLimitedApp "${env:ProgramFiles(x86)}\Overwolf\OverwolfLauncher.exe"
		if (Get-Process -Name "Overwolf" -ErrorAction SilentlyContinue) {
			Start-MemoryLimitedApp "Overwolf.exe" -Running
		}
	}

	# if (Test-Path "${env:ProgramFiles(x86)}\FanControl\FanControl.exe") {
	# 	if (-not (Get-Process -Name "FanControl" -ErrorAction SilentlyContinue)) {
	# 		Start-MemoryLimitedApp "${env:ProgramFiles(x86)}\FanControl\FanControl.exe"
	# 	}
	# }

	# Probe known Voicemeeter editions and retain the first executable found.
	$vm_path = ""
	$vm_exe = ""

	# Prefer the most feature-complete Voicemeeter edition when more than one is installed.
	if (Test-Path "${env:ProgramFiles(x86)}\VB\Voicemeeter\voicemeeterpro_x64.exe") {
		$vm_path = "${env:ProgramFiles(x86)}\VB\Voicemeeter\voicemeeterpro_x64.exe"
		$vm_exe = "voicemeeterpro_x64"
	}
	elseif (Test-Path "${env:ProgramFiles(x86)}\VB\Voicemeeter\voicemeeter8x64.exe") {
		$vm_path = "${env:ProgramFiles(x86)}\VB\Voicemeeter\voicemeeter8x64.exe"
		$vm_exe = "voicemeeter8x64"
	}
	elseif (Test-Path "${env:ProgramFiles(x86)}\VB\Voicemeeter\voicemeeterpro.exe") {
		$vm_path = "${env:ProgramFiles(x86)}\VB\Voicemeeter\voicemeeterpro.exe"
		$vm_exe = "voicemeeterpro"
	}
	elseif (Test-Path "${env:ProgramFiles(x86)}\VB\Voicemeeter\voicemeeter8.exe") {
		$vm_path = "${env:ProgramFiles(x86)}\VB\Voicemeeter\voicemeeter8.exe"
		$vm_exe = "voicemeeter8"
	}

	# Start the selected Voicemeeter executable only when no matching process is already active.
	if ($vm_path) {
		Start-MemoryLimitedApp $vm_path
	}

	if (Test-Path "$env:ProgramFiles\Mozilla Thunderbird\thunderbird.exe") {
		Start-MemoryLimitedApp "$env:ProgramFiles\Mozilla Thunderbird\thunderbird.exe"
	}

	if (Test-Path "$env:ProgramFiles\Microsoft OneDrive\OneDrive.exe") {
		Start-MemoryLimitedApp "$env:ProgramFiles\Microsoft OneDrive\OneDrive.exe"
		if (Get-Process -Name "OneDrive.Sync.Service" -ErrorAction SilentlyContinue) {
			Start-MemoryLimitedApp "OneDrive.Sync.Service.exe" -Running
		}
	}

	if (Test-Path "$env:LOCALAPPDATA\MEGAsync\MEGAsync.exe") {
		Start-MemoryLimitedApp "$env:LOCALAPPDATA\MEGAsync\MEGAsync.exe"
	}

	# packages
	foreach ($p in 'Microsoft.GamingApp', 'Microsoft.WindowsStore') {
		Get-AppxPackage $p -ea 0 | % {
			if ($_.InstallLocation) {
				Get-ChildItem $_.InstallLocation -Filter *.exe -File | % BaseName | % {
					try {
						Start-MemoryLimitedApp $_ -Running
					}
					catch {}
				}
			}
		}
	}
}

if (-not $AdminPhase) {
	Start-ElevatedSelf -AdminPhase
}

# services
$services = Get-CimInstance Win32_Service | Where-Object State -eq Running | ForEach-Object {
	$exePath = Get-ExePathFromServicePath $_.PathName

	[PSCustomObject]@{
		Name         = $_.Name
		ServiceType  = $_.ServiceType
		ExePath      = $exePath
		UnderWindows = Test-IsUnderWindowsDirectory $exePath
	}
}

$nonSystemServices = $services | Where-Object {
	$_.ExePath -and
	$_.ServiceType -notmatch 'Kernel Driver|File System Driver' -and
	-not $_.UnderWindows
}

if ($IncludeRunningServices -and $nonSystemServices) {
	foreach ($svc in $nonSystemServices) {
		Start-MemoryLimitedApp $svc.ExePath -Running
	}
}
else {
	Write-Host "No running non-Windows services eligible for memory limitation were found."
}

Write-Host "Finished checking applications which can be memory limited."

# Optionally lower eligible non-Windows processes after elevation so maintenance work remains responsive.
Write-Section "process priorities"
$DO_SET_LOW_PRIORITY = Prompt-YesNoDefaultN -Message "Set processes to lowest priority? (Y/N)" -TimeoutSeconds 5
if ($DO_SET_LOW_PRIORITY) {
	Write-Host "Finding eligible processes and applying low priorities..."
	# Optionally lower eligible non-Windows processes after elevation so maintenance work remains responsive.
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
else {
	Write-Host "Skipping process priority changes."
}

# Optionally set non-driver services outside the Windows directory to Manual and apply low resource priorities.
Write-Section "services"
$DO_SET_NONSTOCK_SERVICES = Prompt-YesNoDefaultN -Message "Set non-stock services to Manual startup? (Y/N)" -TimeoutSeconds 5

if ($DO_SET_NONSTOCK_SERVICES) {
	Write-Host "Inspecting non-Windows services..."
	$services = Get-CimInstance Win32_Service | ForEach-Object {
		$exePath = Get-ExePathFromServicePath $_.PathName

		[PSCustomObject]@{
			Name         = $_.Name
			ServiceType  = $_.ServiceType
			ExePath      = $exePath
			UnderWindows = Test-IsUnderWindowsDirectory $exePath
		}
	}

	$nonSystemServices = $services | Where-Object {
		$_.ExePath -and
		$_.ServiceType -notmatch 'Kernel Driver|File System Driver' -and
		-not $_.UnderWindows
	}

	if ($nonSystemServices) {
		foreach ($svc in $nonSystemServices) {
			if ($PSCmdlet.ShouldProcess($svc.Name, 'Set startup type to Manual')) {
				Set-Service -Name $svc.Name -StartupType Manual
			}

			# Apply Image File Execution Options by executable name so future service processes inherit low CPU, I/O, and page priorities.
			$exeName = [IO.Path]::GetFileName($svc.ExePath)
			reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$exeName\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 1 /f
			reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$exeName\PerfOptions" /v IoPriority /t REG_DWORD /d 0 /f
			reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$exeName\PerfOptions" /v PagePriority /t REG_DWORD /d 1 /f
		}
	}
	else {
		Write-Host "No eligible non-Windows services found."
	}
}
else {
	Write-Host "Skipping non-stock service startup changes."
}

# Optionally inspect non-Microsoft Exec tasks and disable only those without Windows paths or valid Microsoft signatures.
Write-Section "scheduled tasks"
$DO_SCHEDULED_TASKS = Prompt-YesNoDefaultN -Message "Disable non-Microsoft scheduled tasks? (Y/N)" -TimeoutSeconds 5
if ($DO_SCHEDULED_TASKS) {
	Write-Host "Inspecting scheduled tasks and command signatures..."
	$ScheduledTaskMode = 'Disable' # Report | Disable # | Unregister

	$scheduledTasks = Get-ScheduledTask

	$nonMicrosoftTasks = foreach ($task in $scheduledTasks) {
		if ($task.TaskPath -like '\Microsoft\*') {
			continue
		}

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
else {
	Write-Host "Skipping scheduled task changes."
}

# Optionally remove disconnected devices, then uninstall associated driver packages unless the provider is exactly Microsoft.
Write-Section "devices and drivers"
$DO_REMOVE_DRIVERS = Prompt-YesNoDefaultN -Message "Remove disconnected devices and non-Microsoft drivers? (Y/N)" -TimeoutSeconds 5

if ($DO_REMOVE_DRIVERS) {
	Write-Host "Enumerating disconnected devices and driver packages..."
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

			# Protect only the canonical Microsoft provider string; other providers remain eligible for package deletion.
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

# Optionally configure active adapters with Cloudflare malware-blocking DNS and register per-interface DoH flags.
Write-Section "DNS"
$DO_CONFIGURE_DNS = Prompt-YesNoDefaultN `
	-Message "Configure DNS? (Y/N)" `
	-TimeoutSeconds 5

if ($DO_CONFIGURE_DNS) {
	Write-Host "Configuring DNS and DNS-over-HTTPS on active adapters..."
	try {
		# Limit changes to active adapters, then assign the same IPv4 and IPv6 resolver set to each.
		$ifaces = Get-NetAdapter | Where-Object Status -eq "Up"
		if (-not $ifaces) { Write-Host "No active network adapters found." }
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

# Run PSWindowsUpdate when available, installing the module first and retaining wuauclt as a legacy fallback.
Write-Section "Windows Update"
Write-Host "Checking for Windows updates and the PSWindowsUpdate module..."
try {
	if (Get-Command Get-WindowsUpdate -ErrorAction SilentlyContinue) {
		Get-WindowsUpdate -Download -AcceptAll -Confirm:$false
		Get-WindowsUpdate -Install  -AcceptAll -IgnoreReboot -Confirm:$false
	}
	else {
		Install-Module PSWindowsUpdate -Force -Confirm:$false
		Get-WindowsUpdate -Download -AcceptAll -Confirm:$false
		Get-WindowsUpdate -Install  -AcceptAll -IgnoreReboot -Confirm:$false
	}
}
catch {
	Write-Warning "Error installing or running Windows updates: $_"
}

if (-not (Get-Command Get-WindowsUpdate -ErrorAction SilentlyContinue)) {
	try {
		# Use the legacy Windows Update client only when the module remains unavailable after installation.
		# Trigger update detection and installation through wuauclt without treating it as a feature-equivalent replacement.
		wuauclt /detectnow
		wuauclt /updatenow
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
# so final prompt remains reachable during interactive runs.
# Read-Host "Press Enter to continue"
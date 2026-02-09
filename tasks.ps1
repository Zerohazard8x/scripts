# Ensure the script runs with administrative privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "run this script as admin"
    exit
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

Write-Host ""

function Prompt-YesNoDefaultN {
    param(
        [string]$Message = "App uninstallations? (Y/N)",
        [int]$TimeoutSeconds = 15
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

$DO_UNINSTALL = Prompt-YesNoDefaultN -TimeoutSeconds 15

try {
    if ($DO_UNINSTALL) {
        $appsToRemove = @(
            "3D Viewer","Clipchamp","Microsoft Clipchamp","Feedback Hub","HPHelp","Microsoft Pay",
            "Microsoft People","Microsoft Photos","Microsoft Solitaire Collection",
            "Microsoft Sticky Notes","Sticky Notes","Microsoft Tips","Mixed Reality Portal",
            "Movies & TV","News","OneNote for Windows 10","Paint 3D",
            "Power Automate","Print 3D","Skype",
            "Solitaire & Casual Games","Windows Maps",
            "Media Player", "Sound Recorder", "Family", "Quick Assist", "Outlook", "Translator", "Microsoft Teams"
        )

        foreach ($app in $appsToRemove) {
            Safe-Invoke -Command "winget" -Args @("uninstall","--name",$app,"--exact")
        }

        $idsToRemove = @(
            "9P7BP5VNWKX5","9PDJDJS743XF","9WZDNCRFHWKN"
        )

        foreach ($app in $idsToRemove) {
            Safe-Invoke -Command "winget" -Args @("uninstall","--id",$app)
        }
    }
    else {
        Write-Host "Skipping app uninstallations."
    }
}
catch {
    Write-Warning "Error during bulk uninstall: $_"
}

# Windows store
function Get-StoreAppPackages {
    # Derived from https://christitus.com/installing-appx-without-msstore/ by LLM
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $ProductId,
        [ValidateSet('RP','WIF','Retail','Beta')][string] $Ring = 'RP',
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
            if ($LASTEXITCODE -in 0,-1978335189) {
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
    } else {
        $preferredArch = 'x86'; $fallbackArch = 'x64'
    }
    Write-Verbose "OS is $([Environment]::OSVersion); preferring $preferredArch"

    # 3. Set up download directory
    $apiUrl     = 'https://store.rg-adguard.net/api/GetFiles'
    $productUrl = "Get-StoreAppPackages -ProductId '$ProductId"
    $downloadDir= Join-Path $env:TEMP "StoreDownloads\$ProductId"
    if (-not (Test-Path $downloadDir)) {
        New-Item -Path $downloadDir -ItemType Directory -Force | Out-Null
    }

    # 4. Query RG-AdGuard API
    $body = @{ type='url'; url=$productUrl; ring=$Ring; lang=$Lang }
    try {
        $response = Invoke-RestMethod -Method Post -Uri $apiUrl `
                     -ContentType 'application/x-www-form-urlencoded' `
                     -Body $body
    }
    catch {
        Throw "Failed to call RG-AdGuard API: $_"
    }

    # 5. Parse all candidate URLs
    $pattern = '<tr style.*?<a href="(?<url>[^"]+)"[^>]*>(?<name>[^<]+)</a>'
    $matches = [regex]::Matches($response, $pattern)

    # 6. Filter into buckets
    $byArch = @{ Preferred = @(); Neutral = @(); Fallback = @() }
    foreach ($m in $matches) {
        $url  = $m.Groups['url'].Value
        $name = $m.Groups['name'].Value
        if ($name -match '_(x86|x64|neutral).*?\.(appx|appxbundle)$') {
            switch -Regex ($name) {
                "_$preferredArch" { $byArch.Preferred += @{ Name=$name; Url=$url }; break }
                "_neutral"        { $byArch.Neutral   += @{ Name=$name; Url=$url }; break }
                "_$fallbackArch"  { $byArch.Fallback  += @{ Name=$name; Url=$url }; break }
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
            Throw "Download failed for $($pkgInfo.Name): $_"
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

# chocolatey
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Chocolatey not detected. Installing..."

    Remove-Item -Force -r -v C:\ProgramData\chocolatey
    [Net.ServicePointManager]::SecurityProtocol =
        [Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString(
        'https://community.chocolatey.org/install.ps1'))
}

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
Get-StoreAppPackages -ProductId '9nblggh5r558' # Microsoft To Do. 
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

# winget upgrade
Safe-Invoke -Command "winget" -Args @("upgrade","--all","--accept-source-agreements","--accept-package-agreements")
# Safe-Invoke -Command "winget" -Args @("upgrade","--all","--accept-source-agreements","--accept-package-agreements","--include-unknown")

# configure dns
netsh dns add global doh=yes ddr=yes # Enable DoH

netsh dns add encryption server=1.1.1.2 dohtemplate=https://security.cloudflare-dns.com/dns-query autoupgrade=yes udpfallback=no
netsh dns add encryption server=1.0.0.2 dohtemplate=https://security.cloudflare-dns.com/dns-query autoupgrade=yes udpfallback=no
netsh dns add encryption server=2606:4700:4700::1112 dohtemplate=https://security.cloudflare-dns.com/dns-query autoupgrade=yes udpfallback=no
netsh dns add encryption server=2606:4700:4700::1002 dohtemplate=https://security.cloudflare-dns.com/dns-query autoupgrade=yes udpfallback=no

# Set DNS servers on all "Up" adapters
$ifaces = Get-NetAdapter | Where-Object Status -eq "Up"
$dns = @(
  "1.1.1.2"
  "1.0.0.2"
  "2606:4700:4700::1112"
  "2606:4700:4700::1002"
)
foreach ($i in $ifaces) {
  Set-DnsClientServerAddress -InterfaceIndex $i.ifIndex -ServerAddresses $dns
}

# Windows Defender
try {
    Set-MpPreference -DisableRealtimeMonitoring $false
    Set-MpPreference -EnableControlledFolderAccess Disabled
}
catch {
    Write-Warning "Error: $_"
}

try {
    bcdedit.exe /debug off
    bcdedit.exe /set loadoptions ENABLE_INTEGRITY_CHECKS
    bcdedit.exe /set TESTSIGNING OFF
    bcdedit.exe /set NOINTEGRITYCHECKS OFF
    bcdedit /set hypervisorlaunchtype auto
}
catch {
    Write-Warning "Error running bcdedit: $_"
}

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

try {
    control update
}
catch {
    Write-Warning "Error opening Windows Update control panel: $_"
}

try {
    Start-Process "ms-windows-store://downloadsandupdates"
}
catch {
    Write-Warning "Error opening Microsoft Store updates: $_"
}

exit
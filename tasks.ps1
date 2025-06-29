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

try {
    # https://github.com/SimonCropp/WinDebloat
    # winget uninstall "OneDrive"
    # winget uninstall --name "Microsoft To Do" --exact
    # winget uninstall --name "Microsoft Whiteboard" --exact
    # winget uninstall --name "Windows Calculator" --exact
    # winget uninstall --name "Windows Camera" --exact
    # winget uninstall --name "Xbox Accessories" --exact
    # winget uninstall --name "Xbox Game Bar Plugin" --exact
    # winget uninstall --name "Xbox Game Bar" --exact
    # winget uninstall --name "Xbox Identity Provider" --exact
    # winget uninstall --name "Xbox TCUI" --exact
    # winget uninstall --name "Xbox" --exact

    $appsToRemove = @(
        "3D Viewer","Clipchamp","Cortana","Feedback Hub","Get Help","HPHelp",
        "MSN Weather","Mail and Calendar","Microsoft News","Microsoft Pay",
        "Microsoft People","Microsoft Photos","Microsoft Solitaire Collection",
        "Microsoft Sticky Notes","Microsoft Tips","Mixed Reality Portal",
        "Movies & TV","News","OneNote for Windows 10","Paint 3D",
        "Power Automate","Print 3D","SharedAccess","Skype",
        "Solitaire & Casual Games","Teams Machine-Wide Installer",
        "Windows Alarms & Clock","Windows Clock","Windows Maps",
        "Windows Media Player","Windows Web Experience Pack",
        "Xbox Console Companion","Xbox Game Speech Window"
    )

    foreach ($app in $appsToRemove) {
        Safe-Invoke -Command "winget" -Args @("uninstall","--name",$app,"--exact")
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
    $productUrl = "https://www.microsoft.com/store/productId/$ProductId"
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

Get-StoreAppPackages -ProductId '9WZDNCRFJBMP' # Microsoft Store

# codecs
Get-StoreAppPackages -ProductId '9nmzlz57r3t7' # HEVC
Get-StoreAppPackages -ProductId '9n4wgh0z6vhq' # HEVC (OEM)
Get-StoreAppPackages -ProductId '9MVZQVXJBQ9V' # AV1
Get-StoreAppPackages -ProductId '9N4D0MSMP0PT' # VP9
Get-StoreAppPackages -ProductId '9n95q1zzpmh4' # MPEG-2

# winget upgrade
Safe-Invoke -Command "winget" -Args @("upgrade","--all","--accept-source-agreements","--accept-package-agreements")
# Safe-Invoke -Command "winget" -Args @("upgrade","--all","--accept-source-agreements","--accept-package-agreements","--include-unknown")

# Network
try {
    # check if command is available
    if (Get-Command Add-DnsClientDohServerAddress -ErrorAction SilentlyContinue) {
        # configure dns
        Add-DnsClientDohServerAddress -ServerAddress 2606:4700:4700::1112 -DohTemplate "https://security.cloudflare-dns.com/dns-query" -AutoUpgrade $True
        Add-DnsClientDohServerAddress -ServerAddress 2606:4700:4700::1002 -DohTemplate "https://security.cloudflare-dns.com/dns-query" -AutoUpgrade $True
        Add-DnsClientDohServerAddress -ServerAddress 1.1.1.2 -DohTemplate "https://security.cloudflare-dns.com/dns-query" -AutoUpgrade $True
        Add-DnsClientDohServerAddress -ServerAddress 1.0.0.2 -DohTemplate "https://security.cloudflare-dns.com/dns-query" -AutoUpgrade $True
    }
    else {
        # fallback
        $interfaces = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
        foreach ($interface in $interfaces) {
            Set-DnsClientServerAddress -InterfaceIndex $interface.ifIndex -ServerAddresses "1.1.1.2,1.0.0.2"
        }
    }
}
catch {
    Write-LogMessage "Error configuring DNS: $_" "Error"
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

exit
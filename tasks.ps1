# Ensure the script runs with administrative privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "run this script as admin"
    exit
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
    winget uninstall --name "3D Viewer" --exact
    winget uninstall --name "Clipchamp" --exact
    winget uninstall --name "Cortana" --exact
    winget uninstall --name "Feedback Hub" --exact
    winget uninstall --name "Get Help" --exact
    winget uninstall --name "HPHelp" --exact
    winget uninstall --name "MSN Weather" --exact
    winget uninstall --name "Mail and Calendar" --exact
    winget uninstall --name "Microsoft News" --exact
    winget uninstall --name "Microsoft Pay" --exact
    winget uninstall --name "Microsoft People" --exact
    winget uninstall --name "Microsoft Photos" --exact
    winget uninstall --name "Microsoft Solitaire Collection" --exact
    winget uninstall --name "Microsoft Sticky Notes" --exact
    winget uninstall --name "Microsoft Tips" --exact
    winget uninstall --name "Mixed Reality Portal" --exact
    winget uninstall --name "Movies & TV" --exact
    winget uninstall --name "News" --exact
    winget uninstall --name "OneNote for Windows 10" --exact
    winget uninstall --name "Paint 3D" --exact
    winget uninstall --name "Power Automate" --exact
    winget uninstall --name "Print 3D" --exact
    winget uninstall --name "SharedAccess" --exact
    winget uninstall --name "Skype" --exact
    winget uninstall --name "Solitaire & Casual Games" --exact
    winget uninstall --name "Teams Machine-Wide Installer" --exact
    winget uninstall --name "Windows Alarms & Clock" --exact
    winget uninstall --name "Windows Clock" --exact
    winget uninstall --name "Windows Maps" --exact
    winget uninstall --name "Windows Media Player" --exact
    winget uninstall --name "Windows Web Experience Pack" --exact
    winget uninstall --name "Xbox Console Companion" --exact
    winget uninstall --name "Xbox Game Speech Window" --exact
}
catch {
    Write-Warning "Error: $_"
}

# Set-ItemProperty -Path "Registry::HKCU\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Type "DWord" -Value "0"
# Set-ItemProperty -Path "Registry::HKLM\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell" -Name "ExecutionPolicy" -Type "String" -Value "Unrestricted"
# Set-ItemProperty -Path "Registry::HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "DisableSearchBoxSuggestions" -Type "DWord" -Value "1"

# Stop-Service -Name "Spooler"
# Set-Service -Name "Spooler" -StartupType "Disabled"

# Windows store
function Get-StoreAppPackages {
    # Derived from https://christitus.com/installing-appx-without-msstore/ by LLM
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $ProductId,

        [ValidateSet('RP','WIF','Retail','Beta')]
        [string] $Ring = 'RP',

        [string] $Lang = 'en-US'
    )

    # 1. Try winget first
    Write-Verbose "Attempting winget install for $ProductId"
    try {
        & winget install --id $ProductId --source msstore `
            --accept-source-agreements --accept-package-agreements
        if (($LASTEXITCODE -eq 0) -or ($LASTEXITCODE -eq -1978335189)) {
            Write-Verbose "Winget install succeeded for $ProductId"
            return "Installed via winget: $ProductId"
        }
        Write-Warning "winget exited with code $LASTEXITCODE; falling back to API download."
    }
    catch {
        Write-Warning "winget install error: $_"
    }

    # 2. Determine preferred architecture
    $is64 = [Environment]::Is64BitOperatingSystem
    if ($is64) {
        $preferredArch = 'x64'
        $fallbackArch  = 'x86'
    } else {
        $preferredArch = 'x86'
        $fallbackArch  = 'x64'
    }
    Write-Verbose "OS is $([Environment]::OSVersion); preferring $preferredArch"

    # 3. Set up download directory
    $apiUrl      = 'https://store.rg-adguard.net/api/GetFiles'
    $productUrl  = "https://www.microsoft.com/store/productId/$ProductId"
    $downloadDir = Join-Path $env:TEMP "StoreDownloads\$ProductId"
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
    $byArch = @{
        Preferred = @()
        Neutral   = @()
        Fallback  = @()
    }
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
            Invoke-WebRequest -Uri $pkgInfo.Url `
                              -OutFile $outFile `
                              -UseBasicParsing
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

winget upgrade --all --accept-source-agreements --accept-package-agreements
# winget upgrade --all --accept-source-agreements --accept-package-agreements --include-unknown

# Network
Add-DnsClientDohServerAddress -ServerAddress 2606:4700:4700::1112 -DohTemplate https://security.cloudflare-dns.com/dns-query -AutoUpgrade $True
Add-DnsClientDohServerAddress -ServerAddress 2606:4700:4700::1002 -DohTemplate https://security.cloudflare-dns.com/dns-query -AutoUpgrade $True
Add-DnsClientDohServerAddress -ServerAddress 1.1.1.2 -DohTemplate https://security.cloudflare-dns.com/dns-query -AutoUpgrade $True
Add-DnsClientDohServerAddress -ServerAddress 1.0.0.2 -DohTemplate https://security.cloudflare-dns.com/dns-query -AutoUpgrade $True

Add-DnsClientDohServerAddress -ServerAddress 2001:4860:4860::8888 -DohTemplate https://dns.google/dns-query -AutoUpgrade $True
Add-DnsClientDohServerAddress -ServerAddress 2001:4860:4860::8844 -DohTemplate https://dns.google/dns-query -AutoUpgrade $True
Add-DnsClientDohServerAddress -ServerAddress 8.8.8.8 -DohTemplate https://dns.google/dns-query -AutoUpgrade $True
Add-DnsClientDohServerAddress -ServerAddress 8.8.4.4 -DohTemplate https://dns.google/dns-query -AutoUpgrade $True

Add-DnsClientDohServerAddress -ServerAddress 2606:1a40::2 -DohTemplate https://freedns.controld.com/p2 -AutoUpgrade $True
Add-DnsClientDohServerAddress -ServerAddress 2606:1a40:1::2 -DohTemplate https://freedns.controld.com/p2 -AutoUpgrade $True
Add-DnsClientDohServerAddress -ServerAddress 76.76.2.2 -DohTemplate https://freedns.controld.com/p2 -AutoUpgrade $True
Add-DnsClientDohServerAddress -ServerAddress 76.76.10.2 -DohTemplate https://freedns.controld.com/p2 -AutoUpgrade $True

Add-DnsClientDohServerAddress -ServerAddress 9.9.9.11 -DohTemplate https://dns11.quad9.net/dns-query -AutoUpgrade $True
Add-DnsClientDohServerAddress -ServerAddress 149.112.112.11 -DohTemplate https://dns11.quad9.net/dns-query -AutoUpgrade $True
Add-DnsClientDohServerAddress -ServerAddress 2620:fe::11 -DohTemplate https://dns11.quad9.net/dns-query -AutoUpgrade $True
Add-DnsClientDohServerAddress -ServerAddress 2620:fe::fe:11 -DohTemplate https://dns11.quad9.net/dns-query -AutoUpgrade $True

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

try {
    if (Get-Command Get-WindowsUpdate -ErrorAction SilentlyContinue) {
        # Add-WUServiceManager -MicrosoftUpdate -Confirm:$false
        Get-WindowsUpdate -Download -AcceptAll -Confirm:$false
        Get-WindowsUpdate -Install -AcceptAll -IgnoreReboot -Confirm:$false
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
            Get-WindowsUpdate -Install -AcceptAll -IgnoreReboot -Confirm:$false
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
$ErrorActionPreference = 'Stop'

function New-ReservedMethods([int]$count) {
    (1..$count | ForEach-Object { "        [PreserveSig] int Reserved$_();" }) -join "`r`n"
}

$principal = [Security.Principal.WindowsPrincipal]::new(
    [Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Open as Administrator, then run this script.'
}

if (-not (Get-Service -Name 'WSearch' -ErrorAction SilentlyContinue)) {
    throw 'Windows Search service (WSearch) was not found.'
}

$indexDir = Join-Path $env:ProgramData 'Microsoft\Search\Data\Applications\Windows'
$searchKey = 'HKLM:\SOFTWARE\Microsoft\Windows Search'

# Stop Search UI processes. They are restarted automatically by Windows when needed.
foreach ($processName in @('SearchUI','SearchApp','SearchHost')) {
    Get-Process -Name $processName -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            Stop-Process -Id $_.Id -Force -ErrorAction Stop
            Write-Host "Stopped process $processName ($($_.Id))"
        } catch {
            Write-Warning "Could not stop $processName - $($_.Exception.Message)"
        }
    }
}

if ((Get-Service WSearch).Status -ne 'Stopped') {
    Stop-Service -Name WSearch -Force -ErrorAction Stop
    (Get-Service WSearch).WaitForStatus('Stopped', [TimeSpan]::FromSeconds(90))
}
if ((Get-Service WSearch).Status -ne 'Stopped') {
    throw 'WSearch did not fully stop; database files were not touched.'
}

# Delete only named database files (plus the SQLite journal/sidecars).
# File absence is normal on one of the operating system versions.
foreach ($filename in @(
    'Windows.edb', 'Windows.db',
    'Windows.db-wal', 'Windows.db-shm', 'Windows.db-journal'
)) {
    $file = Join-Path $indexDir $filename
    if (Test-Path -LiteralPath $file -PathType Leaf) {
        Remove-Item -LiteralPath $file -Force -ErrorAction Stop
        Write-Host "Removed index file: $filename"
    } else {
        Write-Host "Not present: $filename"
    }
}

# reset custom scopes to defaults
New-ItemProperty -Path $searchKey -Name 'SetupCompletedSuccessfully' `
    -Value 0 -PropertyType DWord -Force | Out-Null
Write-Host 'Set Windows Search initialization flag to 0.'

# Clear targeted app caches
$packages = @(
    'Microsoft.Cortana_8wekyb3d8bbwe',
    'Microsoft.Windows.Cortana_cw5n1h2txyewy',
    'Microsoft.Search_8wekyb3d8bbwe',
    'Microsoft.Windows.Search_cw5n1h2txyewy',
    'MicrosoftWindows.Client.CBS_cw5n1h2txyewy'
)
foreach ($packageName in $packages) {
    foreach ($cacheName in @('AppCache','INetCache','INetCookies','INetHistory')) {
        $cachePath = Join-Path $env:LOCALAPPDATA ("Packages\{0}\AC\{1}" -f $packageName, $cacheName)
        if (Test-Path -LiteralPath $cachePath) {
            try {
                Remove-Item -LiteralPath $cachePath -Recurse -Force -ErrorAction Stop
                Write-Host "Cleared cache: $cachePath"
            } catch {
                Write-Warning "Cache could not be cleared: $cachePath - $($_.Exception.Message)"
            }
        }
    }
}

# removes TESTABILITY keys.
foreach ($regKey in @(
    'HKLM:\SOFTWARE\Microsoft\Cortana\Testability',
    'HKLM:\SOFTWARE\Microsoft\Search\Testability'
)) {
    if (Test-Path -LiteralPath $regKey) {
        try {
            Remove-Item -LiteralPath $regKey -Recurse -Force -ErrorAction Stop
            Write-Host "Removed testability key: $regKey"
        } catch {
            Write-Warning "Could not remove $regKey - $($_.Exception.Message)"
        }
    }
}

# search scopes
$source = @"
using System;
using System.Runtime.InteropServices;

namespace WindowsSearchScopeReset
{
    [ComImport, Guid("AB310581-AC80-11D1-8DF3-00C04FB6EF69"),
     InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface ISearchManager
    {
$(New-ReservedMethods 7)
        [PreserveSig]
        int GetCatalog([MarshalAs(UnmanagedType.LPWStr)] string name,
                       [MarshalAs(UnmanagedType.Interface)] out ISearchCatalogManager catalog);
    }

    [ComImport, Guid("AB310581-AC80-11D1-8DF3-00C04FB6EF50"),
     InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface ISearchCatalogManager
    {
$(New-ReservedMethods 25)
        [PreserveSig]
        int GetCrawlScopeManager(
            [MarshalAs(UnmanagedType.Interface)] out ISearchCrawlScopeManager scopes);
    }

    [ComImport, Guid("AB310581-AC80-11D1-8DF3-00C04FB6EF55"),
     InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface ISearchCrawlScopeManager
    {
$(New-ReservedMethods 12)
        [PreserveSig] int RevertToDefaultScopes();
        [PreserveSig] int SaveAll();
    }

    public static class Reset
    {
        public static void Run()
        {
            object instance = null;
            ISearchCatalogManager catalog = null;
            ISearchCrawlScopeManager scopes = null;
            try
            {
                var type = Type.GetTypeFromCLSID(
                    new Guid("7D096C5F-AC08-4F1F-BEB7-5C22C517CE39"), true);
                instance = Activator.CreateInstance(type);
                var manager = (ISearchManager)instance;
                Marshal.ThrowExceptionForHR(manager.GetCatalog("SystemIndex", out catalog));
                if (catalog == null) throw new InvalidOperationException("SystemIndex not found.");
                Marshal.ThrowExceptionForHR(catalog.GetCrawlScopeManager(out scopes));
                if (scopes == null) throw new InvalidOperationException("Crawl scope manager not found.");
                Marshal.ThrowExceptionForHR(scopes.RevertToDefaultScopes());
                Marshal.ThrowExceptionForHR(scopes.SaveAll());
            }
            finally
            {
                if (scopes != null) Marshal.ReleaseComObject(scopes);
                if (catalog != null) Marshal.ReleaseComObject(catalog);
                if (instance != null) Marshal.ReleaseComObject(instance);
            }
        }
    }
}
"@

Add-Type -TypeDefinition $source -Language CSharp -ErrorAction Stop
[WindowsSearchScopeReset.Reset]::Run()

# reset HKCU Search settings
$userSearchKey = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'
if (Test-Path -LiteralPath $userSearchKey) {
    try {
        Remove-Item -LiteralPath $userSearchKey -Recurse -Force -ErrorAction Stop
        Write-Host 'Reset current-user Search registry settings.'
    } catch {
        Write-Warning "Could not clear current-user Search key: $($_.Exception.Message)"
    }
}

$win11 = [Environment]::OSVersion.Version.Build -ge 22000
$manifestRelative = if ($win11) {
    'SystemApps\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\Appxmanifest.xml'
} else {
    'SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy\Appxmanifest.xml'
}
$manifest = Join-Path $env:windir $manifestRelative
if (Test-Path -LiteralPath $manifest -PathType Leaf) {
    try {
        Add-AppxPackage -Path $manifest -DisableDevelopmentMode -Register -ErrorAction Stop
        Write-Host 'Registered the Windows Search application package.'
    } catch {
        Write-Warning "Search app package registration failed: $($_.Exception.Message)"
    }
} else {
    Write-Warning "Search app manifest not found; skipped re-registration: $manifest"
}

Write-Host ''
Write-Host 'Reset sequence finished.'

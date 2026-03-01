[CmdletBinding(SupportsShouldProcess = $true)]
param()

$BackupRoot = "$env:LOCALAPPDATA\Packages_Backups"

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Log {
  param([string]$Msg)
  $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  Write-Host "[$ts] $Msg"
}

function Ensure-Dir {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Path $Path | Out-Null
  }
}

function Copy-FolderRobust {
  param(
    [Parameter(Mandatory)] [string]$Source,
    [Parameter(Mandatory)] [string]$Dest
  )

  Ensure-Dir $Dest

  # robocopy copies (does not move). /E includes empty dirs. /R:1 /W:1 to avoid endless retries.
  $cmd = @("robocopy", "`"$Source`"", "`"$Dest`"", "/E", "/COPY:DAT", "/R:1", "/W:1", "/NFL", "/NDL", "/NP")
  $p = Start-Process -FilePath $cmd[0] -ArgumentList $cmd[1..($cmd.Count - 1)] -Wait -PassThru -NoNewWindow

  # robocopy exit codes: 0-7 are “ok-ish”; >=8 indicates failure
  if ($p.ExitCode -ge 8) {
    throw "Robocopy failed (exit code $($p.ExitCode)) copying '$Source' -> '$Dest'"
  }
}

function Remove-PathSafe {
  param([string]$Path)
  if (Test-Path -LiteralPath $Path) {
    if ($PSCmdlet.ShouldProcess($Path, "Remove")) {
      Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue
    }
  }
}

function Get-PackageFamilyNameFromPath {
  param([string]$PackagePath)
  Split-Path -Leaf $PackagePath
}

function Find-SystemAppsManifestForFamily {
  param([string]$FamilyName)

  $root = Join-Path $env:windir "SystemApps"
  if (-not (Test-Path -LiteralPath $root)) { return $null }

  $candidate = Join-Path (Join-Path $root $FamilyName) "AppxManifest.xml"
  if (Test-Path -LiteralPath $candidate) { return $candidate }

  # Fallback: scan SystemApps for a folder name that starts with family name (rare but happens).
  $match = Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue |
  Where-Object { $_.Name -eq $FamilyName -or $_.Name -like "$FamilyName*" } |
  Select-Object -First 1
  if ($match) {
    $m = Join-Path $match.FullName "AppxManifest.xml"
    if (Test-Path -LiteralPath $m) { return $m }
  }
  return $null
}

function Try-ReregisterFromManifest {
  param([string]$FamilyName)

  $manifest = Find-SystemAppsManifestForFamily -FamilyName $FamilyName
  if (-not $manifest) {
    Write-Log "No SystemApps manifest found for $FamilyName (skip re-register)."
    return $false
  }

  Write-Log "Re-registering $FamilyName from: $manifest"
  if ($PSCmdlet.ShouldProcess($FamilyName, "Add-AppxPackage -Register")) {
    try {
      Add-AppxPackage -DisableDevelopmentMode -Register $manifest -ForceApplicationShutdown -ErrorAction Stop | Out-Null
      return $true
    }
    catch {
      Write-Log "Re-register FAILED for $FamilyName : $($_.Exception.Message)"
      return $false
    }
  }
  return $false
}

function Reset-PackageFolderSafe {
  param([string]$PkgPath)

  # Common “state/caches” inside package folders.
  # NOTE: LocalState/Settings are higher-impact (app data/settings loss).
  $toDelete = @(
    "LocalCache",
    "TempState",
    "AC\INetCache",
    "AC\INetCookies",
    "AC\Temp",
    "AC\#!001",
    "Settings",
    "LocalState",
    "RoamingState"
  )

  foreach ($rel in $toDelete) {
    $p = Join-Path $PkgPath $rel
    Remove-PathSafe -Path $p
  }
}

function Reset-PackageFolder {
  param([string]$PkgPath)

  $family = Get-PackageFamilyNameFromPath -PackagePath $PkgPath

  # 1) Never full-delete these
  if ($global:NeverNukeInAggressive | Where-Object { $family -like "*$_*" } | Select-Object -First 1) {

    # For identity-sensitive packages, preserve LocalState/Settings
    if ($global:IdentitySensitive | Where-Object { $family -like "*$_*" } | Select-Object -First 1) {
      Write-Log "Aggressive: $family is identity-sensitive; using LIGHT reset (preserve LocalState/Settings)."
      # preserve Settings + LocalState.
      $toDelete = @(
        "LocalCache",
        "TempState",
        "AC\INetCache",
        "AC\INetCookies",
        "AC\Temp",
        "AC\#!001",
        "RoamingState"
      )

      foreach ($rel in $toDelete) {
        $p = Join-Path $PkgPath $rel
        Remove-PathSafe -Path $p
      }
      return
    }

    Write-Log "Aggressive: $family is protected; using SAFE reset (no full delete)."
    Reset-PackageFolderSafe -PkgPath $PkgPath
    return
  }

  # Only nuke the whole folder if we can re-register from SystemApps.
  $manifest = Find-SystemAppsManifestForFamily -FamilyName $family
  if (-not $manifest) {
    Write-Log "Aggressive requested but no SystemApps manifest for $family; falling back to safe-mode reset."
    Reset-PackageFolderSafe -PkgPath $PkgPath
    return
  }

  # Full delete + re-register
  Remove-PathSafe -Path $PkgPath
  [void](Try-ReregisterFromManifest -FamilyName $family)
}

# ---------------- Main ----------------

$packagesRoot = Join-Path $env:LOCALAPPDATA "Packages"
if (-not (Test-Path -LiteralPath $packagesRoot)) {
  throw "Packages root not found: $packagesRoot"
}

# Base exclusions
$excludes = @(
  "Microsoft.Windows.StartMenuExperienceHost",
  "Microsoft.Windows.ShellExperienceHost",
  "Microsoft.WindowsStore",
  "Microsoft.StorePurchaseApp",
  "Microsoft.DesktopAppInstaller"
)

# won't be full-deleted
$global:NeverNukeInAggressive = @(
  # Store stack + installer plumbing
  "Microsoft.WindowsStore",
  "Microsoft.StorePurchaseApp",
  "Microsoft.DesktopAppInstaller",

  # Settings + core UX
  "windows.immersivecontrolpanel",
  "Microsoft.Windows.ShellExperienceHost",
  "Microsoft.Windows.StartMenuExperienceHost",

  # Identity / account plumbing
  "Microsoft.AAD.BrokerPlugin",
  "Microsoft.AccountsControl",
  "Microsoft.Windows.CloudExperienceHost",

  # Treat CBS as sensitive
  "MicrosoftWindows.Client.CBS"
)

$global:IdentitySensitive = @(
  "Microsoft.AAD.BrokerPlugin",
  "Microsoft.AccountsControl",
  "Microsoft.Windows.CloudExperienceHost"
)

# backup
$global:BackupDir = Join-Path $BackupRoot ("Backup_{0}" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
Ensure-Dir $global:BackupDir 

Write-Log "Packages root: $packagesRoot"
Write-Log "Backup dir:    $global:BackupDir"

$pkgs = Get-ChildItem -LiteralPath $packagesRoot -Directory -ErrorAction Stop

# Apply excludes (skip completely)
$pkgs = $pkgs | Where-Object {
  $name = $_.Name
  -not ($excludes | Where-Object { $name -like "*$_*" } | Select-Object -First 1)
}

Write-Log ("Targets: {0}" -f $pkgs.Count)

foreach ($pkg in $pkgs) {
  $pkgPath = $pkg.FullName
  $family = $pkg.Name

  try {
    Write-Log "----"
    Write-Log "Target: $family"

    # backup
    $dest = Join-Path $global:BackupDir $family
    Write-Log "Backup: $pkgPath -> $dest"
    Copy-FolderRobust -Source $pkgPath -Dest $dest

    Reset-PackageFolder -PkgPath $pkgPath
  }
  catch {
    Write-Log "ERROR on $family : $($_.Exception.Message)"
    continue
  }
}

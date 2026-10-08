[CmdletBinding()]
param(
    [string]$OutputFile = "$PWD\EnabledFeatureOverrides.reg"
)

$BasePath = "HKLM:\SYSTEM\CurrentControlSet\Control\FeatureManagement\Overrides"

if (-not (Test-Path $BasePath)) {
    throw "FeatureManagement Overrides registry path was not found."
}

$Lines = [System.Collections.Generic.List[string]]::new()

$Lines.Add("Windows Registry Editor Version 5.00")
$Lines.Add("")

$ExportedCount = 0
$MissingOptionsCount = 0

Get-ChildItem -Path $BasePath -Recurse -ErrorAction SilentlyContinue |
    ForEach-Object {

        $Key = $_

        try {
            $Properties = Get-ItemProperty -LiteralPath $Key.PSPath -ErrorAction Stop
        }
        catch {
            return
        }

        # Ignore registry keys that do not contain EnabledState.
        if ($null -eq $Properties.PSObject.Properties["EnabledState"]) {
            return
        }

        $EnabledState = [UInt32]$Properties.EnabledState

        # ViVe feature state values:
        #
        # 0 = Default
        # 1 = Disabled
        # 2 = Enabled
        #
        # "Non-disabled" therefore means anything except 1.
        if ($EnabledState -eq 1) {
            return
        }

        $RelativePath = $Key.Name -replace "^HKEY_LOCAL_MACHINE\\", ""

        $Lines.Add("[$("HKEY_LOCAL_MACHINE\$RelativePath")]")
        $Lines.Add(
            '"EnabledState"=dword:{0:x8}' -f $EnabledState
        )

        if ($null -ne $Properties.PSObject.Properties["EnabledStateOptions"]) {
            $EnabledStateOptions = [UInt32]$Properties.EnabledStateOptions

            $Lines.Add(
                '"EnabledStateOptions"=dword:{0:x8}' -f $EnabledStateOptions
            )
        }
        else {
            # Do not invent a value if the original key did not contain one.
            $MissingOptionsCount++
        }

        $Lines.Add("")
        $ExportedCount++
    }

# .reg files normally use UTF-16 LE encoding.
$Lines | Set-Content -LiteralPath $OutputFile -Encoding Unicode

Write-Host ""
Write-Host "Export complete"
Write-Host "Output file          $OutputFile"
Write-Host "Overrides exported   $ExportedCount"

if ($MissingOptionsCount -gt 0) {
    Write-Warning "$MissingOptionsCount exported keys did not contain EnabledStateOptions, so that value was omitted for those keys."
}
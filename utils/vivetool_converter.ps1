# Derived from https://raw.githubusercontent.com/thebookisclosed/ViVe/master/ViVe/ObfuscationHelpers.cs via AI / LLM

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [UInt32[]]$Id,

    [ValidateRange(0, 255)]
    [UInt32]$Priority = 14,

    [switch]$Reverse
)

$C1 = [Convert]::ToUInt32("74161A4E", 16)
$C2 = [Convert]::ToUInt32("8FB23D4F", 16)
$C3 = [Convert]::ToUInt32("833EA8FF", 16)
$Mask32 = [UInt64]0xFFFFFFFF

function Swap-Bytes32 {
    param(
        [UInt32]$Value
    )

    $v = [UInt64]$Value

    $v = (($v -shr 16) -bor (($v -shl 16) -band $Mask32)) -band $Mask32

    $v = (
        (($v -band 0xFF00FF00) -shr 8) -bor
        (($v -band 0x00FF00FF) -shl 8)
    ) -band $Mask32

    return [UInt32]$v
}

function Rotate-Right32 {
    param(
        [UInt32]$Value,
        [Int32]$Shift
    )

    # C# masks 32-bit shift counts to the low 5 bits.
    # This also reproduces ViVe's RotateRight32(value, -1).
    $s = $Shift -band 31

    if ($s -eq 0) {
        return $Value
    }

    $v = [UInt64]$Value

    $result = (
        ($v -shr $s) -bor
        (($v -shl (32 - $s)) -band $Mask32)
    ) -band $Mask32

    return [UInt32]$result
}

function ConvertTo-ViVeRegistryId {
    param(
        [UInt32]$FeatureId
    )

    $x = [UInt32]($FeatureId -bxor $C1)
    $x = Swap-Bytes32 $x
    $x = [UInt32]($x -bxor $C2)
    $x = Rotate-Right32 $x -1
    $x = [UInt32]($x -bxor $C3)

    return $x
}

function ConvertFrom-ViVeRegistryId {
    param(
        [UInt32]$RegistryId
    )

    $x = [UInt32]($RegistryId -bxor $C3)
    $x = Rotate-Right32 $x 1
    $x = [UInt32]($x -bxor $C2)
    $x = Swap-Bytes32 $x
    $x = [UInt32]($x -bxor $C1)

    return $x
}

foreach ($CurrentId in $Id) {

    if ($Reverse) {
        $FeatureId = ConvertFrom-ViVeRegistryId $CurrentId
        $RegistryId = $CurrentId
    }
    else {
        $FeatureId = $CurrentId
        $RegistryId = ConvertTo-ViVeRegistryId $CurrentId
    }

    $RegistryPath =
        "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FeatureManagement\Overrides\$Priority\$RegistryId"

    Write-Host ""
    Write-Host "ViVe feature ID   $FeatureId"
    Write-Host "Registry ID       $RegistryId"
    Write-Host "Priority          $Priority"
    Write-Host "Registry path     $RegistryPath"
    Write-Host ""
    Write-Host "REG entry"
    Write-Host ""
    Write-Host "[$RegistryPath]"
    Write-Host '"EnabledState"=dword:00000002'
    Write-Host '"EnabledStateOptions"=dword:00000000'
}
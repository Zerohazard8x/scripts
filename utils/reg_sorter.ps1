
param(
    [Parameter(Mandatory)]
    [string[]]$Paths
)

foreach ($path in $Paths) {
    $resolved = (Resolve-Path -LiteralPath $path).Path
    $lines = @(Get-Content -LiteralPath $resolved -Encoding Unicode)

    $header = 'Windows Registry Editor Version 5.00'
    $sections = @()
    $current = $null

    foreach ($line in $lines) {
        if ($line -match '^\[') {
            if ($null -ne $current) {
                $sections += $current
            }
            $current = @{
                Key = $line
                Values = @()
            }
        }
        elseif ($null -ne $current -and $line.Trim()) {
            $current.Values += $line
        }
    }

    if ($null -ne $current) {
        $sections += $current
    }

    $output = @($header, '')

    foreach ($section in ($sections | Sort-Object Key -CaseSensitive)) {
        $output += $section.Key
        $output += $section.Values | Sort-Object -CaseSensitive
        $output += ''
    }

    $destination = Join-Path `
        (Split-Path $resolved) `
        (([IO.Path]::GetFileNameWithoutExtension($resolved)) + '.sorted.reg')

    $output | Set-Content -LiteralPath $destination -Encoding Unicode
    Write-Host "Saved $destination"
}

param(
    [Parameter(Mandatory)]
    [string[]]$Paths
)

foreach ($path in $Paths) {
    $resolved = (Resolve-Path -LiteralPath $path).Path
    $reader = [IO.StreamReader]::new($resolved, [Text.UTF8Encoding]::new($false), $true)
    try {
        $text = $reader.ReadToEnd()
        $encoding = $reader.CurrentEncoding
    }
    finally { $reader.Dispose() }

    $newline = if ($text.Contains("`r`n")) { "`r`n" } elseif ($text.Contains("`n")) { "`n" } else { "`r" }
    $endsWithNewline = $text -match '(\r\n|\n|\r)$'
    $lines = @($text -split '\r\n|\n|\r')
    if ($endsWithNewline) { $lines = @($lines | Select-Object -SkipLast 1) }

    $preamble = @()
    $sections = @()
    $current = $null

    foreach ($line in $lines) {
        if ($line -match '^\[[^\]]+\]$') {
            if ($null -ne $current) {
                $sections += $current
            }
            $current = @{
                Key = $line
                Values = @()
                Blanks = @()
            }
        }
        elseif ($null -ne $current) {
            if (-not $line.Trim()) {
                $current['Blanks'] += $line
            }
            elseif ($current['Values'].Count -and $current['Values'][-1] -match '\\$' -and $line -match '^\s+') {
                $current['Values'][-1] += $newline + $line
            }
            else {
                $current['Values'] += $line
            }
        }
        else { $preamble += $line }
    }

    if ($null -ne $current) {
        $sections += $current
    }

    $output = @()
    if ($sections.Count) {
        $output += $preamble
        foreach ($section in ($sections | Sort-Object { $_['Key'] } -CaseSensitive)) {
            $output += $section['Key']
            $output += $section['Values'] | Sort-Object -CaseSensitive
            $output += $section['Blanks']
        }
    }
    else { $output = @($lines | Sort-Object -CaseSensitive) }

    $destination = Join-Path `
        (Split-Path $resolved) `
        (([IO.Path]::GetFileNameWithoutExtension($resolved)) + '.sorted' + [IO.Path]::GetExtension($resolved))

    $result = [string]::Join($newline, [string[]]$output)
    if ($endsWithNewline) { $result += $newline }
    [IO.File]::WriteAllText($destination, $result, $encoding)
    Write-Host "Saved $destination"
}

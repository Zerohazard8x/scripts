Add-Type -AssemblyName System.Windows.Forms

$picker = New-Object System.Windows.Forms.OpenFileDialog
$picker.InitialDirectory = "$env:SystemDrive\PerfLogs"
$picker.Filter = 'Performance logs (*.blg)|*.blg'

if ($picker.ShowDialog() -ne 'OK') {
    return
}

$logicalProcessors = [Environment]::ProcessorCount

Write-Host "Reading performance log..."

# Import-Counter can emit non-terminating errors for individual invalid
# samples, particularly when processes start/stop during collection.
# Keep the samples it successfully imports and filter unusable values below.
$data = @(Import-Counter -Path $picker.FileName -ErrorAction SilentlyContinue)

if ($data.Count -eq 0) {
    Write-Warning "Import-Counter returned no sample sets."
    return
}

$allSamples = @(
    $data |
    ForEach-Object { $_.CounterSamples }
)

Write-Host "Imported $($allSamples.Count) counter samples."

$samples = @(
    $allSamples |
    Where-Object {
        # Keep numerically usable samples. Some process counters can have
        # non-success Status values when processes appear/disappear while
        # the log is being collected.
        $null -ne $_.CookedValue -and
        -not [double]::IsNaN([double]$_.CookedValue) -and
        -not [double]::IsInfinity([double]$_.CookedValue) -and
        $_.CookedValue -ge 0 -and

        $_.Path -match '\\(Working Set - Private|Private Bytes|% Processor Time|IO Read Bytes/sec|IO Write Bytes/sec|IO Read Operations/sec|IO Write Operations/sec)$' -and
        $_.InstanceName -notmatch '^(_total|idle)$'
    }
)

Write-Host "Usable matching samples: $($samples.Count)"

if ($samples.Count -eq 0) {
    Write-Warning "No usable process samples were found in this log."

    Write-Host ""
    Write-Host "Counter names actually present in the file:"
    $allSamples |
        Select-Object -ExpandProperty Path -Unique |
        Sort-Object |
        ForEach-Object { Write-Host $_ }

    Write-Host ""
    Write-Host "Status values actually present:"
    $allSamples |
        Group-Object Status |
        Sort-Object Count -Descending |
        Format-Table Name, Count -AutoSize

    return
}

function Get-Metrics {
    param($Items)

    if (-not $Items -or $Items.Count -eq 0) {
        return $null
    }

    $Items | Measure-Object CookedValue -Average -Maximum
}

function Round-OrNull {
    param(
        $Value,
        [double]$Divisor = 1,
        [int]$Digits = 1
    )

    if ($null -eq $Value) {
        return $null
    }

    [math]::Round(($Value / $Divisor), $Digits)
}

$report = @(
    $samples |
    Group-Object InstanceName |
    ForEach-Object {

        $ws = @(
            $_.Group |
            Where-Object Path -match '\\Working Set - Private$'
        )

        $pb = @(
            $_.Group |
            Where-Object Path -match '\\Private Bytes$'
        )

        $cpu = @(
            $_.Group |
            Where-Object Path -match '\\% Processor Time$'
        )

        $read = @(
            $_.Group |
            Where-Object Path -match '\\IO Read Bytes/sec$'
        )

        $write = @(
            $_.Group |
            Where-Object Path -match '\\IO Write Bytes/sec$'
        )

        $readOps = @(
            $_.Group |
            Where-Object Path -match '\\IO Read Operations/sec$'
        )

        $writeOps = @(
            $_.Group |
            Where-Object Path -match '\\IO Write Operations/sec$'
        )

        $wsMetrics       = Get-Metrics $ws
        $pbMetrics       = Get-Metrics $pb
        $cpuMetrics      = Get-Metrics $cpu
        $readMetrics     = Get-Metrics $read
        $writeMetrics    = Get-Metrics $write
        $readOpsMetrics  = Get-Metrics $readOps
        $writeOpsMetrics = Get-Metrics $writeOps

        [pscustomobject]@{
            Process = $_.Name

            PeakCPU_Percent = Round-OrNull `
                $cpuMetrics.Maximum $logicalProcessors 1

            AverageCPU_Percent = Round-OrNull `
                $cpuMetrics.Average $logicalProcessors 1

            PeakPrivateRAM_MiB = Round-OrNull `
                $wsMetrics.Maximum 1MB 1

            AveragePrivateRAM_MiB = Round-OrNull `
                $wsMetrics.Average 1MB 1

            PeakPrivateBytes_MiB = Round-OrNull `
                $pbMetrics.Maximum 1MB 1

            AveragePrivateBytes_MiB = Round-OrNull `
                $pbMetrics.Average 1MB 1

            PeakRead_MiBps = Round-OrNull `
                $readMetrics.Maximum 1MB 2

            AverageRead_MiBps = Round-OrNull `
                $readMetrics.Average 1MB 2

            PeakWrite_MiBps = Round-OrNull `
                $writeMetrics.Maximum 1MB 2

            AverageWrite_MiBps = Round-OrNull `
                $writeMetrics.Average 1MB 2

            PeakReadOps_PerSec = Round-OrNull `
                $readOpsMetrics.Maximum 1 1

            AverageReadOps_PerSec = Round-OrNull `
                $readOpsMetrics.Average 1 1

            PeakWriteOps_PerSec = Round-OrNull `
                $writeOpsMetrics.Maximum 1 1

            AverageWriteOps_PerSec = Round-OrNull `
                $writeOpsMetrics.Average 1 1

            Samples = @(
                $ws.Count,
                $pb.Count,
                $cpu.Count,
                $read.Count,
                $write.Count
            ) |
            Measure-Object -Maximum |
            Select-Object -ExpandProperty Maximum
        }
    } |
    Sort-Object PeakPrivateRAM_MiB -Descending
)

if ($report.Count -eq 0) {
    Write-Warning "Samples were found, but no report rows could be created."
    return
}

$out = Join-Path `
    (Split-Path -Parent $picker.FileName) `
    'Resource-ranking.csv'

$report |
    Export-Csv $out -NoTypeInformation -Encoding UTF8

$report | Format-Table -AutoSize

Write-Host ""
Write-Host "Created $($report.Count) report rows."
Write-Host "Saved: $out"
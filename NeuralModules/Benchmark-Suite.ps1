<#
.SYNOPSIS
    Benchmark Suite v4.0
    Sistema de pruebas de rendimiento antes/después de optimizaciones.

.DESCRIPTION
    Ejecuta tests de:
    - CPU (Single/Multi-thread)
    - RAM (Lectura/Escritura)
    - Disco (Secuencial/Random)
    - Red (Latencia/Throughput)
    - Boot Time

.NOTES
    Parte de Windows Neural Optimizer v4.0
    Creditos: Jose Bustamante
#>

if (-not (Get-Command "Write-Log" -ErrorAction SilentlyContinue)) {
    $currentDir = Split-Path $MyInvocation.MyCommand.Path
    $utilsPath = Join-Path $currentDir "NeuralUtils.psm1"
    if (Test-Path $utilsPath) { Import-Module $utilsPath -Force -DisableNameChecking }
}

Invoke-AdminCheck -Silent

$Script:BenchmarkResults = @{
    Timestamp = Get-Date
    Tests     = @{}
}

function Test-CpuPerformance {
    Write-Host " [+] CPU Single-Thread Test..." -ForegroundColor Cyan
    
    $start = Get-Date
    $iterations = 1000000
    $result = 0
    
    for ($i = 0; $i -lt $iterations; $i++) {
        $result += [math]::Sqrt($i)
    }
    
    $elapsed = ((Get-Date) - $start).TotalMilliseconds
    $score = [math]::Round(($iterations / $elapsed) * 100, 2)
    
    Write-Host "   [OK] Single-Thread Score: $score" -ForegroundColor Green
    
    # Multi-thread test
    Write-Host " [+] CPU Multi-Thread Test..." -ForegroundColor Cyan
    
    $start = Get-Date
    $jobs = @()
    $cores = [Environment]::ProcessorCount
    
    for ($i = 0; $i -lt $cores; $i++) {
        $jobs += Start-Job -ScriptBlock {
            $result = 0
            for ($j = 0; $j -lt 500000; $j++) {
                $result += [math]::Sqrt($j)
            }
            return $result
        }
    }
    
    $null = $jobs | Wait-Job
    $jobs | Remove-Job -Force
    
    $elapsed = ((Get-Date) - $start).TotalMilliseconds
    $multiScore = [math]::Round(($cores * 500000 / $elapsed) * 100, 2)
    
    Write-Host "   [OK] Multi-Thread Score: $multiScore" -ForegroundColor Green
    
    return @{
        SingleThread = $score
        MultiThread  = $multiScore
    }
}

function Test-RamPerformance {
    Write-Host " [+] RAM Performance Test..." -ForegroundColor Cyan
    
    $arraySize = 10000000
    $array = New-Object byte[] $arraySize
    
    # Write test
    $start = Get-Date
    for ($i = 0; $i -lt $arraySize; $i++) {
        $array[$i] = [byte]($i % 256)
    }
    $writeTime = ((Get-Date) - $start).TotalMilliseconds
    $writeMBps = [math]::Round(($arraySize / 1MB) / ($writeTime / 1000), 2)
    
    # Read test
    $start = Get-Date
    $sum = 0
    for ($i = 0; $i -lt $arraySize; $i++) {
        $sum += $array[$i]
    }
    $readTime = ((Get-Date) - $start).TotalMilliseconds
    $readMBps = [math]::Round(($arraySize / 1MB) / ($readTime / 1000), 2)
    
    Write-Host "   [OK] Write: $writeMBps MB/s" -ForegroundColor Green
    Write-Host "   [OK] Read: $readMBps MB/s" -ForegroundColor Green
    
    return @{
        WriteMBps = $writeMBps
        ReadMBps  = $readMBps
    }
}

function Test-DiskPerformance {
    Write-Host " [+] Disk Performance Test..." -ForegroundColor Cyan
    
    $testFile = "$env:TEMP\neural_bench_test.tmp"
    $testSize = 100MB
    $blockSize = 1MB
    
    try {
        # Sequential Write
        $data = New-Object byte[] $blockSize
        $start = Get-Date
        $stream = [System.IO.File]::Create($testFile)
        
        for ($i = 0; $i -lt ($testSize / $blockSize); $i++) {
            $stream.Write($data, 0, $blockSize)
        }
        $stream.Close()
        
        $writeTime = ((Get-Date) - $start).TotalSeconds
        $writeMBps = [math]::Round(($testSize / 1MB) / $writeTime, 2)
        
        # Sequential Read
        $start = Get-Date
        $stream = [System.IO.File]::OpenRead($testFile)
        
        while ($stream.Position -lt $stream.Length) {
            $null = $stream.Read($data, 0, $blockSize)
        }
        $stream.Close()
        
        $readTime = ((Get-Date) - $start).TotalSeconds
        $readMBps = [math]::Round(($testSize / 1MB) / $readTime, 2)
        
        Write-Host "   [OK] Sequential Write: $writeMBps MB/s" -ForegroundColor Green
        Write-Host "   [OK] Sequential Read: $readMBps MB/s" -ForegroundColor Green
        
        # Cleanup
        Remove-Item -Path $testFile -Force -ErrorAction SilentlyContinue
        
        return @{
            SeqWriteMBps = $writeMBps
            SeqReadMBps  = $readMBps
        }
    }
    catch {
        Write-Host "   [!] Error en test de disco: $_" -ForegroundColor Yellow
        return @{
            SeqWriteMBps = 0
            SeqReadMBps  = 0
        }
    }
}

function Test-NetworkPerformance {
    Write-Host " [+] Network Latency Test..." -ForegroundColor Cyan
    
    $targets = @(
        @{ Name = "Google DNS"; IP = "8.8.8.8" },
        @{ Name = "Cloudflare"; IP = "1.1.1.1" }
    )
    
    $results = @{}
    
    foreach ($target in $targets) {
        try {
            $ping = Test-Connection -ComputerName $target.IP -Count 5 -ErrorAction SilentlyContinue
            if ($ping) {
                $avg = ($ping | Measure-Object -Property ResponseTime -Average).Average
                $results[$target.Name] = [math]::Round($avg, 2)
                Write-Host "   [OK] $($target.Name): $($results[$target.Name]) ms" -ForegroundColor Green
            }
        }
        catch {}
    }
    
    return $results
}

function Get-BootTime {
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $bootTime = $os.LastBootUpTime
        # Uptime check removed as unused
        
        # Estimate boot time (desde apagado hasta escritorio)
        # Windows guarda esto en eventos del sistema
        $bootDuration = Get-WinEvent -FilterHashtable @{
            LogName = 'System'
            ID      = 100
        } -MaxEvents 1 -ErrorAction SilentlyContinue
        
        if ($bootDuration) {
            $bootSeconds = $bootDuration.Properties[0].Value / 1000
            return [math]::Round($bootSeconds, 2)
        }
    }
    catch {}
    
    return $null
}

function Start-BenchmarkSuite {
    Write-Section "BENCHMARK SUITE v4.0"
    
    Write-Host " [i] Este benchmark tomará aproximadamente 2-3 minutos." -ForegroundColor Yellow
    Write-Host " [i] Cierre otras aplicaciones para resultados precisos." -ForegroundColor Yellow
    Write-Host ""
    
    $response = Read-Host " >> ¿Continuar? (S/N)"
    if ($response -notmatch '^[Ss]') {
        Write-Host " [i] Benchmark cancelado." -ForegroundColor Yellow
        return
    }
    
    Write-Host ""
    Write-Host " [+] Iniciando suite de benchmarks..." -ForegroundColor Cyan
    Write-Host ""
    
    $totalTests = 4
    $currentTest = 0
    
    # CPU Test
    $currentTest++
    Write-Progress -Activity "Benchmark Suite" -Status "Test $currentTest/$totalTests : CPU" -PercentComplete (($currentTest / $totalTests) * 100)
    $Script:BenchmarkResults.Tests.CPU = Test-CpuPerformance
    Write-Host ""
    
    # RAM Test
    $currentTest++
    Write-Progress -Activity "Benchmark Suite" -Status "Test $currentTest/$totalTests : RAM" -PercentComplete (($currentTest / $totalTests) * 100)
    $Script:BenchmarkResults.Tests.RAM = Test-RamPerformance
    Write-Host ""
    
    # Disk Test
    $currentTest++
    Write-Progress -Activity "Benchmark Suite" -Status "Test $currentTest/$totalTests : Disk" -PercentComplete (($currentTest / $totalTests) * 100)
    $Script:BenchmarkResults.Tests.Disk = Test-DiskPerformance
    Write-Host ""
    
    # Network Test
    $currentTest++
    Write-Progress -Activity "Benchmark Suite" -Status "Test $currentTest/$totalTests : Network" -PercentComplete (($currentTest / $totalTests) * 100)
    $Script:BenchmarkResults.Tests.Network = Test-NetworkPerformance
    Write-Host ""
    
    Write-Progress -Activity "Benchmark Suite" -Completed
    
    # Boot Time
    $bootTime = Get-BootTime
    if ($bootTime) {
        $Script:BenchmarkResults.Tests.BootTime = $bootTime
    }
    
    # Save results
    $resultsPath = Join-Path ([Environment]::GetFolderPath('Desktop')) "NeuralBenchmark_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    $Script:BenchmarkResults | ConvertTo-Json -Depth 5 | Out-File -FilePath $resultsPath -Encoding UTF8
    
    # Show summary
    Show-BenchmarkSummary
    
    Write-Host ""
    Write-Host " [OK] Resultados guardados en:" -ForegroundColor Green
    Write-Host "      $resultsPath" -ForegroundColor Gray
    Write-Host ""
}

function Show-BenchmarkSummary {
    Write-Host ""
    Write-Host " +========================================================+" -ForegroundColor Green
    Write-Host " |  BENCHMARK RESULTS                                     |" -ForegroundColor Green
    Write-Host " +========================================================+" -ForegroundColor Green
    Write-Host ""
    
    $r = $Script:BenchmarkResults.Tests
    
    Write-Host " CPU Performance:" -ForegroundColor Cyan
    Write-Host "   Single-Thread Score: $($r.CPU.SingleThread)" -ForegroundColor Gray
    Write-Host "   Multi-Thread Score:  $($r.CPU.MultiThread)" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host " RAM Performance:" -ForegroundColor Cyan
    Write-Host "   Write Speed: $($r.RAM.WriteMBps) MB/s" -ForegroundColor Gray
    Write-Host "   Read Speed:  $($r.RAM.ReadMBps) MB/s" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host " Disk Performance:" -ForegroundColor Cyan
    Write-Host "   Sequential Write: $($r.Disk.SeqWriteMBps) MB/s" -ForegroundColor Gray
    Write-Host "   Sequential Read:  $($r.Disk.SeqReadMBps) MB/s" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host " Network Latency:" -ForegroundColor Cyan
    foreach ($net in $r.Network.GetEnumerator()) {
        Write-Host "   $($net.Key): $($net.Value) ms" -ForegroundColor Gray
    }
    
    if ($r.BootTime) {
        Write-Host ""
        Write-Host " Boot Time: $($r.BootTime) seconds" -ForegroundColor Cyan
    }
    
    Write-Host ""
}

function Compare-Benchmarks {
    param(
        [string]$Before,
        [string]$After
    )
    
    if (-not (Test-Path $Before) -or -not (Test-Path $After)) {
        Write-Host " [!] Archivos de benchmark no encontrados." -ForegroundColor Red
        return
    }
    
    try {
        $b1 = Get-Content $Before -Raw | ConvertFrom-Json
        $b2 = Get-Content $After -Raw | ConvertFrom-Json
        
        Write-Section "BENCHMARK COMPARISON"
        
        Write-Host " Antes:  $($b1.Timestamp)" -ForegroundColor Gray
        Write-Host " Después: $($b2.Timestamp)" -ForegroundColor Gray
        Write-Host ""
        
        # CPU
        $cpuDiff = [math]::Round((($b2.Tests.CPU.MultiThread - $b1.Tests.CPU.MultiThread) / $b1.Tests.CPU.MultiThread) * 100, 2)
        $cpuColor = if ($cpuDiff -gt 0) { "Green" } elseif ($cpuDiff -lt 0) { "Red" } else { "Gray" }
        Write-Host " CPU Multi-Thread: " -ForegroundColor White -NoNewline
        Write-Host "$cpuDiff%" -ForegroundColor $cpuColor
        
        # RAM
        $ramDiff = [math]::Round((($b2.Tests.RAM.ReadMBps - $b1.Tests.RAM.ReadMBps) / $b1.Tests.RAM.ReadMBps) * 100, 2)
        $ramColor = if ($ramDiff -gt 0) { "Green" } elseif ($ramDiff -lt 0) { "Red" } else { "Gray" }
        Write-Host " RAM Read Speed:   " -ForegroundColor White -NoNewline
        Write-Host "$ramDiff%" -ForegroundColor $ramColor
        
        # Disk
        $diskDiff = [math]::Round((($b2.Tests.Disk.SeqReadMBps - $b1.Tests.Disk.SeqReadMBps) / $b1.Tests.Disk.SeqReadMBps) * 100, 2)
        $diskColor = if ($diskDiff -gt 0) { "Green" } elseif ($diskDiff -lt 0) { "Red" } else { "Gray" }
        Write-Host " Disk Read Speed:  " -ForegroundColor White -NoNewline
        Write-Host "$diskDiff%" -ForegroundColor $diskColor
        
        Write-Host ""
    }
    catch {
        Write-Host " [!] Error comparando benchmarks: $_" -ForegroundColor Red
    }
}

# Menu
Write-Section "BENCHMARK SUITE v4.0"
Write-Host " 1. Ejecutar Benchmark Completo" -ForegroundColor White
Write-Host " 2. Comparar Dos Benchmarks" -ForegroundColor White
Write-Host " 3. Salir" -ForegroundColor DarkGray
Write-Host ""

$choice = Read-Host " >> Seleccione opción"

switch ($choice) {
    '1' { Start-BenchmarkSuite }
    '2' {
        Write-Host ""
        $before = Read-Host " Ruta del benchmark ANTES"
        $after = Read-Host " Ruta del benchmark DESPUES"
        Compare-Benchmarks -Before $before -After $after
    }
    default { Write-Host " [i] Saliendo..." -ForegroundColor Gray }
}

Wait-ForKeyPress

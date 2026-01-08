<#
.SYNOPSIS
    Real-Time System Monitor v4.0
    Monitor de recursos en consola con estilo HUD.

.DESCRIPTION
    Muestra en tiempo real:
    - Uso CPU Global y por Core
    - Uso RAM (Used/Free/Cache)
    - Actividad de Disco (R/W)
    - Red (Up/Down)
    - Top Procesos
    - Temperatura (si es accesible)

.NOTES
    Parte de Windows Neural Optimizer v5.0
    Creditos: Jose Bustamante
#>

if (-not (Get-Command "Write-Log" -ErrorAction SilentlyContinue)) {
    $currentDir = Split-Path $MyInvocation.MyCommand.Path
    $utilsPath = Join-Path $currentDir "NeuralUtils.psm1"
    if (Test-Path $utilsPath) { Import-Module $utilsPath -Force -DisableNameChecking }
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Show-Bar {
    param(
        [int]$Value,
        [int]$Length = 20,
        [string]$Color = "Green"
    )
    
    $filledLen = [math]::Round(($Value / 100) * $Length)
    $emptyLen = $Length - $filledLen
    
    $filled = "█" * $filledLen
    $empty = "░" * $emptyLen
    
    if ($Value -gt 90) { $Color = "Red" }
    elseif ($Value -gt 70) { $Color = "Yellow" }
    
    Write-Host "[" -NoNewline -ForegroundColor DarkGray
    Write-Host $filled -NoNewline -ForegroundColor $Color
    Write-Host $empty -NoNewline -ForegroundColor DarkGray
    Write-Host "] $Value%" -ForegroundColor $Color
}

function Get-NetworkSpeed {
    $net = Get-Counter "\Network Interface(*)\Bytes Total/sec" | Select-Object -ExpandProperty CounterSamples | Measure-Object -Property CookedValue -Sum
    return [math]::Round($net.Sum / 1KB, 1)
}

function Get-TopProcesses {
    return Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 -Property Name, CPU, WorkingSet
}

# ============================================================================
# MAIN MONITOR LOOP
# ============================================================================

function Start-SystemMonitor {
    $loop = $true
    
    Clear-Host
    Write-Host " INICIANDO MONITOR DE SISTEMA..." -ForegroundColor Cyan
    Start-Sleep -Seconds 1
    
    try {
        while ($loop) {
            # Collect Metrics
            $os = Get-WmiObject Win32_OperatingSystem
            $cpuPercent = (Get-WmiObject Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
            
            $totalRam = [math]::Round($os.TotalVisibleMemorySize / 1KB, 1)
            $freeRam = [math]::Round($os.FreePhysicalMemory / 1KB, 1)
            $usedRam = $totalRam - $freeRam
            $ramPercent = [math]::Round(($usedRam / $totalRam) * 100, 0)
            
            # Clear Screen for refresh (move cursor to top instead of clear host avoids flicker)
            [Console]::SetCursorPosition(0, 0)
            
            Write-Host " +=========================================================+" -ForegroundColor Cyan
            Write-Host " | SYSTEM MONITOR HUD v4.0                                 |" -ForegroundColor White
            Write-Host " +=========================================================+" -ForegroundColor Cyan
            Write-Host ""
            
            # CPU
            Write-Host " CPU LOAD:   " -NoNewline
            Show-Bar -Value $cpuPercent -Length 30
            
            # RAM
            Write-Host " RAM USAGE:  " -NoNewline
            Show-Bar -Value $ramPercent -Length 30
            Write-Host "             ($usedRam MB / $totalRam MB)" -ForegroundColor DimGray
            
            Write-Host ""
            Write-Host " +---------------------------------------------------------+" -ForegroundColor DarkGray
            
            # Top Processes
            Write-Host " TOP PROCESOS (CPU):" -ForegroundColor Yellow
            $procs = Get-TopProcesses
            foreach ($p in $procs) {
                $pName = $p.Name
                if ($pName.Length -gt 15) { $pName = $pName.Substring(0, 12) + "..." }
                $pCpu = [math]::Round($p.CPU, 1)
                $pRam = [math]::Round($p.WorkingSet / 1MB, 0)
                
                Write-Host "   > $($pName.PadRight(18)) RAM: $($pRam.ToString().PadLeft(5)) MB   CPU: $pCpu" -ForegroundColor Gray
            }
            
            Write-Host ""
            Write-Host " +---------------------------------------------------------+" -ForegroundColor DarkGray
            Write-Host " Presiona [CTRL+C] para salir..." -ForegroundColor DarkGray
            
            Start-Sleep -Seconds 2
        }
    }
    catch {
        # Handle exit
        Write-Host ""
        Write-Host " Monitor detenido." -ForegroundColor Yellow
    }
}

Start-SystemMonitor

<#
.SYNOPSIS
    Neural Dashboard v1.0
    Real-time visualization of AI learning state and performance trends.

.DESCRIPTION
    Interactive dashboard showing:
    - Current system score vs historical average
    - Q-Table insights (best actions by state)
    - Performance trends (ASCII graph)
    - Active predictions and anomalies
    - Learning cycle statistics

.NOTES
    Part of Windows Neural Optimizer v6.0
    Author: Jose Bustamante
#>

if (-not (Get-Command "Write-Log" -ErrorAction SilentlyContinue)) {
    $currentDir = Split-Path $MyInvocation.MyCommand.Path
    $utilsPath = Join-Path $currentDir "NeuralUtils.psm1"
    if (Test-Path $utilsPath) { Import-Module $utilsPath -Force -DisableNameChecking }
}

$aiModulePath = Join-Path $PSScriptRoot "NeuralAI.psm1"
if (Test-Path $aiModulePath) { Import-Module $aiModulePath -Force -DisableNameChecking }

$Script:BrainPath = Join-Path $PSScriptRoot "..\NeuralBrain.json"
$Script:QTablePath = Join-Path $PSScriptRoot "..\NeuralQTable.json"
$Script:ConfigPath = Join-Path $PSScriptRoot "..\NeuralConfig.json"

function Show-ASCIIGraph {
    param([array]$Data, [string]$Title = "Performance Trend", [int]$Width = 50, [int]$Height = 10)
    if ($Data.Count -eq 0) { Write-Host "   No data available for graph" -ForegroundColor Yellow; return }
    $min = ($Data | Measure-Object -Minimum).Minimum
    $max = ($Data | Measure-Object -Maximum).Maximum
    if ($max -eq $min) { $max = $min + 1 }
    $range = $max - $min
    Write-Host ""
    Write-Host "   $Title" -ForegroundColor Cyan
    for ($row = $Height - 1; $row -ge 0; $row--) {
        $threshold = $min + ($range * $row / ($Height - 1))
        $label = [math]::Round($threshold, 0).ToString().PadLeft(3)
        Write-Host "   $label |" -NoNewline -ForegroundColor DarkGray
        $step = [math]::Max(1, [math]::Ceiling($Data.Count / $Width))
        for ($i = 0; $i -lt $Data.Count; $i += $step) {
            $value = $Data[$i]
            $normalizedRow = [math]::Floor(($value - $min) / $range * ($Height - 1))
            if ($normalizedRow -eq $row) { Write-Host "*" -NoNewline -ForegroundColor Green }
            elseif ($normalizedRow -gt $row) { Write-Host "|" -NoNewline -ForegroundColor DarkGreen }
            else { Write-Host " " -NoNewline }
        }
        Write-Host ""
    }
    Write-Host ""
}

function Show-CurrentStatus {
    Write-Host ""
    Write-Host " === NEURAL AI DASHBOARD ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " [+] Midiendo sistema actual..." -ForegroundColor Gray
    try {
        $metrics = Measure-SystemMetrics -DurationSeconds 3
        Write-Host ""
        Write-Host " SCORE ACTUAL: $($metrics.Score)/100" -ForegroundColor $(if ($metrics.Score -ge 80) { 'Green' } elseif ($metrics.Score -ge 60) { 'Yellow' } else { 'Red' })
        Write-Host " DPC Time:      $($metrics.DpcTime)%" -ForegroundColor DarkGray
        Write-Host " Interrupt:     $($metrics.InterruptTime)%" -ForegroundColor DarkGray
        Write-Host " Context Sw:    $($metrics.ContextSwitch)/sec" -ForegroundColor DarkGray
        Write-Host " Disk Queue:    $($metrics.DiskQueue)" -ForegroundColor DarkGray
        Write-Host " Network Ping:  $($metrics.NetworkPing)ms" -ForegroundColor DarkGray
    }
    catch { Write-Host " [!] Error midiendo metricas: $_" -ForegroundColor Red }
}

function Show-LearningStats {
    Write-Host ""
    Write-Host " === Q-LEARNING STATISTICS ===" -ForegroundColor Magenta
    $config = @{ Epsilon = 0.3; LearningCycles = 0 }
    if (Test-Path $Script:ConfigPath) {
        try { $config = Get-Content $Script:ConfigPath -Raw | ConvertFrom-Json } catch {}
    }
    $qTableStats = @{ States = 0; Actions = 0 }
    if (Test-Path $Script:QTablePath) {
        try {
            $qt = Get-Content $Script:QTablePath -Raw | ConvertFrom-Json
            $qTableStats.States = ($qt.PSObject.Properties).Count
            $qt.PSObject.Properties | ForEach-Object { $qTableStats.Actions += ($_.Value.PSObject.Properties).Count }
        }
        catch {}
    }
    $epsilon = if ($config.Epsilon) { $config.Epsilon } else { 0.3 }
    $cycles = if ($config.LearningCycles) { $config.LearningCycles } else { 0 }
    Write-Host ""
    Write-Host " Ciclos de Aprendizaje:  $cycles" -ForegroundColor White
    Write-Host " Tasa de Exploracion:    $([math]::Round($epsilon * 100, 1))%" -ForegroundColor $(if ($epsilon -gt 0.2) { 'Yellow' } else { 'Green' })
    Write-Host " Estados Conocidos:      $($qTableStats.States)" -ForegroundColor White
    Write-Host " Pares Estado-Accion:    $($qTableStats.Actions)" -ForegroundColor White
    $phaseName = if ($cycles -lt 10) { "Exploracion Inicial" } elseif ($cycles -lt 50) { "Aprendiendo Patrones" } elseif ($cycles -lt 100) { "Refinando Estrategia" } else { "Modo Experto" }
    Write-Host " Fase Actual: $phaseName" -ForegroundColor Cyan
}

function Show-QTableInsights {
    Write-Host ""
    Write-Host " === TOP ACCIONES APRENDIDAS ===" -ForegroundColor Green
    if (-not (Test-Path $Script:QTablePath)) {
        Write-Host " [i] Q-Table vacia. Ejecuta ciclos de aprendizaje primero." -ForegroundColor Yellow
        return
    }
    try {
        $qt = Get-Content $Script:QTablePath -Raw | ConvertFrom-Json
        $allActions = @()
        $qt.PSObject.Properties | ForEach-Object {
            $state = $_.Name
            $_.Value.PSObject.Properties | ForEach-Object {
                $allActions += [PSCustomObject]@{ State = $state; Action = $_.Name; QValue = $_.Value }
            }
        }
        if ($allActions.Count -eq 0) { Write-Host " [i] No hay acciones aprendidas aun." -ForegroundColor Yellow; return }
        $topActions = $allActions | Sort-Object QValue -Descending | Select-Object -First 8
        Write-Host ""
        foreach ($action in $topActions) {
            $color = if ($action.QValue -gt 0) { "Green" } elseif ($action.QValue -lt 0) { "Red" } else { "Gray" }
            Write-Host " Q=$([math]::Round($action.QValue, 3).ToString().PadLeft(7)) | $($action.Action.PadRight(15)) @ $($action.State)" -ForegroundColor $color
        }
    }
    catch { Write-Host " [!] Error leyendo Q-Table: $_" -ForegroundColor Red }
}

function Show-HistoricalTrend {
    Write-Host ""
    Write-Host " === TENDENCIA HISTORICA ===" -ForegroundColor Blue
    if (-not (Test-Path $Script:BrainPath)) {
        Write-Host " [i] No hay historial aun." -ForegroundColor Yellow
        return
    }
    try {
        $brain = Get-Content $Script:BrainPath -Raw | ConvertFrom-Json
        if (-not $brain.History -or $brain.History.Count -eq 0) { Write-Host " [i] Historial vacio." -ForegroundColor Yellow; return }
        $scores = @($brain.History | ForEach-Object { if ($_.FinalScore) { $_.FinalScore } elseif ($_.Score) { $_.Score } else { 50 } })
        if ($scores.Count -gt 2) {
            Show-ASCIIGraph -Data $scores -Title "Scores (ultimas $($scores.Count) sesiones)" -Width 40 -Height 8
            $avg = [math]::Round(($scores | Measure-Object -Average).Average, 1)
            Write-Host " Promedio: $avg" -ForegroundColor DarkGray
        }
        else { Write-Host " [i] Necesitas al menos 3 sesiones para graficar." -ForegroundColor Yellow }
    }
    catch { Write-Host " [!] Error leyendo historial: $_" -ForegroundColor Red }
}

function Show-Predictions {
    Write-Host ""
    Write-Host " === PREDICCIONES ACTUALES ===" -ForegroundColor Yellow
    try {
        if (Get-Command "Get-HardwareProfile" -ErrorAction SilentlyContinue) {
            $hw = Get-HardwareProfile
            $recommendation = Get-NeuralRecommendation -Hardware $hw -Workload "General"
            if ($recommendation) {
                Write-Host " Accion Recomendada: $($recommendation.ActionName)" -ForegroundColor Cyan
                Write-Host " Confianza: $($recommendation.Confidence)%" -ForegroundColor $(if ($recommendation.Confidence -ge 70) { 'Green' } else { 'Yellow' })
            }
            else { Write-Host " [i] No hay recomendaciones disponibles aun." -ForegroundColor Gray }
        }
    }
    catch { Write-Host " [i] Ejecuta mas ciclos de aprendizaje para obtener predicciones." -ForegroundColor Gray }
    $hour = (Get-Date).Hour
    $timePrediction = if ($hour -ge 6 -and $hour -lt 12) { "Manana - Perfil Productividad" } elseif ($hour -ge 12 -and $hour -lt 18) { "Tarde - Perfil Balanceado" } elseif ($hour -ge 18 -and $hour -lt 23) { "Noche - Perfil Gaming" } else { "Madrugada - Bajo Consumo" }
    Write-Host " Prediccion Horaria: $timePrediction" -ForegroundColor DarkGray
}

function Invoke-QuickLearning {
    Write-Host ""
    Write-Host " [+] Iniciando ciclo de aprendizaje rapido..." -ForegroundColor Cyan
    try {
        $hw = @{ CpuName = "Unknown"; PerformanceTier = "Standard" }
        if (Get-Command "Get-HardwareProfile" -ErrorAction SilentlyContinue) { $hw = Get-HardwareProfile }
        Invoke-NeuralLearning -ProfileName "Dashboard Quick Learn" -Hardware $hw -Workload "General"
    }
    catch { Write-Host " [!] Error en ciclo de aprendizaje: $_" -ForegroundColor Red }
}

function Reset-QLearning {
    Write-Host ""
    Write-Host " [!] ADVERTENCIA: Esto borrara toda la tabla Q" -ForegroundColor Red
    $confirm = Read-Host " >> Continuar? (SI/NO)"
    if ($confirm -eq "SI") {
        try {
            if (Test-Path $Script:QTablePath) { Remove-Item $Script:QTablePath -Force }
            if (Test-Path $Script:ConfigPath) { Remove-Item $Script:ConfigPath -Force }
            Write-Host " [OK] Q-Learning reiniciado" -ForegroundColor Green
        }
        catch { Write-Host " [!] Error: $_" -ForegroundColor Red }
    }
}

function Show-DashboardMenu {
    Clear-Host
    Show-CurrentStatus
    Show-LearningStats
    Write-Host ""
    Write-Host " === MENU ===" -ForegroundColor Gray
    Write-Host " 1. Ver Q-Table Insights"
    Write-Host " 2. Ver Tendencia Historica"
    Write-Host " 3. Ver Predicciones"
    Write-Host " 4. Ejecutar Ciclo de Aprendizaje"
    Write-Host " 5. Dashboard Completo"
    Write-Host " 6. Reiniciar Q-Learning" -ForegroundColor Red
    Write-Host " 7. Salir"
    Write-Host ""
}

while ($true) {
    Show-DashboardMenu
    $choice = Read-Host " >> Opcion"
    switch ($choice) {
        '1' { Show-QTableInsights; Read-Host " Presione ENTER" }
        '2' { Show-HistoricalTrend; Read-Host " Presione ENTER" }
        '3' { Show-Predictions; Read-Host " Presione ENTER" }
        '4' { Invoke-QuickLearning; Read-Host " Presione ENTER" }
        '5' { Clear-Host; Show-CurrentStatus; Show-LearningStats; Show-QTableInsights; Show-HistoricalTrend; Show-Predictions; Read-Host " Presione ENTER" }
        '6' { Reset-QLearning; Read-Host " Presione ENTER" }
        '7' { exit 0 }
        default { Write-Host " [!] Opcion invalida" -ForegroundColor Red; Start-Sleep -Seconds 1 }
    }
}

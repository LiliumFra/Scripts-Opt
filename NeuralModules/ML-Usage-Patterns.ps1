<#
.SYNOPSIS
    Machine Learning Usage Patterns v6.0
    Aprende comportamiento del usuario y predice optimizaciones óptimas.

.DESCRIPTION
    Características:
    - Pattern recognition (horarios de uso)
    - Workload prediction
    - Auto-suggest profile changes
    - Anomaly detection (malware, issues)
    - Performance forecasting
    - Adaptive optimization
    - History tracking (30 días)

.NOTES
    Parte de Windows Neural Optimizer v6.0
    Creditos: Jose Bustamante
    GitHub: https://github.com/LiliumFra/Scripts-Opt
#>

if (-not (Get-Command "Write-Log" -ErrorAction SilentlyContinue)) {
    $currentDir = Split-Path $MyInvocation.MyCommand.Path
    $utilsPath = Join-Path $currentDir "NeuralUtils.psm1"
    if (Test-Path $utilsPath) { Import-Module $utilsPath -Force -DisableNameChecking }
}

Invoke-AdminCheck -Silent

# ============================================================================
# DATA COLLECTION
# ============================================================================

$Script:DataPath = Join-Path $env:LOCALAPPDATA "NeuralOptimizer\ML"
$Script:HistoryFile = Join-Path $Script:DataPath "usage_history.json"
$Script:PatternsFile = Join-Path $Script:DataPath "learned_patterns.json"
$Script:AnomaliesFile = Join-Path $Script:DataPath "anomalies.json"

function Initialize-MLData {
    if (-not (Test-Path $Script:DataPath)) {
        New-Item -Path $Script:DataPath -ItemType Directory -Force | Out-Null
    }
}

function Get-CurrentUsageSnapshot {
    [CmdletBinding()]
    param()
    
    $snapshot = @{
        Timestamp     = Get-Date
        DayOfWeek     = (Get-Date).DayOfWeek.ToString()
        Hour          = (Get-Date).Hour
        
        System        = @{
            CpuUsage        = 0
            RamUsagePercent = 0
            ProcessCount    = 0
        }
        
        Processes     = @{
            Gaming       = @()
            Productivity = @()
            Creative     = @()
            Other        = @()
        }
        
        ActiveProfile = "Unknown"
    }
    
    try {
        # System metrics
        $cpu = Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average
        $os = Get-CimInstance Win32_OperatingSystem
        
        $snapshot.System.CpuUsage = [math]::Round($cpu.Average, 1)
        $snapshot.System.RamUsagePercent = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 1)
        $snapshot.System.ProcessCount = (Get-Process).Count
        
        # Process classification
        $processes = Get-Process
        
        $gamingPatterns = @("*game*", "*steam*", "*epic*", "*origin*", "*riot*", "*valorant*", "cs2", "dota2", "league*")
        $productivityPatterns = @("*office*", "*excel*", "*word*", "*teams*", "*outlook*", "*chrome*", "*edge*")
        $creativePatterns = @("*photoshop*", "*premiere*", "*obs*", "*davinci*", "*blender*", "*unity*")
        
        foreach ($proc in $processes) {
            $found = $false
            
            foreach ($pattern in $gamingPatterns) {
                if ($proc.Name -like $pattern) {
                    $snapshot.Processes.Gaming += $proc.Name
                    $found = $true
                    break
                }
            }
            
            if (-not $found) {
                foreach ($pattern in $productivityPatterns) {
                    if ($proc.Name -like $pattern) {
                        $snapshot.Processes.Productivity += $proc.Name
                        $found = $true
                        break
                    }
                }
            }
            
            if (-not $found) {
                foreach ($pattern in $creativePatterns) {
                    if ($proc.Name -like $pattern) {
                        $snapshot.Processes.Creative += $proc.Name
                        break
                    }
                }
            }
        }
        
        # Get active profile
        try {
            $configPath = "HKLM:\SOFTWARE\NeuralOptimizer"
            if (Test-Path $configPath) {
                $current = Get-ItemProperty -Path $configPath -Name "ActiveProfile" -ErrorAction SilentlyContinue
                if ($current) {
                    $snapshot.ActiveProfile = $current.ActiveProfile
                }
            }
        }
        catch {}
    }
    catch {
        Write-Host " [!] Error capturando snapshot: $_" -ForegroundColor Yellow
    }
    
    return $snapshot
}

function Add-UsageSnapshot {
    param($Snapshot)
    
    try {
        $history = @()
        
        if (Test-Path $Script:HistoryFile) {
            $history = Get-Content $Script:HistoryFile -Raw | ConvertFrom-Json
        }
        
        # Add new snapshot
        $history += $Snapshot
        
        # Keep only last 30 days
        $cutoffDate = (Get-Date).AddDays(-30)
        $history = $history | Where-Object { [DateTime]$_.Timestamp -gt $cutoffDate }
        
        # Save
        $history | ConvertTo-Json -Depth 5 -Compress | Out-File -FilePath $Script:HistoryFile -Encoding UTF8 -Force
        
        return $true
    }
    catch {
        return $false
    }
}

# ============================================================================
# PATTERN LEARNING
# ============================================================================

function Get-UsagePatterns {
    [CmdletBinding()]
    param()
    
    if (-not (Test-Path $Script:HistoryFile)) {
        return $null
    }
    
    try {
        $history = Get-Content $Script:HistoryFile -Raw | ConvertFrom-Json
        
        if ($history.Count -lt 10) {
            Write-Host " [i] Datos insuficientes para análisis (mínimo 10 snapshots)" -ForegroundColor Yellow
            return $null
        }
        
        # Analyze patterns by hour and day
        $patterns = @{
            ByHour         = @{}
            ByDayOfWeek    = @{}
            CommonProfiles = @{}
            Trends         = @{}
        }
        
        # By Hour (0-23)
        for ($hour = 0; $hour -lt 24; $hour++) {
            $hourData = $history | Where-Object { ([DateTime]$_.Timestamp).Hour -eq $hour }
            
            if ($hourData) {
                $patterns.ByHour[$hour] = @{
                    Samples               = $hourData.Count
                    AvgCpuUsage           = ($hourData.System.CpuUsage | Measure-Object -Average).Average
                    AvgRamUsage           = ($hourData.System.RamUsagePercent | Measure-Object -Average).Average
                    
                    GamingFrequency       = ($hourData | Where-Object { $_.Processes.Gaming.Count -gt 0 }).Count
                    ProductivityFrequency = ($hourData | Where-Object { $_.Processes.Productivity.Count -gt 0 }).Count
                    CreativeFrequency     = ($hourData | Where-Object { $_.Processes.Creative.Count -gt 0 }).Count
                    
                    MostCommonProfile     = ($hourData.ActiveProfile | Group-Object | Sort-Object Count -Descending | Select-Object -First 1).Name
                }
            }
        }
        
        # By Day of Week
        $daysOfWeek = @("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")
        foreach ($day in $daysOfWeek) {
            $dayData = $history | Where-Object { $_.DayOfWeek -eq $day }
            
            if ($dayData) {
                $patterns.ByDayOfWeek[$day] = @{
                    Samples               = $dayData.Count
                    GamingFrequency       = ($dayData | Where-Object { $_.Processes.Gaming.Count -gt 0 }).Count
                    ProductivityFrequency = ($dayData | Where-Object { $_.Processes.Productivity.Count -gt 0 }).Count
                    WorkloadType          = "Unknown"
                }
                
                # Classify day
                $gaming = $patterns.ByDayOfWeek[$day].GamingFrequency
                $productivity = $patterns.ByDayOfWeek[$day].ProductivityFrequency
                
                if ($gaming -gt $productivity) {
                    $patterns.ByDayOfWeek[$day].WorkloadType = "Gaming"
                }
                elseif ($productivity -gt $gaming) {
                    $patterns.ByDayOfWeek[$day].WorkloadType = "Productivity"
                }
                else {
                    $patterns.ByDayOfWeek[$day].WorkloadType = "Mixed"
                }
            }
        }
        
        # Save learned patterns
        $patterns | ConvertTo-Json -Depth 5 | Out-File -FilePath $Script:PatternsFile -Encoding UTF8 -Force
        
        return $patterns
    }
    catch {
        Write-Host " [!] Error analizando patrones: $_" -ForegroundColor Red
        return $null
    }
}

function Get-ProfilePrediction {
    [CmdletBinding()]
    param()
    
    $currentHour = (Get-Date).Hour
    
    if (-not (Test-Path $Script:PatternsFile)) {
        return $null
    }
    
    try {
        $patterns = Get-Content $Script:PatternsFile -Raw | ConvertFrom-Json
        
        # Get pattern for current hour
        $hourPattern = $patterns.ByHour.$currentHour
        
        if ($hourPattern) {
            $prediction = @{
                RecommendedProfile = $hourPattern.MostCommonProfile
                Confidence         = 0
                Reason             = ""
            }
            
            # Calculate confidence based on sample size
            if ($hourPattern.Samples -ge 20) {
                $prediction.Confidence = 90
            }
            elseif ($hourPattern.Samples -ge 10) {
                $prediction.Confidence = 70
            }
            else {
                $prediction.Confidence = 50
            }
            
            # Build reason
            if ($hourPattern.GamingFrequency -gt $hourPattern.ProductivityFrequency) {
                $prediction.Reason = "A esta hora ($currentHour:00) normalmente juegas"
            }
            elseif ($hourPattern.ProductivityFrequency -gt $hourPattern.GamingFrequency) {
                $prediction.Reason = "A esta hora ($currentHour:00) normalmente trabajas"
            }
            else {
                $prediction.Reason = "Uso mixto detectado a esta hora"
            }
            
            return $prediction
        }
    }
    catch {}
    
    return $null
}

# ============================================================================
# ANOMALY DETECTION
# ============================================================================

function Test-Anomalies {
    [CmdletBinding()]
    param()
    
    if (-not (Test-Path $Script:HistoryFile)) {
        return @()
    }
    
    try {
        $history = Get-Content $Script:HistoryFile -Raw | ConvertFrom-Json
        $anomalies = @()
        
        if ($history.Count -lt 20) {
            return @()
        }
        
        # Calculate baseline (last 7 days average)
        $recentHistory = $history | Select-Object -Last (7 * 24) # ~7 días
        
        $baselineCpu = ($recentHistory.System.CpuUsage | Measure-Object -Average).Average
        $baselineRam = ($recentHistory.System.RamUsagePercent | Measure-Object -Average).Average
        $baselineProcessCount = ($recentHistory.System.ProcessCount | Measure-Object -Average).Average
        
        # Get current snapshot
        $current = Get-CurrentUsageSnapshot
        
        # Check for anomalies
        
        # High CPU anomaly
        if ($current.System.CpuUsage -gt ($baselineCpu * 2) -and $current.System.CpuUsage -gt 70) {
            $anomalies += @{
                Type        = "HighCPU"
                Severity    = "High"
                Description = "CPU usage anormalmente alto: $($current.System.CpuUsage)% (Baseline: $([math]::Round($baselineCpu, 1))%)"
                Suggestion  = "Verificar procesos con System-Monitor.ps1"
                Timestamp   = Get-Date
            }
        }
        
        # High RAM anomaly
        if ($current.System.RamUsagePercent -gt ($baselineRam * 1.5) -and $current.System.RamUsagePercent -gt 85) {
            $anomalies += @{
                Type        = "HighRAM"
                Severity    = "High"
                Description = "RAM usage anormalmente alto: $($current.System.RamUsagePercent)% (Baseline: $([math]::Round($baselineRam, 1))%)"
                Suggestion  = "Ejecutar Advanced-Memory.ps1 → Memory Leak Detection"
                Timestamp   = Get-Date
            }
        }
        
        # Process count anomaly
        if ($current.System.ProcessCount -gt ($baselineProcessCount * 1.8)) {
            $anomalies += @{
                Type        = "HighProcessCount"
                Severity    = "Medium"
                Description = "Número de procesos anormalmente alto: $($current.System.ProcessCount) (Baseline: $([math]::Round($baselineProcessCount, 0)))"
                Suggestion  = "Verificar procesos sospechosos o malware"
                Timestamp   = Get-Date
            }
        }
        
        # Unknown process anomaly (new processes not seen before)
        $historicalProcesses = $history.Processes.Gaming + $history.Processes.Productivity + $history.Processes.Creative + $history.Processes.Other | Select-Object -Unique
        $currentProcesses = Get-Process | Select-Object -ExpandProperty Name
        
        $newProcesses = $currentProcesses | Where-Object { $_ -notin $historicalProcesses -and $_ -notmatch "svchost|system|dwm|explorer" }
        
        if ($newProcesses) {
            $anomalies += @{
                Type        = "UnknownProcesses"
                Severity    = "Medium"
                Description = "Procesos nuevos detectados: $($newProcesses -join ', ')"
                Suggestion  = "Verificar legitimidad de estos procesos"
                Timestamp   = Get-Date
            }
        }
        
        # Save anomalies
        if ($anomalies.Count -gt 0) {
            $existingAnomalies = @()
            if (Test-Path $Script:AnomaliesFile) {
                $existingAnomalies = Get-Content $Script:AnomaliesFile -Raw | ConvertFrom-Json
            }
            
            $allAnomalies = $existingAnomalies + $anomalies
            
            # Keep only last 100 anomalies
            $allAnomalies = $allAnomalies | Select-Object -Last 100
            
            $allAnomalies | ConvertTo-Json -Depth 5 | Out-File -FilePath $Script:AnomaliesFile -Encoding UTF8 -Force
        }
        
        return $anomalies
    }
    catch {
        return @()
    }
}

# ============================================================================
# AUTO-SUGGEST
# ============================================================================

function Get-SmartSuggestions {
    [CmdletBinding()]
    param()
    
    $suggestions = @()
    
    # Get prediction
    $prediction = Get-ProfilePrediction
    
    if ($prediction -and $prediction.Confidence -ge 70) {
        # Check if current profile matches prediction
        try {
            $configPath = "HKLM:\SOFTWARE\NeuralOptimizer"
            $currentProfile = "Unknown"
            
            if (Test-Path $configPath) {
                $current = Get-ItemProperty -Path $configPath -Name "ActiveProfile" -ErrorAction SilentlyContinue
                if ($current) {
                    $currentProfile = $current.ActiveProfile
                }
            }
            
            if ($currentProfile -ne $prediction.RecommendedProfile -and $prediction.RecommendedProfile -ne "Unknown") {
                $suggestions += @{
                    Type        = "ProfileChange"
                    Title       = "Cambio de Perfil Sugerido"
                    Description = "$($prediction.Reason). Perfil actual: $currentProfile"
                    Action      = "Cambiar a: $($prediction.RecommendedProfile)"
                    Confidence  = $prediction.Confidence
                    Priority    = 80
                }
            }
        }
        catch {}
    }
    
    # Check for anomalies
    $anomalies = Test-Anomalies
    
    foreach ($anomaly in $anomalies) {
        $priority = switch ($anomaly.Severity) {
            "High" { 95 }
            "Medium" { 75 }
            "Low" { 50 }
            default { 60 }
        }
        
        $suggestions += @{
            Type        = "Anomaly"
            Title       = "⚠️ Anomalía Detectada: $($anomaly.Type)"
            Description = $anomaly.Description
            Action      = $anomaly.Suggestion
            Confidence  = 85
            Priority    = $priority
        }
    }
    
    return $suggestions | Sort-Object -Property Priority -Descending
}

# ============================================================================
# BACKGROUND COLLECTOR
# ============================================================================

function Start-BackgroundCollector {
    [CmdletBinding()]
    param([int]$IntervalMinutes = 15)
    
    Write-Host ""
    Write-Host " ╔═══════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host " ║  ML BACKGROUND COLLECTOR ACTIVO                       ║" -ForegroundColor Green
    Write-Host " ╚═══════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host " [i] Recolectando datos cada $IntervalMinutes minutos..." -ForegroundColor Cyan
    Write-Host " [i] Presione CTRL+C para detener" -ForegroundColor DarkGray
    Write-Host ""
    
    $collectCount = 0
    
    while ($true) {
        try {
            $snapshot = Get-CurrentUsageSnapshot
            $success = Add-UsageSnapshot -Snapshot $snapshot
            
            if ($success) {
                $collectCount++
                Write-Host " [$(Get-Date -Format 'HH:mm:ss')] Snapshot #$collectCount capturado" -ForegroundColor Green
                
                # Every 10 snapshots, analyze patterns
                if ($collectCount % 10 -eq 0) {
                    Write-Host " [i] Analizando patrones..." -ForegroundColor Cyan
                    $patterns = Get-UsagePatterns
                    
                    if ($patterns) {
                        Write-Host " [OK] Patrones actualizados" -ForegroundColor Green
                    }
                }
            }
            else {
                Write-Host " [!] Error guardando snapshot" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host " [!] Error: $_" -ForegroundColor Red
        }
        
        Start-Sleep -Seconds ($IntervalMinutes * 60)
    }
}

# ============================================================================
# REPORTS
# ============================================================================

function Show-LearnedPatterns {
    param($Patterns)
    
    if (-not $Patterns) {
        Write-Host " [!] No hay patrones aprendidos" -ForegroundColor Yellow
        return
    }
    
    Write-Host ""
    Write-Host " ╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host " ║  PATRONES APRENDIDOS                                  ║" -ForegroundColor Cyan
    Write-Host " ╚═══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    # By Day of Week
    Write-Host " POR DÍA DE LA SEMANA:" -ForegroundColor Yellow
    Write-Host ""
    
    $daysOfWeek = @("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")
    foreach ($day in $daysOfWeek) {
        if ($Patterns.ByDayOfWeek.$day) {
            $dayPattern = $Patterns.ByDayOfWeek.$day
            $workloadColor = switch ($dayPattern.WorkloadType) {
                "Gaming" { "Magenta" }
                "Productivity" { "Blue" }
                "Mixed" { "Cyan" }
                default { "Gray" }
            }
            
            Write-Host " $day`: " -NoNewline
            Write-Host $dayPattern.WorkloadType -ForegroundColor $workloadColor -NoNewline
            Write-Host " ($($dayPattern.Samples) muestras)" -ForegroundColor DarkGray
        }
    }
    
    Write-Host ""
    Write-Host " POR HORA DEL DÍA (Top actividad):" -ForegroundColor Yellow
    Write-Host ""
    
    # Find peak hours
    $hourPatterns = @()
    for ($hour = 0; $hour -lt 24; $hour++) {
        if ($Patterns.ByHour.$hour) {
            $hourPattern = $Patterns.ByHour.$hour
            $hourPatterns += [PSCustomObject]@{
                Hour             = $hour
                Samples          = $hourPattern.Samples
                GamingFreq       = $hourPattern.GamingFrequency
                ProductivityFreq = $hourPattern.ProductivityFrequency
            }
        }
    }
    
    $topHours = $hourPatterns | Sort-Object -Property Samples -Descending | Select-Object -First 5
    
    foreach ($hourData in $topHours) {
        $hourStr = "$($hourData.Hour):00".PadLeft(5)
        Write-Host " $hourStr - " -NoNewline
        
        if ($hourData.GamingFreq -gt $hourData.ProductivityFreq) {
            Write-Host "Gaming " -NoNewline -ForegroundColor Magenta
        }
        elseif ($hourData.ProductivityFreq -gt $hourData.GamingFreq) {
            Write-Host "Productivity " -NoNewline -ForegroundColor Blue
        }
        else {
            Write-Host "Mixed " -NoNewline -ForegroundColor Cyan
        }
        
        Write-Host "($($hourData.Samples) muestras)" -ForegroundColor DarkGray
    }
    
    Write-Host ""
}

# ============================================================================
# MAIN MENU
# ============================================================================

function Show-MLMenu {
    Clear-Host
    
    $dataExists = Test-Path $Script:HistoryFile
    $sampleCount = 0
    
    if ($dataExists) {
        $history = Get-Content $Script:HistoryFile -Raw | ConvertFrom-Json
        $sampleCount = $history.Count
    }
    
    Write-Host ""
    Write-Host " ╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host " ║  MACHINE LEARNING USAGE PATTERNS v6.0                ║" -ForegroundColor Cyan
    Write-Host " ╚═══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " Muestras recolectadas: $sampleCount" -ForegroundColor Gray
    Write-Host " Estado: $(if($sampleCount -ge 20){'Listo para análisis'}else{'Recolectando datos...'})" -ForegroundColor $(if ($sampleCount -ge 20) { 'Green' }else { 'Yellow' })
    Write-Host ""
    Write-Host " ╔═══════════════════════════════════════════════════════╗" -ForegroundColor Gray
    Write-Host " ║ 1. Capturar snapshot ahora                            ║" -ForegroundColor White
    Write-Host " ║ 2. Iniciar recolector en background                  ║" -ForegroundColor White
    Write-Host " ║ 3. Analizar patrones aprendidos                      ║" -ForegroundColor White
    Write-Host " ║ 4. Ver sugerencias inteligentes                      ║" -ForegroundColor White
    Write-Host " ║ 5. Ver predicción actual                              ║" -ForegroundColor White
    Write-Host " ║ 6. Detectar anomalías                                 ║" -ForegroundColor White
    Write-Host " ║ 7. Borrar datos (reset)                               ║" -ForegroundColor Red
    Write-Host " ║ 8. Salir                                               ║" -ForegroundColor DarkGray
    Write-Host " ╚═══════════════════════════════════════════════════════╝" -ForegroundColor Gray
    Write-Host ""
}

Initialize-MLData

while ($true) {
    Show-MLMenu
    
    $choice = Read-Host " >> Opción"
    
    switch ($choice) {
        '1' {
            Write-Host ""
            Write-Host " [+] Capturando snapshot..." -ForegroundColor Cyan
            
            $snapshot = Get-CurrentUsageSnapshot
            $success = Add-UsageSnapshot -Snapshot $snapshot
            
            if ($success) {
                Write-Host " [OK] Snapshot guardado" -ForegroundColor Green
                Write-Host ""
                Write-Host " Gaming processes: $($snapshot.Processes.Gaming.Count)" -ForegroundColor Gray
                Write-Host " Productivity processes: $($snapshot.Processes.Productivity.Count)" -ForegroundColor Gray
                Write-Host " Creative processes: $($snapshot.Processes.Creative.Count)" -ForegroundColor Gray
            }
            else {
                Write-Host " [!] Error guardando snapshot" -ForegroundColor Red
            }
            
            Wait-ForKeyPress
        }
        '2' {
            try {
                Start-BackgroundCollector -IntervalMinutes 15
            }
            catch {
                Write-Host ""
                Write-Host " [i] Recolector detenido" -ForegroundColor Yellow
            }
            Wait-ForKeyPress
        }
        '3' {
            Write-Host ""
            Write-Host " [+] Analizando patrones..." -ForegroundColor Cyan
            
            $patterns = Get-UsagePatterns
            
            if ($patterns) {
                Show-LearnedPatterns -Patterns $patterns
            }
            else {
                Write-Host " [!] Datos insuficientes para análisis" -ForegroundColor Yellow
            }
            
            Wait-ForKeyPress
        }
        '4' {
            Write-Host ""
            Write-Host " [+] Generando sugerencias..." -ForegroundColor Cyan
            Write-Host ""
            
            $suggestions = Get-SmartSuggestions
            
            if ($suggestions.Count -eq 0) {
                Write-Host " [i] No hay sugerencias en este momento" -ForegroundColor Gray
            }
            else {
                Write-Host " SUGERENCIAS INTELIGENTES:" -ForegroundColor Yellow
                Write-Host ""
                
                $i = 1
                foreach ($sug in $suggestions) {
                    Write-Host " [$i] $($sug.Title)" -ForegroundColor Cyan
                    Write-Host "     $($sug.Description)" -ForegroundColor Gray
                    Write-Host "     Acción: $($sug.Action)" -ForegroundColor White
                    Write-Host "     Confianza: $($sug.Confidence)%" -ForegroundColor DarkGray
                    Write-Host ""
                    $i++
                }
            }
            
            Wait-ForKeyPress
        }
        '5' {
            Write-Host ""
            $prediction = Get-ProfilePrediction
            
            if ($prediction) {
                Write-Host " PREDICCIÓN ACTUAL:" -ForegroundColor Yellow
                Write-Host ""
                Write-Host " Perfil recomendado: " -NoNewline
                Write-Host $prediction.RecommendedProfile -ForegroundColor Cyan
                Write-Host " Confianza: $($prediction.Confidence)%" -ForegroundColor Gray
                Write-Host " Razón: $($prediction.Reason)" -ForegroundColor Gray
            }
            else {
                Write-Host " [!] No hay suficientes datos para predicción" -ForegroundColor Yellow
            }
            
            Write-Host ""
            Wait-ForKeyPress
        }
        '6' {
            Write-Host ""
            Write-Host " [+] Detectando anomalías..." -ForegroundColor Cyan
            Write-Host ""
            
            $anomalies = Test-Anomalies
            
            if ($anomalies.Count -eq 0) {
                Write-Host " [OK] No se detectaron anomalías" -ForegroundColor Green
            }
            else {
                Write-Host " ⚠️ ANOMALÍAS DETECTADAS:" -ForegroundColor Red
                Write-Host ""
                
                foreach ($anomaly in $anomalies) {
                    $severityColor = switch ($anomaly.Severity) {
                        "High" { "Red" }
                        "Medium" { "Yellow" }
                        "Low" { "Cyan" }
                        default { "Gray" }
                    }
                    
                    Write-Host " [$($anomaly.Type)] " -NoNewline -ForegroundColor $severityColor
                    Write-Host $anomaly.Description -ForegroundColor Gray
                    Write-Host "   → $($anomaly.Suggestion)" -ForegroundColor Cyan
                    Write-Host ""
                }
            }
            
            Wait-ForKeyPress
        }
        '7' {
            Write-Host ""
            Write-Host " [!] ADVERTENCIA: Esto borrará todos los datos aprendidos" -ForegroundColor Red
            $confirm = Read-Host " >> ¿Continuar? (SI/NO)"
            
            if ($confirm -eq "SI") {
                try {
                    if (Test-Path $Script:HistoryFile) { Remove-Item $Script:HistoryFile -Force }
                    if (Test-Path $Script:PatternsFile) { Remove-Item $Script:PatternsFile -Force }
                    if (Test-Path $Script:AnomaliesFile) { Remove-Item $Script:AnomaliesFile -Force }
                    
                    Write-Host " [OK] Datos borrados" -ForegroundColor Green
                }
                catch {
                    Write-Host " [!] Error: $_" -ForegroundColor Red
                }
            }
            
            Wait-ForKeyPress
        }
        '8' {
            exit 0
        }
        default {
            Write-Host " [!] Opción inválida" -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}

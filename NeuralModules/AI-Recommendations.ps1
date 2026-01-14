<#
.SYNOPSIS
    AI-Powered Recommendation Engine v6.0
    Analiza el sistema y recomienda optimizaciones personalizadas.

.DESCRIPTION
    Características:
    - Hardware profiling avanzado
    - Usage pattern detection
    - Workload classification (gaming, productivity, mixed)
    - Personalized optimization recommendations
    - Risk assessment
    - Expected impact prediction
    - Smart profile suggestion

.NOTES
    Parte de Windows Neural Optimizer v6.0
    Creditos: Jose Bustamante
#>

if (-not (Get-Command "Write-Log" -ErrorAction SilentlyContinue)) {
    $currentDir = Split-Path $MyInvocation.MyCommand.Path
    $utilsPath = Join-Path $currentDir "NeuralUtils.psm1"
    if (Test-Path $utilsPath) { Import-Module $utilsPath -Force -DisableNameChecking }
}

Invoke-AdminCheck -Silent

# ============================================================================
# SYSTEM PROFILING
# ============================================================================

function Get-SystemProfile {
    [CmdletBinding()]
    param()
    
    Write-Host " [+] $(Msg 'AI.Analying')" -ForegroundColor Cyan
    Write-Host ""
    
    $SysProfile = @{
        Hardware    = $null
        Performance = $null
        Usage       = $null
        Health      = $null
        Workload    = "unknown"
        Score       = 0
    }
    
    # Hardware
    Write-Progress -Activity "System Profiling" -Status (Msg "AI.Progress.Hw") -PercentComplete 10
    $SysProfile.Hardware = Get-HardwareProfile
    
    # Performance metrics
    Write-Progress -Activity "System Profiling" -Status (Msg "AI.Progress.Perf") -PercentComplete 30
    $SysProfile.Performance = Get-PerformanceMetrics
    
    # Usage patterns
    Write-Progress -Activity "System Profiling" -Status (Msg "AI.Progress.Usage") -PercentComplete 50
    $SysProfile.Usage = Get-UsagePatterns
    
    # Health check
    Write-Progress -Activity "System Profiling" -Status (Msg "AI.Progress.Health") -PercentComplete 70
    $SysProfile.Health = Get-QuickHealthCheck
    
    # Classify workload
    Write-Progress -Activity "System Profiling" -Status (Msg "AI.Analying") -PercentComplete 90
    $SysProfile.Workload = Get-WorkloadClassification -Profile $SysProfile
    $SysProfile.Score = Get-SystemScore -Profile $SysProfile
    
    Write-Progress -Activity "System Profiling" -Completed
    
    return $SysProfile
}

function Get-PerformanceMetrics {
    try {
        $cpu = Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average
        $os = Get-CimInstance Win32_OperatingSystem
        $disk = Get-PSDrive C
        
        $metrics = @{
            CpuUsage          = [math]::Round($cpu.Average, 1)
            RamUsagePercent   = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 1)
            DiskUsagePercent  = [math]::Round(($disk.Used / ($disk.Used + $disk.Free)) * 100, 1)
            DriverFreeSpaceGB = [math]::Round($disk.Free / 1GB, 1)
            ProcessCount      = (Get-Process).Count
            ServiceCount      = (Get-Service | Where-Object { $_.Status -eq "Running" }).Count
        }
        
        return $metrics
    }
    catch {
        return @{}
    }
}

function Get-UsagePatterns {
    try {
        $patterns = @{
            GamingProcesses       = 0
            ProductivityProcesses = 0
            CreativeProcesses     = 0
            HasAntiCheat          = $false
            HasVirtualization     = $false
            UptimeHours           = 0
        }
        
        # Analyze running processes
        $processes = Get-Process
        
        # Gaming indicators
        $gamingPatterns = @("*game*", "*steam*", "*epic*", "*origin*", "*uplay*", "*battle.net*", "*riot*")
        foreach ($pattern in $gamingPatterns) {
            $patterns.GamingProcesses += ($processes | Where-Object { $_.Name -like $pattern }).Count
        }
        
        # Productivity indicators
        $productivityPatterns = @("*office*", "*excel*", "*word*", "*powerpoint*", "*outlook*", "*teams*", "*slack*", "*chrome*", "*firefox*")
        foreach ($pattern in $productivityPatterns) {
            $patterns.ProductivityProcesses += ($processes | Where-Object { $_.Name -like $pattern }).Count
        }
        
        # Creative indicators
        $creativePatterns = @("*photoshop*", "*premiere*", "*davinci*", "*obs*", "*streamlabs*", "*blender*", "*unity*", "*unreal*")
        foreach ($pattern in $creativePatterns) {
            $patterns.CreativeProcesses += ($processes | Where-Object { $_.Name -like $pattern }).Count
        }
        
        # Anti-cheat detection
        $antiCheatPatterns = @("*vanguard*", "*eac*", "*battleye*", "*vac*")
        foreach ($pattern in $antiCheatPatterns) {
            if ($processes | Where-Object { $_.Name -like $pattern }) {
                $patterns.HasAntiCheat = $true
                break
            }
        }
        
        # Virtualization
        $vmPatterns = @("*vmware*", "*virtualbox*", "*hyper-v*")
        foreach ($pattern in $vmPatterns) {
            if ($processes | Where-Object { $_.Name -like $pattern }) {
                $patterns.HasVirtualization = $true
                break
            }
        }
        
        # Uptime
        $os = Get-CimInstance Win32_OperatingSystem
        $uptime = (Get-Date) - $os.LastBootUpTime
        $patterns.UptimeHours = [math]::Round($uptime.TotalHours, 1)
        
        return $patterns
    }
    catch {
        return @{}
    }
}

function Get-QuickHealthCheck {
    $health = @{
        DiskHealth     = "Unknown"
        MemoryHealth   = "Unknown"
        TempStatus     = "Unknown"
        DefenderStatus = "Unknown"
        UpdateStatus   = "Unknown"
    }
    
    try {
        # Disk health
        $disk = Get-PhysicalDisk | Where-Object { $_.DeviceId -eq 0 } | Select-Object -First 1
        if ($disk) {
            $health.DiskHealth = $disk.HealthStatus
        }
        
        # Memory health (check for errors)
        $memErrors = Get-WinEvent -FilterHashtable @{
            LogName      = 'System'
            ProviderName = 'Microsoft-Windows-MemoryDiagnostics-Results'
            StartTime    = (Get-Date).AddDays(-7)
        } -MaxEvents 1 -ErrorAction SilentlyContinue
        
        $health.MemoryHealth = if ($memErrors) { "Issues Detected" } else { "Healthy" }
        
        # Temperature (if available)
        $temp = Get-CpuTemperature
        if ($temp) {
            $health.TempStatus = if ($temp -lt 60) { "Normal" } elseif ($temp -lt 80) { "Warm" } else { "Hot" }
        }
        
        # Windows Defender
        $defender = Get-MpComputerStatus -ErrorAction SilentlyContinue
        if ($defender) {
            $health.DefenderStatus = if ($defender.RealTimeProtectionEnabled) { "Active" } else { "Disabled" }
        }
        
        # Windows Update
        try {
            $updateSession = New-Object -ComObject Microsoft.Update.Session
            $updateSearcher = $updateSession.CreateUpdateSearcher()
            $searchResult = $updateSearcher.Search("IsInstalled=0 and Type='Software'")
            $health.UpdateStatus = if ($searchResult.Updates.Count -eq 0) { "Up to date" } else { "$($searchResult.Updates.Count) pending" }
        }
        catch {
            $health.UpdateStatus = "Unknown"
        }
    }
    catch {}
    
    return $health
}

function Get-StartupHealth {
    $startup = @{
        ItemCount  = 0
        HighImpact = $false
        Items      = @()
    }
    
    try {
        $userRun = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -ErrorAction SilentlyContinue
        $sysRun = Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" -ErrorAction SilentlyContinue
        
        # Simple count of registry values (excluding PS default properties)
        if ($userRun) {
            $userRun.PSObject.Properties | Where-Object { $_.Name -notin @("PSPath", "PSParentPath", "PSChildName", "PSDrive", "PSProvider") } | ForEach-Object {
                $startup.Items += $_.Name
                $startup.ItemCount++
            }
        }
        
        if ($sysRun) {
            $sysRun.PSObject.Properties | Where-Object { $_.Name -notin @("PSPath", "PSParentPath", "PSChildName", "PSDrive", "PSProvider") } | ForEach-Object {
                $startup.Items += $_.Name
                $startup.ItemCount++
            }
        }
        
        if ($startup.ItemCount -gt 5) { $startup.HighImpact = $true }
    }
    catch {}
    
    return $startup
}

function Get-MemoryPressure {
    $pressure = @{
        Status        = "Normal"
        CommitPercent = 0
        IsThrashing   = $false
    }
    
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $perf = Get-Counter "\Memory\Pages/sec" -SampleInterval 1 -MaxSamples 3 -ErrorAction SilentlyContinue
        
        # Calculate Commit Charge %
        # TotalVisibleMemorySize is physical. 
        # SizeStoredInPagingFiles is page file size.
        # TotalVirtualMemorySize is sum of both approximately.
        
        $totalVirtual = $os.TotalVirtualMemorySize # KB
        $freeVirtual = $os.FreeVirtualMemory     # KB
        $usedVirtual = $totalVirtual - $freeVirtual
        
        if ($totalVirtual -gt 0) {
            $pressure.CommitPercent = [math]::Round(($usedVirtual / $totalVirtual) * 100, 1)
        }
        
        # Detect Thrashing (High Paging Activity + High Physical RAM Usage)
        $pagingAvg = 0
        if ($perf) {
            $pagingAvg = ($perf.CounterSamples.CookedValue | Measure-Object -Average).Average
        }
        
        $physFreePercent = ($os.FreePhysicalMemory / $os.TotalVisibleMemorySize) * 100
        
        if ($physFreePercent -lt 10 -and $pagingAvg -gt 50) {
            $pressure.IsThrashing = $true
            $pressure.Status = "Thrashing"
        }
        elseif ($pressure.CommitPercent -gt 85) {
            $pressure.Status = "High"
        }
    }
    catch {
        $pressure.Status = "Error"
    }
    
    return $pressure
}

function Get-WorkloadClassification {
    param($SystemProfile)
    
    $usage = $SystemProfile.Usage
    $hw = $SystemProfile.Hardware
    
    # Calculate scores
    $gamingScore = 0
    $productivityScore = 0
    $creativeScore = 0
    
    # Process-based classification
    if ($usage.GamingProcesses -gt 2) { $gamingScore += 30 }
    if ($usage.ProductivityProcesses -gt 3) { $productivityScore += 30 }
    if ($usage.CreativeProcesses -gt 1) { $creativeScore += 30 }
    
    # Hardware-based hints
    if ($hw.HasDedicatedGPU -and $hw.GpuVendor -match "NVIDIA|AMD") { $gamingScore += 20; $creativeScore += 10 }
    if ($hw.RamGB -ge 32) { $creativeScore += 20; $productivityScore += 10 }
    if ($hw.CpuCores -ge 8) { $creativeScore += 15; $gamingScore += 5 }
    
    # Anti-cheat presence
    if ($usage.HasAntiCheat) { $gamingScore += 25 }
    
    # Virtualization
    if ($usage.HasVirtualization) { $productivityScore += 20 }
    
    # Determine primary workload
    $scores = @{
        Gaming       = $gamingScore
        Productivity = $productivityScore
        Creative     = $creativeScore
    }
    
    $maxScore = ($scores.Values | Measure-Object -Maximum).Maximum
    $workload = ($scores.GetEnumerator() | Where-Object { $_.Value -eq $maxScore } | Select-Object -First 1).Name
    
    # If scores are close, it's mixed
    $sortedScores = $scores.Values | Sort-Object -Descending
    if ($sortedScores[0] -gt 0 -and $sortedScores[1] -gt 0 -and ($sortedScores[0] - $sortedScores[1]) -lt 20) {
        $workload = "Mixed"
    }
    
    # If all scores are low, it's general
    if ($maxScore -lt 30) {
        $workload = "General"
    }
    
    return $workload
}

function Get-SystemScore {
    param($SystemProfile)
    
    $score = 100
    
    
    # Registry Status (Phase 3)
    $recommendations += Get-RegistryOptimizationStatus
    # Performance penalties
    if ($SystemProfile.Performance.CpuUsage -gt 80) { $score -= 10 }
    if ($SystemProfile.Performance.RamUsagePercent -gt 85) { $score -= 15 }
    if ($SystemProfile.Performance.DiskUsagePercent -gt 90) { $score -= 10 }
    if ($SystemProfile.Performance.ProcessCount -gt 200) { $score -= 5 }
    
    # Health penalties
    if ($SystemProfile.Health.DiskHealth -ne "Healthy") { $score -= 20 }
    if ($SystemProfile.Health.MemoryHealth -ne "Healthy") { $score -= 15 }
    if ($SystemProfile.Health.TempStatus -eq "Hot") { $score -= 15 }
    if ($SystemProfile.Health.DefenderStatus -eq "Disabled") { $score -= 10 }
    
    # Hardware bonuses
    if ($SystemProfile.Hardware.IsNVMe) { $score += 5 }
    if ($SystemProfile.Hardware.RamGB -ge 16) { $score += 5 }
    if ($SystemProfile.Hardware.CpuCores -ge 8) { $score += 5 }
    
    return [math]::Max(0, [math]::Min(100, $score))
}

# ============================================================================
# RECOMMENDATION ENGINE
# ============================================================================

function Get-SmartRecommendations {
    param($SystemProfile)
    
    $recommendations = @()
    
    # Profile-based recommendations
    $SysProfileRecommendation = Get-ProfileRecommendation -Profile $SystemProfile
    if ($SysProfileRecommendation) {
        $recommendations += $SysProfileRecommendation
    }
    
    # Hardware-specific
    $recommendations += Get-HardwareRecommendations -Hardware $SystemProfile.Hardware
    
    # Performance-based
    $recommendations += Get-PerformanceRecommendations -Performance $SystemProfile.Performance -Hardware $SystemProfile.Hardware
    
    # Health-based
    $recommendations += Get-HealthRecommendations -Health $SystemProfile.Health

    # Optimization Status (Phase 2 Awareness)
    $recommendations += Get-OptimizationStatusRecommendations
    
    # Registry Status (Phase 3)
    $recommendations += Get-RegistryOptimizationStatus
    
    # Sort by priority
    $recommendations = $recommendations | Sort-Object -Property Priority -Descending
    
    # Startup Check
    $startup = Get-StartupHealth
    if ($startup.HighImpact) {
        $recommendations += @{
            Title       = "Alto Impacto de Inicio"
            Description = "Se detectaron $($startup.ItemCount) programas al inicio. Esto ralentiza el boot."
            Action      = "Ejecutar: Service-Manager.ps1 (Safe Preset)"
            Priority    = 80
            Risk        = "Low"
            Impact      = "Medium"
            Category    = "Startup"
        }
    }

    # Disk Space Check
    if ($SystemProfile.Performance.DriverFreeSpaceGB -lt 20) {
        $recommendations += @{
            Title       = "Espacio en Disco Crítico"
            Description = "Menos de 20GB libres en C:. El rendimiento SSD degradará."
            Action      = "Ejecutar: Disk-Hygiene.ps1 / Liberar espacio"
            Priority    = 95
            Risk        = "Low"
            Impact      = "Critical"
            Category    = "Storage"
            Module      = "Disk-Hygiene.ps1"
        }
    }

    
    # Memory Pressure Smart Check (Real-time Paging Analysis)
    $memPressure = Get-MemoryPressure
    if ($memPressure.IsThrashing) {
        $recommendations += @{
            Title       = "⚠️ MEMORIA EXTREMA (Thrashing)"
            Description = "El sistema está usando intensivamente el archivo de paginación. Rendimiento severamente degradado."
            Action      = "Cerrar apps pesadas urgentemente / Considerar más RAM"
            Priority    = 98
            Risk        = "Medium"
            Impact      = "Critical"
            Category    = "Memory"
            Module      = $null
        }
    }
    elseif ($memPressure.Status -eq "High") {
        $recommendations += @{
            Title       = "Carga Virtual Alta"
            Description = "Commit Charge al $($memPressure.CommitPercent)%. Estás cerca del límite de memoria virtual."
            Action      = "Ejecutar: Advanced-Memory.ps1 → Aumentar PageFile"
            Priority    = 75
            Risk        = "Low"
            Impact      = "Medium"
            Category    = "Memory"
            Module      = "Advanced-Memory.ps1"
        }
    }

    # Gaming Synergy
    if ($SystemProfile.Workload -eq "Gaming") {
        # Check if Game Mode is actually enabled in registry
        $gm = Get-ItemProperty "HKCU:\Software\Microsoft\GameBar" -Name "AllowAutoGameMode" -ErrorAction SilentlyContinue
        if (-not $gm -or $gm.AllowAutoGameMode -ne 1) {
            $recommendations += @{
                Title       = "Modo Juego Desactivado"
                Description = "Tu perfil es Gaming pero el Modo Juego de Windows está OFF."
                Action      = "Habilitar 'Game Mode' en Configuración de Windows"
                Priority    = 65
                Risk        = "Low"
                Impact      = "Medium"
                Category    = "Gaming"
                Module      = "Gaming-Optimization.ps1"
            }
        }
    }
    
    return $recommendations
}

function Get-ProfileRecommendation {
    param($SystemProfile)
    
    $workload = $SystemProfile.Workload
    
    $recommendation = @{
        Title       = "Perfil Recomendado"
        Description = ""
        Action      = ""
        Priority    = 100
        Risk        = "Low"
        Impact      = "High"
        Category    = "Profile"
        Module      = "Profile-System.ps1"
    }
    
    switch ($workload) {
        "Gaming" {
            $recommendation.Description = "Tu sistema muestra uso intensivo de gaming. El perfil 'Gaming Competitive' optimizará FPS, latencia y frame timing."
            $recommendation.Action = "Profile-System.ps1 → Gaming Competitive"
        }
        "Productivity" {
            $recommendation.Description = "Detectado uso de productividad. El perfil 'Workstation' optimiza multitarea y aplicaciones de oficina."
            $recommendation.Action = "Profile-System.ps1 → Workstation"
        }
        "Creative" {
            $recommendation.Description = "Aplicaciones creativas detectadas. El perfil 'Content Creation' optimiza rendering y encoding."
            $recommendation.Action = "Profile-System.ps1 → Content Creation"
        }
        "Mixed" {
            $recommendation.Description = "Uso mixto detectado. El perfil 'Gaming Balanced' ofrece un buen equilibrio."
            $recommendation.Action = "Profile-System.ps1 → Gaming Balanced"
        }
        default {
            return $null
        }
    }
    
    return $recommendation
}

function Get-HardwareRecommendations {
    param($Hardware)
    
    $recommendations = @()
    
    # SSD/NVMe optimization
    if ($Hardware.IsSSD -or $Hardware.IsNVMe) {
        $recommendations += @{
            Title       = "Optimización de SSD/NVMe"
            Description = "Tu $( if ($Hardware.IsNVMe) { 'NVMe' } else { 'SSD' }) puede optimizarse para mejor rendimiento y longevidad."
            Action      = "Ejecutar: SSD-NVMe-Optimizer.ps1"
            Priority    = 85
            Risk        = "Low"
            Impact      = "Medium"
            Category    = "Storage"
            Module      = "SSD-NVMe-Optimizer.ps1"
        }
    }
    
    # Memory optimization
    if ($Hardware.RamGB -ge 16) {
        $recommendations += @{
            Title       = "Optimización de Memoria Avanzada"
            Description = "Con $($Hardware.RamGB)GB RAM, puedes deshabilitar memory compression para liberar ~5% CPU."
            Action      = "Ejecutar: Advanced-Memory.ps1 → Configuración completa"
            Priority    = 75
            Risk        = "Low"
            Impact      = "Medium"
            Category    = "Memory"
            Module      = "Advanced-Memory.ps1"
        }
    }
    elseif ($Hardware.RamGB -lt 8) {
        $recommendations += @{
            Title       = "RAM Limitada Detectada"
            Description = "Con $($Hardware.RamGB)GB RAM, optimiza paging file y habilita compression."
            Action      = "Ejecutar: Advanced-Memory.ps1 → Smart Paging File"
            Priority    = 90
            Risk        = "Low"
            Impact      = "High"
            Category    = "Memory"
            Module      = "Advanced-Memory.ps1"
        }
    }
    
    # GPU-specific
    if ($Hardware.HasDedicatedGPU) {
        $recommendations += @{
            Title       = "Optimización Ultra Gaming"
            Description = "GPU dedicada detectada ($($Hardware.GpuVendor)). Optimizaciones específicas disponibles."
            Action      = "Ejecutar: Advanced-Gaming.ps1"
            Priority    = 80
            Risk        = "Medium"
            Impact      = "High"
            Category    = "GPU"
            Module      = "Advanced-Gaming.ps1"
        }
    }
    
    return $recommendations
}

function Get-OptimizationStatusRecommendations {
    $recommendations = @()

    # Network Check
    $tcp = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TcpAckFrequency" -ErrorAction SilentlyContinue
    if (-not $tcp) {
        $recommendations += @{
            Title       = "Red No Optimizada"
            Description = "Stack TCP/IP sin optimizar. Ejecuta Network-Optimizer para reducir latencia."
            Action      = "Ejecutar: Network-Optimizer.ps1"
            Priority    = 90
            Risk        = "Low"
            Impact      = "High"
            Category    = "Network"
            Module      = "Network-Optimizer.ps1"
        }
    }

    # Privacy Check
    $telemetry = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -ErrorAction SilentlyContinue
    if (-not $telemetry -or $telemetry.AllowTelemetry -ne 0) {
        $recommendations += @{
            Title       = "Telemetría Activa"
            Description = "Windows está enviando datos. Protege tu privacidad."
            Action      = "Ejecutar: Privacy-Guardian.ps1"
            Priority    = 60
            Risk        = "Low"
            Impact      = "Privacy"
            Category    = "Privacy"
            Module      = "Privacy-Guardian.ps1"
        }
    }
    
    return $recommendations
}

function Get-PerformanceRecommendations {
    param($Performance, $Hardware)
    
    $recommendations = @()
    
    # High CPU usage
    if ($Performance.CpuUsage -gt 80) {
        $recommendations += @{
            Title       = "CPU Usage Alto"
            Description = "CPU al $($Performance.CpuUsage)%. Considera cerrar aplicaciones no esenciales o analizar procesos."
            Action      = "System-Monitor.ps1 → Identificar procesos"
            Priority    = 70
            Risk        = "Low"
            Impact      = "Medium"
            Category    = "Performance"
            Module      = "System-Monitor.ps1"
        }
    }
    
    # High RAM usage
    if ($Performance.RamUsagePercent -gt 85) {
        $recommendations += @{
            Title       = "Memoria RAM Alta"
            Description = "RAM al $($Performance.RamUsagePercent)%. Liberar memoria o detectar memory leaks."
            Action      = "Advanced-Memory.ps1 → Working Set Trim o Memory Leak Detection"
            Priority    = 85
            Risk        = "Low"
            Impact      = "High"
            Category    = "Memory"
            Module      = "Advanced-Memory.ps1"
        }
    }
    
    # High disk usage
    if ($Performance.DiskUsagePercent -gt 90) {
        $recommendations += @{
            Title       = "Disco Casi Lleno"
            Description = "Disco C: al $($Performance.DiskUsagePercent)%. Limpieza profunda recomendada."
            Action      = "Ejecutar: Disk-Hygiene.ps1"
            Priority    = 95
            Risk        = "Low"
            Impact      = "High"
            Category    = "Storage"
            Module      = "Disk-Hygiene.ps1"
        }
    }
    
    # Too many processes
    if ($Performance.ProcessCount -gt 200) {
        $recommendations += @{
            Title       = "Muchos Procesos"
            Description = "$($Performance.ProcessCount) procesos activos. Considera debloat y startup optimization."
            Action      = "Ejecutar: Debloat-Suite.ps1"
            Priority    = 60
            Risk        = "Low"
            Impact      = "Medium"
            Category    = "Performance"
            Module      = "Debloat-Suite.ps1"
        }
    }
    
    return $recommendations
}

function Get-HealthRecommendations {
    param($Health)
    
    $recommendations = @()
    
    # Disk health issues
    if ($Health.DiskHealth -ne "Healthy" -and $Health.DiskHealth -ne "Unknown") {
        $recommendations += @{
            Title       = "⚠️ PROBLEMA DE DISCO"
            Description = "Disco reporta: $($Health.DiskHealth). URGENTE: Haz backup inmediatamente."
            Action      = "Verificar SMART en: SSD-NVMe-Optimizer.ps1 → SMART Health Check"
            Priority    = 100
            Risk        = "Critical"
            Impact      = "Critical"
            Category    = "Health"
            Module      = "SSD-NVMe-Optimizer.ps1"
        }
    }
    
    # Memory issues
    if ($Health.MemoryHealth -ne "Healthy") {
        $recommendations += @{
            Title       = "Problemas de Memoria"
            Description = "Errores de memoria detectados en últimos 7 días. Ejecuta Memory Diagnostic."
            Action      = "Windows Memory Diagnostic (mdsched.exe)"
            Priority    = 90
            Risk        = "High"
            Impact      = "High"
            Category    = "Health"
            Module      = $null
        }
    }
    
    # Temperature issues
    if ($Health.TempStatus -eq "Hot") {
        $recommendations += @{
            Title       = "Temperaturas Altas"
            Description = "CPU temperatura elevada. Verifica refrigeración y aplica thermal optimization."
            Action      = "Ejecutar: Thermal-Optimization.ps1"
            Priority    = 85
            Risk        = "Medium"
            Impact      = "High"
            Category    = "Thermal"
            Module      = "Thermal-Optimization.ps1"
        }
    }
    
    # Defender disabled
    if ($Health.DefenderStatus -eq "Disabled") {
        $recommendations += @{
            Title       = "Windows Defender Deshabilitado"
            Description = "Real-Time Protection está OFF. Habilítalo para protección."
            Action      = "Windows Security → Virus & threat protection → Enable"
            Priority    = 75
            Risk        = "High"
            Impact      = "Security"
            Category    = "Security"
            Module      = $null
        }
    }
    
    # Pending updates
    if ($Health.UpdateStatus -match "pending") {
        $recommendations += @{
            Title       = "Actualizaciones Pendientes"
            Description = "$($Health.UpdateStatus). Instálalas para seguridad y estabilidad."
            Action      = "Windows Update → Install updates"
            Priority    = 50
            Risk        = "Low"
            Impact      = "Security"
            Category    = "Updates"
            Module      = $null
        }
    }
    
    return $recommendations
}

# ============================================================================
# DISPLAY & INTERACTIVE
# ============================================================================

function Invoke-AIAutoApply {
    param($Recommendations)
    
    $modulesToRun = @()
    foreach ($rec in $Recommendations) {
        if ($rec.Module -and $rec.Priority -ge 70) {
            if ($modulesToRun -notcontains $rec.Module) {
                $modulesToRun += $rec.Module
            }
        }
    }
    
    if ($modulesToRun.Count -gt 0) {
        Write-Host ""
        Write-Host " ╔═══════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host " ║ 🤖 AUTO-APPLY RECOMMENDATIONS                         ║" -ForegroundColor Green
        Write-Host " ╠═══════════════════════════════════════════════════════╣" -ForegroundColor Green
        Write-Host " ║ The AI suggests running the following modules:        ║" -ForegroundColor Green
        foreach ($mod in $modulesToRun) {
            Write-Host " ║  • $mod" -ForegroundColor White
        }
        Write-Host " ╚═══════════════════════════════════════════════════════╝" -ForegroundColor Green
        Write-Host ""
        
        $choice = Read-Host " >> Do you want to apply these optimizations now? (Y/N)"
        if ($choice -eq "Y" -or $choice -eq "S") {
            foreach ($mod in $modulesToRun) {
                $scriptPath = Join-Path $PSScriptRoot $mod
                if (Test-Path $scriptPath) {
                    Write-Host " >> Running $mod..." -ForegroundColor Cyan
                    & $scriptPath
                }
                else {
                    $scriptPath2 = Join-Path $PSScriptRoot "..\$mod" # Try parent if in subdir
                    if (Test-Path $scriptPath2) {
                        Write-Host " >> Running $mod..." -ForegroundColor Cyan
                        & $scriptPath2
                    }
                }
            }
            Write-Host " [OK] All recommended optimizations applied." -ForegroundColor Green
            Read-Host " Press Enter to continue..."
        }
    }
}

function Show-SystemAnalysis {
    param($SystemProfile)
    
    Clear-Host
    
    Write-Host ""
    Write-Host " ╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host " ║  AI-POWERED SYSTEM ANALYSIS                           ║" -ForegroundColor Cyan
    Write-Host " ╚═══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    # System Score
    $scoreColor = if ($SystemProfile.Score -ge 80) { "Green" } elseif ($SystemProfile.Score -ge 60) { "Yellow" } else { "Red" }
    Write-Host " System Health Score: " -NoNewline
    Write-Host "$($SystemProfile.Score)/100" -ForegroundColor $scoreColor
    Write-Host ""
    
    # Workload
    Write-Host " Workload Classification: " -NoNewline
    Write-Host $SystemProfile.Workload -ForegroundColor Cyan
    Write-Host ""
    
    # Hardware Summary
    Write-Host " ┌─ HARDWARE ──────────────────────────────────────────┐" -ForegroundColor Gray
    Write-Host " │ CPU: $($SystemProfile.Hardware.CpuVendor) ($($SystemProfile.Hardware.CpuCores)C/$($SystemProfile.Hardware.CpuThreads)T)" -ForegroundColor Gray
    Write-Host " │ RAM: $($SystemProfile.Hardware.RamGB) GB" -ForegroundColor Gray
    Write-Host " │ GPU: $($SystemProfile.Hardware.GpuVendor)" -ForegroundColor Gray
    Write-Host " │ Storage: $(if($SystemProfile.Hardware.IsNVMe){"NVMe"}elseif($SystemProfile.Hardware.IsSSD){"SSD"}else{"HDD"})" -ForegroundColor Gray
    Write-Host " └─────────────────────────────────────────────────────┘" -ForegroundColor Gray
    Write-Host ""
    
    # Performance
    Write-Host " ┌─ PERFORMANCE ───────────────────────────────────────┐" -ForegroundColor Gray
    Write-Host " │ CPU Usage:      $($SystemProfile.Performance.CpuUsage)%" -ForegroundColor Gray
    Write-Host " │ RAM Usage:      $($SystemProfile.Performance.RamUsagePercent)%" -ForegroundColor Gray
    Write-Host " │ Disk Usage:     $($SystemProfile.Performance.DiskUsagePercent)%" -ForegroundColor Gray
    Write-Host " │ Processes:      $($SystemProfile.Performance.ProcessCount)" -ForegroundColor Gray
    Write-Host " └─────────────────────────────────────────────────────┘" -ForegroundColor Gray
    Write-Host ""
    
    # Health
    Write-Host " ┌─ HEALTH STATUS ─────────────────────────────────────┐" -ForegroundColor Gray
    Write-Host " │ Disk:           $($SystemProfile.Health.DiskHealth)" -ForegroundColor Gray
    Write-Host " │ Memory:         $($SystemProfile.Health.MemoryHealth)" -ForegroundColor Gray
    Write-Host " │ Temperature:    $($SystemProfile.Health.TempStatus)" -ForegroundColor Gray
    Write-Host " │ Defender:       $($SystemProfile.Health.DefenderStatus)" -ForegroundColor Gray
    Write-Host " │ Updates:        $($SystemProfile.Health.UpdateStatus)" -ForegroundColor Gray
    Write-Host " └─────────────────────────────────────────────────────┘" -ForegroundColor Gray
    Write-Host ""
}

function Show-Recommendations {
    param($Recommendations)
    
    Write-Host " ╔═══════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host " ║  AI RECOMMENDATIONS                                   ║" -ForegroundColor Yellow
    Write-Host " ╚═══════════════════════════════════════════════════════╝" -ForegroundColor Yellow
    Write-Host ""
    
    if ($Recommendations.Count -eq 0) {
        Write-Host " ✓ No hay recomendaciones. Tu sistema está optimizado!" -ForegroundColor Green
        Write-Host ""
        return
    }
    
    $i = 1
    foreach ($rec in $Recommendations) {
        $priorityColor = switch ($rec.Priority) {
            { $_ -ge 90 } { "Red" }
            { $_ -ge 70 } { "Yellow" }
            default { "Cyan" }
        }
        
        $riskColor = switch ($rec.Risk) {
            "Critical" { "Magenta" }
            "High" { "Red" }
            "Medium" { "Yellow" }
            default { "Green" }
        }
        
        Write-Host " [$i] " -NoNewline -ForegroundColor White
        Write-Host $rec.Title -ForegroundColor $priorityColor
        Write-Host "     $($rec.Description)" -ForegroundColor Gray
        Write-Host "     " -NoNewline
        Write-Host "Acción: " -NoNewline -ForegroundColor DarkGray
        Write-Host $rec.Action -ForegroundColor Cyan
        Write-Host "     " -NoNewline
        Write-Host "Riesgo: " -NoNewline -ForegroundColor DarkGray
        Write-Host "$($rec.Risk) " -NoNewline -ForegroundColor $riskColor
        Write-Host "| " -NoNewline -ForegroundColor DarkGray
        Write-Host "Impacto: " -NoNewline -ForegroundColor DarkGray
        Write-Host $rec.Impact -ForegroundColor Green
        Write-Host ""
        $i++
    }
}

# ============================================================================
# MAIN
# ============================================================================

# ============================================================================
# REGISTRY HEURISTICS
# ============================================================================

function Get-RegistryOptimizationStatus {
    $recommendations = @()

    # HAGS Check
    $hags = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -ErrorAction SilentlyContinue
    if (-not $hags -or $hags.HwSchMode -ne 2) {
        $recommendations += @{
            Title       = "HAGS Desactivado"
            Description = "Hardware-Accelerated GPU Scheduling puede reducir latencia."
            Action      = "Ejecutar: Advanced-Registry.ps1"
            Priority    = 70
            Risk        = "Medium"
            Impact      = "Medium"
            Category    = "Registry"
        }
    }

    # GameDVR FSE
    $fse = Get-ItemProperty "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehaviorMode" -ErrorAction SilentlyContinue
    if (-not $fse -or $fse.GameDVR_FSEBehaviorMode -ne 2) {
        $recommendations += @{
            Title       = "Full-Screen Optimization Activo"
            Description = "Desactivar FSE puede mejorar frame pacing y reducir input lag."
            Action      = "Ejecutar: Advanced-Registry.ps1"
            Priority    = 65
            Risk        = "Low"
            Impact      = "Medium"
            Category    = "Registry"
        }
    }
    
    # Network Throttling
    $throttle = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -ErrorAction SilentlyContinue
    if (-not $throttle -or $throttle.NetworkThrottlingIndex -ne 0xFFFFFFFF) {
        $recommendations += @{
            Title       = "Throttling de Red Activo"
            Description = "Windows limita el tráfico multimedia/juegos. Desactívalo."
            Action      = "Ejecutar: Advanced-Registry.ps1"
            Priority    = 80
            Risk        = "Low"
            Impact      = "High"
            Category    = "Registry"
        }
    }

    return $recommendations
}

Write-Section "AI-POWERED RECOMMENDATIONS v6.0"

# Analyze system
$SysProfile = Get-SystemProfile

# Show analysis
Show-SystemAnalysis -Profile $SysProfile

# Get recommendations
$recommendations = Get-SmartRecommendations -Profile $SysProfile

# Show recommendations
Show-Recommendations -Recommendations $recommendations

# Interactive Auto-Apply
Invoke-AIAutoApply -Recommendations $recommendations

# Save report
try {
    $reportPath = Join-Path ([Environment]::GetFolderPath('Desktop')) "AI_Recommendations_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    
    $reportContent = @"
NEURAL OPTIMIZER - AI RECOMMENDATIONS
Generated: $(Get-Date)

SYSTEM HEALTH SCORE: $($SysProfile.Score)/100
WORKLOAD: $($SysProfile.Workload)

HARDWARE:
  CPU: $($SysProfile.Hardware.CpuVendor) ($($SysProfile.Hardware.CpuCores)C/$($SysProfile.Hardware.CpuThreads)T)
  RAM: $($SysProfile.Hardware.RamGB) GB
  GPU: $($SysProfile.Hardware.GpuVendor)
  Storage: $(if($SysProfile.Hardware.IsNVMe){"NVMe"}elseif($SysProfile.Hardware.IsSSD){"SSD"}else{"HDD"})

RECOMMENDATIONS ($($recommendations.Count)):

"@
    
    $i = 1
    foreach ($rec in $recommendations) {
        $reportContent += @"
[$i] $($rec.Title)
    Description: $($rec.Description)
    Action: $($rec.Action)
    Risk: $($rec.Risk) | Impact: $($rec.Impact)

"@
        $i++
    }
    
    $reportContent | Out-File -FilePath $reportPath -Encoding UTF8
    
    Write-Host " [i] Reporte guardado: $reportPath" -ForegroundColor Cyan
    Write-Host ""
}
catch {}

Wait-ForKeyPress



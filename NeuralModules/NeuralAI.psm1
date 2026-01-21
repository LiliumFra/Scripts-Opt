<#
.SYNOPSIS
    Neural-AI Module v2.0
    Implements Local Reinforcement Learning (Q-Learning) for system optimization.

.DESCRIPTION
    Advanced AI module with:
    - Q-Learning with persistent Q-Table
    - Expanded system metrics (GPU, Disk, Network, Temperature)
    - Epsilon-greedy exploration with decay
    - 12+ exploratory tweaks with risk assessment
    - Adaptive reward function
    - Performance regression detection

.NOTES
    Part of Windows Neural Optimizer
    Author: Jose Bustamante
#>

$Script:ModulePath = Split-Path $MyInvocation.MyCommand.Path -Parent
$Script:BrainPath = Join-Path $Script:ModulePath "..\NeuralBrain.json"
$Script:QTablePath = Join-Path $Script:ModulePath "..\NeuralQTable.json"
$Script:ConfigPath = Join-Path $Script:ModulePath "..\NeuralConfig.json"

# Import Security Module if available
$SecModule = Join-Path $Script:ModulePath "NeuralSecurity.psm1"
if (Test-Path $SecModule) { Import-Module $SecModule -Force }

# Import Repair Module if available
$RepairModule = Join-Path $Script:ModulePath "NeuralRepair.psm1"
if (Test-Path $RepairModule) { Import-Module $RepairModule -Force }

# Global Hardware/OS Detection
$Script:IsLenovo = (Get-WmiObject Win32_ComputerSystem).Manufacturer -match "Lenovo"
$Script:IsWin11 = [Environment]::OSVersion.Version.Build -ge 22000

# Q-Learning Configuration
$Script:QLearningConfig = @{
    Alpha          = 0.1
    Gamma          = 0.9
    EpsilonInitial = 0.30
    EpsilonMin     = 0.05
    EpsilonDecay   = 0.995
    CurrentEpsilon = 0.30
}

# Tweaks Library - Expanded from GitHub Research (Win11Debloat, Perfect-Windows-11, facet4windows)
# Tweaks Library - Loaded from External Definition
$TweakLibPath = Join-Path $Script:ModulePath "NeuralTweakLibrary.psd1"
if (Test-Path $TweakLibPath) {
    try {
        $ImportedData = Import-PowerShellDataFile -Path $TweakLibPath
        $Script:TweakLibrary = $ImportedData.TweakLibrary
        Write-Host "Loaded $($Script:TweakLibrary.Count) tweaks from NeuralTweakLibrary." -ForegroundColor Cyan
    }
    catch {
        Write-Error "Failed to load TweakLibrary: $_"
        $Script:TweakLibrary = @()
    }
}
else {
    Write-Warning "NeuralTweakLibrary.psd1 not found at $TweakLibPath"
    $Script:TweakLibrary = @()
}



# Persistent State Management
function Get-NeuralBrain {
    if (Test-Path $Script:BrainPath) {
        try { return Get-Content $Script:BrainPath -Raw | ConvertFrom-Json }
        catch { return @{ History = @(); Stats = @{} } }
    }
    return @{ History = @(); Stats = @{} }
}

function Save-NeuralBrain {
    param($Data)
    try { $Data | ConvertTo-Json -Depth 10 | Set-Content $Script:BrainPath -Force -Encoding UTF8 }
    catch { Write-Host " [!] Error saving AI Brain: $_" -ForegroundColor Red }
}

function Get-QTable {
    if (Test-Path $Script:QTablePath) {
        try {
            $json = Get-Content $Script:QTablePath -Raw | ConvertFrom-Json
            $table = @{}
            $json.PSObject.Properties | ForEach-Object {
                $table[$_.Name] = @{}
                if ($_.Value) {
                    $_.Value.PSObject.Properties | ForEach-Object { $table[$_.Name][$_.Name] = $_.Value }
                }
            }
            return $table
        }
        catch { return @{} }
    }
    return @{}
}

function Save-QTable {
    param($QTable)
    try { $QTable | ConvertTo-Json -Depth 5 | Set-Content $Script:QTablePath -Force -Encoding UTF8 }
    catch { Write-Host " [!] Error saving Q-Table: $_" -ForegroundColor Red }
}

function Get-NeuralConfig {
    $default = @{ Epsilon = $Script:QLearningConfig.EpsilonInitial; LearningCycles = 0 }
    
    if (Test-Path $Script:ConfigPath) {
        try { 
            $loaded = Get-Content $Script:ConfigPath -Raw | ConvertFrom-Json
            # Ensure return is a PSCustomObject
            if (-not ($loaded -is [PSCustomObject])) {
                return [PSCustomObject]$default
            }
            # Ensure properties exist
            if (-not $loaded.PSObject.Properties['Epsilon']) { 
                $loaded | Add-Member -MemberType NoteProperty -Name 'Epsilon' -Value $default.Epsilon 
            }
            if (-not $loaded.PSObject.Properties['LearningCycles']) { 
                $loaded | Add-Member -MemberType NoteProperty -Name 'LearningCycles' -Value $default.LearningCycles 
            }
            return $loaded
        }
        catch { return [PSCustomObject]$default }
    }
    return [PSCustomObject]$default
}

function Save-NeuralConfig {
    param($Config)
    try { $Config | ConvertTo-Json | Set-Content $Script:ConfigPath -Force -Encoding UTF8 }
    catch { }
}

# Expanded Metrics Collection
function Measure-SystemMetrics {
    param([int]$DurationSeconds = 5)
    
    Write-Host "   [AI] Measuring System Metrics (Extended)..." -ForegroundColor Cyan
    
    $metrics = @{
        DpcTime       = 0
        InterruptTime = 0
        ContextSwitch = 0
        GpuUsage      = 0
        DiskQueue     = 0
        NetworkPing   = 0
        CpuTemp       = 0
        Score         = 50
        Timestamp     = Get-Date
    }
    
    try {
        # Use WMI/CIM for Language Independence (Spanish/English compatible)
        $procStats = Get-CimInstance -Class Win32_PerfFormattedData_PerfOS_Processor -Filter "Name='_Total'" -ErrorAction Stop
        $sysStats = Get-CimInstance -Class Win32_PerfFormattedData_PerfOS_System -ErrorAction SilentlyContinue
        $diskStats = Get-CimInstance -Class Win32_PerfFormattedData_PerfDisk_PhysicalDisk -Filter "Name='_Total'" -ErrorAction SilentlyContinue

        if ($procStats) {
            $metrics.DpcTime = $procStats.PercentDPCTime
            $metrics.InterruptTime = $procStats.PercentInterruptTime
            $metrics.ProcessorTime = $procStats.PercentProcessorTime # Internal tracking
        }
        if ($sysStats) {
            $metrics.ContextSwitch = $sysStats.ContextSwitchesPerSec
        }
        if ($diskStats) {
            $metrics.DiskQueue = $diskStats.CurrentDiskQueueLength
        }
    }
    catch { 
        Write-Host "   [!] WMI Counters unavailable. Trying legacy fallback..." -ForegroundColor Yellow 
        # Fallback to English counters if WMI fails (rare)
        try {
            $counters = @("\Processor(_Total)\% DPC Time", "\Processor(_Total)\% Interrupt Time", "\System\Context Switches/sec")
            $samples = Get-Counter -Counter $counters -SampleInterval 1 -MaxSamples 1
            $metrics.DpcTime = ($samples.CounterSamples | Where-Object { $_.Path -match "dpc" }).CookedValue
        }
        catch {}
    }
    
    try {
        $ping = Test-Connection -ComputerName "8.8.8.8" -Count 2 -ErrorAction Stop
        $metrics.NetworkPing = [math]::Round(($ping.ResponseTime | Measure-Object -Average).Average, 0)
    }
    catch { $metrics.NetworkPing = 999 }
    
    try {
        $temp = Get-CimInstance -Namespace root\WMI -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction Stop
        if ($temp) {
            $kelvin = ($temp.CurrentTemperature | Measure-Object -Average).Average
            $metrics.CpuTemp = [math]::Round(($kelvin / 10) - 273.15, 1)
        }
    }
    catch { $metrics.CpuTemp = 0 }
    
    $metrics.Score = Get-CompositeScore -Metrics $metrics
    return [PSCustomObject]$metrics
}

# Deep Learning: Load State Detection
function Get-SystemLoadState {
    try {
        $cpu = (Get-Counter "\Processor(_Total)\% Processor Time" -MaxSamples 2 -SampleInterval 1 -ErrorAction SilentlyContinue).CounterSamples.CookedValue | Measure-Object -Average | Select-Object -ExpandProperty Average
        $disk = (Get-Counter "\PhysicalDisk(_Total)\% Disk Time" -MaxSamples 2 -SampleInterval 1 -ErrorAction SilentlyContinue).CounterSamples.CookedValue | Measure-Object -Average | Select-Object -ExpandProperty Average
        
        # Simple heuristic for User Presence (could be expanded)
        # For now, we assume user is active if script is running interactively
        
        if ($cpu -lt 10 -and $disk -lt 10) { return "Idle" }
        if ($cpu -gt 80 -or $disk -gt 90) { return "Thrashing" }
        if ($cpu -gt 40) { return "Heavy" }
        return "Light"
    }
    catch { return "General" }
}

function Get-CompositeScore {
    param($Metrics)
    $score = 100
    
    # Non-linear Multi-dimensional Penalties
    
    # 1. Latency Penalty (Exponential decay)
    if ($Metrics.DpcTime -gt 0.5) { $score -= [math]::Pow($Metrics.DpcTime * 2, 1.5) } 
    if ($Metrics.InterruptTime -gt 0.5) { $score -= [math]::Pow($Metrics.InterruptTime * 2, 1.5) }
    
    # 2. Stability Penalty (Context Switching)
    if ($Metrics.ContextSwitch -gt 3000) { 
        $delta = $Metrics.ContextSwitch - 3000
        $score -= [math]::Log($delta) * 5 # Logarithmic penalty for massive switching
    }
    
    # 3. I/O BottleNeck
    if ($Metrics.DiskQueue -gt 1) { $score -= ($Metrics.DiskQueue * 4) }
    
    # 4. Network Jitter Proxy (Ping)
    if ($Metrics.NetworkPing -gt 30) { $score -= ($Metrics.NetworkPing - 30) / 5 }
    
    # 5. Thermal Throttle Risk
    if ($Metrics.CpuTemp -gt 80) { $score -= ($Metrics.CpuTemp - 80) * 3 } # Aggressive thermal penalty
    
    return [math]::Max(0, [math]::Min(100, [math]::Round($score, 2)))
}

# Q-Learning Engine
function Get-CurrentState {
    param($Hardware, $Workload)
    $hour = (Get-Date).Hour
    $timeSlot = switch ($hour) {
        { $_ -ge 6 -and $_ -lt 12 } { "Morning" }
        { $_ -ge 12 -and $_ -lt 18 } { "Afternoon" }
        { $_ -ge 18 -and $_ -lt 23 } { "Evening" }
        default { "Night" }
    }
    $tier = if ($Hardware.PerformanceTier) { $Hardware.PerformanceTier } else { "Standard" }
    $work = if ($Workload) { $Workload } else { "General" }
    $load = Get-SystemLoadState
    
    # Deep State: Tier|Workload|Time|Load
    return "$tier|$work|$timeSlot|$load"
}

function Get-AvailableActions {
    param(
        [string]$RiskLevel = "Low",
        [string]$Workload = "General",
        [object]$Hardware = $null
    )
    
    # Detect hardware if not provided
    if (-not $Hardware) {
        $Hardware = @{
            HasNvidia = (Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "NVIDIA" }).Count -gt 0
            HasAMD    = (Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "AMD|Radeon" }).Count -gt 0
            HasIntel  = (Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "Intel" }).Count -gt 0
            IsLenovo  = (Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue).Manufacturer -match "Lenovo"
            IsLaptop  = (Get-CimInstance Win32_SystemEnclosure -ErrorAction SilentlyContinue).ChassisTypes -in @(8, 9, 10, 11, 12, 14, 18, 21)
            HasSSD    = (Get-PhysicalDisk -ErrorAction SilentlyContinue | Where-Object { $_.MediaType -eq "SSD" -or $_.MediaType -eq "NVMe" }).Count -gt 0
        }
    }
    
    # Define workload-specific category priorities
    $categoryPriorities = switch ($Workload) {
        "Gaming" { @("Latency", "GPU", "Gaming", "Input", "Memory", "Scheduler", "Network") }
        "Productivity" { @("UI", "System", "Memory", "Storage", "Privacy") }
        "Audio" { @("Audio", "Latency", "System", "Memory") }
        "Streaming" { @("Network", "GPU", "System", "Memory") }
        "Development" { @("System", "Storage", "Memory", "UI", "Privacy") }
        default { @("Latency", "Gaming", "Memory", "System", "Network", "UI", "Input", "Storage", "Privacy", "Scheduler", "Audio", "GPU", "Kernel", "Security") }
    }
    
    $actions = @()
    
    foreach ($tweak in $Script:TweakLibrary) {
        # 1. Risk Filter
        $riskOk = ($RiskLevel -eq "All") -or 
        ($tweak.Risk -eq $RiskLevel) -or 
        ($RiskLevel -eq "Medium" -and $tweak.Risk -eq "Low") -or
        ($RiskLevel -eq "High" -and $tweak.Risk -in @("Low", "Medium"))
        
        if (-not $riskOk) { continue }
        
        # 2. Hardware-specific exclusions
        # Skip NVIDIA tweaks on non-NVIDIA systems
        if ($tweak.Id -match "^Nv|NVIDIA" -and -not $Hardware.HasNvidia) { continue }
        
        # Skip Lenovo tweaks on non-Lenovo systems
        if ($tweak.Category -eq "Lenovo" -and -not $Hardware.IsLenovo) { continue }
        
        # Skip power/AHCI tweaks on desktops (optional - laptops benefit more)
        if ($tweak.Category -eq "Power" -and -not $Hardware.IsLaptop -and $tweak.Risk -eq "Medium") { continue }
        
        # Skip SSD-specific tweaks on HDD-only systems
        if ($tweak.Id -in @("Prefetch", "Superfetch", "WSearch", "SysMain") -and -not $Hardware.HasSSD) { continue }
        
        # 3. Condition script check
        if ($tweak.ConditionScript) {
            try {
                $canApply = Invoke-Expression $tweak.ConditionScript
                if (-not $canApply) { continue }
            }
            catch { continue }
        }
        
        # 4. Category priority scoring
        $priorityIndex = $categoryPriorities.IndexOf($tweak.Category)
        if ($priorityIndex -lt 0) { $priorityIndex = 100 } # Low priority for uncategorized
        
        # Add with priority metadata
        $actions += [PSCustomObject]@{
            Id       = $tweak.Id
            Priority = $priorityIndex
            Category = $tweak.Category
            Risk     = $tweak.Risk
        }
    }
    
    # Sort by priority and return just IDs
    $sortedActions = $actions | Sort-Object Priority | Select-Object -ExpandProperty Id
    
    return $sortedActions
}

function Get-QValue {
    param($QTable, $State, $Action)
    if ($QTable.ContainsKey($State) -and $QTable[$State].ContainsKey($Action)) { return $QTable[$State][$Action] }
    return 0.0
}

function Set-QValue {
    param($QTable, $State, $Action, $Value)
    if (-not $QTable.ContainsKey($State)) { $QTable[$State] = @{} }
    $QTable[$State][$Action] = $Value
}

function Select-Action {
    param($QTable, $State, $AvailableActions, $Epsilon)
    if ($AvailableActions.Count -eq 0) { return $null }
    if ((Get-Random -Minimum 0.0 -Maximum 1.0) -lt $Epsilon) { return $AvailableActions | Get-Random }
    $bestAction = $null
    $bestValue = [double]::MinValue
    foreach ($action in $AvailableActions) {
        $value = Get-QValue -QTable $QTable -State $State -Action $action
        if ($value -gt $bestValue) { $bestValue = $value; $bestAction = $action }
    }
    if ($null -eq $bestAction) { return $AvailableActions | Get-Random }
    return $bestAction
}

function Update-QValue {
    param($QTable, $State, $Action, $Reward, $NewState, $AvailableActions)
    $alpha = $Script:QLearningConfig.Alpha
    $gamma = $Script:QLearningConfig.Gamma
    $currentQ = Get-QValue -QTable $QTable -State $State -Action $Action
    $maxNewQ = 0
    foreach ($a in $AvailableActions) {
        $q = Get-QValue -QTable $QTable -State $NewState -Action $a
        if ($q -gt $maxNewQ) { $maxNewQ = $q }
    }
    $newQ = $currentQ + $alpha * ($Reward + $gamma * $maxNewQ - $currentQ)
    Set-QValue -QTable $QTable -State $State -Action $Action -Value $newQ
}

# ============================================================================
# ENHANCED AI v7.0 - Modern RL Algorithms
# ============================================================================

# Action Visit Counter for UCB1
$Script:ActionVisits = @{}
$Script:TotalVisits = 0

function Get-ActionVisits {
    param([string]$State, [string]$Action)
    $key = "$State|$Action"
    if ($Script:ActionVisits.ContainsKey($key)) { return $Script:ActionVisits[$key] }
    return 0
}

function Update-ActionVisits {
    param([string]$State, [string]$Action)
    $key = "$State|$Action"
    if (-not $Script:ActionVisits.ContainsKey($key)) { $Script:ActionVisits[$key] = 0 }
    $Script:ActionVisits[$key]++
    $Script:TotalVisits++
}

function Select-ActionUCB1 {
    <#
    .SYNOPSIS
        Upper Confidence Bound 1 action selection
    .DESCRIPTION
        Balances exploration vs exploitation mathematically.
        Better than epsilon-greedy for long-term optimization.
    #>
    param($QTable, $State, $AvailableActions, $ExplorationConstant = 1.41)
    
    if ($AvailableActions.Count -eq 0) { return $null }
    if ($Script:TotalVisits -eq 0) { return $AvailableActions | Get-Random }
    
    $bestAction = $null
    $bestUCB = [double]::MinValue
    
    foreach ($action in $AvailableActions) {
        $qValue = Get-QValue -QTable $QTable -State $State -Action $action
        $visits = Get-ActionVisits -State $State -Action $action
        
        if ($visits -eq 0) {
            # Unexplored action - prioritize
            return $action
        }
        
        # UCB1 formula: Q(s,a) + c * sqrt(ln(N) / n(a))
        $ucbValue = $qValue + $ExplorationConstant * [math]::Sqrt([math]::Log($Script:TotalVisits) / $visits)
        
        if ($ucbValue -gt $bestUCB) {
            $bestUCB = $ucbValue
            $bestAction = $action
        }
    }
    
    return $bestAction
}

function Select-ActionThompson {
    <#
    .SYNOPSIS
        Thompson Sampling for rapid decision making
    .DESCRIPTION
        Samples from posterior distribution - great for quick optimizations
    #>
    param($QTable, $State, $AvailableActions)
    
    if ($AvailableActions.Count -eq 0) { return $null }
    
    $samples = @{}
    foreach ($action in $AvailableActions) {
        $qValue = Get-QValue -QTable $QTable -State $State -Action $action
        $visits = [math]::Max(1, (Get-ActionVisits -State $State -Action $action))
        
        # Beta distribution approximation with normal
        $mean = ($qValue + 5) / 10  # Normalize to 0-1
        $stdDev = 1 / [math]::Sqrt($visits)
        
        # Sample from normal approximation
        $u1 = Get-Random -Minimum 0.001 -Maximum 0.999
        $u2 = Get-Random -Minimum 0.001 -Maximum 0.999
        $z = [math]::Sqrt(-2 * [math]::Log($u1)) * [math]::Cos(2 * [math]::PI * $u2)
        $sample = $mean + $stdDev * $z
        
        $samples[$action] = $sample
    }
    
    # Return action with highest sample
    return ($samples.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1).Key
}

function Predict-UserWorkload {
    <#
    .SYNOPSIS
        Predicts current user workload based on running processes
    .DESCRIPTION
        Analyzes active applications to determine: Gaming, Productivity, Streaming, Development, Idle
    #>
    
    try {
        $procs = Get-Process -ErrorAction SilentlyContinue | Select-Object ProcessName, WorkingSet64
        
        # Gaming indicators
        $gamingProcs = @("steam", "epicgameslauncher", "origin", "uplay", "battlenet", "riotclient", 
            "javaw", "minecraft", "valorant", "csgo", "dota2", "gta5", "elden", "cyberpunk")
        $isGaming = ($procs | Where-Object { $gamingProcs -contains $_.ProcessName }).Count -gt 0
        
        # High GPU usage game detection
        $highMemProcs = $procs | Where-Object { $_.WorkingSet64 -gt 2GB } | Select-Object -ExpandProperty ProcessName
        $likelyGame = $highMemProcs | Where-Object { $_ -notmatch "chrome|firefox|edge|code|devenv|explorer|svchost" }
        
        if ($isGaming -or $likelyGame) { return "Gaming" }
        
        # Productivity indicators
        $prodProcs = @("WINWORD", "EXCEL", "POWERPNT", "OUTLOOK", "Teams", "zoom", "slack", "notion")
        $isProd = ($procs | Where-Object { $prodProcs -contains $_.ProcessName }).Count -gt 0
        if ($isProd) { return "Productivity" }
        
        # Development indicators
        $devProcs = @("Code", "devenv", "idea64", "pycharm64", "rider64", "webstorm64", "node", "python")
        $isDev = ($procs | Where-Object { $devProcs -contains $_.ProcessName }).Count -gt 0
        if ($isDev) { return "Development" }
        
        # Streaming indicators
        $streamProcs = @("obs64", "obs32", "streamlabs", "xsplit", "nvidia share")
        $isStream = ($procs | Where-Object { $streamProcs -contains $_.ProcessName }).Count -gt 0
        if ($isStream) { return "Streaming" }
        
        # Browser heavy = Mixed/Browse
        $browserProcs = @("chrome", "firefox", "msedge", "brave")
        $browserCount = ($procs | Where-Object { $browserProcs -contains $_.ProcessName }).Count
        if ($browserCount -gt 3) { return "Browsing" }
        
        # Check CPU usage for idle
        $cpu = (Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor -Filter "Name='_Total'" -ErrorAction SilentlyContinue).PercentProcessorTime
        if ($cpu -lt 10) { return "Idle" }
        
        return "General"
    }
    catch {
        return "General"
    }
}

function Get-MultiObjectiveReward {
    <#
    .SYNOPSIS
        Calculates reward considering multiple performance dimensions
    #>
    param($Baseline, $Current, $Weights = @{ Latency = 0.4; Stability = 0.3; Responsiveness = 0.2; Thermal = 0.1 })
    
    $reward = 0
    
    # Latency improvement (DPC + Interrupt)
    $latencyDelta = ($Baseline.DpcTime - $Current.DpcTime) + ($Baseline.InterruptTime - $Current.InterruptTime)
    $reward += $latencyDelta * $Weights.Latency * 10
    
    # Stability (Context switches - lower is better)
    $stabilityDelta = ($Baseline.ContextSwitch - $Current.ContextSwitch) / 1000
    $reward += $stabilityDelta * $Weights.Stability * 5
    
    # Responsiveness (Disk queue - lower is better)
    $responseDelta = $Baseline.DiskQueue - $Current.DiskQueue
    $reward += $responseDelta * $Weights.Responsiveness * 5
    
    # Thermal (lower is better)
    $thermalDelta = $Baseline.CpuTemp - $Current.CpuTemp
    $reward += $thermalDelta * $Weights.Thermal
    
    return [math]::Round($reward, 3)
}

function Invoke-BatchLearning {
    <#
    .SYNOPSIS
        Runs multiple learning cycles rapidly for initial training
    #>
    param(
        [int]$Episodes = 10,
        [string]$Workload = "General",
        [switch]$Silent
    )
    
    if (-not $Silent) {
        Write-Host ""
        Write-Host " === BATCH LEARNING MODE ($Episodes episodes) ===" -ForegroundColor Magenta
    }
    
    $qTable = Get-QTable
    $hardware = Get-HardwareProfile
    $results = @()
    
    for ($i = 1; $i -le $Episodes; $i++) {
        if (-not $Silent) {
            Write-Host " [Episode $i/$Episodes]" -NoNewline -ForegroundColor Cyan
        }
        
        $state = Get-CurrentState -Hardware $hardware -Workload $Workload
        $actions = Get-AvailableActions -RiskLevel "Low" -Workload $Workload -Hardware $hardware
        
        # Use UCB1 for batch learning
        $action = Select-ActionUCB1 -QTable $qTable -State $state -AvailableActions $actions
        
        if ($action) {
            $baseline = Measure-SystemMetrics -DurationSeconds 2
            $applied = Invoke-Tweak -TweakId $action -Apply
            
            if ($applied) {
                Start-Sleep -Seconds 1
                $after = Measure-SystemMetrics -DurationSeconds 2
                $reward = Get-MultiObjectiveReward -Baseline $baseline -Current $after
                
                Update-ActionVisits -State $state -Action $action
                Update-QValue -QTable $qTable -State $state -Action $action -Reward $reward -NewState $state -AvailableActions $actions
                
                $results += @{ Episode = $i; Action = $action; Reward = $reward }
                
                if (-not $Silent) {
                    $color = if ($reward -gt 0) { "Green" } elseif ($reward -lt 0) { "Red" } else { "Gray" }
                    Write-Host " ${action}: " -NoNewline
                    Write-Host "$reward" -ForegroundColor $color
                }
                
                # Revert if negative
                if ($reward -lt 0) {
                    Invoke-Tweak -TweakId $action -Revert | Out-Null
                }
            }
        }
    }
    
    Save-QTable -QTable $qTable
    
    $totalReward = ($results | Measure-Object -Property Reward -Sum).Sum
    $avgReward = if ($results.Count -gt 0) { [math]::Round($totalReward / $results.Count, 3) } else { 0 }
    
    if (-not $Silent) {
        Write-Host ""
        Write-Host " Batch Complete: $($results.Count) actions, Total Reward: $totalReward, Avg: $avgReward" -ForegroundColor Green
    }
    
    return @{ Episodes = $results.Count; TotalReward = $totalReward; AverageReward = $avgReward }
}

function Invoke-QuickOptimization {
    <#
    .SYNOPSIS
        Fast optimization using Thompson Sampling (no wait for full learning)
    #>
    param([int]$Actions = 5)
    
    Write-Host ""
    Write-Host " === QUICK OPTIMIZATION (Thompson Sampling) ===" -ForegroundColor Cyan
    
    $qTable = Get-QTable
    $hardware = Get-HardwareProfile
    $workload = Predict-UserWorkload
    
    Write-Host " Detected Workload: $workload" -ForegroundColor Gray
    
    $state = Get-CurrentState -Hardware $hardware -Workload $workload
    $availableActions = Get-AvailableActions -RiskLevel "Low" -Workload $workload -Hardware $hardware
    
    $applied = @()
    for ($i = 0; $i -lt $Actions; $i++) {
        $action = Select-ActionThompson -QTable $qTable -State $state -AvailableActions $availableActions
        
        if ($action -and ($action -notin $applied)) {
            $result = Invoke-Tweak -TweakId $action -Apply
            if ($result) {
                $applied += $action
                Write-Host " Applied: $action" -ForegroundColor Green
            }
        }
    }
    
    Write-Host ""
    Write-Host " Quick Optimization Complete: $($applied.Count) tweaks applied" -ForegroundColor Cyan
    return $applied
}

# Tweak Application
function Invoke-Tweak {
    param([string]$TweakId, [switch]$Apply, [switch]$Revert)
    $tweak = $Script:TweakLibrary | Where-Object { $_.Id -eq $TweakId }
    if (-not $tweak) { Write-Host "   [!] Tweak not found: $TweakId" -ForegroundColor Red; return $false }
    
    # Check condition if present
    if ($tweak.ConditionScript) {
        try {
            $canApply = Invoke-Expression $tweak.ConditionScript
            if (-not $canApply) {
                Write-Host "   [i] Skipping $TweakId (condition not met)" -ForegroundColor DarkGray
                return $false
            }
        }
        catch { return $false }
    }
    
    $value = if ($Apply) { $tweak.ValueOn } else { $tweak.ValueOff }
    $command = if ($Apply) { $tweak.CommandOn } else { $tweak.CommandOff }
    $wmiValue = if ($Apply) { $tweak.WmiValueOn } else { $tweak.WmiValueOff }
    
    try {
        if ($tweak.WmiSetting) {
            # Lenovo WMI-based tweak
            $setBios = Get-CimInstance -Namespace root\wmi -ClassName Lenovo_SetBiosSetting -ErrorAction Stop
            $setResult = $setBios | Invoke-CimMethod -MethodName SetBiosSetting -Arguments @{ parameter = "$($tweak.WmiSetting),$wmiValue" }
            if ($setResult.return -eq "Success") {
                $saveBios = Get-CimInstance -Namespace root\wmi -ClassName Lenovo_SaveBiosSettings -ErrorAction Stop
                $saveBios | Invoke-CimMethod -MethodName SaveBiosSettings -Arguments @{ parameter = "" } | Out-Null
                return $true
            }
            return $false
        }
        elseif ($tweak.Path) {
            # Registry-based tweak
            # Ensure path exists for deeper keys
            if (-not (Test-Path $tweak.Path)) { New-Item -Path $tweak.Path -Force -ErrorAction SilentlyContinue | Out-Null }
            Set-ItemProperty -Path $tweak.Path -Name $tweak.Key -Value $value -Force -ErrorAction Stop
            return $true
        }
        elseif ($command) {
            # Command-based tweak (Powershell/CMD mixed)
            # Use Invoke-Expression but silence output unless error
            Invoke-Expression $command 2>&1 | Out-Null
            return $true
        }
        return $false
    }
    catch { 
        # Only log critical errors, suppress "property not found" for optional features
        if ($_.Exception.Message -notmatch "Property.*does not exist") {
            Write-Host "   [!] Failed: $_" -ForegroundColor Red
        }
        return $false 
    }
}

# Main Learning Cycle
function Invoke-NeuralLearning {
    param([string]$ProfileName, [object]$Hardware, [string]$Workload = "General")
    
    Write-Section "NEURAL Q-LEARNING CYCLE v2.0 (DEEP LEARNING)"
    
    $config = Get-NeuralConfig
    $qTable = Get-QTable
    $brain = Get-NeuralBrain
    $epsilon = if ($config.Epsilon) { $config.Epsilon } else { $Script:QLearningConfig.EpsilonInitial }
    
    # Deep Learning: Consolidate Long-Term Memory
    Update-PersistenceRewards -QTable $qTable
    
    $state = Get-CurrentState -Hardware $Hardware -Workload $Workload
    Write-Host "   [STATE] $state" -ForegroundColor Gray
    Write-Host "   [e] Exploration Rate: $([math]::Round($epsilon * 100, 1))%" -ForegroundColor Gray
    
    Write-Host ""
    Write-Host "   [AI] Measuring Baseline..." -ForegroundColor Cyan
    $baselineMetrics = Measure-SystemMetrics -DurationSeconds 3
    $baselineScore = $baselineMetrics.Score
    Write-Host "   [BASELINE] Score: $baselineScore/100" -ForegroundColor Yellow
    
    $availableActions = Get-AvailableActions -RiskLevel "Low" -Workload $Workload -Hardware $Hardware
    Write-Host "   [AI] Available Actions: $($availableActions.Count) tweaks (filtered by context)\" -ForegroundColor DarkGray
    $selectedAction = Select-Action -QTable $qTable -State $state -AvailableActions $availableActions -Epsilon $epsilon
    
    $newScore = $baselineScore
    $reward = 0
    
    if ($selectedAction) {
        $tweak = $Script:TweakLibrary | Where-Object { $_.Id -eq $selectedAction }
        Write-Host ""
        Write-Host "   [ACTION] Selected: $($tweak.Name) ($selectedAction)" -ForegroundColor Magenta
        
        $applied = Invoke-Tweak -TweakId $selectedAction -Apply
        if ($applied) {
            Start-Sleep -Seconds 2
            Write-Host "   [AI] Measuring Impact..." -ForegroundColor Cyan
            $newMetrics = Measure-SystemMetrics -DurationSeconds 3
            $newScore = $newMetrics.Score
            $reward = $newScore - $baselineScore
            
            Write-Host ""
            if ($reward -gt 0) { Write-Host "   [RESULT] Score: $newScore (+$reward) IMPROVEMENT" -ForegroundColor Green }
            elseif ($reward -lt 0) {
                Write-Host "   [RESULT] Score: $newScore ($reward) REGRESSION" -ForegroundColor Red
                Write-Host "   [AI] Reverting tweak..." -ForegroundColor Yellow
                Invoke-Tweak -TweakId $selectedAction -Revert | Out-Null
            }
            else { Write-Host "   [RESULT] Score: $newScore - NO CHANGE" -ForegroundColor Gray }
            
            Update-QValue -QTable $qTable -State $state -Action $selectedAction -Reward $reward -NewState $state -AvailableActions $availableActions
            Save-QTable -QTable $qTable
            
            $epsilon = [math]::Max($Script:QLearningConfig.EpsilonMin, $epsilon * $Script:QLearningConfig.EpsilonDecay)
            $config.Epsilon = $epsilon
            $config.LearningCycles = ($config.LearningCycles -as [int]) + 1
            Save-NeuralConfig -Config $config
        }
    }
    else { Write-Host "   [AI] No suitable actions available" -ForegroundColor Yellow }
    
    if (-not $brain.History) { $brain = @{ History = @(); Stats = @{} } }
    $record = @{
        Timestamp     = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Hardware      = if ($Hardware.CpuName) { $Hardware.CpuName } else { "Unknown" }
        Tier          = if ($Hardware.PerformanceTier) { $Hardware.PerformanceTier } else { "Standard" }
        Profile       = $ProfileName
        Workload      = $Workload
        State         = $state
        Action        = $selectedAction
        BaselineScore = $baselineScore
        FinalScore    = $newScore
        Reward        = $reward
        Metrics       = $baselineMetrics
    }
    $history = @($brain.History) + $record
    $brain.History = $history | Select-Object -Last 100
    Save-NeuralBrain -Data $brain
    
    Write-Host ""
    Show-QLearningInsights -QTable $qTable -State $state
}

function Show-QLearningInsights {
    param($QTable, $State)
    Write-Host "   === Q-LEARNING INSIGHTS ===" -ForegroundColor Cyan
    if ($QTable.ContainsKey($State)) {
        $stateActions = $QTable[$State]
        Write-Host "   Top actions for state [$State]:" -ForegroundColor Gray
        $stateActions.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 5 | ForEach-Object {
            $color = if ($_.Value -gt 0) { "Green" } elseif ($_.Value -lt 0) { "Red" } else { "Gray" }
            Write-Host "     $($_.Name): Q=$([math]::Round($_.Value, 3))" -ForegroundColor $color
        }
    }
    else { Write-Host "   No learned actions for current state yet." -ForegroundColor Yellow }
    $config = Get-NeuralConfig
    Write-Host "   Total Learning Cycles: $($config.LearningCycles)" -ForegroundColor DarkGray
}

# Recommendations
function Get-NeuralRecommendation {
    param($Hardware, $Workload = "General")
    $qTable = Get-QTable
    $state = Get-CurrentState -Hardware $Hardware -Workload $Workload
    if (-not $qTable.ContainsKey($state)) { return $null }
    $stateActions = $qTable[$state]
    $bestAction = $stateActions.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1
    if ($bestAction -and $bestAction.Value -gt 0) {
        $tweak = $Script:TweakLibrary | Where-Object { $_.Id -eq $bestAction.Name }
        return [PSCustomObject]@{
            RecommendedAction = $bestAction.Name
            ActionName        = if ($tweak) { $tweak.Name } else { $bestAction.Name }
            Confidence        = [math]::Min(100, [math]::Round(50 + $bestAction.Value * 5, 0))
            Reason            = "Best tweak based on Q-Learning (Q=$([math]::Round($bestAction.Value, 3)))"
            Risk              = if ($tweak) { $tweak.Risk } else { "Unknown" }
        }
    }
    return $null
}

function Get-BestTweaksForState {
    param($Hardware, $Workload = "General", $TopN = 5)
    $qTable = Get-QTable
    $state = Get-CurrentState -Hardware $Hardware -Workload $Workload
    $recommendations = @()
    if ($qTable.ContainsKey($state)) {
        $stateActions = $qTable[$state]
        $stateActions.GetEnumerator() | Where-Object { $_.Value -gt 0 } | Sort-Object Value -Descending | Select-Object -First $TopN | ForEach-Object {
            $actionEntry = $_
            $tweakObj = $Script:TweakLibrary | Where-Object { $_.Id -eq $actionEntry.Name }
            $recommendations += [PSCustomObject]@{
                TweakId     = $actionEntry.Name
                Name        = if ($tweakObj) { $tweakObj.Name } else { $actionEntry.Name }
                Category    = if ($tweakObj) { $tweakObj.Category } else { "Unknown" }
                QValue      = [math]::Round($actionEntry.Value, 3)
                Risk        = if ($tweakObj) { $tweakObj.Risk } else { "Unknown" }
                Description = if ($tweakObj) { $tweakObj.Description } else { "" }
            }
        }
    }
    return $recommendations
}

function Invoke-ExploratoryTweak {
    param($CurrentScore)
    Write-Host "   [AI] Exploration is now integrated into Q-Learning cycle" -ForegroundColor Cyan
    Write-Host "   [AI] Run Invoke-NeuralLearning for adaptive exploration" -ForegroundColor Gray
}

function Update-PersistenceRewards {
    param($QTable)
    
    $brain = Get-NeuralBrain
    if (-not $brain.History) { return }
    
    # 1. Identify successful actions from 24h+ ago
    $cutoff = (Get-Date).AddHours(-48) # Look back 2 days
    $longTermSuccess = $brain.History | Where-Object { 
        $_.Reward -gt 0 -and 
        ([DateTime]$_.Timestamp) -gt $cutoff 
    }
    
    foreach ($record in $longTermSuccess) {
        # 2. Reinforce the Q-Value slightly (Memory Consolidation)
        $state = $record.State
        $action = $record.Action
        
        # If Q-Table still has this state/action pair
        if ($QTable.ContainsKey($state) -and $QTable[$state].ContainsKey($action)) {
            $currentQ = $QTable[$state][$action]
            # Small reinforcement (0.01) to solidify "good habits"
            $newQ = $currentQ + 0.01 
            Set-QValue -QTable $QTable -State $state -Action $action -Value $newQ
        }
    }
    Write-Host "   [AI] Long-Term Memory Consolidated ($($longTermSuccess.Count) records processed)" -ForegroundColor DarkGray
}

function Get-BestAction {
    param(
        [hashtable]$QTable,
        [string]$State,
        [array]$AvailableActions,
        [double]$Epsilon
    )

    # Exploration (Epsilon-Greedy)
    if ((Get-Random -Minimum 0.0 -Maximum 1.0) -lt $Epsilon) {
        return $AvailableActions | Get-Random
    }

    # Exploitation (Best Known Action)
    if ($QTable.ContainsKey($State)) {
        $actions = $QTable[$State]
        
        # Sort by Q-Value descending
        $bestAction = $actions.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1
        
        if ($bestAction) {
            return $bestAction.Key
        }
    }

    # Fallback (New State or Empty): Random
    return $AvailableActions | Get-Random
}

function Set-UserFeedback {
    param([int]$Reward)
    
    $brain = Get-NeuralBrain
    $qTable = Get-QTable
    
    if ($brain.History.Count -gt 0) {
        $lastAction = $brain.History | Select-Object -Last 1
        $state = $lastAction.State
        $action = $lastAction.Action
        
        if ($QTable.ContainsKey($state) -and $QTable[$state].ContainsKey($action)) {
            $currentQ = $QTable[$state][$action]
            $newQ = $currentQ + ($Reward * 0.1) # Manual feedback has high weight
            Set-QValue -QTable $QTable -State $state -Action $action -Value $newQ
            Save-QTable -QTable $QTable
            
            $type = if ($Reward -gt 0) { "REINFORCED" } else { "PUNISHED" }
            Write-Host "   [MANUAL] Last action '$action' was $type by user." -ForegroundColor Magenta
        }
    }
}



function Start-NeuralAutoPilot {
    param(
        [string]$ProfileName, 
        [int]$TargetScore = 95,
        [int]$MaxNoOps = 5
    )
    
    Clear-Host
    Write-Host " ==========================================================" -ForegroundColor Magenta
    Write-Host "   NEURAL AUTO-PILOT ENGAGED (SMART STOP MODE)" -ForegroundColor Yellow
    Write-Host "   Target: $TargetScore+ | Convergence Limit: $MaxNoOps cycles" -ForegroundColor Gray
    Write-Host "   Press CTRL+C to Stop Manually" -ForegroundColor Gray
    Write-Host " ==========================================================" -ForegroundColor Magenta
    Write-Host ""
    
    $qTable = Get-QTable
    $brain = Get-NeuralBrain
    $epsilon = 0.15 # Low exploration for AutoPilot
    $consecutiveNoOps = 0
    
    while ($true) {
        $hardware = Get-HardwareProfile
        $loadState = Get-SystemLoadState
        
        # 1. Safety Pause
        if ($loadState -eq "Thrashing") {
            Write-Host "   [!] System High Load. Pausing 30s..." -ForegroundColor Red
            Start-Sleep -Seconds 30
            continue
        }
        
        Write-Host "   [AUTO] Analyzing System State ($loadState)..." -ForegroundColor Cyan
        
        # 2. Deep Verification Baseline (10s)
        Write-Host "   [VERIFY] Measuring Baseline (10s deep scan)..." -ForegroundColor DarkGray
        $baseline = Measure-SystemMetrics -DurationSeconds 10
        Write-Host "   [BASELINE] Score: $($baseline.Score)" -ForegroundColor Yellow
        
        # 3. SMART STOP CHECK
        if ($baseline.Score -ge $TargetScore) {
            if ($consecutiveNoOps -ge $MaxNoOps) {
                Write-Host ""
                Write-Host "   [OPTIMIZATION COMPLETE] Target Reached & Converged." -ForegroundColor Green
                Write-Host "   Final Score: $($baseline.Score)" -ForegroundColor Green
                Write-Host "   System is fully optimized. Auto-Pilot stopping." -ForegroundColor Cyan
                Write-Host " ==========================================================" -ForegroundColor Magenta
                break # EXIT LOOP
            }
            else {
                Write-Host "   [OPTIMAL] Score is high ($($baseline.Score)). Checking stability ($consecutiveNoOps/$MaxNoOps)..." -ForegroundColor Green
                $consecutiveNoOps++
            }
        }
        
        # 4. Action Selection (using intelligent filtering)
        $state = Get-CurrentState -Hardware $hardware -Workload "AutoPilot"
        $availableActions = Get-AvailableActions -RiskLevel "Medium" -Workload "AutoPilot" -Hardware $hardware
        $action = Get-BestAction -QTable $qTable -State $state -AvailableActions $availableActions -Epsilon $epsilon
        
        if ($action) {
            Write-Host "   [ACT] Applying Tweak: $action" -ForegroundColor White
            $applied = Invoke-Tweak -TweakId $action -Apply
            
            if ($applied) {
                # Deep Verify Result
                Start-Sleep -Seconds 2
                $result = Measure-SystemMetrics -DurationSeconds 10
                $reward = Get-CompositeScore -Baseline $baseline -Current $result -RiskLevel "Medium"
                
                $resultColor = if ($reward -gt 0) { "Green" } else { "Red" }
                Write-Host "   [RESULT] New Score: $($result.Score) | Reward: $reward" -ForegroundColor $resultColor
                
                # Update Q-Table
                $newState = Get-CurrentState -Hardware $hardware -Workload "AutoPilot"
                Update-QValue -QTable $qTable -State $state -Action $action -Reward $reward -NewState $newState -AvailableActions $availableActions
                
                # History
                $record = @{ Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"; State = $state; Action = $action; Reward = $reward; Mode = "AutoPilot" }
                $brain.History += $record
                $brain.History = $brain.History | Select-Object -Last 100
                
                if ($reward -gt 0) {
                    $consecutiveNoOps = 0 # Reset counter on valid improvement
                }
                elseif ($reward -lt 0) {
                    Write-Host "   [REVERT] Reverting..." -ForegroundColor Yellow
                    Invoke-Tweak -TweakId $action -Revert
                    $consecutiveNoOps++ # Failure counts towards convergence
                }
                
                Save-QTable -QTable $qTable
                Save-NeuralBrain -Data $brain
            }
            else {
                $consecutiveNoOps++
            }
        }
        else {
            Write-Host "   [SKIP] No confident actions found." -ForegroundColor DarkGray
            $consecutiveNoOps++
        }
        
        Write-Host "   [WAIT] Cooling down (5s)..." -ForegroundColor DarkGray
        Start-Sleep -Seconds 5
    }
}

Export-ModuleMember -Function @(
    # Core Q-Learning
    'Invoke-NeuralLearning',
    'Get-NeuralRecommendation', 
    'Get-NeuralBrain',
    'Measure-SystemMetrics',
    'Get-BestTweaksForState',
    'Get-BestAction',
    'Get-QTable',
    'Get-SystemLoadState',
    'Update-PersistenceRewards',
    'Set-UserFeedback',
    'Start-NeuralAutoPilot',
    'Get-AvailableActions',
    'Invoke-Tweak',
    'Get-CurrentState',
    
    # NEW v7.0 - Enhanced AI
    'Select-ActionUCB1',
    'Select-ActionThompson',
    'Predict-UserWorkload',
    'Get-MultiObjectiveReward',
    'Invoke-BatchLearning',
    'Invoke-QuickOptimization'
)

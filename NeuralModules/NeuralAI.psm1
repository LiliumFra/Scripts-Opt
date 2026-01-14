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
$Script:TweakLibrary = @(
    # === LOW RISK TWEAKS ===
    # Latency
    @{ Id = "TimerRes"; Name = "Global Timer Resolution"; Risk = "Low"; Category = "Latency"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel"; Key = "GlobalTimerResolutionRequests"; ValueOn = 1; ValueOff = 0; Description = "Forces high-resolution timer" },
    @{ Id = "DynamicTick"; Name = "Disable Dynamic Tick"; Risk = "Low"; Category = "Latency"; CommandOn = "bcdedit /set disabledynamictick yes"; CommandOff = "bcdedit /set disabledynamictick no"; Description = "Disables power-saving tick" },
    @{ Id = "HPET"; Name = "Disable HPET"; Risk = "Low"; Category = "Latency"; CommandOn = "bcdedit /set useplatformclock no"; CommandOff = "bcdedit /set useplatformclock yes"; Description = "Uses TSC instead of HPET" },
    @{ Id = "TSCSync"; Name = "TSC Sync Policy"; Risk = "Low"; Category = "Latency"; CommandOn = "bcdedit /set tscsyncpolicy enhanced"; CommandOff = "bcdedit /deletevalue tscsyncpolicy"; Description = "Enhanced TSC synchronization" },
    
    # Gaming
    @{ Id = "GameMode"; Name = "Enable Game Mode"; Risk = "Low"; Category = "Gaming"; Path = "HKCU:\Software\Microsoft\GameBar"; Key = "AllowAutoGameMode"; ValueOn = 1; ValueOff = 0; Description = "Windows Game Mode" },
    @{ Id = "FSO"; Name = "Fullscreen Optimizations"; Risk = "Low"; Category = "Gaming"; Path = "HKCU:\System\GameConfigStore"; Key = "GameDVR_FSEBehaviorMode"; ValueOn = 2; ValueOff = 0; Description = "Disable FSO for classic fullscreen" },
    @{ Id = "GameBar"; Name = "Disable Game Bar"; Risk = "Low"; Category = "Gaming"; Path = "HKCU:\Software\Microsoft\GameBar"; Key = "UseNexusForGameBarEnabled"; ValueOn = 0; ValueOff = 1; Description = "Disable Xbox Game Bar overlay" },
    @{ Id = "GameDVR"; Name = "Disable Game DVR"; Risk = "Low"; Category = "Gaming"; Path = "HKCU:\System\GameConfigStore"; Key = "GameDVR_Enabled"; ValueOn = 0; ValueOff = 1; Description = "Disable background recording" },
    
    # Input
    @{ Id = "MouseAccel"; Name = "Disable Mouse Acceleration"; Risk = "Low"; Category = "Input"; Path = "HKCU:\Control Panel\Mouse"; Key = "MouseSpeed"; ValueOn = "0"; ValueOff = "1"; Description = "Raw mouse input" },
    @{ Id = "MouseHover"; Name = "Faster Tooltips"; Risk = "Low"; Category = "Input"; Path = "HKCU:\Control Panel\Mouse"; Key = "MouseHoverTime"; ValueOn = "10"; ValueOff = "400"; Description = "Faster tooltip display" },
    
    # Network
    @{ Id = "TcpAck"; Name = "TCP ACK Frequency"; Risk = "Low"; Category = "Network"; Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Key = "TcpAckFrequency"; ValueOn = 1; ValueOff = 2; Description = "Immediate TCP ack" },
    @{ Id = "NagleOff"; Name = "Disable Nagle"; Risk = "Low"; Category = "Network"; Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Key = "TcpNoDelay"; ValueOn = 1; ValueOff = 0; Description = "Disable packet buffering" },
    @{ Id = "NetThrottle"; Name = "Disable Network Throttling"; Risk = "Low"; Category = "Network"; Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"; Key = "NetworkThrottlingIndex"; ValueOn = 0xffffffff; ValueOff = 10; Description = "Remove network throttling" },
    
    # UI Performance (from Perfect-Windows-11)
    @{ Id = "MenuDelay"; Name = "Menu Show Delay"; Risk = "Low"; Category = "UI"; Path = "HKCU:\Control Panel\Desktop"; Key = "MenuShowDelay"; ValueOn = "0"; ValueOff = "400"; Description = "Instant menu display" },
    @{ Id = "StartupDelay"; Name = "Startup Delay"; Risk = "Low"; Category = "UI"; Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize"; Key = "StartupDelayInMSec"; ValueOn = 0; ValueOff = 500; Description = "Remove startup app delay" },
    @{ Id = "ForegroundLock"; Name = "Foreground Lock Timeout"; Risk = "Low"; Category = "UI"; Path = "HKCU:\Control Panel\Desktop"; Key = "ForegroundLockTimeout"; ValueOn = 0; ValueOff = 200000; Description = "Faster window switching" },
    
    # === MEDIUM RISK TWEAKS ===
    # Memory
    @{ Id = "MemCompress"; Name = "Disable Memory Compression"; Risk = "Medium"; Category = "Memory"; CommandOn = "Disable-MMAgent -MemoryCompression"; CommandOff = "Enable-MMAgent -MemoryCompression"; Description = "Saves CPU on 16GB+ RAM" },
    @{ Id = "LargePages"; Name = "Large System Pages"; Risk = "Medium"; Category = "Memory"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Key = "LargePageMinimum"; ValueOn = 1; ValueOff = 0; Description = "Enable large memory pages" },
    
    # Storage
    @{ Id = "Prefetch"; Name = "Optimize Prefetch"; Risk = "Medium"; Category = "Storage"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"; Key = "EnablePrefetcher"; ValueOn = 0; ValueOff = 3; Description = "Disable prefetch on SSD" },
    @{ Id = "Superfetch"; Name = "Disable Superfetch"; Risk = "Medium"; Category = "Storage"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"; Key = "EnableSuperfetch"; ValueOn = 0; ValueOff = 3; Description = "Disable superfetch on SSD" },
    
    # CPU/Scheduler
    @{ Id = "SysResp"; Name = "System Responsiveness"; Risk = "Medium"; Category = "Scheduler"; Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"; Key = "SystemResponsiveness"; ValueOn = 0; ValueOff = 20; Description = "Prioritize foreground apps" },
    @{ Id = "CoreParking"; Name = "Disable Core Parking"; Risk = "Medium"; Category = "Scheduler"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583"; Key = "ValueMax"; ValueOn = 0; ValueOff = 100; Description = "Keep all cores active" },
    @{ Id = "PowerThrottle"; Name = "Disable Power Throttling"; Risk = "Medium"; Category = "Scheduler"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling"; Key = "PowerThrottlingOff"; ValueOn = 1; ValueOff = 0; Description = "Prevent CPU throttling" },
    
    # Shutdown/Startup
    @{ Id = "WaitToKill"; Name = "Faster Shutdown"; Risk = "Medium"; Category = "System"; Path = "HKCU:\Control Panel\Desktop"; Key = "WaitToKillAppTimeout"; ValueOn = "2000"; ValueOff = "20000"; Description = "Reduce shutdown wait" },
    @{ Id = "AutoEndTasks"; Name = "Auto End Tasks"; Risk = "Medium"; Category = "System"; Path = "HKCU:\Control Panel\Desktop"; Key = "AutoEndTasks"; ValueOn = "1"; ValueOff = "0"; Description = "Auto-kill hung apps" },
    @{ Id = "HungAppTimeout"; Name = "Hung App Timeout"; Risk = "Medium"; Category = "System"; Path = "HKCU:\Control Panel\Desktop"; Key = "HungAppTimeout"; ValueOn = "1000"; ValueOff = "5000"; Description = "Faster hung app detection" },
    
    # Privacy/Telemetry (from Win11Debloat)
    @{ Id = "Telemetry"; Name = "Disable Telemetry"; Risk = "Medium"; Category = "Privacy"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Key = "AllowTelemetry"; ValueOn = 0; ValueOff = 3; Description = "Disable data collection" },
    
    # === FILESYSTEM OPTIMIZATIONS ===
    @{ Id = "Ntfs83"; Name = "Disable 8.3 Naming"; Risk = "Low"; Category = "Filesystem"; CommandOn = "fsutil behavior set disable8dot3 1"; CommandOff = "fsutil behavior set disable8dot3 0"; Description = "Improves NTFS performance" },
    @{ Id = "NtfsLastAccess"; Name = "Disable Last Access Update"; Risk = "Low"; Category = "Filesystem"; CommandOn = "fsutil behavior set disablelastaccess 1"; CommandOff = "fsutil behavior set disablelastaccess 0"; Description = "Reduces disk write ops" },
    @{ Id = "NtfsEncrypt"; Name = "Disable EFS"; Risk = "Low"; Category = "Filesystem"; CommandOn = "fsutil behavior set disableencryption 1"; CommandOff = "fsutil behavior set disableencryption 0"; Description = "Disables EFS overhead" },
    
    # === ADVANCED NETWORK ===
    @{ Id = "CTCP"; Name = "CTCP Congestion Provider"; Risk = "Medium"; Category = "Network"; CommandOn = "netsh int tcp set supplemental template=internet congestionprovider=ctcp"; CommandOff = "netsh int tcp set supplemental template=internet congestionprovider=default"; Description = "Better throughput on high latency" },
    @{ Id = "RscIPv4"; Name = "Enable RSC (IPv4)"; Risk = "Medium"; Category = "Network"; CommandOn = "netsh int tcp set global rsc=enabled"; CommandOff = "netsh int tcp set global rsc=disabled"; Description = "Receive Segment Coalescing" },
    @{ Id = "RssIPv4"; Name = "Enable RSS"; Risk = "Medium"; Category = "Network"; CommandOn = "netsh int tcp set global rss=enabled"; CommandOff = "netsh int tcp set global rss=disabled"; Description = "Receive Side Scaling" },
    @{ Id = "NetOffload"; Name = "Disable Task Offload"; Risk = "Medium"; Category = "Network"; Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Key = "DisableTaskOffload"; ValueOn = 0; ValueOff = 1; Description = "Let NIC handle offloading" },
    
    # === PROCESSOR & THREADS ===
    @{ Id = "Win32Prio"; Name = "Win32 Priority Separation"; Risk = "Medium"; Category = "System"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"; Key = "Win32PrioritySeparation"; ValueOn = 38; ValueOff = 2; Description = "Optimizes for foreground apps (Hex 26)" },
    @{ Id = "SvcSplit"; Name = "Split Threshold"; Risk = "Medium"; Category = "System"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control"; Key = "SvcHostSplitThresholdInKB"; ValueOn = 380000; ValueOff = 38000000; Description = "Better RAM handling for svchost" },
    @{ Id = "LongPaths"; Name = "Enable Long Paths"; Risk = "Low"; Category = "System"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"; Key = "LongPathsEnabled"; ValueOn = 1; ValueOff = 0; Description = "Removes 260 char limit" },
    
    # === MEMORY & CACHE ===
    @{ Id = "IoPageLock"; Name = "IO Page Lock Limit"; Risk = "High"; Category = "Memory"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Key = "IoPageLockLimit"; ValueOn = 65536; ValueOff = 0; Description = "Boosts I/O throughput" },
    @{ Id = "NonPagedPool"; Name = "NonPaged Pool Size"; Risk = "High"; Category = "Memory"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Key = "NonPagedPoolSize"; ValueOn = 0; ValueOff = 0; Description = "System managed pool size" },
    @{ Id = "SecondLevel"; Name = "L2 Cache Size"; Risk = "Medium"; Category = "Memory"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Key = "SecondLevelDataCache"; ValueOn = 0; ValueOff = 0; Description = "Auto-detect L2 cache" },
    
    # === GAMING EXTRAS ===
    @{ Id = "GpuPrio"; Name = "GPU Priority"; Risk = "Medium"; Category = "Gaming"; Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"; Key = "GPU Priority"; ValueOn = 8; ValueOff = 8; Description = "High GPU priority" },
    @{ Id = "GamesPrio"; Name = "Games Scheduling"; Risk = "Medium"; Category = "Gaming"; Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"; Key = "Priority"; ValueOn = 6; ValueOff = 2; Description = "High CPU priority for games" },
    @{ Id = "GamesSched"; Name = "Games Category"; Risk = "Medium"; Category = "Gaming"; Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"; Key = "Scheduling Category"; ValueOn = "High"; ValueOff = "Medium"; Description = "High scheduling category" },
    
    # === PRIVACY EXTENSIONS ===
    @{ Id = "ExpBandwidth"; Name = "Experience Bandwidth"; Risk = "Low"; Category = "Privacy"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Key = "RestrictTelemetry"; ValueOn = 0; ValueOff = 0; Description = "Restrict extra telemetry" },
    @{ Id = "AppTrack"; Name = "Disable App Tracking"; Risk = "Low"; Category = "Privacy"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\EdgeUI"; Key = "DisableMFUTracking"; ValueOn = 1; ValueOff = 0; Description = "Disable most frequently used apps" },
    @{ Id = "Teredo"; Name = "Disable Teredo"; Risk = "Low"; Category = "Network"; CommandOn = "netsh interface teredo set state disabled"; CommandOff = "netsh interface teredo set state default"; Description = "Disable Teredo tunneling" },
    @{ Id = "ISATAP"; Name = "Disable ISATAP"; Risk = "Low"; Category = "Network"; CommandOn = "netsh interface isatap set state disabled"; CommandOff = "netsh interface isatap set state default"; Description = "Disable ISATAP tunneling" },
    
    # === LENOVO-SPECIFIC TWEAKS ===
    # These are only applied on Lenovo systems (condition checked at runtime)
    @{ Id = "LenovoHybrid"; Name = "Lenovo Hybrid Mode (dGPU)"; Risk = "Medium"; Category = "Lenovo"; ConditionScript = "Test-LenovoSystem"; WmiSetting = "HybridMode"; WmiValueOn = "Disable"; WmiValueOff = "Enable"; Description = "Force dedicated GPU for gaming" },
    @{ Id = "LenovoPerf"; Name = "Lenovo Max Performance"; Risk = "Low"; Category = "Lenovo"; ConditionScript = "Test-LenovoSystem"; WmiSetting = "AdaptiveThermalManagementAC"; WmiValueOn = "MaximizePerformance"; WmiValueOff = "Balanced"; Description = "Maximum thermal on AC" },
    @{ Id = "LenovoOverDrive"; Name = "Lenovo LCD OverDrive"; Risk = "Low"; Category = "Lenovo"; ConditionScript = "Test-LenovoSystem"; WmiSetting = "OverDriveMode"; WmiValueOn = "Enable"; WmiValueOff = "Disable"; Description = "Faster LCD response time" },
    @{ Id = "LenovoGPUOC"; Name = "Lenovo GPU Overclock"; Risk = "Medium"; Category = "Lenovo"; ConditionScript = "Test-LenovoSystem"; WmiSetting = "GPUOverclock"; WmiValueOn = "Enable"; WmiValueOff = "Disable"; Description = "Enable GPU boost mode" },
    @{ Id = "LenovoCharge"; Name = "Lenovo Battery Conservation"; Risk = "Low"; Category = "Lenovo"; ConditionScript = "Test-LenovoSystem"; WmiSetting = "BatteryConservationMode"; WmiValueOn = "Enable"; WmiValueOff = "Disable"; Description = "Limit charge to 60% for longevity" }
)

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
    param([string]$RiskLevel = "Low")
    $actions = @()
    foreach ($tweak in $Script:TweakLibrary) {
        if ($RiskLevel -eq "All" -or $tweak.Risk -eq $RiskLevel -or ($RiskLevel -eq "Medium" -and $tweak.Risk -eq "Low")) {
            $actions += $tweak.Id
        }
    }
    return $actions
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
            if (-not (Test-Path $tweak.Path)) { New-Item -Path $tweak.Path -Force | Out-Null }
            Set-ItemProperty -Path $tweak.Path -Name $tweak.Key -Value $value -Force
            return $true
        }
        elseif ($command) {
            # Command-based tweak
            Invoke-Expression $command 2>&1 | Out-Null
            return $true
        }
        return $false
    }
    catch { Write-Host "   [!] Failed: $_" -ForegroundColor Red; return $false }
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
    
    $availableActions = Get-AvailableActions -RiskLevel "Low"
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
            $tweakObj = $Script:TweakLibrary | Where-Object { $_.Id -eq $_.Name }
            $recommendations += [PSCustomObject]@{
                TweakId     = $_.Name
                Name        = if ($tweakObj) { $tweakObj.Name } else { $_.Name }
                Category    = if ($tweakObj) { $tweakObj.Category } else { "Unknown" }
                QValue      = [math]::Round($_.Value, 3)
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
    
    $config = Get-NeuralConfig
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
        
        # 4. Action Selection
        $state = Get-CurrentState -Hardware $hardware -Workload "AutoPilot"
        $action = Get-BestAction -QTable $qTable -State $state -AvailableActions $Script:TweakLibrary.Id -Epsilon $epsilon
        
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
                Update-QValue -QTable $qTable -State $state -Action $action -Reward $reward -NewState $newState -AvailableActions $Script:TweakLibrary.Id
                
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
    'Invoke-NeuralLearning',
    'Get-NeuralRecommendation', 
    'Get-NeuralBrain',
    'Measure-SystemMetrics',
    'Get-BestTweaksForState',
    'Get-QTable',
    'Invoke-ExploratoryTweak',
    'Get-SystemLoadState',
    'Update-PersistenceRewards',
    'Set-UserFeedback',
    'Start-NeuralAutoPilot'
)

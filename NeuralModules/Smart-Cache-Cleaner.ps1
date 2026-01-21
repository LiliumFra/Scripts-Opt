<#
.SYNOPSIS
    Smart-Cache-Cleaner.ps1 - AI-Powered Cache Optimization v7.0

.DESCRIPTION
    Advanced cache cleaning with AI prioritization:
    - Priority scoring based on size, context, and history
    - Performance impact measurement (before/after score)
    - Multi-user support
    - Deep system logs cleanup
    - Gaming/Work context detection
    - NEW: Automatic mode with idle detection
    - NEW: Silent mode for scheduled tasks

.PARAMETER Auto
    Run in automatic mode (no prompts, uses smart defaults)

.PARAMETER Silent
    Suppress all output (for Task Scheduler)

.PARAMETER IdleThreshold
    Minutes of CPU < 10% before auto-clean triggers (default: 5)

.NOTES
    Part of Windows Neural Optimizer v7.0
    Author: Jose Bustamante
#>

param(
    [switch]$Auto,
    [switch]$Silent,
    [int]$IdleThreshold = 5,
    [switch]$WhatIf
)

$Script:ScriptDir = Split-Path $MyInvocation.MyCommand.Path
$Script:AutoMode = $Auto.IsPresent
$Script:SilentMode = $Silent.IsPresent

if (-not (Get-Command "Write-Log" -ErrorAction SilentlyContinue)) {
    $utilsPath = Join-Path $Script:ScriptDir "NeuralUtils.psm1"
    if (Test-Path $utilsPath) { Import-Module $utilsPath -Force -DisableNameChecking }
}

$aiModulePath = Join-Path $Script:ScriptDir "NeuralAI.psm1"
if (Test-Path $aiModulePath) { Import-Module $aiModulePath -Force -DisableNameChecking }

if (-not $Script:SilentMode) { Invoke-AdminCheck -Silent }

# ============================================================================
# IDLE DETECTION & AUTOMATIC MODE
# ============================================================================

function Get-SystemIdleTime {
    <#
    .SYNOPSIS
        Returns system idle time in minutes based on CPU usage
    #>
    try {
        $samples = @()
        for ($i = 0; $i -lt 3; $i++) {
            $cpu = (Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor -Filter "Name='_Total'" -ErrorAction SilentlyContinue).PercentProcessorTime
            $samples += $cpu
            Start-Sleep -Seconds 1
        }
        $avgCpu = ($samples | Measure-Object -Average).Average
        
        # If CPU < 10%, consider system idle
        if ($avgCpu -lt 10) {
            return [math]::Round((Get-Date - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime).TotalMinutes % 60, 0)
        }
        return 0
    }
    catch { return 0 }
}

function Test-SystemIdle {
    param([int]$ThresholdMinutes = 5)
    
    try {
        $cpu = (Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor -Filter "Name='_Total'" -ErrorAction SilentlyContinue).PercentProcessorTime
        $disk = (Get-CimInstance Win32_PerfFormattedData_PerfDisk_PhysicalDisk -Filter "Name='_Total'" -ErrorAction SilentlyContinue).PercentDiskTime
        
        return ($cpu -lt 15 -and $disk -lt 20)
    }
    catch { return $false }
}

function Invoke-SilentCacheClean {
    <#
    .SYNOPSIS
        Performs silent cache cleanup for automatic/scheduled execution
    .DESCRIPTION
        - No prompts or user interaction
        - Cleans high-priority caches only
        - Logs results to JSON for dashboard
    #>
    param([switch]$HighPriorityOnly)
    
    $results = @{
        Timestamp = (Get-Date).ToString("o")
        Mode      = "Silent"
        FreedMB   = 0
        Locations = 0
        Status    = "Started"
    }
    
    try {

        $locations = Get-NeuralCacheLocations
        $cleanupResults = @()
        
        foreach ($loc in $locations) {
            $paths = @($loc.Path)
            foreach ($path in $paths) {
                if (Test-Path $path) {
                    # Skip if process is running
                    if ($loc.Proc) {
                        $proc = Get-Process -Name $loc.Proc -ErrorAction SilentlyContinue
                        if ($proc) { continue }
                    }
                    
                    try {
                        $before = (Get-ChildItem -Path $path -Recurse -File -Force -ErrorAction SilentlyContinue | 
                            Measure-Object -Property Length -Sum).Sum
                        
                        if ($before -gt 10MB) {
                            # Only clean if > 10MB
                            Remove-Item -Path "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
                            $freedMB = [math]::Round($before / 1MB, 2)
                            $cleanupResults += [PSCustomObject]@{ Name = $loc.Name; FreedMB = $freedMB }
                            $results.Locations++
                        }
                    }
                    catch { }
                }
            }
        }
        
        $results.FreedMB = [math]::Round(($cleanupResults | Measure-Object -Property FreedMB -Sum).Sum, 2)
        $results.Status = "Completed"
        
        # Update history
        if ($cleanupResults.Count -gt 0) {
            Update-CleanupHistory -CleanupResults $cleanupResults
        }
    }
    catch {
        $results.Status = "Error: $_"
    }
    
    # Save results for dashboard
    $resultsPath = Join-Path (Split-Path $Script:ScriptDir -Parent) "LastCacheClean.json"
    $results | ConvertTo-Json | Set-Content $resultsPath -Force -ErrorAction SilentlyContinue
    
    return $results
}

function Start-NeuralCacheService {
    <#
    .SYNOPSIS
        Starts automatic cache cleaning service
    .DESCRIPTION
        Monitors system for idle state and triggers cleanup
    #>
    param(
        [switch]$RunOnce,
        [int]$IdleMinutes = 5,
        [int]$CheckIntervalSeconds = 60
    )
    
    if ($RunOnce) {
        if (Test-SystemIdle -ThresholdMinutes $IdleMinutes) {
            return Invoke-SilentCacheClean
        }
        return @{ Status = "System not idle" }
    }
    
    # Continuous monitoring mode
    while ($true) {
        if (Test-SystemIdle -ThresholdMinutes $IdleMinutes) {
            Invoke-SilentCacheClean
            Start-Sleep -Seconds 3600  # Wait 1 hour after cleanup
        }
        Start-Sleep -Seconds $CheckIntervalSeconds
    }
}

# ============================================================================
# AI CONFIGURATION
# ============================================================================

$Script:CacheHistoryPath = Join-Path (Split-Path $Script:ScriptDir -Parent) "CacheHistory.json"
$Script:MLDataPath = Join-Path $env:LOCALAPPDATA "NeuralOptimizer\ML"
$Script:PatternsFile = Join-Path $Script:MLDataPath "learned_patterns.json"

function Get-CacheHistory {
    if (Test-Path $Script:CacheHistoryPath) {
        try { return Get-Content $Script:CacheHistoryPath -Raw | ConvertFrom-Json }
        catch { return @{ Cleanups = @(); Stats = @{} } }
    }
    return @{ Cleanups = @(); Stats = @{} }
}

function Save-CacheHistory {
    param($History)
    $History | ConvertTo-Json -Depth 5 | Set-Content $Script:CacheHistoryPath -Force
}

function Get-UsageContext {
    $hour = (Get-Date).Hour
    $dayOfWeek = (Get-Date).DayOfWeek
    $isWeekend = $dayOfWeek -in @("Saturday", "Sunday")
    
    $context = @{
        Hour                 = $hour
        IsWeekend            = $isWeekend
        TimeSlot             = if ($hour -ge 18 -or $hour -lt 6) { "Gaming" } elseif ($hour -ge 9 -and $hour -lt 17) { "Work" } else { "Mixed" }
        DeepCleanRecommended = $isWeekend -or $hour -ge 22 -or $hour -lt 6
    }
    
    return $context
}

function Get-CachePriority {
    param($CacheInfo, $Context, $History)
    
    $baseScore = $CacheInfo.SizeMB * 2
    
    # Category bonus based on usage context
    $categoryBonus = switch ($CacheInfo.Category) {
        "Gaming" { if ($Context.TimeSlot -eq "Gaming") { 15 } else { 5 } }
        "Browser" { if ($Context.TimeSlot -eq "Work") { 15 } else { 8 } }
        "System" { if ($Context.DeepCleanRecommended) { 20 } else { 10 } }
        "Apps" { 10 }
        default { 5 }
    }
    
    # Historical effectiveness bonus
    $historyBonus = 0
    if ($History.Stats -and $History.Stats.$($CacheInfo.Name)) {
        $stats = $History.Stats.$($CacheInfo.Name)
        if ($stats.AvgFreedMB -gt 100) { $historyBonus = 10 }
        elseif ($stats.AvgFreedMB -gt 50) { $historyBonus = 5 }
    }
    
    return [math]::Round($baseScore + $categoryBonus + $historyBonus, 1)
}

function Update-CleanupHistory {
    param($CleanupResults)
    
    $history = Get-CacheHistory
    
    # Add this cleanup session
    $session = @{
        Timestamp    = (Get-Date).ToString("o")
        TotalFreedMB = ($CleanupResults | Measure-Object -Property FreedMB -Sum).Sum
        Locations    = $CleanupResults.Count
    }
    
    if (-not $history.Cleanups) { $history.Cleanups = @() }
    $history.Cleanups += $session
    if ($history.Cleanups.Count -gt 100) { $history.Cleanups = $history.Cleanups | Select-Object -Last 100 }
    
    # Update per-location stats
    if (-not $history.Stats) { $history.Stats = @{} }
    foreach ($result in $CleanupResults) {
        $name = $result.Name
        if (-not $history.Stats.$name) {
            $history.Stats.$name = @{ CleanCount = 0; TotalFreedMB = 0; AvgFreedMB = 0 }
        }
        $history.Stats.$name.CleanCount++
        $history.Stats.$name.TotalFreedMB += $result.FreedMB
        $history.Stats.$name.AvgFreedMB = [math]::Round($history.Stats.$name.TotalFreedMB / $history.Stats.$name.CleanCount, 2)
    }
    
    Save-CacheHistory -History $history
    return $history
}

function Get-SystemScoreQuick {
    # Fast score calculation with timeout protection
    try {
        # Use CIM instead of Get-Counter (faster, no locale issues)
        $proc = Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor -Filter "Name='_Total'" -ErrorAction SilentlyContinue -OperationTimeoutSec 3
        $cpu = if ($proc) { $proc.PercentProcessorTime } else { 50 }
        
        $mem = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue -OperationTimeoutSec 3
        $memPct = if ($mem) { [math]::Round(($mem.FreePhysicalMemory / $mem.TotalVisibleMemorySize) * 100, 1) } else { 50 }
        
        return [math]::Round((100 - $cpu) * 0.5 + $memPct * 0.5, 1)
    }
    catch { return 50 }
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Get-AllUserProfiles {
    return Get-ChildItem "C:\Users" -Directory | Where-Object { $_.Name -notmatch "Public|Default|All Users" }
}

function Invoke-ServiceControl {
    param([string[]]$Services, [string]$Action)
    $timeout = 5 # seconds per service
    
    foreach ($s in $Services) {
        try {
            $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
            if (-not $svc) { continue }
            
            if ($Action -eq "Stop") {
                # Non-blocking stop with timeout
                $job = Start-Job -ScriptBlock { param($name) Stop-Service -Name $name -Force -ErrorAction SilentlyContinue } -ArgumentList $s
                $null = Wait-Job $job -Timeout $timeout
                Remove-Job $job -Force -ErrorAction SilentlyContinue
            }
            else {
                # Non-blocking start with timeout
                $job = Start-Job -ScriptBlock { param($name) Start-Service -Name $name -ErrorAction SilentlyContinue } -ArgumentList $s
                $null = Wait-Job $job -Timeout $timeout
                Remove-Job $job -Force -ErrorAction SilentlyContinue
            }
        }
        catch {
            # Service control failed, continue silently
        }
    }
}

# ============================================================================
# CACHE LOCATIONS
# ============================================================================

function Get-NeuralCacheLocations {
    $locs = @()
    $userProfiles = Get-AllUserProfiles
    
    # SYSTEM
    $locs += @(
        @{ Cat = "System"; Name = "Windows Temp"; Path = "$env:SystemRoot\Temp" },
        @{ Cat = "System"; Name = "Windows Prefetch"; Path = "$env:SystemRoot\Prefetch" },
        @{ Cat = "System"; Name = "SoftwareDistribution"; Path = "$env:SystemRoot\SoftwareDistribution\Download"; Svc = @("wuauserv", "bits") },
        @{ Cat = "System"; Name = "CBS Logs"; Path = "$env:SystemRoot\Logs\CBS" },
        @{ Cat = "System"; Name = "DISM Logs"; Path = "$env:SystemRoot\Logs\DISM" },
        @{ Cat = "System"; Name = "Delivery Optimization"; Path = "$env:SystemRoot\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization"; Svc = @("DoSvc") },
        @{ Cat = "System"; Name = "Windows Error Reporting"; Path = "C:\ProgramData\Microsoft\Windows\WER" }
    )
    
    # BROWSERS (Multi-User)
    foreach ($user in $userProfiles) {
        $userPath = $user.FullName
        $locs += @(
            @{ Cat = "Browser"; Name = "Chrome ($($user.Name))"; Path = "$userPath\AppData\Local\Google\Chrome\User Data\Default\Cache"; Proc = "chrome" },
            @{ Cat = "Browser"; Name = "Edge ($($user.Name))"; Path = "$userPath\AppData\Local\Microsoft\Edge\User Data\Default\Cache"; Proc = "msedge" },
            @{ Cat = "Browser"; Name = "Brave ($($user.Name))"; Path = "$userPath\AppData\Local\BraveSoftware\Brave-Browser\User Data\Default\Cache"; Proc = "brave" },
            @{ Cat = "Browser"; Name = "User Temp ($($user.Name))"; Path = "$userPath\AppData\Local\Temp" }
        )
    }
    
    # GAMING
    $locs += @(
        @{ Cat = "Gaming"; Name = "DirectX Shader Cache"; Path = "$env:LOCALAPPDATA\D3DSCache" },
        @{ Cat = "Gaming"; Name = "NVIDIA Shaders"; Path = "$env:LOCALAPPDATA\NVIDIA\DXCache" },
        @{ Cat = "Gaming"; Name = "NVIDIA GL Cache"; Path = "$env:LOCALAPPDATA\NVIDIA\GLCache" },
        @{ Cat = "Gaming"; Name = "AMD Shaders"; Path = "$env:LOCALAPPDATA\AMD\DxCache" },
        @{ Cat = "Gaming"; Name = "Intel Shaders"; Path = "$env:LOCALAPPDATA\Intel\ShaderCache" },
        @{ Cat = "Gaming"; Name = "Steam HTML Cache"; Path = "$env:LOCALAPPDATA\Steam\htmlcache"; Proc = "steam" },
        @{ Cat = "Gaming"; Name = "Epic Games Cache"; Path = "$env:LOCALAPPDATA\EpicGamesLauncher\Saved\webcache"; Proc = "EpicGamesLauncher" }
    )
    
    # APPS
    foreach ($user in $userProfiles) {
        $userApp = "$($user.FullName)\AppData"
        $locs += @(
            @{ Cat = "Apps"; Name = "Discord ($($user.Name))"; Path = "$userApp\Roaming\discord\Cache"; Proc = "discord" },
            @{ Cat = "Apps"; Name = "Spotify ($($user.Name))"; Path = "$userApp\Local\Spotify\Storage"; Proc = "spotify" },
            @{ Cat = "Apps"; Name = "VS Code ($($user.Name))"; Path = "$userApp\Roaming\Code\Cache"; Proc = "Code" }
        )
    }
    
    return $locs
}

# ============================================================================
# MODERN UI & MENU SYSTEM
# ============================================================================

$Script:Settings = @{
    DeepClean = $false # DISM/CBS default OFF
}

function Show-CacheMenu {
    Clear-Host
    Write-Host ""
    Write-Host " ╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host " ║                   🚀 NEURAL SMART CACHE v7.2                       ║" -ForegroundColor White
    Write-Host " ╠════════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    
    # Status Indicators
    $deepCleanState = "OFF"
    $deepCleanColor = "Yellow"
    if ($Script:Settings.DeepClean) { 
        $deepCleanState = "ON "
        $deepCleanColor = "Red"
    }

    Write-Host " ║  STATUS: " -NoNewline -ForegroundColor Gray
    Write-Host "Deep Clean [$deepCleanState] " -NoNewline -ForegroundColor $deepCleanColor
    Write-Host "                                           ║" -ForegroundColor Cyan
    Write-Host " ╠════════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host " ║                                                                    ║" -ForegroundColor Cyan
    Write-Host " ║  [1]  ⚡ START SMART SCAN    (Browsers, Temp, App Cache)           ║" -ForegroundColor Green
    Write-Host " ║  [2]  ⚙️  TOGGLE DEEP CLEAN   (DISM, WinSxS - Slow)                 ║" -ForegroundColor White
    Write-Host " ║  [3]  🛡️  FORCE CLEAN SYSTEM  (Direct Clean, No Scan)               ║" -ForegroundColor Magenta
    Write-Host " ║                                                                    ║" -ForegroundColor Cyan
    Write-Host " ║  [0]  🔙 EXIT                                                      ║" -ForegroundColor DarkGray
    Write-Host " ║                                                                    ║" -ForegroundColor Cyan
    Write-Host " ╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    return Read-Host " >> Select Option"
}

function Invoke-NeuralCacheScan {
    $context = Get-UsageContext
    $history = Get-CacheHistory
    
    Write-Host ""
    Write-Host " === NEURAL CACHE ENGINE INITIALIZED ===" -ForegroundColor Cyan
    Write-Host " Context: $($context.TimeSlot)" -ForegroundColor Gray
    if ($Script:Settings.DeepClean) {
        Write-Host " [!] DEEP CLEAN MODE: ACTIVE (Expect longer scan times)" -ForegroundColor Yellow
    }
    Write-Host ""
    
    # Measure baseline score
    Write-Host " [+] Measuring baseline performance..." -ForegroundColor DarkGray
    $baselineScore = Get-SystemScoreQuick
    Write-Host " Baseline Score: $baselineScore" -ForegroundColor Gray
    Write-Host ""
    
    $locations = Get-NeuralCacheLocations
    $scanResults = @()
    
    Write-Host " Scanning locations..." -ForegroundColor Cyan
    
    $scanTimeout = 10 # seconds per location

    
    foreach ($loc in $locations) {
        # SKIP Deep Clean locations if invalid
        if ($loc.Cat -eq "System" -and ($loc.Name -match "DISM|CBS|WinSxS") -and (-not $Script:Settings.DeepClean)) {
            continue
        }

        $pathsArr = @($loc.Path)
        foreach ($pStr in $pathsArr) {
            if (Test-Path $pStr) {
                Write-Host " [Scan] $($loc.Name)..." -NoNewline -ForegroundColor DarkGray
                
                # Use job with timeout to prevent hanging on unresponsive paths
                $job = Start-Job -ScriptBlock {
                    param($path)
                    try {
                        Get-ChildItem -Path $path -Recurse -File -Force -ErrorAction SilentlyContinue | 
                        Measure-Object -Property Length -Sum
                    }
                    catch { $null }
                } -ArgumentList $pStr
                
                $completed = Wait-Job $job -Timeout $scanTimeout
                
                if ($completed) {
                    $measure = Receive-Job $job -ErrorAction SilentlyContinue
                    Remove-Job $job -Force -ErrorAction SilentlyContinue
                    
                    if ($measure -and $measure.Count -gt 0) {
                        $sizeMB = [math]::Round($measure.Sum / 1MB, 2)
                        $cacheInfo = @{ Name = $loc.Name; Category = $loc.Cat; SizeMB = $sizeMB }
                        $priority = Get-CachePriority -CacheInfo $cacheInfo -Context $context -History $history
                        
                        $scanResults += [PSCustomObject]@{
                            Name     = $loc.Name
                            Path     = $pStr
                            SizeMB   = $sizeMB
                            Files    = $measure.Count
                            Category = $loc.Cat
                            Priority = $priority
                            Services = $loc.Svc
                            Process  = $loc.Proc
                        }
                        Write-Host " $sizeMB MB" -ForegroundColor Gray
                    }
                    else {
                        Write-Host " (Clean)" -ForegroundColor DarkGray
                    }
                }
                else {
                    Stop-Job $job -ErrorAction SilentlyContinue
                    Remove-Job $job -Force -ErrorAction SilentlyContinue
                    Write-Host " [SKIP]" -ForegroundColor Yellow
                }
            }
        }
    }
    
    # Sort by AI priority
    $scanResults = $scanResults | Sort-Object Priority -Descending
    
    # Display results
    $totalSize = ($scanResults | Measure-Object -Property SizeMB -Sum).Sum
    $totalFiles = ($scanResults | Measure-Object -Property Files -Sum).Sum
    
    Write-Host ""
    Write-Host " ═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  SCAN RESULTS" -ForegroundColor White
    Write-Host " ═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    $i = 1
    foreach ($res in $scanResults | Select-Object -First 15) {
        $priorityColor = if ($res.Priority -gt 30) { "Green" } elseif ($res.Priority -gt 15) { "Yellow" } else { "Gray" }
        Write-Host " $i. [$($res.Category.PadRight(7))] $($res.Name.PadRight(30)) $($res.SizeMB.ToString().PadLeft(8)) MB  [P:$($res.Priority)]" -ForegroundColor $priorityColor
        $i++
    }
    
    Write-Host ""
    Write-Host " Total Junk: $([math]::Round($totalSize, 2)) MB in $totalFiles files" -ForegroundColor Magenta
    Write-Host ""
    
    if ($totalFiles -gt 0) {
        Write-Host " [1] Smart Clean (High Priority)" -ForegroundColor Green
        Write-Host " [2] Clean All" -ForegroundColor Yellow
        Write-Host " [0] Cancel" -ForegroundColor Gray
        Write-Host ""
        $choice = Read-Host " >> Action"
        
        switch ($choice) {
            '1' { Invoke-SmartCleanup -Results ($scanResults | Where-Object { $_.Priority -gt 20 }) -BaselineScore $baselineScore }
            '2' { Invoke-SmartCleanup -Results $scanResults -BaselineScore $baselineScore }
            default { return }
        }
    }
    else {
        Write-Host " System is clean! No action needed." -ForegroundColor Green
        Wait-ForKeyPress
    }
}

# ============================================================================
# MAIN
# ============================================================================

# Handle automatic mode
if ($Script:AutoMode) {
    if ($Script:SilentMode) {
        $result = Invoke-SilentCacheClean
        exit 0
    }
    else {
        Write-Host ""
        Write-Host " === NEURAL CACHE v7.2 (AUTO) ===" -ForegroundColor Cyan
        $result = Invoke-SilentCacheClean
        Write-Host " Freed: $($result.FreedMB) MB" -ForegroundColor Green
        exit 0
    }
}

# Interactive Menu Loop
while ($true) {
    $sel = Show-CacheMenu
    
    switch ($sel) {
        '1' { Invoke-NeuralCacheScan; Wait-ForKeyPress }
        '2' { 
            $Script:Settings.DeepClean = -not $Script:Settings.DeepClean 
            # Toggle logic implies refresh of loop
        }
        '3' { 
            # Force Clean Logic
            Write-Host " [!] Force Cleaning..." -ForegroundColor Yellow
            $locs = Get-NeuralCacheLocations
            # Filter logic for deep clean
            $toClean = $locs | Where-Object { 
                if ($_.Cat -eq "System" -and ($_.Name -match "DISM|CBS") -and (-not $Script:Settings.DeepClean)) { $false } else { $true }
            }
            # Simplified force clean without measurement
            foreach ($l in $toClean) {
                Write-Host " Cleaning $($l.Name)..." -ForegroundColor DarkGray
                Remove-Item "$($l.Path)\*" -Recurse -Force -ErrorAction SilentlyContinue
            }
            Write-Host " [OK] Force Clean Complete" -ForegroundColor Green
            Wait-ForKeyPress
        }
        '0' { exit }
        default { }
    }
}

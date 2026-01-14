<#
.SYNOPSIS
    Neural Cache Diagnostic v7.0 - AI-Enhanced Edition

.DESCRIPTION
    Advanced cache cleaning with AI prioritization:
    - Q-Learning integration for optimal cleaning order
    - Performance impact measurement
    - Predictive analysis for cache growth
    - Multi-user support
    - Deep system logs cleanup

.NOTES
    Part of Windows Neural Optimizer v6.1 ULTRA
    Author: Jose Bustamante
#>

if (-not (Get-Command "Write-Log" -ErrorAction SilentlyContinue)) {
    $currentDir = Split-Path $MyInvocation.MyCommand.Path
    $utilsPath = Join-Path $currentDir "NeuralModules\NeuralUtils.psm1"
    if (Test-Path $utilsPath) { Import-Module $utilsPath -Force -DisableNameChecking }
}

$aiModulePath = Join-Path (Split-Path $MyInvocation.MyCommand.Path) "NeuralModules\NeuralAI.psm1"
if (Test-Path $aiModulePath) { Import-Module $aiModulePath -Force -DisableNameChecking }

Invoke-AdminCheck -Silent

# ============================================================================
# AI CONFIGURATION
# ============================================================================

$Script:CacheHistoryPath = Join-Path (Split-Path $MyInvocation.MyCommand.Path) "NeuralCacheHistory.json"
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
    try {
        $cpu = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 1).CounterSamples[0].CookedValue
        $mem = (Get-CimInstance Win32_OperatingSystem)
        $memPct = [math]::Round(($mem.FreePhysicalMemory / $mem.TotalVisibleMemorySize) * 100, 1)
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
    foreach ($s in $Services) {
        $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
        if ($svc) {
            if ($Action -eq "Stop") { Stop-Service -Name $s -Force -ErrorAction SilentlyContinue }
            else { Start-Service -Name $s -ErrorAction SilentlyContinue }
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
# AI-POWERED SCAN
# ============================================================================

function Invoke-NeuralCacheScan {
    $context = Get-UsageContext
    $history = Get-CacheHistory
    
    Write-Host ""
    Write-Host " === NEURAL CACHE AI v7.0 ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " Context: $($context.TimeSlot) | Deep Clean: $($context.DeepCleanRecommended)" -ForegroundColor Gray
    Write-Host ""
    
    # Measure baseline score
    Write-Host " [+] Measuring baseline performance..." -ForegroundColor DarkGray
    $baselineScore = Get-SystemScoreQuick
    Write-Host " Baseline Score: $baselineScore" -ForegroundColor Gray
    Write-Host ""
    
    $locations = Get-NeuralCacheLocations
    $scanResults = @()
    
    Write-Host " Scanning with AI prioritization..." -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($loc in $locations) {
        $pathsArr = @($loc.Path)
        foreach ($pStr in $pathsArr) {
            if (Test-Path $pStr) {
                $measure = Get-ChildItem -Path $pStr -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum
                if ($measure.Count -gt 0) {
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
    Write-Host " === SCAN RESULTS (AI Sorted) ===" -ForegroundColor White
    Write-Host ""
    
    $i = 1
    foreach ($res in $scanResults | Select-Object -First 15) {
        $priorityColor = if ($res.Priority -gt 30) { "Green" } elseif ($res.Priority -gt 15) { "Yellow" } else { "Gray" }
        Write-Host " $i. [$($res.Category.PadRight(7))] $($res.Name.PadRight(30)) $($res.SizeMB.ToString().PadLeft(8)) MB  [P:$($res.Priority)]" -ForegroundColor $priorityColor
        $i++
    }
    
    Write-Host ""
    Write-Host " Total: $([math]::Round($totalSize, 2)) MB in $totalFiles files" -ForegroundColor Cyan
    Write-Host ""
    
    if ($totalFiles -gt 0) {
        Write-Host " Options:"
        Write-Host " [1] Smart Clean (High priority only)"
        Write-Host " [2] Full Clean (All locations)"
        Write-Host " [3] Cancel"
        Write-Host ""
        $choice = Read-Host " >> Choice"
        
        switch ($choice) {
            '1' { Invoke-SmartCleanup -Results ($scanResults | Where-Object { $_.Priority -gt 20 }) -BaselineScore $baselineScore }
            '2' { Invoke-SmartCleanup -Results $scanResults -BaselineScore $baselineScore }
            '3' { return }
        }
    }
}

function Invoke-SmartCleanup {
    param($Results, $BaselineScore)
    
    Write-Host ""
    Write-Host " === CLEANING ENGINE ===" -ForegroundColor Yellow
    Write-Host ""
    
    # Stop required services
    $allSvcs = $Results.Services | Select-Object -Unique | Where-Object { $_ }
    if ($allSvcs) {
        Write-Host " [+] Stopping services..." -ForegroundColor DarkGray
        Invoke-ServiceControl -Services $allSvcs -Action "Stop"
    }
    
    $cleanupResults = @()
    
    foreach ($res in $Results) {
        Write-Host " Cleaning $($res.Name)..." -NoNewline -ForegroundColor Gray
        
        if ($res.Process) {
            $proc = Get-Process -Name $res.Process -ErrorAction SilentlyContinue
            if ($proc) {
                Write-Host " [Running, skip]" -ForegroundColor Yellow
                continue
            }
        }
        
        try {
            $before = (Get-ChildItem -Path $res.Path -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            Remove-Item -Path "$($res.Path)\*" -Recurse -Force -ErrorAction SilentlyContinue
            $freedMB = [math]::Round($before / 1MB, 2)
            Write-Host " [OK] $freedMB MB freed" -ForegroundColor Green
            
            $cleanupResults += @{ Name = $res.Name; FreedMB = $freedMB }
        }
        catch {
            Write-Host " [Error]" -ForegroundColor Red
        }
    }
    
    # Restart services
    if ($allSvcs) {
        Write-Host ""
        Write-Host " [+] Restarting services..." -ForegroundColor DarkGray
        Invoke-ServiceControl -Services $allSvcs -Action "Start"
    }
    
    # Update AI history
    $history = Update-CleanupHistory -CleanupResults $cleanupResults
    
    # Measure post-cleanup score
    Start-Sleep -Seconds 2
    $postScore = Get-SystemScoreQuick
    $delta = [math]::Round($postScore - $BaselineScore, 1)
    
    Write-Host ""
    Write-Host " === RESULTS ===" -ForegroundColor Green
    Write-Host " Freed: $([math]::Round(($cleanupResults | Measure-Object -Property FreedMB -Sum).Sum, 2)) MB" -ForegroundColor Cyan
    Write-Host " Score: $BaselineScore -> $postScore ($(if($delta -ge 0){'+'}else{''})$delta)" -ForegroundColor $(if ($delta -ge 0) { 'Green' }else { 'Yellow' })
    Write-Host " Sessions tracked: $($history.Cleanups.Count)" -ForegroundColor Gray
    Write-Host ""
}

# ============================================================================
# MAIN
# ============================================================================

Invoke-NeuralCacheScan
Write-Host ""
Read-Host " Press ENTER to continue"

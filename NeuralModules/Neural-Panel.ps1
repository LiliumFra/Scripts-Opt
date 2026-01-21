<#
.SYNOPSIS
    Neural-Panel.ps1 - Modern Unified Dashboard v7.0

.DESCRIPTION
    All-in-one control panel for Windows Neural Optimizer:
    - Real-time system metrics
    - AI status and recommendations
    - Quick actions with single keypress
    - All modules accessible from one view

.NOTES
    Part of Windows Neural Optimizer v7.0
    Author: Jose Bustamante
#>

param([switch]$TestMode)

$Script:ScriptDir = Split-Path $MyInvocation.MyCommand.Path

# Import modules
$utilsPath = Join-Path $Script:ScriptDir "NeuralUtils.psm1"
$aiPath = Join-Path $Script:ScriptDir "NeuralAI.psm1"
$schedulerPath = Join-Path $Script:ScriptDir "NeuralScheduler.psm1"

if (Test-Path $utilsPath) { Import-Module $utilsPath -Force -DisableNameChecking }
if (Test-Path $aiPath) { Import-Module $aiPath -Force -DisableNameChecking }
if (Test-Path $schedulerPath) { Import-Module $schedulerPath -Force -DisableNameChecking }

# ============================================================================
# REAL-TIME METRICS
# ============================================================================

function Get-LiveMetrics {
    try {
        $cpu = (Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor -Filter "Name='_Total'" -OperationTimeoutSec 2).PercentProcessorTime
        $mem = Get-CimInstance Win32_OperatingSystem -OperationTimeoutSec 2
        $ramUsed = [math]::Round(($mem.TotalVisibleMemorySize - $mem.FreePhysicalMemory) / 1MB, 1)
        $ramPct = [math]::Round((1 - ($mem.FreePhysicalMemory / $mem.TotalVisibleMemorySize)) * 100, 0)
        
        $temp = 0
        try {
            $thermal = Get-CimInstance -Namespace root\WMI -ClassName MSAcpi_ThermalZoneTemperature -OperationTimeoutSec 2 -ErrorAction SilentlyContinue
            if ($thermal) { $temp = [math]::Round((($thermal.CurrentTemperature | Measure-Object -Average).Average / 10) - 273.15, 0) }
        }
        catch { }
        
        return @{
            CPU       = $cpu
            RAMPct    = $ramPct
            RAMUsedGB = $ramUsed
            Temp      = $temp
            Load      = Get-SystemLoadState
        }
    }
    catch {
        return @{ CPU = 0; RAMPct = 0; RAMUsedGB = 0; Temp = 0; Load = "Unknown" }
    }
}

function Get-AIStats {
    try {
        $config = Get-NeuralConfig
        $brain = Get-NeuralBrain
        $qTable = Get-QTable
        
        $stateCount = $qTable.Keys.Count
        $actionCount = ($qTable.Values | ForEach-Object { $_.Keys.Count } | Measure-Object -Sum).Sum
        $cycles = if ($config.LearningCycles) { $config.LearningCycles } else { 0 }
        $epsilon = if ($config.Epsilon) { [math]::Round($config.Epsilon * 100, 0) } else { 30 }
        
        $lastAction = if ($brain.History -and $brain.History.Count -gt 0) {
            $last = $brain.History | Select-Object -Last 1
            "$($last.Action) ($(if($last.Reward -gt 0){'+'}else{''})$($last.Reward))"
        }
        else { "None" }
        
        $workload = Predict-UserWorkload
        
        return @{
            States      = $stateCount
            Actions     = $actionCount
            Cycles      = $cycles
            Exploration = $epsilon
            LastAction  = $lastAction
            Workload    = $workload
            Memories    = if ($brain.History) { $brain.History.Count } else { 0 }
        }
    }
    catch {
        return @{ States = 0; Actions = 0; Cycles = 0; Exploration = 30; LastAction = "Error"; Workload = "Unknown"; Memories = 0 }
    }
}

# ============================================================================
# UI RENDERING
# ============================================================================

function Show-Panel {
    $metrics = Get-LiveMetrics
    $ai = Get-AIStats
    
    $loadColor = switch ($metrics.Load) {
        "Idle" { "Green" }
        "Light" { "Cyan" }
        "Heavy" { "Yellow" }
        "Thrashing" { "Red" }
        default { "White" }
    }
    
    $tempColor = if ($metrics.Temp -gt 80) { "Red" } elseif ($metrics.Temp -gt 60) { "Yellow" } else { "Green" }
    
    Clear-Host
    Write-Host ""
    Write-Host " ╔═══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host " ║  " -NoNewline -ForegroundColor Cyan
    Write-Host "NEURAL OPTIMIZER v7.0 ULTRA" -NoNewline -ForegroundColor White
    Write-Host "          [CPU: " -NoNewline -ForegroundColor Cyan
    Write-Host "$($metrics.CPU)%" -NoNewline -ForegroundColor $(if ($metrics.CPU -gt 80) { "Red" }elseif ($metrics.CPU -gt 50) { "Yellow" }else { "Green" })
    Write-Host "] [RAM: " -NoNewline -ForegroundColor Cyan
    Write-Host "$($metrics.RAMPct)%" -NoNewline -ForegroundColor $(if ($metrics.RAMPct -gt 80) { "Red" }elseif ($metrics.RAMPct -gt 60) { "Yellow" }else { "Green" })
    Write-Host "]   ║" -ForegroundColor Cyan
    Write-Host " ╠═══════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    
    # AI Status Section
    Write-Host " ║  " -NoNewline -ForegroundColor Cyan
    Write-Host "🧠 AI STATUS" -NoNewline -ForegroundColor Magenta
    Write-Host "                                                      ║" -ForegroundColor Cyan
    Write-Host " ║  ├─ Q-Table: " -NoNewline -ForegroundColor Cyan
    Write-Host "$($ai.States) states" -NoNewline -ForegroundColor White
    Write-Host " | " -NoNewline -ForegroundColor Gray
    Write-Host "$($ai.Actions) actions learned" -NoNewline -ForegroundColor White
    $pad1 = 67 - 28 - "$($ai.States) states".Length - "$($ai.Actions) actions learned".Length
    Write-Host (" " * [math]::Max(1, $pad1)) -NoNewline
    Write-Host "║" -ForegroundColor Cyan
    
    Write-Host " ║  ├─ Exploration: " -NoNewline -ForegroundColor Cyan
    Write-Host "$($ai.Exploration)%" -NoNewline -ForegroundColor Yellow
    Write-Host " | Cycles: " -NoNewline -ForegroundColor Gray
    Write-Host "$($ai.Cycles)" -NoNewline -ForegroundColor White
    Write-Host " | Last: " -NoNewline -ForegroundColor Gray
    $lastStr = if ($ai.LastAction.Length -gt 20) { $ai.LastAction.Substring(0, 17) + "..." } else { $ai.LastAction }
    Write-Host "$lastStr" -NoNewline -ForegroundColor Green
    $pad2 = 67 - 45 - "$($ai.Exploration)%".Length - "$($ai.Cycles)".Length - $lastStr.Length
    Write-Host (" " * [math]::Max(1, $pad2)) -NoNewline
    Write-Host "║" -ForegroundColor Cyan
    
    Write-Host " ║  └─ Workload: " -NoNewline -ForegroundColor Cyan
    Write-Host "$($ai.Workload)" -NoNewline -ForegroundColor $loadColor
    Write-Host " | Memories: " -NoNewline -ForegroundColor Gray
    Write-Host "$($ai.Memories)" -NoNewline -ForegroundColor White
    Write-Host " | Temp: " -NoNewline -ForegroundColor Gray
    Write-Host "$($metrics.Temp)°C" -NoNewline -ForegroundColor $tempColor
    $pad3 = 67 - 40 - "$($ai.Workload)".Length - "$($ai.Memories)".Length - "$($metrics.Temp)°C".Length
    Write-Host (" " * [math]::Max(1, $pad3)) -NoNewline
    Write-Host "║" -ForegroundColor Cyan
    
    Write-Host " ╠═══════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    
    # Quick Actions & Modules
    Write-Host " ║  " -NoNewline -ForegroundColor Cyan
    Write-Host "[QUICK ACTIONS]" -NoNewline -ForegroundColor Yellow
    Write-Host "                     " -NoNewline
    Write-Host "[MODULES]" -NoNewline -ForegroundColor Green
    Write-Host "                      ║" -ForegroundColor Cyan
    
    Write-Host " ║  " -NoNewline -ForegroundColor Cyan
    Write-Host "[A]" -NoNewline -ForegroundColor White
    Write-Host " Auto-Pilot (AI)" -NoNewline -ForegroundColor Gray
    Write-Host "               " -NoNewline
    Write-Host "[1]" -NoNewline -ForegroundColor White
    Write-Host " Boot Optimization           ║" -ForegroundColor Gray
    
    Write-Host " ║  " -NoNewline -ForegroundColor Cyan
    Write-Host "[L]" -NoNewline -ForegroundColor White
    Write-Host " Learn Cycle" -NoNewline -ForegroundColor Gray
    Write-Host "                  " -NoNewline
    Write-Host "[2]" -NoNewline -ForegroundColor White
    Write-Host " Debloat Suite               ║" -ForegroundColor Gray
    
    Write-Host " ║  " -NoNewline -ForegroundColor Cyan
    Write-Host "[C]" -NoNewline -ForegroundColor White
    Write-Host " Cache Clean (Auto)" -NoNewline -ForegroundColor Gray
    Write-Host "            " -NoNewline
    Write-Host "[3]" -NoNewline -ForegroundColor White
    Write-Host " Privacy Guardian            ║" -ForegroundColor Gray
    
    Write-Host " ║  " -NoNewline -ForegroundColor Cyan
    Write-Host "[S]" -NoNewline -ForegroundColor White
    Write-Host " Smart Optimize" -NoNewline -ForegroundColor Gray
    Write-Host "               " -NoNewline
    Write-Host "[4]" -NoNewline -ForegroundColor White
    Write-Host " Gaming Ultra                ║" -ForegroundColor Gray
    
    Write-Host " ║  " -NoNewline -ForegroundColor Cyan
    Write-Host "[B]" -NoNewline -ForegroundColor White
    Write-Host " Batch Learning (10x)" -NoNewline -ForegroundColor Gray
    Write-Host "          " -NoNewline
    Write-Host "[5]" -NoNewline -ForegroundColor White
    Write-Host " Network Optimizer           ║" -ForegroundColor Gray
    
    Write-Host " ║  " -NoNewline -ForegroundColor Cyan
    Write-Host "[Q]" -NoNewline -ForegroundColor White
    Write-Host " Quick Optimize (5x)" -NoNewline -ForegroundColor Gray
    Write-Host "           " -NoNewline
    Write-Host "[6]" -NoNewline -ForegroundColor White
    Write-Host " SSD/NVMe Optimizer          ║" -ForegroundColor Gray
    
    Write-Host " ║                                   " -NoNewline -ForegroundColor Cyan
    Write-Host "[7]" -NoNewline -ForegroundColor White
    Write-Host " Memory Optimizer            ║" -ForegroundColor Gray
    
    Write-Host " ║  " -NoNewline -ForegroundColor Cyan
    Write-Host "[SCHEDULER]" -NoNewline -ForegroundColor Magenta
    Write-Host "                        " -NoNewline
    Write-Host "[8]" -NoNewline -ForegroundColor White
    Write-Host " Services Manager            ║" -ForegroundColor Gray
    
    Write-Host " ║  " -NoNewline -ForegroundColor Cyan
    Write-Host "[T]" -NoNewline -ForegroundColor White
    Write-Host " Setup Auto Tasks" -NoNewline -ForegroundColor Gray
    Write-Host "              " -NoNewline
    Write-Host "[9]" -NoNewline -ForegroundColor White
    Write-Host " Visual FX                   ║" -ForegroundColor Gray
    
    Write-Host " ║  " -NoNewline -ForegroundColor Cyan
    Write-Host "[V]" -NoNewline -ForegroundColor White
    Write-Host " View Scheduled Tasks" -NoNewline -ForegroundColor Gray
    Write-Host "          " -NoNewline
    Write-Host "[0]" -NoNewline -ForegroundColor White
    Write-Host " More Modules...             ║" -ForegroundColor Gray
    
    Write-Host " ╠═══════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host " ║  " -NoNewline -ForegroundColor Cyan
    Write-Host "[R]" -NoNewline -ForegroundColor Green
    Write-Host " Reward Last" -NoNewline -ForegroundColor Gray
    Write-Host " | " -NoNewline -ForegroundColor Cyan
    Write-Host "[P]" -NoNewline -ForegroundColor Red
    Write-Host " Punish Last" -NoNewline -ForegroundColor Gray
    Write-Host " | " -NoNewline -ForegroundColor Cyan
    Write-Host "[H]" -NoNewline -ForegroundColor White
    Write-Host " History" -NoNewline -ForegroundColor Gray
    Write-Host " | " -NoNewline -ForegroundColor Cyan
    Write-Host "[X]" -NoNewline -ForegroundColor DarkGray
    Write-Host " Exit" -NoNewline -ForegroundColor Gray
    Write-Host "     ║" -ForegroundColor Cyan
    Write-Host " ╚═══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

# ============================================================================
# ACTION HANDLERS
# ============================================================================

function Invoke-PanelAction {
    param([char]$Key)
    
    switch ($Key) {
        'a' { 
            Write-Host " [AI] Starting Auto-Pilot..." -ForegroundColor Magenta
            Start-NeuralAutoPilot -TargetScore 90 -MaxNoOps 5
        }
        'l' {
            Write-Host " [AI] Running Learning Cycle..." -ForegroundColor Yellow
            $hw = Get-HardwareProfile
            Invoke-NeuralLearning -ProfileName "Interactive" -Hardware $hw -Workload (Predict-UserWorkload)
            Start-Sleep -Seconds 2
        }
        'c' {
            Write-Host " [CACHE] Running Auto Cache Clean..." -ForegroundColor Cyan
            $cacheScript = Join-Path $Script:ScriptDir "Smart-Cache-Cleaner.ps1"
            & $cacheScript -Auto
        }
        's' {
            Write-Host " [SMART] Running Smart Optimizer..." -ForegroundColor Green
            $smartScript = Join-Path $Script:ScriptDir "Smart-Optimizer.ps1"
            if (Test-Path $smartScript) { & $smartScript }
        }
        'b' {
            Invoke-BatchLearning -Episodes 10 -Workload (Predict-UserWorkload)
            Start-Sleep -Seconds 2
        }
        'q' {
            Invoke-QuickOptimization -Actions 5
            Start-Sleep -Seconds 2
        }
        'r' {
            Set-UserFeedback -Reward 10
            Start-Sleep -Seconds 1
        }
        'p' {
            Set-UserFeedback -Reward -10
            Start-Sleep -Seconds 1
        }
        't' {
            Write-Host " [SCHEDULER] Setting up automatic tasks..." -ForegroundColor Magenta
            Initialize-NeuralScheduler
            Read-Host " Press ENTER to continue"
        }
        'v' {
            Write-Host " [SCHEDULER] Viewing scheduled tasks..." -ForegroundColor Cyan
            Get-NeuralScheduledTasks | Format-Table -AutoSize
            Read-Host " Press ENTER to continue"
        }
        'h' {
            Write-Host " [HISTORY] Recent AI Actions:" -ForegroundColor Cyan
            $brain = Get-NeuralBrain
            if ($brain.History) {
                $brain.History | Select-Object -Last 10 | ForEach-Object {
                    $color = if ($_.Reward -gt 0) { "Green" } elseif ($_.Reward -lt 0) { "Red" } else { "Gray" }
                    Write-Host " $($_.Timestamp): $($_.Action) -> " -NoNewline
                    Write-Host "$($_.Reward)" -ForegroundColor $color
                }
            }
            Read-Host " Press ENTER to continue"
        }
        '1' { & (Join-Path $Script:ScriptDir "Boot-Optimization.ps1"); Read-Host " Press ENTER" }
        '2' { & (Join-Path $Script:ScriptDir "Debloat-Suite.ps1"); Read-Host " Press ENTER" }
        '3' { & (Join-Path $Script:ScriptDir "Privacy-Guardian.ps1"); Read-Host " Press ENTER" }
        '4' { & (Join-Path $Script:ScriptDir "Advanced-Gaming.ps1"); Read-Host " Press ENTER" }
        '5' { & (Join-Path $Script:ScriptDir "Network-Optimizer.ps1"); Read-Host " Press ENTER" }
        '6' { & (Join-Path $Script:ScriptDir "SSD-NVMe-Optimizer.ps1"); Read-Host " Press ENTER" }
        '7' { & (Join-Path $Script:ScriptDir "Advanced-Memory.ps1"); Read-Host " Press ENTER" }
        '8' { & (Join-Path $Script:ScriptDir "Service-Manager.ps1"); Read-Host " Press ENTER" }
        '9' { & (Join-Path $Script:ScriptDir "Visual-FX.ps1"); Read-Host " Press ENTER" }
        '0' {
            Write-Host ""
            Write-Host " Additional Modules:" -ForegroundColor Cyan
            Write-Host " [A] Thermal Optimization"
            Write-Host " [B] Disk Hygiene"
            Write-Host " [C] System Monitor"
            Write-Host " [D] Health Check"
            Write-Host " [E] Benchmark Suite"
            Write-Host ""
            $sub = Read-Host " Select"
            switch ($sub.ToLower()) {
                'a' { & (Join-Path $Script:ScriptDir "Thermal-Optimization.ps1") }
                'b' { & (Join-Path $Script:ScriptDir "Disk-Hygiene.ps1") }
                'c' { & (Join-Path $Script:ScriptDir "System-Monitor.ps1") }
                'd' { & (Join-Path $Script:ScriptDir "Health-Check.ps1") }
                'e' { & (Join-Path $Script:ScriptDir "Benchmark-Suite.ps1") }
            }
            Read-Host " Press ENTER"
        }
        'x' { return $false }
    }
    return $true
}

# ============================================================================
# MAIN LOOP
# ============================================================================

if ($TestMode) {
    Show-Panel
    Write-Host " [TEST MODE] Panel rendered successfully" -ForegroundColor Green
    exit 0
}

# Main interactive loop
$running = $true
while ($running) {
    Show-Panel
    
    Write-Host " >> " -NoNewline -ForegroundColor Yellow
    $userInput = Read-Host
    
    if ($userInput.Length -gt 0) {
        $key = $userInput[0]
        $running = Invoke-PanelAction -Key $key
    }
}

Write-Host " [👋] Exiting Neural Panel..." -ForegroundColor Cyan

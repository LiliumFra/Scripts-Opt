<#
.SYNOPSIS
    Neural-Dashboard.ps1
    Real-time interactive console for Windows Neural Optimizer AI v2.0
#>

param([switch]$RunLoop)

$ScriptDir = Split-Path $MyInvocation.MyCommand.Path
$parentDir = Split-Path $ScriptDir -Parent
$utilsPath = Join-Path $ScriptDir "NeuralUtils.psm1"
$aiPath = Join-Path $ScriptDir "NeuralAI.psm1"

# Import Modules
if (Test-Path $utilsPath) { Import-Module $utilsPath -Force -DisableNameChecking }
if (Test-Path $aiPath) { Import-Module $aiPath -Force -DisableNameChecking }

function Show-DashboardHeader {
    Clear-Host
    $config = Get-NeuralConfig
    $brain = Get-NeuralBrain
    $learningCycles = if ($config.LearningCycles) { $config.LearningCycles } else { 0 }
    $epsilon = if ($config.Epsilon) { $config.Epsilon } else { 0.5 }
    
    Write-Host " ==================================================================" -ForegroundColor Cyan
    Write-Host "   NEURAL AI DASHBOARD v2.0 (DEEP LEARNING)" -ForegroundColor Yellow
    Write-Host " ==================================================================" -ForegroundColor Cyan
    Write-Host "   Cycles: $learningCycles   Exploration: $([math]::Round($epsilon * 100, 1))%   Memories: $($brain.History.Count)" -ForegroundColor Gray
    Write-Host ""
}

function Show-LiveStats {
    $load = Get-SystemLoadState
    $loadColor = switch ($load) {
        "Idle" { "Green" }
        "Light" { "Cyan" }
        "Heavy" { "Yellow" }
        "Thrashing" { "Red" }
        Default { "White" }
    }
    
    # Get Real-time Counters
    $cpu = (Get-Counter "\Processor(_Total)\% Processor Time" -MaxSamples 1 -ErrorAction SilentlyContinue).CounterSamples.CookedValue
    $disk = (Get-Counter "\PhysicalDisk(_Total)\% Disk Time" -MaxSamples 1 -ErrorAction SilentlyContinue).CounterSamples.CookedValue
    
    Write-Host "   [SYSTEM STATE]" -ForegroundColor Cyan
    Write-Host "   Load State: " -NoNewline
    Write-Host "$load" -ForegroundColor $loadColor
    Write-Host "   CPU: $([math]::Round($cpu, 1))%   Disk: $([math]::Round($disk, 1))%" -ForegroundColor Gray
    Write-Host ""
}

function Show-RecentHistory {
    Write-Host "   [RECENT ACTIONS]" -ForegroundColor Cyan
    $brain = Get-NeuralBrain
    if ($brain.History.Count -gt 0) {
        $brain.History | Select-Object -Last 5 | ForEach-Object {
            $rewardColor = if ($_.Reward -gt 0) { "Green" } elseif ($_.Reward -lt 0) { "Red" } else { "Gray" }
            Write-Host "   [$($_.Timestamp)] " -NoNewline -ForegroundColor DarkGray
            Write-Host "$($_.Action) " -NoNewline -ForegroundColor White
            Write-Host "-> Reward: $($_.Reward)" -ForegroundColor $rewardColor
        }
    }
    else {
        Write-Host "   No history yet." -ForegroundColor DarkGray
    }
    Write-Host ""
}

function Show-Menu {
    Write-Host "   [CONTROLS]" -ForegroundColor Cyan
    Write-Host "   [L] Run Learning Cycle (Live)" -ForegroundColor White
    Write-Host "   [F] Force Consolidate Memory" -ForegroundColor White
    Write-Host "   [R] Reward Last Action (Good Job)" -ForegroundColor Green
    Write-Host "   [P] Punish Last Action (Bad Job)" -ForegroundColor Red
    Write-Host "   [Q] Quit" -ForegroundColor Gray
    Write-Host ""
}

# Main Loop
do {
    Show-DashboardHeader
    Show-LiveStats
    Show-RecentHistory
    Show-Menu
    
    if ($Host.UI.RawUI.KeyAvailable) {
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        switch ($key.Character) {
            'l' { 
                Write-Host "   Running Learning Cycle..." -ForegroundColor Yellow
                $hw = [PSCustomObject]@{ PerformanceTier = "High"; CpuName = "Live-Dashboard" }
                Invoke-NeuralLearning -ProfileName "Dashboard-Manual" -Hardware $hw
                Start-Sleep -Seconds 2
            }
            'f' {
                Update-PersistenceRewards -QTable (Get-QTable)
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
            'q' { return }
        }
    }
    
    Start-Sleep -Milliseconds 1000
} while ($true)

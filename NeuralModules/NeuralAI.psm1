<#
.SYNOPSIS
    Neural-AI Module v1.0
    Implements Local Reinforcement Learning (RL) for system optimization.

.DESCRIPTION
    This module enables the "Optimize-and-Learn" loop:
    1. Observe: Measure system latency (DPC/Interrupts).
    2. Remember: Store results in a local JSON "Brain".
    3. Adapt: Future runs can query the Brain to see which settings yielded the best scores.

.NOTES
    Part of Windows Neural Optimizer
    Author: Jose Bustamante
#>

$Script:ModulePath = Split-Path $MyInvocation.MyCommand.Path -Parent
$Script:BrainPath = Join-Path $Script:ModulePath "..\NeuralBrain.json"

function Get-NeuralBrain {
    if (Test-Path $Script:BrainPath) {
        try {
            return Get-Content $Script:BrainPath -Raw | ConvertFrom-Json
        }
        catch {
            return @{ History = @() }
        }
    }
    # Future expansion: Cloud AI integration
    # For now, local logic only
    return @{ History = @() }
}

function Save-NeuralBrain {
    param($Data)
    try {
        $Data | ConvertTo-Json -Depth 5 | Set-Content $Script:BrainPath -Force
    }
    catch {
        Write-Host " [!] Error saving AI Brain: $_" -ForegroundColor Red
    }
}

function Measure-SystemMetrics {
    param([int]$DurationSeconds = 5)
    
    Write-Host "   [AI] Measuring System Latency & Stability..." -ForegroundColor Cyan
    
    try {
        # Added Context Switches to detect thrashing
        $counters = @(
            "\Processor(_Total)\% DPC Time", 
            "\Processor(_Total)\% Interrupt Time",
            "\System\Context Switches/sec"
        )
        
        $samples = Get-Counter -Counter $counters -SampleInterval 1 -MaxSamples $DurationSeconds -ErrorAction Stop
    
        $avgDpc = ($samples.CounterSamples | Where-Object Path -match "dpc" | Measure-Object -Property CookedValue -Average).Average
        $avgInt = ($samples.CounterSamples | Where-Object Path -match "interrupt" | Measure-Object -Property CookedValue -Average).Average
        $avgCtx = ($samples.CounterSamples | Where-Object Path -match "context" | Measure-Object -Property CookedValue -Average).Average
        
        # Penalize Context Switches (Thrashing detection)
        # Normal desktop might have 500-2000. Gaming/Stress > 5000.
        # Penalty: -1 point for every 1000 switches over 3000 baseline? Smart heuristic needed.
        $ctxPenalty = 0
        if ($avgCtx -gt 5000) {
            $ctxPenalty = [math]::Round(($avgCtx - 5000) / 1000, 2)
        }
        
        # Base Score
        $rawScore = 100 - ($avgDpc + $avgInt) - $ctxPenalty
        if ($rawScore -lt 0) { $rawScore = 0 }

        return [PSCustomObject]@{
            DpcTime       = [math]::Round($avgDpc, 4)
            InterruptTime = [math]::Round($avgInt, 4)
            ContextSwitch = [math]::Round($avgCtx, 0)
            Score         = [math]::Round($rawScore, 2) # Higher is better
        }
    }
    catch {
        Write-Host "   [!] Failed to measure metrics (PerfCounters might be disabled). Assuming neutral score." -ForegroundColor Yellow
        return [PSCustomObject]@{ DpcTime = 0; InterruptTime = 0; ContextSwitch = 0; Score = 50 } # Neutral score
    }
}

function Invoke-NeuralLearning {
    param(
        [string]$ProfileName,
        [object]$Hardware
    )
    
    Write-Section "NEURAL LEARNING CYCLE (RL)"
    
    # 1. Measure Effect
    $metrics = Measure-SystemMetrics -DurationSeconds 5
    
    Write-Host "   [RESULT] DPC Latency:     $($metrics.DpcTime)%" -ForegroundColor Green
    Write-Host "   [RESULT] Interrupts:      $($metrics.InterruptTime)%" -ForegroundColor Green
    Write-Host "   [RESULT] Context Switch:  $($metrics.ContextSwitch)/sec" -ForegroundColor Green
    Write-Host "   [SCORE]  Optimization Score: $($metrics.Score)/100" -ForegroundColor Cyan
    
    # 2. Update Brain
    $brain = Get-NeuralBrain
    # Convert PSCustomObject to Hashtable if needed for JSON manipulation, or just append
    if (-not $brain.History) { $brain = @{ History = @() } }
    
    # Create Record
    $record = @{
        Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Hardware  = $Hardware.CpuName
        Tier      = $Hardware.PerformanceTier
        Profile   = $ProfileName
        Score     = $metrics.Score
        Metrics   = $metrics
    }
    
    # Append (PowerShell arrays are fixed size, so needs +=)
    $history = $brain.History 
    if ($history -is [System.Array]) {
        $history += $record
    }
    else {
        $history = @($record)
    }
    
    $brain.History = $history
    Save-NeuralBrain -Data $brain
    
    # 3. Insight
    $bestRun = $history | Sort-Object Score -Descending | Select-Object -First 1
    if ($bestRun) {
        Write-Host "   [INSIGHT] Best recorded run: $($bestRun.Score) (Profile: $($bestRun.Profile))" -ForegroundColor Magenta
    }
    
    # 4. Active Exploration
    if ($metrics.Score -lt 80 -and -not $brain.ExplorationLock) {
        Write-Host "   [AI] Score below threshold (80). Triggering Active Exploration..." -ForegroundColor Yellow
        Invoke-ExploratoryTweak -CurrentScore $metrics.Score
    }
}

function Invoke-ExploratoryTweak {
    param($CurrentScore)
    
    # Valid tweaks to test
    $tweaks = @(
        @{ Name = "TimerRes"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel"; Key = "GlobalTimerResolutionRequests"; Vald = 1; ValOriginal = 0 },
        @{ Name = "DynamicTick"; Command = "bcdedit /set disabledynamictick yes"; Rollback = "bcdedit /set disabledynamictick no" }
    )
    
    # Simple Random Choice for now (can be smarter)
    $tweak = $tweaks | Get-Random
    
    Write-Host "   [AI-EXPLORE] Testing Tweak: $($tweak.Name)" -ForegroundColor Magenta
    
    # Apply
    if ($tweak.Command) { cmd /c $tweak.Command | Out-Null }
    if ($tweak.Path) { Set-ItemProperty -Path $tweak.Path -Name $tweak.Key -Value $tweak.Vald -Force -ErrorAction SilentlyContinue }
    
    # Measure Immediate Impact (Quick 3s test)
    Start-Sleep -Seconds 1
    $newMetrics = Measure-SystemMetrics -DurationSeconds 3
    
    if ($newMetrics.Score -gt $CurrentScore) {
        Write-Host "   [AI-EXPLORE] SUCCESS! New Score: $($newMetrics.Score) (+$($newMetrics.Score - $CurrentScore)). Keeping change." -ForegroundColor Green
        # Log success to brain?
    }
    else {
        Write-Host "   [AI-EXPLORE] No improvement ($($newMetrics.Score)). Rolling back." -ForegroundColor DarkGray
        # Revert
        if ($tweak.Rollback) { cmd /c $tweak.Rollback | Out-Null }
        if ($tweak.Path) { Set-ItemProperty -Path $tweak.Path -Name $tweak.Key -Value $tweak.ValOriginal -Force -ErrorAction SilentlyContinue }
    }
}

function Get-NeuralRecommendation {
    param($Hardware)
    
    $brain = Get-NeuralBrain
    if (-not $brain.History) { 
        return $null 
    }
    
    # 1. Filter history for this CPU
    $history = $brain.History | Where-Object { $_.Hardware -eq $Hardware.CpuName }
    if (-not $history) { return $null }

    # 2. Find the best scoring profile
    # We group by profile and average the score to avoid outliers
    $stats = $history | Group-Object Profile | Select-Object Name, @{N = 'AvgScore'; E = { ($_.Group | Measure-Object Score -Average).Average } } | Sort-Object AvgScore -Descending
    
    $best = $stats | Select-Object -First 1
    
    if ($best) {
        Write-Host "   [AI] Recommendation: Found historical best override ($($best.Name))" -ForegroundColor Magenta
        return [PSCustomObject]@{
            RecommendedProfile = $best.Name
            Confidence         = $best.AvgScore
            Reason             = "Based on historical average performance"
        }
    }
    
    return $null
}

Export-ModuleMember -Function Invoke-NeuralLearning, Get-NeuralRecommendation, Get-NeuralBrain

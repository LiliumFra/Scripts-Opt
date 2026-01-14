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
    
    Write-Host "   [AI] Measuring System Latency (DPC/Interrupts)..." -ForegroundColor Cyan
    
    try {
        # Take 5 samples, 1 second interval
        $samples = Get-Counter -Counter "\Processor(_Total)\% DPC Time", "\Processor(_Total)\% Interrupt Time" -SampleInterval 1 -MaxSamples $DurationSeconds -ErrorAction Stop
        
        $avgDpc = ($samples.CounterSamples | Where-Object Path -match "dpc" | Measure-Object -Property CookedValue -Average).Average
        $avgInt = ($samples.CounterSamples | Where-Object Path -match "interrupt" | Measure-Object -Property CookedValue -Average).Average
        
        return [PSCustomObject]@{
            DpcTime       = [math]::Round($avgDpc, 4)
            InterruptTime = [math]::Round($avgInt, 4)
            Score         = [math]::Round(100 - ($avgDpc + $avgInt), 2) # Higher is better
        }
    }
    catch {
        Write-Host "   [!] Failed to measure metrics (PerfCounters might be disabled). Assuming neutral score." -ForegroundColor Yellow
        return [PSCustomObject]@{ DpcTime = 0; InterruptTime = 0; Score = 50 } # Neutral score
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
    
    Write-Host "   [RESULT] DPC Latency: $($metrics.DpcTime)%" -ForegroundColor Green
    Write-Host "   [RESULT] Interrupts:  $($metrics.InterruptTime)%" -ForegroundColor Green
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

Export-ModuleMember -Function Invoke-NeuralLearning, Get-NeuralRecommendation

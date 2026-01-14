<#
.SYNOPSIS
    Test-NeuralAI.ps1
    Verifies the functionality of the Neural-AI Reinforcement Learning Module.
#>

$currentDir = Split-Path $MyInvocation.MyCommand.Path
$modulePath = Join-Path $currentDir "NeuralModules\NeuralAI.psm1"
$utilsPath = Join-Path $currentDir "NeuralModules\NeuralUtils.psm1"

Write-Host " [Testing] Importing Neural Modules..." -ForegroundColor Cyan
Import-Module $utilsPath -Force
Import-Module $modulePath -Force

# Mock Hardware Object
$mockHw = [PSCustomObject]@{
    CpuName         = "Test-CPU-Intel-Gen13"
    PerformanceTier = "High"
    IsLaptop        = $false
}

Write-Host " [Testing] 1. Learning Cycle (Measurement)..." -ForegroundColor Yellow
# Run a short learning cycle
Invoke-NeuralLearning -ProfileName "Neural Low Latency" -Hardware $mockHw

Write-Host "`n [Testing] 2. Checking Brain Persistence..." -ForegroundColor Yellow
$brain = Get-NeuralBrain
if ($brain.History.Count -gt 0) {
    Write-Host "   [OK] Brain has $($brain.History.Count) records." -ForegroundColor Green
    $brain.History | Select-Object -Last 1 | Format-List
}
else {
    Write-Host "   [FAIL] Brain is empty!" -ForegroundColor Red
}

Write-Host "`n [Testing] 3. Recommendation Engine..." -ForegroundColor Yellow
# Asking for recommendation for the same mock hardware
$rec = Get-NeuralRecommendation -Hardware $mockHw
if ($rec) {
    Write-Host "   [OK] AI Recommended: $($rec.RecommendedProfile) (Confidence: $($rec.Confidence))" -ForegroundColor Green
}
else {
    Write-Host "   [INFO] No recommendation yet (might need more data or logic check)." -ForegroundColor Gray
}

Write-Host "`n [Done] Test Complete." -ForegroundColor Cyan

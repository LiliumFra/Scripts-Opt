$ErrorActionPreference = "Stop"
try {
    Write-Host "Importing NeuralEngine..."
    Import-Module "d:\josef\Documents\Scripts Opt\NeuralModules\NeuralEngine.psm1" -Force
    
    Write-Host "Testing Invoke-NeuralEngine (Dry Run)..."
    Invoke-NeuralEngine -RiskLevel "Medium" -OS "Windows 11" -WhatIf
    
    Write-Host "SUCCESS: Engine loaded and executed." -ForegroundColor Green
}
catch {
    Write-Error "FAIL: $_"
}

$ErrorActionPreference = "Stop"

function Assert-Module {
    param($Path, $Name)
    if (Test-Path $Path) { Write-Host " [OK] Module found: $Name" -ForegroundColor Green }
    else { Write-Host " [FAIL] Module MISSING: $Name ($Path)" -ForegroundColor Red }
}

Write-Host "Verifying Windows Neural Optimizer v5.0 ULTRA Structure..." -ForegroundColor Cyan

# Root
Assert-Module "d:\josef\Documents\Scripts Opt\Optimize-Windows.ps1" "Main Controller"
Assert-Module "d:\josef\Documents\Scripts Opt\NeuralCache-Diagnostic.ps1" "Neural Cache Root"

# NeuralModules
$modDir = "d:\josef\Documents\Scripts Opt\NeuralModules"
Assert-Module "$modDir\NeuralUtils.psm1" "Neural Utils"
Assert-Module "$modDir\AI-Recommendations.ps1" "AI Engine"
Assert-Module "$modDir\ML-Usage-Patterns.ps1" "ML Engine"
Assert-Module "$modDir\Network-Optimizer.ps1" "Network Optimizer"
Assert-Module "$modDir\Service-Manager.ps1" "Service Manager"
Assert-Module "$modDir\Privacy-Guardian.ps1" "Privacy Guardian"
Assert-Module "$modDir\Visual-FX.ps1" "Visual FX"
Assert-Module "$modDir\Advanced-Gaming.ps1" "Advanced Gaming"

# Check Main Menu Version text
$content = Get-Content "d:\josef\Documents\Scripts Opt\Optimize-Windows.ps1" -Raw
if ($content -match "Version.*5.0 ULTRA") {
    Write-Host " [OK] Version string verified as 5.0 ULTRA" -ForegroundColor Green
}
else {
    Write-Host " [FAIL] Version string mismatch" -ForegroundColor Red
}

# Check Network Optimizer Integration in Main Menu
if ($content -match "Invoke-OptimizationModule.*Network-Optimizer.ps1") {
    Write-Host " [OK] Network Optimizer hooked in Main Menu" -ForegroundColor Green
}
else {
    Write-Host " [FAIL] Network Optimizer NOT linked in Main Menu" -ForegroundColor Red
}

Write-Host "Verification Complete."

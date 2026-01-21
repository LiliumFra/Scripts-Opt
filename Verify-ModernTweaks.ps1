Import-Module "$PSScriptRoot\NeuralModules\NeuralAI.psm1" -Force

Write-Host "=== Neural Tweak Library Verification ===" -ForegroundColor Cyan

# 1. Get All Actions
$actions = Get-AvailableActions
$count = $actions.Count

Write-Host "Total Tweaks Loaded: $count" -ForegroundColor ($count -eq 96 ? "Green" : "Red")

# 2. Category Breakdown
Write-Host "`n[Category Analysis]" -ForegroundColor Yellow
$actions | Group-Object Category | Select-Object Name, Count | Sort-Object Count -Descending | Format-Table -AutoSize

# 3. Specific Modern Tweak Check
Write-Host "`n[Spot Check]" -ForegroundColor Yellow
$tests = @("DebloatSolitaire", "VisAnim", "PwrThrottling", "SvcTelefax")
foreach ($id in $tests) {
    if ($actions.Id -contains $id) {
        Write-Host " [OK] Found Modern Tweak: $id" -ForegroundColor Green
    }
    else {
        Write-Host " [!!] MISSING Tweak: $id" -ForegroundColor Red
    }
}

# 4. Legacy Check (Should be missing)
Write-Host "`n[Legacy Cleanup Check]" -ForegroundColor Yellow
$legacy = @("IoPageLock", "Prefetch", "Superfetch")
foreach ($id in $legacy) {
    if ($actions.Id -contains $id) {
        Write-Host " [FAIL] Legacy Tweak Found: $id" -ForegroundColor Red
    }
    else {
        Write-Host " [OK] Cleaned: $id" -ForegroundColor Green
    }
}

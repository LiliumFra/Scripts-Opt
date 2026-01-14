# Test-Import.ps1
try {
    Import-Module ".\NeuralModules\NeuralAI.psm1" -Force -ErrorAction Stop
    Write-Host "SUCCESS: Module imported" -ForegroundColor Green
    Get-Command -Module NeuralAI
}
catch {
    Write-Host "IMPORT ERROR:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Details:" -ForegroundColor Yellow
    $_.Exception | Format-List -Force
}

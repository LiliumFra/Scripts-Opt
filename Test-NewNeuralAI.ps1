# Test-NewNeuralAI.ps1
# Quick test of the new NeuralAI module

Write-Host "Testing NeuralAI.psm1 v2.0..." -ForegroundColor Cyan

try {
    # Parse check
    $content = Get-Content ".\NeuralModules\NeuralAI.psm1" -Raw
    $errors = $null
    $tokens = $null
    [void][System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$tokens, [ref]$errors)
    
    if ($errors.Count -gt 0) {
        Write-Host "SYNTAX ERRORS FOUND:" -ForegroundColor Red
        foreach ($err in $errors) {
            Write-Host "  Line $($err.Extent.StartLineNumber): $($err.Message)" -ForegroundColor Red
        }
        exit 1
    }
    else {
        Write-Host "[OK] Syntax validation passed" -ForegroundColor Green
    }
    
    # Import
    Import-Module ".\NeuralModules\NeuralAI.psm1" -Force -ErrorAction Stop
    Write-Host "[OK] Module imported successfully" -ForegroundColor Green
    
    # List functions
    $funcs = Get-Command -Module NeuralAI
    Write-Host "[OK] Exported functions:" -ForegroundColor Green
    foreach ($f in $funcs) {
        Write-Host "     - $($f.Name)" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "All tests passed!" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
    exit 1
}

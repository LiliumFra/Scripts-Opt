# Test-Dashboard.ps1

Write-Host "Testing Neural-Dashboard.ps1..." -ForegroundColor Cyan

$content = Get-Content ".\NeuralModules\Neural-Dashboard.ps1" -Raw
$errors = $null
$tokens = $null
[void][System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$tokens, [ref]$errors)

if ($errors.Count -gt 0) {
    Write-Host "SYNTAX ERRORS FOUND:" -ForegroundColor Red
    foreach ($err in $errors) {
        Write-Host "  Line $($err.Extent.StartLineNumber): $($err.Message)" -ForegroundColor Red
    }
}
else {
    Write-Host "[OK] Syntax validation passed" -ForegroundColor Green
}

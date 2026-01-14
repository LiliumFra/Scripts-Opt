# Test-NewModules.ps1

Write-Host "Testing new modules..." -ForegroundColor Cyan

$modules = @(
    "Update-Checker.ps1",
    "Lenovo-Optimization.ps1"
)

foreach ($mod in $modules) {
    $path = ".\NeuralModules\$mod"
    $content = Get-Content $path -Raw
    $errors = $null
    $tokens = $null
    [void][System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$tokens, [ref]$errors)
    
    if ($errors.Count -gt 0) {
        Write-Host "[ERROR] $mod" -ForegroundColor Red
        foreach ($err in $errors) {
            Write-Host "  Line $($err.Extent.StartLineNumber): $($err.Message)" -ForegroundColor Red
        }
    }
    else {
        Write-Host "[OK] $mod" -ForegroundColor Green
    }
}

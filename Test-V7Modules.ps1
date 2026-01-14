# Test-V7Modules.ps1

Write-Host "Testing v7.0 modules..." -ForegroundColor Cyan

$modules = @(
    @{ Name = "NeuralCache-Diagnostic.ps1"; Path = ".\NeuralCache-Diagnostic.ps1" },
    @{ Name = "Lenovo-Optimization.ps1"; Path = ".\NeuralModules\Lenovo-Optimization.ps1" },
    @{ Name = "NeuralAI.psm1"; Path = ".\NeuralModules\NeuralAI.psm1" }
)

foreach ($mod in $modules) {
    $content = Get-Content $mod.Path -Raw
    $errors = $null
    $tokens = $null
    [void][System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$tokens, [ref]$errors)
    
    if ($errors.Count -gt 0) {
        Write-Host "[ERROR] $($mod.Name)" -ForegroundColor Red
        foreach ($err in $errors | Select-Object -First 3) {
            Write-Host "  Line $($err.Extent.StartLineNumber): $($err.Message)" -ForegroundColor Red
        }
    }
    else {
        Write-Host "[OK] $($mod.Name)" -ForegroundColor Green
    }
}

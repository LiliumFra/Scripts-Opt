# Verification Script for Windows Neural Optimizer v6.0
$ErrorActionPreference = "Stop"

function Test-ModuleImport {
    param($Path)
    Write-Host " [?] Testing module: $Path" -NoNewline
    try {
        # Import into Global scope for functional tests
        Import-Module $Path -Force -ErrorAction Stop -Scope Global
        Write-Host " [OK]" -ForegroundColor Green
    }
    catch {
        Write-Host " [FAIL]" -ForegroundColor Red
        Write-Host "     $($_)" -ForegroundColor Red
    }
}

Write-Host "=== NEURAL OPTIMIZER v6.0 VERIFICATION ===" -ForegroundColor Cyan
Write-Host ""

# 1. Module Imports & Script Syntax Check
$modules = @("NeuralModules\NeuralLocalization.psm1", "NeuralModules\NeuralUtils.psm1")
$scripts = @("NeuralModules\Network-Optimizer.ps1", "NeuralModules\Gaming-Optimization.ps1", "NeuralModules\AI-Recommendations.ps1", "Optimize-Windows.ps1")

foreach ($m in $modules) {
    Test-ModuleImport -Path ".\$m"
}

Write-Host ""
Write-Host " [?] Verifying Script Syntax..."
foreach ($s in $scripts) {
    $path = ".\$s"
    if (Test-Path $path) {
        $errors = $null
        try {
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $path -Raw -Encoding UTF8), [ref]$errors)
            if ($errors) {
                Write-Host " [FAIL] $s" -ForegroundColor Red
                foreach ($err in $errors) {
                    Write-Host "     Line $($err.Token.StartLine): $($err.Message)" -ForegroundColor Red
                }
            }
            else {
                Write-Host " [OK] $s (Syntax Valid)" -ForegroundColor Green
            }
        }
        catch {
            Write-Host " [ERROR] Failed to parse $s : $_" -ForegroundColor Red
        }
    }
    else {
        Write-Host " [MISSING] $s" -ForegroundColor Yellow
    }
}

# 2. Test Configuration & Localization
Write-Host ""
Write-Host " [?] Testing NeuralConfig..."
try {
    $config = Get-NeuralConfig
    if ($null -ne $config) {
        Write-Host "     Loaded Config: $($config | ConvertTo-Json -Compress)" -ForegroundColor Gray
    }
    else {
        Write-Host "     Config not found or empty (Expected if first run)" -ForegroundColor Yellow
    }
    
    # Test Language Switch
    Set-Language "EN"
    $msg = Msg "Utils.Rollback.Confirm"
    Write-Host "     EN Test: $msg" -ForegroundColor Gray
    
    Set-Language "ES"
    $msg = Msg "Utils.Rollback.Confirm"
    Write-Host "     ES Test: $msg" -ForegroundColor Gray
    
    Write-Host " [OK] Localization System" -ForegroundColor Green
}
catch {
    Write-Host " [FAIL] Localization System: $_" -ForegroundColor Red
}

# 3. Test Registry Backup (Safe Test)
Write-Host ""
Write-Host " [?] Testing Registry Backup (HKCU Safe Key)..."
try {
    $testKey = "HKCU:\Software\NeuralTest"
    if (-not (Test-Path $testKey)) { New-Item $testKey -Force | Out-Null }
    
    # Create a value to backup
    Set-ItemProperty $testKey -Name "TestValue" -Value 123
    
    # Test Backup via Set-RegistryKey (should trigger backup)
    # We flip SkipBackup to $false (default is now $false for switch? No, we refactored to -SkipBackup.
    # So calling WITHOUT -SkipBackup should trigger backup.
    
    Set-RegistryKey -Path $testKey -Name "TestValue" -Value 456 -Desc "Test Backup Trigger"
    
    $backupDir = "Backups"
    if (Test-Path $backupDir) {
        $latest = Get-ChildItem $backupDir | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($latest) {
            Write-Host "     Backup created: $($latest.Name)" -ForegroundColor Gray
            Write-Host " [OK] Registry Backup System" -ForegroundColor Green
        }
        else {
            Write-Host " [FAIL] No backup file found" -ForegroundColor Red
        }
    }
    
    # Cleanup
    Remove-Item $testKey -Recurse -Force
}
catch {
    Write-Host " [FAIL] Registry Backup: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== VERIFICATION COMPLETE ===" -ForegroundColor Cyan



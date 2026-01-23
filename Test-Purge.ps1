$ErrorActionPreference = "Stop"

try {
    Write-Host " [Testing] Simulating 'Snake Oil' Infection..." -ForegroundColor Yellow
    
    # 1. Inject a bad key (DisablePagingExecutive = 1)
    $path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
    Set-ItemProperty -Path $path -Name "DisablePagingExecutive" -Value 1 -Force
    Write-Host "   [+] Injected obsolete tweak: DisablePagingExecutive = 1" -ForegroundColor Gray
    
    # 2. Import Engine
    Import-Module "$PSScriptRoot\NeuralModules\NeuralEngine.psm1" -Force
    
    # 3. Run Purge
    Invoke-LegacyPurge
    
    # 4. Verify
    $val = (Get-ItemProperty -Path $path).DisablePagingExecutive
    if ($val -ne 0) {
        Write-Error "FAIL: DisablePagingExecutive is still $val (Expected 0)"
    }
    
    Write-Host "SUCCESS: Legacy Purge worked. System is clean." -ForegroundColor Green
    
}
catch {
    Write-Error "FAIL: $_"
}

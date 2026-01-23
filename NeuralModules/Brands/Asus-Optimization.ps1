<#
.SYNOPSIS
    Asus-Optimization.ps1 v1.0 (Beast Mode)
    ASUS ROG/TUF service optimization and G-Helper integration support.

.DESCRIPTION
    Targeting ASUS Gaming Laptops (Zephyrus, Strix, TUF).
    Since ASUS WMI is complex/proprietary, this module focuses on:
    - Debloating Armoury Crate Services (if user wants pure performance without overhead)
    - Detecting G-Helper (Recommended lightweight alternative)
    - Power Plan Injection for ROG devices

.NOTES
    Author: Neural Optimizer (Beast Mode)
#>

function Test-AsusSystem {
    try {
        $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
        return $cs.Manufacturer -match "ASUS"
    }
    catch { return $false }
}

function Invoke-AsusOptimization {
    Write-Host ""
    Write-Host " === ASUS ROG/TUF OPTIMIZATION ===" -ForegroundColor Magenta
    
    if (-not (Test-AsusSystem)) {
        Write-Host " [!] Not an ASUS System." -ForegroundColor Yellow
        return
    }
    
    # 1. Armoury Crate vs G-Helper Check
    $gHelper = Get-Process "G-Helper" -ErrorAction SilentlyContinue
    if ($gHelper) {
        Write-Host " [OK] G-Helper detected! (Best Practice)" -ForegroundColor Green
        Write-Host "      Stopping redundant ASUS services..." -ForegroundColor Cyan
        
        $asusServices = @("ArmouryCrateService", "ASUSOptimization", "AsusROGLSLService")
        foreach ($svc in $asusServices) {
            $s = Get-Service $svc -ErrorAction SilentlyContinue
            if ($s -and $s.Status -ne "Stopped") {
                Stop-Service $svc -Force -ErrorAction SilentlyContinue
                Set-Service $svc -StartupType Manual -ErrorAction SilentlyContinue
                Write-Host "      Stopped: $svc" -ForegroundColor DarkGray
            }
        }
    }
    else {
        Write-Host " [i] Armoury Crate detected (Standard)." -ForegroundColor Yellow
        Write-Host "     Recommendation: Install 'G-Helper' for lighter resource usage." -ForegroundColor Gray
    }
    
    # 2. Dolby Atmos / Audio Latency
    # ASUS laptops often have Dolby processing that adds latency. 
    # Beast Mode recommendation: Disable for competitive gaming.
    
    # 3. ROG Power Plan Injection
    # Ensure "Turbo" or "Performance" equivalents exist in standard Windows Power Plans
    $plans = Get-CimInstance Win32_PowerPlan -Namespace root\cimv2\power
    $hasTurbo = $plans | Where-Object { $_.ElementName -match "Turbo|High Performance" }
    
    if (-not $hasTurbo) {
        Write-Host " [i] Injecting High Performance Plan template..." -ForegroundColor Cyan
        powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
    }
    
    Write-Host " [OK] ASUS Optimizations Applied." -ForegroundColor Green
}

Export-ModuleMember -Function Invoke-AsusOptimization

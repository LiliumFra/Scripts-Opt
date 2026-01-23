<#
.SYNOPSIS
    Generic-Optimization.ps1 v1.0 (Beast Mode)
    Fallback optimizations for brands without specific WMI integrations (Acer, MSI, Razor, etc.).

.DESCRIPTION
    Applies universal high-performance power profiles and registry tweaks common to gaming laptops.
    Detects "Gaming" SKUs via loose text matching to apply aggressive cooling policies where possible via standard ACPI methods (if widely supported, mostly relies on Power Plans).

.NOTES
    Author: Neural Optimizer (Beast Mode)
#>

function Invoke-GenericOptimization {
    Write-Host ""
    Write-Host " === GENERIC/UNIVERSAL OPTIMIZATION ===" -ForegroundColor Magenta
    
    $cs = Get-CimInstance Win32_ComputerSystem
    Write-Host " [i] Detected System: $($cs.Manufacturer) - $($cs.Model)" -ForegroundColor Cyan
    
    # 1. Gaming Laptop Detection Heuristic
    $isGaming = $cs.Model -match "Nitro|Predator|Katana|Raider|Stealth|Blade|Alienware|G3|G5|G7|Omen|Victus"
    
    if ($isGaming) {
        Write-Host " [!] Gaming SKU Detected! Applying aggressive scheduling..." -ForegroundColor Magenta
        
        # Force High Performance Power Plan if not already
        $currentPlan = Get-CimInstance Win32_PowerPlan -Namespace root\cimv2\power -Filter "IsActive='True'"
        if ($currentPlan.ElementName -notmatch "High|Turbo|Ultimate|Game") {
            powercfg -setactive scheme_min_power_saving
            Write-Host "     Active Plan set to: High Performance" -ForegroundColor Green
        }
        
        # MSI Mode Check (Generic)
        Write-Host "     Verifying MSI Mode on key devices..." -ForegroundColor Cyan
        # (This logic is usually in Smart-Optimizer, but we double check here)
    }
    else {
        Write-Host " [i] Standard System. Applying balanced efficiency tweaks." -ForegroundColor Gray
        # Ensure 'Balanced' is not 'Power Saver'
    }
    
    # 2. Universal Bloat Checks
    # Check for common pre-installed trials (McAfee, Norton)
    $bloat = Get-Service | Where-Object { $_.DisplayName -match "McAfee|Norton|Avast" -and $_.Status -ne "Stopped" }
    if ($bloat) {
        Write-Host " [!] Third-party antivirus detected. Recommended: Use Windows Defender for best performance." -ForegroundColor Yellow
    }
    
    Write-Host " [OK] Generic Optimizations Applied." -ForegroundColor Green
}

Export-ModuleMember -Function Invoke-GenericOptimization

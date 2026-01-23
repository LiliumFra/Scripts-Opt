<#
.SYNOPSIS
    Brand-Factory.psm1
    Factory pattern for loading vendor-specific optimization modules.
#>

function Get-BrandModule {
    $manuf = (Get-CimInstance Win32_ComputerSystem).Manufacturer
    $modulePath = $PSScriptRoot
    
    if ($manuf -match "Lenovo") {
        return Join-Path $modulePath "..\Lenovo-Optimization.ps1" 
    }
    elseif ($manuf -match "HP|Hewlett-Packard") {
        return Join-Path $modulePath "Brands\HP-Optimization.ps1"
    }
    elseif ($manuf -match "Dell") {
        return Join-Path $modulePath "Brands\Dell-Optimization.ps1"
    }
    elseif ($manuf -match "ASUS") {
        return Join-Path $modulePath "Brands\Asus-Optimization.ps1"
    }
    else {
        # Fallback for Acer, MSI, etc.
        return Join-Path $modulePath "Brands\Generic-Optimization.ps1"
    }
    
    return $null
}

function Invoke-BrandOptimization {
    $script = Get-BrandModule
    if ($script -and (Test-Path $script)) {
        Write-Host " [Factory] Detected Brand Module: $(Split-Path $script -Leaf)" -ForegroundColor Cyan
        . $script
        
        # Dispatch based on detected brand functions
        if (Get-Command "Show-LenovoOptimizationMenu" -ErrorAction SilentlyContinue) {
            Show-LenovoOptimizationMenu
        }
        elseif (Get-Command "Invoke-HPOptimization" -ErrorAction SilentlyContinue) {
            Invoke-HPOptimization
        }
        elseif (Get-Command "Invoke-DellOptimization" -ErrorAction SilentlyContinue) {
            Invoke-DellOptimization
        }
        elseif (Get-Command "Invoke-AsusOptimization" -ErrorAction SilentlyContinue) {
            Invoke-AsusOptimization
        }
        elseif (Get-Command "Invoke-GenericOptimization" -ErrorAction SilentlyContinue) {
            Invoke-GenericOptimization
        }
    }
    else {
        Write-Host " [Factory] No optimization module available." -ForegroundColor DarkGray
    }
}

Export-ModuleMember -Function Invoke-BrandOptimization

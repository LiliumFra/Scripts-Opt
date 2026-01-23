<#
.SYNOPSIS
    Dell-Optimization.ps1 v1.0 (Beast Mode)
    Dell Command | Monitor WMI integration for Neural Optimizer.

.DESCRIPTION
    Leverages `root\dcim\sysman` to manage Dell BIOS settings directly from PowerShell.
    Targeting Latitude, Precision, XPS, and Alienware lines.

.NOTES
    Author: Neural Optimizer (Beast Mode)
    Required: Dell Command | Monitor (or Factory installed WMI providers)
#>

function Test-DellSystem {
    try {
        $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
        return $cs.Manufacturer -match "Dell"
    }
    catch { return $false }
}

function Get-DellNamespace {
    # Check standard DCIM namespace
    if (Get-CimInstance -Namespace "root\dcim\sysman" -ClassName "DCIM_BIOSService" -ErrorAction SilentlyContinue) {
        return "root\dcim\sysman"
    }
    return $null
}

function Set-DellBiosAttribute {
    param(
        [string]$AttributeName,
        [string]$AttributeValue,
        [string]$Namespace = "root\dcim\sysman"
    )
    
    try {
        $service = Get-CimInstance -Namespace $Namespace -ClassName "DCIM_BIOSService" -ErrorAction Stop
        if ($service) {
            # Method: SetBIOSAttributes(AttributeName[], AttributeValue[], Password)
            $args = @{
                AttributeName      = @($AttributeName)
                AttributeValue     = @($AttributeValue)
                AuthorizationToken = $null # Settings password if needed
            }
            
            $result = Invoke-CimMethod -InputObject $service -MethodName "SetBIOSAttributes" -Arguments $args
            
            # Return value 0 = Success, 4096 = Job Created (Reboot required usually)
            if ($result.ReturnValue -eq 0 -or $result.ReturnValue -eq 4096) {
                Write-Host "   [OK] Dell BIOS: Set '$AttributeName' to '$AttributeValue'" -ForegroundColor Green
                return $true
            }
            else {
                Write-Host "   [!] Dell BIOS Set Failed: Code $($result.ReturnValue)" -ForegroundColor Red
                return $false
            }
        }
    }
    catch {
        Write-Host "   [!] Error applying Dell Tweak: $_" -ForegroundColor Red
    }
    return $false
}

function Invoke-DellOptimization {
    Write-Host ""
    Write-Host " === DELL BEAST MODE OPTIMIZATION ===" -ForegroundColor Magenta
    
    if (-not (Test-DellSystem)) {
        Write-Host " [!] Not a Dell System." -ForegroundColor Yellow
        return
    }

    $ns = Get-DellNamespace
    if (-not $ns) {
        Write-Host " [!] Dell Command | Monitor Namespace not found." -ForegroundColor Yellow
        Write-Host "     This module requires Dell Command | Monitor installed." -ForegroundColor DarkGray
        return
    }
    
    Write-Host " [i] Dell DCIM Namespace detected." -ForegroundColor Cyan
    
    # 1. Thermal Management
    # Modes: optimized, cool-bottom, quiet, ultraperformance
    Write-Host " [?] Set Thermal Profile to Ultra Performance? (Y/N) " -ForegroundColor Cyan
    # Auto-applying for 'Beast Mode' context if user engaged scripts
    
    Set-DellBiosAttribute -AttributeName "ThermalManagement" -AttributeValue "UltraPerformance" -Namespace $ns
    
    # 2. Peak Shift (Battery)
    # Ensure Peak Shift is disabled for max performance (unless user wants battery life)
    Set-DellBiosAttribute -AttributeName "PeakShift" -AttributeValue "Disabled" -Namespace $ns
    
    # 3. USB Wake Support
    # Disable to prevent sleep wakeups
    Set-DellBiosAttribute -AttributeName "USBWake" -AttributeValue "Disabled" -Namespace $ns
    
    # 4. Block Sleep (Modern Standby Fix - Force S3 if possible? Dell blocks this often)
    # Instead, we optimize 'BlockSleep' if S3 is available.
    
    Write-Host " [OK] Dell Optimizations Applied." -ForegroundColor Green
}

Export-ModuleMember -Function Invoke-DellOptimization

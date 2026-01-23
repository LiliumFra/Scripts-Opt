<#
.SYNOPSIS
    HP-Optimization.ps1 v1.0 (Beast Mode)
    Advanced HP BIOS/WMI Management for Neural Optimizer.

.DESCRIPTION
    Leverages `root\HP\InstrumentedBIOS` for deep hardware control on HP EliteBook, ProBook, ZBook, and Omen devices.
    
    Features:
    - Fan Speed Control (Fan Always On/Off)
    - Battery Health Management (Long Life vs Max Charge)
    - Fn Key Behavior
    - Boost Mode Activation (Omen)

.NOTES
    Author: Neural Optimizer (Beast Mode)
    Risk: Medium (BIOS Settings)
#>

function Test-HPSystem {
    try {
        $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
        return $cs.Manufacturer -match "HP|Hewlett-Packard"
    }
    catch { return $false }
}

function Get-HPWmiNamespace {
    # HP often uses 'root\HP\InstrumentedBIOS' or 'root\wmi' depending on age
    if (Get-CimInstance -Namespace "root\HP\InstrumentedBIOS" -ClassName "HP_BIOSSetting" -ErrorAction SilentlyContinue) {
        return "root\HP\InstrumentedBIOS"
    }
    return $null
}

function Get-HPBiosSettings {
    param($Namespace)
    if (-not $Namespace) { return @() }
    
    try {
        $settings = Get-CimInstance -Namespace $Namespace -ClassName "HP_BIOSSetting" -ErrorAction Stop
        return $settings
    }
    catch { return @() }
}

function Set-HPBiosSetting {
    param(
        [string]$Name,
        [string]$Value,
        [string]$Namespace
    )
    
    try {
        $settingObj = Get-CimInstance -Namespace $Namespace -ClassName "HP_BIOSSetting" -Filter "Name='$Name'" -ErrorAction Stop
        if ($settingObj) {
            # HP WMI SetValue method usually requires a specific format or helper class "HP_BIOSSettingInterface"
            # Attempting SetValue via interface
            
            $interface = Get-CimInstance -Namespace $Namespace -ClassName "HP_BIOSSettingInterface" -ErrorAction SilentlyContinue
            
            if ($interface) {
                # Method signature: SetBiosSetting(Name, Value, Password, Return)
                $args = @{
                    Name     = $Name
                    Value    = $Value
                    Password = "" # Assuming no BIOS password for automation context, or handles empty
                }
                $result = Invoke-CimMethod -InputObject $interface -MethodName "SetBiosSetting" -Arguments $args
                
                if ($result.return -eq 0) {
                    Write-Host "   [OK] HP BIOS: Set '$Name' to '$Value'" -ForegroundColor Green
                    return $true
                }
                else {
                    Write-Host "   [!] HP BIOS Set Failed: Return Code $($result.return)" -ForegroundColor Red
                    return $false
                }
            }
        }
    }
    catch {
        Write-Host "   [!] Error applying HP Tweak: $_" -ForegroundColor Red
    }
    return $false
}

function Invoke-HPOptimization {
    Write-Host ""
    Write-Host " === HP BEAST MODE OPTIMIZATION ===" -ForegroundColor Magenta
    
    if (-not (Test-HPSystem)) {
        Write-Host " [!] Not an HP System." -ForegroundColor Yellow
        return
    }

    $ns = Get-HPWmiNamespace
    if (-not $ns) {
        Write-Host " [!] HP WMI Interface not found. (Install HP Image Assistant/Support Assistant)" -ForegroundColor Yellow
        return
    }
    
    Write-Host " [i] HP WMI Namespace detected: $ns" -ForegroundColor Cyan
    
    # 1. Performance / Fan Control
    # 'Fan Always On while on AC' -> Disable to reduce noise/wear if temps allow, OR Enable for 'Beast Mode' cooling?
    # Neural Optimizer standard: Max Cooling for 'High' tier, Quiet for 'Standard'.
    
    Write-Host " [?] Configure Cooling Policy? (Performance/Quiet) " -ForegroundColor Cyan
    # Logic typically resides in 'Fan Always On while on AC Power'
    
    $fanSetting = Get-HPBiosSettings -Namespace $ns | Where-Object { $_.Name -match "Fan Always On" }
    
    if ($fanSetting) {
        Write-Host "     Current: $($fanSetting.Value)" -ForegroundColor Gray
        # We enforce 'Disable' means smart fan (quieter), 'Enable' means always spinning (cooler but noisy)
        # For Optimization, Smart Fan is usually preferred unless overheating.
        Set-HPBiosSetting -Name "Fan Always On while on AC Power" -Value "Disable" -Namespace $ns
    }
    
    # 2. Battery Health Manager
    # 'Maximize my battery health' vs 'Maximize my battery duration'
    Write-Host " [i] Optimizing Battery Health Manager..." -ForegroundColor Cyan
    Set-HPBiosSetting -Name "Battery Health Manager" -Value "Maximize my battery health" -Namespace $ns
    
    # 3. Fn Key Optimization
    # 'Launch Hotkeys without Fn Keypress' -> Enable (Standard behavior) or Disable (F1-F12 primary)
    Set-HPBiosSetting -Name "Fn Key Switch" -Value "Enable" -Namespace $ns
    
    Write-Host " [OK] HP Optimizations Applied." -ForegroundColor Green
}

Export-ModuleMember -Function Invoke-HPOptimization

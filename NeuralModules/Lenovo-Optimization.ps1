<#
.SYNOPSIS
    Lenovo-Optimization.ps1 v2.0 - Advanced Lenovo WMI Tweaks

.DESCRIPTION
    Detects Lenovo systems and applies model-specific optimizations:
    - Legion: Hybrid Mode, GPU Overclock, OverDrive, Performance
    - ThinkPad: Fn Lock, Charge Threshold, TrackPoint
    - Universal: Thermal profiles, USB power, Battery conservation

.NOTES
    Part of Windows Neural Optimizer v6.1 ULTRA
    Author: Jose Bustamante
    Research: Lenovo WMI docs, Legion Toolkit, ThinkPad utilities
#>

# ============================================================================
# LENOVO DETECTION
# ============================================================================

function Test-LenovoSystem {
    try {
        $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
        return $cs.Manufacturer -match "LENOVO"
    }
    catch { return $false }
}

function Get-LenovoModel {
    try {
        $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
        $model = $cs.Model
        return @{
            Manufacturer = $cs.Manufacturer
            Model        = $model
            SystemFamily = $cs.SystemFamily
            IsThinkPad   = $model -match "ThinkPad"
            IsIdeaPad    = $model -match "IdeaPad"
            IsLegion     = $model -match "Legion"
            IsYoga       = $model -match "Yoga"
            IsLegionGo   = $model -match "Legion Go"
        }
    }
    catch { return $null }
}

function Test-LenovoWmiAvailable {
    try {
        $null = Get-CimInstance -Namespace root\wmi -ClassName Lenovo_BiosSetting -ErrorAction Stop
        return $true
    }
    catch { return $false }
}

function Get-LenovoBiosSettings {
    try {
        $settings = Get-CimInstance -Namespace root\wmi -ClassName Lenovo_BiosSetting -ErrorAction Stop
        $parsed = $settings | ForEach-Object {
            $parts = $_.CurrentSetting -split ','
            if ($parts.Count -ge 2) {
                @{ Name = $parts[0]; CurrentValue = $parts[1] }
            }
        }
        return $parsed | Where-Object { $_.Name }
    }
    catch { return @() }
}

function Set-LenovoBiosSetting {
    param([string]$SettingName, [string]$Value, [string]$BiosPassword = "")
    
    try {
        $setBios = Get-CimInstance -Namespace root\wmi -ClassName Lenovo_SetBiosSetting -ErrorAction Stop
        $setResult = $setBios | Invoke-CimMethod -MethodName SetBiosSetting -Arguments @{ parameter = "$SettingName,$Value" }
        
        if ($setResult.return -ne "Success") {
            Write-Host " [!] Failed: $SettingName -> $($setResult.return)" -ForegroundColor Red
            return $false
        }
        
        $saveBios = Get-CimInstance -Namespace root\wmi -ClassName Lenovo_SaveBiosSettings -ErrorAction Stop
        $saveArgs = @{ parameter = if ($BiosPassword) { "$BiosPassword,ascii,us" } else { "" } }
        $saveResult = $saveBios | Invoke-CimMethod -MethodName SaveBiosSettings -Arguments $saveArgs
        
        if ($saveResult.return -eq "Success") {
            Write-Host " [OK] $SettingName = $Value" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host " [!] Save failed: $($saveResult.return)" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host " [!] Error: $_" -ForegroundColor Red
        return $false
    }
}

# ============================================================================
# THERMAL PROFILES
# ============================================================================

function Get-ThermalProfile {
    $settings = Get-LenovoBiosSettings
    return @{
        AC      = ($settings | Where-Object { $_.Name -eq "AdaptiveThermalManagementAC" }).CurrentValue
        Battery = ($settings | Where-Object { $_.Name -eq "AdaptiveThermalManagementBattery" }).CurrentValue
    }
}

function Set-ThermalProfile {
    param(
        [ValidateSet("MaximizePerformance", "Balanced", "Cool")]
        [string]$ThermalMode,
        [ValidateSet("AC", "Battery", "Both")]
        [string]$PowerSource = "Both"
    )
    
    $success = $true
    if ($PowerSource -in @("AC", "Both")) {
        $success = $success -and (Set-LenovoBiosSetting -SettingName "AdaptiveThermalManagementAC" -Value $ThermalMode)
    }
    if ($PowerSource -in @("Battery", "Both")) {
        $success = $success -and (Set-LenovoBiosSetting -SettingName "AdaptiveThermalManagementBattery" -Value $ThermalMode)
    }
    return $success
}

# ============================================================================
# LEGION-SPECIFIC TWEAKS
# ============================================================================

function Set-LegionHybridMode {
    param([switch]$Disable)
    
    Write-Host ""
    if ($Disable) {
        Write-Host " [+] Disabling Hybrid Mode (dGPU Only)..." -ForegroundColor Cyan
        Set-LenovoBiosSetting -SettingName "HybridMode" -Value "Disable" | Out-Null
        Set-LenovoBiosSetting -SettingName "HybridModeSupport" -Value "Disable" | Out-Null
        Write-Host " [i] Restart required. Games will use dedicated GPU exclusively." -ForegroundColor Yellow
    }
    else {
        Write-Host " [+] Enabling Hybrid Mode..." -ForegroundColor Cyan
        Set-LenovoBiosSetting -SettingName "HybridMode" -Value "Enable" | Out-Null
        Set-LenovoBiosSetting -SettingName "HybridModeSupport" -Value "Enable" | Out-Null
        Write-Host " [i] Restart required. System will switch between GPUs." -ForegroundColor Yellow
    }
}

function Set-LegionGPUOverclock {
    param([switch]$Enable)
    
    Write-Host ""
    if ($Enable) {
        Write-Host " [+] Enabling GPU Overclock..." -ForegroundColor Cyan
        Set-LenovoBiosSetting -SettingName "GPUOverclock" -Value "Enable" | Out-Null
        Write-Host " [i] GPU boost enabled. May increase temperatures." -ForegroundColor Yellow
    }
    else {
        Write-Host " [+] Disabling GPU Overclock..." -ForegroundColor Cyan
        Set-LenovoBiosSetting -SettingName "GPUOverclock" -Value "Disable" | Out-Null
    }
}

function Set-LegionOverDrive {
    param([switch]$Enable)
    
    Write-Host ""
    if ($Enable) {
        Write-Host " [+] Enabling LCD OverDrive..." -ForegroundColor Cyan
        Set-LenovoBiosSetting -SettingName "OverDriveMode" -Value "Enable" | Out-Null
        Write-Host " [i] Faster pixel response. May cause minor ghosting." -ForegroundColor Yellow
    }
    else {
        Write-Host " [+] Disabling LCD OverDrive..." -ForegroundColor Cyan
        Set-LenovoBiosSetting -SettingName "OverDriveMode" -Value "Disable" | Out-Null
    }
}

function Set-LegionRapidCharge {
    param([switch]$Enable)
    
    if ($Enable) {
        Set-LenovoBiosSetting -SettingName "RapidChargeMode" -Value "Enable" | Out-Null
        Write-Host " Rapid Charge enabled" -ForegroundColor Green
    }
    else {
        Set-LenovoBiosSetting -SettingName "RapidChargeMode" -Value "Disable" | Out-Null
        Write-Host " Rapid Charge disabled" -ForegroundColor Yellow
    }
}

# ============================================================================
# THINKPAD-SPECIFIC TWEAKS
# ============================================================================

function Set-ThinkPadFnLock {
    param([switch]$Enable)
    
    if ($Enable) {
        Set-LenovoBiosSetting -SettingName "FnCtrlKeySwap" -Value "Enable" | Out-Null
        Write-Host " Fn Lock enabled (function keys default)" -ForegroundColor Green
    }
    else {
        Set-LenovoBiosSetting -SettingName "FnCtrlKeySwap" -Value "Disable" | Out-Null
        Write-Host " Fn Lock disabled (media keys default)" -ForegroundColor Yellow
    }
}

function Set-ThinkPadChargeThreshold {
    param([int]$StartPercent = 75, [int]$StopPercent = 80)
    
    Write-Host ""
    Write-Host " [+] Setting battery charge thresholds..." -ForegroundColor Cyan
    Set-LenovoBiosSetting -SettingName "ChargeStartThreshold" -Value $StartPercent | Out-Null
    Set-LenovoBiosSetting -SettingName "ChargeStopThreshold" -Value $StopPercent | Out-Null
    Write-Host " Battery will charge from $StartPercent% to $StopPercent% (prolongs battery life)" -ForegroundColor Green
}

function Set-ThinkPadTrackPointSpeed {
    param([ValidateSet("Low", "Medium", "High")][string]$Speed = "Medium")
    
    $value = switch ($Speed) { "Low" { "1" } "Medium" { "3" } "High" { "5" } }
    Set-LenovoBiosSetting -SettingName "TrackPointSpeed" -Value $value | Out-Null
    Write-Host " TrackPoint speed: $Speed" -ForegroundColor Green
}

# ============================================================================
# UNIVERSAL LENOVO TWEAKS
# ============================================================================

function Set-LenovoUSBAlwaysOn {
    param([switch]$Enable)
    
    if ($Enable) {
        Set-LenovoBiosSetting -SettingName "USBAlwaysOn" -Value "Enable" | Out-Null
        Write-Host " USB Always On enabled" -ForegroundColor Green
    }
    else {
        Set-LenovoBiosSetting -SettingName "USBAlwaysOn" -Value "Disable" | Out-Null
        Write-Host " USB Always On disabled" -ForegroundColor Yellow
    }
}

function Set-LenovoBatteryConservation {
    param([switch]$Enable)
    
    if ($Enable) {
        Set-LenovoBiosSetting -SettingName "BatteryConservationMode" -Value "Enable" | Out-Null
        Write-Host " Battery Conservation enabled (max 60% charge)" -ForegroundColor Green
    }
    else {
        Set-LenovoBiosSetting -SettingName "BatteryConservationMode" -Value "Disable" | Out-Null
        Write-Host " Battery Conservation disabled (full charge)" -ForegroundColor Yellow
    }
}

function Set-LenovoPerformanceMode {
    Write-Host ""
    Write-Host " [+] Configuring Maximum Performance Mode..." -ForegroundColor Cyan
    
    Set-ThermalProfile -ThermalMode "MaximizePerformance" -PowerSource "AC"
    Set-ThermalProfile -ThermalMode "Balanced" -PowerSource "Battery"
    Set-LenovoBiosSetting -SettingName "SpeedStep" -Value "Enable" | Out-Null
    Set-LenovoBiosSetting -SettingName "ProcessorPowerManagement" -Value "MaximumPerformance" | Out-Null
    
    Write-Host " [OK] Performance mode configured" -ForegroundColor Green
}

function Set-LenovoBatterySaver {
    Write-Host ""
    Write-Host " [+] Configuring Battery Saver Mode..." -ForegroundColor Cyan
    
    Set-ThermalProfile -ThermalMode "Cool" -PowerSource "Battery"
    Set-ThermalProfile -ThermalMode "Balanced" -PowerSource "AC"
    Set-LenovoBiosSetting -SettingName "BatteryConservationMode" -Value "Enable" | Out-Null
    
    Write-Host " [OK] Battery saver configured" -ForegroundColor Green
}

# ============================================================================
# MAIN MENU
# ============================================================================

function Show-LenovoOptimizationMenu {
    if (-not (Test-LenovoSystem)) {
        Write-Host ""
        Write-Host " [!] This module is only for Lenovo systems." -ForegroundColor Yellow
        Write-Host " [i] Your system: $((Get-CimInstance Win32_ComputerSystem).Manufacturer)" -ForegroundColor Gray
        return
    }
    
    $model = Get-LenovoModel
    $wmiAvailable = Test-LenovoWmiAvailable
    
    Clear-Host
    Write-Host ""
    Write-Host " === LENOVO OPTIMIZATION v2.0 ===" -ForegroundColor Magenta
    Write-Host ""
    Write-Host " Model: $($model.Model)" -ForegroundColor Cyan
    Write-Host " Type: $(if($model.IsLegion){'Legion'}elseif($model.IsThinkPad){'ThinkPad'}elseif($model.IsIdeaPad){'IdeaPad'}elseif($model.IsYoga){'Yoga'}else{'Lenovo'})" -ForegroundColor Gray
    Write-Host " WMI: $(if($wmiAvailable){'Available'}else{'Not Available'})" -ForegroundColor $(if ($wmiAvailable) { 'Green' }else { 'Yellow' })
    Write-Host ""
    
    if (-not $wmiAvailable) {
        Write-Host " [!] WMI interface not available." -ForegroundColor Yellow
        Write-Host " Install Lenovo Vantage or update BIOS." -ForegroundColor Gray
        Read-Host " Press ENTER"
        return
    }
    
    $thermal = Get-ThermalProfile
    Write-Host " Thermal: AC=$($thermal.AC), Battery=$($thermal.Battery)" -ForegroundColor Gray
    Write-Host ""
    Write-Host " === POWER PROFILES ===" -ForegroundColor White
    Write-Host " 1. Maximum Performance Mode"
    Write-Host " 2. Balanced Mode"
    Write-Host " 3. Battery Saver Mode"
    Write-Host ""
    
    if ($model.IsLegion) {
        Write-Host " === LEGION GAMING ===" -ForegroundColor Red
        Write-Host " 4. Toggle Hybrid Mode (dGPU/iGPU)"
        Write-Host " 5. Toggle GPU Overclock"
        Write-Host " 6. Toggle LCD OverDrive"
        Write-Host " 7. Toggle Rapid Charge"
        Write-Host ""
    }
    
    if ($model.IsThinkPad) {
        Write-Host " === THINKPAD ===" -ForegroundColor Blue
        Write-Host " 4. Toggle Fn Lock"
        Write-Host " 5. Set Charge Threshold (75-80%)"
        Write-Host " 6. TrackPoint Speed"
        Write-Host ""
    }
    
    Write-Host " === UNIVERSAL ===" -ForegroundColor Gray
    Write-Host " 8. Toggle USB Always On"
    Write-Host " 9. Toggle Battery Conservation"
    Write-Host " 10. View All BIOS Settings"
    Write-Host ""
    Write-Host " 0. Back"
    Write-Host ""
    
    $choice = Read-Host " >> Option"
    
    switch ($choice) {
        '1' { Set-LenovoPerformanceMode; Read-Host " Press ENTER" }
        '2' { Set-ThermalProfile -ThermalMode "Balanced" -PowerSource "Both"; Read-Host " Press ENTER" }
        '3' { Set-LenovoBatterySaver; Read-Host " Press ENTER" }
        '4' {
            if ($model.IsLegion) {
                $hybrid = Read-Host " Disable Hybrid Mode for pure dGPU? (Y/N)"
                if ($hybrid -match "^[Yy]") { Set-LegionHybridMode -Disable } else { Set-LegionHybridMode }
            }
            elseif ($model.IsThinkPad) {
                Set-ThinkPadFnLock -Enable
            }
            Read-Host " Press ENTER"
        }
        '5' {
            if ($model.IsLegion) {
                $oc = Read-Host " Enable GPU Overclock? (Y/N)"
                if ($oc -match "^[Yy]") { Set-LegionGPUOverclock -Enable } else { Set-LegionGPUOverclock }
            }
            elseif ($model.IsThinkPad) {
                Set-ThinkPadChargeThreshold -StartPercent 75 -StopPercent 80
            }
            Read-Host " Press ENTER"
        }
        '6' {
            if ($model.IsLegion) {
                $od = Read-Host " Enable LCD OverDrive? (Y/N)"
                if ($od -match "^[Yy]") { Set-LegionOverDrive -Enable } else { Set-LegionOverDrive }
            }
            elseif ($model.IsThinkPad) {
                Set-ThinkPadTrackPointSpeed -Speed "High"
            }
            Read-Host " Press ENTER"
        }
        '7' {
            if ($model.IsLegion) {
                $rc = Read-Host " Enable Rapid Charge? (Y/N)"
                if ($rc -match "^[Yy]") { Set-LegionRapidCharge -Enable } else { Set-LegionRapidCharge }
            }
            Read-Host " Press ENTER"
        }
        '8' {
            $usb = Read-Host " Enable USB Always On? (Y/N)"
            if ($usb -match "^[Yy]") { Set-LenovoUSBAlwaysOn -Enable } else { Set-LenovoUSBAlwaysOn }
            Read-Host " Press ENTER"
        }
        '9' {
            $bc = Read-Host " Enable Battery Conservation? (Y/N)"
            if ($bc -match "^[Yy]") { Set-LenovoBatteryConservation -Enable } else { Set-LenovoBatteryConservation }
            Read-Host " Press ENTER"
        }
        '10' {
            Write-Host ""
            Write-Host " === ALL BIOS SETTINGS ===" -ForegroundColor Cyan
            Get-LenovoBiosSettings | ForEach-Object { Write-Host " $($_.Name): $($_.CurrentValue)" -ForegroundColor Gray }
            Read-Host " Press ENTER"
        }
        '0' { return }
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    Show-LenovoOptimizationMenu
}

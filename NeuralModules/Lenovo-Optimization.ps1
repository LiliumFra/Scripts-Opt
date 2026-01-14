<#
.SYNOPSIS
    Lenovo-Optimization.ps1 - Lenovo-specific optimizations via WMI

.DESCRIPTION
    Detects Lenovo systems and applies vendor-specific optimizations.

.NOTES
    Part of Windows Neural Optimizer v6.1
    Author: Jose Bustamante
#>

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
        return @{
            Manufacturer = $cs.Manufacturer
            Model        = $cs.Model
            IsThinkPad   = $cs.Model -match "ThinkPad"
            IsIdeaPad    = $cs.Model -match "IdeaPad"
            IsLegion     = $cs.Model -match "Legion"
            IsYoga       = $cs.Model -match "Yoga"
        }
    }
    catch { return $null }
}

function Test-LenovoWmiAvailable {
    try {
        $settings = Get-CimInstance -Namespace root\wmi -ClassName Lenovo_BiosSetting -ErrorAction Stop
        return ($null -ne $settings -and $settings.Count -gt 0)
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
    catch {
        Write-Host " [!] Error reading Lenovo BIOS: $_" -ForegroundColor Red
        return @()
    }
}

function Set-LenovoBiosSetting {
    param([string]$SettingName, [string]$Value, [string]$BiosPassword = "")
    
    try {
        $setBios = Get-CimInstance -Namespace root\wmi -ClassName Lenovo_SetBiosSetting -ErrorAction Stop
        $setResult = $setBios | Invoke-CimMethod -MethodName SetBiosSetting -Arguments @{ parameter = "$SettingName,$Value" }
        
        if ($setResult.return -ne "Success") {
            Write-Host " [!] Failed to set $SettingName" -ForegroundColor Red
            return $false
        }
        
        $saveBios = Get-CimInstance -Namespace root\wmi -ClassName Lenovo_SaveBiosSettings -ErrorAction Stop
        $saveArgs = @{ parameter = if ($BiosPassword) { "$BiosPassword,ascii,us" } else { "" } }
        $saveResult = $saveBios | Invoke-CimMethod -MethodName SaveBiosSettings -Arguments $saveArgs
        
        if ($saveResult.return -eq "Success") {
            Write-Host " [OK] $SettingName set to $Value" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host " [!] Failed to save settings" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host " [!] Error setting BIOS: $_" -ForegroundColor Red
        return $false
    }
}

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
    if ($PowerSource -eq "AC" -or $PowerSource -eq "Both") {
        $result = Set-LenovoBiosSetting -SettingName "AdaptiveThermalManagementAC" -Value $ThermalMode
        $success = $success -and $result
    }
    if ($PowerSource -eq "Battery" -or $PowerSource -eq "Both") {
        $result = Set-LenovoBiosSetting -SettingName "AdaptiveThermalManagementBattery" -Value $ThermalMode
        $success = $success -and $result
    }
    return $success
}

function Set-PerformanceMode {
    Write-Host ""
    Write-Host " [+] Configuring Lenovo Performance Mode..." -ForegroundColor Cyan
    Set-LenovoBiosSetting -SettingName "SpeedStep" -Value "Enable" | Out-Null
    Set-ThermalProfile -ThermalMode "MaximizePerformance" -PowerSource "AC"
    Set-ThermalProfile -ThermalMode "Balanced" -PowerSource "Battery"
    Write-Host " [OK] Performance mode configured" -ForegroundColor Green
}

function Set-BatterySaverMode {
    Write-Host ""
    Write-Host " [+] Configuring Lenovo Battery Saver..." -ForegroundColor Cyan
    Set-ThermalProfile -ThermalMode "Cool" -PowerSource "Battery"
    Set-ThermalProfile -ThermalMode "Balanced" -PowerSource "AC"
    Set-LenovoBiosSetting -SettingName "BatteryConservationMode" -Value "Enable" | Out-Null
    Write-Host " [OK] Battery saver configured" -ForegroundColor Green
}

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
    Write-Host " === LENOVO OPTIMIZATION MODULE ===" -ForegroundColor Magenta
    Write-Host ""
    Write-Host " Detected: $($model.Model)" -ForegroundColor Cyan
    Write-Host " WMI Available: $wmiAvailable" -ForegroundColor $(if ($wmiAvailable) { 'Green' } else { 'Yellow' })
    Write-Host ""
    
    if (-not $wmiAvailable) {
        Write-Host " [!] WMI interface not available." -ForegroundColor Yellow
        Read-Host " Press ENTER"
        return
    }
    
    $thermal = Get-ThermalProfile
    Write-Host " Current Thermal: AC=$($thermal.AC), Battery=$($thermal.Battery)" -ForegroundColor Gray
    Write-Host ""
    Write-Host " 1. Performance Mode"
    Write-Host " 2. Balanced Mode"
    Write-Host " 3. Battery Saver"
    Write-Host " 4. View All Settings"
    Write-Host " 5. Back"
    Write-Host ""
    
    $choice = Read-Host " >> Option"
    
    switch ($choice) {
        '1' { Set-PerformanceMode; Read-Host " Press ENTER" }
        '2' { Set-ThermalProfile -ThermalMode "Balanced" -PowerSource "Both"; Read-Host " Press ENTER" }
        '3' { Set-BatterySaverMode; Read-Host " Press ENTER" }
        '4' {
            Write-Host ""
            Write-Host " === LENOVO BIOS SETTINGS ===" -ForegroundColor Cyan
            Get-LenovoBiosSettings | ForEach-Object { Write-Host " $($_.Name): $($_.CurrentValue)" }
            Read-Host " Press ENTER"
        }
        '5' { return }
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    Show-LenovoOptimizationMenu
}

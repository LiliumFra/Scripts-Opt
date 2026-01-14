<#
.SYNOPSIS
    Neural Update Manager v6.5
    Advanced Windows Update control and management.

.DESCRIPTION
    Features:
    - Defer Feature Updates (up to 365 days)
    - Defer Quality Updates (up to 30 days)
    - Disable Auto-Reboot after updates
    - Pause Updates instantly
    - Block Driver Updates via Windows Update
    - Disable Delivery Optimization P2P
    - Metered Connection Mode

.NOTES
    Parte de Windows Neural Optimizer v6.5 ULTRA
    Creditos: Jose Bustamante
    Inspirado en: Chris Titus WinUtil, Sophia Script
#>

if (-not (Get-Command "Write-Log" -ErrorAction SilentlyContinue)) {
    $currentDir = Split-Path $MyInvocation.MyCommand.Path
    $utilsPath = Join-Path $currentDir "NeuralUtils.psm1"
    if (Test-Path $utilsPath) { Import-Module $utilsPath -Force -DisableNameChecking }
}

Invoke-AdminCheck -Silent

# ============================================================================
# CORE FUNCTIONS
# ============================================================================

function Show-UpdateMenu {
    Clear-Host
    Write-Host ""
    Write-Host " â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—" -ForegroundColor Cyan
    Write-Host " â•‘  NEURAL UPDATE MANAGER v6.5                           â•‘" -ForegroundColor Cyan
    Write-Host " â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—" -ForegroundColor Gray
    Write-Host " â•‘ 1. Aplicar ConfiguraciÃ³n Recomendada                  â•‘" -ForegroundColor White
    Write-Host " â•‘    (Diferir features 365d, quality 7d, sin auto-reboot)â•‘" -ForegroundColor DarkGray
    Write-Host " â•‘                                                       â•‘" -ForegroundColor Gray
    Write-Host " â•‘ 2. Pausar Updates (35 dÃ­as)                           â•‘" -ForegroundColor White
    Write-Host " â•‘ 3. Reanudar Updates                                   â•‘" -ForegroundColor White
    Write-Host " â•‘ 4. Bloquear Drivers via Windows Update                â•‘" -ForegroundColor White
    Write-Host " â•‘ 5. Desbloquear Drivers via Windows Update             â•‘" -ForegroundColor White
    Write-Host " â•‘ 6. Deshabilitar Auto-Reboot                           â•‘" -ForegroundColor White
    Write-Host " â•‘ 7. Deshabilitar Delivery Optimization (P2P)           â•‘" -ForegroundColor White
    Write-Host " â•‘                                                       â•‘" -ForegroundColor Gray
    Write-Host " â•‘ 0. Volver                                             â•‘" -ForegroundColor DarkGray
    Write-Host " â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•" -ForegroundColor Gray
    Write-Host ""
    
    return Read-Host " >> OpciÃ³n"
}

function Set-RecommendedUpdatePolicy {
    Write-Section "CONFIGURACION RECOMENDADA DE UPDATES"
    
    $wuPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
    $auPath = "$wuPath\AU"
    
    # Ensure paths exist
    if (-not (Test-Path $wuPath)) { New-Item -Path $wuPath -Force | Out-Null }
    if (-not (Test-Path $auPath)) { New-Item -Path $auPath -Force | Out-Null }
    
    Write-Step "[1/4] DIFERIR FEATURE UPDATES (365 dÃ­as)"
    Set-RegistryKey -Path $wuPath -Name "DeferFeatureUpdates" -Value 1 -Desc "Defer Feature Updates ON"
    Set-RegistryKey -Path $wuPath -Name "DeferFeatureUpdatesPeriodInDays" -Value 365 -Desc "Defer Period: 365 days"
    
    Write-Step "[2/4] DIFERIR QUALITY UPDATES (7 dÃ­as)"
    Set-RegistryKey -Path $wuPath -Name "DeferQualityUpdates" -Value 1 -Desc "Defer Quality Updates ON"
    Set-RegistryKey -Path $wuPath -Name "DeferQualityUpdatesPeriodInDays" -Value 7 -Desc "Defer Period: 7 days"
    
    Write-Step "[3/4] DESHABILITAR AUTO-REBOOT"
    Set-RegistryKey -Path $auPath -Name "NoAutoRebootWithLoggedOnUsers" -Value 1 -Desc "No Auto-Reboot with Users"
    Set-RegistryKey -Path $auPath -Name "AUOptions" -Value 4 -Desc "Auto Download, Notify Install"
    
    Write-Step "[4/4] DESHABILITAR DELIVERY OPTIMIZATION P2P"
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DODownloadMode" -Value 0 -Desc "P2P Delivery OFF"
    
    Write-Host ""
    Write-Host " [OK] ConfiguraciÃ³n recomendada aplicada." -ForegroundColor Green
    Write-Host ""
}

function Set-PauseUpdates {
    param([int]$Days = 35)
    
    Write-Section "PAUSAR UPDATES"
    
    $pauseUntil = (Get-Date).AddDays($Days).ToString("yyyy-MM-ddTHH:mm:ssZ")
    
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseUpdatesExpiryTime" -Value $pauseUntil -Type String -Desc "Pause Until: $pauseUntil"
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseFeatureUpdatesStartTime" -Value (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ") -Type String -Desc "Pause Start"
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseQualityUpdatesStartTime" -Value (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ") -Type String -Desc "Pause Start"
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseFeatureUpdatesEndTime" -Value $pauseUntil -Type String -Desc "Feature Pause End"
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseQualityUpdatesEndTime" -Value $pauseUntil -Type String -Desc "Quality Pause End"
    
    Write-Host ""
    Write-Host " [OK] Updates pausados por $Days dÃ­as." -ForegroundColor Green
    Write-Host ""
}

function Set-ResumeUpdates {
    Write-Section "REANUDAR UPDATES"
    
    $settingsPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
    
    try {
        Remove-ItemProperty -Path $settingsPath -Name "PauseUpdatesExpiryTime" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $settingsPath -Name "PauseFeatureUpdatesStartTime" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $settingsPath -Name "PauseQualityUpdatesStartTime" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $settingsPath -Name "PauseFeatureUpdatesEndTime" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $settingsPath -Name "PauseQualityUpdatesEndTime" -ErrorAction SilentlyContinue
        
        Write-Host " [OK] Updates reanudados." -ForegroundColor Green
    }
    catch {
        Write-Host " [!] Error: $_" -ForegroundColor Yellow
    }
    Write-Host ""
}

function Set-BlockDriverUpdates {
    Write-Section "BLOQUEAR DRIVERS VIA WINDOWS UPDATE"
    
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "ExcludeWUDriversInQualityUpdate" -Value 1 -Desc "Exclude Drivers from WU"
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" -Name "SearchOrderConfig" -Value 0 -Desc "Driver Search: Local Only"
    
    Write-Host ""
    Write-Host " [OK] Drivers bloqueados de Windows Update." -ForegroundColor Green
    Write-Host ""
}

function Set-UnblockDriverUpdates {
    Write-Section "DESBLOQUEAR DRIVERS VIA WINDOWS UPDATE"
    
    try {
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "ExcludeWUDriversInQualityUpdate" -ErrorAction SilentlyContinue
        Set-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" -Name "SearchOrderConfig" -Value 1 -Desc "Driver Search: Online"
        
        Write-Host ""
        Write-Host " [OK] Drivers desbloqueados." -ForegroundColor Green
    }
    catch {}
    Write-Host ""
}

function Set-DisableAutoReboot {
    Write-Section "DESHABILITAR AUTO-REBOOT"
    
    $auPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
    if (-not (Test-Path $auPath)) { New-Item -Path $auPath -Force | Out-Null }
    
    Set-RegistryKey -Path $auPath -Name "NoAutoRebootWithLoggedOnUsers" -Value 1 -Desc "No Auto-Reboot"
    Set-RegistryKey -Path $auPath -Name "AlwaysAutoRebootAtScheduledTime" -Value 0 -Desc "Scheduled Reboot OFF"
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" -Name "AUOptions" -Value 2 -Desc "Notify before download"
    
    Write-Host ""
    Write-Host " [OK] Auto-Reboot deshabilitado." -ForegroundColor Green
    Write-Host ""
}

function Set-DisableDeliveryOptimization {
    Write-Section "DESHABILITAR DELIVERY OPTIMIZATION"
    
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DODownloadMode" -Value 0 -Desc "P2P OFF (Local Only)"
    
    try {
        Stop-Service -Name "DoSvc" -Force -ErrorAction SilentlyContinue
        Set-Service -Name "DoSvc" -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host "   [OK] Servicio DoSvc detenido y deshabilitado" -ForegroundColor Green
    }
    catch {}
    
    Write-Host ""
    Write-Host " [OK] Delivery Optimization deshabilitada." -ForegroundColor Green
    Write-Host ""
}

# ============================================================================
# MAIN LOOP
# ============================================================================

while ($true) {
    $choice = Show-UpdateMenu
    
    switch ($choice) {
        '1' { Set-RecommendedUpdatePolicy; Wait-ForKeyPress }
        '2' { Set-PauseUpdates -Days 35; Wait-ForKeyPress }
        '3' { Set-ResumeUpdates; Wait-ForKeyPress }
        '4' { Set-BlockDriverUpdates; Wait-ForKeyPress }
        '5' { Set-UnblockDriverUpdates; Wait-ForKeyPress }
        '6' { Set-DisableAutoReboot; Wait-ForKeyPress }
        '7' { Set-DisableDeliveryOptimization; Wait-ForKeyPress }
        '0' { exit 0 }
        default { Write-Host " [!] OpciÃ³n invÃ¡lida" -ForegroundColor Red; Start-Sleep -Seconds 1 }
    }
}


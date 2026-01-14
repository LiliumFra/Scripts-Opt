<#
.SYNOPSIS
    Neural Performance Extreme v6.5
    Advanced low-level performance optimizations inspired by AtlasOS & ReviOS.

.DESCRIPTION
    Extreme Features (USE WITH CAUTION):
    - Timer Resolution Enhancement (1ms precision)
    - CPU Power States Optimization (C-States)
    - CPU Mitigations Toggle (Spectre/Meltdown)
    - DPC/ISR Latency Optimization
    - NTFS Performance Tweaks
    - Power Throttling Disable
    - Background Apps Control
    - Search Indexing Control

.NOTES
    Parte de Windows Neural Optimizer v6.5 ULTRA
    Creditos: Jose Bustamante
    Inspirado en: AtlasOS, ReviOS, Sophia Script
    
    ADVERTENCIA: Algunas optimizaciones reducen seguridad del sistema.
    Use solo si entiende los riesgos.
#>

if (-not (Get-Command "Write-Log" -ErrorAction SilentlyContinue)) {
    $currentDir = Split-Path $MyInvocation.MyCommand.Path
    $utilsPath = Join-Path $currentDir "NeuralUtils.psm1"
    if (Test-Path $utilsPath) { Import-Module $utilsPath -Force -DisableNameChecking }
}

Invoke-AdminCheck -Silent

# ============================================================================
# MAIN FUNCTION
# ============================================================================

function Show-ExtremeMenu {
    Clear-Host
    Write-Host ""
    Write-Host " â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—" -ForegroundColor Red
    Write-Host " â•‘  NEURAL PERFORMANCE EXTREME v6.5                      â•‘" -ForegroundColor Red
    Write-Host " â•‘  >> Optimizaciones avanzadas de bajo nivel <<         â•‘" -ForegroundColor Yellow
    Write-Host " â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•" -ForegroundColor Red
    Write-Host ""
    Write-Host " > [!] ADVERTENCIA: Estas opciones pueden afectar estabilidad" -ForegroundColor Yellow
    Write-Host " > [!] o seguridad. Crea un punto de restauraciÃ³n primero." -ForegroundColor Yellow
    Write-Host ""
    Write-Host " â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—" -ForegroundColor Gray
    Write-Host " â•‘ [PERFORMANCE]                                         â•‘" -ForegroundColor Magenta
    Write-Host " â•‘ 1. Timer Resolution (1ms Precision)                   â•‘" -ForegroundColor White
    Write-Host " â•‘ 2. CPU Power States (C-States Optimization)           â•‘" -ForegroundColor White
    Write-Host " â•‘ 3. Power Throttling Disable                           â•‘" -ForegroundColor White
    Write-Host " â•‘ 4. DPC/ISR Latency Optimization                       â•‘" -ForegroundColor White
    Write-Host " â•‘                                                       â•‘" -ForegroundColor Gray
    Write-Host " â•‘ [SECURITY TRADE-OFFS]                                 â•‘" -ForegroundColor Red
    Write-Host " â•‘ 5. CPU Mitigations Toggle (Spectre/Meltdown)          â•‘" -ForegroundColor Red
    Write-Host " â•‘                                                       â•‘" -ForegroundColor Gray
    Write-Host " â•‘ [SYSTEM OPTIMIZATION]                                 â•‘" -ForegroundColor Green
    Write-Host " â•‘ 6. NTFS Performance Tweaks                            â•‘" -ForegroundColor White
    Write-Host " â•‘ 7. Background Apps Control                            â•‘" -ForegroundColor White
    Write-Host " â•‘ 8. Search Indexing Control                            â•‘" -ForegroundColor White
    Write-Host " â•‘ 9. Apply ALL Safe Optimizations                       â•‘" -ForegroundColor Cyan
    Write-Host " â•‘                                                       â•‘" -ForegroundColor Gray
    Write-Host " â•‘ 0. Volver                                             â•‘" -ForegroundColor DarkGray
    Write-Host " â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•" -ForegroundColor Gray
    Write-Host ""
    
    return Read-Host " >> OpciÃ³n"
}

# ============================================================================
# INDIVIDUAL OPTIMIZATION FUNCTIONS
# ============================================================================

function Set-TimerResolution {
    Write-Section "TIMER RESOLUTION ENHANCEMENT"
    
    Write-Host " [i] El Timer Resolution afecta la precisiÃ³n de temporizadores." -ForegroundColor Cyan
    Write-Host " [i] Valores mÃ¡s bajos = mayor precisiÃ³n pero mÃ¡s consumo de CPU." -ForegroundColor DarkGray
    Write-Host ""
    
    Write-Host " [!] Esto requiere la herramienta 'TimerResolution' o 'ISLC'." -ForegroundColor Yellow
    Write-Host "     Puedes configurar vÃ­a registro para que apps puedan solicitar 1ms." -ForegroundColor DarkGray
    
    # Enable global timer resolution requests
    Set-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" -Name "GlobalTimerResolutionRequests" -Value 1 -Desc "Global Timer Resolution Requests ON"
    
    # Multimedia scheduling for better timer behavior
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 0 -Desc "System Responsiveness: Gaming Mode"
    
    Write-Host ""
    Write-Host " [OK] Timer Resolution configurado." -ForegroundColor Green
    Write-Host " [TIP] Usa ISLC (Intelligent Standby List Cleaner) para forzar 0.5ms." -ForegroundColor Cyan
    Write-Host ""
}

function Set-CPUPowerStates {
    Write-Section "CPU POWER STATES (C-STATES)"
    
    Write-Host " [i] C-States son estados de ahorro de energÃ­a del CPU." -ForegroundColor Cyan
    Write-Host " [i] Deshabilitarlos reduce latencia pero aumenta consumo/temperatura." -ForegroundColor DarkGray
    Write-Host ""
    
    Write-Host " [?] Â¿Optimizar C-States para mÃ­nima latencia?" -ForegroundColor Yellow
    Write-Host "     (Recomendado solo para PCs de escritorio con buena refrigeraciÃ³n)" -ForegroundColor DarkGray
    $choice = Read-Host "   >> (S/N)"
    
    if ($choice -match "^[Ss]") {
        # Processor power settings subgroup GUID
        $subProc = "54533251-82be-4824-96c1-47b60b740d00"
        
        try {
            # Minimum processor state to 100% (never idle)
            powercfg -setacvalueindex scheme_current $subProc PROCTHROTTLEMIN 100
            Write-Host "   [OK] Min Processor State: 100%" -ForegroundColor Green
            
            # Idle Sensitivity
            # GUID: 4d2b0152-7d5c-498b-88e2-34345392a2c5
            powercfg -setacvalueindex scheme_current $subProc 4d2b0152-7d5c-498b-88e2-34345392a2c5 0
            Write-Host "   [OK] Processor Idle Sensitivity: OFF" -ForegroundColor Green
            
            # Core Parking - Min Cores 100%
            # GUID: 0cc5b647-c1df-4637-891a-dec35c318583
            powercfg -setacvalueindex scheme_current $subProc 0cc5b647-c1df-4637-891a-dec35c318583 100
            Write-Host "   [OK] Core Parking: Disabled (100% cores active)" -ForegroundColor Green
            
            powercfg -setactive scheme_current
            
            Write-Host ""
            Write-Host " [OK] C-States optimizadas para mÃ¡ximo rendimiento." -ForegroundColor Green
        }
        catch {
            Write-Host " [X] Error configurando C-States." -ForegroundColor Red
        }
    }
    else {
        Write-Host " [--] C-States no modificadas." -ForegroundColor DarkGray
    }
    Write-Host ""
}

function Set-PowerThrottling {
    Write-Section "POWER THROTTLING DISABLE"
    
    Write-Host " [i] Power Throttling reduce rendimiento de apps en segundo plano." -ForegroundColor Cyan
    Write-Host " [i] Deshabilitarlo mantiene todas las apps a mÃ¡xima velocidad." -ForegroundColor DarkGray
    Write-Host ""
    
    Set-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" -Name "PowerThrottlingOff" -Value 1 -Desc "Power Throttling OFF"
    
    Write-Host ""
    Write-Host " [OK] Power Throttling deshabilitado." -ForegroundColor Green
    Write-Host ""
}

function Set-DPCLatency {
    Write-Section "DPC/ISR LATENCY OPTIMIZATION"
    
    Write-Host " [i] Optimiza Deferred Procedure Calls para menor latencia." -ForegroundColor Cyan
    Write-Host ""
    
    $latencyKeys = @(
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel"; Name = "DpcWatchdogProfileOffset"; Value = 0; Desc = "DPC Watchdog Offset" },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel"; Name = "DpcTimeout"; Value = 0; Desc = "DPC Timeout" },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel"; Name = "IdealDpcRate"; Value = 1; Desc = "Ideal DPC Rate" },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel"; Name = "MaxDynamicTickDuration"; Value = 10; Desc = "Max Dynamic Tick" },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel"; Name = "MaximumDpcQueueDepth"; Value = 1; Desc = "Max DPC Queue Depth" },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel"; Name = "MinimumDpcRate"; Value = 1; Desc = "Min DPC Rate" },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel"; Name = "ThreadDpcEnable"; Value = 1; Desc = "Thread DPC Enable" }
    )
    
    foreach ($k in $latencyKeys) {
        Set-RegistryKey -Path $k.Path -Name $k.Name -Value $k.Value -Desc $k.Desc
    }
    
    Write-Host ""
    Write-Host " [OK] DPC/ISR Latency optimizada." -ForegroundColor Green
    Write-Host " [TIP] Usa LatencyMon para verificar mejoras." -ForegroundColor Cyan
    Write-Host ""
}

function Set-CPUMitigations {
    Write-Section "CPU MITIGATIONS (Spectre/Meltdown)"
    
    Write-Host ""
    Write-Host " â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—" -ForegroundColor Red
    Write-Host " â•‘  âš ï¸  ADVERTENCIA DE SEGURIDAD                        â•‘" -ForegroundColor Red
    Write-Host " â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•" -ForegroundColor Red
    Write-Host ""
    Write-Host " [!] Las mitigaciones protegen contra vulnerabilidades de CPU." -ForegroundColor Yellow
    Write-Host " [!] Deshabilitarlas puede mejorar rendimiento 5-20% en CPUs antiguos," -ForegroundColor Yellow
    Write-Host "     pero deja el sistema vulnerable a ataques Spectre/Meltdown." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host " [?] Estado actual de mitigaciones:" -ForegroundColor Cyan
    
    # Check current status
    $specStatus = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "FeatureSettingsOverride" -ErrorAction SilentlyContinue
    
    if ($specStatus.FeatureSettingsOverride -eq 3) {
        Write-Host "     >> Mitigations: DISABLED" -ForegroundColor Yellow
    }
    else {
        Write-Host "     >> Mitigations: ENABLED (Secure)" -ForegroundColor Green
    }
    Write-Host ""
    
    Write-Host " [1] Deshabilitar mitigaciones (mÃ¡s rendimiento, menos seguridad)"
    Write-Host " [2] Habilitar mitigaciones (seguro, recomendado)"
    Write-Host " [0] Cancelar"
    $choice = Read-Host " >> OpciÃ³n"
    
    switch ($choice) {
        '1' {
            Set-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "FeatureSettingsOverride" -Value 3 -Desc "Mitigations OFF"
            Set-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "FeatureSettingsOverrideMask" -Value 3 -Desc "Mitigations Mask"
            Write-Host ""
            Write-Host " [!] Mitigaciones DESHABILITADAS. Reinicio requerido." -ForegroundColor Yellow
        }
        '2' {
            Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "FeatureSettingsOverride" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "FeatureSettingsOverrideMask" -ErrorAction SilentlyContinue
            Write-Host ""
            Write-Host " [OK] Mitigaciones HABILITADAS (seguro)." -ForegroundColor Green
        }
        default {
            Write-Host " [--] Cancelado." -ForegroundColor DarkGray
        }
    }
    Write-Host ""
}

function Set-NTFSPerformance {
    Write-Section "NTFS PERFORMANCE TWEAKS"
    
    Write-Host " [i] Optimiza el sistema de archivos NTFS para mejor rendimiento." -ForegroundColor Cyan
    Write-Host ""
    
    # Disable 8.3 filename creation
    try {
        fsutil behavior set disable8dot3 1 | Out-Null
        Write-Host "   [OK] 8.3 Filename Creation: Disabled" -ForegroundColor Green
    }
    catch {}
    
    # Disable last access timestamp
    try {
        fsutil behavior set disablelastaccess 1 | Out-Null
        Write-Host "   [OK] Last Access Timestamp: Disabled" -ForegroundColor Green
    }
    catch {}
    
    # Increase NTFS memory usage
    Set-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "NtfsMemoryUsage" -Value 2 -Desc "NTFS Memory: Maximum"
    Set-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "NtfsDisableLastAccessUpdate" -Value 1 -Desc "Last Access Update OFF"
    Set-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "NtfsDisable8dot3NameCreation" -Value 1 -Desc "8.3 Names OFF"
    
    Write-Host ""
    Write-Host " [OK] NTFS optimizado." -ForegroundColor Green
    Write-Host ""
}

function Set-BackgroundApps {
    Write-Section "BACKGROUND APPS CONTROL"
    
    Write-Host " [i] Controla quÃ© apps pueden ejecutarse en segundo plano." -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host " [1] Deshabilitar TODAS las apps en segundo plano"
    Write-Host " [2] Permitir apps en segundo plano (default)"
    Write-Host " [0] Cancelar"
    $choice = Read-Host " >> OpciÃ³n"
    
    switch ($choice) {
        '1' {
            Set-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1 -Desc "Background Apps OFF"
            Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsRunInBackground" -Value 2 -Desc "Apps Background: Deny"
            Write-Host ""
            Write-Host " [OK] Apps en segundo plano DESHABILITADAS." -ForegroundColor Green
        }
        '2' {
            Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -ErrorAction SilentlyContinue
            Write-Host ""
            Write-Host " [OK] Apps en segundo plano PERMITIDAS." -ForegroundColor Green
        }
        default {
            Write-Host " [--] Cancelado." -ForegroundColor DarkGray
        }
    }
    Write-Host ""
}

function Set-SearchIndexing {
    Write-Section "SEARCH INDEXING CONTROL"
    
    Write-Host " [i] Windows Search Indexer consume recursos para indexar archivos." -ForegroundColor Cyan
    Write-Host " [i] Deshabilitarlo acelera el sistema pero ralentiza bÃºsquedas." -ForegroundColor DarkGray
    Write-Host ""
    
    $service = Get-Service -Name "WSearch" -ErrorAction SilentlyContinue
    
    if ($service) {
        Write-Host " [?] Estado actual: $($service.Status)" -ForegroundColor Cyan
        Write-Host ""
        
        Write-Host " [1] Deshabilitar Windows Search Indexer"
        Write-Host " [2] Habilitar Windows Search Indexer"
        Write-Host " [0] Cancelar"
        $choice = Read-Host " >> OpciÃ³n"
        
        switch ($choice) {
            '1' {
                Stop-Service -Name "WSearch" -Force -ErrorAction SilentlyContinue
                Set-Service -Name "WSearch" -StartupType Disabled
                Write-Host ""
                Write-Host " [OK] Windows Search Indexer DESHABILITADO." -ForegroundColor Green
            }
            '2' {
                Set-Service -Name "WSearch" -StartupType Automatic
                Start-Service -Name "WSearch" -ErrorAction SilentlyContinue
                Write-Host ""
                Write-Host " [OK] Windows Search Indexer HABILITADO." -ForegroundColor Green
            }
            default {
                Write-Host " [--] Cancelado." -ForegroundColor DarkGray
            }
        }
    }
    Write-Host ""
}

function Invoke-AllSafeOptimizations {
    Write-Section "APLICANDO OPTIMIZACIONES SEGURAS"
    
    Write-Host " [i] Aplicando solo optimizaciones sin riesgo de seguridad..." -ForegroundColor Cyan
    Write-Host ""
    
    Set-TimerResolution
    Set-PowerThrottling
    Set-DPCLatency
    Set-NTFSPerformance
    
    Write-Host ""
    Write-Host " +--------------------------------------------------------+" -ForegroundColor Green
    Write-Host " |  OPTIMIZACIONES SEGURAS COMPLETADAS                    |" -ForegroundColor Green
    Write-Host " +--------------------------------------------------------+" -ForegroundColor Green
    Write-Host ""
}

# ============================================================================
# MAIN LOOP
# ============================================================================

while ($true) {
    $choice = Show-ExtremeMenu
    
    switch ($choice) {
        '1' { Set-TimerResolution; Wait-ForKeyPress }
        '2' { Set-CPUPowerStates; Wait-ForKeyPress }
        '3' { Set-PowerThrottling; Wait-ForKeyPress }
        '4' { Set-DPCLatency; Wait-ForKeyPress }
        '5' { Set-CPUMitigations; Wait-ForKeyPress }
        '6' { Set-NTFSPerformance; Wait-ForKeyPress }
        '7' { Set-BackgroundApps; Wait-ForKeyPress }
        '8' { Set-SearchIndexing; Wait-ForKeyPress }
        '9' { Invoke-AllSafeOptimizations; Wait-ForKeyPress }
        '0' { exit 0 }
        default { Write-Host " [!] OpciÃ³n invÃ¡lida" -ForegroundColor Red; Start-Sleep -Seconds 1 }
    }
}


<#
.SYNOPSIS
    Advanced Gaming Optimization v5.0 ULTRA
    Optimizaciones extremas para gaming competitivo y streaming.

.DESCRIPTION
    Nuevas características:
    - MSI Mode para GPU/dispositivos (Interrupt optimization)
    - HPET disable para mejor frame timing
    - Process affinity automation
    - GPU Clock optimization
    - Advanced network stack tuning
    - Competitive gaming presets
    - Streaming optimization

.NOTES
    Parte de Windows Neural Optimizer v5.0
    Creditos: Jose Bustamante
#>

if (-not (Get-Command "Write-Log" -ErrorAction SilentlyContinue)) {
    $currentDir = Split-Path $MyInvocation.MyCommand.Path
    $utilsPath = Join-Path $currentDir "NeuralUtils.psm1"
    if (Test-Path $utilsPath) { Import-Module $utilsPath -Force -DisableNameChecking }
}

Invoke-AdminCheck -Silent

# ============================================================================
# ADVANCED INTERRUPT OPTIMIZATION (MSI MODE)
# ============================================================================

function Enable-MSIMode {
    [CmdletBinding()]
    param()
    
    Write-Step "[ULTRA] MSI MODE - INTERRUPT OPTIMIZATION"
    
    Write-Host " [i] MSI Mode reduce latencia de interrupciones en GPU y dispositivos" -ForegroundColor Cyan
    Write-Host " [i] Esto mejora significativamente frame-time consistency" -ForegroundColor Cyan
    Write-Host ""
    
    $devices = Get-PnpDevice | Where-Object { 
        $_.Status -eq "OK" -and 
        ($_.Class -match "Display|USB|Network|Sound|HDC") 
    }
    
    $msiEnabled = 0
    
    foreach ($device in $devices) {
        try {
            # Get device registry path
            $instanceId = $device.InstanceId
            $regPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$instanceId\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
            
            if (Test-Path $regPath) {
                $current = Get-ItemProperty -Path $regPath -Name "MSISupported" -ErrorAction SilentlyContinue
                
                if ($current.MSISupported -ne 1) {
                    Set-ItemProperty -Path $regPath -Name "MSISupported" -Value 1 -Type DWord -Force
                    Write-Host "   [OK] MSI habilitado: $($device.FriendlyName)" -ForegroundColor Green
                    $msiEnabled++
                }
            }
        }
        catch {}
    }
    
    Write-Host ""
    Write-Host " [OK] MSI Mode configurado en $msiEnabled dispositivos" -ForegroundColor Green
    Write-Host " [!] REINICIO REQUERIDO para aplicar cambios" -ForegroundColor Yellow
    Write-Host ""
}

# ============================================================================
# HPET OPTIMIZATION (High Precision Event Timer)
# ============================================================================

function Optimize-HPET {
    [CmdletBinding()]
    param()
    
    Write-Step "[ULTRA] HPET OPTIMIZATION"
    
    Write-Host " [i] Deshabilitando HPET para mejor frame timing..." -ForegroundColor Cyan
    Write-Host " [i] HPET puede causar micro-stuttering en algunos sistemas" -ForegroundColor DarkGray
    Write-Host ""
    
    try {
        # Disable HPET in BCD
        $null = & bcdedit /deletevalue useplatformclock 2>&1
        Write-Host "   [OK] HPET deshabilitado en BCD" -ForegroundColor Green
        
        # Disable in registry
        Set-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Services\HPET" `
            -Name "Start" -Value 4 -Desc "HPET Service Disabled"
        
        Write-Host ""
        Write-Host " [OK] HPET optimization completa" -ForegroundColor Green
        Write-Host " [!] REINICIO REQUERIDO" -ForegroundColor Yellow
    }
    catch {
        Write-Host " [!] Error optimizando HPET" -ForegroundColor Yellow
    }
    Write-Host ""
}

# ============================================================================
# PROCESS AFFINITY & PRIORITY AUTOMATION
# ============================================================================

function Set-GameProcessOptimization {
    [CmdletBinding()]
    param()
    
    Write-Step "[ULTRA] PROCESS OPTIMIZATION"
    
    Write-Host " [i] Configurando optimizaciones automáticas para procesos de juegos..." -ForegroundColor Cyan
    Write-Host ""
    
    # Common game process patterns
    $gameProcesses = @(
        "*.exe",  # Generic games
        "steam.exe",
        "EpicGamesLauncher.exe",
        "Origin.exe",
        "Uplay.exe",
        "Battle.net.exe"
    )
    
    # Registry path for process priority
    $imagePath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options"
    
    $configured = 0
    
    foreach ($proc in $gameProcesses) {
        $procPath = Join-Path $imagePath $proc
        
        try {
            if (-not (Test-Path $procPath)) {
                New-Item -Path $procPath -Force | Out-Null
            }
            
            # Set CPU Priority to High (Value: 3 = High Priority)
            New-ItemProperty -Path $procPath -Name "PriorityClass" -Value 3 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
            Set-ItemProperty -Path $procPath -Name "PriorityClass" -Value 3 -Force -ErrorAction SilentlyContinue
            
            # Set I/O Priority to High (Value: 3 = High)
            New-ItemProperty -Path $procPath -Name "IoPriority" -Value 3 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
            Set-ItemProperty -Path $procPath -Name "IoPriority" -Value 3 -Force -ErrorAction SilentlyContinue
            
            $configured++
        }
        catch {}
    }
    
    Write-Host "   [OK] $configured patrones de procesos configurados" -ForegroundColor Green
    Write-Host ""
}

# ============================================================================
# GPU CLOCK OPTIMIZATION
# ============================================================================

function Optimize-GPUClocks {
    [CmdletBinding()]
    param()
    
    Write-Step "[ULTRA] GPU CLOCK OPTIMIZATION"
    
    $hw = Get-HardwareProfile
    
    # NVIDIA Specific
    if ($hw.GpuVendor -eq "NVIDIA") {
        Write-Host " [i] Optimizando NVIDIA GPU..." -ForegroundColor Cyan
        
        $nvidiaKeys = @(
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"; Name = "PreferSystemMemoryContiguous"; Value = 1; Desc = "Memory Contiguous" },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"; Name = "TCCSupported"; Value = 0; Desc = "TCC Mode OFF (Gaming)" },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"; Name = "EnableAsyncMidBufferPreemption"; Value = 0; Desc = "Async Preemption OFF" },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"; Name = "EnableMidGfxPreemption"; Value = 0; Desc = "Mid-GFX Preemption OFF" },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"; Name = "EnableMidBufferPreemption"; Value = 0; Desc = "Mid-Buffer Preemption OFF" },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"; Name = "EnableCEPreemption"; Value = 0; Desc = "CE Preemption OFF" },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"; Name = "PerfLevelSrc"; Value = 0x3333; Desc = "Performance Level ULTRA" },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"; Name = "D3PCLatency"; Value = 1; Desc = "D3 Power Latency Min" },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"; Name = "F1TransitionLatency"; Value = 1; Desc = "F1 Transition Min" },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"; Name = "LOWLATENCY"; Value = 1; Desc = "Low Latency Mode" },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"; Name = "Node3DLowLatency"; Value = 1; Desc = "3D Low Latency" },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"; Name = "RMDeepL1EntryLatencyUsec"; Value = 1; Desc = "Deep L1 Latency" }
        )
        
        foreach ($k in $nvidiaKeys) {
            if (Test-Path $k.Path) {
                Set-RegistryKey -Path $k.Path -Name $k.Name -Value $k.Value -Desc $k.Desc -Rollback
            }
        }
    }
    
    # AMD Specific
    if ($hw.GpuVendor -eq "AMD") {
        Write-Host " [i] Optimizando AMD GPU..." -ForegroundColor Cyan
        
        $amdKeys = @(
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"; Name = "KMD_DeLagEnabled"; Value = 1; Desc = "Anti-Lag Enabled" },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"; Name = "KMD_FRTEnabled"; Value = 0; Desc = "Frame Rate Target OFF" },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"; Name = "DisableSAMUPowerGating"; Value = 1; Desc = "SAMU Power Gating OFF" },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"; Name = "DisableUVDPowerGatingDynamic"; Value = 1; Desc = "UVD Dynamic PG OFF" },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"; Name = "DisableVCEPowerGating"; Value = 1; Desc = "VCE Power Gating OFF" },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"; Name = "PP_ThermalAutoThrottlingEnable"; Value = 0; Desc = "Thermal Throttling OFF" }
        )
        
        foreach ($k in $amdKeys) {
            if (Test-Path $k.Path) {
                Set-RegistryKey -Path $k.Path -Name $k.Name -Value $k.Value -Desc $k.Desc -Rollback
            }
        }
    }
    
    Write-Host ""
}


function Optimize-Streaming {
    [CmdletBinding()]
    param()
    
    Write-Step "[ULTRA] STREAMING OPTIMIZATION"
    
    Write-Host " [i] Optimizando para streaming (OBS, XSplit, etc.)..." -ForegroundColor Cyan
    Write-Host ""
    
    # NVENC/AMD VCE optimization
    $hw = Get-HardwareProfile
    
    if ($hw.GpuVendor -eq "NVIDIA") {
        # NVENC Priority
        Set-RegistryKey -Path "HKLM:\SOFTWARE\NVIDIA Corporation\Global\NvEncoder" `
            -Name "EnableAsyncQueue" -Value 1 -Desc "NVENC Async Queue" -Rollback

        Set-RegistryKey -Path "HKLM:\SOFTWARE\NVIDIA Corporation\Global\NvEncoder" `
            -Name "MaxSessionCount" -Value 10 -Desc "NVENC Max Sessions" -Rollback
    }

    # Audio buffer optimization (Network limits handled in Network-Optimizer)
    $mmPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"

    # Audio buffer optimization
    Set-RegistryKey -Path "$mmPath\Tasks\Audio" -Name "Priority" -Value 2 -Desc "Audio Priority" -Rollback
    Set-RegistryKey -Path "$mmPath\Tasks\Audio" -Name "Scheduling Category" -Value "High" -Type String -Desc "Audio Scheduling" -Rollback

    Write-Host " [OK] Streaming optimization completa" -ForegroundColor Green
    Write-Host ""
}

# ============================================================================
# FRAMETIME CONSISTENCY
# ============================================================================

function Optimize-FrameTiming {
    [CmdletBinding()]
    param()
    
    Write-Step "[ULTRA] FRAME TIMING OPTIMIZATION"
    
    Write-Host " [i] Optimizando para frame-time consistency..." -ForegroundColor Cyan
    Write-Host ""
    
    # Disable Windows DWM optimizations (can cause stutter)
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" `
        -Name "OverlayTestMode" -Value 5 -Desc "DWM Overlay Mode" -Rollback
    
    # GPU Preemption
    Set-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Scheduler" `
        -Name "EnablePreemption" -Value 0 -Desc "GPU Preemption OFF" -Rollback
    
    # Disable VSync in DWM for borderless fullscreen
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" `
        -Name "OverlayTestMode" -Value 5 -Desc "DWM Test Mode" -Rollback
    
    Write-Host " [OK] Frame timing optimizado" -ForegroundColor Green
    Write-Host ""
}

# ============================================================================
# ANTI-CHEAT COMPATIBILITY CHECK
# ============================================================================

function Test-AntiCheatCompatibility {
    Write-Host ""
    Write-Host " +========================================================+" -ForegroundColor Yellow
    Write-Host " |  ADVERTENCIA: ANTI-CHEAT COMPATIBILITY                |" -ForegroundColor Yellow
    Write-Host " +========================================================+" -ForegroundColor Yellow
    Write-Host ""
    Write-Host " Algunas optimizaciones pueden ser detectadas por:" -ForegroundColor Yellow
    Write-Host "   - Valorant (Vanguard)" -ForegroundColor Gray
    Write-Host "   - Rainbow Six Siege (BattlEye)" -ForegroundColor Gray
    Write-Host "   - PUBG, Escape from Tarkov, etc." -ForegroundColor Gray
    Write-Host ""
    Write-Host " Si juegas juegos con anti-cheat agresivo:" -ForegroundColor Yellow
    Write-Host "   1. Haz backup antes de optimizar" -ForegroundColor Gray
    Write-Host "   2. Usa el sistema de rollback si tienes problemas" -ForegroundColor Gray
    Write-Host "   3. Considera usar optimizaciones 'conservadoras'" -ForegroundColor Gray
    Write-Host ""
    
    $response = Read-Host " >> ¿Continuar con optimizaciones ULTRA? (SI/NO)"
    
    if ($response -ne "SI") {
        Write-Host " [i] Optimizaciones canceladas." -ForegroundColor Yellow
        return $false
    }
    
    return $true
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

function Start-AdvancedGamingOptimization {
    Write-Section "ADVANCED GAMING OPTIMIZATION v5.0 ULTRA"
    
    $hw = Get-HardwareProfile
    Show-HardwareInfo -Hardware $hw
    
    # Anti-cheat warning
    if (-not (Test-AntiCheatCompatibility)) {
        return
    }
    
    Write-Host ""
    Write-Host " [+] Iniciando optimizaciones ULTRA..." -ForegroundColor Cyan
    Write-Host ""
    
    # Execute optimizations
    Enable-MSIMode
    Optimize-HPET
    Set-GameProcessOptimization
    Optimize-GPUClocks
    # Network optimized in Network-Optimizer.ps1
    Optimize-Streaming
    Optimize-FrameTiming
    
    # Summary
    Write-Host ""
    Write-Host " +========================================================+" -ForegroundColor Green
    Write-Host " |  ADVANCED GAMING OPTIMIZATION COMPLETADA               |" -ForegroundColor Green
    Write-Host " +========================================================+" -ForegroundColor Green
    Write-Host ""
    Write-Host " CAMBIOS APLICADOS:" -ForegroundColor Cyan
    Write-Host "   ✓ MSI Mode habilitado en dispositivos" -ForegroundColor Gray
    Write-Host "   ✓ HPET optimizado" -ForegroundColor Gray
    Write-Host "   ✓ Process priority automation" -ForegroundColor Gray
    Write-Host "   ✓ GPU clocks optimizados" -ForegroundColor Gray
    Write-Host "   ✓ Streaming optimization" -ForegroundColor Gray
    Write-Host "   ✓ Frame timing mejorado" -ForegroundColor Gray
    Write-Host ""
    Write-Host " [!] REINICIO REQUERIDO para aplicar todos los cambios" -ForegroundColor Yellow
    Write-Host ""
    Write-Host " BENCHMARKS RECOMENDADOS:" -ForegroundColor Cyan
    Write-Host "   - 3DMark Time Spy" -ForegroundColor Gray
    Write-Host "   - LatencyMon (DPC Latency)" -ForegroundColor Gray
    Write-Host "   - NVIDIA FrameView / PresentMon" -ForegroundColor Gray
    Write-Host ""
}

Start-AdvancedGamingOptimization
Wait-ForKeyPress

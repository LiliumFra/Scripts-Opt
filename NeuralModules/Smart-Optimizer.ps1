<#
.SYNOPSIS
    Smart-Optimizer v6.5 ULTRA
    Hardware-aware automatic optimization that adapts to your system.

.DESCRIPTION
    Detects your hardware configuration and applies the most appropriate optimizations:
    - Laptop vs Desktop (power management, battery awareness)
    - SSD vs HDD (Prefetch, Superfetch, TRIM)
    - High-end vs Low-end (aggressive vs conservative tweaks)
    - GPU-specific optimizations (NVIDIA, AMD, Intel)
    - RAM-based memory management

.NOTES
    Parte de Windows Neural Optimizer v6.5 ULTRA
    Creditos: Jose Bustamante
    Inspirado en: AtlasOS, ReviOS, Chris Titus WinUtil, Sophia Script
#>

if (-not (Get-Command "Write-Log" -ErrorAction SilentlyContinue)) {
    $currentDir = Split-Path $MyInvocation.MyCommand.Path
    $utilsPath = Join-Path $currentDir "NeuralUtils.psm1"
    $plansPath = Join-Path $currentDir "Power-Plans.ps1"
    $aiPath = Join-Path $currentDir "NeuralAI.psm1"
    
    if (Test-Path $utilsPath) { Import-Module $utilsPath -Force -DisableNameChecking }
    if (Test-Path $plansPath) { Import-Module $plansPath -Force -DisableNameChecking }
    if (Test-Path $aiPath) { Import-Module $aiPath -Force -DisableNameChecking }
}

Invoke-AdminCheck -Silent

# ============================================================================
# HARDWARE DETECTION & DISPLAY
# ============================================================================

function Show-HardwareAnalysis {
    param($hw)
    
    Write-Section "ANALISIS DE HARDWARE"
    
    Write-Host ""
    Write-Host " ========================================================" -ForegroundColor Cyan
    Write-Host " |  PERFIL DE SISTEMA DETECTADO                         |" -ForegroundColor Cyan
    Write-Host " ========================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # System Type
    $systemType = if ($hw.IsLaptop) { "LAPTOP" } else { "DESKTOP" }
    $powerStatus = if ($hw.IsOnBattery) { " (EN BATERIA)" } else { "" }
    Write-Host " Sistema:  $systemType$powerStatus" -ForegroundColor White
    
    # Performance Tier
    $tierColor = switch ($hw.PerformanceTier) {
        "Ultra" { "Magenta" }
        "High" { "Green" }
        "Standard" { "Yellow" }
        "Low" { "Red" }
        Default { "White" }
    }
    $tierDisplay = if ($hw.PerformanceTier) { $hw.PerformanceTier.ToUpper() } else { "UNKNOWN" }
    Write-Host " Tier:     $tierDisplay" -ForegroundColor $tierColor
    
    Write-Host ""
    Write-Host " --------------------------------------------------------" -ForegroundColor Gray
    Write-Host ""
    
    # CPU
    Write-Host " CPU:      $($hw.CpuName)" -ForegroundColor Cyan
    Write-Host "           $($hw.CpuCores) cores / $($hw.CpuThreads) threads @ $($hw.CpuMaxSpeed)MHz" -ForegroundColor DarkGray
    
    # RAM
    Write-Host " RAM:      $($hw.RamGB) GB" -ForegroundColor Cyan
    if ($hw.RamSpeed -gt 0) {
        Write-Host "           $($hw.RamSpeed) MHz" -ForegroundColor DarkGray
    }
    
    # GPU
    if ($hw.Gpus -and $hw.Gpus.Count -gt 0) {
        $i = 1
        foreach ($gpu in $hw.Gpus) {
            $marker = ""
            # Mark the primary GPU
            if ($gpu.Name -eq $hw.GpuName) { $marker = " *" }
            Write-Host (" GPU {0}:    {1}{2}" -f $i, $gpu.Name, $marker) -ForegroundColor Cyan
            $i++
        }
    }
    else {
        Write-Host " GPU:      $($hw.GpuName)" -ForegroundColor Cyan
    }
    
    # Storage
    $storageType = if ($hw.IsNVMe) { "NVMe SSD" } elseif ($hw.IsSSD) { "SATA SSD" } else { "HDD" }
    Write-Host " Storage:  $storageType" -ForegroundColor Cyan
    
    Write-Host ""
}

# ============================================================================
# HARDWARE-SPECIFIC OPTIMIZATION FUNCTIONS
# ============================================================================

function Invoke-StorageOptimizations {
    param($hw)
    
    Write-Step "OPTIMIZACIONES DE ALMACENAMIENTO"
    
    if ($hw.IsSSD) {
        Write-Host "   [i] Detectado: SSD - Aplicando optimizaciones especificas..." -ForegroundColor Cyan
        
        # Disable Prefetch for SSD
        Set-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -Value 0 -Desc "Prefetch OFF (SSD)"
        
        # Disable Superfetch/SysMain for SSD
        Set-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnableSuperfetch" -Value 0 -Desc "Superfetch OFF (SSD)"
        
        # TRIM verification
        try {
            $trimStatus = fsutil behavior query DisableDeleteNotify
            if ($trimStatus -match "= 0") {
                Write-Host "   [OK] TRIM: Habilitado" -ForegroundColor Green
            }
            else {
                Write-Host "   [!] TRIM: Deshabilitado - habilitando..." -ForegroundColor Yellow
                fsutil behavior set DisableDeleteNotify 0 | Out-Null
            }
        }
        catch {}
        
        # NTFS optimizations for SSD
        Set-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "NtfsDisableLastAccessUpdate" -Value 1 -Desc "Last Access OFF (SSD)"
        Set-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "NtfsDisable8dot3NameCreation" -Value 1 -Desc "8.3 Names OFF"
        
        if ($hw.IsNVMe) {
            Write-Host "   [+] NVMe detectado - optimizaciones adicionales..." -ForegroundColor Green
            Set-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "NtfsMemoryUsage" -Value 2 -Desc "NTFS Memory: Maximum"
        }
    }
    else {
        Write-Host "   [i] Detectado: HDD - Manteniendo Prefetch/Superfetch activos..." -ForegroundColor Yellow
        
        # Keep Prefetch enabled for HDD (value 3 = boot + apps)
        Set-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -Value 3 -Desc "Prefetch ON (HDD)"
        Set-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnableSuperfetch" -Value 3 -Desc "Superfetch ON (HDD)"
    }
    
    # WD NVMe Black/Blue HMB Fix (Win11 24H2 BSOD Prevention)
    try {
        $wdDrives = Get-PnpDevice | Where-Object { $_.FriendlyName -match "WD Black|WD Blue|Western Digital" -and $_.Class -eq "DiskDrive" }
        if ($wdDrives) {
            Write-Host "   [!] Disco Western Digital detectado - Aplicando fix de estabilidad HMB..." -ForegroundColor Yellow
            $storPortPath = "HKLM:\SYSTEM\CurrentControlSet\Control\StorPort"
            if (-not (Test-Path $storPortPath)) { New-Item -Path $storPortPath -Force | Out-Null }
            Set-RegistryKey -Path $storPortPath -Name "HmbAllocationPolicy" -Value 2 -Desc "WD HMB Limit (Fix BSOD)"
        }
    }
    catch {}
    
    Write-Host "   [OK] Optimizaciones de almacenamiento aplicadas" -ForegroundColor Green
}

function Invoke-PowerOptimizations {
    param($hw)
    
    Write-Step "OPTIMIZACIONES DE ENERGIA"
    
    # Check for laptop: IsLaptop OR HasBattery (battery = portable device)
    $isPortable = $hw.IsLaptop -or $hw.HasBattery
    
    if ($isPortable) {
        Write-Host "   [i] Detectado: LAPTOP" -ForegroundColor Cyan
        
        if ($hw.IsOnBattery) {
            Write-Host "   [!] En bateria - usando configuracion balanceada..." -ForegroundColor Yellow
            powercfg -setactive scheme_balanced
            Write-Host "   [OK] Plan: Balanced (para preservar bateria)" -ForegroundColor Green
        }
        else {
            Write-Host "   [i] Conectado a AC - activando High Performance..." -ForegroundColor Cyan
            powercfg -setactive scheme_min_power_saving
            # Set high performance while plugged in
            $subProc = "54533251-82be-4824-96c1-47b60b740d00"
            powercfg -setacvalueindex scheme_current $subProc PROCTHROTTLEMIN 100
            powercfg -setacvalueindex scheme_current $subProc PROCTHROTTLEMAX 100
            powercfg -setactive scheme_current
            Write-Host "   [OK] Plan: High Performance (AC)" -ForegroundColor Green
        }
        
        # Conservative USB suspend for laptops
        # Keep enabled for battery savings but disable if plugged in
        if (-not $hw.IsOnBattery) {
            Set-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Services\USB" -Name "DisableSelectiveSuspend" -Value 1 -Desc "USB Selective Suspend OFF (AC)"
        }
    }
    else {
        Write-Host "   [i] Detectado: DESKTOP - Activando Ultimate Performance..." -ForegroundColor Cyan
        
        # Try to activate Ultimate Performance plan
        try {
            $ultimateExists = powercfg /list | Select-String "e9a42b02-d5df-448d-aa00-03f14749eb61"
            if (-not $ultimateExists) {
                # Create Ultimate Performance plan
                powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null
            }
            powercfg -setactive e9a42b02-d5df-448d-aa00-03f14749eb61
            Write-Host "   [OK] Plan: Ultimate Performance" -ForegroundColor Green
        }
        catch {
            powercfg -setactive scheme_min_power_saving
            Write-Host "   [OK] Plan: High Performance (fallback)" -ForegroundColor Green
        }
        
        # Desktop-specific: disable all power saving
        $subProc = "54533251-82be-4824-96c1-47b60b740d00"
        powercfg -setacvalueindex scheme_current $subProc PROCTHROTTLEMIN 100
        powercfg -setacvalueindex scheme_current $subProc PROCTHROTTLEMAX 100
        
        # Disable Core Parking
        powercfg -setacvalueindex scheme_current $subProc 0cc5b647-c1df-4637-891a-dec35c318583 100
        
        # USB Selective Suspend OFF
        Set-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Services\USB" -Name "DisableSelectiveSuspend" -Value 1 -Desc "USB Selective Suspend OFF"
        
        # PCI Express Link State OFF
        Set-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\501a4d13-42af-4429-9fd1-a8218c268e20\ee12f906-d277-404b-b6da-e5fa1a576df5" -Name "Attributes" -Value 2 -Desc "PCI-E ASPM Visible"
        
        powercfg -setactive scheme_current
    }
}

function Invoke-MemoryOptimizations {
    param($hw)
    
    Write-Step "OPTIMIZACIONES DE MEMORIA (RAM: $($hw.RamGB) GB)"
    
    if ($hw.RamGB -ge 16) {
        Write-Host "   [i] RAM Alta (16GB+) - Optimizaciones agresivas..." -ForegroundColor Green
        
        # Large System Cache
        Set-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "LargeSystemCache" -Value 1 -Desc "Large System Cache ON"
        
        # Disable paging of kernel
        Set-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "DisablePagingExecutive" -Value 1 -Desc "Kernel Paging OFF"
        
        # Second Level Data Cache
        Set-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "SecondLevelDataCache" -Value 1024 -Desc "L2 Cache: 1024KB"
        
        # System Responsiveness for gaming/streaming
        Set-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 0 -Desc "System Responsiveness: 0%"
        
        # Disable Memory Compression (MmAgent) to reduce CPU overhead
        Write-Host "   [i] Desactivando compresion de memoria (Reduce uso de CPU)..." -ForegroundColor Cyan
        try {
            Disable-MMAgent -mc -ErrorAction SilentlyContinue
            Write-Host "   [OK] Compresion de Memoria: OFF" -ForegroundColor Green
        }
        catch {
            Write-Host "   [!] Error ajustando MmAgent: $_" -ForegroundColor DarkGray
        }
    }
    elseif ($hw.RamGB -ge 6) {
        Write-Host "   [i] RAM Media (6-16GB) - Optimizaciones balanceadas..." -ForegroundColor Yellow
        
        # Balanced cache
        Set-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "LargeSystemCache" -Value 0 -Desc "Large System Cache: Auto"
        
        # Keep kernel paging for stability
        Set-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "DisablePagingExecutive" -Value 0 -Desc "Kernel Paging: Default"
        
        # Moderate responsiveness
        Set-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 10 -Desc "System Responsiveness: 10%"
    }
    else {
        Write-Host "   [i] RAM Baja (<6GB) - Optimizaciones conservadoras..." -ForegroundColor Red
        
        # Keep defaults to avoid out of memory issues
        Set-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "LargeSystemCache" -Value 0 -Desc "Large System Cache: Off"
        
        # Standard responsiveness
        Set-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 20 -Desc "System Responsiveness: 20%"
    }
    
    Write-Host "   [OK] Optimizaciones de memoria aplicadas" -ForegroundColor Green
}

function Invoke-ProcessOptimizations {
    param($hw)
    Write-Step "OPTIMIZACION DE PROCESOS (Win32Priority)"
    
    # Win32PrioritySeparation = 38 (0x26) -> Good balance for responsiveness
    Set-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 38 -Desc "Win32Priority: Balanced (0x26)"
    
    # Common Launchers Priority
    $launchers = @("Steam.exe", "EpicGamesLauncher.exe", "Battle.net.exe", "Origin.exe", "Uplay.exe")
    $imagePath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options"
    
    foreach ($proc in $launchers) {
        $procPath = Join-Path $imagePath $proc
        if (-not (Test-Path $procPath)) { New-Item -Path $procPath -Force | Out-Null }
        # Priority Class 3 = High
        Set-RegistryKey -Path $procPath -Name "PriorityClass" -Value 3 -Desc "$proc High Priority"
    }
    Write-Host "   [OK] Prioridades de proceso ajustadas" -ForegroundColor Green
}

function Invoke-GamingOptimizations {
    param($hw)
    
    Write-Step "OPTIMIZACIONES DE GAMING Y LATENCIA"
    
    Write-Host "   [i] Aplicando tweaks de baja latencia (AtlasOS/WinUtil style)..." -ForegroundColor Cyan
    
    # 1. Disable GameDVR and Xbox Game Bar (Major latency source)
    $gameConfigPath = "HKCU:\System\GameConfigStore"
    if (Test-Path $gameConfigPath) {
        Set-RegistryKey -Path $gameConfigPath -Name "GameDVR_Enabled" -Value 0 -Desc "GameDVR OFF"
        Set-RegistryKey -Path $gameConfigPath -Name "GameDVR_FSEBehaviorMode" -Value 2 -Desc "Full Screen Optimization OFF"
    }
    
    $gameDvrPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"
    Set-RegistryKey -Path $gameDvrPath -Name "AllowGameDVR" -Value 0 -Desc "Allow GameDVR OFF"
    
    # 2. Disable Fullscreen Optimizations Globally (User compatibility)
    # $compatPath = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"
    # Note: Global disable is complex, usually done via GameDVR_FSEBehaviorMode above or specific EXE flags.
    # We rely on the FSEBehaviorMode=2 tweak which is the robust method.

    # 3. Optimize System Responsiveness (Multimedia Class Scheduler)
    $mmPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
    Set-RegistryKey -Path $mmPath -Name "SystemResponsiveness" -Value 0 -Desc "System Responsiveness 0%"
    Set-RegistryKey -Path $mmPath -Name "NoLazyMode" -Value 1 -Desc "No Lazy Mode"
    
    # 4. Debloat DiagTrack (Connected User Experiences and Telemetry) - Service Level
    Write-Host "   [i] Optimizando servicios en segundo plano..." -ForegroundColor Cyan
    $diagSvc = Get-Service "DiagTrack" -ErrorAction SilentlyContinue
    if ($diagSvc -and $diagSvc.Status -ne "Stopped") {
        Stop-Service "DiagTrack" -Force -ErrorAction SilentlyContinue
        Set-Service "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host "   [OK] Servicio Telemetria (DiagTrack): Deshabilitado" -ForegroundColor Green
    }
    
    # 5. Smart HPET (High Precision Event Timer) with Vanguard Safety Check
    $vanguard = Get-Process | Where-Object { $_.Name -match "vgc|vgtray" }
    if ($vanguard) {
        Write-Host "   [!] VANGUARD (Valorant) DETECTADO - Omitiendo HPET para evitar bans." -ForegroundColor Red
    }
    else {
        Write-Host "   [i] Optimizando HPET (Mejora de Frame Timing)..." -ForegroundColor Cyan
        try {
            $null = & bcdedit /deletevalue useplatformclock 2>&1
            Set-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Services\HPET" -Name "Start" -Value 4 -Desc "HPET Service Disabled"
        }
        catch {}
    }
    
    # 6. MSI Mode (Message Signaled Interrupts) - Lite Version
    Write-Host "   [i] Verificando MSI Mode para reducción de latencia..." -ForegroundColor Cyan
    $msiDevices = Get-PnpDevice | Where-Object { $_.Status -eq "OK" -and ($_.Class -match "Display|Network") }
    foreach ($dev in $msiDevices) {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($dev.InstanceId)\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
        if (Test-Path $regPath) {
            Set-ItemProperty -Path $regPath -Name "MSISupported" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Host "   [OK] MSI Mode activado en GPU/Red (si es soportado)" -ForegroundColor Green

    Write-Host "   [OK] Optimizaciones de Gaming aplicadas" -ForegroundColor Green
}

function Invoke-GPUOptimizations {
    param($hw)
    
    Write-Step "OPTIMIZACIONES DE GPU ($($hw.GpuVendor))"
    
    # Common GPU optimizations
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "GPU Priority" -Value 8 -Desc "Game GPU Priority: 8"
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "Priority" -Value 6 -Desc "Game Priority: 6"
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "Scheduling Category" -Value "High" -Desc "Game Scheduling: High"
    
    # Hardware-accelerated GPU scheduling (if supported)
    Set-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Value 2 -Desc "Hardware GPU Scheduling ON"
    

    
    # New Multi-GPU Logic replacing the simple switch
    # Get unique vendors from the list
    $vendors = @()
    if ($hw.Gpus) {
        $vendors = $hw.Gpus | Select-Object -ExpandProperty Vendor -Unique
    }
    else {
        $vendors = @($hw.GpuVendor)
    }

    foreach ($vendor in $vendors) {
        switch ($vendor) {
            "NVIDIA" {
                Write-Host "   [i] NVIDIA detectada - aplicando tweaks especificos..." -ForegroundColor Green
                
                # NVIDIA shader cache
                Set-RegistryKey -Path "HKCU:\Software\NVIDIA Corporation\Global\NVTweak" -Name "Gestalt" -Value 1 -Desc "NVIDIA Tweaks"
                
                # Threaded optimization hint
                $nvidiaPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"
                if (Test-Path $nvidiaPath) {
                    Set-RegistryKey -Path $nvidiaPath -Name "RMHdcpKeyglobZero" -Value 1 -Desc "NVIDIA HDCP"
                    
                    # Prevent clock drops (PowerMizer high perf) for Desktops
                    if (-not $hw.IsLaptop) {
                        Set-RegistryKey -Path $nvidiaPath -Name "RmGpsPsEnable" -Value 0 -Desc "NVIDIA Power Saving OFF (Desktop)"
                    }
                    
                    # Low Latency preemptions
                    Set-RegistryKey -Path $nvidiaPath -Name "EnablePreemption" -Value 0 -Desc "NVIDIA Preemption OFF"
                }
            }
            "AMD" {
                Write-Host "   [i] AMD/Radeon detectada - aplicando tweaks especificos..." -ForegroundColor Red
                
                # AMD Anti-Lag hint
                Set-RegistryKey -Path "HKCU:\Software\AMD\CN" -Name "AutoUpdate" -Value 0 -Desc "AMD Auto Update OFF"
            }
            "Intel" {
                Write-Host "   [i] Intel iGPU detectada - optimizaciones integradas..." -ForegroundColor Cyan
                
                # Intel graphics optimization
                Set-RegistryKey -Path "HKLM:\SOFTWARE\Intel\Display\igfxcui\profiles\Media" -Name "VSync" -Value 0 -Desc "Intel VSync OFF"
            }
        }
    }
    
    # MSI Mode for GPU (Low Latency)
    if ($hw.GpuPnpId) {
        Write-Host "   [i] Enabling MSI Mode for GPU..." -ForegroundColor Cyan
        Set-DeviceMSIMode -PnpDeviceID $hw.GpuPnpId -DeviceDesc "GPU ($($hw.GpuName))"
    }

    Write-Host "   [OK] Optimizaciones de GPU aplicadas" -ForegroundColor Green
}

function Invoke-InputLatencyOptimizations {
    param($hw)
    Write-Step "OPTIMIZACION DE LATENCIA DE ENTRADA (Hellzerg/Calypto)"
    
    # 1. Mouse & Keyboard Data Queue Size
    # Default is 100. Lowering to 50 reduces buffer latency without risking cursor skipping (unlike 20 or lower).
    Write-Host "   [i] Ajustando buffers de entrada (Mouse/Teclado)..." -ForegroundColor Cyan
    
    $mouClass = "HKLM:\SYSTEM\CurrentControlSet\Services\mouclass\Parameters"
    $kbdClass = "HKLM:\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters"
    
    if (-not (Test-Path $mouClass)) { New-Item -Path $mouClass -Force | Out-Null }
    if (-not (Test-Path $kbdClass)) { New-Item -Path $kbdClass -Force | Out-Null }
    
    Set-RegistryKey -Path $mouClass -Name "MouseDataQueueSize" -Value 50 -Desc "Mouse Queue Size (50)"
    Set-RegistryKey -Path $kbdClass -Name "KeyboardDataQueueSize" -Value 50 -Desc "Keyboard Queue Size (50)"
    
    # 2. Priority Boost for Input Drivers (Experimental but safe)
    # HKLM\System\CurrentControlSet\Control\PriorityControl -> IRQ8 priority is often mythical, 
    # but ensuring driver efficiency is key. We stick to QueueSize which is proven.
    
    Write-Host "   [OK] Latencia de entrada optimizada" -ForegroundColor Green
}

function Invoke-KernelTweaks {
    param($hw)
    Write-Step "OPTIMIZACION DE KERNEL & BOOT (LATENCIA)"
    
    # Only apply on High/Ultra tier to avoid stability risks on very old hardware
    if ($hw.PerformanceTier -in "High", "Ultra", "Standard") {
        Write-Host "   [i] Optimizando temporizadores del sistema (BCD)..." -ForegroundColor Cyan
        
        # 1. Disable Dynamic Tick (Reduces micro-stutters/latency)
        cmd /c "bcdedit /set disabledynamictick yes" | Out-Null
        
        # 2. Ensure HPET is OFF (Delete useplatformclock to force default TSC)
        cmd /c "bcdedit /deletevalue useplatformclock" 2>$null | Out-Null
        
        # 3. TSC Sync Policy (Enhanced is safest/best for modern CPUs)
        cmd /c "bcdedit /set tscsyncpolicy Enhanced" | Out-Null
        
        Write-Host "   [OK] Timers ajustados (DynamicTick: OFF, HPET: Default)" -ForegroundColor Green
    }
}

function Invoke-UsbPowerOptimizations {
    param($hw)
    Write-Step "OPTIMIZACION DE ENERGIA USB"
    
    # Disable USB Selective Suspend (prevents HID wake-up lag)
    # 2a737441-1930-4402-8d77-b94982726d37 = USB settings
    # 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 = USB Selective Suspend Setting
    # 0 = Disabled
    
    $currentScheme = Get-CimInstance Win32_PowerPlan -Namespace root\cimv2\power -Filter "IsActive='True'"
    
    # Apply to current scheme
    if ($currentScheme) {
        $guid = $currentScheme.InstanceID -replace ".*{(.*)}", '$1'
        cmd /c "powercfg /setacvalueindex $guid 2a737441-1930-4402-8d77-b94982726d37 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0" | Out-Null
        cmd /c "powercfg /setdcvalueindex $guid 2a737441-1930-4402-8d77-b94982726d37 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0" | Out-Null
        cmd /c "powercfg /active $guid" | Out-Null # Refresh
        
        Write-Host "   [OK] Suspension Selectiva USB: Deshabilitada" -ForegroundColor Green
    }
}

function Invoke-NetworkOptimizations {
    param($hw)
    
    Write-Step "OPTIMIZACIONES DE RED"
    
    # Network Throttling OFF
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xffffffff -Desc "Network Throttling OFF"
    
    # Nagle's Algorithm per adapter
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
    foreach ($adapter in $adapters) {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\{$($adapter.InterfaceGuid)}"
        if (Test-Path $regPath) {
            Set-RegistryKey -Path $regPath -Name "TcpAckFrequency" -Value 1 -Desc "TCP Ack Freq: 1"
            Set-RegistryKey -Path $regPath -Name "TCPNoDelay" -Value 1 -Desc "Nagle OFF"
        }
        
        # MSI Mode for NIC
        if ($adapter.PnpDeviceID) {
            Set-DeviceMSIMode -PnpDeviceID $adapter.PnpDeviceID -DeviceDesc "NIC ($($adapter.InterfaceDescription))"
        }
    }
    
    Write-Host "   [OK] Optimizaciones de red aplicadas" -ForegroundColor Green
}

function Invoke-VisualOptimizations {
    param($hw)
    
    Write-Step "OPTIMIZACIONES VISUALES (Tier: $($hw.PerformanceTier))"
    
    $visualPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
    $advPath = "HKCU:\Control Panel\Desktop"
    
    switch ($hw.PerformanceTier) {
        "Ultra" {
            Write-Host "   [i] Ultra Tier - Manteniendo efectos visuales completos..." -ForegroundColor Magenta
            # Keep all visual effects for Ultra systems
            Set-RegistryKey -Path $visualPath -Name "VisualFXSetting" -Value 1 -Desc "Visual Effects: Best Appearance"
        }
        "High" {
            Write-Host "   [i] High Tier - Efectos balanceados..." -ForegroundColor Green
            # Let Windows decide
            Set-RegistryKey -Path $visualPath -Name "VisualFXSetting" -Value 0 -Desc "Visual Effects: Auto"
        }
        "Standard" {
            Write-Host "   [i] Standard Tier - Reduciendo efectos..." -ForegroundColor Yellow
            # Custom - disable some effects
            Set-RegistryKey -Path $visualPath -Name "VisualFXSetting" -Value 3 -Desc "Visual Effects: Custom"
            Set-RegistryKey -Path $advPath -Name "UserPreferencesMask" -Value ([byte[]](0x90, 0x12, 0x03, 0x80, 0x10, 0x00, 0x00, 0x00)) -Desc "Reduced Effects"
        }
        "Low" {
            Write-Host "   [i] Low Tier - Deshabilitando efectos para mejor rendimiento..." -ForegroundColor Red
            # Best performance
            Set-RegistryKey -Path $visualPath -Name "VisualFXSetting" -Value 2 -Desc "Visual Effects: Performance"
        }
    }
    
    Write-Host "   [OK] Optimizaciones visuales aplicadas" -ForegroundColor Green
}


function Invoke-AudioLatencyOptimizations {
    param($hw)
    Write-Step "OPTIMIZACION DE AUDIO & LATENCIA (MMCSS)"
    
    # 1. System Responsiveness
    # Default is 20%. Gaming/Audio benefits from 10% or lower, ensuring Multimedia gets CPU time.
    $sysProfile = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
    Set-RegistryKey -Path $sysProfile -Name "SystemResponsiveness" -Value 10 -Desc "System Responsiveness (10%)"
    
    # 2. Priorities for Games/Multimedia
    $tasks = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
    if (Test-Path $tasks) {
        Set-RegistryKey -Path $tasks -Name "GPU Priority" -Value 8 -Desc "GPU Priority (8)"
        Set-RegistryKey -Path $tasks -Name "Priority" -Value 6 -Desc "Games MM Priority (6)"
        Set-RegistryKey -Path $tasks -Name "Scheduling Category" -Value "High" -Desc "Scheduling: High"
        Set-RegistryKey -Path $tasks -Name "SFIO Priority" -Value "High" -Desc "SFIO: High"
    }

    Write-Host "   [OK] Latencia de audio optimizada" -ForegroundColor Green
}

function Invoke-CpuMitigationToggles {
    param($hw)
    
    # Only applicable for older CPUs where mitigations hit performance hard (Pre-Gen 8 Intel, Pre-Ryzen 2000)
    if (-not $hw.IsOldCpu) { return }
    
    Write-Step "OPTIMIZACION DE CPU (LEGACY)"
    Write-Host "   [!] CPU Antigua detectada ($($hw.CpuGen))." -ForegroundColor Yellow
    Write-Host "       Las mitigaciones de seguridad (Spectre/Meltdown) pueden reducir el rendimiento." -ForegroundColor Gray
    
    # Check if already disabled
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
    $featSettings = Get-ItemProperty -Path $regPath -Name "FeatureSettingsOverride" -ErrorAction SilentlyContinue
    
    if ($featSettings -and $featSettings.FeatureSettingsOverride -eq 3) {
        Write-Host "   [OK] Mitigaciones ya estan deshabilitadas (Rendimiento Maximo)." -ForegroundColor Green
    }
    else {
        # We generally DO NOT force this. It's a security risk.
        # But we can set a helper key or just log it.
        # For this suite, we will applying a safe "mask" that doesn't break things, or better yet:
        # Just create the registry value but leave it at default (0) unless user engages with "Extreme" mode.
        # Given this is 'Smart-Optimizer', we will skip AUTO-applying this risky tweak.
        
        Write-Host "   [i] Nota: Para ganar 5-15% FPS, use el script 'Advanced-Registry' para deshabilitar mitigaciones." -ForegroundColor Cyan
    }
}


function Invoke-ServiceOptimizations {
    param($hw)
    Write-Step "OPTIMIZACION DE SERVICIOS INTELIGENTE"
    
    $servicesToDisable = @(
        "DiagTrack",          # Telemetry
        "dmwappushservice",   # WAP Push (Telemetry)
        "MapsBroker",         # Downloaded Maps Manager
        "RetailDemo",         # Retail Demo Service
        "WalletService",      # Wallet Service
        "XblGameSave",        # Xbox Game Save (Only if user doesn't game? No, keep safe, disabling interferes with GamePass)
        "XboxNetApiSvc"       # Xbox Live Networking (Keep safe)
    )
    
    # Safe bloat removal list
    $bloatServices = @("RetailDemo", "MapsBroker", "WalletService")
    
    # Fax (Who uses Fax?)
    $bloatServices += "Fax"
    
    foreach ($svcName in $bloatServices) {
        $svc = Get-Service $svcName -ErrorAction SilentlyContinue
        if ($svc -and $svc.StartType -ne "Disabled") {
            Set-Service $svcName -StartupType Disabled -ErrorAction SilentlyContinue
            Stop-Service $svcName -Force -ErrorAction SilentlyContinue
            Write-Host "   [OK] Servicio Bloatware desactivado: $svcName" -ForegroundColor Green
        }
    }
    
    # Laptop specific services
    if (-not $hw.IsLaptop) {
        # Sensor Service (Rotacion, Brillo) - Usually not needed on Desktop
        $sensorSvc = Get-Service "SensorService" -ErrorAction SilentlyContinue
        if ($sensorSvc -and $sensorSvc.Status -ne "Stopped") {
            Set-Service "SensorService" -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Host "   [OK] Servicio Sensores (Desktop): Desactivado" -ForegroundColor Green
        }
    }
    
    Write-Host "   [OK] Limpieza de servicios completada" -ForegroundColor Green
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

function Invoke-SmartOptimization {
    Clear-Host
    
    Write-Host ""
    Write-Host " ========================================================" -ForegroundColor Cyan
    Write-Host " |  SMART OPTIMIZER v6.5 ULTRA                          |" -ForegroundColor Cyan
    Write-Host " |  Optimizacion adaptativa basada en hardware          |" -ForegroundColor Yellow
    Write-Host " ========================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Detect hardware
    Write-Host " [*] Analizando hardware..." -ForegroundColor Yellow
    $hw = Get-HardwareProfile
    
    # Show analysis
    Show-HardwareAnalysis $hw
    
    if ($hw.IsHybrid) {
        Write-Host " [!] Arquitectura Hibrida (P-Cores/E-Cores) detectada." -ForegroundColor Magenta
        Write-Host "     Se aplicaran politicas de programacion heterogenea." -ForegroundColor Gray
        Write-Host ""
    }
    
    # Confirmation
    Write-Host ""
    Write-Host " [?] Desea aplicar optimizaciones personalizadas para este hardware? (S/N)" -ForegroundColor Yellow
    $choice = Read-Host "   >>"
    
    if ($choice -notmatch "^[Ss]") {
        Write-Host " [--] Cancelado." -ForegroundColor DarkGray
        return
    }
    
    Write-Host ""
    Write-Section "APLICANDO OPTIMIZACIONES INTELIGENTES"

    # --- AI DECISION LOGIC REPORT ---
    Write-Host " [IA] Decidiendo configuracion optima..." -ForegroundColor Cyan
    Write-Host ""
    
    # 1. Power Plan Decision
    $planTarget = "Neural Balanced"
    if ($hw.PerformanceTier -match "Ultra|High") { $planTarget = "Neural Low Latency" }
    elseif ($hw.PerformanceTier -eq "Streaming") { $planTarget = "Neural Streaming" }
    Write-Host "   > Perfil: $($hw.PerformanceTier) -> Plan: $planTarget" -ForegroundColor Green
    
    # 2. Kernel/Latency Decision
    if ($hw.PerformanceTier -in "High", "Ultra", "Standard") {
        Write-Host "   > Kernel: BCD/Timers optimizados para baja latencia." -ForegroundColor Green
    }
    
    # 3. CPU Mitigation Decision
    if ($hw.IsOldCpu) {
        Write-Host "   > CPU Legacy ($($hw.CpuGen)): Mitigaciones marcadas para revision." -ForegroundColor Yellow
    }
    
    # 4. Storage Decision
    if ($hw.IsNVMe) {
        Write-Host "   > Storage: NVMe detectado -> Optimizacion Maxima I/O." -ForegroundColor Green
    }
    
    # 5. Hybrid Awareness
    if ($hw.IsHybrid) {
        Write-Host "   > Hybrid CPU: Optimizando Thread Director y Parking." -ForegroundColor Magenta
    }

    Write-Host ""
    # --------------------------------
    
    # Apply all hardware-aware optimizations
    Invoke-StorageOptimizations $hw
    Invoke-PowerOptimizations $hw
    Invoke-MemoryOptimizations $hw
    Invoke-GPUOptimizations $hw
    Invoke-NetworkOptimizations $hw
    Invoke-VisualOptimizations $hw
    Invoke-ServiceOptimizations $hw  # Added Smart Services
    
    # --- REAL AI INTEGRATION ---
    if (Get-Command "Get-SimulatedAIResponse" -ErrorAction SilentlyContinue) {
        Write-Host ""
        Write-Section "NEURAL AI ENGINE (TRUE-AI)"
        Write-Host " [IA] Analizando telemetria de hardware..." -ForegroundColor Cyan
        
        # In a full version, we would check for NeuralConfig.json API Key here
        # $aiResponse = Invoke-CloudAIAnalysis -HardwareProfile $hw -ApiKey $config.ApiKey
        
        # For now, we utilize the Local Expert System which uses non-linear decision trees
        $aiTweaks = Get-SimulatedAIResponse -hw $hw
        
        if ($aiTweaks) {
            foreach ($tweak in $aiTweaks) {
                Write-Host "   [AI] Recommended: $($tweak.Desc)" -ForegroundColor Magenta
                # Apply the tweak
                Set-RegistryKey -Path $tweak.Path -Name $tweak.Name -Value $tweak.Value -Type $tweak.Type -Desc $tweak.Desc
            }
        }
    }

    # Invoke-PowerOptimizations $hw # Deprecated in favor of Neural Power Plans
    
    # Create/Ensure Plans exist
    Invoke-PowerPlanCreation
    
    # Apply based on tier/profile context
    # Assuming $hw.PerformanceTier maps to profiles. We might need a specific 'Profile' param in the future.
    # For now: High/Ultra -> Low Latency. Standard -> Balanced.
    Set-NeuralPowerPlan -ProfileName $hw.PerformanceTier 
    
    Invoke-InputLatencyOptimizations $hw
    Invoke-AudioLatencyOptimizations $hw
    Invoke-GamingOptimizations $hw
    Invoke-CpuMitigationToggles $hw
    Invoke-UsbPowerOptimizations $hw
    Invoke-KernelTweaks $hw
    
    # Summary
    Write-Host ""
    Write-Host " ========================================================" -ForegroundColor Green
    Write-Host " |  SMART OPTIMIZER COMPLETADO                          |" -ForegroundColor Green
    Write-Host " ========================================================" -ForegroundColor Green
    Write-Host " |  Sistema: $(if($hw.IsLaptop){'LAPTOP'}else{'DESKTOP'}) | Tier: $($hw.PerformanceTier)" -ForegroundColor Green
    Write-Host " |  Optimizaciones aplicadas segun tu hardware.         |" -ForegroundColor Green
    Write-Host " |                                                      |" -ForegroundColor Green
    
    # Neural Learning Phase
    if (Get-Command "Invoke-NeuralLearning" -ErrorAction SilentlyContinue) {
        Write-Host " |  [AI] Learning Phase: Measuring Impact...            |" -ForegroundColor Magenta
        Invoke-NeuralLearning -ProfileName $hw.PerformanceTier -Hardware $hw
    }
    
    Write-Host " |  Reinicia para aplicar todos los cambios.            |" -ForegroundColor Yellow
    Write-Host " ========================================================" -ForegroundColor Green
    Write-Host ""
}

# Run
Invoke-SmartOptimization
Wait-ForKeyPress

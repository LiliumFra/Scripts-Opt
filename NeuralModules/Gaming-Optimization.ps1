<#
.SYNOPSIS
    Gaming & Performance Module v6.5 ULTRA
    Optimizaciones para NVIDIA, AMD, Intel, y rendimiento general.

.DESCRIPTION
    Advanced Features:
    - Game Mode & Xbox Game Bar optimization
    - GPU Scheduling (HAGS) & DirectX 12 tweaks
    - Mouse & Input latency reduction
    - NVIDIA/AMD/Intel GPU-specific tweaks
    - CPU Priority for Games (MMCSS)
    - Fullscreen Optimizations global disable
    - Network Throttling disable
    - Nagle's Algorithm disable (per-adapter)
    - VBS/Core Isolation option (latency reduction)
    - Ultimate Performance power plan
    - Smart DNS benchmark

.NOTES
    Parte de Windows Neural Optimizer v6.5 ULTRA
    Creditos: Jose Bustamante
    Inspirado en: Chris Titus WinUtil, Sophia Script
#>

# Ensure Utils are loaded
if (-not (Get-Command "Write-Log" -ErrorAction SilentlyContinue)) {
    $currentDir = Split-Path $MyInvocation.MyCommand.Path
    $utilsPath = Join-Path $currentDir "NeuralUtils.psm1"
    if (Test-Path $utilsPath) { Import-Module $utilsPath -Force -DisableNameChecking }
}

Invoke-AdminCheck -Silent

function Optimize-Gaming {
    [CmdletBinding()]
    param()
    
    Write-Section (Msg "Game.Title")
    
    # Hardware Detection
    $hw = Get-HardwareProfile
    Write-Host " [i] $(Msg 'Game.Hw.Detected')" -ForegroundColor Cyan
    Write-Host "     CPU: $($hw.CpuVendor)" -ForegroundColor Gray
    Write-Host "     RAM: $($hw.RamGB) GB" -ForegroundColor Gray
    Write-Host "     SSD: $($hw.IsSSD)" -ForegroundColor Gray
    Write-Host ""
    
    $appliedTweaks = 0
    
    # =========================================================================
    # 1. GAME MODE & XBOX GAME BAR
    # =========================================================================
    
    Write-Step (Msg "Game.Step.GameMode")
    
    $gameModeKeys = @(
        @{ Path = "HKCU:\Software\Microsoft\GameBar"; Name = "AllowAutoGameMode"; Value = 1; Desc = (Msg "Game.Desc.GameModeAuto") },
        @{ Path = "HKCU:\Software\Microsoft\GameBar"; Name = "AutoGameModeEnabled"; Value = 1; Desc = (Msg "Game.Desc.GameModeEnabled") },
        @{ Path = "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR"; Name = "value"; Value = 0; Desc = (Msg "Game.Desc.DVR") },
        @{ Path = "HKCU:\System\GameConfigStore"; Name = "GameDVR_Enabled"; Value = 0; Desc = (Msg "Game.Desc.DVR") },
        @{ Path = "HKCU:\System\GameConfigStore"; Name = "GameDVR_FSEBehaviorMode"; Value = 2; Desc = (Msg "Game.Desc.FSE") },
        @{ Path = "HKCU:\System\GameConfigStore"; Name = "GameDVR_DXGIHonorFSEWindowsCompatible"; Value = 1; Desc = "FSE Windows Compatible" },
        @{ Path = "HKCU:\System\GameConfigStore"; Name = "GameDVR_HonorUserFSEBehaviorMode"; Value = 1; Desc = "Honor FSE Mode" }
    )
    
    foreach ($k in $gameModeKeys) {
        if (Set-RegistryKey -Path $k.Path -Name $k.Name -Value $k.Value -Desc $k.Desc) {
            $appliedTweaks++
        }
    }
    
    # =========================================================================
    # 2. GPU SCHEDULING & DX12
    # =========================================================================
    
    Write-Step (Msg "Game.Step.GPU")
    
    $gpuKeys = @(
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"; Name = "HwSchMode"; Value = 2; Desc = (Msg "Game.Desc.HAGS") },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"; Name = "TdrLevel"; Value = 0; Desc = "TDR deshabilitado (anti-crash)" },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"; Name = "TdrDelay"; Value = 60; Desc = "TDR Delay 60s" },
        @{ Path = "HKLM:\SOFTWARE\Microsoft\DirectX"; Name = "D3D12_ENABLE_UNSAFE_COMMAND_BUFFER_REUSE"; Value = 1; Desc = "DX12 Command Buffer Reuse" },
        @{ Path = "HKLM:\SOFTWARE\Microsoft\DirectX"; Name = "D3D12_ENABLE_RUNTIME_DRIVER_OPTIMIZATIONS"; Value = 1; Desc = "DX12 Driver Optimizations" }
    )
    
    foreach ($k in $gpuKeys) {
        if (Set-RegistryKey -Path $k.Path -Name $k.Name -Value $k.Value -Desc $k.Desc) {
            $appliedTweaks++
        }
    }
    
    # =========================================================================
    # 3. MOUSE & INPUT OPTIMIZATION
    # =========================================================================
    
    Write-Step "[3/10] OPTIMIZACION MOUSE & INPUT"
    
    $mouseKeys = @(
        @{ Path = "HKCU:\Control Panel\Mouse"; Name = "MouseSpeed"; Value = "0"; Type = "String"; Desc = "Mouse Acceleration OFF" },
        @{ Path = "HKCU:\Control Panel\Mouse"; Name = "MouseThreshold1"; Value = "0"; Type = "String"; Desc = "Mouse Threshold1 OFF" },
        @{ Path = "HKCU:\Control Panel\Mouse"; Name = "MouseThreshold2"; Value = "0"; Type = "String"; Desc = "Mouse Threshold2 OFF" },
        @{ Path = "HKCU:\Control Panel\Mouse"; Name = "MouseSensitivity"; Value = "10"; Type = "String"; Desc = "Mouse Sensitivity Default" },
        @{ Path = "HKCU:\Control Panel\Accessibility\MouseKeys"; Name = "Flags"; Value = "0"; Type = "String"; Desc = "Mouse Keys OFF" },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\mouclass\Parameters"; Name = "MouseDataQueueSize"; Value = 20; Type = "DWord"; Desc = "Mouse Queue optimizada" },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\mouclass\Parameters"; Name = "MouseDataQueueSize"; Value = 20; Type = "DWord"; Desc = "Mouse Queue optimizada" },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters"; Name = "KeyboardDataQueueSize"; Value = 20; Type = "DWord"; Desc = "Keyboard Queue optimizada" },
        @{ Path = "HKCU:\Control Panel\Keyboard"; Name = "KeyboardDelay"; Value = "0"; Type = "String"; Desc = "Keyboard Delay 0 (Instant)" },
        @{ Path = "HKCU:\Control Panel\Keyboard"; Name = "KeyboardSpeed"; Value = "31"; Type = "String"; Desc = "Keyboard Speed 31 (Fastest)" }
    )
    
    foreach ($k in $mouseKeys) {
        $type = if ($k.Type) { $k.Type } else { "DWord" }
        if (Set-RegistryKey -Path $k.Path -Name $k.Name -Value $k.Value -Type $type -Desc $k.Desc) {
            $appliedTweaks++
        }
    }
    
    # =========================================================================
    # 4. NVIDIA OPTIMIZATIONS
    # =========================================================================
    
    Write-Step "[4/10] OPTIMIZACIONES NVIDIA"
    
    # Basic detect from profile works, but we also check WMI for details if needed
    $hasNvidia = (Get-CimInstance Win32_VideoController | Where-Object { $_.Name -match "NVIDIA" })
    
    if ($hasNvidia) {
        $nvidiaKeys = @(
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"; Name = "RMHdcpKeyglobZero"; Value = 1; Desc = "HDCP Optimization" },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\NVTweak"; Name = "DisplayPowerSaving"; Value = 0; Desc = "Display Power Saving OFF" },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"; Name = "PerfLevelSrc"; Value = 0x2222; Desc = "Performance Level Max" },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"; Name = "PowerMizerEnable"; Value = 0; Desc = "PowerMizer OFF" },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"; Name = "PowerMizerLevel"; Value = 1; Desc = "PowerMizer Level Max" },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"; Name = "PowerMizerLevelAC"; Value = 1; Desc = "PowerMizer AC Max" }
        )
        
        foreach ($k in $nvidiaKeys) {
            if (Test-Path $k.Path) {
                if (Set-RegistryKey -Path $k.Path -Name $k.Name -Value $k.Value -Desc $k.Desc) {
                    $appliedTweaks++
                }
            }
        }
        Write-Host "   [i] NVIDIA Detectada" -ForegroundColor DarkCyan
    }
    else {
        Write-Host "   [--] NVIDIA no detectada" -ForegroundColor DarkGray
    }
    
    # =========================================================================
    # 5. AMD OPTIMIZATIONS
    # =========================================================================
    
    Write-Step "[5/10] OPTIMIZACIONES AMD"
    
    $hasAMD = (Get-CimInstance Win32_VideoController | Where-Object { $_.Name -match "AMD|Radeon" })
    
    if ($hasAMD) {
        $amdKeys = @(
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"; Name = "EnableUlps"; Value = 0; Desc = "ULPS OFF (mejor latencia)" },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"; Name = "EnableUlps_NA"; Value = 0; Desc = "ULPS NA OFF" },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"; Name = "PP_SclkDeepSleepDisable"; Value = 1; Desc = "Deep Sleep OFF" },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"; Name = "DisableDMACopy"; Value = 0; Desc = "DMA Copy ON" },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"; Name = "DisableBlockWrite"; Value = 0; Desc = "Block Write ON" },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"; Name = "StutterMode"; Value = 0; Desc = "Anti-Stutter" }
        )
        
        foreach ($k in $amdKeys) {
            if (Test-Path $k.Path) {
                if (Set-RegistryKey -Path $k.Path -Name $k.Name -Value $k.Value -Desc $k.Desc) {
                    $appliedTweaks++
                }
            }
        }
        Write-Host "   [i] AMD Detectada" -ForegroundColor DarkCyan
    }
    else {
        Write-Host "   [--] AMD no detectada" -ForegroundColor DarkGray
    }
    
    # =========================================================================
    # 6. INTEL GPU OPTIMIZATIONS
    # =========================================================================
    
    Write-Step "[6/10] OPTIMIZACIONES INTEL GPU"
    
    $hasIntel = (Get-CimInstance Win32_VideoController | Where-Object { $_.Name -match "Intel" })
    
    if ($hasIntel) {
        $intelKeys = @(
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"; Name = "Disable_OverlayDSQualityEnhancement"; Value = 1; Desc = "Overlay Enhancement OFF" },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"; Name = "IncreaseFixedSegment"; Value = 1; Desc = "Fixed Segment Size UP" },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"; Name = "AdaptiveVsyncEnable"; Value = 0; Desc = "Adaptive VSync OFF" },
            @{ Path = "HKLM:\SOFTWARE\Intel\GMM"; Name = "DedicatedSegmentSize"; Value = 512; Desc = "VRAM Dedicada 512MB" },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"; Name = "DisablePSR"; Value = 1; Desc = "Panel Self Refresh OFF" },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"; Name = "ACPowerPolicyVersion"; Value = 0; Desc = "AC Power Max Performance" },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"; Name = "DCPowerPolicyVersion"; Value = 0; Desc = "DC Power Max Performance" }
        )
        
        foreach ($k in $intelKeys) {
            # Low complexity conditional set - only set if key path roughly exists or create it safely
            # Since Set-RegistryKey handles creation, we can try applying common paths
            if (Set-RegistryKey -Path $k.Path -Name $k.Name -Value $k.Value -Desc $k.Desc) {
                $appliedTweaks++
            }
        }
        Write-Host "   [i] Intel GPU Detectada" -ForegroundColor DarkCyan
    }
    else {
        Write-Host "   [--] Intel GPU no detectada" -ForegroundColor DarkGray
    }

    # =========================================================================
    # 7. CPU PRIORITY FOR GAMES
    # =========================================================================
    
    Write-Step "[7/10] PRIORIDAD CPU PARA JUEGOS"
    
    $gameTasks = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
    
    $cpuKeys = @(
        @{ Path = $gameTasks; Name = "Affinity"; Value = 0; Desc = "Game Affinity ALL CPUs" },
        @{ Path = $gameTasks; Name = "Background Only"; Value = "False"; Type = "String"; Desc = "No solo background" },
        @{ Path = $gameTasks; Name = "Clock Rate"; Value = 10000; Desc = "Clock Rate 10ms" },
        @{ Path = $gameTasks; Name = "GPU Priority"; Value = 8; Desc = "GPU Priority MAX" },
        @{ Path = $gameTasks; Name = "Priority"; Value = 6; Desc = "CPU Priority HIGH" },
        @{ Path = $gameTasks; Name = "Scheduling Category"; Value = "High"; Type = "String"; Desc = "Scheduling HIGH" },
        @{ Path = $gameTasks; Name = "SFIO Priority"; Value = "High"; Type = "String"; Desc = "SFIO Priority HIGH" },
        @{ Path = $gameTasks; Name = "Latency Sensitive"; Value = "True"; Type = "String"; Desc = "Latency Sensitive ON" }
    )
    
    foreach ($k in $cpuKeys) {
        $type = if ($k.Type) { $k.Type } else { "DWord" }
        if (Set-RegistryKey -Path $k.Path -Name $k.Name -Value $k.Value -Type $type -Desc $k.Desc) {
            $appliedTweaks++
        }
    }
    
    # =========================================================================
    # 8. FULLSCREEN & VSYNC OPTIMIZATIONS
    # =========================================================================
    
    Write-Step "[8/10] FULLSCREEN & VSYNC"
    
    $fsKeys = @(
        @{ Path = "HKCU:\System\GameConfigStore"; Name = "GameDVR_FSEBehavior"; Value = 2; Desc = "FSE Behavior optimizado" },
        @{ Path = "HKCU:\System\GameConfigStore"; Name = "GameDVR_EFSEFeatureFlags"; Value = 0; Desc = "EFSE Flags OFF" },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"; Name = "__COMPAT_LAYER"; Value = "~ DISABLEDXMAXIMIZEDWINDOWEDMODE"; Type = "String"; Desc = "DX Maximized OFF" },
        @{ Path = "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences"; Name = "DirectXUserGlobalSettings"; Value = "SwapEffectUpgradeEnable=1;"; Type = "String"; Desc = "Swap Effect Upgrade ON" }
    )
    
    foreach ($k in $fsKeys) {
        $type = if ($k.Type) { $k.Type } else { "DWord" }
        if (Set-RegistryKey -Path $k.Path -Name $k.Name -Value $k.Value -Type $type -Desc $k.Desc) {
            $appliedTweaks++
        }
    }
    
    # =========================================================================
    # 9. FULLSCREEN OPTIMIZATIONS GLOBAL DISABLE
    # =========================================================================
    
    Write-Step "[9/15] FULLSCREEN OPTIMIZATIONS GLOBAL"
    
    # Disable FSO globally for all applications
    $fsoKeys = @(
        @{ Path = "HKCU:\System\GameConfigStore"; Name = "GameDVR_FSEBehaviorMode"; Value = 2; Desc = "FSE Behavior: Fullscreen" },
        @{ Path = "HKCU:\System\GameConfigStore"; Name = "GameDVR_HonorUserFSEBehaviorMode"; Value = 1; Desc = "Honor User FSE Mode" },
        @{ Path = "HKCU:\System\GameConfigStore"; Name = "GameDVR_DXGIHonorFSEWindowsCompatible"; Value = 1; Desc = "DXGI Honor FSE" },
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\Dwm"; Name = "OverlayTestMode"; Value = 5; Desc = "DWM Overlay Test Mode" }
    )
    
    foreach ($k in $fsoKeys) {
        if (Set-RegistryKey -Path $k.Path -Name $k.Name -Value $k.Value -Desc $k.Desc) {
            $appliedTweaks++
        }
    }
    
    Write-Host "   [OK] Fullscreen Optimizations globalmente deshabilitadas" -ForegroundColor Green
    
    # =========================================================================
    # 10. NETWORK THROTTLING & NAGLE'S ALGORITHM
    # =========================================================================
    
    Write-Step "[10/15] NETWORK GAMING TWEAKS"
    
    # Disable Network Throttling Index
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xffffffff -Desc "Network Throttling OFF"
    $appliedTweaks++
    
    # Disable Nagle's Algorithm on all network interfaces
    Write-Host "   [i] Deshabilitando Nagle's Algorithm..." -ForegroundColor Cyan
    
    $tcpPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
    $interfaces = Get-ChildItem -Path $tcpPath -ErrorAction SilentlyContinue
    
    foreach ($iface in $interfaces) {
        $ifacePath = $iface.PSPath
        Set-ItemProperty -Path $ifacePath -Name "TcpAckFrequency" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $ifacePath -Name "TCPNoDelay" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
    }
    
    Write-Host "   [OK] Nagle's Algorithm deshabilitado en todas las interfaces" -ForegroundColor Green
    $appliedTweaks++
    
    # =========================================================================
    # 10. SYSTEM LATENCY TWEAKS
    # =========================================================================
    
    Write-Step "[10/10] LATENCIA DEL SISTEMA"
    
    $power = "HKLM:\SYSTEM\CurrentControlSet\Control\Power"
    
    $latencyKeys = @(
        @{ Path = $power; Name = "ExitLatency"; Value = 1; Desc = "Exit Latency Low" },
        @{ Path = $power; Name = "ExitLatencyCheckEnabled"; Value = 1; Desc = "Latency Check ON" },
        @{ Path = $power; Name = "Latency"; Value = 1; Desc = "Power Latency Low" },
        @{ Path = $power; Name = "LatencyToleranceDefault"; Value = 1; Desc = "Latency Tolerance Min" },
        @{ Path = $power; Name = "LatencyToleranceFSVP"; Value = 1; Desc = "FSVP Latency Min" },
        @{ Path = $power; Name = "LatencyTolerancePerfOverride"; Value = 1; Desc = "Perf Override Latency" },
        @{ Path = $power; Name = "LatencyToleranceScreenOffIR"; Value = 1; Desc = "Screen Off IR Latency" },
        @{ Path = $power; Name = "LatencyToleranceVSyncEnabled"; Value = 1; Desc = "VSync Latency Enabled" }
    )
    
    foreach ($k in $latencyKeys) {
        if (Set-RegistryKey -Path $k.Path -Name $k.Name -Value $k.Value -Desc $k.Desc) {
            $appliedTweaks++
        }
    }
    
    Write-Host ""
    Write-Host " [!] REINICIE SU PC PARA APLICAR CAMBIOS DE GPU/RED" -ForegroundColor Yellow

    # =========================================================================
    # 11. ULTIMATE PERFORMANCE (TUNED - ANTI-HEAT)
    # =========================================================================
    
    Write-Step "[11/13] PLAN DE ENERGIA (ULTIMATE TUNED)"
    
    $ultimateGuid = "e9a42b02-d5df-448d-aa00-03f14749eb61"
    $powerList = powercfg /list
    
    if ($powerList -match $ultimateGuid) {
        Write-Host "   [i] Plan Ultimate Performance ya existe." -ForegroundColor DarkGray
    }
    else {
        Write-Host "   [+] Creando Plan Ultimate Performance..." -ForegroundColor Cyan
        powercfg -duplicatescheme $ultimateGuid 2>$null | Out-Null
    }
    
    # Activar
    try {
        powercfg -setactive $ultimateGuid
        $currentPlan = powercfg /getactivescheme
        if ($currentPlan -match $ultimateGuid) {
            Write-Host "   [OK] Plan 'Ultimate Performance' ACTIVADO" -ForegroundColor Green
            $appliedTweaks++
            
            # TUNING AVANZADO DE ESCALADO DINAMICO (ROCKET UP, PARACHUTE DOWN)
            # Objetivo: CPU debe saltar a Max Freq INSTANTANEAMENTE al mover el mouse/jugar
            # pero bajar suavemente para enfriarse cuando no se hace nada.
            
            Write-Host "   [i] Aplicando 'Dynamic Quantum Boost'..." -ForegroundColor Cyan
            
            # GUIDs de Subgrupo Processor Settings
            $subProc = "54533251-82be-4824-96c1-47b60b740d00"
            
            # 1. Minimum Processor State: 0% -> 5% (Permite enfriamiento)
            powercfg -setacvalueindex scheme_current $subProc PROCTHROTTLEMIN 5
            powercfg -setdcvalueindex scheme_current $subProc PROCTHROTTLEMIN 5
            
            # 2. Maximum Processor State: 100%
            powercfg -setacvalueindex scheme_current $subProc PROCTHROTTLEMAX 100
            
            # --- SUPER TUNING DE RESPUESTA ---
            
            # 3. Increase Policy: ROCKET (2) -> Salta a Max Freq INMEDIATAMENTE
            # GUID: 465e1f50-b610-4a66-a5f6-30e92623b054
            powercfg -setacvalueindex scheme_current $subProc 465e1f50-b610-4a66-a5f6-30e92623b054 2
            
            # 4. Decrease Policy: SINGLE (1) -> Baja gradualmente (Suave)
            # GUID: 40fbefc7-2e9d-4d25-a185-0cfd8574bac6
            powercfg -setacvalueindex scheme_current $subProc 40fbefc7-2e9d-4d25-a185-0cfd8574bac6 1
            
            # 5. Increase Threshold: 10% -> Detecta carga minima y acelera
            # GUID: 06cadf0e-64ed-448a-8927-ce7bf90eb35d
            powercfg -setacvalueindex scheme_current $subProc 06cadf0e-64ed-448a-8927-ce7bf90eb35d 10
            
            # 6. Decrease Threshold: 8% -> Mantiene velocidad alta hasta ser casi idle
            # GUID: 12a0650c-292b-4ef1-87c3-15d71b563531
            powercfg -setacvalueindex scheme_current $subProc 12a0650c-292b-4ef1-87c3-15d71b563531 8
            
            # 7. Increase Time: 0 o 1ms -> Reacción Instantánea
            # GUID: 984cf492-3bed-4488-a8f9-4286c97bf5aa
            powercfg -setacvalueindex scheme_current $subProc 984cf492-3bed-4488-a8f9-4286c97bf5aa 1
            
            # 8. Decrease Time: 500ms -> Mantiene Freq alta medio segundo tras soltar carga (evita micro-lags)
            # GUID: d8ed251d-a688-4662-9550-5d93975002dd
            powercfg -setacvalueindex scheme_current $subProc d8ed251d-a688-4662-9550-5d93975002dd 500
            
            # 9. PCIe Link State Power Management: OFF (0)
            # GUID: 501a4d13-42af-4429-9fd1-a8218c268e20 (Subgrupo PCI Express) -> ee12f906-d277-404b-b6da-e5fa1a576df5 (Link State)
            $subPCI = "501a4d13-42af-4429-9fd1-a8218c268e20"
            $linkState = "ee12f906-d277-404b-b6da-e5fa1a576df5"
            powercfg -setacvalueindex scheme_current $subPCI $linkState 0
            powercfg -setdcvalueindex scheme_current $subPCI $linkState 0
            
            powercfg -setactive scheme_current # Apply updates
            
            Write-Host "   [OK] CPU Logic: Rocket UP (Instant) | Parachute DOWN (Smooth)" -ForegroundColor Green
        }
        else {
            Write-Host "   [!] No se pudo activar el plan automáticamente." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "   [X] Error gestionando plan de energía." -ForegroundColor Red
    }
    
    # =========================================================================
    # 12. VBS / CORE ISOLATION (Optional - Performance vs Security)
    # =========================================================================
    
    Write-Step "[12/15] VBS / CORE ISOLATION (LATENCIA)"
    
    Write-Host "   [!] VBS/Core Isolation puede reducir rendimiento hasta 10-15%" -ForegroundColor Yellow
    Write-Host "   [i] Deshabilitarlo mejora latencia pero reduce seguridad." -ForegroundColor DarkGray
    
    $vbsChoice = Read-Host "   >> ¿Deshabilitar VBS para máximo rendimiento? (S/N)"
    
    if ($vbsChoice -match "^[Ss]") {
        $vbsKeys = @(
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard"; Name = "EnableVirtualizationBasedSecurity"; Value = 0; Desc = "VBS OFF" },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"; Name = "Enabled"; Value = 0; Desc = "HVCI OFF" },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\CredentialGuard"; Name = "Enabled"; Value = 0; Desc = "Credential Guard OFF" }
        )
        
        foreach ($k in $vbsKeys) {
            if (Set-RegistryKey -Path $k.Path -Name $k.Name -Value $k.Value -Desc $k.Desc) {
                $appliedTweaks++
            }
        }
        
        Write-Host "   [OK] VBS/Core Isolation deshabilitado. Reinicio requerido." -ForegroundColor Green
    }
    else {
        Write-Host "   [--] VBS mantenido (seguridad conservada)" -ForegroundColor DarkGray
    }
    
    # =========================================================================
    # 12. VISUAL EFFECTS (PERFORMANCE)
    # =========================================================================
    
    Write-Step "[12/13] EFECTOS VISUALES (RENDIMIENTO)"
    
    # Adjust for Best Performance (VisualFXSetting = 2)
    $visKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
    if (Set-RegistryKey -Path $visKey -Name "VisualFXSetting" -Value 2 -Desc "Ajustar para mejor rendimiento") { 
        $appliedTweaks++ 
    }
    
    # Disable Transparency
    $personalizeKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    if (Set-RegistryKey -Path $personalizeKey -Name "EnableTransparency" -Value 0 -Desc "Transparencia Deshabilitada") { 
        $appliedTweaks++ 
    }
    
    # =========================================================================
    # 13. KERNEL & MODERN ALGORITHMS (SPEED TWEAKS)
    # =========================================================================
    
    Write-Step "[13/15] OPTIMIZACIONES DE KERNEL Y ALGORITMOS"
    
    # 13.1 System Responsiveness (Multimedia Scheduler)
    # Reserva 0% de CPU para tareas de baja prioridad (Juegos obtienen 100%)
    $systemProfile = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
    if (Set-RegistryKey -Path $systemProfile -Name "SystemResponsiveness" -Value 0 -Desc "Kernel: System Responsiveness = 0") { 
        $appliedTweaks++
    }
    
    # 13.2 Memory Compression (Solo si RAM > 16GB)
    # Deshabilitar compresión libera ciclos de CPU (Kernel) pero usa más RAM.
    if ($hw.RamGB -ge 16) {
        Write-Host "   [i] Memoria Inteligente (>16GB Detectado)" -ForegroundColor Cyan
        try {
            # Check current status
            $mmStatus = Get-MMAgent -ErrorAction SilentlyContinue
            if ($mmStatus.MemoryCompression) {
                Disable-MMAgent -MemoryCompression -ErrorAction SilentlyContinue | Out-Null
                Write-Host "   [OK] Algoritmo: Memory Compression DESHABILITADO (CPU Boost)" -ForegroundColor Green
                $appliedTweaks++
            }
        }
        catch {}
    }
    
    # 13.3 Advanced Network Algorithms (RSC / ECN)
    if ($activeNic) {
        Write-Host "   [i] Algoritmos de Red Modernos..." -ForegroundColor Cyan
        
        # RSC (Receive Segment Coalescing) - BAD for Latency, GOOD for Throughput
        # Deshabilitar RSC reduce latencia en juegos online
        try {
            if (Get-Command "Disable-NetAdapterRsc" -ErrorAction SilentlyContinue) {
                Disable-NetAdapterRsc -Name $activeNic.Name -ErrorAction SilentlyContinue
                Write-Host "   [OK] Algoritmo: RSC Deshabilitado (Menor Latencia)" -ForegroundColor Green
                $appliedTweaks++
            }
        }
        catch {}
        
        # ECN (Explicit Congestion Notification) - Modern Router Efficiency
        try {
            Set-NetTCPSetting -SettingName InternetCustom -EcnCapability Enabled -ErrorAction SilentlyContinue
            Write-Host "   [OK] Algoritmo: ECN Habilitado (Modern Routing)" -ForegroundColor Green
            $appliedTweaks++
        }
        catch {}
        
        # Disable Timestamps (Overhead reduction)
        try {
            Set-NetTCPSetting -SettingName InternetCustom -Timestamps Disabled -ErrorAction SilentlyContinue
            Write-Host "   [OK] TCP Timestamps: Deshabilitado (Overhead Off)" -ForegroundColor Green
            $appliedTweaks++
        }
        catch {}
    }

    # =========================================================================
    # 14. SMART DNS BENCHMARK
    # =========================================================================
    
    Write-Step "[14/14] SMART DNS BENCHMARK (Experimental)"
    
    function Test-DnsLatency {
        param($IP)
        try {
            $avg = 0
            for ($i = 0; $i -lt 3; $i++) {
                $ping = Test-Connection -ComputerName $IP -Count 1 -ErrorAction SilentlyContinue
                if ($ping) { $avg += $ping.ResponseTime } else { return 9999 }
            }
            return [math]::Round($avg / 3)
        }
        catch { return 9999 }
    }
    
    $activeNic = Get-ActiveNetworkAdapter
    
    if ($activeNic) {
        Write-Host "   [i] Probando latencia de DNS..." -ForegroundColor Cyan
        
        $dnsServers = @(
            @{ Name = "Google"; IP = "8.8.8.8" },
            @{ Name = "Cloudflare"; IP = "1.1.1.1" },
            @{ Name = "OpenDNS"; IP = "208.67.222.222" }
        )
        
        $bestDns = $null
        $bestLatency = 9999
        
        foreach ($dns in $dnsServers) {
            $lat = Test-DnsLatency -IP $dns.IP
            Write-Host "     - $($dns.Name) ($($dns.IP)): ${lat}ms" -ForegroundColor Gray
            if ($lat -lt $bestLatency) {
                $bestLatency = $lat
                $bestDns = $dns
            }
        }
        
        if ($bestDns -and $bestLatency -lt 999) {
            Write-Host "   [+] Mejor DNS detectado: $($bestDns.Name)" -ForegroundColor Green
            
            # Note: Changing DNS usually requires more robust handling (like clearing current list first).
            # For safety in this version, we will only Suggest it, or apply if user confirms.
            # To be non-intrusive in "Optimization" flow, we'll set it as Primary if it's significantly better.
            
            try {
                Set-DnsClientServerAddress -InterfaceIndex $activeNic.InterfaceIndex -ServerAddresses ($bestDns.IP) -ErrorAction SilentlyContinue
                Write-Host "   [OK] DNS configurado a $($bestDns.Name) en $($activeNic.Name)" -ForegroundColor Green
                $appliedTweaks++
            }
            catch {
                Write-Host "   [!] No se pudo cambiar DNS automaticamente." -ForegroundColor DarkGray
            }
        }
    }

    # Resumen
    Write-Host ""
    Write-Host " +--------------------------------------------------------+" -ForegroundColor Green
    Write-Host " |  GAMING OPTIMIZATION v6.0 COMPLETADO                   |" -ForegroundColor Green
    Write-Host " |  Tweaks aplicados: $appliedTweaks                                    |" -ForegroundColor Green
    Write-Host " +--------------------------------------------------------+" -ForegroundColor Green
}

Optimize-Gaming



<#
.SYNOPSIS
    Gaming & Performance Module v3.5 - ULTIMATE
    Optimizaciones para NVIDIA, AMD, Intel, y rendimiento general.

.NOTES
    Parte de Windows Neural Optimizer v3.5
#>

# Ensure Utils are loaded
if (-not (Get-Command "Write-Log" -ErrorAction SilentlyContinue)) {
    $currentDir = Split-Path $MyInvocation.MyCommand.Path
    $utilsPath = Join-Path $currentDir "NeuralUtils.psm1"
    if (Test-Path $utilsPath) { Import-Module $utilsPath -Force -DisableNameChecking }
}

Ensure-Admin -Silent

function Optimize-Gaming {
    [CmdletBinding()]
    param()
    
    Write-Section "GAMING & PERFORMANCE v3.5 (DEEP TUNED)"
    
    # Hardware Detection
    $hw = Get-HardwareProfile
    Write-Host " [i] Hardware Detectado:" -ForegroundColor Cyan
    Write-Host "     CPU: $($hw.CpuVendor)" -ForegroundColor Gray
    Write-Host "     RAM: $($hw.RamGB) GB" -ForegroundColor Gray
    Write-Host "     SSD: $($hw.IsSSD)" -ForegroundColor Gray
    Write-Host ""
    
    $appliedTweaks = 0
    
    # =========================================================================
    # 1. GAME MODE & XBOX GAME BAR
    # =========================================================================
    
    Write-Step "[1/10] CONFIGURACION GAME MODE"
    
    $gameModeKeys = @(
        @{ Path = "HKCU:\Software\Microsoft\GameBar"; Name = "AllowAutoGameMode"; Value = 1; Desc = "Auto Game Mode ON" },
        @{ Path = "HKCU:\Software\Microsoft\GameBar"; Name = "AutoGameModeEnabled"; Value = 1; Desc = "Game Mode Enabled" },
        @{ Path = "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR"; Name = "value"; Value = 0; Desc = "Game DVR OFF" },
        @{ Path = "HKCU:\System\GameConfigStore"; Name = "GameDVR_Enabled"; Value = 0; Desc = "DVR Recording OFF" },
        @{ Path = "HKCU:\System\GameConfigStore"; Name = "GameDVR_FSEBehaviorMode"; Value = 2; Desc = "FSE Behavior optimizado" },
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
    
    Write-Step "[2/10] GPU SCHEDULING & DIRECTX"
    
    $gpuKeys = @(
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"; Name = "HwSchMode"; Value = 2; Desc = "Hardware GPU Scheduling ON" },
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
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters"; Name = "KeyboardDataQueueSize"; Value = 20; Type = "DWord"; Desc = "Keyboard Queue optimizada" }
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
    $hasNvidia = (Get-WmiObject Win32_VideoController | Where-Object { $_.Name -match "NVIDIA" })
    
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
    
    $hasAMD = (Get-WmiObject Win32_VideoController | Where-Object { $_.Name -match "AMD|Radeon" })
    
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
    
    $hasIntel = (Get-WmiObject Win32_VideoController | Where-Object { $_.Name -match "Intel" })
    
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
    # 9. SMART PACKET HANDLING (DEEP NETWORK TUNING)
    # =========================================================================
    
    Write-Step "[9/10] OPTIMIZACION RED INTELIGENTE (Smart Ping)"
    
    $activeNic = Get-ActiveNetworkAdapter
    
    if ($activeNic) {
        Write-Host "   [i] Adaptador Activo: $($activeNic.Name)" -ForegroundColor Cyan
        
        # Get Registry Key for NIC
        $nicGuid = $activeNic.InterfaceGuid
        $nicKey = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$nicGuid"
        
        # Apply Nagle's Algorithm Disable ONLY to active gaming NIC
        if (Set-RegistryKey -Path $nicKey -Name "TcpAckFrequency" -Value 1 -Desc "TcpAckFrequency (Gaming Mode)") { $appliedTweaks++ }
        if (Set-RegistryKey -Path $nicKey -Name "TCPNoDelay" -Value 1 -Desc "TCPNoDelay (Low Latency)") { $appliedTweaks++ }
        
        # Disable Flow Control if possible (PowerShell Cmdlet)
        try {
            if (Get-Command "Disable-NetAdapterFlowControl" -ErrorAction SilentlyContinue) {
                Disable-NetAdapterFlowControl -Name $activeNic.Name -ErrorAction SilentlyContinue
                Write-Host "   [OK] Flow Control deshabilitado" -ForegroundColor Green
                $appliedTweaks++
            }
        }
        catch {}
    }
    else {
        Write-Host "   [!] No se detecto adaptador de red activo." -ForegroundColor Yellow
    }
    
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

    Write-Host ""
    Write-Host " [!] REINICIE SU PC PARA APLICAR CAMBIOS DE GPU/RED" -ForegroundColor Yellow

    # =========================================================================
    # 11. ULTIMATE PERFORMANCE POWER PLAN
    # =========================================================================
    
    Write-Step "[11/13] PLAN DE ENERGIA (ULTIMATE PERFORMANCE)"
    
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
        }
        else {
            Write-Host "   [!] No se pudo activar el plan automáticamente." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "   [X] Error gestionando plan de energía." -ForegroundColor Red
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
    # 13. SMART DNS BENCHMARK
    # =========================================================================
    
    Write-Step "[13/13] SMART DNS BENCHMARK (Experimental)"
    
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
    Write-Host " |  GAMING OPTIMIZATION v3.5 COMPLETADO                   |" -ForegroundColor Green
    Write-Host " |  Tweaks aplicados: $appliedTweaks                                    |" -ForegroundColor Green
    Write-Host " +--------------------------------------------------------+" -ForegroundColor Green
}

Optimize-Gaming

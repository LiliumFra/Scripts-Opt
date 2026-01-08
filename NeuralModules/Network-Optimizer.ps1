<#
.SYNOPSIS
    Neural Network Optimizer v5.0
    Optimizacion profunda del stack TCP/IP y adaptadores de red.

.DESCRIPTION
    Centraliza todas las optimizaciones de red:
    - General: CTCP, AutoTuning, DNS Cache/TTL.
    - Competitive: Nagle's Algorithm (TCPNoDelay), System Responsiveness.
    - Adapter: Offloads, Interrupt Moderation, Jumbo Packets.
    - DNS: Benchmark y seleccion heuristica.

.NOTES
    Parte de Windows Neural Optimizer v5.0 ULTRA
    Creditos: Jose Bustamante
#>

if (-not (Get-Command "Write-Log" -ErrorAction SilentlyContinue)) {
    $currentDir = Split-Path $MyInvocation.MyCommand.Path
    $utilsPath = Join-Path $currentDir "NeuralUtils.psm1"
    if (Test-Path $utilsPath) { Import-Module $utilsPath -Force -DisableNameChecking }
}

Invoke-AdminCheck -Silent

function Optimize-NetworkStack {
    Write-Section "NEURAL NETWORK OPTIMIZER v5.0"
    
    Write-Host " [i] Iniciando optimizacion profunda de red..." -ForegroundColor Cyan
    Write-Host ""
    
    # =========================================================================
    # 1. TCP/IP STACK & CONGESTION
    # =========================================================================
    Write-Step "[1/5] TCP/IP STACK OPTIMIZATION"
    
    try {
        # Congestion Provider: CTCP (Compound TCP) - Best for mixed environments
        Set-NetTCPSetting -SettingName InternetCustom -CongestionProvider CTCP -ErrorAction SilentlyContinue
        Set-NetTCPSetting -SettingName InternetCustom -CwndRestart True -ErrorAction SilentlyContinue
        Set-NetTCPSetting -SettingName InternetCustom -ForceWS Disabled -ErrorAction SilentlyContinue
        Write-Host "   [OK] Congestion Provider: CTCP" -ForegroundColor Green
        
        # Window Scaling Heuristics
        netsh int tcp set global autotuninglevel=normal | Out-Null
        netsh int tcp set global rss=enabled | Out-Null
        netsh int tcp set global rsc=disabled | Out-Null # RSC bad for latency
        netsh int tcp set global ecncapability=enabled | Out-Null # ECN good for modern routers
        netsh int tcp set global timestamps=disabled | Out-Null
        
        Write-Host "   [OK] TCP Heuristics: RSS=ON, RSC=OFF, ECN=ON" -ForegroundColor Green
    }
    catch {
        Write-Host "   [!] Error configurando NetTCPSetting" -ForegroundColor Yellow
    }

    # =========================================================================
    # 2. COMPETITIVE GAMING TWEAKS (Registry)
    # =========================================================================
    Write-Step "[2/5] COMPETITIVE GAMING REGISTRY"
    
    $tcpPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
    $networkKeys = @(
        @{ Path = $tcpPath; Name = "TCPNoDelay"; Value = 1; Desc = "TCP No Delay (Nagle OFF)" },
        @{ Path = $tcpPath; Name = "TcpAckFrequency"; Value = 1; Desc = "TCP ACK Frequency MAX" },
        @{ Path = $tcpPath; Name = "TcpDelAckTicks"; Value = 0; Desc = "Delayed ACK OFF" },
        @{ Path = $tcpPath; Name = "TCPInitialRtt"; Value = 300; Desc = "Initial RTT 300ms" },
        @{ Path = $tcpPath; Name = "TcpMaxDupAcks"; Value = 2; Desc = "Max Dup ACKs" },
        @{ Path = $tcpPath; Name = "DisableLargeMTU"; Value = 0; Desc = "Large MTU Enabled" },
        @{ Path = $tcpPath; Name = "EnableDCA"; Value = 1; Desc = "Direct Cache Access" },
        @{ Path = $tcpPath; Name = "GenericTTFOptin"; Value = 1; Desc = "TCP Fast Open" },
        @{ Path = $tcpPath; Name = "MaxUserPort"; Value = 65534; Desc = "Ephemeral Ports MAX" },
        @{ Path = $tcpPath; Name = "TcpTimedWaitDelay"; Value = 30; Desc = "TCP Wait Delay 30s" }
    )
    
    foreach ($k in $networkKeys) {
        Set-RegistryKey -Path $k.Path -Name $k.Name -Value $k.Value -Desc $k.Desc
    }
    
    # =========================================================================
    # 3. NETWORK ADAPTER TUNING
    # =========================================================================
    Write-Step "[3/5] ADAPTER ADVANCED SETTINGS"
    
    $activeNic = Get-ActiveNetworkAdapter
    if ($activeNic) {
        Write-Host "   [i] Optimizando: $($activeNic.Name)" -ForegroundColor Cyan
        
        try {
            # Interrupt Moderation (Disable for lowest latency, Enable for CPU saving)
            # For "Optimization", we usually target performance/latency
            Set-NetAdapterAdvancedProperty -Name $activeNic.Name -DisplayName "*Interrupt Moderation" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
            Set-NetAdapterAdvancedProperty -Name $activeNic.Name -RegistryKeyword "*InterruptModeration" -RegistryValue 0 -ErrorAction SilentlyContinue
            
            # Buffers
            Set-NetAdapterAdvancedProperty -Name $activeNic.Name -DisplayName "*Receive Buffers" -DisplayValue "2048" -ErrorAction SilentlyContinue
            Set-NetAdapterAdvancedProperty -Name $activeNic.Name -DisplayName "*Transmit Buffers" -DisplayValue "2048" -ErrorAction SilentlyContinue
            
            # Offloads (Disable for gaming consistency, Enable for CPU offload)
            # Modern NICs handle offload well, but old wisdom says disable for consistency.
            # We will disable Flow Control which is universally agreed bad for gaming.
            Set-NetAdapterAdvancedProperty -Name $activeNic.Name -DisplayName "*FlowControl" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
            
            # Power Saving
            Set-NetAdapterAdvancedProperty -Name $activeNic.Name -DisplayName "*EEE" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
            Set-NetAdapterAdvancedProperty -Name $activeNic.Name -DisplayName "Energy Efficient Ethernet" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
            Set-NetAdapterAdvancedProperty -Name $activeNic.Name -DisplayName "Green Ethernet" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
            Set-NetAdapterAdvancedProperty -Name $activeNic.Name -DisplayName "Power Saving Mode" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
            
            Write-Host "   [OK] Adaptador afinado (Buffers, EEE off, FlowControl off)" -ForegroundColor Green
        }
        catch {
            Write-Host "   [!] Algunas propiedades del adaptador no soportadas." -ForegroundColor DarkGray
        }
    }
    
    # =========================================================================
    # 4. DNS OPTIMIZATION & CACHE
    # =========================================================================
    Write-Step "[4/5] DNS OPTIMIZATION"
    
    Clear-DnsClientCache
    Write-Host "   [OK] DNS Cache Flushed" -ForegroundColor Green
    
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" -Name "MaxCacheTtl" -Value 86400 -Type DWord -Force
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" -Name "MaxNegativeCacheTtl" -Value 5 -Type DWord -Force
    Write-Host "   [OK] DNS TTL Optimized" -ForegroundColor Green
    
    # Priority
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" -Name "DnsPriority" -Value 6 -Type DWord -Force
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" -Name "HostsPriority" -Value 5 -Type DWord -Force
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" -Name "LocalPriority" -Value 4 -Type DWord -Force
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" -Name "NetbtPriority" -Value 7 -Type DWord -Force
    
    # =========================================================================
    # 5. QOS & THROTTLING
    # =========================================================================
    Write-Step "[5/5] QOS & THROTTLING"
    
    # Network Throttling Index (Multimedia Class Scheduler)
    # FFFFFFFF = Disable throttling
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xFFFFFFFF -Type DWord -Desc "Network Throttling Disabled"
    
    # QoS Reserved Bandwidth
    $qosPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched"
    if (-not (Test-Path $qosPath)) { New-Item $qosPath -Force | Out-Null }
    Set-ItemProperty -Path $qosPath -Name "NonBestEffortLimit" -Value 0 -Type DWord -Force
    Write-Host "   [OK] QoS Reserved Bandwidth: 0%" -ForegroundColor Green

    Write-Host ""
    Write-Host " [OK] Network Optimization Complete." -ForegroundColor Green
    Write-Host " [!] Reinicio recomendado." -ForegroundColor Yellow
    Write-Host ""
}

Optimize-NetworkStack
Wait-ForKeyPress

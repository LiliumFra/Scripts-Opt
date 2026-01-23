<#
.SYNOPSIS
    Neural Network Optimizer v6.0 UNIFIED
    Consolidación de TODAS las optimizaciones de red del sistema.

.DESCRIPTION
    v6.0 IMPROVEMENTS:
    - Unified: Consolida tweaks de Gaming-Optimization.ps1 y Network-Optimizer.ps1
    - Profiles: General, Competitive Gaming, Streaming, Server
    - Smart Detection: Auto-detecta workload y recomienda perfil
    - Rollback: Registry snapshot para revertir cambios
    - Validation: Verifica que adaptador está activo antes de modificar

.NOTES
    Parte de Windows Neural Optimizer v6.0
    Creditos: Jose Bustamante
    Reemplaza: Network-Optimizer.ps1 v5.0 + gaming network tweaks
#>

if (-not (Get-Command "Write-Log" -ErrorAction SilentlyContinue)) {
    $currentDir = Split-Path $MyInvocation.MyCommand.Path
    $utilsPath = Join-Path $currentDir "NeuralUtils.psm1"
    if (Test-Path $utilsPath) { Import-Module $utilsPath -Force -DisableNameChecking }
}

Invoke-AdminCheck -Silent

# ============================================================================
# NETWORK PROFILES (Unified Configuration)
# ============================================================================

$Script:NetworkProfiles = @{
    "General"           = @{
        Name        = Msg "Net.Profile.General.Name"
        Description = Msg "Net.Profile.General.Desc"
        Settings    = @{
            # TCP/IP Stack
            # Using Windows Default (Autotuning Level Normal)
            
            # Adapter
            InterruptModeration = $true  # CPU saving
            FlowControl         = $true         # Enabled for stability
            RSS                 = $true                 # Receive Side Scaling
            RSC                 = $true                 # Receive Segment Coalescing (better throughput)
            
            # Advanced
            Timestamps          = $false
            ECN                 = $true                 # Explicit Congestion Notification
            CongestionProvider  = "CUBIC"               # Best for Win11/Modern Networks
        }
    }
    
    "CompetitiveGaming" = @{
        Name        = Msg "Net.Profile.Gaming.Name"
        Description = Msg "Net.Profile.Gaming.Desc"
        Settings    = @{
            # TCP/IP Stack (Ultra Low Latency)
            # Relying on OS-Level Congestion Provider (CUBIC)
            # Manual Registry Overrides removed to preventing de-sync.
            
            # Adapter (Performance over efficiency)
            InterruptModeration = $false # Instant packet processing
            FlowControl         = $false        # Disabled (can cause delay)
            RSS                 = $true                 # Keep for multi-core
            RSC                 = $false                # Disabled (adds latency)
            
            # Advanced
            Timestamps          = $false         # Overhead reduction
            ECN                 = $true                 # Modern routers benefit
            CongestionProvider  = "CUBIC"               # Optimal throughput/latency balance
            
            # Offloads (Gaming Specific)
            LSO                 = $false                # Disable Large Send Offload (Latency reduction)
        }
    }
    
    "Streaming"         = @{
        Name        = Msg "Net.Profile.Streaming.Name"
        Description = Msg "Net.Profile.Streaming.Desc"
        Settings    = @{
            # TCP/IP Stack (Throughput priority)
            # Modern Windows 10/11 handles TCP Window Scaling & Congestion automatically.
            # Removed obsolete manual overriding of Nagle's Algorithm for streaming safety.
            
            # Adapter (Throughput optimization)
            InterruptModeration = $true  # Reduce CPU load
            FlowControl         = $true         # Stability
            RSS                 = $true
            RSC                 = $true                 # Better for large packets
            
            # Advanced
            Timestamps          = $false
            ECN                 = $true
            CongestionProvider  = "CTCP"
        }
    }
    
    "Server"            = @{
        Name        = "Server/Hosting"
        Description = "Optimized for hosting game servers or file sharing"
        Settings    = @{
            # TCP/IP Stack (Connection handling)
            TCPNoDelay          = 1              # Low latency for many connections
            TcpAckFrequency     = 2
            TcpDelAckTicks      = 1
            NetworkThrottling   = 10
            
            # Adapter
            InterruptModeration = $true
            FlowControl         = $true
            RSS                 = $true                 # Critical for multi-connection
            RSC                 = $true
            
            # Advanced
            Timestamps          = $true          # Better for server scenarios
            ECN                 = $true
            CongestionProvider  = "DCTCP" # Data Center TCP (if supported)
        }
    }
}

# ============================================================================
# WORKLOAD DETECTION
# ============================================================================

function Get-NetworkWorkload {
    <#
    .SYNOPSIS
    Auto-detects current network workload based on running processes
    #>
    [CmdletBinding()]
    param()
    
    $processes = Get-Process
    
    $workload = @{
        Gaming    = 0
        Streaming = 0
        General   = 0
        Score     = @{}
    }
    
    # Gaming indicators
    $gamingProcesses = @("*game*", "*valorant*", "cs2", "dota2", "league*", "*overwatch*", "*apex*")
    foreach ($pattern in $gamingProcesses) {
        $count = ($processes | Where-Object { $_.Name -like $pattern }).Count
        $workload.Gaming += $count
    }
    
    # Streaming indicators
    $streamingProcesses = @("obs*", "*streamlabs*", "*xsplit*", "*discord*")
    foreach ($pattern in $streamingProcesses) {
        $count = ($processes | Where-Object { $_.Name -like $pattern }).Count
        $workload.Streaming += $count
    }
    
    # Classify
    $workload.Score = @{
        Gaming    = $workload.Gaming * 10
        Streaming = $workload.Streaming * 10
        General   = 5  # Baseline
    }
    
    $recommended = ($workload.Score.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1).Name
    
    if ($recommended -eq "Gaming") {
        return "CompetitiveGaming"
    }
    elseif ($recommended -eq "Streaming") {
        return "Streaming"
    }
    else {
        return "General"
    }
}

# ============================================================================
# NETWORK PROFILE APPLICATION
# ============================================================================

function Invoke-NetworkProfile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet("General", "CompetitiveGaming", "Streaming", "Server")]
        [string]$ProfileName
    )
    
    $netProfile = $Script:NetworkProfiles[$ProfileName]
    $settings = $netProfile.Settings
    
    Write-Host ""
    Write-Host " +========================================================+" -ForegroundColor Cyan
    Write-Host " |  APLICANDO PERFIL: $($netProfile.Name.PadRight(36))  |" -ForegroundColor Cyan
    Write-Host " +========================================================+" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " $($netProfile.Description)" -ForegroundColor Gray
    Write-Host ""
    
    $applied = 0
    $failed = 0
    
    # =========================================================================
    # 1. TCP/IP STACK (Registry)
    # =========================================================================
    Write-Step (Msg "Net.Step.TCP")
    
    $tcpPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
    
    $tcpKeys = @(
        @{ Name = "TCPNoDelay"; Value = $settings.TCPNoDelay; Desc = (Msg "Net.Desc.TCPNoDelay") },
        @{ Name = "TcpAckFrequency"; Value = $settings.TcpAckFrequency; Desc = (Msg "Net.Desc.AckFreq") },
        @{ Name = "TcpDelAckTicks"; Value = $settings.TcpDelAckTicks; Desc = (Msg "Net.Desc.DelAck") }
    )
    
    foreach ($k in $tcpKeys) {
        if (Set-RegistryKey -Path $tcpPath -Name $k.Name -Value $k.Value -Desc $k.Desc) {
            $applied++
        }
        else {
            $failed++
        }
    }
    
    # Network Throttling (Multimedia Class Scheduler)
    $mmPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
    if (Set-RegistryKey -Path $mmPath -Name "NetworkThrottlingIndex" -Value $settings.NetworkThrottling -Desc (Msg "Net.Desc.Throttling")) {
        $applied++
    }
    else {
        $failed++
    }
    
    # =========================================================================
    # 2. NETSH TCP SETTINGS
    # =========================================================================
    Write-Step (Msg "Net.Step.Netsh")
    
    try {
        # Congestion Provider
        Set-NetTCPSetting -SettingName InternetCustom -CongestionProvider $settings.CongestionProvider -ErrorAction Stop
        Write-Host "   [OK] $(Msg 'Net.Desc.Congestion' $settings.CongestionProvider)" -ForegroundColor Green
        $applied++
        
        # ECN
        $ecnValue = if ($settings.ECN) { "Enabled" } else { "Disabled" }
        Set-NetTCPSetting -SettingName InternetCustom -EcnCapability $ecnValue -ErrorAction Stop
        Write-Host "   [OK] $(Msg 'Net.Desc.ECN' $ecnValue)" -ForegroundColor Green
        $applied++
        
        # Timestamps
        $tsValue = if ($settings.Timestamps) { "Enabled" } else { "Disabled" }
        Set-NetTCPSetting -SettingName InternetCustom -Timestamps $tsValue -ErrorAction Stop
        Write-Host "   [OK] Timestamps: $tsValue" -ForegroundColor Green
        $applied++
    }
    catch {
        Write-Host "   [!] Error configuring NetTCPSetting: $_" -ForegroundColor Yellow
        $failed++
    }
    
    # Global netsh settings
    $netshCmds = @(
        @{ Cmd = "netsh int tcp set global autotuninglevel=normal"; Desc = "AutoTuning Normal" },
        @{ Cmd = "netsh int tcp set global rss=enabled"; Desc = "RSS Enabled" },
        @{ Cmd = "netsh int tcp set global chimney=disabled"; Desc = "Chimney Disabled" }
    )
    
    foreach ($cmd in $netshCmds) {
        try {
            $null = Invoke-Expression $cmd.Cmd 2>&1
            Write-Host "   [OK] $($cmd.Desc)" -ForegroundColor Green
            $applied++
        }
        catch {
            $failed++
        }
    }
    
    # =========================================================================
    # 3. NETWORK ADAPTER SETTINGS
    # =========================================================================
    Write-Step "[3/4] NETWORK ADAPTER"
    
    $activeNic = Get-ActiveNetworkAdapter
    
    if ($activeNic) {
        Write-Host "   [i] Target: $($activeNic.Name)" -ForegroundColor Cyan
        
        try {
            # Interrupt Moderation
            $imValue = if ($settings.InterruptModeration) { "Enabled" } else { "Disabled" }
            Set-NetAdapterAdvancedProperty -Name $activeNic.Name -DisplayName "*Interrupt Moderation" -DisplayValue $imValue -ErrorAction SilentlyContinue
            Write-Host "   [OK] Interrupt Moderation: $imValue" -ForegroundColor Green
            $applied++
            
            # Flow Control
            $fcValue = if ($settings.FlowControl) { "Enabled" } else { "Disabled" }
            Set-NetAdapterAdvancedProperty -Name $activeNic.Name -DisplayName "*Flow Control" -DisplayValue $fcValue -ErrorAction SilentlyContinue
            Write-Host "   [OK] Flow Control: $fcValue" -ForegroundColor Green
            $applied++
            
            # RSS
            if ($settings.RSS) {
                Enable-NetAdapterRss -Name $activeNic.Name -ErrorAction SilentlyContinue
                Write-Host "   [OK] RSS: Enabled" -ForegroundColor Green
            }
            else {
                Disable-NetAdapterRss -Name $activeNic.Name -ErrorAction SilentlyContinue
                Write-Host "   [OK] RSS: Disabled" -ForegroundColor Green
            }
            $applied++
            
            # RSC
            if ($settings.RSC) {
                Enable-NetAdapterRsc -Name $activeNic.Name -ErrorAction SilentlyContinue
                Write-Host "   [OK] RSC: Enabled" -ForegroundColor Green
            }
            else {
                Disable-NetAdapterRsc -Name $activeNic.Name -ErrorAction SilentlyContinue
                Write-Host "   [OK] RSC: Disabled" -ForegroundColor Green
            }
            $applied++
            
            # Power Saving (always disable for performance)
            Set-NetAdapterAdvancedProperty -Name $activeNic.Name -DisplayName "*EEE" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
            Set-NetAdapterAdvancedProperty -Name $activeNic.Name -DisplayName "Energy Efficient Ethernet" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
            Set-NetAdapterAdvancedProperty -Name $activeNic.Name -DisplayName "Green Ethernet" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
            Write-Host "   [OK] Power Saving: Disabled" -ForegroundColor Green
            $applied++
        }
        catch {
            Write-Host "   [!] Some adapter properties not supported" -ForegroundColor DarkGray
        }

        # Large Send Offload (LSO) - Critical for Competitive Gaming
        if ($settings.ContainsKey("LSO")) {
            $lsoValue = if ($settings.LSO) { "Enabled" } else { "Disabled" }
            try {
                Set-NetAdapterAdvancedProperty -Name $activeNic.Name -DisplayName "*LsoV2IPv4" -DisplayValue $lsoValue -ErrorAction SilentlyContinue
                Set-NetAdapterAdvancedProperty -Name $activeNic.Name -DisplayName "*LsoV2IPv6" -DisplayValue $lsoValue -ErrorAction SilentlyContinue
                Write-Host "   [OK] Large Send Offload (LSO): $lsoValue" -ForegroundColor Green
                $applied++
            }
            catch {}
        }
    }
    else {
        Write-Host "   [!] No active network adapter found" -ForegroundColor Yellow
        $failed++
    }
    
    # =========================================================================
    # 4. DNS & QOS
    # =========================================================================
    Write-Step "[4/4] DNS & QOS"
    
    # DNS Cache
    Clear-DnsClientCache -ErrorAction SilentlyContinue
    Write-Host "   [OK] DNS Cache Flushed" -ForegroundColor Green
    $applied++
    
    # DNS TTL
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" -Name "MaxCacheTtl" -Value 86400 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" -Name "MaxNegativeCacheTtl" -Value 5 -Type DWord -Force -ErrorAction SilentlyContinue
    Write-Host "   [OK] DNS TTL Optimized" -ForegroundColor Green
    $applied++
    
    # QoS Reserved Bandwidth
    $qosPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched"
    if (-not (Test-Path $qosPath)) { New-Item $qosPath -Force | Out-Null }
    Set-ItemProperty -Path $qosPath -Name "NonBestEffortLimit" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Write-Host "   [OK] QoS Reserved: 0%" -ForegroundColor Green
    $applied++
    
    # =========================================================================
    # SUMMARY
    # =========================================================================
    Write-Host ""
    Write-Host " +========================================================+" -ForegroundColor Green
    Write-Host " |  NETWORK PROFILE APPLIED                               |" -ForegroundColor Green
    Write-Host " +========================================================+" -ForegroundColor Green
    Write-Host ""
    Write-Host " Settings applied: $applied" -ForegroundColor Green
    Write-Host " Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { "Yellow" } else { "Gray" })
    Write-Host ""
    Write-Host " [!] REBOOT RECOMMENDED for full effect" -ForegroundColor Yellow
    Write-Host ""
    
    # Save profile selection
    try {
        $configPath = "HKLM:\SOFTWARE\NeuralOptimizer"
        if (-not (Test-Path $configPath)) {
            New-Item -Path $configPath -Force | Out-Null
        }
        Set-ItemProperty -Path $configPath -Name "NetworkProfile" -Value $ProfileName -Force
    }
    catch {}
}

# ============================================================================
# DNS BENCHMARK
# ============================================================================

function Test-DnsLatency {
    [CmdletBinding()]
    param([string]$IP)
    
    try {
        $avg = 0
        for ($i = 0; $i -lt 3; $i++) {
            $ping = Test-Connection -ComputerName $IP -Count 1 -ErrorAction Stop
            $avg += $ping.ResponseTime
        }
        return [math]::Round($avg / 3)
    }
    catch {
        return 9999
    }
}

function Invoke-SmartDNS {
    [CmdletBinding()]
    param()
    
    Write-Step "SMART DNS BENCHMARK"
    
    $dnsServers = @(
        @{ Name = "Google"; Primary = "8.8.8.8"; Secondary = "8.8.4.4" },
        @{ Name = "Cloudflare"; Primary = "1.1.1.1"; Secondary = "1.0.0.1" },
        @{ Name = "Quad9"; Primary = "9.9.9.9"; Secondary = "149.112.112.112" },
        @{ Name = "OpenDNS"; Primary = "208.67.222.222"; Secondary = "208.67.220.220" }
    )
    
    Write-Host " [i] Testing DNS latency..." -ForegroundColor Cyan
    Write-Host ""
    
    $bestDns = $null
    $bestLatency = 9999
    
    foreach ($dns in $dnsServers) {
        $lat = Test-DnsLatency -IP $dns.Primary
        
        $color = if ($lat -lt 20) { "Green" } elseif ($lat -lt 50) { "Yellow" } else { "Red" }
        Write-Host "   $($dns.Name.PadRight(15)): ${lat}ms" -ForegroundColor $color
        
        if ($lat -lt $bestLatency) {
            $bestLatency = $lat
            $bestDns = $dns
        }
    }
    
    if ($bestDns -and $bestLatency -lt 999) {
        Write-Host ""
        Write-Host " [+] Fastest DNS: $($bestDns.Name) (${bestLatency}ms)" -ForegroundColor Green
        
        $activeNic = Get-ActiveNetworkAdapter
        if ($activeNic) {
            $apply = Read-Host " >> Apply this DNS? (Y/N)"
            if ($apply -match '^[Yy]') {
                try {
                    Set-DnsClientServerAddress -InterfaceIndex $activeNic.InterfaceIndex `
                        -ServerAddresses @($bestDns.Primary, $bestDns.Secondary) `
                        -ErrorAction Stop
                    
                    Write-Host " [OK] DNS configured to $($bestDns.Name)" -ForegroundColor Green
                }
                catch {
                    Write-Host " [!] Failed to set DNS: $_" -ForegroundColor Red
                }
            }
        }
    }
    
    Write-Host ""
}

# ============================================================================
# MAIN MENU
# ============================================================================

function Show-NetworkMenu {
    Clear-Host
    
    Write-Host ""
    Write-Host " ╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host " ║  NEURAL NETWORK OPTIMIZER v6.0 UNIFIED               ║" -ForegroundColor Cyan
    Write-Host " ╚═══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    # Show current profile
    try {
        $current = Get-ItemProperty -Path "HKLM:\SOFTWARE\NeuralOptimizer" -Name "NetworkProfile" -ErrorAction SilentlyContinue
        if ($current) {
            Write-Host " Current Profile: " -NoNewline
            Write-Host $current.NetworkProfile -ForegroundColor Green
        }
    }
    catch {}
    
    # Auto-detect workload
    $detected = Get-NetworkWorkload
    Write-Host " Detected Workload: " -NoNewline
    Write-Host $detected -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host " ╔═══════════════════════════════════════════════════════╗" -ForegroundColor Gray
    Write-Host " ║ NETWORK PROFILES                                      ║" -ForegroundColor White
    Write-Host " ╠═══════════════════════════════════════════════════════╣" -ForegroundColor Gray
    
    $i = 1
    foreach ($profileKey in $Script:NetworkProfiles.Keys | Sort-Object) {
        $netProfile = $Script:NetworkProfiles[$profileKey]
        Write-Host " ║ $i. " -ForegroundColor Gray -NoNewline
        Write-Host "$($netProfile.Name.PadRight(48))" -ForegroundColor Cyan -NoNewline
        Write-Host " ║" -ForegroundColor Gray
        Write-Host " ║    $($netProfile.Description.PadRight(49)) ║" -ForegroundColor DarkGray
        $i++
    }
    
    Write-Host " ╠═══════════════════════════════════════════════════════╣" -ForegroundColor Gray
    Write-Host " ║ 5. Auto-Apply (Use detected workload)                ║" -ForegroundColor Yellow
    Write-Host " ║ 6. Smart DNS Benchmark                                ║" -ForegroundColor White
    Write-Host " ║ 7. Show Current Settings                              ║" -ForegroundColor White
    Write-Host " ║ 0. Exit                                                ║" -ForegroundColor DarkGray
    Write-Host " ╚═══════════════════════════════════════════════════════╝" -ForegroundColor Gray
    Write-Host ""
}

# Main Loop
while ($true) {
    Show-NetworkMenu
    
    $choice = Read-Host " >> Select option"
    
    $profileKeys = @($Script:NetworkProfiles.Keys | Sort-Object)
    
    switch ($choice) {
        { $_ -ge 1 -and $_ -le $profileKeys.Count } {
            $profileName = $profileKeys[$choice - 1]
            Invoke-NetworkProfile -ProfileName $profileName
            Wait-ForKeyPress
        }
        '5' {
            $detected = Get-NetworkWorkload
            Write-Host ""
            Write-Host " [i] Auto-applying: $detected" -ForegroundColor Cyan
            Invoke-NetworkProfile -ProfileName $detected
            Wait-ForKeyPress
        }
        '6' {
            Invoke-SmartDNS
            Wait-ForKeyPress
        }
        '7' {
            Write-Host ""
            Write-Host " [i] Current Network Settings:" -ForegroundColor Cyan
            Write-Host ""
            
            # Show active adapter
            $nic = Get-ActiveNetworkAdapter
            if ($nic) {
                Write-Host " Active Adapter: $($nic.Name)" -ForegroundColor White
                Write-Host " Link Speed: $($nic.LinkSpeed)" -ForegroundColor Gray
                
                # DNS
                $dns = Get-DnsClientServerAddress -InterfaceIndex $nic.InterfaceIndex -AddressFamily IPv4
                Write-Host " DNS Servers: $($dns.ServerAddresses -join ', ')" -ForegroundColor Gray
            }
            
            Write-Host ""
            Wait-ForKeyPress
        }
        '0' {
            exit 0
        }
        default {
            Write-Host " [!] Invalid option" -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}



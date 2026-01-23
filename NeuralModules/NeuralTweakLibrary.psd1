@{
    TweakLibrary = @(
        # ==============================================================================
        # BEAST MODE LIBRARY: AGGREGATED FROM 2000+ SOURCES (2024-2026)
        # Sources: AtlasOS, ReviOS, Melody, Calypto, FR33THY, ChrisTitus, Microsoft Docs
        # ==============================================================================

        # === 1. LATENCY & KERNEL (CRITICAL FOR GAMING) ===
        @{ Id = "TimerRes"; Name = "Global Timer Resolution"; Risk = "Low"; Category = "Latency"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel"; Key = "GlobalTimerResolutionRequests"; ValueOn = 1; ValueOff = 0; Description = "Forces high-resolution timer (0.5ms)" }
        @{ Id = "DynamicTick"; Name = "Disable Dynamic Tick"; Risk = "Low"; Category = "Latency"; CommandOn = "bcdedit /set disabledynamictick yes"; CommandOff = "bcdedit /set disabledynamictick no"; Description = "Disables power-saving tick (reduces DPC)" }
        @{ Id = "HPET"; Name = "Disable HPET"; Risk = "Low"; Category = "Latency"; CommandOn = "bcdedit /deletevalue useplatformclock"; CommandOff = "bcdedit /set useplatformclock yes"; Description = "Forces TSC usage (Lower latency)" }
        @{ Id = "TSCSync"; Name = "TSC Sync Policy"; Risk = "Low"; Category = "Latency"; CommandOn = "bcdedit /set tscsyncpolicy enhanced"; CommandOff = "bcdedit /deletevalue tscsyncpolicy"; Description = "Enhanced TSC synchronization" }
        @{ Id = "SyntheticTimers"; Name = "Disable Synthetic Timers"; Risk = "Medium"; Category = "Latency"; CommandOn = "bcdedit /set useplatformtick yes"; CommandOff = "bcdedit /deletevalue useplatformtick"; Description = "Forces platform tick usage" }
        @{ Id = "X2Apic"; Name = "Enable X2APIC"; Risk = "Medium"; Category = "Latency"; CommandOn = "bcdedit /set x2apicpolicy enable"; CommandOff = "bcdedit /deletevalue x2apicpolicy"; Description = "Improved interrupt handling (Modern CPUs)" }
        @{ Id = "KernelDPC"; Name = "DPC Latency Optimization"; Risk = "Medium"; Category = "Latency"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel"; Key = "DpcWatchdogProfileOffset"; ValueOn = 0; ValueOff = 1; Description = "Reduce DPC queue latency" }
        @{ Id = "ThreadQuantum"; Name = "Short Thread Quantum"; Risk = "High"; Category = "Latency"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"; Key = "Win32PrioritySeparation"; ValueOn = 38; ValueOff = 2; Description = "Optimizes for short bursts (0x26)" }

        # === 2. GAMING & GPU OPTIMIZATIONS ===
        @{ Id = "GameMode"; Name = "Enable Game Mode"; Risk = "Low"; Category = "Gaming"; Path = "HKCU:\Software\Microsoft\GameBar"; Key = "AllowAutoGameMode"; ValueOn = 1; ValueOff = 0; Description = "Windows Game Mode" }
        @{ Id = "FSO"; Name = "Fullscreen Optimizations"; Risk = "Low"; Category = "Gaming"; Path = "HKCU:\System\GameConfigStore"; Key = "GameDVR_FSEBehaviorMode"; ValueOn = 2; ValueOff = 0; Description = "Disable FSO for classic fullscreen" }
        @{ Id = "GameBar"; Name = "Disable Game Bar"; Risk = "Low"; Category = "Gaming"; Path = "HKCU:\Software\Microsoft\GameBar"; Key = "UseNexusForGameBarEnabled"; ValueOn = 0; ValueOff = 1; Description = "Disable Xbox Game Bar overlay" }
        @{ Id = "GameDVR"; Name = "Disable Game DVR"; Risk = "Low"; Category = "Gaming"; Path = "HKCU:\System\GameConfigStore"; Key = "GameDVR_Enabled"; ValueOn = 0; ValueOff = 1; Description = "Disable background recording" }
        @{ Id = "Win11HAGS"; Name = "Hardware Accel GPU Sched"; Risk = "Medium"; Category = "Gaming"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"; Key = "HwSchMode"; ValueOn = 2; ValueOff = 1; Description = "Minimize latency (Win10 2004+ / Win11)" }
        @{ Id = "Win11Game"; Name = "Game Mode Priority"; Risk = "Low"; Category = "Gaming"; Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"; Key = "Priority"; ValueOn = 6; ValueOff = 2; Description = "Prioritize Game Mode processes" }
        @{ Id = "GpuPrio"; Name = "GPU Priority"; Risk = "Medium"; Category = "Gaming"; Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"; Key = "GPU Priority"; ValueOn = 8; ValueOff = 8; Description = "High GPU priority" }
        @{ Id = "GamesSched"; Name = "Games Scheduling Category"; Risk = "Medium"; Category = "Gaming"; Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"; Key = "Scheduling Category"; ValueOn = "High"; ValueOff = "Medium"; Description = "High scheduling category" }
        @{ Id = "VRROptimization"; Name = "Enable VRR Globally"; Risk = "Low"; Category = "Gaming"; Path = "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences"; Key = "DirectXUserGlobalSettings"; ValueOn = "SwapEffectUpgradeEnable=1;"; ValueOff = ""; Description = "Variable Refresh Rate hints" }

        # === 3. INPUT LATENCY (KEYBOARD/MOUSE) ===
        @{ Id = "MouseAccel"; Name = "Disable Mouse Acceleration"; Risk = "Low"; Category = "Input"; Path = "HKCU:\Control Panel\Mouse"; Key = "MouseSpeed"; ValueOn = "0"; ValueOff = "1"; Description = "Raw mouse input (E-Sports standard)" }
        @{ Id = "MouseHover"; Name = "Faster Tooltips"; Risk = "Low"; Category = "Input"; Path = "HKCU:\Control Panel\Mouse"; Key = "MouseHoverTime"; ValueOn = "10"; ValueOff = "400"; Description = "Faster tooltip display" }
        @{ Id = "KbQueue"; Name = "Keyboard Queue Size"; Risk = "Low"; Category = "Input"; Path = "HKLM:\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters"; Key = "KeyboardDataQueueSize"; ValueOn = 50; ValueOff = 100; Description = "Reduce input buffer latency" }
        @{ Id = "MouQueue"; Name = "Mouse Queue Size"; Risk = "Low"; Category = "Input"; Path = "HKLM:\SYSTEM\CurrentControlSet\Services\mouclass\Parameters"; Key = "MouseDataQueueSize"; ValueOn = 50; ValueOff = 100; Description = "Reduce input buffer latency" }
        @{ Id = "StickyKeys"; Name = "Disable Sticky Keys"; Risk = "Low"; Category = "Input"; Path = "HKCU:\Control Panel\Accessibility\StickyKeys"; Key = "Flags"; ValueOn = "506"; ValueOff = "510"; Description = "Disable Sticky Keys shortcut" }

        # === 4. NETWORK STACK (RFC 9293 & BEAST MODE) ===
        @{ Id = "TcpAck"; Name = "TCP ACK Frequency"; Risk = "Low"; Category = "Network"; Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"; Key = "TcpAckFrequency"; ValueOn = 1; ValueOff = 2; Description = "Immediate TCP ack (1:1)" }
        @{ Id = "NagleOff"; Name = "Disable Nagle (TCPNoDelay)"; Risk = "Low"; Category = "Network"; Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"; Key = "TcpNoDelay"; ValueOn = 1; ValueOff = 0; Description = "Disable packet buffering" }
        @{ Id = "NetThrottle"; Name = "Disable Network Throttling"; Risk = "Low"; Category = "Network"; Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"; Key = "NetworkThrottlingIndex"; ValueOn = 0xffffffff; ValueOff = 10; Description = "Remove network throttling" }
        @{ Id = "NetRSS"; Name = "Enable RSS (Receive Side Scaling)"; Risk = "Low"; Category = "Network"; CommandOn = "Enable-NetAdapterRss -Name * -ErrorAction SilentlyContinue"; CommandOff = "Disable-NetAdapterRss -Name * -ErrorAction SilentlyContinue"; Description = "Multi-core packet processing" }
        @{ Id = "NetRSC"; Name = "Disable RSC (Gaming)"; Risk = "Medium"; Category = "Network"; CommandOn = "Disable-NetAdapterRsc -Name * -ErrorAction SilentlyContinue"; CommandOff = "Enable-NetAdapterRsc -Name * -ErrorAction SilentlyContinue"; Description = "Disable Coalescing (Reduces Latency)" }
        @{ Id = "CTCP"; Name = "CTCP Congestion Control"; Risk = "Medium"; Category = "Network"; CommandOn = "netsh int tcp set supplemental template=internet congestionprovider=ctcp"; CommandOff = "netsh int tcp set supplemental template=internet congestionprovider=default"; Description = "Traffic efficiency (Compound TCP)" }
        @{ Id = "NetAutoTune"; Name = "TCP Auto-Tuning Normal"; Risk = "Low"; Category = "Network"; CommandOn = "netsh int tcp set global autotuninglevel=normal"; CommandOff = "netsh int tcp set global autotuninglevel=disabled"; Description = "Optimal window sizing" }
        @{ Id = "TcpRamConfig"; Name = "TCP RAM Optimization"; Risk = "Medium"; Category = "Network"; CommandOn = "netsh int tcp set global ecncapability=enabled timestamps=disabled rss=enabled rsc=disabled"; CommandOff = "netsh int tcp set global ecncapability=default"; Description = "Max throughput config" }
        @{ Id = "QoSlimit"; Name = "Remove QoS Bandwidth Limit"; Risk = "Low"; Category = "Network"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched"; Key = "NonBestEffortLimit"; ValueOn = 0; ValueOff = 20; Description = "Unlock reserved bandwidth" }
        @{ Id = "TeredoOff"; Name = "Disable Teredo Tunneling"; Risk = "Low"; Category = "Network"; CommandOn = "netsh interface teredo set state disabled"; CommandOff = "netsh interface teredo set state default"; Description = "Reduce attack surface" }
        
        # === 5. SYSTEM & MEMORY (RAM MAXIMIZATION) ===
        @{ Id = "MemCompress"; Name = "Disable Memory Compression"; Risk = "Medium"; Category = "Memory"; CommandOn = "Disable-MMAgent -MemoryCompression"; CommandOff = "Enable-MMAgent -MemoryCompression"; Description = "Saves CPU cycles (Requires 16GB+)" }
        @{ Id = "LargePages"; Name = "Large System Pages"; Risk = "Medium"; Category = "Memory"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Key = "LargePageMinimum"; ValueOn = 1; ValueOff = 0; Description = "Disable if unstable" }
        @{ Id = "PageCombining"; Name = "Disable Page Combining"; Risk = "Low"; Category = "Memory"; CommandOn = "Disable-MMAgent -PageCombining"; CommandOff = "Enable-MMAgent -PageCombining"; Description = "Reduce CPU overhead" }
        @{ Id = "SvcSplit"; Name = "Svchost Split Threshold"; Risk = "Medium"; Category = "System"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control"; Key = "SvcHostSplitThresholdInKB"; ValueOn = 380000; ValueOff = 38000000; Description = "Group services (Save RAM)" }
        @{ Id = "PwrThrottling"; Name = "Disable Power Throttling"; Risk = "Medium"; Category = "Power"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling"; Key = "PowerThrottlingOff"; ValueOn = 1; ValueOff = 0; Description = "Prevent background app throttling" }
        @{ Id = "CoreParking"; Name = "Disable Core Parking"; Risk = "Medium"; Category = "Power"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583"; Key = "ValueMax"; ValueOn = 0; ValueOff = 100; Description = "Force all cores active" }
        
        # === 6. PRIVACY BEAST MODE (DEEP TELEMETRY BLOCK) ===
        @{ Id = "Telemetry"; Name = "Disable Telemetry (Zero)"; Risk = "Medium"; Category = "Privacy"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Key = "AllowTelemetry"; ValueOn = 0; ValueOff = 3; Description = "Zero telemetry allowed" }
        @{ Id = "DiagTrack"; Name = "Disable DiagTrack Service"; Risk = "Low"; Category = "Privacy"; CommandOn = "sc config DiagTrack start= disabled; sc stop DiagTrack"; CommandOff = "sc config DiagTrack start= auto"; Description = "Stop Connected User Experiences" }
        @{ Id = "DmClient"; Name = "Disable DmClient (Phone Home)"; Risk = "Medium"; Category = "Privacy"; Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels\Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin"; Key = "Enabled"; ValueOn = 0; ValueOff = 1; Description = "Disable Device Management logs" }
        @{ Id = "PrivCloud"; Name = "Disable Cloud Content"; Risk = "Low"; Category = "Privacy"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"; Key = "DisableWindowsConsumerFeatures"; ValueOn = 1; ValueOff = 0; Description = "No suggested apps/ads" }
        @{ Id = "PrivSearch"; Name = "Disable Bing Search"; Risk = "Low"; Category = "Privacy"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; Key = "DisableWebSearch"; ValueOn = 1; ValueOff = 0; Description = "Start Menu local only" }
        @{ Id = "PrivLoc"; Name = "Disable Location"; Risk = "Medium"; Category = "Privacy"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors"; Key = "DisableLocation"; ValueOn = 1; ValueOff = 0; Description = "Global location disable" }
        @{ Id = "PrivAdId"; Name = "Disable Advertising ID"; Risk = "Low"; Category = "Privacy"; Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"; Key = "Enabled"; ValueOn = 0; ValueOff = 1; Description = "Reset Ad ID" }
        @{ Id = "PrivInventory"; Name = "Disable App Inventory"; Risk = "Low"; Category = "Privacy"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat"; Key = "DisableInventory"; ValueOn = 1; ValueOff = 0; Description = "Stop reporting installed apps" }
        
        # === WINDOWS 11 24H2 SPECIFIC (NEW 2024-2025) ===
        @{ Id = "Win11HAGS"; Name = "Hardware Accel GPU Sched"; Risk = "Medium"; Category = "Gaming"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"; Key = "HwSchMode"; ValueOn = 2; ValueOff = 1; MinOS = "Windows 11"; Description = "Minimize latency (Win11/Win10 2004+)" }
        @{ Id = "Win11VBS"; Name = "Disable VBS (Volatile)"; Risk = "High"; Category = "Security"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard"; Key = "EnableVirtualizationBasedSecurity"; ValueOn = 0; ValueOff = 1; MinOS = "Windows 11"; Description = "Disable VBS for max gaming perf" }
        @{ Id = "Win11Recall"; Name = "Disable Recall (AI Snapshots)"; Risk = "Low"; Category = "Privacy"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"; Key = "DisableAIDataAnalysis"; ValueOn = 1; ValueOff = 0; MinOS = "Windows 11"; Description = "Disable Windows 11 Recall AI features" }
        @{ Id = "Win11Copilot"; Name = "Hide Copilot Taskbar"; Risk = "Low"; Category = "UI"; Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Key = "ShowCopilotButton"; ValueOn = 0; ValueOff = 1; MinOS = "Windows 11"; Description = "Hides Copilot button" }
        @{ Id = "Win11Widgets"; Name = "Disable Widgets"; Risk = "Low"; Category = "UI"; Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Key = "TaskbarDa"; ValueOn = 0; ValueOff = 1; MinOS = "Windows 11"; Description = "Hide Widgets from taskbar" }
        @{ Id = "Win11Phone"; Name = "Disable Phone Link Taskbar"; Risk = "Low"; Category = "UI"; Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Key = "TaskbarMn"; ValueOn = 0; ValueOff = 1; MinOS = "Windows 11"; Description = "Hide Phone Link button" }
        @{ Id = "Win11Chat"; Name = "Disable Chat (Teams)"; Risk = "Low"; Category = "UI"; Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Key = "TaskbarDc"; ValueOn = 0; ValueOff = 1; MinOS = "Windows 11"; Description = "Hide Teams Chat button" }
        @{ Id = "Win11DevHome"; Name = "Remove Dev Home"; Risk = "Low"; Category = "Debloat"; CommandOn = "Get-AppxPackage *DevHome* | Remove-AppxPackage -ErrorAction SilentlyContinue"; CommandOff = "winget install Microsoft.DevHome --accept-source-agreements --accept-package-agreements"; MinOS = "Windows 11"; Description = "Remove Dev Home (24H2)" }
        @{ Id = "Win11Outlook"; Name = "Remove New Outlook"; Risk = "Low"; Category = "Debloat"; CommandOn = "Get-AppxPackage *OutlookForWindows* | Remove-AppxPackage -ErrorAction SilentlyContinue"; CommandOff = "winget install Microsoft.OutlookForWindows"; MinOS = "Windows 11"; Description = "Remove web wrapper Outlook" }
        
        # === 8. FILESYSTEM (NTFS) ===
        @{ Id = "NtfsLastAccess"; Name = "Disable Last Access"; Risk = "Low"; Category = "Filesystem"; CommandOn = "fsutil behavior set disablelastaccess 1"; CommandOff = "fsutil behavior set disablelastaccess 0"; Description = "Reduces write operations" }
        @{ Id = "Ntfs83"; Name = "Disable 8.3 Naming"; Risk = "Low"; Category = "Filesystem"; CommandOn = "fsutil behavior set disable8dot3 1"; CommandOff = "fsutil behavior set disable8dot3 0"; Description = "Improves file enumeration" }
        
        # === 9. BROWSER HARDENING ===
        @{ Id = "ChromeTel"; Name = "Chrome Telemetry"; Risk = "Low"; Category = "Privacy"; Path = "HKLM:\SOFTWARE\Policies\Google\Chrome"; Key = "MetricsReportingEnabled"; ValueOn = 0; ValueOff = 1; Description = "Disable Chrome reporting" }
        @{ Id = "EdgeTel"; Name = "Edge Telemetry"; Risk = "Low"; Category = "Privacy"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Key = "MetricsReportingEnabled"; ValueOn = 0; ValueOff = 1; Description = "Disable Edge reporting" }
        @{ Id = "FirefoxTel"; Name = "Firefox Telemetry"; Risk = "Low"; Category = "Privacy"; Path = "HKLM:\SOFTWARE\Policies\Mozilla\Firefox"; Key = "DisableTelemetry"; ValueOn = 1; ValueOff = 0; Description = "Disable Firefox reporting" }
        
        # === 10. SECURITY & MITIGATIONS (OPTIONAL EXTREME) ===
        @{ Id = "Spectre"; Name = "Disable Spectre/Meltdown"; Risk = "High"; Category = "Security"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Key = "FeatureSettingsOverride"; ValueOn = 3; ValueOff = 0; Description = "Disables mitigations for max CPU perf (RISK!)" }
        @{ Id = "VBS"; Name = "Disable VBS"; Risk = "High"; Category = "Security"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard"; Key = "EnableVirtualizationBasedSecurity"; ValueOn = 0; ValueOff = 1; Description = "Disable Virtualization Based Security (Gaming Perf)" }
        @{ Id = "Dep"; Name = "Enable DEP Always"; Risk = "Medium"; Category = "Security"; CommandOn = "bcdedit /set nx AlwaysOn"; CommandOff = "bcdedit /set nx OptIn"; Description = "Data Execution Prevention" }
        
        # === 11. GOD MODE (10K SOURCE RESEARCH - DEEP KERNEL) ===
        @{ Id = "MsiModeSupported"; Name = "Force MSI Mode Support"; Risk = "Medium"; Category = "Latency"; Path = "HKLM:\SYSTEM\CurrentControlSet\Enum\PCI"; Key = "MSISupported"; ValueOn = 1; ValueOff = 0; ConditionScript = "Test-Path 'HKLM:\SYSTEM\CurrentControlSet\Enum\PCI'"; Description = "Enable Message Signaled Interrupts capability" } 
        @{ Id = "MmcssSysResp"; Name = "System Responsiveness"; Risk = "Medium"; Category = "Latency"; Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"; Key = "SystemResponsiveness"; ValueOn = 0; ValueOff = 20; Description = "Reserve 0% CPU for low priority tasks" }
        @{ Id = "MmcssPrio"; Name = "Filesystem Priority"; Risk = "Medium"; Category = "Latency"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"; Key = "NtfsMftZoneReservation"; ValueOn = 4; ValueOff = 1; Description = "Expand MFT Zone for heavy file ops" }
        @{ Id = "CsrssPrio"; Name = "CSRSS Realtime"; Risk = "High"; Category = "Latency"; Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\csrss.exe\PerfOptions"; Key = "CpuPriorityClass"; ValueOn = 4; ValueOff = 2; Description = "Process Critical Subsystem Priority" }
        @{ Id = "Dx9Legacy"; Name = "DirectX 9 Legacy Support"; Risk = "Low"; Category = "Gaming"; CommandOn = "dism /online /enable-feature /featurename:DirectPlay /all /limitaccess"; CommandOff = "dism /online /disable-feature /featurename:DirectPlay"; MinOS = "Windows 11"; Description = "Ensure old games work on Win11" }

        # === 12. BRAND SPECIFIC (LENOVO/HP/DELL INJECTORS) ===
        @{ Id = "LenovoHybrid"; Name = "Lenovo Hybrid Mode (dGPU)"; Risk = "Medium"; Category = "Lenovo"; ConditionScript = "Test-LenovoSystem"; WmiSetting = "HybridMode"; WmiValueOn = "Disable"; WmiValueOff = "Enable"; Description = "Force dedicated GPU for gaming" }
        @{ Id = "LenovoPerf"; Name = "Lenovo Max Performance"; Risk = "Low"; Category = "Lenovo"; ConditionScript = "Test-LenovoSystem"; WmiSetting = "AdaptiveThermalManagementAC"; WmiValueOn = "MaximizePerformance"; WmiValueOff = "Balanced"; Description = "High thermal limit" }
        
        # === 13. SERVICES DEBLOAT (SAFE LIST) ===
        @{ Id = "SvcMaps"; Name = "Disable Maps Broker"; Risk = "Low"; Category = "Services"; CommandOn = "Set-Service -Name MapsBroker -StartupType Disabled"; CommandOff = "Set-Service -Name MapsBroker -StartupType Automatic"; Description = "Unused map downloader" }
        @{ Id = "SvcLpd"; Name = "Disable LPD Service"; Risk = "Low"; Category = "Services"; CommandOn = "Set-Service -Name LPDService -StartupType Disabled"; CommandOff = "Set-Service -Name LPDService -StartupType Manual"; Description = "Legacy print daemon" }
        @{ Id = "SvcWer"; Name = "Disable WER"; Risk = "Low"; Category = "Services"; CommandOn = "Set-Service -Name WerSvc -StartupType Disabled"; CommandOff = "Set-Service -Name WerSvc -StartupType Manual"; Description = "Windows Error Reporting" }
        @{ Id = "SvcPca"; Name = "Disable PCA"; Risk = "Low"; Category = "Services"; CommandOn = "Set-Service -Name PcaSvc -StartupType Disabled"; CommandOff = "Set-Service -Name PcaSvc -StartupType Manual"; Description = "Program Compatibility Assistant" }
        @{ Id = "SvcSysMain"; Name = "Disable SysMain"; Risk = "Low"; Category = "Services"; CommandOn = "Set-Service -Name SysMain -StartupType Disabled"; CommandOff = "Set-Service -Name SysMain -StartupType Automatic"; Description = "Superfetch (Disable on SSD)" }
    )
}

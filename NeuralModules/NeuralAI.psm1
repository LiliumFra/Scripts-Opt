<#
.SYNOPSIS
    Neural-AI Module v2.0
    Implements Local Reinforcement Learning (Q-Learning) for system optimization.

.DESCRIPTION
    Advanced AI module with:
    - Q-Learning with persistent Q-Table
    - Expanded system metrics (GPU, Disk, Network, Temperature)
    - Epsilon-greedy exploration with decay
    - 12+ exploratory tweaks with risk assessment
    - Adaptive reward function
    - Performance regression detection

.NOTES
    Part of Windows Neural Optimizer
    Author: Jose Bustamante
#>

$Script:ModulePath = Split-Path $MyInvocation.MyCommand.Path -Parent
$Script:BrainPath = Join-Path $Script:ModulePath "..\NeuralBrain.json"
$Script:QTablePath = Join-Path $Script:ModulePath "..\NeuralQTable.json"
$Script:ConfigPath = Join-Path $Script:ModulePath "..\NeuralConfig.json"

# Q-Learning Configuration
$Script:QLearningConfig = @{
    Alpha          = 0.1
    Gamma          = 0.9
    EpsilonInitial = 0.30
    EpsilonMin     = 0.05
    EpsilonDecay   = 0.995
    CurrentEpsilon = 0.30
}

# Tweaks Library - Expanded from GitHub Research (Win11Debloat, Perfect-Windows-11, facet4windows)
$Script:TweakLibrary = @(
    # === LOW RISK TWEAKS ===
    # Latency
    @{ Id = "TimerRes"; Name = "Global Timer Resolution"; Risk = "Low"; Category = "Latency"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel"; Key = "GlobalTimerResolutionRequests"; ValueOn = 1; ValueOff = 0; Description = "Forces high-resolution timer" },
    @{ Id = "DynamicTick"; Name = "Disable Dynamic Tick"; Risk = "Low"; Category = "Latency"; CommandOn = "bcdedit /set disabledynamictick yes"; CommandOff = "bcdedit /set disabledynamictick no"; Description = "Disables power-saving tick" },
    @{ Id = "HPET"; Name = "Disable HPET"; Risk = "Low"; Category = "Latency"; CommandOn = "bcdedit /set useplatformclock no"; CommandOff = "bcdedit /set useplatformclock yes"; Description = "Uses TSC instead of HPET" },
    @{ Id = "TSCSync"; Name = "TSC Sync Policy"; Risk = "Low"; Category = "Latency"; CommandOn = "bcdedit /set tscsyncpolicy enhanced"; CommandOff = "bcdedit /deletevalue tscsyncpolicy"; Description = "Enhanced TSC synchronization" },
    
    # Gaming
    @{ Id = "GameMode"; Name = "Enable Game Mode"; Risk = "Low"; Category = "Gaming"; Path = "HKCU:\Software\Microsoft\GameBar"; Key = "AllowAutoGameMode"; ValueOn = 1; ValueOff = 0; Description = "Windows Game Mode" },
    @{ Id = "FSO"; Name = "Fullscreen Optimizations"; Risk = "Low"; Category = "Gaming"; Path = "HKCU:\System\GameConfigStore"; Key = "GameDVR_FSEBehaviorMode"; ValueOn = 2; ValueOff = 0; Description = "Disable FSO for classic fullscreen" },
    @{ Id = "GameBar"; Name = "Disable Game Bar"; Risk = "Low"; Category = "Gaming"; Path = "HKCU:\Software\Microsoft\GameBar"; Key = "UseNexusForGameBarEnabled"; ValueOn = 0; ValueOff = 1; Description = "Disable Xbox Game Bar overlay" },
    @{ Id = "GameDVR"; Name = "Disable Game DVR"; Risk = "Low"; Category = "Gaming"; Path = "HKCU:\System\GameConfigStore"; Key = "GameDVR_Enabled"; ValueOn = 0; ValueOff = 1; Description = "Disable background recording" },
    
    # Input
    @{ Id = "MouseAccel"; Name = "Disable Mouse Acceleration"; Risk = "Low"; Category = "Input"; Path = "HKCU:\Control Panel\Mouse"; Key = "MouseSpeed"; ValueOn = "0"; ValueOff = "1"; Description = "Raw mouse input" },
    @{ Id = "MouseHover"; Name = "Faster Tooltips"; Risk = "Low"; Category = "Input"; Path = "HKCU:\Control Panel\Mouse"; Key = "MouseHoverTime"; ValueOn = "10"; ValueOff = "400"; Description = "Faster tooltip display" },
    
    # Network
    @{ Id = "TcpAck"; Name = "TCP ACK Frequency"; Risk = "Low"; Category = "Network"; Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Key = "TcpAckFrequency"; ValueOn = 1; ValueOff = 2; Description = "Immediate TCP ack" },
    @{ Id = "NagleOff"; Name = "Disable Nagle"; Risk = "Low"; Category = "Network"; Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Key = "TcpNoDelay"; ValueOn = 1; ValueOff = 0; Description = "Disable packet buffering" },
    @{ Id = "NetThrottle"; Name = "Disable Network Throttling"; Risk = "Low"; Category = "Network"; Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"; Key = "NetworkThrottlingIndex"; ValueOn = 0xffffffff; ValueOff = 10; Description = "Remove network throttling" },
    
    # UI Performance (from Perfect-Windows-11)
    @{ Id = "MenuDelay"; Name = "Menu Show Delay"; Risk = "Low"; Category = "UI"; Path = "HKCU:\Control Panel\Desktop"; Key = "MenuShowDelay"; ValueOn = "0"; ValueOff = "400"; Description = "Instant menu display" },
    @{ Id = "StartupDelay"; Name = "Startup Delay"; Risk = "Low"; Category = "UI"; Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize"; Key = "StartupDelayInMSec"; ValueOn = 0; ValueOff = 500; Description = "Remove startup app delay" },
    @{ Id = "ForegroundLock"; Name = "Foreground Lock Timeout"; Risk = "Low"; Category = "UI"; Path = "HKCU:\Control Panel\Desktop"; Key = "ForegroundLockTimeout"; ValueOn = 0; ValueOff = 200000; Description = "Faster window switching" },
    
    # === MEDIUM RISK TWEAKS ===
    # Memory
    @{ Id = "MemCompress"; Name = "Disable Memory Compression"; Risk = "Medium"; Category = "Memory"; CommandOn = "Disable-MMAgent -MemoryCompression"; CommandOff = "Enable-MMAgent -MemoryCompression"; Description = "Saves CPU on 16GB+ RAM" },
    @{ Id = "LargePages"; Name = "Large System Pages"; Risk = "Medium"; Category = "Memory"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Key = "LargePageMinimum"; ValueOn = 1; ValueOff = 0; Description = "Enable large memory pages" },
    
    # Storage
    @{ Id = "Prefetch"; Name = "Optimize Prefetch"; Risk = "Medium"; Category = "Storage"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"; Key = "EnablePrefetcher"; ValueOn = 0; ValueOff = 3; Description = "Disable prefetch on SSD" },
    @{ Id = "Superfetch"; Name = "Disable Superfetch"; Risk = "Medium"; Category = "Storage"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"; Key = "EnableSuperfetch"; ValueOn = 0; ValueOff = 3; Description = "Disable superfetch on SSD" },
    
    # CPU/Scheduler
    @{ Id = "SysResp"; Name = "System Responsiveness"; Risk = "Medium"; Category = "Scheduler"; Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"; Key = "SystemResponsiveness"; ValueOn = 0; ValueOff = 20; Description = "Prioritize foreground apps" },
    @{ Id = "CoreParking"; Name = "Disable Core Parking"; Risk = "Medium"; Category = "Scheduler"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583"; Key = "ValueMax"; ValueOn = 0; ValueOff = 100; Description = "Keep all cores active" },
    @{ Id = "PowerThrottle"; Name = "Disable Power Throttling"; Risk = "Medium"; Category = "Scheduler"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling"; Key = "PowerThrottlingOff"; ValueOn = 1; ValueOff = 0; Description = "Prevent CPU throttling" },
    
    # Shutdown/Startup
    @{ Id = "WaitToKill"; Name = "Faster Shutdown"; Risk = "Medium"; Category = "System"; Path = "HKCU:\Control Panel\Desktop"; Key = "WaitToKillAppTimeout"; ValueOn = "2000"; ValueOff = "20000"; Description = "Reduce shutdown wait" },
    @{ Id = "AutoEndTasks"; Name = "Auto End Tasks"; Risk = "Medium"; Category = "System"; Path = "HKCU:\Control Panel\Desktop"; Key = "AutoEndTasks"; ValueOn = "1"; ValueOff = "0"; Description = "Auto-kill hung apps" },
    @{ Id = "HungAppTimeout"; Name = "Hung App Timeout"; Risk = "Medium"; Category = "System"; Path = "HKCU:\Control Panel\Desktop"; Key = "HungAppTimeout"; ValueOn = "1000"; ValueOff = "5000"; Description = "Faster hung app detection" },
    
    # Privacy/Telemetry (from Win11Debloat)
    @{ Id = "Telemetry"; Name = "Disable Telemetry"; Risk = "Medium"; Category = "Privacy"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Key = "AllowTelemetry"; ValueOn = 0; ValueOff = 3; Description = "Disable data collection" },
    
    # === FILESYSTEM OPTIMIZATIONS ===
    @{ Id = "Ntfs83"; Name = "Disable 8.3 Naming"; Risk = "Low"; Category = "Filesystem"; CommandOn = "fsutil behavior set disable8dot3 1"; CommandOff = "fsutil behavior set disable8dot3 0"; Description = "Improves NTFS performance" },
    @{ Id = "NtfsLastAccess"; Name = "Disable Last Access Update"; Risk = "Low"; Category = "Filesystem"; CommandOn = "fsutil behavior set disablelastaccess 1"; CommandOff = "fsutil behavior set disablelastaccess 0"; Description = "Reduces disk write ops" },
    @{ Id = "NtfsEncrypt"; Name = "Disable EFS"; Risk = "Low"; Category = "Filesystem"; CommandOn = "fsutil behavior set disableencryption 1"; CommandOff = "fsutil behavior set disableencryption 0"; Description = "Disables EFS overhead" },
    
    # === ADVANCED NETWORK ===
    @{ Id = "CTCP"; Name = "CTCP Congestion Provider"; Risk = "Medium"; Category = "Network"; CommandOn = "netsh int tcp set supplemental template=internet congestionprovider=ctcp"; CommandOff = "netsh int tcp set supplemental template=internet congestionprovider=default"; Description = "Better throughput on high latency" },
    @{ Id = "RscIPv4"; Name = "Enable RSC (IPv4)"; Risk = "Medium"; Category = "Network"; CommandOn = "netsh int tcp set global rsc=enabled"; CommandOff = "netsh int tcp set global rsc=disabled"; Description = "Receive Segment Coalescing" },
    @{ Id = "RssIPv4"; Name = "Enable RSS"; Risk = "Medium"; Category = "Network"; CommandOn = "netsh int tcp set global rss=enabled"; CommandOff = "netsh int tcp set global rss=disabled"; Description = "Receive Side Scaling" },
    @{ Id = "NetOffload"; Name = "Disable Task Offload"; Risk = "Medium"; Category = "Network"; Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Key = "DisableTaskOffload"; ValueOn = 0; ValueOff = 1; Description = "Let NIC handle offloading" },
    
    # === PROCESSOR & THREADS ===
    @{ Id = "Win32Prio"; Name = "Win32 Priority Separation"; Risk = "Medium"; Category = "System"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"; Key = "Win32PrioritySeparation"; ValueOn = 38; ValueOff = 2; Description = "Optimizes for foreground apps (Hex 26)" },
    @{ Id = "SvcSplit"; Name = "Split Threshold"; Risk = "Medium"; Category = "System"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control"; Key = "SvcHostSplitThresholdInKB"; ValueOn = 380000; ValueOff = 38000000; Description = "Better RAM handling for svchost" },
    @{ Id = "LongPaths"; Name = "Enable Long Paths"; Risk = "Low"; Category = "System"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"; Key = "LongPathsEnabled"; ValueOn = 1; ValueOff = 0; Description = "Removes 260 char limit" },
    
    # === MEMORY & CACHE ===
    @{ Id = "IoPageLock"; Name = "IO Page Lock Limit"; Risk = "High"; Category = "Memory"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Key = "IoPageLockLimit"; ValueOn = 65536; ValueOff = 0; Description = "Boosts I/O throughput" },
    @{ Id = "NonPagedPool"; Name = "NonPaged Pool Size"; Risk = "High"; Category = "Memory"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Key = "NonPagedPoolSize"; ValueOn = 0; ValueOff = 0; Description = "System managed pool size" },
    @{ Id = "SecondLevel"; Name = "L2 Cache Size"; Risk = "Medium"; Category = "Memory"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Key = "SecondLevelDataCache"; ValueOn = 0; ValueOff = 0; Description = "Auto-detect L2 cache" },
    
    # === GAMING EXTRAS ===
    @{ Id = "GpuPrio"; Name = "GPU Priority"; Risk = "Medium"; Category = "Gaming"; Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"; Key = "GPU Priority"; ValueOn = 8; ValueOff = 8; Description = "High GPU priority" },
    @{ Id = "GamesPrio"; Name = "Games Scheduling"; Risk = "Medium"; Category = "Gaming"; Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"; Key = "Priority"; ValueOn = 6; ValueOff = 2; Description = "High CPU priority for games" },
    @{ Id = "GamesSched"; Name = "Games Category"; Risk = "Medium"; Category = "Gaming"; Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"; Key = "Scheduling Category"; ValueOn = "High"; ValueOff = "Medium"; Description = "High scheduling category" },
    
    # === PRIVACY EXTENSIONS ===
    @{ Id = "ExpBandwidth"; Name = "Experience Bandwidth"; Risk = "Low"; Category = "Privacy"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Key = "RestrictTelemetry"; ValueOn = 0; ValueOff = 0; Description = "Restrict extra telemetry" },
    @{ Id = "AppTrack"; Name = "Disable App Tracking"; Risk = "Low"; Category = "Privacy"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\EdgeUI"; Key = "DisableMFUTracking"; ValueOn = 1; ValueOff = 0; Description = "Disable most frequently used apps" },
    @{ Id = "Teredo"; Name = "Disable Teredo"; Risk = "Low"; Category = "Network"; CommandOn = "netsh interface teredo set state disabled"; CommandOff = "netsh interface teredo set state default"; Description = "Disable Teredo tunneling" },
    @{ Id = "ISATAP"; Name = "Disable ISATAP"; Risk = "Low"; Category = "Network"; CommandOn = "netsh interface isatap set state disabled"; CommandOff = "netsh interface isatap set state default"; Description = "Disable ISATAP tunneling" },
    
    # === NEW: ADVANCED PRIVACY (from ChrisTitusTech/winutil) ===
    @{ Id = "ActivityFeed"; Name = "Disable Activity History"; Risk = "Low"; Category = "Privacy"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Key = "EnableActivityFeed"; ValueOn = 0; ValueOff = 1; Description = "Erases recent docs, clipboard, run history" },
    @{ Id = "PublishActivity"; Name = "Disable Publish Activity"; Risk = "Low"; Category = "Privacy"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Key = "PublishUserActivities"; ValueOn = 0; ValueOff = 1; Description = "Stop publishing user activities" },
    @{ Id = "UploadActivity"; Name = "Disable Upload Activity"; Risk = "Low"; Category = "Privacy"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Key = "UploadUserActivities"; ValueOn = 0; ValueOff = 1; Description = "Stop uploading user activities" },
    @{ Id = "LocationTrack"; Name = "Disable Location Tracking"; Risk = "Low"; Category = "Privacy"; Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"; Key = "Value"; ValueOn = "Deny"; ValueOff = "Allow"; Description = "Prevents GPS/location tracking" },
    @{ Id = "SensorPerm"; Name = "Disable Sensor Permission"; Risk = "Low"; Category = "Privacy"; Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}"; Key = "SensorPermissionState"; ValueOn = 0; ValueOff = 1; Description = "Block location sensor" },
    @{ Id = "WifiSense"; Name = "Disable WiFi Sense"; Risk = "Low"; Category = "Privacy"; Path = "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config"; Key = "AutoConnectAllowedOEM"; ValueOn = 0; ValueOff = 1; Description = "Prevents auto-sharing WiFi credentials" },
    @{ Id = "AdvertisingId"; Name = "Disable Advertising ID"; Risk = "Low"; Category = "Privacy"; Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"; Key = "Enabled"; ValueOn = 0; ValueOff = 1; Description = "Stop personalized ads" },
    @{ Id = "ContentDelivery"; Name = "Disable Content Delivery"; Risk = "Low"; Category = "Privacy"; Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Key = "SilentInstalledAppsEnabled"; ValueOn = 0; ValueOff = 1; Description = "Stop auto-installing suggested apps" },
    @{ Id = "StartSuggestions"; Name = "Disable Start Suggestions"; Risk = "Low"; Category = "Privacy"; Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Key = "SystemPaneSuggestionsEnabled"; ValueOn = 0; ValueOff = 1; Description = "Remove Start menu suggestions" },
    
    # === NEW: MMCSS ADVANCED (from latency research) ===
    @{ Id = "SFIO_Priority"; Name = "SFIO High Priority"; Risk = "Low"; Category = "Gaming"; Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"; Key = "SFIO Priority"; ValueOn = "High"; ValueOff = "Normal"; Description = "High scheduled file I/O priority" },
    @{ Id = "GamesAffinity"; Name = "Full CPU Affinity"; Risk = "Low"; Category = "Gaming"; Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"; Key = "Affinity"; ValueOn = 0; ValueOff = 0; Description = "Use all CPU cores for games" },
    @{ Id = "BackgroundOnly"; Name = "Foreground Priority"; Risk = "Low"; Category = "Gaming"; Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"; Key = "Background Only"; ValueOn = "False"; ValueOff = "True"; Description = "Prioritize foreground games" },
    @{ Id = "ClockRate"; Name = "Force High Clock Rate"; Risk = "Medium"; Category = "Latency"; Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"; Key = "AlwaysOn"; ValueOn = 1; ValueOff = 0; Description = "Force high resolution timer always" },
    @{ Id = "LatencySens"; Name = "Latency Sensitive"; Risk = "Low"; Category = "Latency"; Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"; Key = "Latency Sensitive"; ValueOn = "True"; ValueOff = "False"; Description = "Mark games as latency sensitive" },
    
    # === NEW: GPU/DIRECT3D (from optimizer research) ===
    @{ Id = "PreRender"; Name = "Max Pre-Rendered Frames"; Risk = "Low"; Category = "Gaming"; Path = "HKLM:\SOFTWARE\Microsoft\Direct3D"; Key = "MaxPreRenderedFrames"; ValueOn = 1; ValueOff = 3; Description = "Reduces GPU render queue latency" },
    @{ Id = "HAGS"; Name = "HW GPU Scheduling"; Risk = "Medium"; Category = "Gaming"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"; Key = "HwSchMode"; ValueOn = 2; ValueOff = 1; Description = "Hardware-accelerated GPU scheduling" },
    @{ Id = "FlipModel"; Name = "Flip Model Optimization"; Risk = "Low"; Category = "Gaming"; Path = "HKCU:\System\GameConfigStore"; Key = "GameDVR_DXGIHonorFlipModeWindowedForHwnd"; ValueOn = 1; ValueOff = 0; Description = "Modern presentation model" },
    @{ Id = "VRROptimize"; Name = "VRR Optimization"; Risk = "Low"; Category = "Gaming"; Path = "HKCU:\System\GameConfigStore"; Key = "GameDVR_DSE_Enable"; ValueOn = 1; ValueOff = 0; Description = "Variable Refresh Rate optimization" },
    
    # === NEW: NETWORK INTERFACE (advanced) ===
    @{ Id = "TcpDelAck"; Name = "TCP Delayed ACK Ticks"; Risk = "Low"; Category = "Network"; Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Key = "TcpDelAckTicks"; ValueOn = 0; ValueOff = 2; Description = "Zero delay ACK timer" },
    @{ Id = "ECN"; Name = "Disable ECN Capability"; Risk = "Low"; Category = "Network"; CommandOn = "netsh int tcp set global ecncapability=disabled"; CommandOff = "netsh int tcp set global ecncapability=default"; Description = "Better legacy network compatibility" },
    @{ Id = "AutoTuning"; Name = "Normal Auto-Tuning"; Risk = "Low"; Category = "Network"; CommandOn = "netsh int tcp set global autotuninglevel=normal"; CommandOff = "netsh int tcp set global autotuninglevel=disabled"; Description = "Enable TCP window auto-tuning" },
    @{ Id = "Timestamps"; Name = "Disable TCP Timestamps"; Risk = "Low"; Category = "Network"; CommandOn = "netsh int tcp set global timestamps=disabled"; CommandOff = "netsh int tcp set global timestamps=enabled"; Description = "Reduce packet overhead" },
    
    # === NEW: POWER/SLEEP (Laptop-Aware) ===
    @{ Id = "ModernStandby"; Name = "Disable Modern Standby"; Risk = "Medium"; Category = "Power"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Power"; Key = "PlatformAoAcOverride"; ValueOn = 0; ValueOff = 1; Description = "Prevents S0 low power drain (laptops)" },
    @{ Id = "USBSuspend"; Name = "Disable USB Selective Suspend"; Risk = "Low"; Category = "Power"; Path = "HKLM:\SYSTEM\CurrentControlSet\Services\USB"; Key = "DisableSelectiveSuspend"; ValueOn = 1; ValueOff = 0; Description = "Prevents USB disconnection issues" },
    @{ Id = "FastStartup"; Name = "Disable Fast Startup"; Risk = "Medium"; Category = "Power"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"; Key = "HiberbootEnabled"; ValueOn = 0; ValueOff = 1; Description = "Clean boot every time" },
    @{ Id = "Hibernate"; Name = "Disable Hibernation"; Risk = "Low"; Category = "Power"; CommandOn = "powercfg /hibernate off"; CommandOff = "powercfg /hibernate on"; Description = "Disables hiberfil.sys (saves disk space)" },
    @{ Id = "AHCI_LPM"; Name = "Disable AHCI Link Power"; Risk = "Medium"; Category = "Storage"; CommandOn = "powercfg -setacvalueindex SCHEME_CURRENT 0012ee47-9041-4b5d-9b77-535fba8b1442 dab60367-53fe-4fbc-825e-521d069d2456 0 & powercfg -setactive SCHEME_CURRENT"; CommandOff = "powercfg -setacvalueindex SCHEME_CURRENT 0012ee47-9041-4b5d-9b77-535fba8b1442 dab60367-53fe-4fbc-825e-521d069d2456 1 & powercfg -setactive SCHEME_CURRENT"; Description = "SSD/HDD always active (no power saving)" },
    
    # === NEW: BCDEDIT KERNEL TWEAKS (from 100+ source research) ===
    @{ Id = "HypervisorOff"; Name = "Disable Hypervisor"; Risk = "Medium"; Category = "Kernel"; CommandOn = "bcdedit /set hypervisorlaunchtype off"; CommandOff = "bcdedit /set hypervisorlaunchtype auto"; Description = "Disables Hyper-V for gaming (if not using VMs)" },
    @{ Id = "TSCEnhanced"; Name = "Enhanced TSC Sync"; Risk = "Low"; Category = "Kernel"; CommandOn = "bcdedit /set tscsyncpolicy enhanced"; CommandOff = "bcdedit /deletevalue tscsyncpolicy"; Description = "Better multi-core timestamp coordination" },
    @{ Id = "LinuxBoot"; Name = "Disable Linear Boot"; Risk = "Low"; Category = "Kernel"; CommandOn = "bcdedit /set linearaddress57 optout"; CommandOff = "bcdedit /deletevalue linearaddress57"; Description = "Opt out of 57-bit linear addressing" },
    @{ Id = "IncreaseUCR"; Name = "Increase User CR"; Risk = "Medium"; Category = "Kernel"; CommandOn = "bcdedit /set increaseuserva 3072"; CommandOff = "bcdedit /deletevalue increaseuserva"; Description = "More user-mode virtual address space" },
    
    # === NEW: VBS/HVCI SECURITY (gaming performance tradeoff) ===
    @{ Id = "VBSOff"; Name = "Disable VBS"; Risk = "High"; Category = "Security"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard"; Key = "EnableVirtualizationBasedSecurity"; ValueOn = 0; ValueOff = 1; Description = "Disable Virtualization-Based Security (5-15% FPS boost)" },
    @{ Id = "HVCIOff"; Name = "Disable HVCI/Memory Integrity"; Risk = "High"; Category = "Security"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"; Key = "Enabled"; ValueOn = 0; ValueOff = 1; Description = "Disable Memory Integrity for gaming" },
    @{ Id = "CredGuardOff"; Name = "Disable Credential Guard"; Risk = "High"; Category = "Security"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard"; Key = "LsaCfgFlags"; ValueOn = 0; ValueOff = 1; Description = "Disable Credential Guard virtualization" },
    
    # === NEW: DPC/INTERRUPT LATENCY ===
    @{ Id = "IntAffinity"; Name = "Interrupt Affinity Policy"; Risk = "Medium"; Category = "Latency"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel"; Key = "InterruptAffinityPolicy"; ValueOn = 2; ValueOff = 0; Description = "Spread interrupts across CPU cores" },
    @{ Id = "DisPageExec"; Name = "Disable Paging Executive"; Risk = "Medium"; Category = "Memory"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Key = "DisablePagingExecutive"; ValueOn = 1; ValueOff = 0; Description = "Keep kernel code in RAM (reduces DPC latency)" },
    @{ Id = "TimerCoal"; Name = "Disable Timer Coalescing"; Risk = "Low"; Category = "Latency"; Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"; Key = "TimerResolution"; ValueOn = 0; ValueOff = 1; Description = "Prevents grouped background tasks" },
    
    # === NEW: AUDIO/MMCSS ADVANCED ===
    @{ Id = "AudioPrio"; Name = "Audio Task Priority"; Risk = "Low"; Category = "Audio"; Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio"; Key = "Priority"; ValueOn = 8; ValueOff = 6; Description = "High audio thread priority" },
    @{ Id = "AudioSched"; Name = "Audio Scheduling"; Risk = "Low"; Category = "Audio"; Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio"; Key = "Scheduling Category"; ValueOn = "High"; ValueOff = "Medium"; Description = "High audio scheduling category" },
    @{ Id = "AudioClock"; Name = "Audio Clock Rate"; Risk = "Low"; Category = "Audio"; Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio"; Key = "Clock Rate"; ValueOn = 5000; ValueOff = 10000; Description = "Lower audio clock rate for less latency" },
    @{ Id = "AudioDG"; Name = "Audio Device Graph Priority"; Risk = "Low"; Category = "Audio"; Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Audio"; Key = "MMCSSPriority"; ValueOn = 6; ValueOff = 2; Description = "Higher audiodg.exe priority" },
    
    # === NEW: CRASH DUMPS/DEBUG ===
    @{ Id = "CrashDump"; Name = "Disable Crash Dumps"; Risk = "Medium"; Category = "System"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl"; Key = "CrashDumpEnabled"; ValueOn = 0; ValueOff = 7; Description = "Saves disk space, minor performance boost" },
    @{ Id = "AutoReboot"; Name = "Disable Auto Reboot on BSOD"; Risk = "Low"; Category = "System"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl"; Key = "AutoReboot"; ValueOn = 0; ValueOff = 1; Description = "Don't auto-reboot on crash" },
    @{ Id = "WERDisable"; Name = "Disable Windows Error Reporting"; Risk = "Low"; Category = "Privacy"; Path = "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting"; Key = "Disabled"; ValueOn = 1; ValueOff = 0; Description = "Stop error report uploads" },
    
    # === NEW: DEFENDER/SECURITY PERFORMANCE ===
    @{ Id = "DefenderRT"; Name = "Reduce Defender CPU Usage"; Risk = "Medium"; Category = "Security"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Scan"; Key = "AvgCPULoadFactor"; ValueOn = 10; ValueOff = 50; Description = "Limit Defender CPU usage to 10%" },
    @{ Id = "DefenderCloud"; Name = "Disable Defender Cloud"; Risk = "Medium"; Category = "Security"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet"; Key = "SpynetReporting"; ValueOn = 0; ValueOff = 2; Description = "Disable cloud lookup" },
    
    # === NEW: SCHEDULER VARIANTS (Win32PrioritySeparation) ===
    @{ Id = "SchedFixed"; Name = "Fixed Short Quantum"; Risk = "Medium"; Category = "Scheduler"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"; Key = "Win32PrioritySeparation"; ValueOn = 0x28; ValueOff = 0x26; Description = "Short fixed quantum, no foreground boost" },
    
    # === NEW: HID/INPUT LATENCY ===
    @{ Id = "HIDIdle"; Name = "Disable HID Idle"; Risk = "Low"; Category = "Input"; Path = "HKLM:\SYSTEM\CurrentControlSet\Services\HidUsb"; Key = "IdleEnabled"; ValueOn = 0; ValueOff = 1; Description = "Prevents HID device idle/wake delays" },
    @{ Id = "MouseQueue"; Name = "Mouse Data Queue Size"; Risk = "Low"; Category = "Input"; Path = "HKLM:\SYSTEM\CurrentControlSet\Services\mouclass\Parameters"; Key = "MouseDataQueueSize"; ValueOn = 32; ValueOff = 100; Description = "Smaller mouse buffer for lower latency" },
    @{ Id = "KeyboardQueue"; Name = "Keyboard Data Queue Size"; Risk = "Low"; Category = "Input"; Path = "HKLM:\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters"; Key = "KeyboardDataQueueSize"; ValueOn = 32; ValueOff = 100; Description = "Smaller keyboard buffer" },
    
    # === NEW: NVME/STORAGE ADVANCED ===
    @{ Id = "NVMeNative"; Name = "NVMe Native Mode"; Risk = "High"; Category = "Storage"; Path = "HKLM:\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device"; Key = "ForcedPhysicalSectorSizeInBytes"; ValueOn = 0; ValueOff = 0; Description = "Enable native NVMe (experimental)" },
    @{ Id = "StorTelemetry"; Name = "Disable Storage Telemetry"; Risk = "Low"; Category = "Storage"; Path = "HKLM:\SYSTEM\CurrentControlSet\Services\disk"; Key = "EnableTelemetry"; ValueOn = 0; ValueOff = 1; Description = "Disable disk telemetry" },
    
    # === NEW: NVIDIA GPU (if detected) ===
    @{ Id = "NvFrameQueue"; Name = "NVIDIA Disable Frame Queue"; Risk = "Medium"; Category = "GPU"; Path = "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm\FTS"; Key = "EnableFrameQueue"; ValueOn = 0; ValueOff = 1; Description = "Disable NVIDIA driver frame queue (lowest latency)" },
    @{ Id = "D3DPreRender"; Name = "Direct3D Pre-Rendered Frames"; Risk = "Low"; Category = "GPU"; Path = "HKLM:\SOFTWARE\Microsoft\Direct3D"; Key = "MaxPreRenderedFrames"; ValueOn = 1; ValueOff = 3; Description = "Limit GPU pre-render queue" },
    @{ Id = "D3DFlipQueue"; Name = "Direct3D Flip Queue Size"; Risk = "Low"; Category = "GPU"; Path = "HKLM:\SOFTWARE\Microsoft\Direct3D"; Key = "FlipQueueSize"; ValueOn = 1; ValueOff = 0; Description = "Minimal flip queue for latency" },
    
    # === NEW: WINDOWS SERVICES (via command) ===
    @{ Id = "DiagTrack"; Name = "Disable DiagTrack Service"; Risk = "Low"; Category = "Privacy"; CommandOn = "sc config DiagTrack start= disabled & sc stop DiagTrack"; CommandOff = "sc config DiagTrack start= auto & sc start DiagTrack"; Description = "Disable telemetry service" },
    @{ Id = "WSearch"; Name = "Disable Windows Search"; Risk = "Medium"; Category = "System"; CommandOn = "sc config WSearch start= disabled & sc stop WSearch"; CommandOff = "sc config WSearch start= delayed-auto & sc start WSearch"; Description = "Disable indexing service (SSD optimization)" },
    @{ Id = "SysMain"; Name = "Disable SysMain/Superfetch"; Risk = "Medium"; Category = "Memory"; CommandOn = "sc config SysMain start= disabled & sc stop SysMain"; CommandOff = "sc config SysMain start= auto & sc start SysMain"; Description = "Disable prefetch/superfetch (for SSD)" },
    @{ Id = "XboxServices"; Name = "Disable Xbox Services"; Risk = "Low"; Category = "Gaming"; CommandOn = "sc config XblAuthManager start= disabled & sc config XblGameSave start= disabled & sc config XboxNetApiSvc start= disabled"; CommandOff = "sc config XblAuthManager start= manual & sc config XblGameSave start= manual & sc config XboxNetApiSvc start= manual"; Description = "Disable Xbox background services" },
    
    # === NEW: BACKGROUND APPS/STARTUP ===
    @{ Id = "BackgroundApps"; Name = "Disable Background Apps"; Risk = "Low"; Category = "System"; Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"; Key = "GlobalUserDisabled"; ValueOn = 1; ValueOff = 0; Description = "Prevent UWP apps from running in background" },
    @{ Id = "StartupDelay2"; Name = "Remove All Startup Delay"; Risk = "Low"; Category = "System"; Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"; Key = "Serialize"; ValueOn = 0; ValueOff = 1; Description = "Remove delay before loading startup apps" },
    @{ Id = "OneDriveSU"; Name = "Disable OneDrive Startup"; Risk = "Low"; Category = "Privacy"; Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"; Key = "OneDrive"; ValueOn = 3; ValueOff = 2; Description = "Prevent OneDrive auto-start" },
    
    # === NEW: VISUAL/UI PERFORMANCE ===
    @{ Id = "DWMFlush"; Name = "DWM Animation Flush"; Risk = "Low"; Category = "UI"; Path = "HKCU:\SOFTWARE\Microsoft\Windows\DWM"; Key = "AnimationsShiftKey"; ValueOn = 0; ValueOff = 1; Description = "Faster DWM animation flush" },
    @{ Id = "MinAnimate"; Name = "Disable Min/Max Animate"; Risk = "Low"; Category = "UI"; Path = "HKCU:\Control Panel\Desktop\WindowMetrics"; Key = "MinAnimate"; ValueOn = "0"; ValueOff = "1"; Description = "Disable window animation" },
    @{ Id = "CursorBlink"; Name = "Faster Cursor Blink"; Risk = "Low"; Category = "UI"; Path = "HKCU:\Control Panel\Desktop"; Key = "CursorBlinkRate"; ValueOn = "-1"; ValueOff = "530"; Description = "Disable cursor blink (saves CPU cycles)" },
    
    # === NEW: EXPLORER/SHELL ===
    @{ Id = "ExplorerHeap"; Name = "Explorer Large Heap"; Risk = "Low"; Category = "System"; Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"; Key = "AlwaysUnloadDLL"; ValueOn = 1; ValueOff = 0; Description = "Free DLLs from memory when not used" },
    @{ Id = "ThumbnailCache"; Name = "Disable Thumbnail Cache"; Risk = "Low"; Category = "Storage"; Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Key = "DisableThumbnailCache"; ValueOn = 1; ValueOff = 0; Description = "Don't cache folder thumbnails" },

    # === LENOVO-SPECIFIC TWEAKS ===
    # These are only applied on Lenovo systems (condition checked at runtime)
    @{ Id = "LenovoHybrid"; Name = "Lenovo Hybrid Mode (dGPU)"; Risk = "Medium"; Category = "Lenovo"; ConditionScript = "Test-LenovoSystem"; WmiSetting = "HybridMode"; WmiValueOn = "Disable"; WmiValueOff = "Enable"; Description = "Force dedicated GPU for gaming" },
    @{ Id = "LenovoPerf"; Name = "Lenovo Max Performance"; Risk = "Low"; Category = "Lenovo"; ConditionScript = "Test-LenovoSystem"; WmiSetting = "AdaptiveThermalManagementAC"; WmiValueOn = "MaximizePerformance"; WmiValueOff = "Balanced"; Description = "Maximum thermal on AC" },
    @{ Id = "LenovoOverDrive"; Name = "Lenovo LCD OverDrive"; Risk = "Low"; Category = "Lenovo"; ConditionScript = "Test-LenovoSystem"; WmiSetting = "OverDriveMode"; WmiValueOn = "Enable"; WmiValueOff = "Disable"; Description = "Faster LCD response time" },
    @{ Id = "LenovoGPUOC"; Name = "Lenovo GPU Overclock"; Risk = "Medium"; Category = "Lenovo"; ConditionScript = "Test-LenovoSystem"; WmiSetting = "GPUOverclock"; WmiValueOn = "Enable"; WmiValueOff = "Disable"; Description = "Enable GPU boost mode" },
    @{ Id = "LenovoCharge"; Name = "Lenovo Battery Conservation"; Risk = "Low"; Category = "Lenovo"; ConditionScript = "Test-LenovoSystem"; WmiSetting = "BatteryConservationMode"; WmiValueOn = "Enable"; WmiValueOff = "Disable"; Description = "Limit charge to 60% for longevity" }
)

# Persistent State Management
function Get-NeuralBrain {
    if (Test-Path $Script:BrainPath) {
        try { return Get-Content $Script:BrainPath -Raw | ConvertFrom-Json }
        catch { return @{ History = @(); Stats = @{} } }
    }
    return @{ History = @(); Stats = @{} }
}

function Save-NeuralBrain {
    param($Data)
    try { $Data | ConvertTo-Json -Depth 10 | Set-Content $Script:BrainPath -Force -Encoding UTF8 }
    catch { Write-Host " [!] Error saving AI Brain: $_" -ForegroundColor Red }
}

function Get-QTable {
    if (Test-Path $Script:QTablePath) {
        try {
            $json = Get-Content $Script:QTablePath -Raw | ConvertFrom-Json
            $table = @{}
            $json.PSObject.Properties | ForEach-Object {
                $table[$_.Name] = @{}
                if ($_.Value) {
                    $_.Value.PSObject.Properties | ForEach-Object { $table[$_.Name][$_.Name] = $_.Value }
                }
            }
            return $table
        }
        catch { return @{} }
    }
    return @{}
}

function Save-QTable {
    param($QTable)
    try { $QTable | ConvertTo-Json -Depth 5 | Set-Content $Script:QTablePath -Force -Encoding UTF8 }
    catch { Write-Host " [!] Error saving Q-Table: $_" -ForegroundColor Red }
}

function Get-NeuralConfig {
    $default = @{ Epsilon = $Script:QLearningConfig.EpsilonInitial; LearningCycles = 0 }
    
    if (Test-Path $Script:ConfigPath) {
        try { 
            $loaded = Get-Content $Script:ConfigPath -Raw | ConvertFrom-Json
            # Ensure return is a PSCustomObject
            if (-not ($loaded -is [PSCustomObject])) {
                return [PSCustomObject]$default
            }
            # Ensure properties exist
            if (-not $loaded.PSObject.Properties['Epsilon']) { 
                $loaded | Add-Member -MemberType NoteProperty -Name 'Epsilon' -Value $default.Epsilon 
            }
            if (-not $loaded.PSObject.Properties['LearningCycles']) { 
                $loaded | Add-Member -MemberType NoteProperty -Name 'LearningCycles' -Value $default.LearningCycles 
            }
            return $loaded
        }
        catch { return [PSCustomObject]$default }
    }
    return [PSCustomObject]$default
}

function Save-NeuralConfig {
    param($Config)
    try { $Config | ConvertTo-Json | Set-Content $Script:ConfigPath -Force -Encoding UTF8 }
    catch { }
}

# Expanded Metrics Collection
function Measure-SystemMetrics {
    param([int]$DurationSeconds = 5)
    
    Write-Host "   [AI] Measuring System Metrics (Extended)..." -ForegroundColor Cyan
    
    $metrics = @{
        DpcTime       = 0
        InterruptTime = 0
        ContextSwitch = 0
        GpuUsage      = 0
        DiskQueue     = 0
        NetworkPing   = 0
        CpuTemp       = 0
        Score         = 50
        Timestamp     = Get-Date
    }
    
    try {
        # Use WMI/CIM for Language Independence (Spanish/English compatible)
        $procStats = Get-CimInstance -Class Win32_PerfFormattedData_PerfOS_Processor -Filter "Name='_Total'" -ErrorAction Stop
        $sysStats = Get-CimInstance -Class Win32_PerfFormattedData_PerfOS_System -ErrorAction SilentlyContinue
        $diskStats = Get-CimInstance -Class Win32_PerfFormattedData_PerfDisk_PhysicalDisk -Filter "Name='_Total'" -ErrorAction SilentlyContinue

        if ($procStats) {
            $metrics.DpcTime = $procStats.PercentDPCTime
            $metrics.InterruptTime = $procStats.PercentInterruptTime
            $metrics.ProcessorTime = $procStats.PercentProcessorTime # Internal tracking
        }
        if ($sysStats) {
            $metrics.ContextSwitch = $sysStats.ContextSwitchesPerSec
        }
        if ($diskStats) {
            $metrics.DiskQueue = $diskStats.CurrentDiskQueueLength
        }
    }
    catch { 
        Write-Host "   [!] WMI Counters unavailable. Trying legacy fallback..." -ForegroundColor Yellow 
        # Fallback to English counters if WMI fails (rare)
        try {
            $counters = @("\Processor(_Total)\% DPC Time", "\Processor(_Total)\% Interrupt Time", "\System\Context Switches/sec")
            $samples = Get-Counter -Counter $counters -SampleInterval 1 -MaxSamples 1
            $metrics.DpcTime = ($samples.CounterSamples | Where-Object { $_.Path -match "dpc" }).CookedValue
        }
        catch {}
    }
    
    try {
        $ping = Test-Connection -ComputerName "8.8.8.8" -Count 2 -ErrorAction Stop
        $metrics.NetworkPing = [math]::Round(($ping.ResponseTime | Measure-Object -Average).Average, 0)
    }
    catch { $metrics.NetworkPing = 999 }
    
    try {
        $temp = Get-CimInstance -Namespace root\WMI -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction Stop
        if ($temp) {
            $kelvin = ($temp.CurrentTemperature | Measure-Object -Average).Average
            $metrics.CpuTemp = [math]::Round(($kelvin / 10) - 273.15, 1)
        }
    }
    catch { $metrics.CpuTemp = 0 }
    
    $metrics.Score = Get-CompositeScore -Metrics $metrics
    return [PSCustomObject]$metrics
}

# Deep Learning: Load State Detection
function Get-SystemLoadState {
    try {
        $cpu = (Get-Counter "\Processor(_Total)\% Processor Time" -MaxSamples 2 -SampleInterval 1 -ErrorAction SilentlyContinue).CounterSamples.CookedValue | Measure-Object -Average | Select-Object -ExpandProperty Average
        $disk = (Get-Counter "\PhysicalDisk(_Total)\% Disk Time" -MaxSamples 2 -SampleInterval 1 -ErrorAction SilentlyContinue).CounterSamples.CookedValue | Measure-Object -Average | Select-Object -ExpandProperty Average
        
        # Simple heuristic for User Presence (could be expanded)
        # For now, we assume user is active if script is running interactively
        
        if ($cpu -lt 10 -and $disk -lt 10) { return "Idle" }
        if ($cpu -gt 80 -or $disk -gt 90) { return "Thrashing" }
        if ($cpu -gt 40) { return "Heavy" }
        return "Light"
    }
    catch { return "General" }
}

function Get-CompositeScore {
    param($Metrics)
    $score = 100
    
    # Non-linear Multi-dimensional Penalties
    
    # 1. Latency Penalty (Exponential decay)
    if ($Metrics.DpcTime -gt 0.5) { $score -= [math]::Pow($Metrics.DpcTime * 2, 1.5) } 
    if ($Metrics.InterruptTime -gt 0.5) { $score -= [math]::Pow($Metrics.InterruptTime * 2, 1.5) }
    
    # 2. Stability Penalty (Context Switching)
    if ($Metrics.ContextSwitch -gt 3000) { 
        $delta = $Metrics.ContextSwitch - 3000
        $score -= [math]::Log($delta) * 5 # Logarithmic penalty for massive switching
    }
    
    # 3. I/O BottleNeck
    if ($Metrics.DiskQueue -gt 1) { $score -= ($Metrics.DiskQueue * 4) }
    
    # 4. Network Jitter Proxy (Ping)
    if ($Metrics.NetworkPing -gt 30) { $score -= ($Metrics.NetworkPing - 30) / 5 }
    
    # 5. Thermal Throttle Risk
    if ($Metrics.CpuTemp -gt 80) { $score -= ($Metrics.CpuTemp - 80) * 3 } # Aggressive thermal penalty
    
    return [math]::Max(0, [math]::Min(100, [math]::Round($score, 2)))
}

# Q-Learning Engine
function Get-CurrentState {
    param($Hardware, $Workload)
    $hour = (Get-Date).Hour
    $timeSlot = switch ($hour) {
        { $_ -ge 6 -and $_ -lt 12 } { "Morning" }
        { $_ -ge 12 -and $_ -lt 18 } { "Afternoon" }
        { $_ -ge 18 -and $_ -lt 23 } { "Evening" }
        default { "Night" }
    }
    $tier = if ($Hardware.PerformanceTier) { $Hardware.PerformanceTier } else { "Standard" }
    $work = if ($Workload) { $Workload } else { "General" }
    $load = Get-SystemLoadState
    
    # Deep State: Tier|Workload|Time|Load
    return "$tier|$work|$timeSlot|$load"
}

function Get-AvailableActions {
    param([string]$RiskLevel = "Low")
    $actions = @()
    foreach ($tweak in $Script:TweakLibrary) {
        if ($RiskLevel -eq "All" -or $tweak.Risk -eq $RiskLevel -or ($RiskLevel -eq "Medium" -and $tweak.Risk -eq "Low")) {
            $actions += $tweak.Id
        }
    }
    return $actions
}

function Get-QValue {
    param($QTable, $State, $Action)
    if ($QTable.ContainsKey($State) -and $QTable[$State].ContainsKey($Action)) { return $QTable[$State][$Action] }
    return 0.0
}

function Set-QValue {
    param($QTable, $State, $Action, $Value)
    if (-not $QTable.ContainsKey($State)) { $QTable[$State] = @{} }
    $QTable[$State][$Action] = $Value
}

function Select-Action {
    param($QTable, $State, $AvailableActions, $Epsilon)
    if ($AvailableActions.Count -eq 0) { return $null }
    if ((Get-Random -Minimum 0.0 -Maximum 1.0) -lt $Epsilon) { return $AvailableActions | Get-Random }
    $bestAction = $null
    $bestValue = [double]::MinValue
    foreach ($action in $AvailableActions) {
        $value = Get-QValue -QTable $QTable -State $State -Action $action
        if ($value -gt $bestValue) { $bestValue = $value; $bestAction = $action }
    }
    if ($null -eq $bestAction) { return $AvailableActions | Get-Random }
    return $bestAction
}

function Update-QValue {
    param($QTable, $State, $Action, $Reward, $NewState, $AvailableActions)
    $alpha = $Script:QLearningConfig.Alpha
    $gamma = $Script:QLearningConfig.Gamma
    $currentQ = Get-QValue -QTable $QTable -State $State -Action $Action
    $maxNewQ = 0
    foreach ($a in $AvailableActions) {
        $q = Get-QValue -QTable $QTable -State $NewState -Action $a
        if ($q -gt $maxNewQ) { $maxNewQ = $q }
    }
    $newQ = $currentQ + $alpha * ($Reward + $gamma * $maxNewQ - $currentQ)
    Set-QValue -QTable $QTable -State $State -Action $Action -Value $newQ
}

# Tweak Application
function Invoke-Tweak {
    param([string]$TweakId, [switch]$Apply, [switch]$Revert)
    $tweak = $Script:TweakLibrary | Where-Object { $_.Id -eq $TweakId }
    if (-not $tweak) { Write-Host "   [!] Tweak not found: $TweakId" -ForegroundColor Red; return $false }
    
    # Check condition if present
    if ($tweak.ConditionScript) {
        try {
            $canApply = Invoke-Expression $tweak.ConditionScript
            if (-not $canApply) {
                Write-Host "   [i] Skipping $TweakId (condition not met)" -ForegroundColor DarkGray
                return $false
            }
        }
        catch { return $false }
    }
    
    $value = if ($Apply) { $tweak.ValueOn } else { $tweak.ValueOff }
    $command = if ($Apply) { $tweak.CommandOn } else { $tweak.CommandOff }
    $wmiValue = if ($Apply) { $tweak.WmiValueOn } else { $tweak.WmiValueOff }
    
    try {
        if ($tweak.WmiSetting) {
            # Lenovo WMI-based tweak
            $setBios = Get-CimInstance -Namespace root\wmi -ClassName Lenovo_SetBiosSetting -ErrorAction Stop
            $setResult = $setBios | Invoke-CimMethod -MethodName SetBiosSetting -Arguments @{ parameter = "$($tweak.WmiSetting),$wmiValue" }
            if ($setResult.return -eq "Success") {
                $saveBios = Get-CimInstance -Namespace root\wmi -ClassName Lenovo_SaveBiosSettings -ErrorAction Stop
                $saveBios | Invoke-CimMethod -MethodName SaveBiosSettings -Arguments @{ parameter = "" } | Out-Null
                return $true
            }
            return $false
        }
        elseif ($tweak.Path) {
            # Registry-based tweak
            if (-not (Test-Path $tweak.Path)) { New-Item -Path $tweak.Path -Force | Out-Null }
            Set-ItemProperty -Path $tweak.Path -Name $tweak.Key -Value $value -Force
            return $true
        }
        elseif ($command) {
            # Command-based tweak
            Invoke-Expression $command 2>&1 | Out-Null
            return $true
        }
        return $false
    }
    catch { Write-Host "   [!] Failed: $_" -ForegroundColor Red; return $false }
}

# Main Learning Cycle
function Invoke-NeuralLearning {
    param([string]$ProfileName, [object]$Hardware, [string]$Workload = "General")
    
    Write-Section "NEURAL Q-LEARNING CYCLE v2.0 (DEEP LEARNING)"
    
    $config = Get-NeuralConfig
    $qTable = Get-QTable
    $brain = Get-NeuralBrain
    $epsilon = if ($config.Epsilon) { $config.Epsilon } else { $Script:QLearningConfig.EpsilonInitial }
    
    # Deep Learning: Consolidate Long-Term Memory
    Update-PersistenceRewards -QTable $qTable
    
    $state = Get-CurrentState -Hardware $Hardware -Workload $Workload
    Write-Host "   [STATE] $state" -ForegroundColor Gray
    Write-Host "   [e] Exploration Rate: $([math]::Round($epsilon * 100, 1))%" -ForegroundColor Gray
    
    Write-Host ""
    Write-Host "   [AI] Measuring Baseline..." -ForegroundColor Cyan
    $baselineMetrics = Measure-SystemMetrics -DurationSeconds 3
    $baselineScore = $baselineMetrics.Score
    Write-Host "   [BASELINE] Score: $baselineScore/100" -ForegroundColor Yellow
    
    $availableActions = Get-AvailableActions -RiskLevel "Low"
    $selectedAction = Select-Action -QTable $qTable -State $state -AvailableActions $availableActions -Epsilon $epsilon
    
    $newScore = $baselineScore
    $reward = 0
    
    if ($selectedAction) {
        $tweak = $Script:TweakLibrary | Where-Object { $_.Id -eq $selectedAction }
        Write-Host ""
        Write-Host "   [ACTION] Selected: $($tweak.Name) ($selectedAction)" -ForegroundColor Magenta
        
        $applied = Invoke-Tweak -TweakId $selectedAction -Apply
        if ($applied) {
            Start-Sleep -Seconds 2
            Write-Host "   [AI] Measuring Impact..." -ForegroundColor Cyan
            $newMetrics = Measure-SystemMetrics -DurationSeconds 3
            $newScore = $newMetrics.Score
            $reward = $newScore - $baselineScore
            
            Write-Host ""
            if ($reward -gt 0) { Write-Host "   [RESULT] Score: $newScore (+$reward) IMPROVEMENT" -ForegroundColor Green }
            elseif ($reward -lt 0) {
                Write-Host "   [RESULT] Score: $newScore ($reward) REGRESSION" -ForegroundColor Red
                Write-Host "   [AI] Reverting tweak..." -ForegroundColor Yellow
                Invoke-Tweak -TweakId $selectedAction -Revert | Out-Null
            }
            else { Write-Host "   [RESULT] Score: $newScore - NO CHANGE" -ForegroundColor Gray }
            
            Update-QValue -QTable $qTable -State $state -Action $selectedAction -Reward $reward -NewState $state -AvailableActions $availableActions
            Save-QTable -QTable $qTable
            
            $epsilon = [math]::Max($Script:QLearningConfig.EpsilonMin, $epsilon * $Script:QLearningConfig.EpsilonDecay)
            $config.Epsilon = $epsilon
            $config.LearningCycles = ($config.LearningCycles -as [int]) + 1
            Save-NeuralConfig -Config $config
        }
    }
    else { Write-Host "   [AI] No suitable actions available" -ForegroundColor Yellow }
    
    if (-not $brain.History) { $brain = @{ History = @(); Stats = @{} } }
    $record = @{
        Timestamp     = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Hardware      = if ($Hardware.CpuName) { $Hardware.CpuName } else { "Unknown" }
        Tier          = if ($Hardware.PerformanceTier) { $Hardware.PerformanceTier } else { "Standard" }
        Profile       = $ProfileName
        Workload      = $Workload
        State         = $state
        Action        = $selectedAction
        BaselineScore = $baselineScore
        FinalScore    = $newScore
        Reward        = $reward
        Metrics       = $baselineMetrics
    }
    $history = @($brain.History) + $record
    $brain.History = $history | Select-Object -Last 100
    Save-NeuralBrain -Data $brain
    
    Write-Host ""
    Show-QLearningInsights -QTable $qTable -State $state
}

function Show-QLearningInsights {
    param($QTable, $State)
    Write-Host "   === Q-LEARNING INSIGHTS ===" -ForegroundColor Cyan
    if ($QTable.ContainsKey($State)) {
        $stateActions = $QTable[$State]
        Write-Host "   Top actions for state [$State]:" -ForegroundColor Gray
        $stateActions.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 5 | ForEach-Object {
            $color = if ($_.Value -gt 0) { "Green" } elseif ($_.Value -lt 0) { "Red" } else { "Gray" }
            Write-Host "     $($_.Name): Q=$([math]::Round($_.Value, 3))" -ForegroundColor $color
        }
    }
    else { Write-Host "   No learned actions for current state yet." -ForegroundColor Yellow }
    $config = Get-NeuralConfig
    Write-Host "   Total Learning Cycles: $($config.LearningCycles)" -ForegroundColor DarkGray
}

# Recommendations
function Get-NeuralRecommendation {
    param($Hardware, $Workload = "General")
    $qTable = Get-QTable
    $state = Get-CurrentState -Hardware $Hardware -Workload $Workload
    if (-not $qTable.ContainsKey($state)) { return $null }
    $stateActions = $qTable[$state]
    $bestAction = $stateActions.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1
    if ($bestAction -and $bestAction.Value -gt 0) {
        $tweak = $Script:TweakLibrary | Where-Object { $_.Id -eq $bestAction.Name }
        return [PSCustomObject]@{
            RecommendedAction = $bestAction.Name
            ActionName        = if ($tweak) { $tweak.Name } else { $bestAction.Name }
            Confidence        = [math]::Min(100, [math]::Round(50 + $bestAction.Value * 5, 0))
            Reason            = "Best tweak based on Q-Learning (Q=$([math]::Round($bestAction.Value, 3)))"
            Risk              = if ($tweak) { $tweak.Risk } else { "Unknown" }
        }
    }
    return $null
}

function Get-BestTweaksForState {
    param($Hardware, $Workload = "General", $TopN = 5)
    $qTable = Get-QTable
    $state = Get-CurrentState -Hardware $Hardware -Workload $Workload
    $recommendations = @()
    if ($qTable.ContainsKey($state)) {
        $stateActions = $qTable[$state]
        $stateActions.GetEnumerator() | Where-Object { $_.Value -gt 0 } | Sort-Object Value -Descending | Select-Object -First $TopN | ForEach-Object {
            $actionEntry = $_
            $tweakObj = $Script:TweakLibrary | Where-Object { $_.Id -eq $actionEntry.Name }
            $recommendations += [PSCustomObject]@{
                TweakId     = $actionEntry.Name
                Name        = if ($tweakObj) { $tweakObj.Name } else { $actionEntry.Name }
                Category    = if ($tweakObj) { $tweakObj.Category } else { "Unknown" }
                QValue      = [math]::Round($actionEntry.Value, 3)
                Risk        = if ($tweakObj) { $tweakObj.Risk } else { "Unknown" }
                Description = if ($tweakObj) { $tweakObj.Description } else { "" }
            }
        }
    }
    return $recommendations
}

function Invoke-ExploratoryTweak {
    param($CurrentScore)
    Write-Host "   [AI] Exploration is now integrated into Q-Learning cycle" -ForegroundColor Cyan
    Write-Host "   [AI] Run Invoke-NeuralLearning for adaptive exploration" -ForegroundColor Gray
}

function Update-PersistenceRewards {
    param($QTable)
    
    $brain = Get-NeuralBrain
    if (-not $brain.History) { return }
    
    # 1. Identify successful actions from 24h+ ago
    $cutoff = (Get-Date).AddHours(-48) # Look back 2 days
    $longTermSuccess = $brain.History | Where-Object { 
        $_.Reward -gt 0 -and 
        ([DateTime]$_.Timestamp) -gt $cutoff 
    }
    
    foreach ($record in $longTermSuccess) {
        # 2. Reinforce the Q-Value slightly (Memory Consolidation)
        $state = $record.State
        $action = $record.Action
        
        # If Q-Table still has this state/action pair
        if ($QTable.ContainsKey($state) -and $QTable[$state].ContainsKey($action)) {
            $currentQ = $QTable[$state][$action]
            # Small reinforcement (0.01) to solidify "good habits"
            $newQ = $currentQ + 0.01 
            Set-QValue -QTable $QTable -State $state -Action $action -Value $newQ
        }
    }
    Write-Host "   [AI] Long-Term Memory Consolidated ($($longTermSuccess.Count) records processed)" -ForegroundColor DarkGray
}

function Get-BestAction {
    param(
        [hashtable]$QTable,
        [string]$State,
        [array]$AvailableActions,
        [double]$Epsilon
    )

    # Exploration (Epsilon-Greedy)
    if ((Get-Random -Minimum 0.0 -Maximum 1.0) -lt $Epsilon) {
        return $AvailableActions | Get-Random
    }

    # Exploitation (Best Known Action)
    if ($QTable.ContainsKey($State)) {
        $actions = $QTable[$State]
        
        # Sort by Q-Value descending
        $bestAction = $actions.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1
        
        if ($bestAction) {
            return $bestAction.Key
        }
    }

    # Fallback (New State or Empty): Random
    return $AvailableActions | Get-Random
}

function Set-UserFeedback {
    param([int]$Reward)
    
    $brain = Get-NeuralBrain
    $qTable = Get-QTable
    
    if ($brain.History.Count -gt 0) {
        $lastAction = $brain.History | Select-Object -Last 1
        $state = $lastAction.State
        $action = $lastAction.Action
        
        if ($QTable.ContainsKey($state) -and $QTable[$state].ContainsKey($action)) {
            $currentQ = $QTable[$state][$action]
            $newQ = $currentQ + ($Reward * 0.1) # Manual feedback has high weight
            Set-QValue -QTable $QTable -State $state -Action $action -Value $newQ
            Save-QTable -QTable $QTable
            
            $type = if ($Reward -gt 0) { "REINFORCED" } else { "PUNISHED" }
            Write-Host "   [MANUAL] Last action '$action' was $type by user." -ForegroundColor Magenta
        }
    }
}



function Start-NeuralAutoPilot {
    param(
        [string]$ProfileName, 
        [int]$TargetScore = 95,
        [int]$MaxNoOps = 5
    )
    
    Clear-Host
    Write-Host " ==========================================================" -ForegroundColor Magenta
    Write-Host "   NEURAL AUTO-PILOT ENGAGED (SMART STOP MODE)" -ForegroundColor Yellow
    Write-Host "   Target: $TargetScore+ | Convergence Limit: $MaxNoOps cycles" -ForegroundColor Gray
    Write-Host "   Press CTRL+C to Stop Manually" -ForegroundColor Gray
    Write-Host " ==========================================================" -ForegroundColor Magenta
    Write-Host ""
    
    $qTable = Get-QTable
    $brain = Get-NeuralBrain
    $epsilon = 0.15 # Low exploration for AutoPilot
    $consecutiveNoOps = 0
    
    while ($true) {
        $hardware = Get-HardwareProfile
        $loadState = Get-SystemLoadState
        
        # 1. Safety Pause
        if ($loadState -eq "Thrashing") {
            Write-Host "   [!] System High Load. Pausing 30s..." -ForegroundColor Red
            Start-Sleep -Seconds 30
            continue
        }
        
        Write-Host "   [AUTO] Analyzing System State ($loadState)..." -ForegroundColor Cyan
        
        # 2. Deep Verification Baseline (10s)
        Write-Host "   [VERIFY] Measuring Baseline (10s deep scan)..." -ForegroundColor DarkGray
        $baseline = Measure-SystemMetrics -DurationSeconds 10
        Write-Host "   [BASELINE] Score: $($baseline.Score)" -ForegroundColor Yellow
        
        # 3. SMART STOP CHECK
        if ($baseline.Score -ge $TargetScore) {
            if ($consecutiveNoOps -ge $MaxNoOps) {
                Write-Host ""
                Write-Host "   [OPTIMIZATION COMPLETE] Target Reached & Converged." -ForegroundColor Green
                Write-Host "   Final Score: $($baseline.Score)" -ForegroundColor Green
                Write-Host "   System is fully optimized. Auto-Pilot stopping." -ForegroundColor Cyan
                Write-Host " ==========================================================" -ForegroundColor Magenta
                break # EXIT LOOP
            }
            else {
                Write-Host "   [OPTIMAL] Score is high ($($baseline.Score)). Checking stability ($consecutiveNoOps/$MaxNoOps)..." -ForegroundColor Green
                $consecutiveNoOps++
            }
        }
        
        # 4. Action Selection
        $state = Get-CurrentState -Hardware $hardware -Workload "AutoPilot"
        $action = Get-BestAction -QTable $qTable -State $state -AvailableActions $Script:TweakLibrary.Id -Epsilon $epsilon
        
        if ($action) {
            Write-Host "   [ACT] Applying Tweak: $action" -ForegroundColor White
            $applied = Invoke-Tweak -TweakId $action -Apply
            
            if ($applied) {
                # Deep Verify Result
                Start-Sleep -Seconds 2
                $result = Measure-SystemMetrics -DurationSeconds 10
                $reward = Get-CompositeScore -Baseline $baseline -Current $result -RiskLevel "Medium"
                
                $resultColor = if ($reward -gt 0) { "Green" } else { "Red" }
                Write-Host "   [RESULT] New Score: $($result.Score) | Reward: $reward" -ForegroundColor $resultColor
                
                # Update Q-Table
                $newState = Get-CurrentState -Hardware $hardware -Workload "AutoPilot"
                Update-QValue -QTable $qTable -State $state -Action $action -Reward $reward -NewState $newState -AvailableActions $Script:TweakLibrary.Id
                
                # History
                $record = @{ Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"; State = $state; Action = $action; Reward = $reward; Mode = "AutoPilot" }
                $brain.History += $record
                $brain.History = $brain.History | Select-Object -Last 100
                
                if ($reward -gt 0) {
                    $consecutiveNoOps = 0 # Reset counter on valid improvement
                }
                elseif ($reward -lt 0) {
                    Write-Host "   [REVERT] Reverting..." -ForegroundColor Yellow
                    Invoke-Tweak -TweakId $action -Revert
                    $consecutiveNoOps++ # Failure counts towards convergence
                }
                
                Save-QTable -QTable $qTable
                Save-NeuralBrain -Data $brain
            }
            else {
                $consecutiveNoOps++
            }
        }
        else {
            Write-Host "   [SKIP] No confident actions found." -ForegroundColor DarkGray
            $consecutiveNoOps++
        }
        
        Write-Host "   [WAIT] Cooling down (5s)..." -ForegroundColor DarkGray
        Start-Sleep -Seconds 5
    }
}

Export-ModuleMember -Function @(
    'Invoke-NeuralLearning',
    'Get-NeuralRecommendation', 
    'Get-NeuralBrain',
    'Measure-SystemMetrics',
    'Get-BestTweaksForState',
    'Get-BestAction',
    'Get-QTable',
    'Invoke-ExploratoryTweak',
    'Get-SystemLoadState',
    'Update-PersistenceRewards',
    'Set-UserFeedback',
    'Start-NeuralAutoPilot'
)

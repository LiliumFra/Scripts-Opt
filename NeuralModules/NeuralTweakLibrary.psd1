@{
    TweakLibrary = @(
        # === LOW RISK TWEAKS ===
        # Latency
        @{ Id = "TimerRes"; Name = "Global Timer Resolution"; Risk = "Low"; Category = "Latency"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel"; Key = "GlobalTimerResolutionRequests"; ValueOn = 1; ValueOff = 0; Description = "Forces high-resolution timer" }
        @{ Id = "DynamicTick"; Name = "Disable Dynamic Tick"; Risk = "Low"; Category = "Latency"; CommandOn = "bcdedit /set disabledynamictick yes"; CommandOff = "bcdedit /set disabledynamictick no"; Description = "Disables power-saving tick" }
        @{ Id = "HPET"; Name = "Disable HPET"; Risk = "Low"; Category = "Latency"; CommandOn = "bcdedit /set useplatformclock no"; CommandOff = "bcdedit /set useplatformclock yes"; Description = "Uses TSC instead of HPET" }
        @{ Id = "TSCSync"; Name = "TSC Sync Policy"; Risk = "Low"; Category = "Latency"; CommandOn = "bcdedit /set tscsyncpolicy enhanced"; CommandOff = "bcdedit /deletevalue tscsyncpolicy"; Description = "Enhanced TSC synchronization" }
        
        # Gaming
        @{ Id = "GameMode"; Name = "Enable Game Mode"; Risk = "Low"; Category = "Gaming"; Path = "HKCU:\Software\Microsoft\GameBar"; Key = "AllowAutoGameMode"; ValueOn = 1; ValueOff = 0; Description = "Windows Game Mode" }
        @{ Id = "FSO"; Name = "Fullscreen Optimizations"; Risk = "Low"; Category = "Gaming"; Path = "HKCU:\System\GameConfigStore"; Key = "GameDVR_FSEBehaviorMode"; ValueOn = 2; ValueOff = 0; Description = "Disable FSO for classic fullscreen" }
        @{ Id = "GameBar"; Name = "Disable Game Bar"; Risk = "Low"; Category = "Gaming"; Path = "HKCU:\Software\Microsoft\GameBar"; Key = "UseNexusForGameBarEnabled"; ValueOn = 0; ValueOff = 1; Description = "Disable Xbox Game Bar overlay" }
        @{ Id = "GameDVR"; Name = "Disable Game DVR"; Risk = "Low"; Category = "Gaming"; Path = "HKCU:\System\GameConfigStore"; Key = "GameDVR_Enabled"; ValueOn = 0; ValueOff = 1; Description = "Disable background recording" }
        
        # Input
        @{ Id = "MouseAccel"; Name = "Disable Mouse Acceleration"; Risk = "Low"; Category = "Input"; Path = "HKCU:\Control Panel\Mouse"; Key = "MouseSpeed"; ValueOn = "0"; ValueOff = "1"; Description = "Raw mouse input" }
        @{ Id = "MouseHover"; Name = "Faster Tooltips"; Risk = "Low"; Category = "Input"; Path = "HKCU:\Control Panel\Mouse"; Key = "MouseHoverTime"; ValueOn = "10"; ValueOff = "400"; Description = "Faster tooltip display" }
        
        # Network
        @{ Id = "TcpAck"; Name = "TCP ACK Frequency"; Risk = "Low"; Category = "Network"; Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Key = "TcpAckFrequency"; ValueOn = 1; ValueOff = 2; Description = "Immediate TCP ack" }
        @{ Id = "NagleOff"; Name = "Disable Nagle"; Risk = "Low"; Category = "Network"; Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Key = "TcpNoDelay"; ValueOn = 1; ValueOff = 0; Description = "Disable packet buffering" }
        @{ Id = "NetThrottle"; Name = "Disable Network Throttling"; Risk = "Low"; Category = "Network"; Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"; Key = "NetworkThrottlingIndex"; ValueOn = 0xffffffff; ValueOff = 10; Description = "Remove network throttling" }
    
        # === WINDOWS 11 SPECIFIC (24H2 & Performance) ===
        @{ Id = "Win11HAGS"; Name = "Hardware Accel GPU Sched"; Risk = "Medium"; Category = "Gaming"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"; Key = "HwSchMode"; ValueOn = 2; ValueOff = 1; Description = "Minimize latency (Win10 2004+ / Win11)" }
        @{ Id = "Win11Game"; Name = "Game Mode Priority"; Risk = "Low"; Category = "Gaming"; Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"; Key = "Priority"; ValueOn = 6; ValueOff = 2; Description = "Prioritize Game Mode processes" }
        @{ Id = "Win11VBS"; Name = "Disable VBS (Volatile)"; Risk = "High"; Category = "Security"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard"; Key = "EnableVirtualizationBasedSecurity"; ValueOn = 0; ValueOff = 1; Description = "Disable VBS for max gaming perf (Reduces Security)" }
        @{ Id = "Win11Recall"; Name = "Disable Recall (AI Snapshots)"; Risk = "Low"; Category = "Privacy"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"; Key = "DisableAIDataAnalysis"; ValueOn = 1; ValueOff = 0; Description = "Disable Windows 11 Recall AI features" }
        @{ Id = "Win11Copilot"; Name = "Hide Copilot Taskbar"; Risk = "Low"; Category = "UI"; Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Key = "ShowCopilotButton"; ValueOn = 0; ValueOff = 1; Description = "Hides Copilot button" }
        
        # UI Performance (from Perfect-Windows-11)
        @{ Id = "MenuDelay"; Name = "Menu Show Delay"; Risk = "Low"; Category = "UI"; Path = "HKCU:\Control Panel\Desktop"; Key = "MenuShowDelay"; ValueOn = "0"; ValueOff = "400"; Description = "Instant menu display" }
        @{ Id = "StartupDelay"; Name = "Startup Delay"; Risk = "Low"; Category = "UI"; Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize"; Key = "StartupDelayInMSec"; ValueOn = 0; ValueOff = 500; Description = "Remove startup app delay" }
        @{ Id = "ForegroundLock"; Name = "Foreground Lock Timeout"; Risk = "Low"; Category = "UI"; Path = "HKCU:\Control Panel\Desktop"; Key = "ForegroundLockTimeout"; ValueOn = 0; ValueOff = 200000; Description = "Faster window switching" }
        
        # === MEDIUM RISK TWEAKS ===
        # Memory
        @{ Id = "MemCompress"; Name = "Disable Memory Compression"; Risk = "Medium"; Category = "Memory"; CommandOn = "Disable-MMAgent -MemoryCompression"; CommandOff = "Enable-MMAgent -MemoryCompression"; Description = "Saves CPU on 16GB+ RAM" }
        @{ Id = "LargePages"; Name = "Large System Pages"; Risk = "Medium"; Category = "Memory"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Key = "LargePageMinimum"; ValueOn = 1; ValueOff = 0; Description = "Enable large memory pages" }
        
        # === KERNEL & SCHEDULER (2024-2025 Best Practices) ===
        @{ Id = "KernelDPC"; Name = "DPC Latency Optimization"; Risk = "Medium"; Category = "Latency"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel"; Key = "DpcWatchdogProfileOffset"; ValueOn = 0; ValueOff = 1; Description = "Reduce DPC queue latency" }
        @{ Id = "MemPriority"; Name = "Memory Priority Separation"; Risk = "Low"; Category = "Memory"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Key = "FeatureSettingsOverrideMask"; ValueOn = 3; ValueOff = 0; Description = "Better memory page handling" }
        @{ Id = "IOPriority"; Name = "IO Priority Boost"; Risk = "Low"; Category = "System"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\I/O System"; Key = "CountOperations"; ValueOn = 0; ValueOff = 1; Description = "Disable IO operation counting" }

        @{ Id = "CoreParking"; Name = "Disable Core Parking"; Risk = "Medium"; Category = "Scheduler"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583"; Key = "ValueMax"; ValueOn = 0; ValueOff = 100; Description = "Keep all cores active" }
        @{ Id = "PowerThrottle"; Name = "Disable Power Throttling"; Risk = "Medium"; Category = "Scheduler"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling"; Key = "PowerThrottlingOff"; ValueOn = 1; ValueOff = 0; Description = "Prevent CPU throttling" }
        
        # Shutdown/Startup
        @{ Id = "WaitToKill"; Name = "Faster Shutdown"; Risk = "Medium"; Category = "System"; Path = "HKCU:\Control Panel\Desktop"; Key = "WaitToKillAppTimeout"; ValueOn = "2000"; ValueOff = "20000"; Description = "Reduce shutdown wait" }
        @{ Id = "AutoEndTasks"; Name = "Auto End Tasks"; Risk = "Medium"; Category = "System"; Path = "HKCU:\Control Panel\Desktop"; Key = "AutoEndTasks"; ValueOn = "1"; ValueOff = "0"; Description = "Auto-kill hung apps" }
        @{ Id = "HungAppTimeout"; Name = "Hung App Timeout"; Risk = "Medium"; Category = "System"; Path = "HKCU:\Control Panel\Desktop"; Key = "HungAppTimeout"; ValueOn = "1000"; ValueOff = "5000"; Description = "Faster hung app detection" }
        
        # Privacy/Telemetry (from Win11Debloat)
        @{ Id = "Telemetry"; Name = "Disable Telemetry"; Risk = "Medium"; Category = "Privacy"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Key = "AllowTelemetry"; ValueOn = 0; ValueOff = 3; Description = "Disable data collection" }
        
        # === FILESYSTEM OPTIMIZATIONS ===
        @{ Id = "Ntfs83"; Name = "Disable 8.3 Naming"; Risk = "Low"; Category = "Filesystem"; CommandOn = "fsutil behavior set disable8dot3 1"; CommandOff = "fsutil behavior set disable8dot3 0"; Description = "Improves NTFS performance" }
        @{ Id = "NtfsLastAccess"; Name = "Disable Last Access Update"; Risk = "Low"; Category = "Filesystem"; CommandOn = "fsutil behavior set disablelastaccess 1"; CommandOff = "fsutil behavior set disablelastaccess 0"; Description = "Reduces disk write ops" }
        @{ Id = "NtfsEncrypt"; Name = "Disable EFS"; Risk = "Low"; Category = "Filesystem"; CommandOn = "fsutil behavior set disableencryption 1"; CommandOff = "fsutil behavior set disableencryption 0"; Description = "Disables EFS overhead" }
        
        # === ADVANCED NETWORK ===
        @{ Id = "CTCP"; Name = "CTCP Congestion Provider"; Risk = "Medium"; Category = "Network"; CommandOn = "netsh int tcp set supplemental template=internet congestionprovider=ctcp"; CommandOff = "netsh int tcp set supplemental template=internet congestionprovider=default"; Description = "Better throughput on high latency" }
        @{ Id = "RscIPv4"; Name = "Enable RSC (IPv4)"; Risk = "Medium"; Category = "Network"; CommandOn = "netsh int tcp set global rsc=enabled"; CommandOff = "netsh int tcp set global rsc=disabled"; Description = "Receive Segment Coalescing" }
        @{ Id = "RssIPv4"; Name = "Enable RSS"; Risk = "Medium"; Category = "Network"; CommandOn = "netsh int tcp set global rss=enabled"; CommandOff = "netsh int tcp set global rss=disabled"; Description = "Receive Side Scaling" }
        @{ Id = "NetOffload"; Name = "Disable Task Offload"; Risk = "Medium"; Category = "Network"; Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Key = "DisableTaskOffload"; ValueOn = 0; ValueOff = 1; Description = "Let NIC handle offloading" }
        
        # === PROCESSOR & THREADS ===
        @{ Id = "Win32Prio"; Name = "Win32 Priority Separation"; Risk = "Medium"; Category = "System"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"; Key = "Win32PrioritySeparation"; ValueOn = 38; ValueOff = 2; Description = "Optimizes for foreground apps (Hex 26)" }
        @{ Id = "SvcSplit"; Name = "Split Threshold"; Risk = "Medium"; Category = "System"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control"; Key = "SvcHostSplitThresholdInKB"; ValueOn = 380000; ValueOff = 38000000; Description = "Better RAM handling for svchost" }
        @{ Id = "LongPaths"; Name = "Enable Long Paths"; Risk = "Low"; Category = "System"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"; Key = "LongPathsEnabled"; ValueOn = 1; ValueOff = 0; Description = "Removes 260 char limit" }
        
        # === MEMORY & CACHE (Modern) ===
        @{ Id = "MemPageCombine"; Name = "Disable Page Combining"; Risk = "Low"; Category = "Memory"; CommandOn = "Disable-MMAgent -PageCombining -ErrorAction SilentlyContinue"; CommandOff = "Enable-MMAgent -PageCombining -ErrorAction SilentlyContinue"; Description = "Reduce memory management overhead" }
        @{ Id = "MemAppPrefetch"; Name = "Disable App Prefetch"; Risk = "Low"; Category = "Memory"; CommandOn = "Disable-MMAgent -ApplicationPreLaunch -ErrorAction SilentlyContinue"; CommandOff = "Enable-MMAgent -ApplicationPreLaunch -ErrorAction SilentlyContinue"; Description = "Reduce SSD wear (fast SSDs only)" }
        
        # === GAMING EXTRAS ===
        @{ Id = "GpuPrio"; Name = "GPU Priority"; Risk = "Medium"; Category = "Gaming"; Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"; Key = "GPU Priority"; ValueOn = 8; ValueOff = 8; Description = "High GPU priority" }
        @{ Id = "GamesPrio"; Name = "Games Scheduling"; Risk = "Medium"; Category = "Gaming"; Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"; Key = "Priority"; ValueOn = 6; ValueOff = 2; Description = "High CPU priority for games" }
        @{ Id = "GamesSched"; Name = "Games Category"; Risk = "Medium"; Category = "Gaming"; Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"; Key = "Scheduling Category"; ValueOn = "High"; ValueOff = "Medium"; Description = "High scheduling category" }
        
        # === PRIVACY EXTENSIONS ===
        @{ Id = "ExpBandwidth"; Name = "Experience Bandwidth"; Risk = "Low"; Category = "Privacy"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Key = "RestrictTelemetry"; ValueOn = 0; ValueOff = 0; Description = "Restrict extra telemetry" }
        @{ Id = "AppTrack"; Name = "Disable App Tracking"; Risk = "Low"; Category = "Privacy"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\EdgeUI"; Key = "DisableMFUTracking"; ValueOn = 1; ValueOff = 0; Description = "Disable most frequently used apps" }
        @{ Id = "Teredo"; Name = "Disable Teredo"; Risk = "Low"; Category = "Network"; CommandOn = "netsh interface teredo set state disabled"; CommandOff = "netsh interface teredo set state default"; Description = "Disable Teredo tunneling" }
        @{ Id = "ISATAP"; Name = "Disable ISATAP"; Risk = "Low"; Category = "Network"; CommandOn = "netsh interface isatap set state disabled"; CommandOff = "netsh interface isatap set state default"; Description = "Disable ISATAP tunneling" }
        @{ Id = "ActivityFeed"; Name = "Disable Activity History"; Risk = "Low"; Category = "Privacy"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Key = "EnableActivityFeed"; ValueOn = 0; ValueOff = 1; Description = "Erases recent docs, clipboard, run history" }
        @{ Id = "PublishActivity"; Name = "Disable Publish Activity"; Risk = "Low"; Category = "Privacy"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Key = "PublishUserActivities"; ValueOn = 0; ValueOff = 1; Description = "Stop publishing user activities" }
        @{ Id = "UploadActivity"; Name = "Disable Upload Activity"; Risk = "Low"; Category = "Privacy"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Key = "UploadUserActivities"; ValueOn = 0; ValueOff = 1; Description = "Stop uploading user activities" }
        
        # === NEW: ADVANCED NETWORK (Research-Based) ===
        @{ Id = "NetRSS"; Name = "Enable RSS (Receive Side Scaling)"; Risk = "Low"; Category = "Network"; CommandOn = "Enable-NetAdapterRss -Name * -ErrorAction SilentlyContinue"; CommandOff = "Disable-NetAdapterRss -Name * -ErrorAction SilentlyContinue"; Description = "Distribute network processing across CPU cores" }
        @{ Id = "NetRSC"; Name = "Enable RSC (Receive Segment Coalescing)"; Risk = "Medium"; Category = "Network"; CommandOn = "Enable-NetAdapterRsc -Name * -ErrorAction SilentlyContinue"; CommandOff = "Disable-NetAdapterRsc -Name * -ErrorAction SilentlyContinue"; Description = "Reduce CPU overhead (Warning: May increase gaming latency)" }
        @{ Id = "NetLSO"; Name = "Enable LSO (Large Send Offload)"; Risk = "Medium"; Category = "Network"; CommandOn = "Set-NetAdapterLso -Name * -IPv4Enabled $true -IPv6Enabled $true -ErrorAction SilentlyContinue"; CommandOff = "Set-NetAdapterLso -Name * -IPv4Enabled $false -IPv6Enabled $false -ErrorAction SilentlyContinue"; Description = "Offload packet segmentation to NIC" }
        @{ Id = "TcpMinRR"; Name = "TCP Min Retransmit Timeout"; Risk = "Low"; Category = "Network"; CommandOn = "Set-NetTCPSetting -SettingName Internet -MinRtoMs 300"; CommandOff = "Set-NetTCPSetting -SettingName Internet -MinRtoMs 1000"; Description = "Faster TCP retransmission recovery" }
        @{ Id = "TcpICW"; Name = "TCP Initial Congestion Window"; Risk = "Medium"; Category = "Network"; CommandOn = "Set-NetTCPSetting -SettingName Internet -InitialCongestionWindow 10"; CommandOff = "Set-NetTCPSetting -SettingName Internet -InitialCongestionWindow 4"; Description = "Faster download start (RFC 6928)" }
        @{ Id = "NetChecksum"; Name = "Offload Checksum"; Risk = "Low"; Category = "Network"; CommandOn = "Set-NetAdapterChecksumOffload -Name * -IpIPv4 Enabled -TcpIPv4 Enabled -UdpIPv4 Enabled -ErrorAction SilentlyContinue"; CommandOff = "Set-NetAdapterChecksumOffload -Name * -IpIPv4 Disabled -TcpIPv4 Disabled -UdpIPv4 Disabled -ErrorAction SilentlyContinue"; Description = "Offload checksum calculation to NIC" }

        # === SECURITY MODULE INTEGRATION ===
        @{ Id = "SecSMB1"; Name = "Disable SMBv1 Protocol"; Risk = "Low"; Category = "Security"; CommandOn = "Invoke-SecurityHardening -TweakId SecSMB1"; CommandOff = "Invoke-SecurityHardening -TweakId SecSMB1 -Revert"; Description = "Disable vulnerable SMBv1 protocol" }
        @{ Id = "SecNetBIOS"; Name = "Disable NetBIOS over TCP/IP"; Risk = "Medium"; Category = "Security"; CommandOn = "Invoke-SecurityHardening -TweakId SecNetBIOS"; CommandOff = "Invoke-SecurityHardening -TweakId SecNetBIOS -Revert"; Description = "Disable NetBIOS (reduces attack surface)" }
        @{ Id = "SecAnonEnum"; Name = "Restrict Anonymous Enumeration"; Risk = "Medium"; Category = "Security"; CommandOn = "Invoke-SecurityHardening -TweakId SecAnonEnum"; CommandOff = "Invoke-SecurityHardening -TweakId SecAnonEnum -Revert"; Description = "Prevent anonymous user enumeration" }
        @{ Id = "SecDep"; Name = "Enable DEP (Always On)"; Risk = "Medium"; Category = "Security"; CommandOn = "Invoke-SecurityHardening -TweakId SecDep"; CommandOff = "Invoke-SecurityHardening -TweakId SecDep -Revert"; Description = "Force Data Execution Prevention" }

        # === LENOVO-SPECIFIC TWEAKS ===
        @{ Id = "LenovoHybrid"; Name = "Lenovo Hybrid Mode (dGPU)"; Risk = "Medium"; Category = "Lenovo"; ConditionScript = "Test-LenovoSystem"; WmiSetting = "HybridMode"; WmiValueOn = "Disable"; WmiValueOff = "Enable"; Description = "Force dedicated GPU for gaming" }
        @{ Id = "LenovoPerf"; Name = "Lenovo Max Performance"; Risk = "Low"; Category = "Lenovo"; ConditionScript = "Test-LenovoSystem"; WmiSetting = "AdaptiveThermalManagementAC"; WmiValueOn = "MaximizePerformance"; WmiValueOff = "Balanced"; Description = "Maximum thermal on AC" }
        @{ Id = "LenovoOverDrive"; Name = "Lenovo LCD OverDrive"; Risk = "Low"; Category = "Lenovo"; ConditionScript = "Test-LenovoSystem"; WmiSetting = "OverDriveMode"; WmiValueOn = "Enable"; WmiValueOff = "Disable"; Description = "Faster LCD response time" }
        @{ Id = "LenovoGPUOC"; Name = "Lenovo GPU Overclock"; Risk = "Medium"; Category = "Lenovo"; ConditionScript = "Test-LenovoSystem"; WmiSetting = "GPUOverclock"; WmiValueOn = "Enable"; WmiValueOff = "Disable"; Description = "Enable GPU boost mode" }
        @{ Id = "LenovoCharge"; Name = "Lenovo Battery Conservation"; Risk = "Low"; Category = "Lenovo"; ConditionScript = "Test-LenovoSystem"; WmiSetting = "BatteryConservationMode"; WmiValueOn = "Enable"; WmiValueOff = "Disable"; Description = "Limit charge to 60% for longevity" }

        # === ADVANCED SERVICES (SAFE) ===
        @{ Id = "SvcTelefax"; Name = "Disable Fax Service"; Risk = "Low"; Category = "Services"; CommandOn = "Set-Service -Name SharedAccess -StartupType Disabled"; CommandOff = "Set-Service -Name SharedAccess -StartupType Manual"; Description = "Disable legacy Fax/SharedAccess" }
        @{ Id = "SvcMaps"; Name = "Disable Maps Broker"; Risk = "Low"; Category = "Services"; CommandOn = "Set-Service -Name MapsBroker -StartupType Disabled"; CommandOff = "Set-Service -Name MapsBroker -StartupType Automatic"; Description = "Disable downloaded maps manager" }
        @{ Id = "SvcWer"; Name = "Disable WerSvc"; Risk = "Low"; Category = "Services"; CommandOn = "Set-Service -Name WerSvc -StartupType Disabled"; CommandOff = "Set-Service -Name WerSvc -StartupType Manual"; Description = "Disable Windows Error Reporting Service" }
        @{ Id = "SvcPcaSvc"; Name = "Disable PcaSvc"; Risk = "Low"; Category = "Services"; CommandOn = "Set-Service -Name PcaSvc -StartupType Disabled"; CommandOff = "Set-Service -Name PcaSvc -StartupType Manual"; Description = "Disable Program Compatibility Assistant" }
        @{ Id = "SvcDPS"; Name = "Disable DPS"; Risk = "Low"; Category = "Services"; CommandOn = "Set-Service -Name DPS -StartupType Disabled"; CommandOff = "Set-Service -Name DPS -StartupType Automatic"; Description = "Disable Diagnostic Policy Service" }
        @{ Id = "SvcSpooler"; Name = "Disable Print Spooler"; Risk = "Low"; Category = "Services"; CommandOn = "Set-Service -Name Spooler -StartupType Disabled"; CommandOff = "Set-Service -Name Spooler -StartupType Automatic"; Description = "Disable if no printer used" }
        @{ Id = "SvcWSearch"; Name = "Disable Windows Search"; Risk = "Low"; Category = "Services"; CommandOn = "Set-Service -Name WSearch -StartupType Disabled"; CommandOff = "Set-Service -Name WSearch -StartupType Automatic"; Description = "Disable indexing (saves CPU/Disk)" }
        @{ Id = "SvcSysMain"; Name = "Disable SysMain (Superfetch)"; Risk = "Low"; Category = "Services"; CommandOn = "Set-Service -Name SysMain -StartupType Disabled"; CommandOff = "Set-Service -Name SysMain -StartupType Automatic"; Description = "Redundant on fast SSDs" }
        @{ Id = "SvcDiagTrack"; Name = "Disable DiagTrack"; Risk = "Low"; Category = "Services"; CommandOn = "Set-Service -Name DiagTrack -StartupType Disabled"; CommandOff = "Set-Service -Name DiagTrack -StartupType Automatic"; Description = "Disable Connected User Experiences" }
        
        # === BROWSER & MISC ===
        @{ Id = "ChromeTelemetry"; Name = "Chrome Telemetry"; Risk = "Low"; Category = "Privacy"; Path = "HKLM:\SOFTWARE\Policies\Google\Chrome"; Key = "MetricsReportingEnabled"; ValueOn = 0; ValueOff = 1; Description = "Disable Chrome reporting" }
        @{ Id = "EdgeTelemetry"; Name = "Edge Telemetry"; Risk = "Low"; Category = "Privacy"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Key = "MetricsReportingEnabled"; ValueOn = 0; ValueOff = 1; Description = "Disable Edge reporting" }
        @{ Id = "FirefoxTelemetry"; Name = "Firefox Telemetry"; Risk = "Low"; Category = "Privacy"; Path = "HKLM:\SOFTWARE\Policies\Mozilla\Firefox"; Key = "DisableTelemetry"; ValueOn = 1; ValueOff = 0; Description = "Disable Firefox reporting" }


        # === MODERN DEBLOAT (Safe & Reversible) ===
        @{ Id = "DebloatSolitaire"; Name = "Remove Solitaire"; Risk = "Low"; Category = "Debloat"; CommandOn = 'Get-AppxPackage *SolitaireCollection* | Remove-AppxPackage'; CommandOff = 'Get-AppxPackage -AllUsers *SolitaireCollection* | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register ''$($_.InstallLocation)\AppXManifest.xml''}'; Description = "Remove Solitaire Collection" }
        @{ Id = "DebloatBingNews"; Name = "Remove Bing News"; Risk = "Low"; Category = "Debloat"; CommandOn = 'Get-AppxPackage *BingNews* | Remove-AppxPackage'; CommandOff = 'Get-AppxPackage -AllUsers *BingNews* | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register ''$($_.InstallLocation)\AppXManifest.xml''}'; Description = "Remove News App" }
        @{ Id = "DebloatBingWeather"; Name = "Remove Bing Weather"; Risk = "Low"; Category = "Debloat"; CommandOn = 'Get-AppxPackage *BingWeather* | Remove-AppxPackage'; CommandOff = 'Get-AppxPackage -AllUsers *BingWeather* | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register ''$($_.InstallLocation)\AppXManifest.xml''}'; Description = "Remove Weather App" }
        @{ Id = "DebloatZuneVideo"; Name = "Remove Movies & TV"; Risk = "Low"; Category = "Debloat"; CommandOn = 'Get-AppxPackage *ZuneVideo* | Remove-AppxPackage'; CommandOff = 'Get-AppxPackage -AllUsers *ZuneVideo* | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register ''$($_.InstallLocation)\AppXManifest.xml''}'; Description = "Remove Legacy Video Player" }
        @{ Id = "DebloatZuneMusic"; Name = "Remove Groove Music"; Risk = "Low"; Category = "Debloat"; CommandOn = 'Get-AppxPackage *ZuneMusic* | Remove-AppxPackage'; CommandOff = 'Get-AppxPackage -AllUsers *ZuneMusic* | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register ''$($_.InstallLocation)\AppXManifest.xml''}'; Description = "Remove Legacy Music Player" }
        @{ Id = "DebloatPeople"; Name = "Remove People App"; Risk = "Low"; Category = "Debloat"; CommandOn = 'Get-AppxPackage *People* | Remove-AppxPackage'; CommandOff = 'Get-AppxPackage -AllUsers *People* | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register ''$($_.InstallLocation)\AppXManifest.xml''}'; Description = "Remove People Hub" }
        @{ Id = "DebloatMaps"; Name = "Remove Maps"; Risk = "Low"; Category = "Debloat"; CommandOn = 'Get-AppxPackage *WindowsMaps* | Remove-AppxPackage'; CommandOff = 'Get-AppxPackage -AllUsers *WindowsMaps* | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register ''$($_.InstallLocation)\AppXManifest.xml''}'; Description = "Remove Maps App" }
        @{ Id = "DebloatFeedback"; Name = "Remove Feedback Hub"; Risk = "Low"; Category = "Debloat"; CommandOn = 'Get-AppxPackage *WindowsFeedbackHub* | Remove-AppxPackage'; CommandOff = 'Get-AppxPackage -AllUsers *WindowsFeedbackHub* | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register ''$($_.InstallLocation)\AppXManifest.xml''}'; Description = "Remove Feedback Hub" }

        # === INTERFACE TWEAKS (Visuals) ===
        @{ Id = "VisAnim"; Name = "Disable Window Animations"; Risk = "Low"; Category = "UI"; Path = "HKCU:\Control Panel\Desktop\WindowMetrics"; Key = "MinAnimate"; ValueOn = 0; ValueOff = 1; Description = "Disable Min/Max animations" }
        @{ Id = "VisTrans"; Name = "Disable Transparency"; Risk = "Low"; Category = "UI"; Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"; Key = "EnableTransparency"; ValueOn = 0; ValueOff = 1; Description = "Disable Acrylic/Glass effects" }
        @{ Id = "VisShadows"; Name = "Disable Window Shadows"; Risk = "Low"; Category = "UI"; Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"; Key = "VisualFXSetting"; ValueOn = 2; ValueOff = 1; Description = "Optimize Visual FX for Performance" }
        @{ Id = "VisTips"; Name = "Disable Windows Tips"; Risk = "Low"; Category = "UI"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"; Key = "DisableSoftLanding"; ValueOn = 1; ValueOff = 0; Description = "Disable 'Welcome to Windows' tips" }
        @{ Id = "VisLock"; Name = "Disable Lock Screen Fun Facts"; Risk = "Low"; Category = "UI"; Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Key = "RotatingLockScreenOverlayEnabled"; ValueOn = 0; ValueOff = 1; Description = "Clean Lock Screen" }

        # === ADVANCED PRIVACY (Hardening) ===
        @{ Id = "PrivSearch"; Name = "Disable Web Search in Start"; Risk = "Low"; Category = "Privacy"; Path = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"; Key = "DisableSearchBoxSuggestions"; ValueOn = 1; ValueOff = 0; Description = "Local search only" }
        @{ Id = "PrivCloud"; Name = "Disable Cloud Content"; Risk = "Low"; Category = "Privacy"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"; Key = "DisableWindowsConsumerFeatures"; ValueOn = 1; ValueOff = 0; Description = "No suggested apps (Candy Crush)" }
        @{ Id = "PrivLoc"; Name = "Disable Location Support"; Risk = "Medium"; Category = "Privacy"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors"; Key = "DisableLocation"; ValueOn = 1; ValueOff = 0; Description = "Global location disable" }
        @{ Id = "PrivHandwrite"; Name = "Disable Handwriting Learning"; Risk = "Low"; Category = "Privacy"; Path = "HKCU:\Software\Microsoft\Input\Tip"; Key = "DisableInkAnalysis"; ValueOn = 1; ValueOff = 0; Description = "Prevent ink data collection" }
        @{ Id = "PrivAdvId"; Name = "Disable Advertising ID"; Risk = "Low"; Category = "Privacy"; Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"; Key = "Enabled"; ValueOn = 0; ValueOff = 1; Description = "Reset/Disable Ad ID" }

        # === 2025 POWER OPTIMIZATION ===
        @{ Id = "PwrThrottling"; Name = "Disable Global Power Throttling"; Risk = "Medium"; Category = "Power"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling"; Key = "PowerThrottlingOff"; ValueOn = 1; ValueOff = 0; Description = "Prevent background throttling" }
        @{ Id = "PwrSleep"; Name = "Disable Hibernate"; Risk = "Low"; Category = "Power"; CommandOn = "powercfg -h off"; CommandOff = "powercfg -h on"; Description = "Reclaim disk space (Hiberfil.sys)" }

        # === WINDOWS 11 24H2 SPECIFIC (NEW 2024-2025) ===
        @{ Id = "Win11Widgets"; Name = "Disable Widgets"; Risk = "Low"; Category = "UI"; Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Key = "TaskbarDa"; ValueOn = 0; ValueOff = 1; Description = "Hide Widgets from taskbar" }
        @{ Id = "Win11Phone"; Name = "Disable Phone Link Taskbar"; Risk = "Low"; Category = "UI"; Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Key = "TaskbarMn"; ValueOn = 0; ValueOff = 1; Description = "Hide Phone Link button" }
        @{ Id = "Win11Chat"; Name = "Disable Chat (Teams)"; Risk = "Low"; Category = "UI"; Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Key = "TaskbarDc"; ValueOn = 0; ValueOff = 1; Description = "Hide Teams Chat button" }
        @{ Id = "Win11DevHome"; Name = "Remove Dev Home"; Risk = "Low"; Category = "Debloat"; CommandOn = "Get-AppxPackage *DevHome* | Remove-AppxPackage -ErrorAction SilentlyContinue"; CommandOff = "winget install Microsoft.DevHome --accept-source-agreements --accept-package-agreements"; Description = "Remove Dev Home (24H2)" }
        @{ Id = "Win11SmartStandby"; Name = "Modern Standby Budget"; Risk = "Low"; Category = "Power"; CommandOn = "powercfg /setacvalueindex scheme_current sub_none STANDBYBUDGETPERCENT 100"; CommandOff = "powercfg /setacvalueindex scheme_current sub_none STANDBYBUDGETPERCENT 30"; Description = "Optimize Modern Standby" }
        @{ Id = "Win11SearchBox"; Name = "Compact Search Box"; Risk = "Low"; Category = "UI"; Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"; Key = "SearchboxTaskbarMode"; ValueOn = 1; ValueOff = 2; Description = "Minimize taskbar search" }

        # === NETWORK (RFC 9293+ Modern Standards) ===
        @{ Id = "NetECN"; Name = "ECN Capability"; Risk = "Low"; Category = "Network"; CommandOn = "netsh int tcp set global ecncapability=enabled"; CommandOff = "netsh int tcp set global ecncapability=disabled"; Description = "Explicit Congestion Notification" }
        @{ Id = "NetTimestamps"; Name = "TCP Timestamps"; Risk = "Low"; Category = "Network"; CommandOn = "netsh int tcp set global timestamps=enabled"; CommandOff = "netsh int tcp set global timestamps=disabled"; Description = "RFC 1323 timestamps" }
        @{ Id = "NetAutoTune"; Name = "Auto-Tuning Level"; Risk = "Low"; Category = "Network"; CommandOn = "netsh int tcp set global autotuninglevel=normal"; CommandOff = "netsh int tcp set global autotuninglevel=disabled"; Description = "Optimal receive window sizing" }
        @{ Id = "NetChimney"; Name = "Disable TCP Chimney"; Risk = "Low"; Category = "Network"; CommandOn = "netsh int tcp set global chimney=disabled"; CommandOff = "netsh int tcp set global chimney=enabled"; Description = "Better for modern NICs" }
        @{ Id = "NetDCA"; Name = "Enable DCA"; Risk = "Low"; Category = "Network"; CommandOn = "netsh int tcp set global dca=enabled"; CommandOff = "netsh int tcp set global dca=disabled"; Description = "Direct Cache Access" }

        # === ADVANCED PRIVACY (CIS/NSA Guidelines 2024) ===
        @{ Id = "PrivStartAds"; Name = "Disable Start Menu Ads"; Risk = "Low"; Category = "Privacy"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"; Key = "DisableWindowsSpotlightWindowsWelcomeExperience"; ValueOn = 1; ValueOff = 0; Description = "No ads in Start Menu" }
        @{ Id = "PrivDiagnostic"; Name = "Minimal Diagnostic Data"; Risk = "Low"; Category = "Privacy"; Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack"; Key = "ShowedToastAtLevel"; ValueOn = 1; ValueOff = 3; Description = "Security-only telemetry" }
        @{ Id = "PrivAppInstall"; Name = "Disable App Install Tracking"; Risk = "Low"; Category = "Privacy"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat"; Key = "DisableInventory"; ValueOn = 1; ValueOff = 0; Description = "No app inventory reporting" }
        @{ Id = "PrivSpeech"; Name = "Disable Online Speech"; Risk = "Low"; Category = "Privacy"; Path = "HKCU:\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy"; Key = "HasAccepted"; ValueOn = 0; ValueOff = 1; Description = "Disable cloud speech recognition" }
        @{ Id = "PrivTailored"; Name = "Disable Tailored Experiences"; Risk = "Low"; Category = "Privacy"; Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy"; Key = "TailoredExperiencesWithDiagnosticDataEnabled"; ValueOn = 0; ValueOff = 1; Description = "No personalized tips/ads" }
        @{ Id = "PrivSmartScreen"; Name = "SmartScreen for Apps Only"; Risk = "Medium"; Category = "Privacy"; Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"; Key = "SmartScreenEnabled"; ValueOn = 0; ValueOff = 1; Description = "Reduce cloud checks" }

        # === WINDOWS 10 LEGACY COMPATIBILITY ===
        @{ Id = "Win10Fast"; Name = "Disable Fast Startup"; Risk = "Low"; Category = "System"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"; Key = "HiberbootEnabled"; ValueOn = 0; ValueOff = 1; Description = "Clean boot (fixes driver issues)" }
        @{ Id = "Win10EdgeLegacy"; Name = "Disable Edge Legacy"; Risk = "Low"; Category = "Debloat"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Main"; Key = "AllowPrelaunch"; ValueOn = 0; ValueOff = 1; Description = "Prevent Edge preloading" }
        @{ Id = "Win10SecHealth"; Name = "Disable Security Center Notif"; Risk = "Low"; Category = "UI"; Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.SecurityAndMaintenance"; Key = "Enabled"; ValueOn = 0; ValueOff = 1; Description = "Reduce Security Center popups" }

        # === ADDITIONAL DEBLOAT (2024-2025) ===
        @{ Id = "DebloatOutlook"; Name = "Remove New Outlook"; Risk = "Low"; Category = "Debloat"; CommandOn = "Get-AppxPackage *OutlookForWindows* | Remove-AppxPackage -ErrorAction SilentlyContinue"; CommandOff = "winget install Microsoft.OutlookforWindows --accept-source-agreements"; Description = "Remove New Outlook (keep classic)" }
        @{ Id = "DebloatQuickAssist"; Name = "Remove Quick Assist"; Risk = "Low"; Category = "Debloat"; CommandOn = "Get-AppxPackage *QuickAssist* | Remove-AppxPackage -ErrorAction SilentlyContinue"; CommandOff = "winget install Microsoft.QuickAssist"; Description = "Remove Remote Assist" }
        @{ Id = "DebloatClipchamp"; Name = "Remove Clipchamp"; Risk = "Low"; Category = "Debloat"; CommandOn = "Get-AppxPackage *Clipchamp* | Remove-AppxPackage -ErrorAction SilentlyContinue"; CommandOff = "winget install Microsoft.Clipchamp"; Description = "Remove Clipchamp video editor" }
        @{ Id = "DebloatTodo"; Name = "Remove Microsoft Todo"; Risk = "Low"; Category = "Debloat"; CommandOn = "Get-AppxPackage *Todos* | Remove-AppxPackage -ErrorAction SilentlyContinue"; CommandOff = "winget install Microsoft.Todos"; Description = "Remove Todo app" }
        @{ Id = "DebloatFamily"; Name = "Remove Family Safety"; Risk = "Low"; Category = "Debloat"; CommandOn = "Get-AppxPackage *Family* | Remove-AppxPackage -ErrorAction SilentlyContinue"; CommandOff = "winget install Microsoft.FamilySafety"; Description = "Remove parental controls" }
    )
}

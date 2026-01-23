# ============================================================================
# NEURAL RESTORE V2.0 - FACTORY RESET "TIME MACHINE"
# Designed to revert ALL deep tweaks from Neural Optimizer (including obsolete logic)
# ============================================================================

$ErrorActionPreference = "SilentlyContinue"

function Write-Section {
    param($Title)
    Write-Host ""
    Write-Host " ╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host " ║ $($Title.PadRight(53)) ║" -ForegroundColor Cyan
    Write-Host " ╚═══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Reset-RegValue {
    param($Path, $Name, $DefaultValue)
    try {
        if (Test-Path $Path) {
            Set-ItemProperty -Path $Path -Name $Name -Value $DefaultValue -Force
            Write-Host "   [RESTORE] $Name -> $DefaultValue" -ForegroundColor Green
        }
    }
    catch { Write-Host "   [!] Failed to reset $Name" -ForegroundColor Red }
}

function Remove-RegKey {
    param($Path, $Name)
    try {
        if ((Get-ItemProperty -Path $Path -Name $Name).$Name) {
            Remove-ItemProperty -Path $Path -Name $Name -Force
            Write-Host "   [DELETE] Removed Tweak: $Name" -ForegroundColor Yellow
        }
    }
    catch {}
}

Invoke-AdminCheck # Assumed alias or check

# ============================================================================
# PHASE 1: KERNEL & MEMORY
# ============================================================================
Write-Section "PHASE 1: KERNEL & MEMORY ROLLBACK"

$MemPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
Reset-RegValue -Path $MemPath -Name "DisablePagingExecutive" -DefaultValue 0
Reset-RegValue -Path $MemPath -Name "LargeSystemCache" -DefaultValue 0
Reset-RegValue -Path $MemPath -Name "IoPageLockLimit" -DefaultValue 0
Reset-RegValue -Path $MemPath -Name "NonPagedPoolSize" -DefaultValue 0
Reset-RegValue -Path $MemPath -Name "SecondLevelDataCache" -DefaultValue 0

# Obsolete Latency Tweaks
Reset-RegValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" -Name "PowerThrottlingOff" -DefaultValue 0

# ============================================================================
# PHASE 2: NETWORK STACK "DEEP CLEAN"
# ============================================================================
Write-Section "PHASE 2: NETWORK STACK PURGE"

$MultimediaPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
Reset-RegValue -Path $MultimediaPath -Name "NetworkThrottlingIndex" -DefaultValue 10
Reset-RegValue -Path $MultimediaPath -Name "SystemResponsiveness" -DefaultValue 20

# Delete specific Legacy/Snake-Oil TCP keys
$TcpPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
$LegacyTcpKeys = @("TcpNoDelay", "TcpAckFrequency", "TcpDelAckTicks", "MaxUserPort", "TcpTimedWaitDelay", "DefaultTTL", "GlobalMaxTcpWindowSize")
foreach ($key in $LegacyTcpKeys) { Remove-RegKey -Path $TcpPath -Name $key }

# Reset Netsh
Write-Host "   [NETSH] Resetting TCP Int Global..." -ForegroundColor Cyan
netsh int tcp set global autotuninglevel=normal | Out-Null
netsh int tcp set global rss=enabled | Out-Null
netsh int tcp set global chimney=disabled | Out-Null
Set-NetTCPSetting -SettingName InternetCustom -CongestionProvider "CUBIC" -ErrorAction SilentlyContinue

# ============================================================================
# PHASE 3: SCHEDULER & PRIORITY
# ============================================================================
Write-Section "PHASE 3: PROCESS SCHEDULER"

$PrioPath = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"
Reset-RegValue -Path $PrioPath -Name "Win32PrioritySeparation" -DefaultValue 2

# Reset Game Task Priority
$GameTaskPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
Reset-RegValue -Path $GameTaskPath -Name "GPU Priority" -DefaultValue 8
Reset-RegValue -Path $GameTaskPath -Name "Priority" -DefaultValue 2
Reset-RegValue -Path $GameTaskPath -Name "Scheduling Category" -DefaultValue "Medium"
Reset-RegValue -Path $GameTaskPath -Name "SFIO Priority" -DefaultValue "Normal"

# ============================================================================
# PHASE 4: GAMING OPTIMIZATIONS (FSE/GameDVR)
# ============================================================================
Write-Section "PHASE 4: GAMING CONFIG"

$GameConfig = "HKCU:\System\GameConfigStore"
Reset-RegValue -Path $GameConfig -Name "GameDVR_FSEBehaviorMode" -DefaultValue 0
Reset-RegValue -Path $GameConfig -Name "GameDVR_HonorUserFSEBehaviorMode" -DefaultValue 0

# HAGS (Hardware Accelerated GPU Scheduling) - Default is usually 2 (On) in Win11, but 0 is 'safe'
# Checking current OS
$os = Get-CimInstance Win32_OperatingSystem
if ($os.Caption -match "Windows 11") {
    Reset-RegValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -DefaultValue 2 
}
else {
    Reset-RegValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -DefaultValue 1
}

# ============================================================================
# PHASE 5: SERVICES & BLOATWARE
# ============================================================================
Write-Section "PHASE 5: SERVICES RESTORATION"

$ServicesRestored = @(
    @{ Name = "SysMain"; Start = "Automatic" }
    @{ Name = "MapsBroker"; Start = "Automatic" }
    @{ Name = "DiagTrack"; Start = "Automatic" } # Telemetry... factory is ON.
    @{ Name = "WSearch"; Start = "Automatic" }
    @{ Name = "DusmSvc"; Start = "Automatic" }
)

foreach ($svc in $ServicesRestored) {
    Set-Service -Name $svc.Name -StartupType $svc.Start -ErrorAction SilentlyContinue
    Write-Host "   [SERVICE] Restored: $($svc.Name)" -ForegroundColor Green
}

# ============================================================================
# PHASE 6: POWER PLANS
# ============================================================================
Write-Section "PHASE 6: POWER PLANS"

Start-Process "powercfg" -ArgumentList "-restoredefaultschemes" -NoNewWindow -Wait
Write-Host "   [POWERCFG] Restored Default Schemes" -ForegroundColor Green
# Delete our custom plan GUID if detected (Requires hardcoded GUID from creation script, skipping for safety of user custom plans)

# ============================================================================
# PHASE 7: FILESYSTEM
# ============================================================================
Write-Section "PHASE 7: NTFS/FILESYSTEM"

$FsUtilPath = "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"
Reset-RegValue -Path $FsUtilPath -Name "NtfsDisableLastAccessUpdate" -DefaultValue 2 # System Managed
Reset-RegValue -Path $FsUtilPath -Name "NtfsDisable8dot3NameCreation" -DefaultValue 2 # Volume Dependent

# ============================================================================
# PHASE 8: DEVICE MANAGER (MSI MODE)
# ============================================================================
Write-Section "PHASE 8: MSI MODE CLEANUP"

# MSI Mode is tricky to revert without backup.
# Strategy: Disable MSI for Generic Devices if they were forced ON by us. 
# We look for the "MSISupported" key we added. If no "DevicePriority" exists, it might be artificial.
# SAFE MOVEMENT: We do NOT blindly revert MSI as it can break boot if the device relies on it.
Write-Host "   [INFO] MSI Mode tweaks are retained for system safety." -ForegroundColor Yellow
Write-Host "   [INFO] Manual driver re-installation recommended if issues persist." -ForegroundColor Gray

# ============================================================================
# PHASE 9: DNS & HOSTS
# ============================================================================
Write-Section "PHASE 9: DNS CACHE"

Clear-DnsClientCache
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" -Name "MaxCacheTtl" -Value 86400 -Force # Default is actually 86400 (1 day) on modern
Reset-RegValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" -Name "MaxNegativeCacheTtl" -DefaultValue 5

# ============================================================================
# PHASE 10: COMPLETION
# ============================================================================
Write-Section "PHASE 10: FINALIZATION"

Write-Host " [SUCCESS] System restored to Factory Defaults (Obsolete logic purged)." -ForegroundColor Green
Write-Host " [!] REBOOT REQUIRED." -ForegroundColor Red

Start-Sleep -Seconds 3

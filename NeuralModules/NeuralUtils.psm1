<#
.SYNOPSIS
    NeuralUtils Module v5.1 GLOBAL
    Core shared functions for Windows Neural Optimizer.

.DESCRIPTION
    Centralizes common logic:
    - Localization (NeuralLocalization)
    - Logging (Write-Log)
    - Admin Checks (Test-AdminPrivileges)
    - UI Helpers (Wait-ForKeyPress, Write-Section)
    - Registry Helpers (Set-RegistryKey)
    - File Ops (Remove-FolderSafe)
    - Performance Timing (Start/Stop-PerformanceTimer)
    - Reporting (Get-PerformanceReport)
    - Rollback (Invoke-Rollback)
    - Hardware Info (Show-HardwareInfo)

.NOTES
    Part of Windows Neural Optimizer v5.0 ULTRA
    Creditos: Jose Bustamante
#>
# ============================================================================
# IMPORTS
# ============================================================================
$Script:ModulePath = Split-Path $MyInvocation.MyCommand.Path -Parent
Import-Module "$Script:ModulePath\NeuralLocalization.psm1" -Force -DisableNameChecking

# ============================================================================
# LOGGING SYSTEM
# ============================================================================

enum LogLevel {
    Info
    Success
    Warning
    Error
}

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)][string]$Message,
        [Parameter(Position = 1)][LogLevel]$Level = [LogLevel]::Info,
        [string]$LogPath
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $prefix = switch ($Level) {
        'Info' { "INFO" }
        'Success' { " OK " }
        'Warning' { "WARN" }
        'Error' { "ERR " }
    }
    
    $logEntry = "[$timestamp][$prefix] $Message"
    
    # Write to file if path provided
    if (-not [string]::IsNullOrEmpty($LogPath)) {
        try {
            Add-Content -Path $LogPath -Value $logEntry -Encoding UTF8 -ErrorAction SilentlyContinue
        }
        catch {}
    }
    
    # Write to Console
    $color = switch ($Level) {
        'Info' { 'Gray' }
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
    }
    Write-Host " $Message" -ForegroundColor $color
}

# ============================================================================
# ADMIN & SECURITY
# ============================================================================

function Test-AdminPrivileges {
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]$identity
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch { return $false }
}

function Invoke-AdminCheck {
    param([switch]$Silent)
    
    # Simple check if running as admin
    if (Test-AdminPrivileges) { return }

    if (-not $Silent) {
        Write-Host ""
        Write-Host " +========================================================+" -ForegroundColor Yellow
        Write-Host " |  [!] $(Msg 'Utils.Admin.Title'.PadRight(50).Substring(0,50))|" -ForegroundColor Yellow
        Write-Host " +========================================================+" -ForegroundColor Yellow
        Write-Host ""
        Write-Host " [i] $(Msg 'Utils.Admin.Request')" -ForegroundColor Cyan
    }

    try {
        Write-Host " [X] $(Msg 'Utils.Admin.Error')" -ForegroundColor Red
        Wait-ForKeyPress
        exit 1
    }
    catch {
        exit 1
    }
}

# ... (Existing UI Helpers code in between, skipping for brevity in replacement if contiguous is preferred, but I'll assume I need to jump to next function or use separate calls. I will use separate calls to avoid replacing too much)
# Better to do this in chunks for safety. I'll split this into multiple chunks or just replace Invoke-AdminCheck first.


# ============================================================================
# UI HELPERS
# ============================================================================

function Wait-ForKeyPress {
    param([string]$Message)
    
    if (-not $Message) {
        $Message = Msg "Common.Continue"
    }

    Write-Host ""
    Write-Host " $Message" -ForegroundColor DarkGray
    try { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") }
    catch { Read-Host " Presione Enter" }
}

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host " +========================================================+" -ForegroundColor Cyan
    Write-Host " |  $($Title.PadRight(52).Substring(0,52))  |" -ForegroundColor Cyan
    Write-Host " +========================================================+" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step {
    param([string]$Message)
    Write-Host " $Message" -ForegroundColor Yellow
    Write-Host ""
}

# ============================================================================
# REGISTRY HELPERS
# ============================================================================

function Backup-RegistryKey {
    param(
        [string]$Path,
        [string]$Name
    )
    
    # Use $PSScriptRoot or fall back to module variable
    $root = if ($PSScriptRoot) { $PSScriptRoot } else { $Script:ModulePath }
    $backupDir = Join-Path $root "..\Backups"
    if (-not (Test-Path $backupDir)) { New-Item -Path $backupDir -ItemType Directory -Force | Out-Null }
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $safePath = $Path -replace ":", "" -replace "\\", "_"
    $backupFile = Join-Path $backupDir "RegBackup_${safePath}_${Name}_$timestamp.reg"
    
    try {
        # Export specific key logic or value dump
        # For granular rollback, we export the parent key
        # Using reg.exe for reliability with .reg format
        $regPath = $Path -replace "HKLM:", "HKLM" -replace "HKCU:", "HKCU"
        
        $process = Start-Process -FilePath "reg.exe" -ArgumentList "export `"$regPath`" `"$backupFile`" /y" -PassThru -NoNewWindow -Wait
        
        if ($process.ExitCode -eq 0) {
            Write-Log "Backup created: $backupFile" "Info"
        }
    }
    catch {
        Write-Log "Backup failed: $_" "Warning"
    }
}

function Set-RegistryKey {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)]$Value,
        [ValidateSet("DWord", "String", "QWord", "Binary", "MultiString", "ExpandString")]
        [string]$Type = "DWord",
        [string]$Desc,
        [switch]$SkipBackup
    )

    try {
        if (-not (Test-Path $Path)) { 
            New-Item -Path $Path -Force -ErrorAction SilentlyContinue | Out-Null 
            if (-not $SkipBackup) {
                # Note: Key didn't exist, so rollback would be "Delete Key"
                # For now we just log creation
            }
        }
        else {
            if (-not $SkipBackup) {
                Backup-RegistryKey -Path $Path -Name $Name
            }
        }
        
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction Stop
        
        if ($Desc) {
            Write-Host "   [OK] $Desc" -ForegroundColor Green
            return $true
        }
    }
    catch {
        if ($Desc) {
            Write-Host "   [!!] $Desc - Error: $_" -ForegroundColor Yellow
        }
        return $false
    }
    return $false
}

# ============================================================================
# FILE OPS
# ============================================================================

function Get-FolderSizeMB {
    param([string]$Path)
    try {
        if (Test-Path $Path) {
            $size = (Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue | 
                Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
            return [math]::Round($size / 1MB, 2)
        }
    }
    catch {}
    return 0
}

function Remove-FolderSafe {
    param(
        [string]$Path,
        [string]$Desc
    )

    $startSize = Get-FolderSizeMB -Path $Path

    try {
        if (Test-Path $Path) {
            Remove-Item -Path $Path -Recurse -Force -ErrorAction SilentlyContinue 
            
            if (Test-Path $Path) {
                Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue | 
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
    catch {}

    $endSize = Get-FolderSizeMB -Path $Path
    $freed = [math]::Max(0, $startSize - $endSize)

    if ($Desc) {
        if ($freed -gt 0.1) {
            Write-Host "   [OK] $Desc - $(Msg 'Utils.FS.Freed' $freed)" -ForegroundColor Green
        }
        else {
            Write-Host "   [--] $Desc" -ForegroundColor DarkGray
        }
    }
    
    return $freed
}

# ============================================================================
# OS COMPATIBILITY
# ============================================================================

function Get-WindowsVersion {
    <#
    .SYNOPSIS
    Detects Windows version (10 vs 11) and build number
    #>
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $build = [int]$os.BuildNumber
        
        $version = @{
            Name        = "Unknown"
            Build       = $build
            IsSupported = $false
        }
        
        if ($build -ge 22000) {
            $version.Name = "Windows 11"
            $version.IsSupported = $true
        }
        elseif ($build -ge 10240 -and $build -lt 22000) {
            $version.Name = "Windows 10"
            $version.IsSupported = $true
        }
        else {
            $version.Name = "Windows $($os.Version)"
            $version.IsSupported = $false
        }
        
        return $version
    }
    catch {
        return @{ Name = "Unknown"; Build = 0; IsSupported = $false }
    }
}

function Assert-SupportedOS {
    <#
    .SYNOPSIS
    Validates that Windows version is supported. Exits if not.
    #>
    $version = Get-WindowsVersion
    
    Write-Host " [i] Detected: $($version.Name) (Build $($version.Build))" -ForegroundColor Cyan
    
    if (-not $version.IsSupported) {
        Write-Host ""
        Write-Host " +========================================================+" -ForegroundColor Red
        Write-Host " |  ⚠️ UNSUPPORTED WINDOWS VERSION                        |" -ForegroundColor Red
        Write-Host " +========================================================+" -ForegroundColor Red
        Write-Host ""
        Write-Host " Neural Optimizer requires Windows 10 (Build 10240+) or Windows 11." -ForegroundColor Yellow
        Write-Host " Your version: $($version.Name) (Build $($version.Build))" -ForegroundColor Gray
        Write-Host ""
        Write-Host " Continuing may cause system instability." -ForegroundColor Red
        Write-Host ""
        
        $confirm = Read-Host " >> Continue anyway? (type 'I UNDERSTAND THE RISK')"
        if ($confirm -ne "I UNDERSTAND THE RISK") {
            Write-Host " [i] Exiting for safety..." -ForegroundColor Yellow
            exit 1
        }
    }
}

# ============================================================================
# HARDWARE & NETWORK UTILS
# ============================================================================

function Get-HardwareProfile {
    $hw = [PSCustomObject]@{
        IsSSD       = $false
        RamGB       = 0
        CpuVendor   = "Unknown"
        CpuCores    = 0
        CpuThreads  = 0
        CpuMaxSpeed = 0
        GpuVendor   = "Unknown"
        GpuName     = "Unknown"
        RamSpeed    = 0
    }

    # RAM
    try {
        $comp = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
        if ($comp) {
            $hw.RamGB = [math]::Round($comp.TotalPhysicalMemory / 1GB, 1)
        }
        $mem = Get-CimInstance Win32_PhysicalMemory -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($mem) {
            $hw.RamSpeed = $mem.Speed
        }
    }
    catch {}

    # CPU
    try {
        $cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($cpu) {
            if ($cpu.Name -match "Intel") { $hw.CpuVendor = "Intel" }
            elseif ($cpu.Name -match "AMD|Ryzen") { $hw.CpuVendor = "AMD" }
            $hw.CpuCores = $cpu.NumberOfCores
            $hw.CpuThreads = $cpu.NumberOfLogicalProcessors
            $hw.CpuMaxSpeed = $cpu.MaxClockSpeed
        }
    }
    catch {}
    
    # GPU
    try {
        $gpu = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($gpu) {
            $hw.GpuName = $gpu.Name
            if ($gpu.Name -match "NVIDIA") { $hw.GpuVendor = "NVIDIA" }
            elseif ($gpu.Name -match "AMD|Radeon") { $hw.GpuVendor = "AMD" }
            elseif ($gpu.Name -match "Intel") { $hw.GpuVendor = "Intel" }
        }
    }
    catch {}
    
    # SSD
    try {
        $driveLetter = ($env:SystemDrive -replace ':', '')
        $partition = Get-Partition -DriveLetter $driveLetter -ErrorAction SilentlyContinue
        $targetDisk = $null
        if ($partition) {
            $targetDisk = Get-PhysicalDisk | Where-Object { $_.DeviceId -eq $partition.DiskNumber } | Select-Object -First 1
        }
        if (-not $targetDisk) {
            $targetDisk = Get-PhysicalDisk | Where-Object { $_.DeviceId -eq 0 } | Select-Object -First 1
        }

        if ($targetDisk -and ($targetDisk.MediaType -match "SSD|Unspecified")) {
            $hw.IsSSD = $true
            # Simple NVMe check: usually bus type 17 is NVMe
            if ($targetDisk.BusType -eq 17) { $hw.IsNVMe = $true } else { $hw.IsNVMe = $false }
        }
    }
    catch {}
    
    return $hw
}

function Get-ActiveNetworkAdapter {
    try {
        $route = Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($route) {
            $ifIndex = $route.InterfaceIndex
            $nic = Get-NetAdapter | Where-Object { $_.InterfaceIndex -eq $ifIndex }
            return $nic
        }
    }
    catch {}
    return $null
}

# ============================================================================
# SYSTEM SAFETY & RECOVERY
# ============================================================================

function New-SystemRestorePoint {
    param([string]$Description = "Neural Optimizer Auto-Restore")
    
    Write-Section "SYSTEM SAFETY CHECK"
    
    # Check if we should skip asking via global config or parameter (future proofing)
    # For now, we always ask unless silent mode is implemented later
    
    Write-Host " [?] $(Msg 'Utils.Restore.Check')" -ForegroundColor Yellow
    $response = Read-Host " >> Crear Punto de Restauracion? / Create Restore Point? (Y/N)"
    
    if ($response -notmatch '^[Yy]') {
        Write-Host " [i] Restore Point creation skipped by user." -ForegroundColor Gray
        return $true # Treat as success to continue execution
    }
    
    try {
        if (-not (Test-AdminPrivileges)) {
            Write-Host " [!] $(Msg 'Common.AdminRequired')" -ForegroundColor Yellow
            return $false
        }

        # Check if System Restore is enabled for System Drive
        $sysDrive = $env:SystemDrive
        $status = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
        
        # Simple check: try to create
        Write-Host " [+] $(Msg 'Utils.Restore.Creating' $Description)" -ForegroundColor Cyan
        
        try {
            Checkpoint-Computer -Description $Description -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop | Out-Null
            Write-Host " [OK] $(Msg 'Utils.Restore.Success')" -ForegroundColor Green
            return $true
        }
        catch {
            $err = $_.Exception.Message
            Write-Host " [!] $(Msg 'Utils.Restore.Fail')" -ForegroundColor Red
            Write-Host "     Error: $err" -ForegroundColor Gray
            
            if ($err -match "disabled") {
                Write-Host "     [TIP] System Protection might be disabled on drive C:" -ForegroundColor Yellow
                Write-Host "     [TIP] Configure System Restore in Windows Settings." -ForegroundColor Yellow
            }
            elseif ($err -match "frequency") {
                Write-Host "     [TIP] A restore point was likely created recently (24h limit)." -ForegroundColor Yellow
            }
            
            # Ask to continue despite error
            $cont = Read-Host " >> Continue without Restore Point? (Y/N)"
            if ($cont -match '^[Yy]') { return $true }
            return $false
        }
    }
    catch {
        Write-Host " [!] Critical Error in Restore Point system: $_" -ForegroundColor Red
        return $false
    }
}

function Invoke-Rollback {
    Write-Section "SYSTEM RESTORE ROLLBACK"
    
    try {
        $points = Get-ComputerRestorePoint -ErrorAction SilentlyContinue | Sort-Object CreationTime -Descending
        
        if (-not $points) {
            Write-Host " [!] $(Msg 'Utils.Rollback.NoPoints')" -ForegroundColor Red
            return
        }
        
        Write-Host " $(Msg 'Utils.Rollback.Recent')" -ForegroundColor Cyan
        Write-Host ""
        
        $i = 1
        foreach ($p in $points) {
            Write-Host " $i. [$($p.CreationTime)] $($p.Description)" -ForegroundColor White
            $i++
            if ($i -gt 5) { break }
        }
        
        Write-Host ""
        $choice = Read-Host " >> $(Msg 'Utils.Rollback.Select')"
        
        if ($choice -match '^\d+$' -and $choice -gt 0 -and $choice -le $points.Count) {
            $selected = $points[$choice - 1]
            Write-Host ""
            Write-Host " [!] $(Msg 'Utils.Rollback.Warning' $selected.Description)" -ForegroundColor Yellow
            $confirm = Read-Host " >> $(Msg 'Utils.Rollback.Confirm')"
            
            if ($confirm -match '^[SsYy]') {
                # Check S or Y for ES/EN support
                Restore-Computer -RestorePoint $selected -Confirm:$false
            }
        }
    }
    catch {
        Write-Host " [!] Error en rollback: $_" -ForegroundColor Red
    }
}

# ============================================================================
# PERFORMANCE & TIMING
# ============================================================================

$Script:PerformanceTimers = @{}

function Start-PerformanceTimer {
    param([string]$Name)
    $Script:PerformanceTimers[$Name] = Get-Date
}

function Stop-PerformanceTimer {
    param([string]$Name)
    if ($Script:PerformanceTimers.ContainsKey($Name)) {
        $start = $Script:PerformanceTimers[$Name]
        $elapsed = ((Get-Date) - $start).TotalSeconds
        $Script:PerformanceTimers.Remove($Name)
        return $elapsed
    }
    return 0
}

function Get-PerformanceReport {
    Write-Section "PERFORMANCE REPORT"
    
    $historyLog = Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) "..\Neural_History.log"
    
    if (Test-Path $historyLog) {
        $lines = Get-Content $historyLog -Tail 20
        Write-Host " $(Msg 'Utils.Hw.Recent')" -ForegroundColor Cyan
        foreach ($line in $lines) {
            if ($line -match "ERROR") {
                Write-Host " $line" -ForegroundColor Red
            }
            elseif ($line -match "OK|Success") {
                Write-Host " $line" -ForegroundColor Green
            }
            else {
                Write-Host " $line" -ForegroundColor Gray
            }
        }
    }
    else {
        Write-Host " $(Msg 'Utils.Hw.NoHistory')" -ForegroundColor Gray
    }
    
    Write-Host ""
}

function Show-HardwareInfo {
    $hw = Get-HardwareProfile
    Write-Section "HARDWARE PROFILE"
    
    Write-Host " CPU:     $($hw.CpuVendor) Core ($($hw.CpuCores)C/$($hw.CpuThreads)T)" -ForegroundColor White
    Write-Host " Speed:   $($hw.CpuMaxSpeed) MHz" -ForegroundColor Gray
    Write-Host " RAM:     $($hw.RamGB) GB @ $($hw.RamSpeed) MHz" -ForegroundColor White
    Write-Host " GPU:     $($hw.GpuName) ($($hw.GpuVendor))" -ForegroundColor White
    
    $storageType = if ($hw.IsNVMe) { "NVMe" }elseif ($hw.IsSSD) { "SSD" }else { "HDD" }
    Write-Host " $(Msg 'Utils.Hw.Storage' $storageType)" -ForegroundColor White
    
    Write-Host ""
    
    $nic = Get-ActiveNetworkAdapter
    if ($nic) {
        Write-Host " $(Msg 'Utils.Hw.Network' $nic.Name)" -ForegroundColor White
        Write-Host " $(Msg 'Utils.Hw.Speed' $nic.LinkSpeed)" -ForegroundColor Gray
    }
    
    Write-Host ""
}

# ============================================================================
# CONFIGURATION SYSTEM
# ============================================================================

$Script:ConfigPath = Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) "..\NeuralConfig.json"

function Get-NeuralConfig {
    if (Test-Path $Script:ConfigPath) {
        try {
            $json = Get-Content $Script:ConfigPath -Raw
            return ConvertFrom-Json $json
        }
        catch {
            Write-Log "ERROR" "Failed to load config: $_"
            return $null
        }
    }
    return $null
}

function Set-NeuralConfig {
    param(
        [string]$Key,
        [string]$Value
    )
    
    $config = @{}
    if (Test-Path $Script:ConfigPath) {
        try {
            $existing = Get-Content $Script:ConfigPath -Raw | ConvertFrom-Json
            # Convert PSCustomObject to Hashtable for modification
            if ($existing) {
                $existing.PSObject.Properties | ForEach-Object { $config[$_.Name] = $_.Value }
            }
        }
        catch {
            Write-Log "WARN" "Config corrupted, resetting."
        }
    }
    
    $config[$Key] = $Value
    
    try {
        $config | ConvertTo-Json | Set-Content $Script:ConfigPath
        Write-Log "Config updated: $Key = $Value" "Info"
    }
    catch {
        Write-Log "Failed to save config: $_" "Error"
    }
}

Export-ModuleMember -Function Write-Log, Test-AdminPrivileges, Invoke-AdminCheck, Wait-ForKeyPress, Write-Section, Write-Step, Set-RegistryKey, Remove-FolderSafe, Get-HardwareProfile, Get-ActiveNetworkAdapter, New-SystemRestorePoint, Start-PerformanceTimer, Stop-PerformanceTimer, Get-PerformanceReport, Invoke-Rollback, Show-HardwareInfo, Get-WindowsVersion, Assert-SupportedOS, Get-NeuralConfig, Set-NeuralConfig


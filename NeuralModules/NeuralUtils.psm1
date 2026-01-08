<#
.SYNOPSIS
    NeuralUtils Module v5.0 ULTRA
    Core shared functions for Windows Neural Optimizer.

.DESCRIPTION
    Centralizes common logic:
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
        Write-Host " |  [!] SE REQUIEREN PERMISOS DE ADMINISTRADOR            |" -ForegroundColor Yellow
        Write-Host " +========================================================+" -ForegroundColor Yellow
        Write-Host ""
        Write-Host " [i] Solicitando permisos de administrador..." -ForegroundColor Cyan
    }

    try {
        Write-Host " [X] ERROR: Reinicie como Administrador." -ForegroundColor Red
        Wait-ForKeyPress
        exit 1
    }
    catch {
        exit 1
    }
}

# ============================================================================
# UI HELPERS
# ============================================================================

function Wait-ForKeyPress {
    param([string]$Message = "Presione cualquier tecla para continuar...")
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

function Set-RegistryKey {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)]$Value,
        [ValidateSet("DWord", "String", "QWord", "Binary", "MultiString", "ExpandString")]
        [string]$Type = "DWord",
        [string]$Desc
    )

    try {
        if (-not (Test-Path $Path)) { 
            New-Item -Path $Path -Force -ErrorAction SilentlyContinue | Out-Null 
        }
        
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction Stop
        
        if ($Desc) {
            Write-Host "   [OK] $Desc" -ForegroundColor Green
            return $true
        }
    }
    catch {
        if ($Desc) {
            Write-Host "   [!!] $Desc" -ForegroundColor Yellow
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
            Write-Host "   [OK] $Desc - Liberado: $freed MB" -ForegroundColor Green
        }
        else {
            Write-Host "   [--] $Desc" -ForegroundColor DarkGray
        }
    }
    
    return $freed
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
    Write-Host " [i] Verificando Sistema de Restauracion..." -ForegroundColor Cyan
    
    try {
        $null = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
        
        if (-not (Test-AdminPrivileges)) {
            Write-Host " [!] Se requieren permisos de Admin." -ForegroundColor Yellow
            return $false
        }

        Write-Host " [+] Creando Punto de Restauracion: '$Description'..." -ForegroundColor Cyan
        Checkpoint-Computer -Description $Description -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop | Out-Null
        
        Write-Host " [OK] Punto de Restauracion Creado Exitosamente." -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host " [!] No se pudo crear el Punto de Restauracion." -ForegroundColor Red
        return $false
    }
}

function Invoke-Rollback {
    Write-Section "SYSTEM RESTORE ROLLBACK"
    
    try {
        $points = Get-ComputerRestorePoint -ErrorAction SilentlyContinue | Sort-Object CreationTime -Descending
        
        if (-not $points) {
            Write-Host " [!] No hay puntos de restauración disponibles." -ForegroundColor Red
            return
        }
        
        Write-Host " Puntos de restauración recientes:" -ForegroundColor Cyan
        Write-Host ""
        
        $i = 1
        foreach ($p in $points) {
            Write-Host " $i. [$($p.CreationTime)] $($p.Description)" -ForegroundColor White
            $i++
            if ($i -gt 5) { break }
        }
        
        Write-Host ""
        $choice = Read-Host " >> Seleccione número para restaurar (0 para cancelar)"
        
        if ($choice -match '^\d+$' -and $choice -gt 0 -and $choice -le $points.Count) {
            $selected = $points[$choice - 1]
            Write-Host ""
            Write-Host " [!] ADVERTENCIA: El sistema se reiniciará para restaurar: $($selected.Description)" -ForegroundColor Yellow
            $confirm = Read-Host " >> ¿Continuar? (S/N)"
            
            if ($confirm -match '^[Ss]') {
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
        Write-Host " Actividad reciente:" -ForegroundColor Cyan
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
        Write-Host " No hay historial disponible." -ForegroundColor Gray
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
    Write-Host " Storage: $(if($hw.IsNVMe){"NVMe"}elseif($hw.IsSSD){"SSD"}else{"HDD"})" -ForegroundColor White
    
    Write-Host ""
    
    $nic = Get-ActiveNetworkAdapter
    if ($nic) {
        Write-Host " Network: $($nic.Name)" -ForegroundColor White
        Write-Host " Speed:   $($nic.LinkSpeed)" -ForegroundColor Gray
    }
    
    Write-Host ""
}

Export-ModuleMember -Function Write-Log, Test-AdminPrivileges, Invoke-AdminCheck, Wait-ForKeyPress, Write-Section, Write-Step, Set-RegistryKey, Remove-FolderSafe, Get-HardwareProfile, Get-ActiveNetworkAdapter, New-SystemRestorePoint, Start-PerformanceTimer, Stop-PerformanceTimer, Get-PerformanceReport, Invoke-Rollback, Show-HardwareInfo

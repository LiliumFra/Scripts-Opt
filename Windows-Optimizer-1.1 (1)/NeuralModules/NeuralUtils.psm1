<#
.SYNOPSIS
    NeuralUtils Module v3.5
    Core shared functions for Windows Neural Optimizer.

.DESCRIPTION
    Centralizes common logic:
    - Logging (Write-Log)
    - Admin Checks (Test-AdminPrivileges)
    - UI Helpers (Wait-ForKeyPress, Write-Section)
    - Registry Helpers (Set-RegistryKey)
    - File Ops (Remove-FolderSafe)

.NOTES
    Part of Windows Neural Optimizer v3.5
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
        # Script path logic removed (unused)
        # Relaunch logic is handled by caller usually or simple restart here
        # But usually better to let the script handle the restart arguments (like -SkipRestore)
        # For modules, we just exit if not admin.
        
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
            # Write-Host "        $($_.Exception.Message)" -ForegroundColor DarkGray
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
            # Try fast removal first
            Remove-Item -Path $Path -Recurse -Force -ErrorAction SilentlyContinue 
            
            # If still exists (partial), try child items
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
        IsSSD     = $false
        RamGB     = 0
        CpuVendor = "Unknown"
    }

    # RAM
    try {
        $comp = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
        if ($comp) {
            $hw.RamGB = [math]::Round($comp.TotalPhysicalMemory / 1GB, 1)
        }
    }
    catch {}

    # CPU
    try {
        $cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($cpu) {
            if ($cpu.Name -match "Intel") { $hw.CpuVendor = "Intel" }
            elseif ($cpu.Name -match "AMD|Ryzen") { $hw.CpuVendor = "AMD" }
        }
    }
    catch {}
    
    # SSD (Smart System Drive Detection)
    try {
        # Try to find the physical disk hosting the OS (C:)
        $driveLetter = ($env:SystemDrive -replace ':', '')
        $partition = Get-Partition -DriveLetter $driveLetter -ErrorAction SilentlyContinue
        
        $targetDisk = $null
        
        if ($partition) {
            $targetDisk = Get-PhysicalDisk | Where-Object { $_.DeviceId -eq $partition.DiskNumber } | Select-Object -First 1
        }
        
        # Fallback to Disk 0 if logic fails
        if (-not $targetDisk) {
            $targetDisk = Get-PhysicalDisk | Where-Object { $_.DeviceId -eq 0 } | Select-Object -First 1
        }

        if ($targetDisk -and ($targetDisk.MediaType -match "SSD|Unspecified")) {
            $hw.IsSSD = $true
        }
    }
    catch {}
    
    return $hw
}

function Get-ActiveNetworkAdapter {
    try {
        # Get adapter with default gateway (internet access)
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
        # Check if System Restore is enabled
        $null = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
        
        # Check privileges again just in case (needs admin)
        if (-not (Test-AdminPrivileges)) {
            Write-Host " [!] Se requieren permisos de Admin para crear punto de restauracion." -ForegroundColor Yellow
            return $false
        }

        # Attempt creation
        Write-Host " [+] Creando Punto de Restauracion: '$Description'..." -ForegroundColor Cyan
        Checkpoint-Computer -Description $Description -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop | Out-Null
        
        Write-Host " [OK] Punto de Restauracion Creado Exitosamente." -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host " [!] No se pudo crear el Punto de Restauracion." -ForegroundColor Red
        Write-Host "     Posible causa: La proteccion del sistema esta deshabilitada o frecuencia limitada." -ForegroundColor DarkGray
        Write-Host "     Error: $($_.Exception.Message)" -ForegroundColor DarkGray
        
        # Optional: Ask user if they want to enable it? (Maybe too intrusive for utility, keeping it simple)
        return $false
    }
}

Export-ModuleMember -Function Write-Log, Test-AdminPrivileges, Invoke-AdminCheck, Wait-ForKeyPress, Write-Section, Write-Step, Set-RegistryKey, Remove-FolderSafe, Get-HardwareProfile, Get-ActiveNetworkAdapter, New-SystemRestorePoint

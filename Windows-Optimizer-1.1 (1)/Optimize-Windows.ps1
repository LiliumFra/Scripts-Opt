<#
.SYNOPSIS
    WINDOWS NEURAL OPTIMIZER v3.5
    Controlador Maestro - Unifica optimizaciones de arranque, debloat y disco.

.DESCRIPTION
    Sistema modular de optimización de Windows con:
    - Auto-elevación a administrador (via Utils)
    - Puntos de restauración automáticos
    - Logging detallado (Utils)
    - Validación de módulos
    - Manejo robusto de errores

.NOTES
    Versión: 3.5 NEURAL
    Requiere: PowerShell 5.1+, Permisos de Administrador
#>

#Requires -Version 5.1

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$SkipRestore,
    [switch]$Silent
)

$ErrorActionPreference = "Stop"
$Script:Version = "3.5 NEURAL"
$Script:ScriptDir = $PSScriptRoot
$Script:ModuleDir = Join-Path -Path $Script:ScriptDir -ChildPath "NeuralModules"
$Script:LogFile = Join-Path -Path $Script:ScriptDir -ChildPath "Neural_History.log"
$Script:UtilsPath = Join-Path -Path $Script:ModuleDir -ChildPath "NeuralUtils.psm1"

# ============================================================================
# BOOTSTRAP UTILS
# ============================================================================

if (-not (Test-Path $Script:UtilsPath)) {
    Write-Host " [FATAL] No se encuentra NeuralUtils.psm1 en $Script:ModuleDir" -ForegroundColor Red
    exit 1
}

Import-Module $Script:UtilsPath -Force -DisableNameChecking

# ============================================================================
# AUTO-ELEVACIÓN
# ============================================================================

if (-not (Test-AdminPrivileges)) {
    if (-not $Silent) {
        Write-Host ""
        Write-Host " +========================================================+" -ForegroundColor Yellow
        Write-Host " |  [!] SE REQUIEREN PERMISOS DE ADMINISTRADOR            |" -ForegroundColor Yellow
        Write-Host " +========================================================+" -ForegroundColor Yellow
        Write-Host ""
        Write-Host " [i] Solicitando permisos de administrador..." -ForegroundColor Cyan
    }
    
    try {
        $scriptPath = if ($MyInvocation.MyCommand.Path) { $MyInvocation.MyCommand.Path } else { $PSCommandPath }
        $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
        if ($SkipRestore) { $arguments += " -SkipRestore" }
        if ($Silent) { $arguments += " -Silent" }
        
        Start-Process -FilePath "powershell.exe" -ArgumentList $arguments -Verb RunAs -Wait
        exit 0
    }
    catch {
        Write-Host ' [X] ERROR: No se pudieron obtener permisos.' -ForegroundColor Red
        Wait-ForKeyPress
        exit 1
    }
}

# ============================================================================
# SAFETY SYSTEM
# ============================================================================

# ============================================================================
# SAFETY SYSTEM
# ============================================================================

# Restore Point Logic is now handled by NeuralUtils

# ============================================================================
# MODULE SYSTEM
# ============================================================================

function Test-ModulesExist {
    [CmdletBinding()]
    [OutputType([bool])]
    param()
    
    $requiredModules = @(
        "Boot-Optimization.ps1",
        "Debloat-Suite.ps1",
        "Disk-Hygiene.ps1",
        "Gaming-Optimization.ps1",
        "NeuralUtils.psm1"
    )
    
    $allExist = $true
    
    foreach ($module in $requiredModules) {
        $modulePath = Join-Path -Path $Script:ModuleDir -ChildPath $module
        if (-not (Test-Path -Path $modulePath -PathType Leaf)) {
            Write-Log "Modulo no encontrado: $module" -Level Error -LogPath $Script:LogFile
            $allExist = $false
        }
    }
    
    return $allExist
}

function Invoke-OptimizationModule {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        
        [Parameter(Mandatory)]
        [string]$ScriptPath
    )
    
    Write-Host "------------------------------------------------" -ForegroundColor Gray
    Write-Log "EJECUTANDO MODULO: $Name" -Level Info -LogPath $Script:LogFile
    
    if (-not (Test-Path -Path $ScriptPath -PathType Leaf)) {
        Write-Log "Error: No se encuentra el archivo $ScriptPath" -Level Error -LogPath $Script:LogFile
        return $false
    }
    
    if ($PSCmdlet.ShouldProcess($Name, "Ejecutar modulo de optimizacion")) {
        try {
            $startTime = Get-Date
            . $ScriptPath
            $elapsed = (Get-Date) - $startTime
            
            Write-Log "Modulo $Name finalizado en $([int]$elapsed.TotalSeconds)s" -Level Success -LogPath $Script:LogFile
            return $true
        }
        catch {
            Write-Log "ERROR en $Name : $($_.Exception.Message)" -Level Error -LogPath $Script:LogFile
            Write-Log "Stack: $($_.ScriptStackTrace)" -Level Error -LogPath $Script:LogFile
            return $false
        }
    }
    
    return $true
}

# ============================================================================
# USER INTERFACE
# ============================================================================

function Show-Banner {
    Clear-Host
    Write-Host ''
    Write-Host '   =============================================' -ForegroundColor Cyan
    Write-Host '          NEURAL OPTIMIZER' -ForegroundColor Cyan
    Write-Host "       Windows System Tweaker v$Script:Version" -ForegroundColor Cyan
    Write-Host '   =============================================' -ForegroundColor Cyan
    Write-Host ''
    Write-Host " [ LOGGING: $Script:LogFile ]" -ForegroundColor DarkGray
    Write-Host ''
}

function Show-Menu {
    Write-Host ' +-------------------------------------------------+' -ForegroundColor Gray
    Write-Host ' | 1. [BOOT]    Optimizar Arranque (BCD + NTFS)    |' -ForegroundColor White
    Write-Host ' | 2. [DEBLOAT] Eliminar Apps + Privacidad         |' -ForegroundColor White
    Write-Host ' | 3. [DISK]    Limpieza + Red                     |' -ForegroundColor White
    Write-Host ' | 4. [GAMING]  Optimizar para Juegos              |' -ForegroundColor White
    Write-Host ' | 5. [CACHE]   Neural Cache Diagnostic            |' -ForegroundColor White
    Write-Host ' | 6. [ALL]     EJECUTAR TODO (Recomendado)        |' -ForegroundColor Cyan
    Write-Host ' | 8. [THERMAL] Optimizar Ventiladores (Thermal)  |' -ForegroundColor White
    Write-Host ' | 7. Salir                                        |' -ForegroundColor DarkGray
    Write-Host ' +-------------------------------------------------+' -ForegroundColor Gray
    Write-Host ''
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

trap {
    Write-Log "ERROR FATAL: $($_.Exception.Message)" -Level Error -LogPath $Script:LogFile
    Write-Log "Ubicacion: $($_.InvocationInfo.ScriptName):$($_.InvocationInfo.ScriptLineNumber)" -Level Error -LogPath $Script:LogFile
    Wait-ForKeyPress -Message "Presione cualquier tecla para salir..."
    Stop-Transcript -ErrorAction SilentlyContinue
    exit 1
}

# Initialize
Write-Log "=== INICIANDO NEURAL OPTIMIZER v$Script:Version ===" -Level Info -LogPath $Script:LogFile
Write-Log "Usuario: $env:USERNAME | Computadora: $env:COMPUTERNAME" -Level Info -LogPath $Script:LogFile
Write-Log "PowerShell: $($PSVersionTable.PSVersion) | OS: $([Environment]::OSVersion.VersionString)" -Level Info -LogPath $Script:LogFile

# Start detailed transcript
try { 
    $TranscriptFile = Join-Path -Path $Script:ScriptDir -ChildPath "Neural_Detailed.log"
    Start-Transcript -Path $TranscriptFile -Append -IncludeInvocationHeader -Force -ErrorAction SilentlyContinue | Out-Null
}
catch {}

# Validate modules exist
if (-not (Test-ModulesExist)) {
    Write-Host ""
    Write-Host " [X] ERROR: Faltan modulos requeridos en $Script:ModuleDir" -ForegroundColor Red
    Wait-ForKeyPress
    Stop-Transcript -ErrorAction SilentlyContinue
    exit 1
}

# Create restore point
if (-not $SkipRestore) {
    if (-not (New-SystemRestorePoint -Description "NeuralOptimize_v$Script:Version")) {
        $choice = Read-Host " >> Continuar SIN punto de restauracion? (SI/NO)"
        if ($choice -ne "SI") { Stop-Transcript -ErrorAction SilentlyContinue; exit }
    }
}

# Main menu loop
while ($true) {
    Show-Banner
    Show-Menu
    
    $selection = Read-Host " >> Seleccione una opcion"
    
    switch ($selection) {
        '1' {
            Invoke-OptimizationModule -Name "BOOT OPTIMIZER" -ScriptPath (Join-Path $Script:ModuleDir "Boot-Optimization.ps1")
            Wait-ForKeyPress
        }
        '2' {
            Invoke-OptimizationModule -Name "DEBLOAT SUITE" -ScriptPath (Join-Path $Script:ModuleDir "Debloat-Suite.ps1")
            Wait-ForKeyPress
        }
        '3' {
            Invoke-OptimizationModule -Name 'DISK AND NETWORK' -ScriptPath (Join-Path $Script:ModuleDir "Disk-Hygiene.ps1")
            Wait-ForKeyPress
        }
        '4' {
            Invoke-OptimizationModule -Name "GAMING OPTIMIZER" -ScriptPath (Join-Path $Script:ModuleDir "Gaming-Optimization.ps1")
            Wait-ForKeyPress
        }
        '5' {
            $ncPath = Join-Path (Split-Path $Script:ScriptDir -Parent) "NeuralCache-Diagnostic.ps1"
            if (Test-Path $ncPath) {
                Invoke-OptimizationModule -Name "NEURAL CACHE" -ScriptPath $ncPath
            }
            else {
                Write-Host " [!] NeuralCache-Diagnostic.ps1 no encontrado en $ncPath" -ForegroundColor Red
            }
            Wait-ForKeyPress
        }
        '6' {
            $startAll = Get-Date
            Write-Log "=== OPTIMIZACION COMPLETA INICIADA ===" -Level Info -LogPath $Script:LogFile
            
            $results = @{
                Boot    = Invoke-OptimizationModule -Name "BOOT OPTIMIZER" -ScriptPath (Join-Path $Script:ModuleDir "Boot-Optimization.ps1")
                Debloat = Invoke-OptimizationModule -Name "DEBLOAT SUITE" -ScriptPath (Join-Path $Script:ModuleDir "Debloat-Suite.ps1")
                Disk    = Invoke-OptimizationModule -Name 'DISK AND NETWORK' -ScriptPath (Join-Path $Script:ModuleDir "Disk-Hygiene.ps1")
                Gaming  = Invoke-OptimizationModule -Name "GAMING OPTIMIZER" -ScriptPath (Join-Path $Script:ModuleDir "Gaming-Optimization.ps1")
            }
            
            $totalTime = (Get-Date) - $startAll
            $successCount = ($results.Values | Where-Object { $_ -eq $true }).Count
            Write-Host ''
            Write-Host ' =================================================' -ForegroundColor Green
            Write-Host '   OPTIMIZACION COMPLETA FINALIZADA' -ForegroundColor Green
            Write-Host "   Modulos exitosos: $successCount/4" -ForegroundColor Green
            Write-Host "   Tiempo total: $([int]$totalTime.TotalSeconds) segundos" -ForegroundColor Green
            Write-Host ' =================================================' -ForegroundColor Green
            
            Write-Log "=== OPTIMIZACION COMPLETA: $successCount/4 modulos en $([int]$totalTime.TotalSeconds)s ===" -Level Success -LogPath $Script:LogFile
            Wait-ForKeyPress
        }
        '8' {
            Invoke-OptimizationModule -Name "THERMAL OPTIMIZATION" -ScriptPath (Join-Path $Script:ModuleDir "Thermal-Optimization.ps1")
            Wait-ForKeyPress
        }
        '7' {
            Write-Log "Usuario salio del programa." -Level Info -LogPath $Script:LogFile
            Stop-Transcript -ErrorAction SilentlyContinue
            exit 0
        }
        default {
            Write-Host " [!] Opcion no valida. Intente de nuevo." -ForegroundColor Yellow
            Start-Sleep -Seconds 1
        }
    }
}

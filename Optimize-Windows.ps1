<#
.SYNOPSIS
    WINDOWS NEURAL OPTIMIZER v5.0 ULTRA
    Controlador Maestro con módulos avanzados integrados.

.DESCRIPTION
    v5.0 ULTRA incluye:
    - Advanced Gaming (MSI, HPET, competitive network)
    - Advanced Memory (smart paging, pools, compression)
    - SSD/NVMe Optimizer (TRIM, power, health)
    - Profile System (presets para diferentes usos)
    - Todo de v4.0 mejorado

.NOTES
    Versión: 5.0 ULTRA
    Creditos: Jose Bustamante
    Requiere: PowerShell 5.1+, Administrador
#>

#Requires -Version 5.1

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$SkipRestore,
    [switch]$Silent,
    [switch]$AutoOptimize,
    [string]$ProfileName  # Para aplicar perfil automático
)

$ErrorActionPreference = "Stop"
$Script:Version = "5.0 ULTRA"
$Script:ScriptDir = $PSScriptRoot
$Script:ModuleDir = Join-Path -Path $Script:ScriptDir -ChildPath "NeuralModules"
$Script:LogFile = Join-Path -Path $Script:ScriptDir -ChildPath "Neural_History.log"
$Script:UtilsPath = Join-Path -Path $Script:ModuleDir -ChildPath "NeuralUtils.psm1"

# ============================================================================
# BOOTSTRAP
# ============================================================================

if (-not (Test-Path $Script:UtilsPath)) {
    Write-Host " [FATAL] NeuralUtils.psm1 no encontrado" -ForegroundColor Red
    exit 1
}

Import-Module $Script:UtilsPath -Force -DisableNameChecking
Import-Module "d:\josef\Documents\Scripts Opt\NeuralModules\NeuralLocalization.psm1" -Force -DisableNameChecking

# CRITICAL: Validate OS before proceeding
Assert-SupportedOS

# ============================================================================
# AUTO-ELEVACIÓN
# ============================================================================

if (-not (Test-AdminPrivileges)) {
    if (-not $Silent) {
        Write-Host ""
        Write-Host " ╔═══════════════════════════════════════════════════════╗" -ForegroundColor Yellow
        Write-Host " ║  ⚠️  SE REQUIEREN PERMISOS DE ADMINISTRADOR          ║" -ForegroundColor Yellow
        Write-Host " ╚═══════════════════════════════════════════════════════╝" -ForegroundColor Yellow
        Write-Host ""
    }
    
    try {
        $scriptPath = if ($MyInvocation.MyCommand.Path) { $MyInvocation.MyCommand.Path } else { $PSCommandPath }
        $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
        if ($SkipRestore) { $arguments += " -SkipRestore" }
        if ($Silent) { $arguments += " -Silent" }
        if ($AutoOptimize) { $arguments += " -AutoOptimize" }
        if ($ProfileName) { $arguments += " -ProfileName `"$ProfileName`"" }
        
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
# MODULE VALIDATION
# ============================================================================

function Test-ModulesExist {
    [CmdletBinding()]
    [OutputType([bool])]
    param()
    
    $requiredModules = @(
        "NeuralUtils.psm1",
        "Boot-Optimization.ps1",
        "Debloat-Suite.ps1",
        "Disk-Hygiene.ps1",
        "Gaming-Optimization.ps1",
        "Thermal-Optimization.ps1",
        "System-Monitor.ps1",
        "Benchmark-Suite.ps1",
        "Health-Check.ps1",
        "Advanced-Gaming.ps1",
        "Advanced-Memory.ps1",
        "SSD-NVMe-Optimizer.ps1",
        "Profile-System.ps1",
        "AI-Recommendations.ps1",
        "ML-Usage-Patterns.ps1",
        "Per-Game-Profiles.ps1",
        "Network-Optimizer.ps1",
        "Service-Manager.ps1",
        "Privacy-Guardian.ps1",
        "Visual-FX.ps1",
        "Advanced-Registry.ps1",
        "Update-System.ps1"
    )
    
    $allExist = $true
    $missing = @()
    
    foreach ($module in $requiredModules) {
        $modulePath = Join-Path -Path $Script:ModuleDir -ChildPath $module
        if (-not (Test-Path -Path $modulePath -PathType Leaf)) {
            $allExist = $false
            $missing += $module
        }
    }
    
    if (-not $allExist) {
        Write-Host ""
        Write-Host " [!] Módulos faltantes:" -ForegroundColor Red
        foreach ($m in $missing) {
            Write-Host "     - $m" -ForegroundColor Yellow
        }
        Write-Host ""
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
    
    Write-Host ""
    Write-Host " ════════════════════════════════════════════════════════" -ForegroundColor Gray
    Write-Log "EJECUTANDO: $Name" -Level Info -LogPath $Script:LogFile
    
    if (-not (Test-Path -Path $ScriptPath -PathType Leaf)) {
        Write-Log "ERROR: Módulo no encontrado: $ScriptPath" -Level Error -LogPath $Script:LogFile
        return $false
    }
    
    if ($PSCmdlet.ShouldProcess($Name, "Ejecutar módulo")) {
        try {
            Start-PerformanceTimer -Name $Name
            . $ScriptPath
            $elapsed = Stop-PerformanceTimer -Name $Name
            
            Write-Log "✓ $Name completado en $([math]::Round($elapsed, 2))s" -Level Success -LogPath $Script:LogFile
            return $true
        }
        catch {
            Write-Log "✗ ERROR en $Name : $($_.Exception.Message)" -Level Error -LogPath $Script:LogFile
            return $false
        }
    }
    
    return $true
}

# ============================================================================
# UI
# ============================================================================

function Show-Banner {
    Clear-Host
    
    $hw = Get-HardwareProfile
    
    Write-Host ""
    Write-Host " +=================================================================+" -ForegroundColor Cyan
    Write-Host " |             $(Msg 'Menu.Title')             |" -ForegroundColor Cyan
    Write-Host " +=================================================================+" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " System: $($hw.CpuVendor) | RAM: $($hw.RamGB)GB | GPU: $($hw.GpuName)" -ForegroundColor DarkGray
    Write-Host " Lang:   $($global:NeuralLang) (Auto-Detected)" -ForegroundColor DarkGray
    Write-Host ""
}

function Show-Menu {
    Write-Host " ╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host " ║                MAIN MENU                              ║" -ForegroundColor White
    Write-Host " ╠═══════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host " ║ 1.  🚀 QUICK OPTIMIZE (Recommended)                   ║" -ForegroundColor Green
    Write-Host " ║     (Boot, Debloat, Disk, Gaming Standard)            ║" -ForegroundColor Gray
    Write-Host " ║                                                       ║" -ForegroundColor Cyan
    Write-Host " ║ 2.  🧠 AI SMART OPTIMIZE                              ║" -ForegroundColor Magenta
    Write-Host " ║     (Analyzes hardware & applies best tweaks)         ║" -ForegroundColor Gray
    Write-Host " ║                                                       ║" -ForegroundColor Cyan
    Write-Host " ║ 3.  🛠️ ADVANCED TOOLS                                 ║" -ForegroundColor Yellow
    Write-Host " ║     (Manual selection, Ultra Tweaks, Network, SSD)    ║" -ForegroundColor Gray
    Write-Host " ║                                                       ║" -ForegroundColor Cyan
    Write-Host " ║ 4.  🛡️ SAFETY & RESTORE                               ║" -ForegroundColor White
    Write-Host " ║     (Backups, Restore Points, Undo Changes)           ║" -ForegroundColor Gray
    Write-Host " ║ ╠═══════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host " ║ 0.  EXIT                                              ║" -ForegroundColor DarkGray
    Write-Host " ╚═══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    return Read-Host " >> Seleccione una opción / Select option"
}

function Show-AdvancedMenu {
    Clear-Host
    Write-Host " ╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host " ║              ADVANCED TOOLS                           ║" -ForegroundColor Yellow
    Write-Host " ╠═══════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host " ║ [STANDARD MODULES]                                    ║" -ForegroundColor White
    Write-Host " ║ 1. Boot Optimization                                  ║" -ForegroundColor Gray
    Write-Host " ║ 2. Debloat Suite (Apps + Privacy)                     ║" -ForegroundColor Gray
    Write-Host " ║ 3. Disk Hygiene (Cleanup)                             ║" -ForegroundColor Gray
    Write-Host " ║ 4. Gaming Optimization (Standard)                     ║" -ForegroundColor Gray
    Write-Host " ║ 5. Thermal Optimization                               ║" -ForegroundColor Gray
    Write-Host " ║                                                       ║" -ForegroundColor Cyan
    Write-Host " ║ [ULTRA MODULES]                                       ║" -ForegroundColor Magenta
    Write-Host " ║ 6. Advanced Gaming (MSI, HPET, Latency)               ║" -ForegroundColor Magenta
    Write-Host " ║ 7. Advanced Memory (Pools, Pagefile)                  ║" -ForegroundColor Magenta
    Write-Host " ║ 8. SSD/NVMe Optimizer                                 ║" -ForegroundColor Magenta
    Write-Host " ║ 9. Advanced Registry (Experimental)                   ║" -ForegroundColor Red
    Write-Host " ║                                                       ║" -ForegroundColor Cyan
    Write-Host " ║ [TOOLS]                                               ║" -ForegroundColor Green
    Write-Host " ║ 10. System Monitor                                    ║" -ForegroundColor Green
    Write-Host " ║ 11. Network Diagnostics                               ║" -ForegroundColor Green
    Write-Host " ║ 12. Health Check                                      ║" -ForegroundColor Green
    Write-Host " ║                                                       ║" -ForegroundColor Cyan
    Write-Host " ║ 0. Back to Main Menu                                  ║" -ForegroundColor White
    Write-Host " ╚═══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    return Read-Host " >> Select Tool"
}

function Show-SafetyMenu {
    Clear-Host
    Write-Host " ╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host " ║             SAFETY & RESTORE                          ║" -ForegroundColor White
    Write-Host " ╠═══════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host " ║ 1. Create System Restore Point                        ║" -ForegroundColor Green
    Write-Host " ║ 2. Rollback Last Optimization (Undo)                  ║" -ForegroundColor Yellow
    Write-Host " ║ 3. View Registry Backups                              ║" -ForegroundColor Gray
    Write-Host " ║                                                       ║" -ForegroundColor Cyan
    Write-Host " ║ 0. Back to Main Menu                                  ║" -ForegroundColor White
    Write-Host " ╚═══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    return Read-Host " >> Select Option"
}

# ============================================================================
# AUTO-OPTIMIZE MODE
# ============================================================================

if ($AutoOptimize) {
    Write-Log "=== AUTO-OPTIMIZE MODE ===" -Level Info -LogPath $Script:LogFile
    
    if (-not $SkipRestore) {
        New-SystemRestorePoint -Description "NeuralOptimize_v$Script:Version"
    }
    
    $modules = @(
        @{ Name = "BOOT"; Path = "Boot-Optimization.ps1" },
        @{ Name = "DEBLOAT"; Path = "Debloat-Suite.ps1" },
        @{ Name = "DISK"; Path = "Disk-Hygiene.ps1" },
        @{ Name = "GAMING"; Path = "Gaming-Optimization.ps1" },
        @{ Name = "THERMAL"; Path = "Thermal-Optimization.ps1" }
    )
    
    $startAll = Get-Date
    $results = @{}
    
    foreach ($mod in $modules) {
        $results[$mod.Name] = Invoke-OptimizationModule -Name $mod.Name -ScriptPath (Join-Path $Script:ModuleDir $mod.Path)
    }
    
    $totalTime = ((Get-Date) - $startAll).TotalSeconds
    $successCount = ($results.Values | Where-Object { $_ -eq $true }).Count
    
    Write-Host ''
    Write-Host ' ═══════════════════════════════════════════════════════' -ForegroundColor Green
    Write-Host '   ✓ AUTO-OPTIMIZE COMPLETADO' -ForegroundColor Green
    Write-Host "   Módulos exitosos: $successCount/$($modules.Count)" -ForegroundColor Green
    Write-Host "   Tiempo total: $([math]::Round($totalTime, 2))s" -ForegroundColor Green
    Write-Host ' ═══════════════════════════════════════════════════════' -ForegroundColor Green
    
    Get-PerformanceReport
    exit 0
}

# ============================================================================
# PROFILE AUTO-APPLY
# ============================================================================

if ($ProfileName) {
    Write-Log "=== AUTO-APPLYING PROFILE: $ProfileName ===" -Level Info -LogPath $Script:LogFile
    
    $profileScript = Join-Path $Script:ModuleDir "Profile-System.ps1"
    if (Test-Path $profileScript) {
        & $profileScript -ProfileName $ProfileName -Apply
    }
    
    exit 0
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

trap {
    Write-Log "FATAL ERROR: $($_.Exception.Message)" -Level Error -LogPath $Script:LogFile
    Wait-ForKeyPress
    Stop-Transcript -ErrorAction SilentlyContinue
    exit 1
}

Write-Log "=== NEURAL OPTIMIZER v$Script:Version STARTED ===" -Level Info -LogPath $Script:LogFile

try { 
    $TranscriptFile = Join-Path -Path $Script:ScriptDir -ChildPath "Neural_Detailed.log"
    Start-Transcript -Path $TranscriptFile -Append -Force -ErrorAction SilentlyContinue | Out-Null
}
catch {}

if (-not (Test-ModulesExist)) {
    Wait-ForKeyPress
    Stop-Transcript -ErrorAction SilentlyContinue
    exit 1
}

if (-not $SkipRestore) {
    if (-not (New-SystemRestorePoint -Description "NeuralOptimize_v$Script:Version")) {
        $choice = Read-Host " >> ¿Continuar SIN restore point? (SI/NO)"
        if ($choice -ne "SI") { Stop-Transcript -ErrorAction SilentlyContinue; exit }
    }
}

# Main loop
# ============================================================================
# MAIN LOOP
# ============================================================================

while ($true) {
    Show-Banner
    $selection = Show-Menu

    switch ($selection) {
        '1' { 
            # QUICK OPTIMIZE (Legacy "Run ALL")
            Write-Host " [🚀] Starting Quick Optimization..." -ForegroundColor Green
            $modules = @("Boot-Optimization.ps1", "Debloat-Suite.ps1", "Disk-Hygiene.ps1", "Gaming-Optimization.ps1", "Thermal-Optimization.ps1")
            foreach ($m in $modules) {
                Invoke-OptimizationModule -Name $m.Replace(".ps1", "") -ScriptPath (Join-Path $Script:ModuleDir $m)
            }
            Wait-ForKeyPress
        }
        
        '2' {
            # AI OPTIMIZATION
            Invoke-OptimizationModule -Name "AI-RECOMMENDATIONS" -ScriptPath (Join-Path $Script:ModuleDir "AI-Recommendations.ps1")
            Wait-ForKeyPress
        }
        
        '3' {
            # ADVANCED TOOLS SUB-MENU
            while ($true) {
                $advSel = Show-AdvancedMenu
                if ($advSel -eq '0') { break }
                switch ($advSel) {
                    '1' { Invoke-OptimizationModule -Name 'BOOT' -ScriptPath (Join-Path $Script:ModuleDir "Boot-Optimization.ps1"); Wait-ForKeyPress }
                    '2' { Invoke-OptimizationModule -Name 'DEBLOAT' -ScriptPath (Join-Path $Script:ModuleDir "Debloat-Suite.ps1"); Wait-ForKeyPress }
                    '3' { Invoke-OptimizationModule -Name 'DISK' -ScriptPath (Join-Path $Script:ModuleDir "Disk-Hygiene.ps1"); Wait-ForKeyPress }
                    '4' { Invoke-OptimizationModule -Name 'GAMING' -ScriptPath (Join-Path $Script:ModuleDir "Gaming-Optimization.ps1"); Wait-ForKeyPress }
                    '5' { Invoke-OptimizationModule -Name 'THERMAL' -ScriptPath (Join-Path $Script:ModuleDir "Thermal-Optimization.ps1"); Wait-ForKeyPress }
                    '6' { Invoke-OptimizationModule -Name 'ULTRA-GAMING' -ScriptPath (Join-Path $Script:ModuleDir "Advanced-Gaming.ps1"); Wait-ForKeyPress }
                    '7' { Invoke-OptimizationModule -Name 'ADV-MEMORY' -ScriptPath (Join-Path $Script:ModuleDir "Advanced-Memory.ps1"); Wait-ForKeyPress }
                    '8' { Invoke-OptimizationModule -Name 'SSD-NVME' -ScriptPath (Join-Path $Script:ModuleDir "SSD-NVMe-Optimizer.ps1"); Wait-ForKeyPress }
                    '9' { Invoke-OptimizationModule -Name 'REGISTRY' -ScriptPath (Join-Path $Script:ModuleDir "Advanced-Registry.ps1"); Wait-ForKeyPress }
                    '10' { Invoke-OptimizationModule -Name 'MONITOR' -ScriptPath (Join-Path $Script:ModuleDir "System-Monitor.ps1"); Wait-ForKeyPress }
                    '11' { Invoke-OptimizationModule -Name 'NETWORK' -ScriptPath (Join-Path $Script:ModuleDir "Network-Optimizer.ps1"); Wait-ForKeyPress }
                    '12' { Invoke-OptimizationModule -Name 'HEALTH' -ScriptPath (Join-Path $Script:ModuleDir "Health-Check.ps1"); Wait-ForKeyPress }
                    default { Write-Host "Invalid Option" -ForegroundColor Red; Start-Sleep 1 }
                }
            }
        }
        
        '4' {
            # SAFETY MENU
            while ($true) {
                $safeSel = Show-SafetyMenu
                if ($safeSel -eq '0') { break }
                switch ($safeSel) {
                    '1' { 
                        Write-Host "Creating Restore Point..." -ForegroundColor Yellow
                        New-SystemRestorePoint -Description "Manual_User_Request"
                        Wait-ForKeyPress
                    }
                    '2' {
                        Write-Host "Rollback feature requires a generic restore point mechanism or specific undo scripts." -ForegroundColor Yellow
                        Write-Host "For now, please use System Restore." -ForegroundColor Yellow
                        Wait-ForKeyPress
                    }
                    '3' {
                        $backupDir = Join-Path $Script:ModuleDir "..\Backups"
                        if (Test-Path $backupDir) { Invoke-Item $backupDir } else { Write-Host "No backup folder found." -ForegroundColor Yellow }
                    }
                }
            }
        }
        
        '0' { 
            Write-Host " [👋] Exiting..." -ForegroundColor Cyan
            exit 
        }
        
        'q' { exit }
        
        default { 
            Write-Host " [!] Invalid Option" -ForegroundColor Yellow
            Start-Sleep -Seconds 1
        }
    }
}

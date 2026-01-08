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
    Write-Host " [1] $(Msg 'Menu.Option.1')" -ForegroundColor White
    Write-Host " [2] $(Msg 'Menu.Option.2')" -ForegroundColor White
    Write-Host " [3] $(Msg 'Menu.Option.3')" -ForegroundColor White
    Write-Host " [4] $(Msg 'Menu.Option.4')" -ForegroundColor White
    Write-Host " [5] $(Msg 'Menu.Option.5')" -ForegroundColor White
    Write-Host " [6] $(Msg 'Menu.Option.6')" -ForegroundColor White
    Write-Host " [7] $(Msg 'Menu.Option.7')" -ForegroundColor White
    Write-Host " [8] $(Msg 'Menu.Option.8')" -ForegroundColor White
    Write-Host " [9] $(Msg 'Menu.Option.9')" -ForegroundColor White
    Write-Host ""
    Write-Host " [X] $(Msg 'Menu.Option.X')" -ForegroundColor Red
    Write-Host ""
    
    return Read-Host " >> Seleccione una opción / Select option"
}

function Show-Menu {
    Write-Host " ╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host " ║ 📋 OPTIMIZACIONES STANDARD                            ║" -ForegroundColor White
    Write-Host " ╠═══════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host " ║ 1.  [BOOT]     Optimizar Arranque (BCD + NTFS)       ║" -ForegroundColor White
    Write-Host " ║ 2.  [DEBLOAT]  Eliminar Apps + Privacidad            ║" -ForegroundColor White
    Write-Host " ║ 3.  [DISK]     Limpieza Profunda + Red               ║" -ForegroundColor White
    Write-Host " ║ 4.  [GAMING]   Optimizar para Juegos (Standard)      ║" -ForegroundColor White
    Write-Host " ║ 5.  [THERMAL]  Optimizar Ventiladores                ║" -ForegroundColor White
    Write-Host " ║ 6.  [ALL]      ⚡ EJECUTAR TODO ⚡                     ║" -ForegroundColor Cyan
    Write-Host " ╠═══════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host " ║ 🔥 OPTIMIZACIONES ULTRA (NUEVO v5.0)                  ║" -ForegroundColor Magenta
    Write-Host " ╠═══════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host " ║ 7.  [ULTRA]    🎮 Advanced Gaming (MSI, HPET, Net)   ║" -ForegroundColor Magenta
    Write-Host " ║ 8.  [MEMORY]     Advanced Memory (Pools, Paging)     ║" -ForegroundColor Magenta
    Write-Host " ║ 9.  [SSD]      💿 SSD/NVMe Optimizer (TRIM, Health)  ║" -ForegroundColor Magenta
    Write-Host " ║ 10. [PROFILE]  🎯 Profile System (Presets)           ║" -ForegroundColor Magenta
    Write-Host " ╠═══════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host " ║ 🔥 PHASE 3 EXPERIMENTAL                               ║" -ForegroundColor Red
    Write-Host " ╠═══════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host " ║ 10a. [REGISTRY] ⚡ Advanced Registry (HAGS, DVR)     ║" -ForegroundColor Red
    Write-Host " ║ 10b. [UPDATE]   🔄 Update System (Git Pull)          ║" -ForegroundColor Red
    Write-Host " ╠═══════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host " ║ 🧠 AI & MACHINE LEARNING                              ║" -ForegroundColor Green
    Write-Host " ╠═══════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host " ║ 11. [AI]       🤖 AI Recommendation Engine           ║" -ForegroundColor Green
    Write-Host " ║ 12. [ML]       🧠 ML Usage Patterns                  ║" -ForegroundColor Green
    Write-Host " ║ 13. [GAMEPRO]  🎮 Per-Game Profiles                  ║" -ForegroundColor Green
    Write-Host " ╠═══════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host " ║ 🛠️ HERRAMIENTAS                                       ║" -ForegroundColor Yellow
    Write-Host " ╠═══════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host " ║ 14. [MONITOR]  📊 Monitor Tiempo Real                ║" -ForegroundColor White
    Write-Host " ║ 15. [BENCH]    ⚡ Benchmark Suite                    ║" -ForegroundColor White
    Write-Host " ║ 16. [HEALTH]   🏥 Health Check                       ║" -ForegroundColor White
    Write-Host " ║ 17. [CACHE]    🗃️ Neural Cache (Steam/Games)         ║" -ForegroundColor White
    Write-Host " ║ 18. [INFO]     ℹ️ Hardware Profile                    ║" -ForegroundColor White
    Write-Host " ║ 19. [NET]      🌐 Network Diagnostics                ║" -ForegroundColor White
    Write-Host " ║ 20. [ROLLBACK] 🔄 Revertir Cambios                   ║" -ForegroundColor Red
    Write-Host " ║ 21. [REPORT]   📈 Performance Report                 ║" -ForegroundColor Yellow
    Write-Host " ╠═══════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host " ║ 0.  [EXIT]     Salir                                  ║" -ForegroundColor DarkGray
    Write-Host " ╚═══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
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
while ($true) {
    Show-Banner
    Show-Menu
    
    $selection = Read-Host " >> Opción"
    
    switch ($selection) {
        '1' { Invoke-OptimizationModule -Name "BOOT OPTIMIZER" -ScriptPath (Join-Path $Script:ModuleDir "Boot-Optimization.ps1"); Wait-ForKeyPress }
        '2' { Invoke-OptimizationModule -Name "DEBLOAT SUITE" -ScriptPath (Join-Path $Script:ModuleDir "Debloat-Suite.ps1"); Wait-ForKeyPress }
        '3' { Invoke-OptimizationModule -Name "DISK and NETWORK" -ScriptPath (Join-Path $Script:ModuleDir "Disk-Hygiene.ps1"); Wait-ForKeyPress }
        '4' { Invoke-OptimizationModule -Name "GAMING OPTIMIZER" -ScriptPath (Join-Path $Script:ModuleDir "Gaming-Optimization.ps1"); Wait-ForKeyPress }
        '5' { Invoke-OptimizationModule -Name "THERMAL OPTIMIZER" -ScriptPath (Join-Path $Script:ModuleDir "Thermal-Optimization.ps1"); Wait-ForKeyPress }
        '6' {
            $startAll = Get-Date
            Write-Log "=== FULL OPTIMIZATION STARTED ===" -Level Info -LogPath $Script:LogFile
            
            $results = @{
                Boot    = Invoke-OptimizationModule -Name "BOOT" -ScriptPath (Join-Path $Script:ModuleDir "Boot-Optimization.ps1")
                Debloat = Invoke-OptimizationModule -Name "DEBLOAT" -ScriptPath (Join-Path $Script:ModuleDir "Debloat-Suite.ps1")
                Disk    = Invoke-OptimizationModule -Name "DISK" -ScriptPath (Join-Path $Script:ModuleDir "Disk-Hygiene.ps1")
                Gaming  = Invoke-OptimizationModule -Name "GAMING" -ScriptPath (Join-Path $Script:ModuleDir "Gaming-Optimization.ps1")
                Thermal = Invoke-OptimizationModule -Name "THERMAL" -ScriptPath (Join-Path $Script:ModuleDir "Thermal-Optimization.ps1")
            }
            
            $totalTime = ((Get-Date) - $startAll).TotalSeconds
            $successCount = ($results.Values | Where-Object { $_ -eq $true }).Count
            
            Write-Host ''
            Write-Host ' ═══════════════════════════════════════════════════════' -ForegroundColor Green
            Write-Host '   ✓ OPTIMIZACIÓN COMPLETA FINALIZADA' -ForegroundColor Green
            Write-Host "   Módulos exitosos: $successCount/5" -ForegroundColor Green
            Write-Host "   Tiempo: $([math]::Round($totalTime, 2))s" -ForegroundColor Green
            Write-Host ' ═══════════════════════════════════════════════════════' -ForegroundColor Green
            
            Get-PerformanceReport
            Wait-ForKeyPress
        }
        '7' { Invoke-OptimizationModule -Name "ADVANCED GAMING" -ScriptPath (Join-Path $Script:ModuleDir "Advanced-Gaming.ps1") }
        '8' { Invoke-OptimizationModule -Name "ADVANCED MEMORY" -ScriptPath (Join-Path $Script:ModuleDir "Advanced-Memory.ps1") }
        '9' { Invoke-OptimizationModule -Name "SSD/NVMe OPTIMIZER" -ScriptPath (Join-Path $Script:ModuleDir "SSD-NVMe-Optimizer.ps1") }
        '10' { Invoke-OptimizationModule -Name "PROFILE SYSTEM" -ScriptPath (Join-Path $Script:ModuleDir "Profile-System.ps1") }
        '10a' { Invoke-OptimizationModule -Name "ADVANCED REGISTRY" -ScriptPath (Join-Path $Script:ModuleDir "Advanced-Registry.ps1") }
        '10b' { Invoke-OptimizationModule -Name "SYSTEM UPDATE" -ScriptPath (Join-Path $Script:ModuleDir "Update-System.ps1") }
        '11' { Invoke-OptimizationModule -Name "AI RECOMMENDATIONS" -ScriptPath (Join-Path $Script:ModuleDir "AI-Recommendations.ps1") }
        '12' { Invoke-OptimizationModule -Name "ML USAGE PATTERNS" -ScriptPath (Join-Path $Script:ModuleDir "ML-Usage-Patterns.ps1") }
        '13' { Invoke-OptimizationModule -Name "PER-GAME PROFILES" -ScriptPath (Join-Path $Script:ModuleDir "Per-Game-Profiles.ps1") }
        '14' { Invoke-OptimizationModule -Name "NETWORK OPTIMIZER" -ScriptPath (Join-Path $Script:ModuleDir "Network-Optimizer.ps1"); Wait-ForKeyPress }
        '15' { Invoke-OptimizationModule -Name "SERVICE MANAGER" -ScriptPath (Join-Path $Script:ModuleDir "Service-Manager.ps1"); Wait-ForKeyPress }
        '16' { Invoke-OptimizationModule -Name "PRIVACY GUARDIAN" -ScriptPath (Join-Path $Script:ModuleDir "Privacy-Guardian.ps1"); Wait-ForKeyPress }
        '17' { Invoke-OptimizationModule -Name "VISUAL FX" -ScriptPath (Join-Path $Script:ModuleDir "Visual-FX.ps1"); Wait-ForKeyPress }
        '18' { Invoke-OptimizationModule -Name "SYSTEM MONITOR" -ScriptPath (Join-Path $Script:ModuleDir "System-Monitor.ps1") }
        '19' { Invoke-OptimizationModule -Name "BENCHMARK SUITE" -ScriptPath (Join-Path $Script:ModuleDir "Benchmark-Suite.ps1") }
        '20' { Invoke-OptimizationModule -Name "HEALTH CHECK" -ScriptPath (Join-Path $Script:ModuleDir "Health-Check.ps1") }
        '21' {
            # NeuralCache logic
            $ncPath = Join-Path $Script:ScriptDir "NeuralCache-Diagnostic.ps1"
            if (Test-Path $ncPath) { Invoke-OptimizationModule -Name "NEURAL CACHE" -ScriptPath $ncPath }
            else { 
                # Fallback to NeuralModules if moved there
                $ncPathMod = Join-Path $Script:ModuleDir "NeuralCache-Diagnostic.ps1"
                if (Test-Path $ncPathMod) { Invoke-OptimizationModule -Name "NEURAL CACHE" -ScriptPath $ncPathMod }
                else { Write-Host " [!] NeuralCache no encontrado" -ForegroundColor Red }
            }
            Wait-ForKeyPress
        }
        '22' { Show-HardwareInfo; Wait-ForKeyPress }
        '23' { Test-NetworkPerformance; Wait-ForKeyPress }
        '24' { Invoke-Rollback -Confirm; Wait-ForKeyPress }
        '25' { Get-PerformanceReport; Wait-ForKeyPress }
        '0' { 
            Write-Host " [i] Saliendo..." -ForegroundColor Gray
            Start-Sleep -Seconds 1
            Stop-Transcript -ErrorAction SilentlyContinue
            exit 0
        }
        default {
            Write-Host " [!] Opción inválida" -ForegroundColor Yellow
            Start-Sleep -Seconds 1
        }
    }
}


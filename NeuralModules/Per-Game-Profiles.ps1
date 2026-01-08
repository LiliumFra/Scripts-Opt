<#
.SYNOPSIS
    Per-Game Profiles v6.0
    Configuraciones específicas por juego con auto-detección.

.DESCRIPTION
    Características:
    - Auto-detect game process
    - Apply game-specific optimizations
    - CPU affinity per-game
    - GPU priority per-game
    - Network settings per-game
    - Visual effects per-game
    - Profile switching automático
    - Database de juegos populares

.NOTES
    Parte de Windows Neural Optimizer v6.0
    Creditos: Jose Bustamante
    GitHub: https://github.com/LiliumFra/Scripts-Opt
#>

if (-not (Get-Command "Write-Log" -ErrorAction SilentlyContinue)) {
    $currentDir = Split-Path $MyInvocation.MyCommand.Path
    $utilsPath = Join-Path $currentDir "NeuralUtils.psm1"
    if (Test-Path $utilsPath) { Import-Module $utilsPath -Force -DisableNameChecking }
}

Invoke-AdminCheck -Silent

# ============================================================================
# GAME DATABASE
# ============================================================================

$Script:GameDatabase = @{
    # Competitive FPS
    "cs2.exe"                           = @{
        Name                = "Counter-Strike 2"
        Category            = "Competitive FPS"
        Priority            = "RealTime"
        Affinity            = "All"
        NetworkPriority     = "High"
        VisualEffects       = "Minimal"
        MouseOptimization   = $true
        RecommendedSettings = @{
            CPUPriority    = "RealTime"
            GPUPriority    = 8
            NetworkLatency = "Ultra Low"
        }
    }
    
    "VALORANT-Win64-Shipping.exe"       = @{
        Name                = "Valorant"
        Category            = "Competitive FPS"
        Priority            = "High"
        Affinity            = "All"
        NetworkPriority     = "High"
        VisualEffects       = "Minimal"
        MouseOptimization   = $true
        AntiCheat           = "Vanguard"
        RecommendedSettings = @{
            CPUPriority    = "High"
            GPUPriority    = 8
            NetworkLatency = "Ultra Low"
            Note           = "HPET debe estar habilitado para Vanguard"
        }
    }
    
    "RainbowSix.exe"                    = @{
        Name                = "Rainbow Six Siege"
        Category            = "Competitive FPS"
        Priority            = "High"
        Affinity            = "All"
        NetworkPriority     = "High"
        VisualEffects       = "Balanced"
        MouseOptimization   = $true
        AntiCheat           = "BattlEye"
        RecommendedSettings = @{
            CPUPriority    = "High"
            GPUPriority    = 8
            NetworkLatency = "Low"
        }
    }
    
    # Battle Royale
    "FortniteClient-Win64-Shipping.exe" = @{
        Name                = "Fortnite"
        Category            = "Battle Royale"
        Priority            = "High"
        Affinity            = "All"
        NetworkPriority     = "High"
        VisualEffects       = "Balanced"
        MouseOptimization   = $true
        AntiCheat           = "Easy Anti-Cheat"
        RecommendedSettings = @{
            CPUPriority    = "High"
            GPUPriority    = 7
            NetworkLatency = "Low"
        }
    }
    
    "PUBG.exe"                          = @{
        Name                = "PUBG: Battlegrounds"
        Category            = "Battle Royale"
        Priority            = "High"
        Affinity            = "All"
        NetworkPriority     = "High"
        VisualEffects       = "Minimal"
        MouseOptimization   = $true
        AntiCheat           = "BattlEye"
        RecommendedSettings = @{
            CPUPriority    = "High"
            GPUPriority    = 8
            NetworkLatency = "Low"
        }
    }
    
    # MOBA
    "League of Legends.exe"             = @{
        Name                = "League of Legends"
        Category            = "MOBA"
        Priority            = "High"
        Affinity            = "All"
        NetworkPriority     = "High"
        VisualEffects       = "Balanced"
        MouseOptimization   = $true
        RecommendedSettings = @{
            CPUPriority    = "High"
            GPUPriority    = 7
            NetworkLatency = "Low"
        }
    }
    
    "Dota2.exe"                         = @{
        Name                = "Dota 2"
        Category            = "MOBA"
        Priority            = "High"
        Affinity            = "All"
        NetworkPriority     = "High"
        VisualEffects       = "Balanced"
        MouseOptimization   = $true
        RecommendedSettings = @{
            CPUPriority    = "High"
            GPUPriority    = 7
            NetworkLatency = "Low"
        }
    }
    
    # Single Player AAA
    "Cyberpunk2077.exe"                 = @{
        Name                = "Cyberpunk 2077"
        Category            = "Single Player"
        Priority            = "High"
        Affinity            = "All"
        NetworkPriority     = "Normal"
        VisualEffects       = "Full"
        MouseOptimization   = $false
        RecommendedSettings = @{
            CPUPriority    = "High"
            GPUPriority    = 8
            NetworkLatency = "Normal"
        }
    }
    
    "witcher3.exe"                      = @{
        Name                = "The Witcher 3"
        Category            = "Single Player"
        Priority            = "High"
        Affinity            = "All"
        NetworkPriority     = "Normal"
        VisualEffects       = "Full"
        MouseOptimization   = $false
        RecommendedSettings = @{
            CPUPriority    = "High"
            GPUPriority    = 7
            NetworkLatency = "Normal"
        }
    }
    
    # Streaming/Recording
    "obs64.exe"                         = @{
        Name                = "OBS Studio"
        Category            = "Streaming"
        Priority            = "AboveNormal"
        Affinity            = "All"
        NetworkPriority     = "High"
        VisualEffects       = "Minimal"
        MouseOptimization   = $false
        RecommendedSettings = @{
            CPUPriority    = "AboveNormal"
            GPUPriority    = 6
            NetworkLatency = "Low"
            Note           = "Usa cores específicos para encoding"
        }
    }
}

# ============================================================================
# GAME DETECTION
# ============================================================================

function Get-RunningGames {
    [CmdletBinding()]
    param()
    
    $detectedGames = @()
    $processes = Get-Process
    
    foreach ($gameExe in $Script:GameDatabase.Keys) {
        $processName = $gameExe -replace '\.exe$', ''
        $runningProcess = $processes | Where-Object { $_.Name -eq $processName }
        
        if ($runningProcess) {
            $gameInfo = $Script:GameDatabase[$gameExe].Clone()
            $gameInfo.ProcessId = $runningProcess.Id
            $gameInfo.ProcessName = $runningProcess.Name
            $gameInfo.Exe = $gameExe
            
            $detectedGames += $gameInfo
        }
    }
    
    return $detectedGames
}

# ============================================================================
# OPTIMIZATION APPLICATION
# ============================================================================

function Set-GameOptimizations {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $GameInfo
    )
    
    Write-Host " [+] Aplicando optimizaciones para: $($GameInfo.Name)" -ForegroundColor Cyan
    Write-Host ""
    
    $applied = 0
    $failed = 0
    
    try {
        $process = Get-Process -Id $GameInfo.ProcessId -ErrorAction Stop
        
        # CPU Priority
        try {
            $priorityClass = switch ($GameInfo.Priority) {
                "RealTime" {
                    # ⚠️ SAFETY: Warn and require confirmation
                    Write-Host ""
                    Write-Host " +========================================================+" -ForegroundColor Red
                    Write-Host " |  ⚠️ ADVERTENCIA: REALTIME PRIORITY                     |" -ForegroundColor Red
                    Write-Host " +========================================================+" -ForegroundColor Red
                    Write-Host ""
                    Write-Host " RealTime priority puede:" -ForegroundColor Yellow
                    Write-Host "   • Congelar el sistema si el juego crashea" -ForegroundColor Gray
                    Write-Host "   • Ser detectado por anti-cheat (BattlEye, Vanguard)" -ForegroundColor Gray
                    Write-Host "   • Causar inestabilidad en Windows" -ForegroundColor Gray
                    Write-Host ""
                    $confirm = Read-Host " >> ¿Continuar de todas formas? (escriba 'ACEPTO RIESGO')"
                    
                    if ($confirm -ne "ACEPTO RIESGO") {
                        Write-Host " [i] Usando High Priority en lugar de RealTime" -ForegroundColor Cyan
                        [System.Diagnostics.ProcessPriorityClass]::High
                    }
                    else {
                        # Auto-revert to High after 5 minutes
                        Start-Job -ScriptBlock {
                            Start-Sleep -Seconds 300
                            $proc = Get-Process -Id $using:GameInfo.ProcessId -ErrorAction SilentlyContinue
                            if ($proc) {
                                $proc.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High
                                Write-Host " [i] Auto-reverted to High priority (safety timeout)" -ForegroundColor Yellow
                            }
                        }
                        [System.Diagnostics.ProcessPriorityClass]::RealTime
                    }
                }
                "High" { [System.Diagnostics.ProcessPriorityClass]::High }
                "AboveNormal" { [System.Diagnostics.ProcessPriorityClass]::AboveNormal }
                default { [System.Diagnostics.ProcessPriorityClass]::Normal }
            }
            
            $process.PriorityClass = $priorityClass
            Write-Host "   [OK] CPU Priority: $($GameInfo.Priority)" -ForegroundColor Green
            $applied++
        }
        catch {
            Write-Host "   [!] CPU Priority: Error" -ForegroundColor Yellow
            $failed++
        }
        
        # CPU Affinity
        if ($GameInfo.Affinity -eq "All") {
            try {
                $coreCount = [Environment]::ProcessorCount
                $affinityMask = [Math]::Pow(2, $coreCount) - 1
                $process.ProcessorAffinity = [IntPtr]$affinityMask
                Write-Host "   [OK] CPU Affinity: All $coreCount cores" -ForegroundColor Green
                $applied++
            }
            catch {
                $failed++
            }
        }
        
        # GPU Priority (via registry)
        try {
            $exeName = $GameInfo.Exe
            $gpuPriorityPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$exeName\PerfOptions"
            
            if (-not (Test-Path $gpuPriorityPath)) {
                New-Item -Path $gpuPriorityPath -Force | Out-Null
            }
            
            Set-ItemProperty -Path $gpuPriorityPath -Name "GpuPriorityClass" -Value $GameInfo.RecommendedSettings.GPUPriority -Type DWord -Force
            Write-Host "   [OK] GPU Priority: $($GameInfo.RecommendedSettings.GPUPriority)" -ForegroundColor Green
            $applied++
        }
        catch {
            $failed++
        }
        
        # I/O Priority
        try {
            # Set I/O priority via registry
            $ioPriorityPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$($GameInfo.Exe)"
            if (-not (Test-Path $ioPriorityPath)) {
                New-Item -Path $ioPriorityPath -Force | Out-Null
            }
            
            Set-ItemProperty -Path $ioPriorityPath -Name "IoPriority" -Value 3 -Type DWord -Force
            Write-Host "   [OK] I/O Priority: High" -ForegroundColor Green
            $applied++
        }
        catch {
            $failed++
        }
        
        # Mouse optimization
        if ($GameInfo.MouseOptimization) {
            Write-Host "   [i] Mouse optimization recomendada (ya aplicada globalmente)" -ForegroundColor DarkGray
        }
        
        # Anti-cheat warning
        if ($GameInfo.AntiCheat) {
            Write-Host ""
            Write-Host "   [!] ADVERTENCIA: $($GameInfo.Name) usa $($GameInfo.AntiCheat)" -ForegroundColor Yellow
            
            if ($GameInfo.RecommendedSettings.Note) {
                Write-Host "   [i] $($GameInfo.RecommendedSettings.Note)" -ForegroundColor Cyan
            }
        }
        
        Write-Host ""
        Write-Host " [OK] Optimizaciones aplicadas: $applied exitosas, $failed fallidas" -ForegroundColor Green
        
        return $true
    }
    catch {
        Write-Host " [!] Error aplicando optimizaciones: $_" -ForegroundColor Red
        return $false
    }
}

# ============================================================================
# CUSTOM PROFILE MANAGEMENT
# ============================================================================

function New-CustomGameProfile {
    [CmdletBinding()]
    param()
    
    Write-Host ""
    Write-Host " ╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host " ║  CREAR PERFIL PERSONALIZADO                          ║" -ForegroundColor Cyan
    Write-Host " ╚═══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    # Get game exe
    $exe = Read-Host " >> Nombre del ejecutable (ej: mygame.exe)"
    
    if ([string]::IsNullOrWhiteSpace($exe)) {
        Write-Host " [!] Ejecutable no puede estar vacío" -ForegroundColor Red
        return
    }
    
    # Get game name
    $name = Read-Host " >> Nombre del juego"
    
    # Category
    Write-Host ""
    Write-Host " Categoría:" -ForegroundColor White
    Write-Host "   1. Competitive FPS" -ForegroundColor Gray
    Write-Host "   2. Battle Royale" -ForegroundColor Gray
    Write-Host "   3. MOBA" -ForegroundColor Gray
    Write-Host "   4. Single Player" -ForegroundColor Gray
    Write-Host "   5. Streaming/Recording" -ForegroundColor Gray
    Write-Host "   6. Other" -ForegroundColor Gray
    $catChoice = Read-Host " >>"
    
    $category = switch ($catChoice) {
        '1' { "Competitive FPS" }
        '2' { "Battle Royale" }
        '3' { "MOBA" }
        '4' { "Single Player" }
        '5' { "Streaming" }
        default { "Other" }
    }
    
    # Priority
    Write-Host ""
    Write-Host " Prioridad CPU:" -ForegroundColor White
    Write-Host "   1. RealTime (máximo, puede causar inestabilidad)" -ForegroundColor Gray
    Write-Host "   2. High (recomendado para competitive)" -ForegroundColor Gray
    Write-Host "   3. AboveNormal (balanceado)" -ForegroundColor Gray
    $prioChoice = Read-Host " >>"
    
    $priority = switch ($prioChoice) {
        '1' { "RealTime" }
        '2' { "High" }
        default { "AboveNormal" }
    }
    
    # Create profile
    $customProfile = @{
        Name                = $name
        Category            = $category
        Priority            = $priority
        Affinity            = "All"
        NetworkPriority     = "High"
        VisualEffects       = "Balanced"
        MouseOptimization   = $true
        RecommendedSettings = @{
            CPUPriority    = $priority
            GPUPriority    = 7
            NetworkLatency = "Low"
        }
    }
    
    # Add to database
    $Script:GameDatabase[$exe] = $customProfile
    
    # Save to file
    try {
        $customProfilesPath = Join-Path $PSScriptRoot "custom-game-profiles.json"
        $customProfiles = @{}
        
        if (Test-Path $customProfilesPath) {
            $customProfiles = Get-Content $customProfilesPath -Raw | ConvertFrom-Json -AsHashtable
        }
        
        $customProfiles[$exe] = $customProfile
        $customProfiles | ConvertTo-Json -Depth 5 | Out-File -FilePath $customProfilesPath -Encoding UTF8 -Force
        
        Write-Host ""
        Write-Host " [OK] Perfil personalizado guardado" -ForegroundColor Green
    }
    catch {
        Write-Host ""
        Write-Host " [!] Error guardando perfil: $_" -ForegroundColor Yellow
    }
}

function Import-CustomProfiles {
    try {
        $customProfilesPath = Join-Path $PSScriptRoot "custom-game-profiles.json"
        
        if (Test-Path $customProfilesPath) {
            $customProfiles = Get-Content $customProfilesPath -Raw | ConvertFrom-Json -AsHashtable
            
            foreach ($exe in $customProfiles.Keys) {
                if (-not $Script:GameDatabase.ContainsKey($exe)) {
                    $Script:GameDatabase[$exe] = $customProfiles[$exe]
                }
            }
        }
    }
    catch {}
}

# ============================================================================
# AUTO-MONITOR MODE
# ============================================================================

function Start-GameMonitor {
    [CmdletBinding()]
    param([int]$IntervalSeconds = 5)
    
    Write-Host ""
    Write-Host " ╔═══════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host " ║  GAME MONITOR ACTIVO                                  ║" -ForegroundColor Green
    Write-Host " ╚═══════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host " [i] Monitoreando juegos cada $IntervalSeconds segundos..." -ForegroundColor Cyan
    Write-Host " [i] Presione CTRL+C para detener" -ForegroundColor DarkGray
    Write-Host ""
    
    $optimizedGames = @{}
    
    while ($true) {
        $runningGames = Get-RunningGames
        
        foreach ($game in $runningGames) {
            $key = "$($game.Exe)_$($game.ProcessId)"
            
            # Si no ha sido optimizado
            if (-not $optimizedGames.ContainsKey($key)) {
                Write-Host " [!] JUEGO DETECTADO: $($game.Name)" -ForegroundColor Yellow
                
                $success = Set-GameOptimizations -GameInfo $game
                
                if ($success) {
                    $optimizedGames[$key] = Get-Date
                }
                
                Write-Host ""
            }
        }
        
        # Limpiar juegos que ya no están corriendo
        $keysToRemove = @()
        foreach ($key in $optimizedGames.Keys) {
            $processId = $key.Split('_')[1]
            if (-not (Get-Process -Id $processId -ErrorAction SilentlyContinue)) {
                $keysToRemove += $key
            }
        }
        
        foreach ($key in $keysToRemove) {
            $optimizedGames.Remove($key)
        }
        
        Start-Sleep -Seconds $IntervalSeconds
    }
}

# ============================================================================
# MAIN MENU
# ============================================================================

function Show-GameProfileMenu {
    Clear-Host
    
    Write-Host ""
    Write-Host " ╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host " ║  PER-GAME PROFILES v6.0                               ║" -ForegroundColor Cyan
    Write-Host " ╚═══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " Games en base de datos: $($Script:GameDatabase.Count)" -ForegroundColor Gray
    Write-Host ""
    Write-Host " ╔═══════════════════════════════════════════════════════╗" -ForegroundColor Gray
    Write-Host " ║ 1. Detectar y optimizar juegos activos               ║" -ForegroundColor White
    Write-Host " ║ 2. Iniciar monitor automático                         ║" -ForegroundColor White
    Write-Host " ║ 3. Ver base de datos de juegos                        ║" -ForegroundColor White
    Write-Host " ║ 4. Crear perfil personalizado                         ║" -ForegroundColor White
    Write-Host " ║ 5. Exportar perfiles                                  ║" -ForegroundColor White
    Write-Host " ║ 6. Salir                                               ║" -ForegroundColor DarkGray
    Write-Host " ╚═══════════════════════════════════════════════════════╝" -ForegroundColor Gray
    Write-Host ""
}

# Import custom profiles
Import-CustomProfiles

# Main loop
while ($true) {
    Show-GameProfileMenu
    
    $choice = Read-Host " >> Opción"
    
    switch ($choice) {
        '1' {
            Write-Host ""
            Write-Host " [+] Detectando juegos activos..." -ForegroundColor Cyan
            Write-Host ""
            
            $runningGames = Get-RunningGames
            
            if ($runningGames.Count -eq 0) {
                Write-Host " [i] No hay juegos conocidos ejecutándose" -ForegroundColor Yellow
            }
            else {
                foreach ($game in $runningGames) {
                    Set-GameOptimizations -GameInfo $game
                    Write-Host ""
                }
            }
            
            Wait-ForKeyPress
        }
        '2' {
            try {
                Start-GameMonitor
            }
            catch {
                Write-Host ""
                Write-Host " [i] Monitor detenido" -ForegroundColor Yellow
            }
            Wait-ForKeyPress
        }
        '3' {
            Write-Host ""
            Write-Host " ╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
            Write-Host " ║  BASE DE DATOS DE JUEGOS                              ║" -ForegroundColor Cyan
            Write-Host " ╚═══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
            Write-Host ""
            
            $grouped = $Script:GameDatabase.GetEnumerator() | Group-Object -Property { $_.Value.Category }
            
            foreach ($group in $grouped) {
                Write-Host " [$($group.Name)]" -ForegroundColor Yellow
                foreach ($game in $group.Group) {
                    Write-Host "   • $($game.Value.Name) ($($game.Key))" -ForegroundColor Gray
                }
                Write-Host ""
            }
            
            Wait-ForKeyPress
        }
        '4' {
            New-CustomGameProfile
            Wait-ForKeyPress
        }
        '5' {
            try {
                $exportPath = Join-Path ([Environment]::GetFolderPath('Desktop')) "game-profiles-export.json"
                $Script:GameDatabase | ConvertTo-Json -Depth 5 | Out-File -FilePath $exportPath -Encoding UTF8 -Force
                Write-Host ""
                Write-Host " [OK] Perfiles exportados: $exportPath" -ForegroundColor Green
            }
            catch {
                Write-Host ""
                Write-Host " [!] Error exportando: $_" -ForegroundColor Red
            }
            Wait-ForKeyPress
        }
        '6' {
            exit 0
        }
        default {
            Write-Host " [!] Opción inválida" -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}


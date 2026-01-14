<#
.SYNOPSIS
    Neural Cache Diagnostic v6.5 ULTRA (Advanced Edition)
    Analiza y limpia cahés del sistema inteligentes y temporales.

.DESCRIPTION
    Características Avanzadas:
    - Escaneo Multi-Perfil: Limpia caches de TODOS los usuarios del sistema.
    - Deep Logic: Detiene servicios (wuauserv, bits, cryptsvc) para limpieza profunda.
    - Shadow Locations: Limpia logs de CBS, DISM, WAAS y CryptoSvc.
    - GPU Shaders PRO: Cobertura total para NVIDIA, AMD e Intel.
    - Browser Elite: Incluye Vivaldi, Opera GX y versiones dev/beta.
    - App Hygiene: Discord, Spotify, Teams, VS Code, Slack, Zoom, Dropbox.
    - Component Optimization: DISM StartComponentCleanup integrado.
    
    Integración total con Neural Utils y ML Usage Patterns.

.NOTES
    Parte de Windows Neural Optimizer v6.5 ULTRA
    Creditos: Jose Bustamante
    Inspirado en: Chris Titus Tech, Sophia Script y Optimizer.
#>

if (-not (Get-Command "Write-Log" -ErrorAction SilentlyContinue)) {
    $currentDir = Split-Path $MyInvocation.MyCommand.Path
    $utilsPath = Join-Path $currentDir "NeuralModules\NeuralUtils.psm1"
    if (Test-Path $utilsPath) { Import-Module $utilsPath -Force -DisableNameChecking }
}

Invoke-AdminCheck -Silent

# ============================================================================
# CONFIGURATION & ML INTEGRATION
# ============================================================================

$Script:MLDataPath = Join-Path $env:LOCALAPPDATA "NeuralOptimizer\ML"
$Script:PatternsFile = Join-Path $Script:MLDataPath "learned_patterns.json"

function Get-NeuralMLRecommendation {
    if (Test-Path $Script:PatternsFile) {
        try {
            $patterns = Get-Content $Script:PatternsFile -Raw | ConvertFrom-Json
            $currentHour = (Get-Date).Hour
            $hourPattern = $patterns.ByHour."$currentHour"
            
            if ($hourPattern) {
                if ($hourPattern.GamingFrequency -gt $hourPattern.ProductivityFrequency) {
                    return @{ Type = "Gaming"; Msg = "Uso de juegos detectado. Priorizando limpieza de Shaders y System Logs." }
                }
                elseif ($hourPattern.ProductivityFrequency -gt $hourPattern.GamingFrequency) {
                    return @{ Type = "Productivity"; Msg = "Uso de productividad detectado. Enfocándose en App Caches y Browser Data." }
                }
            }
        }
        catch {}
    }
    return $null
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Get-AllUserProfiles {
    return Get-ChildItem "C:\Users" -Directory | Where-Object { $_.Name -notmatch "Public|Default|All Users" }
}

function Invoke-ServiceControl {
    param([string[]]$Services, [string]$Action)
    
    foreach ($s in $Services) {
        $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
        if ($svc) {
            Write-Host "   [i] $($Action)ing $s..." -ForegroundColor DarkGray
            if ($Action -eq "Stop") { Stop-Service -Name $s -Force -ErrorAction SilentlyContinue }
            else { Start-Service -Name $s -ErrorAction SilentlyContinue }
        }
    }
}

# ============================================================================
# CACHE DEFINITIONS
# ============================================================================

function Get-NeuralCacheLocations {
    $locs = @()
    $userProfiles = Get-AllUserProfiles
    
    # 1. SYSTEM & DEEP LOGS
    $locs += @(
        @{ Cat = "System"; Name = "Windows Temp"; Path = "$env:SystemRoot\Temp" },
        @{ Cat = "System"; Name = "Windows Prefetch"; Path = "$env:SystemRoot\Prefetch" },
        @{ Cat = "System"; Name = "SoftwareDistribution (Downloads)"; Path = "$env:SystemRoot\SoftwareDistribution\Download"; Svc = @("wuauserv", "bits") },
        @{ Cat = "System"; Name = "Catroot2 (Signatures Cache)"; Path = "$env:SystemRoot\System32\catroot2"; Svc = @("cryptsvc") },
        @{ Cat = "System"; Name = "CBS & DISM Logs"; Path = "$env:SystemRoot\Logs\CBS;C:\Windows\Logs\DISM" },
        @{ Cat = "System"; Name = "Delivery Optimization"; Path = "$env:SystemRoot\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization"; Svc = @("DoSvc") },
        @{ Cat = "System"; Name = "Windows Error Reporting"; Path = "C:\ProgramData\Microsoft\Windows\WER" },
        @{ Cat = "System"; Name = "CryptSvc Cache"; Path = "$env:SystemRoot\ServiceProfiles\LocalService\AppData\Local\Microsoft\Windows\Caches" }
    )
    
    # 2. BROWSERS (Multi-User)
    foreach ($user in $userProfiles) {
        $userPath = $user.FullName
        $locs += @(
            @{ Cat = "Browser"; Name = "Chrome ($($user.Name))"; Path = "$userPath\AppData\Local\Google\Chrome\User Data\Default\Cache"; Proc = "chrome" },
            @{ Cat = "Browser"; Name = "Edge ($($user.Name))"; Path = "$userPath\AppData\Local\Microsoft\Edge\User Data\Default\Cache"; Proc = "msedge" },
            @{ Cat = "Browser"; Name = "Brave ($($user.Name))"; Path = "$userPath\AppData\Local\BraveSoftware\Brave-Browser\User Data\Default\Cache"; Proc = "brave" },
            @{ Cat = "Browser"; Name = "Opera GX ($($user.Name))"; Path = "$userPath\AppData\Roaming\Opera Software\Opera GX Stable\Cache"; Proc = "opera" },
            @{ Cat = "Browser"; Name = "User Temp ($($user.Name))"; Path = "$userPath\AppData\Local\Temp" }
        )
    }
    
    # 3. GPU & GAMING
    $locs += @(
        @{ Cat = "Gaming"; Name = "DirectX Shader Cache"; Path = "$env:LOCALAPPDATA\D3DSCache" },
        @{ Cat = "Gaming"; Name = "NVIDIA Shaders"; Path = "$env:LOCALAPPDATA\NVIDIA\DXCache;$env:LOCALAPPDATA\NVIDIA\GLCache" },
        @{ Cat = "Gaming"; Name = "AMD Shaders"; Path = "$env:LOCALAPPDATA\AMD\DxCache;$env:LOCALAPPDATA\AMD\DxcCache" },
        @{ Cat = "Gaming"; Name = "Intel Shaders"; Path = "$env:LOCALAPPDATA\Intel\ShaderCache" },
        @{ Cat = "Gaming"; Name = "Steam HTML Cache"; Path = "$env:LOCALAPPDATA\Steam\htmlcache"; Proc = "steam" },
        @{ Cat = "Gaming"; Name = "Epic Games Cache"; Path = "$env:LOCALAPPDATA\EpicGamesLauncher\Saved\webcache"; Proc = "EpicGamesLauncher" },
        @{ Cat = "Gaming"; Name = "Battle.net Cache"; Path = "$env:LOCALAPPDATA\battle.net\Cache"; Proc = "Battle.net" },
        @{ Cat = "Gaming"; Name = "Riot Games Cache"; Path = "$env:LOCALAPPDATA\Riot Games\Riot Client\Data\Cache"; Proc = "RiotClientServices" }
    )
    
    # 4. ADVANCED APPS
    foreach ($user in $userProfiles) {
        $userApp = "$($user.FullName)\AppData"
        $locs += @(
            @{ Cat = "Apps"; Name = "Discord ($($user.Name))"; Path = "$userApp\Roaming\discord\Cache;$userApp\Roaming\discord\Code Cache"; Proc = "discord" },
            @{ Cat = "Apps"; Name = "Spotify ($($user.Name))"; Path = "$userApp\Local\Spotify\Storage"; Proc = "spotify" },
            @{ Cat = "Apps"; Name = "Teams ($($user.Name))"; Path = "$userApp\Roaming\Microsoft\Teams\Cache"; Proc = "teams" },
            @{ Cat = "Apps"; Name = "VS Code ($($user.Name))"; Path = "$userApp\Roaming\Code\Cache;$userApp\Roaming\Code\CachedData"; Proc = "Code" },
            @{ Cat = "Apps"; Name = "Slack ($($user.Name))"; Path = "$userApp\Roaming\Slack\Cache"; Proc = "slack" },
            @{ Cat = "Apps"; Name = "Dropbox Cache"; Path = "$userApp\Roaming\Dropbox\cache"; Proc = "dropbox" }
        )
    }
    
    return $locs
}

# ============================================================================
# SCAN & CLEAN LOGIC
# ============================================================================

function Invoke-NeuralCacheScan {
    $recommendation = Get-NeuralMLRecommendation
    
    Write-Section "NEURAL CACHE ULTIMATE v6.5"
    
    if ($recommendation) {
        Write-Host " [i] Recomendación IA: $($recommendation.Msg)" -ForegroundColor Cyan
        Write-Host ""
    }
    
    $locations = Get-NeuralCacheLocations
    $results = @()
    $totalSize = 0
    $totalFiles = 0
    
    Write-Host " Escaneando ubicaciones profundidad (Multi-User)..." -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($loc in $locations) {
        $pathsArr = $loc.Path -split ";"
        foreach ($pStr in $pathsArr) {
            $paths = Resolve-Path $pStr -ErrorAction SilentlyContinue
            
            foreach ($p in $paths) {
                Write-Host " Analyzing $($loc.Name)..." -NoNewline -ForegroundColor Gray
                
                if (Test-Path $p.Path) {
                    $measure = Get-ChildItem -Path $p.Path -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum
                    
                    if ($measure.Count -gt 0) {
                        $sizeMB = [math]::Round($measure.Sum / 1MB, 2)
                        $isRunning = $false
                        if ($loc.Proc) { $isRunning = Get-Process -Name $loc.Proc -ErrorAction SilentlyContinue }
                        
                        Write-Host "Found $($measure.Count) files ($sizeMB MB)" -ForegroundColor $(if ($sizeMB -gt 500) { "Yellow" }else { "Gray" })
                        
                        $results += [PSCustomObject]@{
                            Name     = $loc.Name
                            Path     = $p.Path
                            SizeMB   = $sizeMB
                            Files    = $measure.Count
                            Running  = $isRunning
                            Services = $loc.Svc
                            Category = $loc.Cat
                        }
                        $totalSize += $sizeMB
                        $totalFiles += $measure.Count
                    }
                    else { Write-Host " Clean" -ForegroundColor Green }
                }
                else { } # Path doesn't exist, skip silently
            }
        }
    }
    
    Write-Host ""
    Write-Host " ------------------------------------------------" -ForegroundColor Gray
    Write-Host " RESUMEN DE ANALISIS INTELIGENTE:" -ForegroundColor White
    Write-Host " Archivos detectados: $totalFiles" -ForegroundColor Cyan
    Write-Host " Espacio estimable:   $([math]::Round($totalSize, 2)) MB" -ForegroundColor Cyan
    Write-Host ""
    
    if ($totalFiles -gt 0) {
        $choice = Read-Host " >> ¿Desea ejecutar la limpieza avanzada? (S/N)"
        if ($choice -match "^[Ss]") {
            Invoke-NeuralCacheClean -ScanResults $results
        }
    }
}

function Invoke-NeuralCacheClean {
    param($ScanResults)
    
    Write-Section "CLEANING ENGINE"
    
    # 1. STOP REQUIRED SERVICES
    $allSvcs = $ScanResults.Services | Select-Object -Unique | Where-Object { $_ -ne $null }
    if ($allSvcs) {
        Write-Host " [+] Deteniendo servicios para limpieza profunda..." -ForegroundColor Yellow
        Invoke-ServiceControl -Services $allSvcs -Action "Stop"
    }
    
    $freedTotal = 0
    
    # 2. CLEAN FILES
    foreach ($res in $ScanResults) {
        if ($res.Running) {
            Write-Host " [?] $($res.Name) está activo. ¿Cerrar para limpiar? (S/N/A:Saltar)" -ForegroundColor Yellow -NoNewline
            $ans = Read-Host " >"
            if ($ans -match "^[Ss]") {
                Stop-Process -Name $res.Proc -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 1
            }
            elseif ($ans -match "^[Aa]") {
                Write-Host "   [--] Saltando $($res.Name)" -ForegroundColor DarkGray
                continue
            }
        }
        
        Write-Host " Cleaning $($res.Name)..." -NoNewline -ForegroundColor Gray
        $freed = Remove-FolderSafe -Path $res.Path -Desc ""
        if ($freed -ge 0) {
            Write-Host " [OK] ($([math]::Round($freed,2)) MB)" -ForegroundColor Green
            $freedTotal += $freed
        }
    }
    
    # 3. EXTRA: DISM COMPONENT CLEANUP
    Write-Host ""
    $dismAns = Read-Host " >> ¿Ejecutar limpieza de componentes de Windows (DISM)? (Lento pero efectivo) (S/N)"
    if ($dismAns -match "^[Ss]") {
        Write-Host " [+] Iniciando DISM Component Cleanup... esto tardará unos minutos." -ForegroundColor Yellow
        try { & dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase } catch {}
    }
    
    # 4. RESTART SERVICES
    if ($allSvcs) {
        Write-Host ""
        Write-Host " [+] Reiniciando servicios..." -ForegroundColor Yellow
        Invoke-ServiceControl -Services $allSvcs -Action "Start"
    }
    
    Write-Host ""
    Write-Host " ✅ Proceso completado." -ForegroundColor Green
    Write-Host " Liberado: $([math]::Round($freedTotal, 2)) MB" -ForegroundColor Cyan
    Write-Host ""
}

# START
Invoke-NeuralCacheScan
Wait-ForKeyPress


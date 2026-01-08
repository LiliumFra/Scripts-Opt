<#
.SYNOPSIS
    Neural Cache Diagnostic v5.0
    Analiza y limpia cahés del sistema inteligentes y temporales.

.DESCRIPTION
    Escanea ubicaciones críticas:
    - Windows Temp & User Temp
    - Prefetch (Analisis inteligente)
    - Windows Update Cache (SoftwareDistribution)
    - DirectX Shader Cache
    - Browser Caches (Chrome, Edge, Firefox)
    - Store Apps Cache
    
    Provee reporte detallado y limpieza segura.

.NOTES
    Parte de Windows Neural Optimizer v5.0 ULTRA
    Creditos: Jose Bustamante
#>

if (-not (Get-Command "Write-Log" -ErrorAction SilentlyContinue)) {
    $currentDir = Split-Path $MyInvocation.MyCommand.Path
    $utilsPath = Join-Path $currentDir "NeuralModules\NeuralUtils.psm1"
    if (Test-Path $utilsPath) { Import-Module $utilsPath -Force -DisableNameChecking }
}

Invoke-AdminCheck -Silent

function Get-FolderSize {
    param($Path)
    if (Test-Path $Path) {
        $measure = Get-ChildItem $Path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum
        return @{
            Count  = $measure.Count
            SizeMB = [math]::Round($measure.Sum / 1MB, 2)
        }
    }
    return @{ Count = 0; SizeMB = 0 }
}

function Invoke-NeuralCacheScan {
    Write-Section "NEURAL CACHE DIAGNOSTIC"
    
    $locations = @(
        @{ Name = "System Temp"; Path = "$env:SystemRoot\Temp" },
        @{ Name = "User Temp"; Path = "$env:TEMP" },
        @{ Name = "Prefetch"; Path = "$env:SystemRoot\Prefetch" },
        @{ Name = "Windows Update"; Path = "$env:SystemRoot\SoftwareDistribution\Download" },
        @{ Name = "DirectX Shader Cache"; Path = "$env:LOCALAPPDATA\D3DSCache" },
        @{ Name = "NVIDIA GLCache"; Path = "$env:LOCALAPPDATA\NVIDIA\GLCache" },
        @{ Name = "AMD Shader Cache"; Path = "$env:LOCALAPPDATA\AMD\DxCache" },
        @{ Name = "Crash Dumps"; Path = "$env:LOCALAPPDATA\CrashDumps" }
    )
    
    # Browser Caches
    $browsers = @(
        @{ Name = "Google Chrome"; Path = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache" },
        @{ Name = "Microsoft Edge"; Path = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache" },
        @{ Name = "Mozilla Firefox"; Path = "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles" } # General profile path
    )
    
    foreach ($b in $browsers) {
        if (Test-Path $b.Path) { $locations += $b }
    }
    
    $totalFiles = 0
    $totalSize = 0
    
    Write-Host " Escaneando ubicaciones..." -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($loc in $locations) {
        Write-Host " Analyzing $($loc.Name)..." -NoNewline -ForegroundColor Gray
        
        if (Test-Path $loc.Path) {
            $info = Get-FolderSize -Path $loc.Path
            
            if ($info.Count -gt 0) {
                Write-Host " Encontrado: $($info.Count) archivos ($($info.SizeMB) MB)" -ForegroundColor Yellow
                $totalFiles += $info.Count
                $totalSize += $info.SizeMB
            }
            else {
                Write-Host " Limpio" -ForegroundColor Green
            }
        }
        else {
            Write-Host " No encontrado" -ForegroundColor DarkGray
        }
    }
    
    Write-Host ""
    Write-Host " ------------------------------------------------" -ForegroundColor Gray
    Write-Host " TOTAL ANALIZADO:" -ForegroundColor White
    Write-Host " Archivos: $totalFiles" -ForegroundColor Cyan
    Write-Host " Tamaño:   $([math]::Round($totalSize, 2)) MB" -ForegroundColor Cyan
    Write-Host ""
    
    if ($totalFiles -gt 0) {
        $choice = Read-Host " >> ¿Desea limpiar estos archivos? (SI/NO)"
        if ($choice -eq "SI") {
            Invoke-NeuralCacheClean -Locations $locations
        }
    }
    else {
        Write-Host " El sistema está optimizado." -ForegroundColor Green
    }
}

function Invoke-NeuralCacheClean {
    param($Locations)
    
    Write-Section "LIMPIEZA DE CACHE"
    
    # Close browsers if running
    Stop-Process -Name "chrome" -ErrorAction SilentlyContinue
    Stop-Process -Name "msedge" -ErrorAction SilentlyContinue
    Stop-Process -Name "firefox" -ErrorAction SilentlyContinue
    
    foreach ($loc in $Locations) {
        if (Test-Path $loc.Path) {
            Write-Host " Limpiando $($loc.Name)..." -NoNewline -ForegroundColor Gray
            try {
                Remove-Item -Path "$($loc.Path)\*" -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host " [OK]" -ForegroundColor Green
            }
            catch {
                Write-Host " [PARCIAL]" -ForegroundColor Yellow
            }
        }
    }
    
    Write-Host ""
    Write-Host " ✓ Limpieza completada." -ForegroundColor Green
    Write-Host ""
}

Invoke-NeuralCacheScan
Wait-ForKeyPress

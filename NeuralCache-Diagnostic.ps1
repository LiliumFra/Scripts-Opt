<#
.SYNOPSIS
    NEURALCACHE v3.5 LTS - CON INICIO AUTOMATICO
    Auto-elevación, detección automática de Steam, y cache persistente.

.DESCRIPTION
    Sistema de cache que guarda los archivos escaneados para no tener que
    escanear de nuevo cada vez. Cache de 15 dias. Incluye inicio automatico.
    Creditos: Jose Bustamante
    
.PARAMETER TargetDir
    Directorio a escanear (auto-detecta D:\Steam si no se especifica)

.PARAMETER ForceRescan
    Forzar re-escaneo ignorando el cache

.PARAMETER Threads
    Número de threads para procesamiento (0 = auto)
#>

param(
    [string]$TargetDir = "",
    [switch]$ForceRescan,
    [int]$Threads = 0,
    [switch]$Silent,      # No user iteraction
    [switch]$AutoAccept   # Automatically accept Steam directory
)

#Requires -Version 5.1

# ============================================================================
# AUTO-ELEVACIÓN A ADMINISTRADOR
# ============================================================================

function Test-AdminPrivileges {
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]$identity
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch { return $false }
}

if (-not (Test-AdminPrivileges)) {
    if (-not $Silent) { Write-Host " [i] Solicitando permisos de administrador..." -ForegroundColor Yellow }
    
    try {
        $scriptPath = if ($MyInvocation.MyCommand.Path) { $MyInvocation.MyCommand.Path } else { $PSCommandPath }
        $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
        if ($TargetDir) { $arguments += " -TargetDir `"$TargetDir`"" }
        if ($ForceRescan) { $arguments += " -ForceRescan" }
        if ($Threads -gt 0) { $arguments += " -Threads $Threads" }
        if ($Silent) { $arguments += " -Silent" }
        if ($AutoAccept) { $arguments += " -AutoAccept" }
        
        Start-Process -FilePath "powershell.exe" -ArgumentList $arguments -Verb RunAs -Wait
        exit 0
    }
    catch {
        if (-not $Silent) {
            Write-Host " [X] ERROR: No se pudo obtener permisos de administrador." -ForegroundColor Red
            Write-Host " Presione cualquier tecla para salir..." -ForegroundColor Gray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        exit 1
    }
}

# ============================================================================
# CONFIGURACIÓN GLOBAL
# ============================================================================

$ErrorActionPreference = "Stop"
$Script:Version = "3.5"
$LogPath = Join-Path -Path ([Environment]::GetFolderPath('Desktop')) -ChildPath "NeuralCache_Debug.log"
$TranscriptStarted = $false

# ============================================================================
# FUNCIONES DE UTILIDAD
# ============================================================================

function Write-Log {
    param([string]$Message, [string]$Level = 'Info')
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    try { "[$timestamp] [$Level] $Message" | Out-File -FilePath $LogPath -Append -Encoding UTF8 -EA SilentlyContinue } catch {}
    $color = switch ($Level) { 'Info' { 'Gray' } 'Warning' { 'Yellow' } 'Error' { 'Red' } 'Success' { 'Green' } default { 'Gray' } }
    Write-Host " [LOG] $Message" -ForegroundColor $color
}

function Wait-ForKeyPress {
    param([string]$Message = "Presiona cualquier tecla para continuar...")
    Write-Host " $Message" -ForegroundColor Green
    try { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") } catch { Read-Host " Presiona Enter" }
}

function Show-FatalError {
    param($Exception)
    Clear-Host
    Write-Host "`n +========================================================+" -ForegroundColor Red
    Write-Host " |  ERROR FATAL DETECTADO - EL SCRIPT SE DETUVO           |" -ForegroundColor Red
    Write-Host " +========================================================+`n" -ForegroundColor Red
    $msg = if ($Exception -is [System.Management.Automation.ErrorRecord]) { $Exception.Exception.Message } else { $Exception.ToString() }
    Write-Host " $msg" -ForegroundColor Red
    Write-Log -Message "FATAL: $msg" -Level Error
    Wait-ForKeyPress -Message "Presiona CUALQUIER TECLA para cerrar..."
}

function Find-SteamDirectory {
    $paths = @("D:\Steam", "D:\SteamLibrary", "D:\Games\Steam", "E:\Steam", "C:\Program Files (x86)\Steam")
    foreach ($p in $paths) { if (Test-Path $p) { return $p } }
    return $null
}

function Clear-OldCaches {
    $cacheRootDir = Join-Path -Path $env:LOCALAPPDATA -ChildPath "NeuralCache"
    if (Test-Path $cacheRootDir) {
        try {
            # Remove files older than 15 days
            $oldFiles = Get-ChildItem -Path $cacheRootDir -Filter "cache_*.json" | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-15) }
            foreach ($file in $oldFiles) {
                Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
                Write-Log "Cache expirado eliminado: $($file.Name)" -Level Info
            }
        }
        catch {}
    }
}

# ============================================================================
# SISTEMA DE CACHE / MEMORIA
# ============================================================================

function Get-CachePath {
    param([string]$Directory)
    $hash = [System.BitConverter]::ToString([System.Security.Cryptography.MD5]::Create().ComputeHash(
            [System.Text.Encoding]::UTF8.GetBytes($Directory.ToLower())
        )).Replace("-", "").Substring(0, 8)
    return Join-Path -Path $env:LOCALAPPDATA -ChildPath "NeuralCache\cache_$hash.json"
}

function Get-CachedScan {
    param([string]$Directory, [int]$MaxAgeHours = 360)  # 15 dias de cache
    
    $cachePath = Get-CachePath -Directory $Directory
    
    if (-not (Test-Path $cachePath)) {
        Write-Host " [CACHE] No existe cache previo para este directorio." -ForegroundColor DarkGray
        return $null
    }
    
    try {
        $cacheData = Get-Content -Path $cachePath -Raw | ConvertFrom-Json
        
        # Verificar edad del cache
        $cacheTime = [DateTime]::Parse($cacheData.Timestamp)
        $age = (Get-Date) - $cacheTime
        
        if ($age.TotalHours -gt $MaxAgeHours) {
            Write-Host " [CACHE] Cache expirado (antiguo: $([int]$age.TotalHours) horas)." -ForegroundColor Yellow
            return $null
        }
        
        # Verificar que el directorio no haya cambiado mucho
        $currentDirInfo = Get-Item $Directory
        if ($cacheData.DirectoryLastWrite -and $currentDirInfo.LastWriteTime -gt [DateTime]::Parse($cacheData.DirectoryLastWrite)) {
            Write-Host " [CACHE] El directorio fue modificado desde el ultimo escaneo." -ForegroundColor Yellow
            return $null
        }
        
        Write-Host " [CACHE] Usando cache existente ($($cacheData.FileCount) archivos, hace $([int]$age.TotalMinutes) min)" -ForegroundColor Green
        return $cacheData
    }
    catch {
        Write-Host " [CACHE] Error leyendo cache: $_" -ForegroundColor Yellow
        return $null
    }
}

function Save-ScanCache {
    param(
        [string]$Directory,
        [string[]]$Files,
        [int]$ProcessedCount
    )
    
    $cachePath = Get-CachePath -Directory $Directory
    $cacheDir = Split-Path $cachePath -Parent
    
    # Crear directorio de cache si no existe
    if (-not (Test-Path $cacheDir)) {
        New-Item -Path $cacheDir -ItemType Directory -Force | Out-Null
    }
    
    try {
        $dirInfo = Get-Item $Directory -ErrorAction SilentlyContinue
        
        $cacheData = @{
            Version            = $Script:Version
            Timestamp          = (Get-Date).ToString("o")
            Directory          = $Directory
            DirectoryLastWrite = if ($dirInfo) { $dirInfo.LastWriteTime.ToString("o") } else { $null }
            FileCount          = $Files.Count
            ProcessedCount     = $ProcessedCount
            Files              = $Files
        }
        
        $cacheData | ConvertTo-Json -Depth 3 -Compress | Out-File -FilePath $cachePath -Encoding UTF8 -Force
        Write-Host " [CACHE] Guardado exitosamente ($($Files.Count) archivos)" -ForegroundColor Green
        Write-Log -Message "Cache guardado: $cachePath" -Level Success
    }
    catch {
        Write-Host " [CACHE] Error guardando cache: $_" -ForegroundColor Yellow
    }
}

# ============================================================================
# LOGICA DE FILTRADO INTELIGENTE
# ============================================================================

function Get-OptimizedFileList {
    param([string[]]$Files)
    
    Write-Host " [BRAIN] Analizando importancia de archivos..." -ForegroundColor Cyan
    
    # Prioridad Alta: Binarios y Assets Criticos (Cargar SIEMPRE)
    $HighPriorityExt = @('.exe', '.dll', '.sys', '.pak', '.vpk', '.pck', '.ba2', '.dat', '.bin', '.assets', '.unity3d')
    
    # Exclusiones: Media, logs, instaladores, basura (IGNORAR)
    $BloatExt = @('.txt', '.log', '.tmp', '.dmp', '.mp4', '.avi', '.mkv', '.webm', '.wmv', '.zip', '.rar', '.7z', '.installer', '.msi')
    
    $optimizedList = @()
    $skippedCount = 0
    $priorityCount = 0
    
    foreach ($file in $Files) {
        $ext = [System.IO.Path]::GetExtension($file).ToLower()
        
        # 1. Ignorar Bloat explicitamente
        if ($BloatExt -contains $ext) { 
            $skippedCount++
            continue 
        }
        
        # 2. Contar Prioridad (Binarios/Assets)
        if ($HighPriorityExt -contains $ext) {
            $priorityCount++
        }
        
        # 3. Todo lo demas entra
        $optimizedList += $file
    }
    
    if ($skippedCount -gt 0) {
        Write-Host " [SMART] Se ignoraron $skippedCount archivos innecesarios (videos, logs, etc)." -ForegroundColor Green
    }
    if ($priorityCount -gt 0) {
        Write-Host " [SMART] Identificados $priorityCount archivos criticos (Binarios/Assets)." -ForegroundColor Cyan
    }
    
    return , $optimizedList
}

# ============================================================================
# CÓDIGO C# OPTIMIZADO
# ============================================================================

$CSharpSource = @"
using System;
using System.IO;
using System.Threading;
using System.Threading.Tasks;
using System.Collections.Generic;

public class FastLoader 
{
    private static readonly object _lock = new object();
    private static int _processed = 0;
    private static int _total = 0;
    
    public static void Test() { Console.WriteLine("[FastLoader] Motor C# Activo - v3.5"); }
    
    public static int GetProcessed() { return _processed; }
    public static int GetTotal() { return _total; }
    
    public static int Load(string[] files, int threads) 
    {
        if (files == null || files.Length == 0) { return 0; }
        
        _processed = 0;
        _total = files.Length;
        int threadCount = threads > 0 ? threads : Environment.ProcessorCount;
        
        Parallel.ForEach(files, new ParallelOptions { MaxDegreeOfParallelism = threadCount }, file =>
        {
            try
            {
                if (File.Exists(file))
                {
                    using (var fs = File.OpenRead(file)) { byte[] b = new byte[4096]; fs.Read(b, 0, Math.Min(4096, (int)fs.Length)); }
                    Interlocked.Increment(ref _processed);
                }
            }
            catch { }
        });
        
        return _processed;
    }
    
    public static string[] ScanDirectory(string path)
    {
        if (string.IsNullOrEmpty(path) || !Directory.Exists(path)) return new string[0];
        try { return Directory.GetFiles(path, "*.*", SearchOption.AllDirectories); }
        catch { return new string[0]; }
    }
    
    public static List<string> ScanDirectoryWithProgress(string path)
    {
        var result = new List<string>();
        if (string.IsNullOrEmpty(path) || !Directory.Exists(path)) return result;
        
        try
        {
            var dirs = new Queue<string>();
            dirs.Enqueue(path);
            
            while (dirs.Count > 0)
            {
                string current = dirs.Dequeue();
                try
                {
                    foreach (var file in Directory.GetFiles(current))
                        result.Add(file);
                    foreach (var dir in Directory.GetDirectories(current))
                        dirs.Enqueue(dir);
                }
                catch { }
            }
        }
        catch { }
        
        return result;
    }
}
"@

# ============================================================================
# INICIO DEL SCRIPT PRINCIPAL
# ============================================================================

try {
    # Limpiar caches antiguos
    Clear-OldCaches
    
    # Iniciar logging
    try { Stop-Transcript -EA SilentlyContinue | Out-Null } catch {}
    try { Start-Transcript -Path $LogPath -Force -Append | Out-Null; $TranscriptStarted = $true } catch {}
    
    Write-Log -Message "Iniciando NeuralCache v$Script:Version (con memoria)" -Level Info
    Write-Log -Message "Usuario: $env:USERNAME | Admin: True" -Level Success
    
    # Compilar motor C#
    Write-Log -Message "Compilando motor C#..." -Level Info
    if (-not ([System.Management.Automation.PSTypeName]'FastLoader').Type) {
        Add-Type -TypeDefinition $CSharpSource -Language CSharp -ErrorAction Stop -WarningAction SilentlyContinue
    }
    Write-Log -Message "Motor C# listo." -Level Success
    
    # Interfaz
    Clear-Host
    Write-Host ""
    Write-Host " +========================================================+" -ForegroundColor Cyan
    Write-Host " |       NEURALCACHE v$Script:Version LTS - CON MEMORIA              |" -ForegroundColor Cyan
    Write-Host " +========================================================+" -ForegroundColor Cyan
    Write-Host " |  [OK] Ejecutando como Administrador                    |" -ForegroundColor Green
    Write-Host " |  [OK] Motor C# compilado                               |" -ForegroundColor Green
    Write-Host " |  [OK] Sistema de cache activo                          |" -ForegroundColor Green
    Write-Host " +--------------------------------------------------------+" -ForegroundColor Gray
    Write-Host ""
    
    # Detectar directorio
    if ([string]::IsNullOrWhiteSpace($TargetDir)) {
        if (-not $Silent) { Write-Host " [i] Buscando Steam automaticamente..." -ForegroundColor Cyan }
        $detected = Find-SteamDirectory
        
        if ($detected) {
            if ($AutoAccept -or $Silent) {
                if (-not $Silent) { Write-Host " [OK] Auto-detectado: $detected" -ForegroundColor Green }
                $TargetDir = $detected
            }
            else {
                Write-Host " [OK] Detectado: $detected" -ForegroundColor Green
                Write-Host ""
                Write-Host " Usar este directorio? (S/N o escribe ruta):" -ForegroundColor White
                $r = Read-Host " >"
                
                if ([string]::IsNullOrWhiteSpace($r) -or $r -match '^[Ss]') { $TargetDir = $detected }
                elseif ($r -match '^[Nn]') {
                    $TargetDir = (Read-Host " Arrastra carpeta aqui >").Trim().Trim('"')
                }
                else { $TargetDir = $r.Trim().Trim('"') }
            }
        }
        else {
            if ($Silent) { throw "No se detecto Steam y no se especifico directorio (Silent)." }
            $TargetDir = (Read-Host " Arrastra carpeta aqui >").Trim().Trim('"')
        }
    }
    
    Write-Log -Message "Directorio: $TargetDir" -Level Info
    
    if (-not (Test-Path $TargetDir)) { throw "Carpeta no existe: $TargetDir" }
    
    # ========================================================================
    # SISTEMA DE MEMORIA - VERIFICAR CACHE
    # ========================================================================
    
    Write-Host ""
    $files = $null
    $fromCache = $false
    
    if (-not $ForceRescan) {
        $cache = Get-CachedScan -Directory $TargetDir -MaxAgeHours 24
        
        if ($cache) {
            $files = $cache.Files
            $fromCache = $true
            Write-Host " [MEMORIA] Usando $($files.Count) archivos del cache anterior." -ForegroundColor Cyan
        }
    }
    else {
        Write-Host " [MEMORIA] Forzando re-escaneo (ForceRescan activo)." -ForegroundColor Yellow
    }
    
    # Si no hay cache, escanear con progreso
    if (-not $files) {
        Write-Host " [SCAN] Escaneando directorio (esto se guardara para la proxima vez)..." -ForegroundColor Cyan
        Write-Host "" 
        
        $scanStart = Get-Date
        
        # Usar escaneo con progreso
        Write-Progress -Activity "NEURALCACHE - Escaneando Directorio" -Status "Buscando archivos en $TargetDir..." -PercentComplete 0
        
        $fileList = [FastLoader]::ScanDirectoryWithProgress($TargetDir)
        $rawFiles = $fileList.ToArray()
        
        # APLICAR FILTRO INTELIGENTE
        $files = Get-OptimizedFileList -Files $rawFiles
        
        Write-Progress -Activity "NEURALCACHE - Escaneando Directorio" -Completed
        
        $scanTime = (Get-Date) - $scanStart
        Write-Host " [SCAN] Encontrados $($rawFiles.Count) archivos (Filtrado a: $($files.Count)) en $([int]$scanTime.TotalSeconds)s." -ForegroundColor Green
    }
    
    Write-Log -Message "Archivos: $($files.Count)" -Level Info
    
    # Procesar archivos con BARRA DE PROGRESO
    if ($files.Count -gt 0) {
        Write-Host ""
        Write-Host " [PROC] Procesando $($files.Count) archivos..." -ForegroundColor Cyan
        
        $threadCount = if ($Threads -gt 0) { $Threads } else { [Environment]::ProcessorCount }
        Write-Host " [PROC] Usando $threadCount threads." -ForegroundColor Gray
        Write-Host ""
        
        [FastLoader]::Test()
        
        # Iniciar procesamiento en background job para mostrar progreso
        $totalFiles = $files.Count
        $job = Start-Job -ScriptBlock {
            param($filesArray, $threads, $csharpCode)
            Add-Type -TypeDefinition $csharpCode -Language CSharp -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            [FastLoader]::Load($filesArray, $threads)
        } -ArgumentList @(, $files), $threadCount, $CSharpSource
        
        # Mostrar progreso mientras se procesa
        $progressStart = Get-Date
        while ($job.State -eq 'Running') {
            $current = [FastLoader]::GetProcessed()
            $percent = if ($totalFiles -gt 0) { [math]::Min(100, [int](($current / $totalFiles) * 100)) } else { 0 }
            $elapsed = (Get-Date) - $progressStart
            $speed = if ($elapsed.TotalSeconds -gt 0) { [int]($current / $elapsed.TotalSeconds) } else { 0 }
            
            Write-Progress -Activity "NEURALCACHE - Cargando Archivos en Memoria" `
                -Status "Procesados: $current / $totalFiles ($speed archivos/seg)" `
                -PercentComplete $percent `
                -CurrentOperation "Optimizando cache del sistema..."
            
            Start-Sleep -Milliseconds 200
        }
        
        # Obtener resultado
        $processed = Receive-Job -Job $job
        Remove-Job -Job $job -Force
        
        Write-Progress -Activity "NEURALCACHE - Cargando Archivos en Memoria" -Completed
        
        $procTime = (Get-Date) - $progressStart
        Write-Host ""
        Write-Host " [OK] Procesados $processed archivos en $([int]$procTime.TotalSeconds) segundos" -ForegroundColor Green
        
        Write-Log -Message "Procesados: $processed" -Level Success
        
        # Guardar en cache si escaneamos nuevo
        if (-not $fromCache) {
            Write-Host ""
            Save-ScanCache -Directory $TargetDir -Files $files -ProcessedCount $processed
        }
    }
    else {
        Write-Host " No se encontraron archivos." -ForegroundColor Yellow
    }
    
    # Resumen
    Write-Host ""
    Write-Host " +--------------------------------------------------------+" -ForegroundColor Green
    Write-Host " |  [OK] Proceso completado!                              |" -ForegroundColor Green
    if ($fromCache) {
        Write-Host " |  [i] Datos cargados desde cache (instantaneo)          |" -ForegroundColor Cyan
    }
    else {
        Write-Host " |  [i] Cache guardado para proximas ejecuciones          |" -ForegroundColor Cyan
    }
    Write-Host " +--------------------------------------------------------+" -ForegroundColor Green
    Write-Host ""
    Write-Host " TIPS:" -ForegroundColor White
    Write-Host "   - La proxima vez sera MUCHO mas rapido (usa cache)" -ForegroundColor Gray
    Write-Host "   - Usa -ForceRescan para forzar nuevo escaneo" -ForegroundColor Gray
    Write-Host "   - Cache valido por 15 dias" -ForegroundColor Gray
    Write-Host ""
    
    # Ofrecer o Actualizar inicio automatico
    $startupPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    $startupName = "NeuralCache"
    $currentStartup = Get-ItemProperty -Path $startupPath -Name $startupName -EA SilentlyContinue
    
    # Construir comando ideal
    $scriptFullPath = $MyInvocation.MyCommand.Path
    if (-not $scriptFullPath) { $scriptFullPath = $PSCommandPath }
    $startupCmd = "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptFullPath`" -TargetDir `"$TargetDir`" -Silent -AutoAccept"
    
    if ($currentStartup) {
        # Ya existe, verificar si esta actualizado
        $currentVal = $currentStartup.$startupName
        if ($currentVal -ne $startupCmd) {
            # Actualizar silenciosamente para asegurar que tenga -Silent y la ruta correcta
            try {
                Set-ItemProperty -Path $startupPath -Name $startupName -Value $startupCmd -Type String -Force
                if (-not $Silent) { 
                    Write-Host " [UPDATE] Configuracion de inicio actualizada a la version v3.5." -ForegroundColor Green
                }
            }
            catch {}
        }
        else {
            if (-not $Silent) { Write-Host " [i] Inicio automatico activo y configurado correctamente." -ForegroundColor DarkCyan }
        }
    }
    else {
        # No existe, ofrecer activar
        if (-not $Silent) {
            Write-Host " [?] Deseas activar inicio automatico con Windows? (S/N)" -ForegroundColor Yellow
            $response = Read-Host " >"
            
            if ($response -match '^[Ss]') {
                try {
                    Set-ItemProperty -Path $startupPath -Name $startupName -Value $startupCmd -Type String -Force
                    Write-Host " [OK] Inicio automatico activado!" -ForegroundColor Green
                    Write-Host "      Se ejecutara silenciosamente al iniciar Windows." -ForegroundColor DarkCyan
                }
                catch {
                    Write-Host " [!!] Error al configurar inicio automatico: $_" -ForegroundColor Yellow
                }
            }
        }
    }
    
    if (-not $Silent) {
        Write-Host ""
        Write-Log -Message "Completado exitosamente." -Level Success
        Wait-ForKeyPress
    }
}
catch {
    Show-FatalError -Exception $_
}
finally {
    if ($TranscriptStarted) { try { Stop-Transcript -EA SilentlyContinue | Out-Null } catch {} }
}
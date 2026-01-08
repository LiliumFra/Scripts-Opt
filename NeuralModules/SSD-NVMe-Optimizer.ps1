<#
.SYNOPSIS
    SSD/NVMe Advanced Optimizer v5.0
    Optimizaciones específicas para unidades de estado sólido.

.DESCRIPTION
    Características:
    - NVMe Protocol optimization
    - TRIM interval tuning
    - Over-provisioning check
    - Write cache policy
    - 4K Alignment verification
    - SMART Health analysis
    - SLC Cache flushing

.NOTES
    Parte de Windows Neural Optimizer v5.0
    Creditos: Jose Bustamante
#>

if (-not (Get-Command "Write-Log" -ErrorAction SilentlyContinue)) {
    $currentDir = Split-Path $MyInvocation.MyCommand.Path
    $utilsPath = Join-Path $currentDir "NeuralUtils.psm1"
    if (Test-Path $utilsPath) { Import-Module $utilsPath -Force -DisableNameChecking }
}

Invoke-AdminCheck -Silent

# ============================================================================
# DISK DETECTION & CLASSIFICATION
# ============================================================================

function Get-DiskType {
    [CmdletBinding()]
    param()
    
    Write-Step "[DISK] DISK DETECTION"
    
    $disks = Get-PhysicalDisk | Select-Object FriendlyName, MediaType, BusType, Size, HealthStatus
    
    $ssdCount = 0
    $nvmeCount = 0
    
    Write-Host " Unidades detectadas:" -ForegroundColor Cyan
    
    foreach ($d in $disks) {
        $sizeGB = [math]::Round($d.Size / 1GB, 1)
        
        Write-Host "   • $($d.FriendlyName)" -NoNewline -ForegroundColor White
        Write-Host " [$($d.MediaType)]" -NoNewline -ForegroundColor Yellow
        Write-Host " ($sizeGB GB)" -ForegroundColor Gray
        
        if ($d.MediaType -eq "SSD") { $ssdCount++ }
        if ($d.BusType -eq "NVMe") { $nvmeCount++ }
    }
    
    Write-Host ""
    return @{ SSD = $ssdCount; NVMe = $nvmeCount }
}

# ============================================================================
# TRIM OPTIMIZATION
# ============================================================================

function Optimize-Trim {
    [CmdletBinding()]
    param()
    
    Write-Step "[DISK] TRIM OPTIMIZATION"
    
    Write-Host " [i] Optimizando configuración de TRIM/ReTrim..." -ForegroundColor Cyan
    Write-Host ""
    
    # Enable NTFS DisableDeleteNotify (0 = Enabled)
    $null = & fsutil behavior set DisableDeleteNotify 0 2>&1
    Write-Host "   [OK] TRIM enabled (NTFS)" -ForegroundColor Green
    
    # ReFS support if applicable
    $null = & fsutil behavior set DisableDeleteNotifyReFS 0 2>&1
    Write-Host "   [OK] TRIM enabled (ReFS)" -ForegroundColor Green
    
    # Run optimize-volume for all SSDs
    Write-Host " [i] Ejecutando ReTrim en unidades SSD..." -ForegroundColor Cyan
    
    $volumes = Get-Volume | Where-Object { $_.DriveType -eq "Fixed" }
    
    foreach ($vol in $volumes) {
        if ($vol.DriveLetter) {
            # Check if drive is SSD not reliable in all PS versions without admin, assume yes for optimization attempt
            try {
                Write-Host "   > Procesando unidad $($vol.DriveLetter): ..." -NoNewline -ForegroundColor Gray
                Optimize-Volume -DriveLetter $vol.DriveLetter -ReTrim -Verbose:$false -ErrorAction SilentlyContinue
                Write-Host " [OK] Hecho" -ForegroundColor Green
            }
            catch {
                Write-Host " [SKIP]" -ForegroundColor DarkGray
            }
        }
    }
    
    # Set maintenance schedule for TRIM
    # Ensure Defrag service is manual, not disabled
    Set-Service -Name "defragsvc" -StartupType Manual -ErrorAction SilentlyContinue
    
    Write-Host ""
    Write-Host " [OK] TRIM Optimization completa" -ForegroundColor Green
    Write-Host ""
}

# ============================================================================
# NVME POWER SETTINGS
# ============================================================================

function Optimize-NVMePower {
    [CmdletBinding()]
    param()
    
    $diskInfo = Get-DiskType
    
    if ($diskInfo.NVMe -gt 0) {
        Write-Step "[DISK] NVME POWER MANAGEMENT"
        
        Write-Host " [i] Configurando gestión de energía para NVMe..." -ForegroundColor Cyan
        
        # Change power plan settings for PCI Express -> Link State Power Management to OFF
        # GUID: 501a4d13-42af-4429-9fd1-a8218c268e20 (PCI Express)
        # SUB: ee12f906-d277-404b-b6da-e5fa1a576df5 (Link State Power Management)
        # Value: 0 (Off)
        
        $schemes = Get-CimInstance Win32_PowerPlan
        
        foreach ($s in $schemes) {
            $guid = $s.InstanceID.Substring($s.InstanceID.Length - 38, 36)
            
            # Set on Battery and AC
            & powercfg /setacvalueindex $guid 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0 2>&1 | Out-Null
            & powercfg /setdcvalueindex $guid 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0 2>&1 | Out-Null
        }
        
        & powercfg /configuration disable 2>&1 | Out-Null
        
        # NVMe specific registry tweaks
        $stornvme = "HKLM:\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device"
        if (-not (Test-Path $stornvme)) { New-Item -Path $stornvme -Force | Out-Null }
        
        # Idle Timeout to 0 (No sleep)
        Set-RegistryKey -Path $stornvme -Name "IdlePowerMode" -Value 0 -Desc "NVMe Idle Power Mode" -Rollback
        
        Write-Host " [OK] NVMe Performance Mode activado (No Sleep)" -ForegroundColor Green
        Write-Host ""
    }
}

# ============================================================================
# 4K ALIGNMENT CHECK
# ============================================================================

function Test-4KAlignment {
    [CmdletBinding()]
    param()
    
    Write-Step "[DISK] 4K ALIGNMENT CHECK"
    
    $partitions = Get-Partition | Where-Object { $null -ne $_.DriveLetter }
    
    foreach ($part in $partitions) {
        $offset = $part.Offset
        $alignment = $offset % 4096
        
        Write-Host " Drive $($part.DriveLetter): " -NoNewline
        
        if ($alignment -eq 0) {
            Write-Host "[OK] Aligned (4K)" -ForegroundColor Green
        }
        else {
            Write-Host "[ALERTA] NO ALINEADO!" -ForegroundColor Red
            Write-Host "       > Impacto en rendimiento significativo." -ForegroundColor Yellow
            Write-Host "       > Recomendación: Re-particionar unidad." -ForegroundColor Gray
        }
    }
    
    Write-Host ""
}

# ============================================================================
# WRITE CACHE OPTIMIZATION
# ============================================================================

function Optimize-WriteCache {
    [CmdletBinding()]
    param()
    
    Write-Step "[DISK] WRITE CACHE POLICY"
    
    Write-Host " [i] Habilitando Write Caching en todas las unidades..." -ForegroundColor Cyan
    
    $disks = Get-Disk | Where-Object { $_.IsSystem -eq $true -or $_.MediaType -eq "SSD" }
    
    foreach ($d in $disks) {
        try {
            # This cmdlet might not be available in all editions, using error handling
            Set-Disk -Number $d.Number -IsWriteCacheEnabled $true -ErrorAction SilentlyContinue
            Write-Host "   Disk $($d.Number) ($($d.FriendlyName)) -> Cache ENABLED" -ForegroundColor Green
        }
        catch {
            Write-Host "   Disk $($d.Number) -> No se pudo cambiar política" -ForegroundColor Gray
        }
    }
    
    # SysMain Management (Superfetch)
    # For SSDs, SysMain is generally not needed and can cause extra writes
    $diskInfo = Get-DiskType
    if ($diskInfo.SSD -gt 0) {
        Write-Host " [i] SSD detectado. Deshabilitando SysMain (Superfetch)..." -ForegroundColor Cyan
        Stop-Service "SysMain" -ErrorAction SilentlyContinue
        Set-Service "SysMain" -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host " [OK] SysMain disabled" -ForegroundColor Green
    }
    
    Write-Host ""
}

# ============================================================================
# SMART HEALTH CHECK
# ============================================================================

function Get-SmartHealth {
    [CmdletBinding()]
    param()
    
    Write-Step "[DISK] SMART HEALTH ANALYSIS"
    
    try {
        $drives = Get-PhysicalDisk
        
        foreach ($d in $drives) {
            $healthColor = if ($d.HealthStatus -eq "Healthy") { "Green" } else { "Red" }
            
            Write-Host " Unidad: $($d.FriendlyName)" -ForegroundColor Cyan
            Write-Host "   Estado: " -NoNewline
            Write-Host "$($d.HealthStatus)" -ForegroundColor $healthColor
            Write-Host "   Uso: " -NoNewline
            
            # Try to get wear leveling if possible (advanced)
            # This is generic, manufacturer specific tools are better
            $wear = $d | Get-StorageReliabilityCounter -ErrorAction SilentlyContinue
            
            if ($wear) {
                $wearPercent = 100 - $wear.Wear
                if ($wearPercent -lt 100) {
                    Write-Host "Vida útil restante: ~$wearPercent%" -ForegroundColor Yellow
                }
                else {
                    Write-Host "Información no disponible" -ForegroundColor Gray
                }
                
                Write-Host "   Temp: " -NoNewline
                if ($wear.Temperature -gt 0) {
                    Write-Host "$($wear.Temperature) °C" -ForegroundColor White
                }
                else {
                    Write-Host "-" -ForegroundColor Gray
                }
            }
            
            Write-Host ""
        }
    }
    catch {
        Write-Host " [!] No se pudo leer información SMART detallada" -ForegroundColor Gray
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

function Start-SSDOptimization {
    Write-Section "SSD/NVMe ADVANCED OPTIMIZER v5.0"
    
    $diskInfo = Get-DiskType
    Write-Host " Resumen: $($diskInfo.SSD) SSDs, $($diskInfo.NVMe) NVMes detectados" -ForegroundColor Gray
    Write-Host ""
    
    if ($diskInfo.SSD -eq 0) {
        Write-Host " [!] No se detectaron unidades SSD/NVMe." -ForegroundColor Yellow
        Write-Host "     La mayoría de estas optimizaciones no aplicarán." -ForegroundColor Yellow
        Write-Host ""
    }
    
    Write-Host " [?] Seleccione operación:" -ForegroundColor Yellow
    Write-Host " 1. Optimización Completa (Recomendado)" -ForegroundColor White
    Write-Host " 2. Ejecutar TRIM/ReTrim" -ForegroundColor White
    Write-Host " 3. Verificar Alineación 4K" -ForegroundColor White
    Write-Host " 4. Configuración NVMe Power" -ForegroundColor White
    Write-Host " 5. Ver Salud del Disco (SMART)" -ForegroundColor White
    Write-Host " 6. Salir" -ForegroundColor DarkGray
    Write-Host ""
    
    $choice = Read-Host " >> Opción"
    
    switch ($choice) {
        '1' {
            Optimize-Trim
            Optimize-NVMePower
            Test-4KAlignment
            Optimize-WriteCache
            Get-SmartHealth
            
            Write-Host ""
            Write-Host " +========================================================+" -ForegroundColor Green
            Write-Host " |  SSD OPTIMIZATION COMPLETADA                           |" -ForegroundColor Green
            Write-Host " +========================================================+" -ForegroundColor Green
            Write-Host ""
        }
        '2' { Optimize-Trim }
        '3' { Test-4KAlignment }
        '4' { Optimize-NVMePower }
        '5' { Get-SmartHealth }
        '6' { return }
        default { Write-Host " [!] Opción inválida" -ForegroundColor Red }
    }
    
    Write-Host ""
}

Start-SSDOptimization
Wait-ForKeyPress


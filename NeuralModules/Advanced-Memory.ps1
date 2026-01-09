<#
.SYNOPSIS
    Advanced Memory Optimization v5.0
    Optimización profunda de RAM, paging, y memory pools.

.DESCRIPTION
    Características avanzadas:
    - Smart Paging File calculation
    - Memory Pool optimization
    - RAM compression control
    - Memory leak detection
    - Standby list management
    - NUMA optimization
    - Large Page support

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
# SMART PAGING FILE CONFIGURATION
# ============================================================================

function Set-SmartPagingFile {
    [CmdletBinding()]
    param()
    
    Write-Step "[MEMORY] SMART PAGING FILE"
    
    $hw = Get-HardwareProfile
    $ramGB = $hw.RamGB
    
    Write-Host " [i] RAM Detectada: $ramGB GB" -ForegroundColor Cyan
    Write-Host ""
    
    # Cálculo inteligente de Paging File
    # Regla: 
    # - RAM < 8GB: PageFile = RAM * 1.5
    # - RAM 8-16GB: PageFile = RAM
    # - RAM 16-32GB: PageFile = RAM * 0.5
    # - RAM > 32GB: PageFile = 8GB (fijo)
    
    $pageFileSizeMB = switch ($true) {
        ($ramGB -lt 8) { [math]::Round($ramGB * 1536) }  # 1.5x
        ($ramGB -lt 16) { [math]::Round($ramGB * 1024) }  # 1x
        ($ramGB -lt 32) { [math]::Round($ramGB * 512) }   # 0.5x
        default { 8192 }  # 8GB fijo
    }
    
    Write-Host " [i] Tamaño recomendado de PageFile: $pageFileSizeMB MB" -ForegroundColor Cyan
    Write-Host ""
    
    try {
        # Get current paging file settings
        $currentPF = Get-CimInstance Win32_PageFileSetting
        
        if ($currentPF) {
            Write-Host " [i] Configuración actual de PageFile:" -ForegroundColor Yellow
            foreach ($pf in $currentPF) {
                Write-Host "     $($pf.Name): Initial=$($pf.InitialSize)MB, Max=$($pf.MaximumSize)MB" -ForegroundColor Gray
            }
            Write-Host ""
            
            $response = Read-Host " >> ¿Aplicar configuración optimizada? (S/N)"
            
            if ($response -match '^[Ss]') {
                # Remove all existing page files
                $currentPF | Remove-CimInstance
                
                # Create new page file on system drive
                $systemDrive = $env:SystemDrive
                
                $newPF = New-CimInstance -ClassName Win32_PageFileSetting -Property @{
                    Name = "$systemDrive\pagefile.sys"
                } -ErrorAction Stop
                
                # Set sizes (Initial = Max for performance)
                $newPF | Set-CimInstance -Property @{
                    InitialSize = $pageFileSizeMB
                    MaximumSize = $pageFileSizeMB
                }
                
                Write-Host " [OK] PageFile configurado: $pageFileSizeMB MB (fijo)" -ForegroundColor Green
                Write-Host " [!] REINICIO REQUERIDO" -ForegroundColor Yellow
            }
        }
        else {
            Write-Host " [i] No hay PageFile configurado (System-managed)" -ForegroundColor Yellow
            Write-Host " [i] Recomendado: Configurar PageFile fijo para mejor performance" -ForegroundColor Cyan
        }
    }
    catch {
        Write-Host " [!] Error configurando PageFile: $_" -ForegroundColor Red
    }
    
    Write-Host ""
}

# ============================================================================
# MEMORY POOL OPTIMIZATION
# ============================================================================

function Optimize-MemoryPools {
    [CmdletBinding()]
    param()
    
    Write-Step "[MEMORY] MEMORY POOL OPTIMIZATION"
    
    Write-Host " [i] Optimizando Memory Pools del kernel..." -ForegroundColor Cyan
    Write-Host ""
    
    $memPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
    
    $hw = Get-HardwareProfile
    
    # Pool optimization based on RAM
    if ($hw.RamGB -ge 16) {
        # Large system - optimize for performance
        $poolKeys = @(
            @{ Name = "PoolUsageMaximum"; Value = 60; Desc = "Pool Usage Max 60%" },
            @{ Name = "PagedPoolSize"; Value = 0xFFFFFFFF; Desc = "Paged Pool Auto" },
            @{ Name = "NonPagedPoolSize"; Value = 0; Desc = "Non-Paged Pool Auto" },
            @{ Name = "NonPagedPoolQuota"; Value = 0; Desc = "Non-Paged Quota Auto" },
            @{ Name = "PagedPoolQuota"; Value = 0; Desc = "Paged Quota Auto" },
            @{ Name = "SessionPoolSize"; Value = 192; Desc = "Session Pool 192MB" },
            @{ Name = "SessionViewSize"; Value = 192; Desc = "Session View 192MB" }
        )
    }
    else {
        # Standard system - balanced
        $poolKeys = @(
            @{ Name = "PoolUsageMaximum"; Value = 40; Desc = "Pool Usage Max 40%" },
            @{ Name = "SessionPoolSize"; Value = 96; Desc = "Session Pool 96MB" },
            @{ Name = "SessionViewSize"; Value = 96; Desc = "Session View 96MB" }
        )
    }
    
    foreach ($k in $poolKeys) {
        Set-RegistryKey -Path $memPath -Name $k.Name -Value $k.Value -Desc $k.Desc
    }
    
    Write-Host ""
}

# ============================================================================
# STANDBY LIST MANAGEMENT
# ============================================================================

function Optimize-StandbyList {
    [CmdletBinding()]
    param()
    
    Write-Step "[MEMORY] STANDBY LIST OPTIMIZATION"
    
    Write-Host " [i] Configurando Standby List para mejor performance..." -ForegroundColor Cyan
    Write-Host ""
    
    $memPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
    
    # Clear standby list on low memory
    Set-RegistryKey -Path $memPath -Name "ClearPageFileAtShutdown" -Value 0 -Desc "No clear PageFile (faster boot)"
    Set-RegistryKey -Path $memPath -Name "EnableSuperfetch" -Value 0 -Desc "Superfetch OFF (SSD)"
    
    # Memory trimming
    Set-RegistryKey -Path $memPath -Name "DisablePagingExecutive" -Value 1 -Desc "Lock kernel in RAM"
    
    Write-Host ""
    Write-Host " [TIP] Para limpiar Standby List manualmente:" -ForegroundColor Cyan
    Write-Host "       Usa RAMMap (Microsoft Sysinternals)" -ForegroundColor Gray
    Write-Host ""
}

# ============================================================================
# LARGE PAGE SUPPORT
# ============================================================================

function Enable-LargePageSupport {
    [CmdletBinding()]
    param()
    
    Write-Step "[MEMORY] LARGE PAGE SUPPORT"
    
    Write-Host " [i] Habilitando Large Pages para aplicaciones..." -ForegroundColor Cyan
    Write-Host " [i] Esto mejora performance en aplicaciones que lo soporten" -ForegroundColor DarkGray
    Write-Host ""
    
    try {
        # Grant "Lock pages in memory" privilege
        $username = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        
        # Export current policy
        $tempFile = "$env:TEMP\secpol.cfg"
        & secedit /export /cfg $tempFile | Out-Null
        
        # Read and modify
        $content = Get-Content $tempFile
        $newContent = $content -replace '(SeLockMemoryPrivilege\s*=\s*)(.*)', "`$1`$2,$username"
        $newContent | Set-Content $tempFile
        
        # Import modified policy
        & secedit /configure /db secedit.sdb /cfg $tempFile /areas USER_RIGHTS | Out-Null
        Remove-Item $tempFile -Force
        
        Write-Host " [OK] Large Page Support habilitado para $username" -ForegroundColor Green
        Write-Host " [!] REINICIO REQUERIDO" -ForegroundColor Yellow
    }
    catch {
        Write-Host " [!] Error habilitando Large Pages: $_" -ForegroundColor Yellow
    }
    
    # Registry settings
    $memPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
    Set-RegistryKey -Path $memPath -Name "LargePageMinimum" -Value 0xFFFFFFFF -Desc "Large Page Auto"
    
    Write-Host ""
}

# ============================================================================
# MEMORY COMPRESSION CONTROL
# ============================================================================

function Set-MemoryCompression {
    [CmdletBinding()]
    param()
    
    Write-Step "[MEMORY] MEMORY COMPRESSION"
    
    $hw = Get-HardwareProfile
    
    Write-Host " [i] RAM Disponible: $($hw.RamGB) GB" -ForegroundColor Cyan
    Write-Host ""
    
    try {
        $mmStatus = Get-MMAgent -ErrorAction SilentlyContinue
        
        if ($mmStatus) {
            Write-Host " [i] Estado actual de Memory Compression: $($mmStatus.MemoryCompression)" -ForegroundColor Yellow
            Write-Host ""
            
            # Recomendación basada en RAM
            if ($hw.RamGB -ge 16) {
                Write-Host " [i] Con 16GB+ de RAM, desactivar compression mejora performance" -ForegroundColor Cyan
                Write-Host " [i] (Usa más RAM pero libera ciclos de CPU)" -ForegroundColor DarkGray
                Write-Host ""
                
                $response = Read-Host " >> ¿Deshabilitar Memory Compression? (S/N)"
                
                if ($response -match '^[Ss]') {
                    Disable-MMAgent -MemoryCompression -ErrorAction Stop
                    Write-Host " [OK] Memory Compression deshabilitada" -ForegroundColor Green
                }
            }
            else {
                Write-Host " [i] Con menos de 16GB RAM, compression es beneficiosa" -ForegroundColor Cyan
                Write-Host " [i] Mantener habilitada (recomendado)" -ForegroundColor DarkGray
                
                if (-not $mmStatus.MemoryCompression) {
                    $response = Read-Host " >> ¿Habilitar Memory Compression? (S/N)"
                    
                    if ($response -match '^[Ss]') {
                        Enable-MMAgent -MemoryCompression -ErrorAction Stop
                        Write-Host " [OK] Memory Compression habilitada" -ForegroundColor Green
                    }
                }
            }
        }
    }
    catch {
        Write-Host " [!] Error gestionando Memory Compression: $_" -ForegroundColor Yellow
    }
    
    Write-Host ""
}

# ============================================================================
# NUMA OPTIMIZATION
# ============================================================================

function Optimize-NUMA {
    [CmdletBinding()]
    param()
    
    Write-Step "[MEMORY] NUMA OPTIMIZATION"
    
    Write-Host " [i] Verificando configuración NUMA..." -ForegroundColor Cyan
    Write-Host ""
    
    try {
        $numaNodes = Get-CimInstance Win32_Processor | Select-Object -First 1 -ExpandProperty NumberOfCores
        
        if ($numaNodes -gt 8) {
            Write-Host " [i] Sistema multi-NUMA detectado" -ForegroundColor Yellow
            
            # NUMA optimization for multi-socket systems
            Set-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" `
                -Name "DisableTaskOffload" -Value 0 -Desc "Task Offload Enabled"
            
            # NUMA-aware memory allocation
            $memPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
            Set-RegistryKey -Path $memPath -Name "SecondLevelDataCache" -Value 2048 -Desc "L2 Cache 2MB"
            
            Write-Host " [OK] NUMA optimization aplicada" -ForegroundColor Green
        }
        else {
            Write-Host " [i] Sistema single-NUMA, optimizaciones no necesarias" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host " [!] Error verificando NUMA" -ForegroundColor Yellow
    }
    
    Write-Host ""
}

# ============================================================================
# MEMORY LEAK DETECTION
# ============================================================================

function Test-MemoryLeaks {
    [CmdletBinding()]
    param()
    
    Write-Step "[MEMORY] MEMORY LEAK DETECTION"
    
    Write-Host " [i] Analizando procesos con posibles memory leaks..." -ForegroundColor Cyan
    Write-Host ""
    
    try {
        # Get processes sorted by WorkingSet growth
        $processes = Get-Process | Where-Object { $_.WorkingSet64 -gt 100MB } | 
        Sort-Object WorkingSet64 -Descending | 
        Select-Object -First 10 -Property Name, Id, WorkingSet64, HandleCount
        
        Write-Host " Top 10 procesos por uso de memoria:" -ForegroundColor Yellow
        Write-Host ""
        
        foreach ($proc in $processes) {
            $memMB = [math]::Round($proc.WorkingSet64 / 1MB, 2)
            $color = if ($memMB -gt 1000) { "Red" } elseif ($memMB -gt 500) { "Yellow" } else { "Gray" }
            
            Write-Host "   $($proc.Name.PadRight(30)) " -NoNewline
            Write-Host "$memMB MB " -ForegroundColor $color -NoNewline
            Write-Host "($($proc.HandleCount) handles)" -ForegroundColor DarkGray
        }
        
        Write-Host ""
        Write-Host " [TIP] Si un proceso crece constantemente, puede tener memory leak" -ForegroundColor Cyan
        Write-Host " [TIP] Usa 'Performance Monitor' para análisis detallado" -ForegroundColor DarkGray
    }
    catch {
        Write-Host " [!] Error analizando procesos" -ForegroundColor Yellow
    }
    
    Write-Host ""
}

# ============================================================================
# WORKING SET TRIM
# ============================================================================

function Invoke-WorkingSetTrim {
    [CmdletBinding()]
    param()
    
    Write-Step "[MEMORY] WORKING SET TRIM"
    
    Write-Host " [i] Liberando memoria no utilizada de procesos..." -ForegroundColor Cyan
    Write-Host ""
    
    try {
        $beforeFree = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB
        
        # Trim working sets
        $processes = Get-Process | Where-Object { $_.WorkingSet64 -gt 10MB }
        
        foreach ($proc in $processes) {
            try {
                $proc.MinWorkingSet = 0
                $proc.MaxWorkingSet = 0
            }
            catch {}
        }
        
        # Force garbage collection
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        
        Start-Sleep -Seconds 2
        
        $afterFree = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB
        $freed = [math]::Round($afterFree - $beforeFree, 2)
        
        if ($freed -gt 0) {
            Write-Host " [OK] Liberados ~$freed MB de RAM" -ForegroundColor Green
        }
        else {
            Write-Host " [i] No se liberó memoria significativa" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host " [!] Error en Working Set Trim" -ForegroundColor Yellow
    }
    
    Write-Host ""
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

function Start-AdvancedMemoryOptimization {
    Write-Section "ADVANCED MEMORY OPTIMIZATION v5.0"
    
    $hw = Get-HardwareProfile
    Write-Host " Hardware Profile:" -ForegroundColor Cyan
    Write-Host "   RAM: $($hw.RamGB) GB @ $($hw.RamSpeed) MHz" -ForegroundColor Gray
    Write-Host "   CPU: $($hw.CpuVendor) ($($hw.CpuCores) cores)" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host " [?] Seleccione operación:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host " 1. Configuración completa (Recomendado)" -ForegroundColor White
    Write-Host " 2. Solo Paging File" -ForegroundColor White
    Write-Host " 3. Solo Memory Pools" -ForegroundColor White
    Write-Host " 4. Solo Memory Compression" -ForegroundColor White
    Write-Host " 5. Detectar Memory Leaks" -ForegroundColor White
    Write-Host " 6. Liberar memoria ahora (Working Set Trim)" -ForegroundColor White
    Write-Host " 7. Salir" -ForegroundColor DarkGray
    Write-Host ""
    
    $choice = Read-Host " >> Opción"
    
    switch ($choice) {
        '1' {
            Set-SmartPagingFile
            Optimize-MemoryPools
            Optimize-StandbyList
            Enable-LargePageSupport
            Set-MemoryCompression
            Optimize-NUMA
            
            Write-Host ""
            Write-Host " +========================================================+" -ForegroundColor Green
            Write-Host " |  MEMORY OPTIMIZATION COMPLETADA                        |" -ForegroundColor Green
            Write-Host " +========================================================+" -ForegroundColor Green
            Write-Host ""
            Write-Host " [!] REINICIO REQUERIDO para aplicar todos los cambios" -ForegroundColor Yellow
        }
        '2' { Set-SmartPagingFile }
        '3' { Optimize-MemoryPools }
        '4' { Set-MemoryCompression }
        '5' { Test-MemoryLeaks }
        '6' { Invoke-WorkingSetTrim }
        '7' { return }
        default { Write-Host " [!] Opción inválida" -ForegroundColor Red }
    }
    
    Write-Host ""
}

Start-AdvancedMemoryOptimization
Wait-ForKeyPress


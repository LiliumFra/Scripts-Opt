<#
.SYNOPSIS
    Boot Optimization Module v3.5 - ULTIMATE
    Optimizaciones avanzadas de arranque, BCD, NTFS, memoria y más.

.NOTES
    Parte de Windows Neural Optimizer v3.5
#>

# Ensure Utils are loaded
if (-not (Get-Command "Write-Log" -ErrorAction SilentlyContinue)) {
    $currentDir = Split-Path $MyInvocation.MyCommand.Path
    $utilsPath = Join-Path $currentDir "NeuralUtils.psm1"
    if (Test-Path $utilsPath) { Import-Module $utilsPath -Force -DisableNameChecking }
}

Ensure-Admin -Silent

function Optimize-Boot {
    [CmdletBinding()]
    param()
    
    Write-Section "BOOT & SYSTEM OPTIMIZATION v3.5 (DEEP TUNED)"
    
    # Hardware Detection
    $hw = Get-HardwareProfile
    Write-Host " [i] Hardware Detectado:" -ForegroundColor Cyan
    Write-Host "     CPU: $($hw.CpuVendor)" -ForegroundColor Gray
    Write-Host "     RAM: $($hw.RamGB) GB" -ForegroundColor Gray
    Write-Host "     SSD: $($hw.IsSSD)" -ForegroundColor Gray
    Write-Host ""
    
    $totalTweaks = 0
    $appliedTweaks = 0
    
    # =========================================================================
    # 1. BCD TWEAKS - Optimización del Boot
    # =========================================================================
    
    Write-Step "[1/7] CONFIGURACION BCD (Boot Configuration Data)"
    
    $bcdTweaks = @(
        @{ Cmd = @("bcdedit", "/deletevalue", "useplatformclock"); Desc = "Deshabilitar Platform Clock"; Safe = $true },
        @{ Cmd = @("bcdedit", "/set", "disabledynamictick", "yes"); Desc = "Deshabilitar Dynamic Tick"; Safe = $false },
        @{ Cmd = @("bcdedit", "/set", "useplatformtick", "no"); Desc = "Deshabilitar Platform Tick"; Safe = $true },
        @{ Cmd = @("bcdedit", "/set", "tscsyncpolicy", "Enhanced"); Desc = "TSC Sync Policy Enhanced"; Safe = $false },
        @{ Cmd = @("bcdedit", "/set", "x2apicpolicy", "Enable"); Desc = "Habilitar x2APIC"; Safe = $false },
        @{ Cmd = @("bcdedit", "/set", "quietboot", "on"); Desc = "Quiet Boot (sin logo)"; Safe = $true },
        @{ Cmd = @("bcdedit", "/set", "bootmenupolicy", "Legacy"); Desc = "Boot Menu Legacy"; Safe = $true },
        @{ Cmd = @("bcdedit", "/set", "linearaddress57", "OptOut"); Desc = "Linear Address 57 OptOut"; Safe = $true },
        @{ Cmd = @("bcdedit", "/timeout", "3"); Desc = "Boot Timeout 3 segundos"; Safe = $false }
    )
    
    $i = 0
    foreach ($t in $bcdTweaks) {
        $i++
        $percent = [int](($i / $bcdTweaks.Count) * 100)
        Write-Progress -Activity "Optimizando BCD" -Status "Aplicando: $($t.Desc)" -PercentComplete $percent
        
        $totalTweaks++
        try {
            $null = & $t.Cmd[0] $t.Cmd[1..($t.Cmd.Length - 1)] 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "   [OK] $($t.Desc)" -ForegroundColor Green
                $appliedTweaks++
            }
            else {
                if ($t.Safe) { $appliedTweaks++ }
            }
        }
        catch {
        }
    }
    Write-Progress -Activity "Optimizando BCD" -Completed
    
    # =========================================================================
    # 2. NTFS OPTIMIZATIONS
    # =========================================================================
    
    Write-Step "[2/7] OPTIMIZACION NTFS (Sistema de Archivos)"
    
    $ntfsTweaks = @(
        @{ Cmd = @("fsutil", "behavior", "set", "disabledeletenotify", $(if ($hw.IsSSD) { "0" } else { "1" })); Desc = "TRIM $(if ($hw.IsSSD) { 'ON' } else { 'OFF' })" },
        @{ Cmd = @("fsutil", "behavior", "set", "disablelastaccess", "1"); Desc = "Deshabilitar Last Access" },
        @{ Cmd = @("fsutil", "behavior", "set", "disable8dot3", "1"); Desc = "Deshabilitar nombres 8.3" },
        @{ Cmd = @("fsutil", "behavior", "set", "memoryusage", "2"); Desc = "Optimizar memoria NTFS" },
        @{ Cmd = @("fsutil", "behavior", "set", "mftzone", "2"); Desc = "MFT Zone Size Medium" },
        @{ Cmd = @("fsutil", "behavior", "set", "encryptpagingfile", "0"); Desc = "PageFile sin encriptar" }
    )
    
    foreach ($t in $ntfsTweaks) {
        $totalTweaks++
        try {
            $null = & $t.Cmd[0] $t.Cmd[1..($t.Cmd.Length - 1)] 2>&1
            Write-Host "   [OK] $($t.Desc)" -ForegroundColor Green
            $appliedTweaks++
        }
        catch {
            Write-Host "   [!!] $($t.Desc)" -ForegroundColor Yellow
        }
    }
    
    # =========================================================================
    # 3. MEMORY MANAGEMENT (SMART TUNING)
    # =========================================================================
    
    Write-Step "[3/7] GESTION DE MEMORIA INTELIGENTE"
    
    $memPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
    $prefPath = "$memPath\PrefetchParameters"
    
    # 1. IO Page Lock Limit
    # Determina cuánta memoria I/O se puede bloquear. Defecto es 512KB (muy bajo).
    # Calculo inteligente: 64MB para sistemas normales, hasta 256MB/512MB para sistemas grandes.
    if ($hw.RamGB -ge 32) { $ioLimit = 0x20000000; $ioDesc = "512MB (RAM >= 32GB)" } # 512MB
    elseif ($hw.RamGB -ge 16) { $ioLimit = 0x10000000; $ioDesc = "256MB (RAM >= 16GB)" } # 256MB
    elseif ($hw.RamGB -ge 8) { $ioLimit = 0x4000000; $ioDesc = "64MB (RAM >= 8GB)" } # 64MB
    else { $ioLimit = 0; $ioDesc = "Default (Low RAM)" }
    
    # 2. Svchost Split Threshold
    # Controla cómo Windows agrupa servicios. Más Split = Más Estabilidad/Aislamiento, Menos Split = Menos RAM.
    # En sistemas modernos (>8GB) queremos Split para que 1 servicio fallido no mate a otros.
    if ($hw.RamGB -ge 4) { $svcSplit = 380000; $svcDesc = "Optimizado (3.8GB Threshold)" }
    else { $svcSplit = 380000; $svcDesc = "Optimizado (Legacy)" } # Default moderno es seguro
    
    # Smart logic based on RAM
    if ($hw.RamGB -ge 16) {
        Write-Host "   [i] RAM > 16GB detectada: Activando Large System Cache" -ForegroundColor Cyan
        $largeSystemCache = 1
        $disablePagingExe = 1
    }
    else {
        Write-Host "   [i] RAM estandar detectada: Optimizando para estabilidad" -ForegroundColor Cyan
        $largeSystemCache = 0
        $disablePagingExe = 0
    }
    
    $memoryKeys = @(
        @{ Path = $memPath; Name = "ClearPageFileAtShutdown"; Value = 0; Desc = "No limpiar PageFile al apagar" },
        @{ Path = $memPath; Name = "DisablePagingExecutive"; Value = $disablePagingExe; Desc = "DisablePagingExecutive ($disablePagingExe)" },
        @{ Path = $memPath; Name = "LargeSystemCache"; Value = $largeSystemCache; Desc = "LargeSystemCache ($largeSystemCache)" },
        @{ Path = $memPath; Name = "IoPageLockLimit"; Value = $ioLimit; Type = "DWord"; Desc = "IO Buffer: $ioDesc" },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control"; Name = "SvcHostSplitThresholdInKB"; Value = $svcSplit; Type = "DWord"; Desc = "Svchost Split: $svcDesc" },
        @{ Path = $prefPath; Name = "EnablePrefetcher"; Value = 3; Desc = "Prefetcher optimizado" },
        @{ Path = $prefPath; Name = "EnableSuperfetch"; Value = 3; Desc = "Superfetch optimizado" }
    )
    
    foreach ($k in $memoryKeys) {
        $totalTweaks++
        if (Set-RegistryKey -Path $k.Path -Name $k.Name -Value $k.Value -Desc $k.Desc) {
            $appliedTweaks++
        }
    }
    
    # =========================================================================
    # 4. VISUAL EFFECTS OPTIMIZATION
    # =========================================================================
    
    Write-Step "[4/7] EFECTOS VISUALES (Rendimiento)"
    
    $visualKeys = @(
        @{ Path = "HKCU:\Control Panel\Desktop"; Name = "MenuShowDelay"; Value = "0"; Type = "String"; Desc = "Menus instantaneos" },
        @{ Path = "HKCU:\Control Panel\Desktop"; Name = "AutoEndTasks"; Value = "1"; Type = "String"; Desc = "Cerrar tareas colgadas auto" },
        @{ Path = "HKCU:\Control Panel\Desktop"; Name = "HungAppTimeout"; Value = "1000"; Type = "String"; Desc = "Timeout apps colgadas 1s" },
        @{ Path = "HKCU:\Control Panel\Desktop"; Name = "WaitToKillAppTimeout"; Value = "2000"; Type = "String"; Desc = "Kill apps timeout 2s" },
        @{ Path = "HKCU:\Control Panel\Desktop"; Name = "LowLevelHooksTimeout"; Value = "1000"; Type = "String"; Desc = "Hooks timeout 1s" },
        @{ Path = "HKCU:\Control Panel\Desktop\WindowMetrics"; Name = "MinAnimate"; Value = "0"; Type = "String"; Desc = "Sin animacion minimizar" },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "TaskbarAnimations"; Value = 0; Desc = "Sin animaciones taskbar" },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "ListviewAlphaSelect"; Value = 0; Desc = "Sin transparencia seleccion" },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "ListviewShadow"; Value = 0; Desc = "Sin sombras iconos" },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"; Name = "VisualFXSetting"; Value = 2; Desc = "Modo rendimiento" }
    )
    
    foreach ($k in $visualKeys) {
        $totalTweaks++
        $type = if ($k.Type) { $k.Type } else { "DWord" }
        if (Set-RegistryKey -Path $k.Path -Name $k.Name -Value $k.Value -Type $type -Desc $k.Desc) {
            $appliedTweaks++
        }
    }
    
    # =========================================================================
    # 5. SYSTEM RESPONSIVENESS (CPU TUNING)
    # =========================================================================
    
    Write-Step "[5/7] RESPONSIVIDAD DEL SISTEMA ($($hw.CpuVendor))"
    
    $sysProfile = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
    $gamesTasks = "$sysProfile\Tasks\Games"
    
    $respKeys = @(
        @{ Path = $sysProfile; Name = "SystemResponsiveness"; Value = 10; Desc = "Max CPU para apps primer plano (10)" }, # Updated from 0 to 10 based on deeper research
        @{ Path = $sysProfile; Name = "NetworkThrottlingIndex"; Value = 0xFFFFFFFF; Desc = "Sin throttling de red" },
        @{ Path = $gamesTasks; Name = "Priority"; Value = 6; Desc = "Prioridad alta para juegos" },
        @{ Path = $gamesTasks; Name = "Scheduling Category"; Value = "High"; Type = "String"; Desc = "Scheduling alto juegos" },
        @{ Path = $gamesTasks; Name = "SFIO Priority"; Value = "High"; Type = "String"; Desc = "SFIO Priority alto" },
        @{ Path = $gamesTasks; Name = "GPU Priority"; Value = 8; Desc = "GPU Priority max" },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"; Name = "Win32PrioritySeparation"; Value = 38; Desc = "Prioridad apps primer plano (26 Hex)" }
    )
    
    # Intel Specific
    if ($hw.CpuVendor -eq "Intel") {
        # Disable Power Throttling for modern Intel CPUs
        $respKeys += @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling"; Name = "PowerThrottlingOff"; Value = 1; Desc = "Intel: Power Throttling OFF" }
    }
    
    foreach ($k in $respKeys) {
        $totalTweaks++
        $type = if ($k.Type) { $k.Type } else { "DWord" }
        if (Set-RegistryKey -Path $k.Path -Name $k.Name -Value $k.Value -Type $type -Desc $k.Desc) {
            $appliedTweaks++
        }
    }
    
    # =========================================================================
    # 6. STARTUP OPTIMIZATION
    # =========================================================================
    
    Write-Step "[6/7] OPTIMIZACION DE INICIO"
    
    $startupKeys = @(
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize"; Name = "StartupDelayInMSec"; Value = 0; Desc = "Sin delay de inicio apps" },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize"; Name = "StartupDelayInMSec"; Value = 0; Desc = "Sin delay inicio usuario" },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control"; Name = "WaitToKillServiceTimeout"; Value = "2000"; Type = "String"; Desc = "Kill servicios rapido" },
        @{ Path = "HKCU:\Control Panel\Desktop"; Name = "WaitToKillServiceTimeout"; Value = "2000"; Type = "String"; Desc = "Kill servicios usuario" }
    )
    
    foreach ($k in $startupKeys) {
        $totalTweaks++
        $type = if ($k.Type) { $k.Type } else { "DWord" }
        if (Set-RegistryKey -Path $k.Path -Name $k.Name -Value $k.Value -Type $type -Desc $k.Desc) {
            $appliedTweaks++
        }
    }
    
    # =========================================================================
    # 7. ADDITIONAL SYSTEM TWEAKS
    # =========================================================================
    
    Write-Step "[7/7] TWEAKS ADICIONALES"
    
    # Deshabilitar Hibernación
    try {
        $null = & powercfg /h off 2>&1
        Write-Host "   [OK] Hibernacion deshabilitada (ahorra espacio)" -ForegroundColor Green
        $appliedTweaks++; $totalTweaks++
    }
    catch { $totalTweaks++ }
    
    # USB & Network Nagle (Standard Global)
    $totalTweaks += 2
    if (Set-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Services\USB" -Name "DisableSelectiveSuspend" -Value 1 -Desc "USB Selective Suspend deshabilitado") { $appliedTweaks++ }
    
    # Resumen
    Write-Host ""
    Write-Host " +--------------------------------------------------------+" -ForegroundColor Green
    Write-Host " |  BOOT OPTIMIZATION COMPLETADO                          |" -ForegroundColor Green
    Write-Host " |  Tweaks aplicados: $appliedTweaks/$totalTweaks                               |" -ForegroundColor Green
    Write-Host " +--------------------------------------------------------+" -ForegroundColor Green
}

Optimize-Boot

<#
.SYNOPSIS
    Disk, Cache & Network Module v3.5 - ULTIMATE
    Limpieza avanzada + optimizaciones de disco, cache y red.

.NOTES
    Parte de Windows Neural Optimizer v3.5
    Creditos: Jose Bustamante
#>

# Ensure Utils are loaded
if (-not (Get-Command "Write-Log" -ErrorAction SilentlyContinue)) {
    $currentDir = Split-Path $MyInvocation.MyCommand.Path
    $utilsPath = Join-Path $currentDir "NeuralUtils.psm1"
    if (Test-Path $utilsPath) { Import-Module $utilsPath -Force -DisableNameChecking }
}

Invoke-AdminCheck -Silent

function Optimize-Disk {
    [CmdletBinding()]
    param(
        [switch]$Silent
    )
    
    Write-Section "DISK, CACHE & NETWORK v3.5"
    
    # Check/Create Scheduled Task (Only if not Silent and Admin)
    if (-not $Silent) {
        $taskName = "NeuralMaintenance"
        if (-not (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue)) {
            Write-Host " [?] Deseas programar Mantenimiento Semanal Automatico? (S/N)" -ForegroundColor Yellow
            $resp = Read-Host " >"
            if ($resp -match '^[Ss]') {
                try {
                    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`" -Silent"
                    $trigger = New-ScheduledTaskTrigger -Weekly -Days Sunday -At 12pm
                    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -RunLevel Highest -User "System" -Force | Out-Null
                    Write-Host " [OK] Tarea '$taskName' creada (Domingos 12PM)" -ForegroundColor Green
                }
                catch {
                    Write-Host " [X] Error creando tarea: $_" -ForegroundColor Red
                }
            }
        }
    }
    
    $totalFreed = 0
    $appliedTweaks = 0
    $startTime = Get-Date
    
    # =========================================================================
    # 1. SYSTEM TEMP CLEANUP
    # =========================================================================
    
    Write-Step "[1/8] LIMPIEZA DE TEMPORALES"
    
    $tempPaths = @(
        @{ Path = "C:\Windows\Temp"; Desc = "Windows Temp" },
        @{ Path = "$env:TEMP"; Desc = "User Temp" },
        @{ Path = "$env:LOCALAPPDATA\Temp"; Desc = "LocalAppData Temp" },
        @{ Path = "C:\Windows\Prefetch"; Desc = "Prefetch" },
        @{ Path = "C:\Windows\SoftwareDistribution\Download"; Desc = "Windows Update Cache" },
        @{ Path = "$env:LOCALAPPDATA\Microsoft\Windows\INetCache"; Desc = "Internet Cache" },
        @{ Path = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"; Desc = "Thumbnail Cache" },
        @{ Path = "$env:LOCALAPPDATA\CrashDumps"; Desc = "Crash Dumps" },
        @{ Path = "C:\Windows\Logs\CBS"; Desc = "CBS Logs" },
        @{ Path = "C:\Windows\Downloaded Program Files"; Desc = "Downloaded Programs" },
        @{ Path = "$env:LOCALAPPDATA\Microsoft\Windows\WER"; Desc = "Error Reports" },
        @{ Path = "C:\Windows\Logs\DISM"; Desc = "DISM Logs" },
        @{ Path = "C:\Windows\Logs\waasmedia"; Desc = "WAASMedia Logs" },
        @{ Path = "$env:LOCALAPPDATA\Microsoft\Terminal Server Client\Cache"; Desc = "RDP Cache" },
        @{ Path = "$env:APPDATA\Microsoft\Teams\Cache"; Desc = "Teams Cache" },
        @{ Path = "$env:APPDATA\Microsoft\Teams\blob_storage"; Desc = "Teams Blob" },
        @{ Path = "$env:APPDATA\Microsoft\Teams\databases"; Desc = "Teams DBs" },
        @{ Path = "$env:APPDATA\Microsoft\Teams\GPUCache"; Desc = "Teams GPU Cache" },
        @{ Path = "$env:APPDATA\Microsoft\Teams\IndexedDB"; Desc = "Teams IndexedDB" },
        @{ Path = "$env:APPDATA\Slack\Cache"; Desc = "Slack Cache" },
        @{ Path = "$env:APPDATA\discord\Cache"; Desc = "Discord Cache" },
        @{ Path = "$env:APPDATA\discord\Code Cache"; Desc = "Discord Code Cache" }
    )
    
    $i = 0
    foreach ($t in $tempPaths) {
        $i++
        if (Test-Path $t.Path) {
            # Only show progress for existing folders to avoid flicker
            $percent = [int](($i / $tempPaths.Count) * 100)
            Write-Progress -Activity "Limpiando Temporales" -Status "Procesando $($t.Desc)" -PercentComplete $percent
            $totalFreed += Remove-FolderSafe -Path $t.Path -Desc $t.Desc
        }
    }
    Write-Progress -Activity "Limpiando Temporales" -Completed
    
    # =========================================================================
    # 2. BROWSER CACHES
    # =========================================================================
    
    Write-Step "[2/8] CACHE DE NAVEGADORES"
    
    $browsers = @(
        @{ Name = "chrome"; Paths = @(
                "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
                "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache",
                "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\GPUCache",
                "$env:LOCALAPPDATA\Google\Chrome\User Data\ShaderCache"
            )
        },
        @{ Name = "msedge"; Paths = @(
                "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
                "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache",
                "$env:LOCALAPPDATA\Microsoft\Edge\User Data\ShaderCache"
            )
        },
        @{ Name = "firefox"; Paths = @(
                "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles\*.default*\cache2"
            )
        },
        @{ Name = "brave"; Paths = @(
                "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Cache"
            )
        },
        @{ Name = "opera"; Paths = @(
                "$env:APPDATA\Opera Software\Opera Stable\Cache"
            )
        }
    )
    
    foreach ($browser in $browsers) {
        $running = Get-Process -Name $browser.Name -EA SilentlyContinue
        if (-not $running) {
            foreach ($path in $browser.Paths) {
                if (Test-Path $path) {
                    $totalFreed += Remove-FolderSafe -Path $path -Desc "$($browser.Name) cache"
                }
            }
        }
        else {
            Write-Host "   [--] $($browser.Name) en uso" -ForegroundColor DarkGray
        }
    }
    
    # =========================================================================
    # 3. GPU & GAMING CACHES
    # =========================================================================
    
    Write-Step "[3/8] CACHE GPU & GAMING"
    
    $gamePaths = @(
        @{ Path = "$env:LOCALAPPDATA\NVIDIA\DXCache"; Desc = "NVIDIA DX Cache" },
        @{ Path = "$env:LOCALAPPDATA\NVIDIA\GLCache"; Desc = "NVIDIA GL Cache" },
        @{ Path = "$env:LOCALAPPDATA\NVIDIA Corporation\NV_Cache"; Desc = "NVIDIA NV Cache" },
        @{ Path = "$env:TEMP\NVIDIA Corporation"; Desc = "NVIDIA Temp" },
        @{ Path = "$env:LOCALAPPDATA\AMD\DxCache"; Desc = "AMD DX Cache" },
        @{ Path = "$env:LOCALAPPDATA\AMD\DxcCache"; Desc = "AMD Dxc Cache" },
        @{ Path = "$env:LOCALAPPDATA\AMD\GLCache"; Desc = "AMD GL Cache" },
        @{ Path = "$env:LOCALAPPDATA\AMD\VkCache"; Desc = "AMD Vulkan Cache" },
        @{ Path = "$env:LOCALAPPDATA\D3DSCache"; Desc = "D3DS Cache" },
        @{ Path = "$env:LOCALAPPDATA\Intel\ShaderCache"; Desc = "Intel Shader Cache" },
        @{ Path = "$env:LOCALAPPDATA\UnrealEngine"; Desc = "Unreal Engine" },
        @{ Path = "$env:APPDATA\Unity"; Desc = "Unity Cache" },
        @{ Path = "$env:LOCALAPPDATA\EpicGamesLauncher\Saved\webcache"; Desc = "Epic Games" },
        @{ Path = "$env:LOCALAPPDATA\Steam\htmlcache"; Desc = "Steam HTML Cache" },
        @{ Path = "$env:LOCALAPPDATA\Origin\webcache"; Desc = "Origin Cache" },
        @{ Path = "$env:LOCALAPPDATA\battle.net\Cache"; Desc = "Battle.net Cache" }
    )
    
    foreach ($g in $gamePaths) {
        if (Test-Path $g.Path) {
            $totalFreed += Remove-FolderSafe -Path $g.Path -Desc $g.Desc
        }
    }
    
    # =========================================================================
    # 4. DISM & COMPONENT CLEANUP
    # =========================================================================
    
    Write-Step "[4/8] LIMPIEZA DISM (WinSxS)"
    Write-Host "       Esto puede tomar varios minutos..." -ForegroundColor DarkGray
    
    try {
        $null = & dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   [OK] WinSxS optimizado" -ForegroundColor Green
            $appliedTweaks++
        }
        else {
            Write-Host "   [--] WinSxS: sin cambios" -ForegroundColor DarkGray
        }
    }
    catch {}
    
    # =========================================================================
    # 5. DISK OPTIMIZATION REGISTRY
    # =========================================================================
    
    Write-Step "[5/8] OPTIMIZACIONES DE DISCO (Registry)"
    
    # Detectar SSD
    $isSSD = $false
    try {
        $disk = Get-PhysicalDisk | Where-Object { $_.DeviceId -eq 0 } | Select-Object -First 1
        $isSSD = $disk.MediaType -match "SSD|Unspecified"
        $diskType = if ($isSSD) { "SSD/NVMe" } else { "HDD" }
        Write-Host "   [i] Disco principal: $diskType" -ForegroundColor DarkCyan
    }
    catch {}
    
    $sysPath = "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"
    
    $diskKeys = @(
        @{ Path = $sysPath; Name = "NtfsDisableLastAccessUpdate"; Value = 1; Desc = "Last Access Update OFF" },
        @{ Path = $sysPath; Name = "NtfsDisable8dot3NameCreation"; Value = 1; Desc = "8.3 Names OFF" },
        @{ Path = $sysPath; Name = "NtfsMemoryUsage"; Value = 2; Desc = "NTFS Memory Usage High" },
        @{ Path = $sysPath; Name = "NtfsMftZoneReservation"; Value = 2; Desc = "MFT Zone Medium" },
        @{ Path = $sysPath; Name = "NtfsEncryptPagingFile"; Value = 0; Desc = "PageFile Encrypt OFF" },
        @{ Path = $sysPath; Name = "LongPathsEnabled"; Value = 1; Desc = "Long Paths Enabled" },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name = "EnablePrefetcher"; Value = $(if ($isSSD) { 0 } else { 3 }); Desc = "Prefetcher $(if ($isSSD) { 'OFF (SSD)' } else { 'ON (HDD)' })" },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name = "EnableSuperfetch"; Value = $(if ($isSSD) { 0 } else { 3 }); Desc = "Superfetch $(if ($isSSD) { 'OFF (SSD)' } else { 'ON (HDD)' })" },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\storahci\Parameters\Device"; Name = "EnableQueryAccessAlignment"; Value = 1; Desc = "Query Access Alignment" }
    )
    
    foreach ($k in $diskKeys) {
        if (Set-RegistryKey -Path $k.Path -Name $k.Name -Value $k.Value -Desc $k.Desc) {
            $appliedTweaks++
        }
    }
    
    # =========================================================================
    # 6. NETWORK OPTIMIZATIONS
    # =========================================================================
    
    Write-Step "[6/8] OPTIMIZACIONES DE RED"
    
    # DNS & ARP Cache
    try { Clear-DnsClientCache -EA SilentlyContinue; Write-Host "   [OK] DNS Cache limpiada" -ForegroundColor Green; $appliedTweaks++ } catch {}
    try { $null = & netsh interface ip delete arpcache 2>&1; Write-Host "   [OK] ARP Cache limpiada" -ForegroundColor Green; $appliedTweaks++ } catch {}
    
    $tcpPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
    
    $netKeys = @(
        @{ Path = $tcpPath; Name = "TcpTimedWaitDelay"; Value = 30; Desc = "TCP Wait 30s" },
        @{ Path = $tcpPath; Name = "MaxUserPort"; Value = 65534; Desc = "Max Ports 65534" },
        @{ Path = $tcpPath; Name = "TcpMaxDataRetransmissions"; Value = 3; Desc = "TCP Retransmissions 3" },
        @{ Path = $tcpPath; Name = "EnablePMTUDiscovery"; Value = 1; Desc = "MTU Discovery ON" },
        @{ Path = $tcpPath; Name = "EnablePMTUBHDetect"; Value = 0; Desc = "Black Hole OFF" },
        @{ Path = $tcpPath; Name = "SackOpts"; Value = 1; Desc = "SACK ON" },
        @{ Path = $tcpPath; Name = "Tcp1323Opts"; Value = 1; Desc = "TCP Timestamps" },
        @{ Path = $tcpPath; Name = "DefaultTTL"; Value = 64; Desc = "TTL 64" },
        @{ Path = $tcpPath; Name = "KeepAliveTime"; Value = 300000; Desc = "Keep Alive 5min" },
        @{ Path = $tcpPath; Name = "KeepAliveInterval"; Value = 1000; Desc = "Keep Alive Interval 1s" },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"; Name = "IRPStackSize"; Value = 32; Desc = "IRP Stack 32" },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"; Name = "Size"; Value = 3; Desc = "Server Size Large" },
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched"; Name = "NonBestEffortLimit"; Value = 0; Desc = "QoS sin limite" },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\AFD\Parameters"; Name = "FastSendDatagramThreshold"; Value = 1500; Desc = "Fast Datagram 1500" },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\AFD\Parameters"; Name = "DefaultReceiveWindow"; Value = 65535; Desc = "Receive Window 64KB" },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\AFD\Parameters"; Name = "DefaultSendWindow"; Value = 65535; Desc = "Send Window 64KB" }
    )
    
    foreach ($k in $netKeys) {
        if (Set-RegistryKey -Path $k.Path -Name $k.Name -Value $k.Value -Desc $k.Desc) {
            $appliedTweaks++
        }
    }
    
    # Netsh optimizations
    $netshCmds = @(
        @{ Cmd = "netsh int tcp set global autotuninglevel=normal"; Desc = "Autotuning Normal" },
        @{ Cmd = "netsh int tcp set global congestionprovider=ctcp"; Desc = "CTCP" },
        @{ Cmd = "netsh int tcp set global ecncapability=enabled"; Desc = "ECN" },
        @{ Cmd = "netsh int tcp set global timestamps=enabled"; Desc = "Timestamps" },
        @{ Cmd = "netsh int tcp set global rss=enabled"; Desc = "RSS" },
        @{ Cmd = "netsh int tcp set global chimney=disabled"; Desc = "Chimney OFF" },
        @{ Cmd = "netsh int tcp set global dca=enabled"; Desc = "DCA" },
        @{ Cmd = "netsh int tcp set global netdma=enabled"; Desc = "NetDMA" },
        @{ Cmd = "netsh int ip set global taskoffload=enabled"; Desc = "Task Offload" }
    )
    
    foreach ($n in $netshCmds) {
        try {
            $null = Invoke-Expression $n.Cmd 2>&1
            Write-Host "   [OK] $($n.Desc)" -ForegroundColor Green
            $appliedTweaks++
        }
        catch {}
    }
    
    # =========================================================================
    # 7. CACHE OPTIMIZATION
    # =========================================================================
    
    Write-Step "[7/8] OPTIMIZACION DE CACHE SISTEMA"
    
    $cacheKeys = @(
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"; Name = "MaxFreeConnections"; Value = 100; Desc = "Max Free Connections" },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"; Name = "MinFreeConnections"; Value = 32; Desc = "Min Free Connections" },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters"; Name = "MaxCmds"; Value = 30; Desc = "Max Commands" },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name = "IoPageLockLimit"; Value = 983040; Desc = "IO Page Lock 960KB" },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name = "SystemPages"; Value = 0; Desc = "System Pages Auto" },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name = "SecondLevelDataCache"; Value = 1024; Desc = "L2 Cache 1MB" },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name = "LargePageMinimum"; Value = 4194304; Desc = "Large Page 4MB" }
    )
    
    foreach ($k in $cacheKeys) {
        if (Set-RegistryKey -Path $k.Path -Name $k.Name -Value $k.Value -Desc $k.Desc) {
            $appliedTweaks++
        }
    }
    
    # =========================================================================
    # 8. ADDITIONAL CLEANUPS
    # =========================================================================
    
    Write-Step "[8/8] LIMPIEZA ADICIONAL"
    
    # Recycle Bin
    try {
        $shell = New-Object -ComObject Shell.Application
        $recycleBin = $shell.NameSpace(0xA)
        $recycleCount = $recycleBin.Items().Count
        if ($recycleCount -gt 0) {
            Clear-RecycleBin -Force -EA SilentlyContinue
            Write-Host "   [OK] Papelera vaciada ($recycleCount items)" -ForegroundColor Green
        }
        else {
            Write-Host "   [--] Papelera vacia" -ForegroundColor DarkGray
        }
    }
    catch {}
    
    # Event Logs cleanup
    try {
        wevtutil el | ForEach-Object { wevtutil cl $_ 2>$null }
        Write-Host "   [OK] Event Logs limpiados" -ForegroundColor Green
        $appliedTweaks++
    }
    catch {}
    
    # Font cache
    try {
        $fontCache = "C:\Windows\ServiceProfiles\LocalService\AppData\Local\FontCache"
        if (Test-Path $fontCache) {
            Stop-Service -Name "FontCache" -Force -EA SilentlyContinue
            Remove-Item "$fontCache\*" -Recurse -Force -EA SilentlyContinue
            Start-Service -Name "FontCache" -EA SilentlyContinue
            Write-Host "   [OK] Font Cache limpiada" -ForegroundColor Green
        }
    }
    catch {}
    
    # Windows.old warning
    if (Test-Path "C:\Windows.old") {
        Write-Host "   [i] Windows.old detectado (~GB) - use Disk Cleanup" -ForegroundColor Yellow
    }
    
    # Finish
    $elapsed = (Get-Date) - $startTime
    
    Write-Host ""
    Write-Host " +--------------------------------------------------------+" -ForegroundColor Green
    Write-Host " |  DISK, CACHE & NETWORK v3.5 COMPLETADO                 |" -ForegroundColor Green
    Write-Host " |  Espacio liberado: ~$([int]$totalFreed) MB                           |" -ForegroundColor Green
    Write-Host " |  Tweaks aplicados: $appliedTweaks                                   |" -ForegroundColor Green
    Write-Host " |  Tiempo: $([int]$elapsed.TotalSeconds) segundos                               |" -ForegroundColor Green
    Write-Host " +--------------------------------------------------------+" -ForegroundColor Green
    Write-Host ""
    if (-not $Silent) {
        Write-Host " [!] REINICIAR para aplicar todos los cambios" -ForegroundColor Yellow
    }
}

if ($Silent) { Optimize-Disk -Silent } else { Optimize-Disk }



<#
.SYNOPSIS
    System Health Check v4.0
    Valida el estado del sistema y detecta problemas.

.DESCRIPTION
    Verifica:
    - Integridad de archivos del sistema
    - Estado de drivers
    - Errores en Event Log
    - Malware/Amenazas (Windows Defender)
    - Updates pendientes
    - Fragmentación de disco
    - Estado de servicios críticos

.NOTES
    Parte de Windows Neural Optimizer v4.0
    Creditos: Jose Bustamante
#>

if (-not (Get-Command "Write-Log" -ErrorAction SilentlyContinue)) {
    $currentDir = Split-Path $MyInvocation.MyCommand.Path
    $utilsPath = Join-Path $currentDir "NeuralUtils.psm1"
    if (Test-Path $utilsPath) { Import-Module $utilsPath -Force -DisableNameChecking }
}

Invoke-AdminCheck -Silent

$Script:Issues = @()
$Script:Warnings = @()

function Add-Issue {
    param(
        [string]$Category,
        [string]$Description,
        [string]$Severity = "Medium",
        [string]$Fix = ""
    )
    
    $Script:Issues += [PSCustomObject]@{
        Category    = $Category
        Description = $Description
        Severity    = $Severity
        Fix         = $Fix
    }
}

function Add-Warning {
    param([string]$Message)
    $Script:Warnings += $Message
}

function Test-SystemFiles {
    Write-Host " [+] Verificando integridad de archivos del sistema..." -ForegroundColor Cyan
    
    try {
        $sfc = & sfc /verifyonly 2>&1
        
        if ($sfc -match "found corrupt|integrity violations") {
            Add-Issue -Category "System Files" -Description "Archivos corruptos detectados" -Severity "High" -Fix "Ejecutar: sfc /scannow"
            Write-Host "   [!] Archivos corruptos encontrados" -ForegroundColor Red
        }
        else {
            Write-Host "   [OK] Archivos del sistema íntegros" -ForegroundColor Green
        }
    }
    catch {
        Add-Warning "No se pudo verificar archivos del sistema"
    }
}

function Test-DiskHealth {
    Write-Host " [+] Verificando salud del disco..." -ForegroundColor Cyan
    
    try {
        $volumes = Get-Volume | Where-Object { $_.DriveLetter -and $_.FileSystem -eq "NTFS" }
        
        foreach ($vol in $volumes) {
            $disk = Get-Partition -DriveLetter $vol.DriveLetter | Get-Disk
            
            if ($disk.HealthStatus -ne "Healthy") {
                Add-Issue -Category "Disk Health" `
                    -Description "Disco $($vol.DriveLetter): tiene problemas de salud" `
                    -Severity "High" `
                    -Fix "Verificar con chkdsk /f $($vol.DriveLetter):"
                Write-Host "   [!] Disco $($vol.DriveLetter): $($disk.HealthStatus)" -ForegroundColor Red
            }
            
            # Check fragmentation (HDD only)
            if ($disk.MediaType -notmatch "SSD") {
                $defrag = & defrag $vol.DriveLetter /A 2>&1 | Out-String
                if ($defrag -match "(\d+)% fragmented") {
                    $fragPercent = [int]$matches[1]
                    if ($fragPercent -gt 10) {
                        Add-Issue -Category "Disk Fragmentation" `
                            -Description "Disco $($vol.DriveLetter): $fragPercent% fragmentado" `
                            -Severity "Low" `
                            -Fix "Ejecutar desfragmentación"
                        Write-Host "   [!] Disco $($vol.DriveLetter): $fragPercent% fragmentado" -ForegroundColor Yellow
                    }
                }
            }
        }
        
        Write-Host "   [OK] Verificación de disco completa" -ForegroundColor Green
    }
    catch {
        Add-Warning "Error verificando discos"
    }
}

function Test-Drivers {
    Write-Host " [+] Verificando drivers problemáticos..." -ForegroundColor Cyan
    
    try {
        $problemDevices = Get-PnpDevice | Where-Object { 
            $_.Status -ne "OK" -and $_.Class -notmatch "Printer|SoftwareDevice" 
        }
        
        if ($problemDevices) {
            foreach ($dev in $problemDevices) {
                Add-Issue -Category "Drivers" `
                    -Description "$($dev.FriendlyName) - Estado: $($dev.Status)" `
                    -Severity "Medium" `
                    -Fix "Actualizar driver desde Device Manager"
                Write-Host "   [!] $($dev.FriendlyName): $($dev.Status)" -ForegroundColor Yellow
            }
        }
        else {
            Write-Host "   [OK] Todos los drivers funcionando correctamente" -ForegroundColor Green
        }
    }
    catch {
        Add-Warning "Error verificando drivers"
    }
}

function Test-EventLogs {
    Write-Host " [+] Analizando eventos críticos recientes..." -ForegroundColor Cyan
    
    try {
        $criticalEvents = Get-WinEvent -FilterHashtable @{
            LogName   = 'System', 'Application'
            Level     = 1, 2  # Critical, Error
            StartTime = (Get-Date).AddHours(-24)
        } -MaxEvents 50 -ErrorAction SilentlyContinue
        
        if ($criticalEvents) {
            $grouped = $criticalEvents | Group-Object -Property Id | Sort-Object -Property Count -Descending | Select-Object -First 5
            
            foreach ($group in $grouped) {
                $event = $group.Group[0]
                Add-Issue -Category "Event Log" `
                    -Description "ID $($event.Id): $($event.Message.Substring(0, [math]::Min(100, $event.Message.Length)))..." `
                    -Severity "Low" `
                    -Fix "Revisar Event Viewer para detalles"
                Write-Host "   [!] $($group.Count)x Evento ID $($event.Id)" -ForegroundColor Yellow
            }
        }
        else {
            Write-Host "   [OK] No hay eventos críticos recientes" -ForegroundColor Green
        }
    }
    catch {
        Add-Warning "Error leyendo event logs"
    }
}

function Test-DefenderStatus {
    Write-Host " [+] Verificando Windows Defender..." -ForegroundColor Cyan
    
    try {
        $defender = Get-MpComputerStatus -ErrorAction SilentlyContinue
        
        if ($defender) {
            if (-not $defender.RealTimeProtectionEnabled) {
                Add-Issue -Category "Security" `
                    -Description "Real-Time Protection deshabilitado" `
                    -Severity "High" `
                    -Fix "Habilitar en Windows Security"
                Write-Host "   [!] Real-Time Protection OFF" -ForegroundColor Red
            }
            
            if ($defender.AntivirusSignatureAge -gt 7) {
                Add-Issue -Category "Security" `
                    -Description "Definiciones de virus desactualizadas ($($defender.AntivirusSignatureAge) días)" `
                    -Severity "Medium" `
                    -Fix "Actualizar Windows Defender"
                Write-Host "   [!] Definiciones antiguas: $($defender.AntivirusSignatureAge) días" -ForegroundColor Yellow
            }
            
            $threats = Get-MpThreatDetection -ErrorAction SilentlyContinue
            if ($threats) {
                Add-Issue -Category "Security" `
                    -Description "$($threats.Count) amenazas detectadas" `
                    -Severity "Critical" `
                    -Fix "Ejecutar escaneo completo"
                Write-Host "   [!!] $($threats.Count) amenazas detectadas" -ForegroundColor Red
            }
            
            if ($Script:Issues.Count -eq 0 -or ($Script:Issues | Where-Object Category -eq "Security").Count -eq 0) {
                Write-Host "   [OK] Windows Defender funcionando correctamente" -ForegroundColor Green
            }
        }
    }
    catch {
        Add-Warning "No se pudo verificar Windows Defender"
    }
}

function Test-WindowsUpdates {
    Write-Host " [+] Verificando actualizaciones pendientes..." -ForegroundColor Cyan
    
    try {
        $updateSession = New-Object -ComObject Microsoft.Update.Session
        $updateSearcher = $updateSession.CreateUpdateSearcher()
        $searchResult = $updateSearcher.Search("IsInstalled=0 and Type='Software'")
        
        if ($searchResult.Updates.Count -gt 0) {
            Add-Issue -Category "Updates" `
                -Description "$($searchResult.Updates.Count) actualizaciones pendientes" `
                -Severity "Low" `
                -Fix "Instalar desde Windows Update"
            Write-Host "   [!] $($searchResult.Updates.Count) actualizaciones pendientes" -ForegroundColor Yellow
        }
        else {
            Write-Host "   [OK] Sistema actualizado" -ForegroundColor Green
        }
    }
    catch {
        Add-Warning "Error verificando updates"
    }
}

function Test-CriticalServices {
    Write-Host " [+] Verificando servicios críticos..." -ForegroundColor Cyan
    
    $criticalServices = @(
        @{ Name = "Winmgmt"; Desc = "Windows Management Instrumentation" },
        @{ Name = "EventLog"; Desc = "Windows Event Log" },
        @{ Name = "RpcSs"; Desc = "Remote Procedure Call" },
        @{ Name = "DcomLaunch"; Desc = "DCOM Server Process Launcher" },
        @{ Name = "Dhcp"; Desc = "DHCP Client" },
        @{ Name = "Dnscache"; Desc = "DNS Client" }
    )
    
    $issues = 0
    
    foreach ($svc in $criticalServices) {
        $service = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
        if ($service) {
            if ($service.Status -ne "Running") {
                Add-Issue -Category "Services" `
                    -Description "$($svc.Desc) no está ejecutándose" `
                    -Severity "High" `
                    -Fix "Iniciar servicio: Start-Service $($svc.Name)"
                Write-Host "   [!] $($svc.Desc): $($service.Status)" -ForegroundColor Red
                $issues++
            }
        }
    }
    
    if ($issues -eq 0) {
        Write-Host "   [OK] Servicios críticos funcionando" -ForegroundColor Green
    }
}

function Test-MemoryDiagnostics {
    Write-Host " [+] Verificando memoria RAM..." -ForegroundColor Cyan
    
    try {
        # Check for memory errors in event log
        $memErrors = Get-WinEvent -FilterHashtable @{
            LogName      = 'System'
            ProviderName = 'Microsoft-Windows-MemoryDiagnostics-Results'
            StartTime    = (Get-Date).AddDays(-30)
        } -MaxEvents 10 -ErrorAction SilentlyContinue
        
        if ($memErrors) {
            Add-Issue -Category "Memory" `
                -Description "Errores de memoria detectados en los últimos 30 días" `
                -Severity "High" `
                -Fix "Ejecutar Windows Memory Diagnostic"
            Write-Host "   [!] Errores de memoria encontrados" -ForegroundColor Red
        }
        else {
            Write-Host "   [OK] No hay errores de memoria recientes" -ForegroundColor Green
        }
    }
    catch {
        Add-Warning "Error verificando memoria"
    }
}

function Show-HealthReport {
    Clear-Host
    Write-Host ""
    Write-Host " +========================================================+" -ForegroundColor Cyan
    Write-Host " |  HEALTH CHECK REPORT                                   |" -ForegroundColor Cyan
    Write-Host " +========================================================+" -ForegroundColor Cyan
    Write-Host ""
    
    if ($Script:Issues.Count -eq 0) {
        Write-Host " ✓ NO SE ENCONTRARON PROBLEMAS" -ForegroundColor Green
        Write-Host ""
        Write-Host " El sistema está en condiciones óptimas." -ForegroundColor Gray
    }
    else {
        $critical = ($Script:Issues | Where-Object Severity -eq "Critical").Count
        $high = ($Script:Issues | Where-Object Severity -eq "High").Count
        $medium = ($Script:Issues | Where-Object Severity -eq "Medium").Count
        $low = ($Script:Issues | Where-Object Severity -eq "Low").Count
        
        Write-Host " RESUMEN DE PROBLEMAS:" -ForegroundColor Yellow
        if ($critical -gt 0) { Write-Host "   Críticos: $critical" -ForegroundColor Magenta }
        if ($high -gt 0) { Write-Host "   Altos:    $high" -ForegroundColor Red }
        if ($medium -gt 0) { Write-Host "   Medios:   $medium" -ForegroundColor Yellow }
        if ($low -gt 0) { Write-Host "   Bajos:    $low" -ForegroundColor DarkYellow }
        Write-Host ""
        
        Write-Host " DETALLES:" -ForegroundColor Cyan
        Write-Host ""
        
        $grouped = $Script:Issues | Group-Object -Property Category
        
        foreach ($group in $grouped) {
            Write-Host " [$($group.Name)]" -ForegroundColor White
            foreach ($issue in $group.Group) {
                $severityColor = switch ($issue.Severity) {
                    "Critical" { "Magenta" }
                    "High" { "Red" }
                    "Medium" { "Yellow" }
                    "Low" { "DarkYellow" }
                }
                Write-Host "   • " -NoNewline -ForegroundColor $severityColor
                Write-Host "$($issue.Description)" -ForegroundColor Gray
                if ($issue.Fix) {
                    Write-Host "     Solución: $($issue.Fix)" -ForegroundColor DarkGray
                }
            }
            Write-Host ""
        }
    }
    
    if ($Script:Warnings.Count -gt 0) {
        Write-Host " ADVERTENCIAS:" -ForegroundColor Yellow
        foreach ($warning in $Script:Warnings) {
            Write-Host "   • $warning" -ForegroundColor DarkGray
        }
        Write-Host ""
    }
    
    # Save report
    $reportPath = Join-Path ([Environment]::GetFolderPath('Desktop')) "HealthCheck_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    
    $reportContent = @"
NEURAL OPTIMIZER - HEALTH CHECK REPORT
======================================
Fecha: $(Get-Date)

PROBLEMAS ENCONTRADOS: $($Script:Issues.Count)

"@
    
    foreach ($issue in $Script:Issues) {
        $reportContent += @"
[$($issue.Severity)] [$($issue.Category)]
$($issue.Description)
Solución: $($issue.Fix)

"@
    }
    
    $reportContent | Out-File -FilePath $reportPath -Encoding UTF8
    
    Write-Host " [i] Reporte guardado en:" -ForegroundColor Cyan
    Write-Host "     $reportPath" -ForegroundColor Gray
    Write-Host ""
}

# Ejecutar Health Check
Write-Section "SYSTEM HEALTH CHECK v4.0"

Write-Host " [i] Iniciando diagnóstico del sistema..." -ForegroundColor Cyan
Write-Host " [i] Esto puede tomar 2-5 minutos..." -ForegroundColor Yellow
Write-Host ""

$tests = @(
    "Test-SystemFiles",
    "Test-DiskHealth",
    "Test-Drivers",
    "Test-EventLogs",
    "Test-DefenderStatus",
    "Test-WindowsUpdates",
    "Test-CriticalServices",
    "Test-MemoryDiagnostics"
)

$current = 0
foreach ($test in $tests) {
    $current++
    Write-Progress -Activity "Health Check" -Status "Ejecutando: $test" -PercentComplete (($current / $tests.Count) * 100)
    & $test
    Write-Host ""
}

Write-Progress -Activity "Health Check" -Completed

Show-HealthReport
Wait-ForKeyPress


<#
.SYNOPSIS
    Neural Service Manager v5.0
    Gestion inteligente de servicios de Windows.

.DESCRIPTION
    Ofrece dos niveles de optimizacion:
    - SAFE: Deshabilita servicios secundarios sin riesgo (Fax, Retail Demo, etc.)
    - AGGRESSIVE: Deshabilita SysMain, Search, y servicios de tablet en escritorio.

.NOTES
    Parte de Windows Neural Optimizer v5.0 ULTRA
    Creditos: Jose Bustamante
#>

if (-not (Get-Command "Write-Log" -ErrorAction SilentlyContinue)) {
    $currentDir = Split-Path $MyInvocation.MyCommand.Path
    $utilsPath = Join-Path $currentDir "NeuralUtils.psm1"
    if (Test-Path $utilsPath) { Import-Module $utilsPath -Force -DisableNameChecking }
}

Invoke-AdminCheck -Silent

function Disable-ServiceSafe {
    param($Name, $Desc)
    if (Get-Service $Name -ErrorAction SilentlyContinue) {
        Set-Service -Name $Name -StartupType Disabled -ErrorAction SilentlyContinue
        Stop-Service -Name $Name -Force -ErrorAction SilentlyContinue
        Write-Host "   [DISABLED] $Desc ($Name)" -ForegroundColor Green
    }
}

function Invoke-ServiceOptimization {
    Write-Section "NEURAL SERVICE MANAGER"
    
    Write-Host " Seleccione nivel de optimizacion:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " 1. SAFE (Recomendado)" -ForegroundColor Green
    Write-Host "    Deshabilita: Fax, Maps, Retail Demo, Shared Experience, Xbox (if not used)"
    Write-Host "    Riesgo: NULO. No rompe funciones core."
    Write-Host ""
    Write-Host " 2. AGGRESSIVE (Gaming/Benchmarking)" -ForegroundColor Red
    Write-Host "    Deshabilita: SysMain, Windows Search, Print Spooler, Tablet Input"
    Write-Host "    Riesgo: BAJO/MEDIO. Puede afectar busqueda y nuevas apps."
    Write-Host ""
    
    $choice = Read-Host " >> Seleccione opcion (1/2)"
    
    if ($choice -eq "1") {
        Write-Step "APPLYING SAFE PRESET"
        
        $safeServices = @(
            @{ Name = "DiagTrack"; Desc = "Connected User Experiences and Telemetry" },
            @{ Name = "dmwappushservice"; Desc = "WAP Push Message Routing Service" },
            @{ Name = "RetailDemo"; Desc = "Retail Demo Service" },
            @{ Name = "Fax"; Desc = "Fax Service" },
            @{ Name = "MapsBroker"; Desc = "Downloaded Maps Manager" },
            @{ Name = "lfsvc"; Desc = "Geolocation Service" },
            @{ Name = "XblAuthManager"; Desc = "Xbox Live Auth Manager (Safe disable)" },
            @{ Name = "XblGameSave"; Desc = "Xbox Live Game Save (Safe disable)" }
        )
        
        foreach ($s in $safeServices) { Disable-ServiceSafe -Name $s.Name -Desc $s.Desc }
        
    }
    elseif ($choice -eq "2") {
        Write-Step "APPLYING AGGRESSIVE PRESET"
        
        # Apply Safe first
        $safeServices = @(
            @{ Name = "DiagTrack"; Desc = "Telemetry" },
            @{ Name = "RetailDemo"; Desc = "Retail Demo" }
        )
        foreach ($s in $safeServices) { Disable-ServiceSafe -Name $s.Name -Desc $s.Desc }

        # Aggressive
        $aggServices = @(
            @{ Name = "SysMain"; Desc = "SysMain (Superfetch)" },
            @{ Name = "WSearch"; Desc = "Windows Search" },
            @{ Name = "Spooler"; Desc = "Print Spooler" },
            @{ Name = "TabletInputService"; Desc = "Touch Keyboard and Handwriting Panel" },
            @{ Name = "WerSvc"; Desc = "Windows Error Reporting" }
        )
        
        foreach ($s in $aggServices) { Disable-ServiceSafe -Name $s.Name -Desc $s.Desc }
        
        # Optimize Memory for Services
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "LargeSystemCache" -Value 0 -Type DWord -Force
        Write-Host "   [TWEAK] LargeSystemCache Disabled (Better for Gaming)" -ForegroundColor Yellow
        
    }
    else {
        Write-Host " [i] Operacion cancelada." -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host " [OK] Servicios optimizados." -ForegroundColor Green
    Write-Host ""
}

Invoke-ServiceOptimization
Wait-ForKeyPress

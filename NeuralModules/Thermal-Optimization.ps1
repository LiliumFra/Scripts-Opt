<#
.SYNOPSIS
    Thermal & Fan Optimization Module v3.5
    Optimiza la política de refrigeración y ventiladores.

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

function Optimize-Thermal {
    [CmdletBinding()]
    param()

    Write-Section "THERMAL & FAN OPTIMIZATION v3.5"
    $tweaks = 0

    # =========================================================================
    # 1. UNIVERSAL POWER SETTINGS
    # =========================================================================
    
    Write-Step "[1/3] POLITICA DE REFRIGERACION (Universal)"
    
    try {
        # GUIDs for Power Management
        # SUB_PROCESSOR: 54533251-82be-4824-96c1-47b60b740d00
        # SYSCOOLPOL: 94d3a615-a899-4ac5-ad29-0278443d052d
        # Value 1 = ACTIVE (Fan faster), 0 = PASSIVE (CPU throttling)
        
        Write-Host "   [i] Configurando 'Active Cooling Mode'..." -ForegroundColor Cyan
        
        # AC Power
        powercfg -setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 94d3a615-a899-4ac5-ad29-0278443d052d 1
        # DC Power (Battery) - Usually passive, but we want aggressive? Let's ask user or set to Active for 'Performance' context
        # Setting AC only usually safe/expected for 'fans'. Setting DC might kill battery. 
        # Let's set both to Active to ensure fans run if hot.
        powercfg -setdcvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 94d3a615-a899-4ac5-ad29-0278443d052d 1
        
        # Apply
        powercfg -setactive SCHEME_CURRENT
        
        Write-Host "   [OK] Politica de refrigeracion: ACTIVA (Prioridad Ventiladores)" -ForegroundColor Green
        $tweaks++
    }
    catch {
        Write-Host "   [X] Error configurando PowerCFG: $_" -ForegroundColor Red
    }

    # =========================================================================
    # 2. MANUFACTURER DETECTION
    # =========================================================================
    
    Write-Step "[2/3] DETECCION DE HARDWARE"
    
    $sys = Get-CimInstance Win32_ComputerSystem
    $manufacturer = $sys.Manufacturer
    $model = $sys.Model
    
    Write-Host "   Fabricante: $manufacturer" -ForegroundColor Yellow
    Write-Host "   Modelo:     $model" -ForegroundColor Yellow
    
    # =========================================================================
    # 3. VENDOR SPECIFIC TWEAKS
    # =========================================================================
    
    Write-Step "[3/3] OPTIMIZACIONES ESPECIFICAS (Experimental)"
    
    if ($manufacturer -match "Dell") {
        try {
            # Dell Command | PowerShell Provider or WMI
            # Check for Dell SMBIOS WMI
            $dellWmi = Get-CimInstance -Namespace root/dcim/sysman -ClassName DCIM_ThermalManagementService -ErrorAction SilentlyContinue
            
            if ($dellWmi) {
                Write-Host "   [i] Sistema Dell detectado con interfaz WMI..." -ForegroundColor Cyan
                # Try to set Ultra Performance
                # Note: This often requires Dell Command | Configure installed, or specific BIOS support.
                # Valid methods often depend on specific valid values exposed by DCIM_ThermalManagementService
                
                # Placeholder for safe attempt. Real implementation is complex without specific Dell tools.
                # We will log that it's detected but warn about BIOS control.
                Write-Host "   [i] Intente usar 'Dell Power Manager' para 'Ultra Performance'." -ForegroundColor Gray
            }
            else {
                Write-Host "   [i] No se detecto interfaz WMI de Dell accesible." -ForegroundColor DarkGray
            }
        }
        catch {}
    }
    elseif ($manufacturer -match "HP") {
        # HP often uses 'Fan Always On' in BIOS.
        Write-Host "   [Tip] En equipos HP, verifique BIOS -> System Configuration -> Fan Always On." -ForegroundColor Gray
    }
    elseif ($manufacturer -match "Lenovo") {
        # Lenovo Intelligent Cooling
        Write-Host "   [Tip] Use Fn+Q en laptops Lenovo para cambiar modo (Performance)." -ForegroundColor Gray
    }
    else {
        Write-Host "   [--] Sin optimizaciones especificas para este fabricante." -ForegroundColor DarkGray
    }

    Write-Host ""
    Write-Host " +--------------------------------------------------------+" -ForegroundColor Green
    Write-Host " |  OPTIMIZACION TERMICA COMPLETADA                       |" -ForegroundColor Green
    Write-Host " |  Tweaks: $tweaks                                            |" -ForegroundColor Green
    Write-Host " +--------------------------------------------------------+" -ForegroundColor Green
    Write-Host " [i] NOTA: Los cambios en PowerCFG son PERMANENTES." -ForegroundColor Yellow
    Write-Host ""
}

Optimize-Thermal



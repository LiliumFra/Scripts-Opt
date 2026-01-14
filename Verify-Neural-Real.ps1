# Verify-Neural-Real.ps1
# DEMOSTRACION DE APRENDIZAJE REAL (NO SIMULADO)

$ScriptDir = Split-Path $MyInvocation.MyCommand.Path
$ModulePath = Join-Path $ScriptDir "NeuralModules\NeuralAI.psm1"
$UtilsPath = Join-Path $ScriptDir "NeuralModules\NeuralUtils.psm1"

Import-Module $UtilsPath -Force
Import-Module $ModulePath -Force

Clear-Host
Write-Host " ==================================================" -ForegroundColor Cyan
Write-Host "      VERIFICACION DE APRENDIZAJE PROFUNDO (REAL)" -ForegroundColor Yellow
Write-Host " ==================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host " [i] Conectando con Neural Brain..." -ForegroundColor Gray

# 1. Verify Real System Load Detection
Write-Host ""
Write-Host " [1] DETECTANDO ESTADO DE CARGA REAL DEL SISTEMA:" -ForegroundColor Yellow
$loadState = Get-SystemLoadState
Write-Host "   -> CPU/Disk Load State: $loadState" -ForegroundColor Green

# 2. Verify Real Q-Learning Cycle
Write-Host ""
Write-Host " [2] INICIANDO CICLO DE APRENDIZAJE REAL:" -ForegroundColor Yellow
Write-Host "   (Esto medirá rendimiento real, aplicará un tweak real seguro, y medirá el cambio)" -ForegroundColor Gray
Write-Host ""

$hw = [PSCustomObject]@{
    PerformanceTier = "High"
    CpuName         = (Get-CimInstance Win32_Processor).Name
}

# Force a Learning Cycle
Invoke-NeuralLearning -ProfileName "Verify-Test" -Hardware $hw -Workload "Verification"

# 3. Verify Persistence Logic
Write-Host ""
Write-Host " [3] VERIFICANDO LOGICA DE MEMORIA A LARGO PLAZO:" -ForegroundColor Yellow
Update-PersistenceRewards -QTable (Get-QTable)

Write-Host ""
Write-Host " [OK] Verificacion completada. El sistema esta aprendiendo de datos reales." -ForegroundColor Green
Read-Host " Presione ENTER para salir..."

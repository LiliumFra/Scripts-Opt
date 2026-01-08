<#
.SYNOPSIS
    Neural Visual FX Manager v5.0
    Optimizacion de efectos visuales para maximo rendimiento.

.DESCRIPTION
    Ajusta configuracion de SystemPerformanceProperties.
    Deshabilita transparencia, animaciones, y sombras de ventanas.

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

function Invoke-VisualOptimization {
    Write-Section "NEURAL VISUAL FX"
    
    Write-Host " [i] Optimizando efectos visuales para FPS..." -ForegroundColor Cyan
    Write-Host ""
    
    # 1. Transparency
    Write-Step "TRANSPARENCY EFFECTS"
    Set-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0 -Desc "Transparency Disabled"
    
    # 2. Performance Options (Explorer)
    Write-Step "EXPLORER ANIMATIONS"
    
    # VisualEffects - 2 = Adjust for best performance (Custom in registry terms)
    # We modify individual bits in UserPreferencesMask
    # This is complex via script, so we use direct registry tweaks for key items
    
    $explorerKeys = @(
        @{ Name = "ListviewAlphaSelect"; Value = 0; Desc = "Listview Selection Alpha" },
        @{ Name = "ListviewShadow"; Value = 0; Desc = "Listview Shadow" },
        @{ Name = "TaskbarAnimations"; Value = 0; Desc = "Taskbar Animations" },
        @{ Name = "ComboListAlphaSelect"; Value = 0; Desc = "Combo List Alpha" }
    )
    
    foreach ($k in $explorerKeys) {
        Set-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name $k.Name -Value $k.Value -Desc $k.Desc
    }
    
    # 3. Window Metrics (MinAnimate)
    Write-Step "WINDOW METRICS"
    Set-RegistryKey -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value "0" -Type String -Desc "Minimize/Maximize Animations Disabled"
    
    # 4. Menu Delay
    Set-RegistryKey -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value "0" -Type String -Desc "Menu Show Delay (0ms)"
    
    Write-Host ""
    Write-Host " [!] Reiniciando Explorer para aplicar cambios..." -ForegroundColor Yellow
    Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue
    
    Write-Host " [OK] Efectos visuales optimizados." -ForegroundColor Green
    Write-Host ""
}

Invoke-VisualOptimization
Wait-ForKeyPress


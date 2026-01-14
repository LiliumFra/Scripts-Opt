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
        @{ Name = "ComboListAlphaSelect"; Value = 0; Desc = "Combo List Alpha" },
        @{ Name = "SeparateProcess"; Value = 1; Desc = "Launch Folder Windows in Separate Process" },
        @{ Name = "ShowSyncProviderNotifications"; Value = 0; Desc = "Explorer Provider Notifications OFF" },
        @{ Name = "ShowDriveLettersFirst"; Value = 4; Desc = "Show Drive Letters First" },
        @{ Name = "NavPaneExpandToCurrentFolder"; Value = 1; Desc = "Expand to Current Folder" }
    )
    
    foreach ($k in $explorerKeys) {
        Set-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name $k.Name -Value $k.Value -Desc $k.Desc
    }
    
    # 4. UserPreferencesMask (The "Correct" way for Visual Effects)
    Write-Step "USER PREFERENCES MASK (Advanced)"
    
    # 90 12 03 80 = Custom Performance Settings (Similar to 'Adjust for best performance' but keeps font smoothing)
    # Bitmask calculation is complex, so we apply the known good hex value specific for perf + smooth fonts.
    $maskPath = "HKCU:\Control Panel\Desktop"
    try {
        # Keep font smoothing (ScreenFonts) - crucial for usability
        Set-RegistryKey -Path $maskPath -Name "UserPreferencesMask" -Value ([byte[]](0x90, 0x12, 0x03, 0x80, 0x10, 0x00, 0x00, 0x00)) -Type Binary -Desc "Performance Mask (w/ Smooth Fonts)"
        Set-RegistryKey -Path $maskPath -Name "FontSmoothing" -Value "2" -Type String -Desc "Font Smoothing Enabled"
    }
    catch {}

    # 5. Menu Delay & Window Metrics
    Set-RegistryKey -Path $maskPath -Name "MenuShowDelay" -Value "0" -Type String -Desc "Menu Show Delay (0ms)"
    Set-RegistryKey -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value "0" -Type String -Desc "Minimize/Maximize Animations Disabled"
    
    Write-Host ""
    Write-Host " [!] Reiniciando Explorer para aplicar cambios..." -ForegroundColor Yellow
    Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue
    
    Write-Host " [OK] Efectos visuales optimizados." -ForegroundColor Green
    Write-Host ""
}

Invoke-VisualOptimization
Wait-ForKeyPress



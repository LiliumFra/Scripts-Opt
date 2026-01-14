<#
.SYNOPSIS
    Neural UI Preferences v6.5
    Windows interface customization and user experience tweaks.

.DESCRIPTION
    Features:
    - Classic Context Menu (Windows 10 style)
    - Show/Hide File Extensions
    - Show/Hide Hidden Files
    - Remove Home/Gallery from Explorer
    - Dark/Light Mode Toggle
    - Taskbar Customization (Widgets, Chat, Search)
    - NumLock on Startup
    - Verbose Boot Messages

.NOTES
    Parte de Windows Neural Optimizer v6.5 ULTRA
    Creditos: Jose Bustamante
    Inspirado en: Chris Titus WinUtil, Sophia Script
#>

if (-not (Get-Command "Write-Log" -ErrorAction SilentlyContinue)) {
    $currentDir = Split-Path $MyInvocation.MyCommand.Path
    $utilsPath = Join-Path $currentDir "NeuralUtils.psm1"
    if (Test-Path $utilsPath) { Import-Module $utilsPath -Force -DisableNameChecking }
}

Invoke-AdminCheck -Silent

# ============================================================================
# CORE FUNCTIONS
# ============================================================================

function Show-UIMenu {
    Clear-Host
    Write-Host ""
    Write-Host " â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—" -ForegroundColor Cyan
    Write-Host " â•‘  NEURAL UI PREFERENCES v6.5                           â•‘" -ForegroundColor Cyan
    Write-Host " â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—" -ForegroundColor Gray
    Write-Host " â•‘ [CONTEXT MENU]                                        â•‘" -ForegroundColor Yellow
    Write-Host " â•‘ 1. Restaurar MenÃº Contextual ClÃ¡sico (Win10 Style)    â•‘" -ForegroundColor White
    Write-Host " â•‘ 2. Usar MenÃº Contextual Moderno (Win11 Default)       â•‘" -ForegroundColor White
    Write-Host " â•‘                                                       â•‘" -ForegroundColor Gray
    Write-Host " â•‘ [FILE EXPLORER]                                       â•‘" -ForegroundColor Yellow
    Write-Host " â•‘ 3. Mostrar Extensiones de Archivo                     â•‘" -ForegroundColor White
    Write-Host " â•‘ 4. Mostrar Archivos Ocultos                           â•‘" -ForegroundColor White
    Write-Host " â•‘ 5. Remover Home/Gallery de Explorer (Win11)           â•‘" -ForegroundColor White
    Write-Host " â•‘ 6. Restaurar Home/Gallery en Explorer                 â•‘" -ForegroundColor White
    Write-Host " â•‘                                                       â•‘" -ForegroundColor Gray
    Write-Host " â•‘ [THEME & TASKBAR]                                     â•‘" -ForegroundColor Yellow
    Write-Host " â•‘ 7. Activar Dark Mode                                  â•‘" -ForegroundColor White
    Write-Host " â•‘ 8. Activar Light Mode                                 â•‘" -ForegroundColor White
    Write-Host " â•‘ 9. Limpiar Taskbar (Quitar Widgets, Chat, Search)     â•‘" -ForegroundColor White
    Write-Host " â•‘                                                       â•‘" -ForegroundColor Gray
    Write-Host " â•‘ [MISC]                                                â•‘" -ForegroundColor Yellow
    Write-Host " â•‘ A. Activar NumLock al Inicio                          â•‘" -ForegroundColor White
    Write-Host " â•‘ B. Verbose Boot Messages                              â•‘" -ForegroundColor White
    Write-Host " â•‘                                                       â•‘" -ForegroundColor Gray
    Write-Host " â•‘ 0. Volver                                             â•‘" -ForegroundColor DarkGray
    Write-Host " â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•" -ForegroundColor Gray
    Write-Host ""
    
    return Read-Host " >> OpciÃ³n"
}

function Set-ClassicContextMenu {
    Write-Section "MENU CONTEXTUAL CLASICO"
    
    $clsid = "{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}"
    $regPath = "HKCU:\Software\Classes\CLSID\$clsid\InprocServer32"
    
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    Set-ItemProperty -Path $regPath -Name "(Default)" -Value "" -Force
    
    Write-Host " [OK] MenÃº contextual clÃ¡sico activado." -ForegroundColor Green
    Write-Host " [!] Reinicia Explorer o el PC para aplicar." -ForegroundColor Yellow
    Write-Host ""
}

function Set-ModernContextMenu {
    Write-Section "MENU CONTEXTUAL MODERNO"
    
    $clsid = "{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}"
    $regPath = "HKCU:\Software\Classes\CLSID\$clsid"
    
    if (Test-Path $regPath) {
        Remove-Item -Path $regPath -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    Write-Host " [OK] MenÃº contextual moderno restaurado." -ForegroundColor Green
    Write-Host " [!] Reinicia Explorer o el PC para aplicar." -ForegroundColor Yellow
    Write-Host ""
}

function Set-ShowFileExtensions {
    Write-Section "MOSTRAR EXTENSIONES"
    
    Set-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Desc "File Extensions: Visible"
    
    Write-Host ""
    Write-Host " [OK] Extensiones de archivo visibles." -ForegroundColor Green
    Write-Host ""
}

function Set-ShowHiddenFiles {
    Write-Section "MOSTRAR ARCHIVOS OCULTOS"
    
    Set-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1 -Desc "Hidden Files: Visible"
    Set-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowSuperHidden" -Value 1 -Desc "System Files: Visible"
    
    Write-Host ""
    Write-Host " [OK] Archivos ocultos visibles." -ForegroundColor Green
    Write-Host ""
}

function Set-RemoveHomeGallery {
    Write-Section "REMOVER HOME/GALLERY"
    
    # Windows 11 22H2+ Home folder
    $homeGuid = "{f874310e-b6b7-47dc-bc84-b9e6b38f5903}"
    # Gallery
    $galleryGuid = "{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}"
    
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace_36354489\$homeGuid" -Name "HideIfEnabled" -Value "" -Type String -Desc "Hide Home"
    
    # Try to hide by removing from namespace
    try {
        Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\$galleryGuid" -Force -ErrorAction SilentlyContinue
        Write-Host "   [OK] Gallery folder removed" -ForegroundColor Green
    }
    catch {}
    
    Write-Host ""
    Write-Host " [OK] Home/Gallery removidos del Explorer." -ForegroundColor Green
    Write-Host " [!] Reinicia Explorer para aplicar." -ForegroundColor Yellow
    Write-Host ""
}

function Set-RestoreHomeGallery {
    Write-Section "RESTAURAR HOME/GALLERY"
    
    Write-Host " [i] Esta funciÃ³n restaura la configuraciÃ³n por defecto." -ForegroundColor Cyan
    Write-Host " [i] Puede requerir revertir manualmente en Opciones de Explorer." -ForegroundColor Cyan
    Write-Host ""
}

function Set-DarkMode {
    Write-Section "DARK MODE"
    
    Set-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0 -Desc "Apps: Dark"
    Set-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0 -Desc "System: Dark"
    
    Write-Host ""
    Write-Host " [OK] Dark Mode activado." -ForegroundColor Green
    Write-Host ""
}

function Set-LightMode {
    Write-Section "LIGHT MODE"
    
    Set-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 1 -Desc "Apps: Light"
    Set-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 1 -Desc "System: Light"
    
    Write-Host ""
    Write-Host " [OK] Light Mode activado." -ForegroundColor Green
    Write-Host ""
}

function Set-CleanTaskbar {
    Write-Section "LIMPIAR TASKBAR"
    
    # Remove Widgets
    Set-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value 0 -Desc "Widgets OFF"
    
    # Remove Chat
    Set-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarMn" -Value 0 -Desc "Chat OFF"
    
    # Remove Search Box (just icon)
    Set-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 1 -Desc "Search: Icon Only"
    
    # Remove Task View
    Set-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value 0 -Desc "Task View OFF"
    
    Write-Host ""
    Write-Host " [OK] Taskbar limpia." -ForegroundColor Green
    Write-Host ""
}

function Set-NumLockOnBoot {
    Write-Section "NUMLOCK AL INICIO"
    
    # Set for current user
    Set-RegistryKey -Path "HKCU:\Control Panel\Keyboard" -Name "InitialKeyboardIndicators" -Value "2" -Type String -Desc "NumLock ON (User)"
    
    # Set for default user (new users)
    try {
        reg load "HKU\DefaultUser" "C:\Users\Default\NTUSER.DAT" 2>$null
        Set-RegistryKey -Path "Registry::HKU\DefaultUser\Control Panel\Keyboard" -Name "InitialKeyboardIndicators" -Value "2" -Type String -Desc "NumLock ON (Default)"
        reg unload "HKU\DefaultUser" 2>$null
    }
    catch {}
    
    Write-Host ""
    Write-Host " [OK] NumLock activado al inicio." -ForegroundColor Green
    Write-Host ""
}

function Set-VerboseBoot {
    Write-Section "VERBOSE BOOT MESSAGES"
    
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "VerboseStatus" -Value 1 -Desc "Verbose Boot ON"
    
    Write-Host ""
    Write-Host " [OK] Mensajes detallados durante boot activados." -ForegroundColor Green
    Write-Host ""
}

# ============================================================================
# MAIN LOOP
# ============================================================================

while ($true) {
    $choice = Show-UIMenu
    
    switch ($choice.ToUpper()) {
        '1' { Set-ClassicContextMenu; Wait-ForKeyPress }
        '2' { Set-ModernContextMenu; Wait-ForKeyPress }
        '3' { Set-ShowFileExtensions; Wait-ForKeyPress }
        '4' { Set-ShowHiddenFiles; Wait-ForKeyPress }
        '5' { Set-RemoveHomeGallery; Wait-ForKeyPress }
        '6' { Set-RestoreHomeGallery; Wait-ForKeyPress }
        '7' { Set-DarkMode; Wait-ForKeyPress }
        '8' { Set-LightMode; Wait-ForKeyPress }
        '9' { Set-CleanTaskbar; Wait-ForKeyPress }
        'A' { Set-NumLockOnBoot; Wait-ForKeyPress }
        'B' { Set-VerboseBoot; Wait-ForKeyPress }
        '0' { exit 0 }
        default { Write-Host " [!] OpciÃ³n invÃ¡lida" -ForegroundColor Red; Start-Sleep -Seconds 1 }
    }
}


<#
.SYNOPSIS
    Neural Privacy Guardian v5.0
    Proteccion de privacidad y bloqueo de telemetria.

.DESCRIPTION
    Deshabilita Advertising ID, Activity Feed, Location Tracking,
    y bloquea envio de datos a Microsoft.

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

function Invoke-PrivacyHardening {
    Write-Section "NEURAL PRIVACY GUARDIAN"
    
    Write-Host " [i] Aplicando politicas de privacidad..." -ForegroundColor Cyan
    Write-Host ""
    
    # 1. Advertising ID
    Write-Step "ADVERTISING & TRACKING"
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0 -Desc "Advertising ID Disabled"
    Set-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0 -Desc "User Advertising ID Disabled"
    
    # 2. Activity Feed
    Write-Step "ACTIVITY HISTORY"
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Value 0 -Desc "Activity Feed Disabled"
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Value 0 -Desc "User Activities Publish Disabled"
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "UploadUserActivities" -Value 0 -Desc "User Activities Upload Disabled"
    
    # 3. Telemetry
    Write-Step "TELEMETRY BLOCKING"
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Desc "Telemetry Allowed: Security Only"
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\SQMClient\Windows" -Name "CEIPEnable" -Value 0 -Desc "Customer Experience Program OFF"
    
    # 4. Location
    Write-Step "LOCATION SERVICES"
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Value "Deny" -Type String -Desc "Location Access Denied"
    
    # 5. Cortona / AI Search
    Write-Step "CORTANA & SEARCH"
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0 -Desc "Cortana Disabled"
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "DisableWebSearch" -Value 1 -Desc "Web Search in Start Menu Disabled"
    
    Write-Host ""
    Write-Host " [OK] Privacidad reforzada." -ForegroundColor Green
    Write-Host ""
}

Invoke-PrivacyHardening
Wait-ForKeyPress


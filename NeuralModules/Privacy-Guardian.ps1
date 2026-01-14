<#
.SYNOPSIS
    Neural Privacy Guardian v6.5 ULTRA
    Comprehensive privacy hardening and telemetry blocking.

.DESCRIPTION
    Advanced Privacy Features:
    - Advertising ID & Tracking Disable
    - Activity History (Local & Cloud) Block
    - Full Telemetry Disable (Security Level)
    - Diagnostic Data Restrictions
    - Clipboard History Disable
    - Tailored Experiences Block
    - Feedback & Suggestions Disable
    - Location Services Control
    - Inking/Typing Personalization Disable
    - App Launch Tracking Block
    - SmartScreen Options
    - Copilot/AI Features Disable

.NOTES
    Parte de Windows Neural Optimizer v6.5 ULTRA
    Creditos: Jose Bustamante
    Inspirado en: Sophia Script, Chris Titus WinUtil
#>

if (-not (Get-Command "Write-Log" -ErrorAction SilentlyContinue)) {
    $currentDir = Split-Path $MyInvocation.MyCommand.Path
    $utilsPath = Join-Path $currentDir "NeuralUtils.psm1"
    if (Test-Path $utilsPath) { Import-Module $utilsPath -Force -DisableNameChecking }
}

Invoke-AdminCheck -Silent

function Invoke-PrivacyHardening {
    Write-Section "NEURAL PRIVACY GUARDIAN v6.5"
    
    Write-Host " [i] Aplicando 30+ políticas de privacidad avanzadas..." -ForegroundColor Cyan
    Write-Host ""
    
    $appliedTweaks = 0
    
    # =========================================================================
    # 1. ADVERTISING & TRACKING
    # =========================================================================
    
    Write-Step "[1/8] ADVERTISING & TRACKING"
    
    $adKeys = @(
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"; Name = "Enabled"; Value = 0; Desc = "Advertising ID OFF" },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"; Name = "Enabled"; Value = 0; Desc = "User Advertising ID OFF" },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "Start_TrackProgs"; Value = 0; Desc = "App Launch Tracking OFF" },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "Start_TrackDocs"; Value = 0; Desc = "Document Tracking OFF" },
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo"; Name = "DisabledByGroupPolicy"; Value = 1; Desc = "Advertising ID Policy OFF" }
    )
    
    foreach ($k in $adKeys) {
        if (Set-RegistryKey -Path $k.Path -Name $k.Name -Value $k.Value -Desc $k.Desc) { $appliedTweaks++ }
    }
    
    # =========================================================================
    # 2. ACTIVITY HISTORY & TIMELINE
    # =========================================================================
    
    Write-Step "[2/8] ACTIVITY HISTORY & TIMELINE"
    
    $activityKeys = @(
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Name = "EnableActivityFeed"; Value = 0; Desc = "Activity Feed OFF" },
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Name = "PublishUserActivities"; Value = 0; Desc = "Publish User Activities OFF" },
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Name = "UploadUserActivities"; Value = 0; Desc = "Upload User Activities OFF" },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy"; Name = "TailoredExperiencesWithDiagnosticDataEnabled"; Value = 0; Desc = "Tailored Experiences OFF" }
    )
    
    foreach ($k in $activityKeys) {
        if (Set-RegistryKey -Path $k.Path -Name $k.Name -Value $k.Value -Desc $k.Desc) { $appliedTweaks++ }
    }
    
    # =========================================================================
    # 3. TELEMETRY & DIAGNOSTIC DATA
    # =========================================================================
    
    Write-Step "[3/8] TELEMETRY & DIAGNOSTIC DATA"
    
    $telemetryKeys = @(
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name = "AllowTelemetry"; Value = 0; Desc = "Telemetry: Security Only (0)" },
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name = "MaxTelemetryAllowed"; Value = 0; Desc = "Max Telemetry: Security" },
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name = "DisableEnterpriseAuthProxy"; Value = 1; Desc = "Enterprise Auth Proxy OFF" },
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"; Name = "AllowTelemetry"; Value = 0; Desc = "System Telemetry OFF" },
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\SQMClient\Windows"; Name = "CEIPEnable"; Value = 0; Desc = "CEIP OFF" },
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat"; Name = "AITEnable"; Value = 0; Desc = "Application Impact Telemetry OFF" },
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat"; Name = "DisableInventory"; Value = 1; Desc = "Inventory Collector OFF" }
    )
    
    foreach ($k in $telemetryKeys) {
        if (Set-RegistryKey -Path $k.Path -Name $k.Name -Value $k.Value -Desc $k.Desc) { $appliedTweaks++ }
    }
    
    # =========================================================================
    # 4. FEEDBACK & SUGGESTIONS
    # =========================================================================
    
    Write-Step "[4/8] FEEDBACK & SUGGESTIONS"
    
    $feedbackKeys = @(
        @{ Path = "HKCU:\Software\Microsoft\Siuf\Rules"; Name = "NumberOfSIUFInPeriod"; Value = 0; Desc = "Feedback Frequency: Never" },
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"; Name = "DisableWindowsConsumerFeatures"; Value = 1; Desc = "Consumer Features OFF" },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SilentInstalledAppsEnabled"; Value = 0; Desc = "Silent App Install OFF" },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SystemPaneSuggestionsEnabled"; Value = 0; Desc = "Settings Suggestions OFF" },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SoftLandingEnabled"; Value = 0; Desc = "Tips & Suggestions OFF" },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContent-338388Enabled"; Value = 0; Desc = "Start Menu Suggestions OFF" },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContent-338389Enabled"; Value = 0; Desc = "Tips on Start OFF" },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContent-310093Enabled"; Value = 0; Desc = "Show Me Windows Welcome OFF" }
    )
    
    foreach ($k in $feedbackKeys) {
        if (Set-RegistryKey -Path $k.Path -Name $k.Name -Value $k.Value -Desc $k.Desc) { $appliedTweaks++ }
    }
    
    # =========================================================================
    # 5. LOCATION SERVICES
    # =========================================================================
    
    Write-Step "[5/8] LOCATION SERVICES"
    
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Value "Deny" -Type String -Desc "Location Access: Deny"
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableLocation" -Value 1 -Desc "Location Services OFF"
    Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableLocationScripting" -Value 1 -Desc "Location Scripting OFF"
    $appliedTweaks += 3
    
    # =========================================================================
    # 6. CORTANA, SEARCH & AI
    # =========================================================================
    
    Write-Step "[6/8] CORTANA, SEARCH & AI FEATURES"
    
    $cortanaKeys = @(
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; Name = "AllowCortana"; Value = 0; Desc = "Cortana OFF" },
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; Name = "DisableWebSearch"; Value = 1; Desc = "Web Search OFF" },
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; Name = "ConnectedSearchUseWeb"; Value = 0; Desc = "Connected Search OFF" },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"; Name = "BingSearchEnabled"; Value = 0; Desc = "Bing Search OFF" },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"; Name = "CortanaConsent"; Value = 0; Desc = "Cortana Consent OFF" },
        # Windows 11 Copilot
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"; Name = "TurnOffWindowsCopilot"; Value = 1; Desc = "Windows Copilot OFF" },
        @{ Path = "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot"; Name = "TurnOffWindowsCopilot"; Value = 1; Desc = "User Copilot OFF" },
        # Recall (Windows 11 24H2+)
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"; Name = "DisableAIDataAnalysis"; Value = 1; Desc = "Windows Recall OFF" }
    )
    
    foreach ($k in $cortanaKeys) {
        if (Set-RegistryKey -Path $k.Path -Name $k.Name -Value $k.Value -Desc $k.Desc) { $appliedTweaks++ }
    }
    
    # =========================================================================
    # 7. CLIPBOARD & INKING
    # =========================================================================
    
    Write-Step "[7/8] CLIPBOARD & INKING PERSONALIZATION"
    
    $clipKeys = @(
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Name = "AllowClipboardHistory"; Value = 0; Desc = "Clipboard History OFF" },
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Name = "AllowCrossDeviceClipboard"; Value = 0; Desc = "Cross-Device Clipboard OFF" },
        @{ Path = "HKCU:\Software\Microsoft\InputPersonalization"; Name = "RestrictImplicitInkCollection"; Value = 1; Desc = "Ink Collection OFF" },
        @{ Path = "HKCU:\Software\Microsoft\InputPersonalization"; Name = "RestrictImplicitTextCollection"; Value = 1; Desc = "Text Collection OFF" },
        @{ Path = "HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore"; Name = "HarvestContacts"; Value = 0; Desc = "Contacts Harvest OFF" },
        @{ Path = "HKCU:\Software\Microsoft\Personalization\Settings"; Name = "AcceptedPrivacyPolicy"; Value = 0; Desc = "Typing Insights OFF" }
    )
    
    foreach ($k in $clipKeys) {
        if (Set-RegistryKey -Path $k.Path -Name $k.Name -Value $k.Value -Desc $k.Desc) { $appliedTweaks++ }
    }
    
    # =========================================================================
    # 8. WIDGETS & EXTRAS
    # =========================================================================
    
    Write-Step "[8/8] WIDGETS & MISC PRIVACY"
    
    $miscKeys = @(
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"; Name = "AllowNewsAndInterests"; Value = 0; Desc = "News & Interests OFF" },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds"; Name = "ShellFeedsTaskbarViewMode"; Value = 2; Desc = "Widgets Icon OFF" },
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Name = "EnableCdp"; Value = 0; Desc = "Connected Devices Platform OFF" },
        @{ Path = "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Bluetooth"; Name = "AllowAdvertising"; Value = 0; Desc = "Bluetooth Advertising OFF" }
    )
    
    foreach ($k in $miscKeys) {
        if (Set-RegistryKey -Path $k.Path -Name $k.Name -Value $k.Value -Desc $k.Desc) { $appliedTweaks++ }
    }
    
    # =========================================================================
    # SUMMARY
    # =========================================================================
    
    Write-Host ""
    Write-Host " +--------------------------------------------------------+" -ForegroundColor Green
    Write-Host " |  NEURAL PRIVACY GUARDIAN v6.5 COMPLETADO               |" -ForegroundColor Green
    Write-Host " |  Políticas aplicadas: $appliedTweaks                                  |" -ForegroundColor Green
    Write-Host " +--------------------------------------------------------+" -ForegroundColor Green
    Write-Host ""
    Write-Host " [!] Algunos cambios requieren reinicio." -ForegroundColor Yellow
    Write-Host ""
}

Invoke-PrivacyHardening
Wait-ForKeyPress




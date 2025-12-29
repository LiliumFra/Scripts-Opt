<#
.SYNOPSIS
    Debloat & Privacy Suite v3.5 - ULTIMATE
    Elimina bloatware, telemetría, y optimiza privacidad.

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

function Optimize-Debloat {
    [CmdletBinding()]
    param()
    
    Write-Section "DEBLOAT & PRIVACY SUITE v3.5"
    
    $removedApps = 0
    $appliedTweaks = 0
    
    # =========================================================================
    # 1. WHITELIST - Apps que NUNCA tocamos
    # =========================================================================
    
    $WhiteList = @(
        "Microsoft.WindowsCalculator", "Microsoft.WindowsStore", "Microsoft.Windows.Photos",
        "Microsoft.WindowsTerminal", "Microsoft.DesktopAppInstaller", "Microsoft.StorePurchaseApp",
        "Microsoft.VP9VideoExtensions", "Microsoft.WebMediaExtensions", "Microsoft.WebpImageExtension",
        "Microsoft.HEIFImageExtension", "Microsoft.HEVCVideoExtension", "Microsoft.ScreenSketch",
        "Microsoft.Paint", "Microsoft.WindowsNotepad"
    )
    
    # =========================================================================
    # 2. BLOATWARE LIST - Apps a eliminar
    # =========================================================================
    
    Write-Step "[1/6] ELIMINANDO BLOATWARE"
    
    $BloatList = @(
        "Microsoft.3DBuilder", "Microsoft.549981C3F5F10", "Microsoft.BingNews",
        "Microsoft.BingWeather", "Microsoft.BingSports", "Microsoft.BingFinance",
        "Microsoft.BingSearch", "Microsoft.Getstarted", "Microsoft.MicrosoftSolitaireCollection",
        "Microsoft.MicrosoftOfficeHub", "Microsoft.Office.OneNote", "Microsoft.People",
        "Microsoft.SkypeApp", "Microsoft.Wallet", "Microsoft.WindowsAlarms",
        "Microsoft.WindowsCamera", "microsoft.windowscommunicationsapps",
        "Microsoft.WindowsFeedbackHub", "Microsoft.WindowsMaps",
        "Microsoft.WindowsSoundRecorder", "Microsoft.YourPhone",
        "Microsoft.MixedReality.Portal", "Microsoft.MSPaint", "Microsoft.Print3D",
        "Microsoft.OneConnect", "Microsoft.GetHelp", "Microsoft.Todos",
        "Microsoft.PowerAutomateDesktop", "MicrosoftCorporationII.QuickAssist",
        "Microsoft.Clipchamp", "MicrosoftTeams", "Microsoft.OutlookForWindows",
        "Microsoft.XboxApp", "Microsoft.Xbox.TCUI", "Microsoft.XboxGamingOverlay",
        "Microsoft.XboxGameOverlay", "Microsoft.XboxSpeechToTextOverlay",
        "Microsoft.XboxIdentityProvider", "Microsoft.GamingApp",
        "Microsoft.ZuneMusic", "Microsoft.ZuneVideo",
        "king.com.*", "Flipboard.Flipboard", "9E2F88E3.Twitter",
        "SpotifyAB.SpotifyMusic", "Facebook.*", "Disney.*",
        "TikTok.*", "BytedancePte.*", "ADOBESYSTEMSINCORPORATED.*",
        "AmazonVideo.PrimeVideo", "Duolingo*", "Clipchamp*"
    )
    
    $i = 0
    foreach ($appPattern in $BloatList) {
        $i++
        $percent = [int](($i / $BloatList.Count) * 100)
        Write-Progress -Activity "Eliminando Bloatware" -Status "Escaneando: $appPattern" -PercentComplete $percent
        
        try {
            $packages = Get-AppxPackage -Name $appPattern -ErrorAction SilentlyContinue
            foreach ($pkg in $packages) {
                $isWhite = $false
                foreach ($w in $WhiteList) { if ($pkg.Name -like "*$w*") { $isWhite = $true; break } }
                
                if (-not $isWhite) {
                    Write-Host "   [DEL] $($pkg.Name)" -ForegroundColor Yellow -NoNewline
                    try {
                        $pkg | Remove-AppxPackage -ErrorAction Stop
                        Write-Host " OK" -ForegroundColor Green
                        $removedApps++
                    }
                    catch { Write-Host " Error" -ForegroundColor Red }
                }
            }
        }
        catch {}
    }
    Write-Progress -Activity "Eliminando Bloatware" -Completed
    
    Write-Host "   Eliminadas: $removedApps apps" -ForegroundColor Cyan
    
    # =========================================================================
    # 3. SCHEDULED TASKS
    # =========================================================================
    
    Write-Step "[2/6] DESHABILITANDO TAREAS PROGRAMADAS"
    
    $tasksToDisable = @(
        "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
        "\Microsoft\Windows\Application Experience\ProgramDataUpdater",
        "\Microsoft\Windows\Autochk\Proxy",
        "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
        "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
        "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector",
        "\Microsoft\Windows\Feedback\Siuf\DmClient",
        "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload",
        "\Microsoft\Windows\Maps\MapsToastTask",
        "\Microsoft\Windows\Maps\MapsUpdateTask",
        "\Microsoft\Windows\Windows Error Reporting\QueueReporting",
        "\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem"
    )
    
    foreach ($task in $tasksToDisable) {
        try {
            Disable-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue | Out-Null
            $taskName = Split-Path $task -Leaf
            Write-Host "   [OK] $taskName" -ForegroundColor Green
            $appliedTweaks++
        }
        catch {}
    }
    
    # =========================================================================
    # 4. TELEMETRY & PRIVACY
    # =========================================================================
    
    Write-Step "[3/6] DESHABILITANDO TELEMETRIA"
    
    $telemetryKeys = @(
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name = "AllowTelemetry"; Value = 0; Desc = "Telemetria Windows" },
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name = "DoNotShowFeedbackNotifications"; Value = 1; Desc = "Notificaciones feedback" },
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"; Name = "AllowTelemetry"; Value = 0; Desc = "Data Collection" },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy"; Name = "TailoredExperiencesWithDiagnosticDataEnabled"; Value = 0; Desc = "Experiencias personalizadas" },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "ContentDeliveryAllowed"; Value = 0; Desc = "Content Delivery" },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SilentInstalledAppsEnabled"; Value = 0; Desc = "Instalacion silenciosa apps" },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SoftLandingEnabled"; Value = 0; Desc = "Tips Windows" },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContentEnabled"; Value = 0; Desc = "Contenido suscrito" },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContent-338388Enabled"; Value = 0; Desc = "Sugerencias Start" },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContent-338389Enabled"; Value = 0; Desc = "Sugerencias Settings" },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SystemPaneSuggestionsEnabled"; Value = 0; Desc = "Sugerencias panel" },
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo"; Name = "DisabledByGroupPolicy"; Value = 1; Desc = "Advertising ID" },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"; Name = "Enabled"; Value = 0; Desc = "Advertising ID usuario" },
        @{ Path = "HKCU:\Software\Microsoft\Input\TIPC"; Name = "Enabled"; Value = 0; Desc = "Typing insights" },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "Start_TrackProgs"; Value = 0; Desc = "Track programas" }
    )
    
    foreach ($k in $telemetryKeys) {
        if (Set-RegistryKey -Path $k.Path -Name $k.Name -Value $k.Value -Desc $k.Desc) {
            $appliedTweaks++
        }
    }
    
    # =========================================================================
    # 5. DISABLE TELEMETRY SERVICES
    # =========================================================================
    
    Write-Step "[4/6] DESHABILITANDO SERVICIOS TELEMETRIA"
    
    $servicesToDisable = @(
        @{ Name = "DiagTrack"; Desc = "Connected User Experiences" },
        @{ Name = "dmwappushservice"; Desc = "WAP Push Service" },
        @{ Name = "diagnosticshub.standardcollector.service"; Desc = "Diagnostics Hub" },
        @{ Name = "WMPNetworkSvc"; Desc = "WMP Network Sharing" },
        @{ Name = "WerSvc"; Desc = "Error Reporting" },
        @{ Name = "MapsBroker"; Desc = "Maps Broker" },
        @{ Name = "lfsvc"; Desc = "Geolocation Service" },
        @{ Name = "SharedAccess"; Desc = "Internet Connection Sharing" },
        @{ Name = "RemoteRegistry"; Desc = "Remote Registry" },
        @{ Name = "RetailDemo"; Desc = "Retail Demo" }
    )
    
    foreach ($svc in $servicesToDisable) {
        try {
            $service = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
            if ($service) {
                Stop-Service -Name $svc.Name -Force -ErrorAction SilentlyContinue
                Set-Service -Name $svc.Name -StartupType Disabled -ErrorAction SilentlyContinue
                Write-Host "   [OK] $($svc.Desc)" -ForegroundColor Green
                $appliedTweaks++
            }
        }
        catch {}
    }
    
    # =========================================================================
    # 6. CORTANA & SEARCH
    # =========================================================================
    
    Write-Step "[5/6] DESHABILITANDO CORTANA Y BUSQUEDA WEB"
    
    $cortanaKeys = @(
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; Name = "AllowCortana"; Value = 0; Desc = "Cortana" },
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; Name = "DisableWebSearch"; Value = 1; Desc = "Busqueda Web" },
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; Name = "ConnectedSearchUseWeb"; Value = 0; Desc = "Busqueda conectada" },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"; Name = "BingSearchEnabled"; Value = 0; Desc = "Bing Search" },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"; Name = "CortanaConsent"; Value = 0; Desc = "Cortana Consent" }
    )
    
    foreach ($k in $cortanaKeys) {
        if (Set-RegistryKey -Path $k.Path -Name $k.Name -Value $k.Value -Desc $k.Desc) {
            $appliedTweaks++
        }
    }
    
    # =========================================================================
    # 7. ADDITIONAL
    # =========================================================================
    
    Write-Step "[6/6] LIMPIEZA ADICIONAL"
    
    # OneDrive Auto-start
    try {
        Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive" -ErrorAction SilentlyContinue
        Write-Host "   [OK] OneDrive auto-start deshabilitado" -ForegroundColor Green
        $appliedTweaks++
    }
    catch {}
    
    # Windows Widgets & Chat
    if (Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests" -Value 0 -Desc "Windows Widgets (Policy)") { $appliedTweaks++ }
    if (Set-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value 0 -Desc "Windows Widgets (Taskbar)") { $appliedTweaks++ }
    if (Set-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarMn" -Value 0 -Desc "Teams Chat icon") { $appliedTweaks++ }
    
    # Resumen
    Write-Host ""
    Write-Host " +--------------------------------------------------------+" -ForegroundColor Green
    Write-Host " |  DEBLOAT & PRIVACY COMPLETADO                          |" -ForegroundColor Green
    Write-Host " |  Apps eliminadas: $removedApps                                    |" -ForegroundColor Green
    Write-Host " |  Tweaks aplicados: $appliedTweaks                                  |" -ForegroundColor Green
    Write-Host " +--------------------------------------------------------+" -ForegroundColor Green
}

Optimize-Debloat

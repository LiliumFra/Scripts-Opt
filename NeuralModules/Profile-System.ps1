<#
.SYNOPSIS
    Profile System v5.0
    Sistema de perfiles de configuración predefinidos.

.DESCRIPTION
    Perfiles disponibles:
    - Gaming Competitive (máximo FPS, mínima latencia)
    - Gaming Balanced (balance performance/estabilidad)
    - Workstation (productividad, multitarea)
    - Content Creation (rendering, encoding)
    - Power Saver (laptops, batería)
    - Custom (configuración personalizada)

.NOTES
    Parte de Windows Neural Optimizer v5.0
    Creditos: Jose Bustamante
#>

if (-not (Get-Command "Write-Log" -ErrorAction SilentlyContinue)) {
    $currentDir = Split-Path $MyInvocation.MyCommand.Path
    $utilsPath = Join-Path $currentDir "NeuralUtils.psm1"
    if (Test-Path $utilsPath) { Import-Module $utilsPath -Force -DisableNameChecking }
}

Invoke-AdminCheck -Silent

# ============================================================================
# PROFILE DEFINITIONS
# ============================================================================

$Script:Profiles = @{
    "GamingCompetitive" = @{
        Name        = "Gaming Competitive"
        Description = "Máximo FPS, mínima latencia. Para gaming competitivo y esports."
        Color       = "Magenta"
        Settings    = @{
            # Power
            PowerPlan               = "Ultimate"
            CPUMinState             = 100
            CPUMaxState             = 100
            
            # Memory
            LargeSystemCache        = 0
            DisablePagingExecutive  = 1
            ClearPageFileAtShutdown = 0
            
            # Network
            NetworkThrottling       = 0xFFFFFFFF
            TCPNoDelay              = 1
            TcpAckFrequency         = 1
            
            # GPU
            HardwareGPUScheduling   = 2
            GameMode                = 1
            
            # Visual
            VisualEffects           = 2  # Performance
            EnableTransparency      = 0
            
            # Services
            Superfetch              = 0
            Prefetch                = 0
            WindowsSearch           = 4  # Disabled
            
            # Advanced
            HPET                    = 4  # Disabled
            MSIMode                 = 1
            DynamicTick             = "no"
        }
    }
    
    "GamingBalanced"    = @{
        Name        = "Gaming Balanced"
        Description = "Balance entre performance y estabilidad. Para gaming casual."
        Color       = "Cyan"
        Settings    = @{
            PowerPlan               = "High Performance"
            CPUMinState             = 5
            CPUMaxState             = 100
            
            LargeSystemCache        = 0
            DisablePagingExecutive  = 0
            ClearPageFileAtShutdown = 0
            
            NetworkThrottling       = 10
            TCPNoDelay              = 1
            TcpAckFrequency         = 2
            
            HardwareGPUScheduling   = 2
            GameMode                = 1
            
            VisualEffects           = 2
            EnableTransparency      = 0
            
            Superfetch              = 0
            Prefetch                = 0
            WindowsSearch           = 2  # Automatic
            
            HPET                    = 0  # Enabled
            MSIMode                 = 1
            DynamicTick             = "yes"
        }
    }
    
    "Workstation"       = @{
        Name        = "Workstation"
        Description = "Optimizado para productividad, multitarea y aplicaciones profesionales."
        Color       = "Blue"
        Settings    = @{
            PowerPlan               = "Balanced"
            CPUMinState             = 5
            CPUMaxState             = 100
            
            LargeSystemCache        = 1  # Better for large files
            DisablePagingExecutive  = 0
            ClearPageFileAtShutdown = 0
            
            NetworkThrottling       = 10
            TCPNoDelay              = 0
            TcpAckFrequency         = 2
            
            HardwareGPUScheduling   = 2
            GameMode                = 0
            
            VisualEffects           = 1  # Best appearance
            EnableTransparency      = 1
            
            Superfetch              = 3
            Prefetch                = 3
            WindowsSearch           = 2
            
            HPET                    = 0
            MSIMode                 = 0
            DynamicTick             = "yes"
        }
    }
    
    "ContentCreation"   = @{
        Name        = "Content Creation"
        Description = "Para rendering, encoding, video editing. Máxima potencia sostenida."
        Color       = "Yellow"
        Settings    = @{
            PowerPlan               = "Ultimate"
            CPUMinState             = 100
            CPUMaxState             = 100
            
            LargeSystemCache        = 1
            DisablePagingExecutive  = 1
            ClearPageFileAtShutdown = 0
            
            NetworkThrottling       = 0xFFFFFFFF
            TCPNoDelay              = 0
            TcpAckFrequency         = 2
            
            HardwareGPUScheduling   = 2
            GameMode                = 0
            
            VisualEffects           = 2
            EnableTransparency      = 0
            
            Superfetch              = 0
            Prefetch                = 0
            WindowsSearch           = 2
            
            HPET                    = 0
            MSIMode                 = 1
            DynamicTick             = "yes"
        }
    }
    
    "PowerSaver"        = @{
        Name        = "Power Saver"
        Description = "Máxima duración de batería. Para laptops en movilidad."
        Color       = "Green"
        Settings    = @{
            PowerPlan               = "Power Saver"
            CPUMinState             = 5
            CPUMaxState             = 50
            
            LargeSystemCache        = 0
            DisablePagingExecutive  = 0
            ClearPageFileAtShutdown = 0
            
            NetworkThrottling       = 10
            TCPNoDelay              = 0
            TcpAckFrequency         = 2
            
            HardwareGPUScheduling   = 0
            GameMode                = 0
            
            VisualEffects           = 2
            EnableTransparency      = 0
            
            Superfetch              = 3
            Prefetch                = 3
            WindowsSearch           = 2
            
            HPET                    = 0
            MSIMode                 = 0
            DynamicTick             = "yes"
        }
    }
}

# ============================================================================
# PROFILE APPLICATION
# ============================================================================

function Invoke-ProfileApplication {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProfileName
    )
    
    $OptimProfile = $Script:Profiles[$ProfileName]
    
    if (-not $OptimProfile) {
        Write-Host " [!] Perfil no encontrado: $ProfileName" -ForegroundColor Red
        return $false
    }
    
    Write-Host ""
    Write-Host " +========================================================+" -ForegroundColor $OptimProfile.Color
    Write-Host " |  APLICANDO PERFIL: $($OptimProfile.Name.PadRight(36))  |" -ForegroundColor $OptimProfile.Color
    Write-Host " +========================================================+" -ForegroundColor $OptimProfile.Color
    Write-Host ""
    Write-Host " $($OptimProfile.Description)" -ForegroundColor Gray
    Write-Host ""
    
    $settings = $OptimProfile.Settings
    $applied = 0
    $failed = 0
    
    # Power Plan
    Write-Step "[1/10] POWER PLAN"
    try {
        $planGuid = switch ($settings.PowerPlan) {
            "Power Saver" { "a1841308-3541-4fab-bc81-f71556f20b4a" }
            "Balanced" { "381b4222-f694-41f0-9685-ff5bb260df2e" }
            "High Performance" { "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" }
            "Ultimate" { "e9a42b02-d5df-448d-aa00-03f14749eb61" }
            default { "381b4222-f694-41f0-9685-ff5bb260df2e" }
        }
        
        if ($settings.PowerPlan -eq "Ultimate") {
            $null = powercfg -duplicatescheme $planGuid 2>&1
        }
        
        powercfg -setactive $planGuid
        Write-Host " [OK] Power Plan: $($settings.PowerPlan)" -ForegroundColor Green
        $applied++
        
        # CPU States
        $subProc = "54533251-82be-4824-96c1-47b60b740d00"
        powercfg -setacvalueindex SCHEME_CURRENT $subProc PROCTHROTTLEMIN $settings.CPUMinState
        powercfg -setacvalueindex SCHEME_CURRENT $subProc PROCTHROTTLEMAX $settings.CPUMaxState
        powercfg -setactive SCHEME_CURRENT
        
        Write-Host " [OK] CPU Min/Max: $($settings.CPUMinState)% / $($settings.CPUMaxState)%" -ForegroundColor Green
        $applied++
    }
    catch {
        Write-Host " [!] Error configurando Power Plan" -ForegroundColor Yellow
        $failed++
    }
    
    # Memory
    Write-Step "[2/10] MEMORY MANAGEMENT"
    $memPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
    
    if (Set-RegistryKey -Path $memPath -Name "LargeSystemCache" -Value $settings.LargeSystemCache -Desc "Large System Cache") { $applied++ } else { $failed++ }
    if (Set-RegistryKey -Path $memPath -Name "DisablePagingExecutive" -Value $settings.DisablePagingExecutive -Desc "Disable Paging Executive") { $applied++ } else { $failed++ }
    if (Set-RegistryKey -Path $memPath -Name "ClearPageFileAtShutdown" -Value $settings.ClearPageFileAtShutdown -Desc "Clear PageFile at Shutdown") { $applied++ } else { $failed++ }
    
    # Network
    Write-Step "[3/10] NETWORK OPTIMIZATION"
    $sysProfile = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
    $tcpPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
    
    if (Set-RegistryKey -Path $sysProfile -Name "NetworkThrottlingIndex" -Value $settings.NetworkThrottling -Desc "Network Throttling") { $applied++ } else { $failed++ }
    if (Set-RegistryKey -Path $tcpPath -Name "TCPNoDelay" -Value $settings.TCPNoDelay -Desc "TCP No Delay") { $applied++ } else { $failed++ }
    if (Set-RegistryKey -Path $tcpPath -Name "TcpAckFrequency" -Value $settings.TcpAckFrequency -Desc "TCP ACK Frequency") { $applied++ } else { $failed++ }
    
    # GPU
    Write-Step "[4/10] GPU SETTINGS"
    $gpuPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
    
    if (Set-RegistryKey -Path $gpuPath -Name "HwSchMode" -Value $settings.HardwareGPUScheduling -Desc "Hardware GPU Scheduling") { $applied++ } else { $failed++ }
    
    $gamePath = "HKCU:\Software\Microsoft\GameBar"
    if (Set-RegistryKey -Path $gamePath -Name "AutoGameModeEnabled" -Value $settings.GameMode -Desc "Game Mode") { $applied++ } else { $failed++ }
    
    # Visual Effects
    Write-Step "[5/10] VISUAL EFFECTS"
    $visPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
    $persPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    
    if (Set-RegistryKey -Path $visPath -Name "VisualFXSetting" -Value $settings.VisualEffects -Desc "Visual Effects") { $applied++ } else { $failed++ }
    if (Set-RegistryKey -Path $persPath -Name "EnableTransparency" -Value $settings.EnableTransparency -Desc "Transparency") { $applied++ } else { $failed++ }
    
    # Services
    Write-Step "[6/10] SERVICES"
    
    try {
        Set-Service -Name "SysMain" -StartupType $(if ($settings.Superfetch -eq 0) { "Disabled" } else { "Automatic" }) -ErrorAction SilentlyContinue
        Write-Host " [OK] Superfetch: $(if ($settings.Superfetch -eq 0) { 'Disabled' } else { 'Enabled' })" -ForegroundColor Green
        $applied++
    }
    catch { $failed++ }
    
    if (Set-RegistryKey -Path "$memPath\PrefetchParameters" -Name "EnablePrefetcher" -Value $settings.Prefetch -Desc "Prefetcher") { $applied++ } else { $failed++ }
    
    try {
        Set-Service -Name "WSearch" -StartupType $(
            switch ($settings.WindowsSearch) {
                2 { "Automatic" }
                3 { "Manual" }
                4 { "Disabled" }
            }
        ) -ErrorAction SilentlyContinue
        Write-Host " [OK] Windows Search configured" -ForegroundColor Green
        $applied++
    }
    catch { $failed++ }
    
    # Advanced
    Write-Step "[7/10] ADVANCED SETTINGS"
    
    # HPET
    try {
        Set-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Services\HPET" -Name "Start" -Value $settings.HPET -Desc "HPET Service"
        if ($settings.HPET -eq 4) {
            $null = bcdedit /deletevalue useplatformclock 2>&1
        }
        $applied++
    }
    catch { $failed++ }
    
    # Dynamic Tick
    try {
        $null = bcdedit /set disabledynamictick $settings.DynamicTick 2>&1
        Write-Host " [OK] Dynamic Tick: $($settings.DynamicTick)" -ForegroundColor Green
        $applied++
    }
    catch { $failed++ }
    
    # Process Priority
    Write-Step "[8/10] PROCESS PRIORITY"
    if (Set-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 38 -Desc "Process Priority") { $applied++ } else { $failed++ }
    
    # System Responsiveness
    Write-Step "[9/10] SYSTEM RESPONSIVENESS"
    $sysResponsiveness = if ($ProfileName -eq "GamingCompetitive") { 0 } elseif ($ProfileName -eq "Workstation") { 20 } else { 10 }
    if (Set-RegistryKey -Path $sysProfile -Name "SystemResponsiveness" -Value $sysResponsiveness -Desc "System Responsiveness") { $applied++ } else { $failed++ }
    
    # Save profile selection
    Write-Step "[10/10] SAVING CONFIGURATION"
    $configPath = "HKLM:\SOFTWARE\NeuralOptimizer"
    if (-not (Test-Path $configPath)) {
        New-Item -Path $configPath -Force | Out-Null
    }
    
    Set-ItemProperty -Path $configPath -Name "ActiveProfile" -Value $ProfileName -Force
    Set-ItemProperty -Path $configPath -Name "ProfileAppliedDate" -Value (Get-Date).ToString("yyyy-MM-dd HH:mm:ss") -Force
    
    # Summary
    Write-Host ""
    Write-Host " +========================================================+" -ForegroundColor Green
    Write-Host " |  PERFIL APLICADO EXITOSAMENTE                          |" -ForegroundColor Green
    Write-Host " +========================================================+" -ForegroundColor Green
    Write-Host ""
    Write-Host " Configuraciones aplicadas: $applied" -ForegroundColor Green
    Write-Host " Configuraciones fallidas:  $failed" -ForegroundColor $(if ($failed -gt 0) { "Yellow" } else { "Gray" })
    Write-Host ""
    Write-Host " [!] REINICIO REQUERIDO para aplicar todos los cambios" -ForegroundColor Yellow
    Write-Host ""
    
    return $true
}

# ============================================================================
# PROFILE COMPARISON
# ============================================================================

function Compare-Profiles {
    [CmdletBinding()]
    param(
        [string]$Profile1,
        [string]$Profile2
    )
    
    if (-not $Script:Profiles.ContainsKey($Profile1) -or -not $Script:Profiles.ContainsKey($Profile2)) {
        Write-Host " [!] Perfil no encontrado" -ForegroundColor Red
        return
    }
    
    $p1 = $Script:Profiles[$Profile1]
    $p2 = $Script:Profiles[$Profile2]
    
    Write-Host ""
    Write-Host " +========================================================+" -ForegroundColor Cyan
    Write-Host " |  COMPARACION DE PERFILES                               |" -ForegroundColor Cyan
    Write-Host " +========================================================+" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " $($p1.Name) vs $($p2.Name)" -ForegroundColor White
    Write-Host ""
    
    $keys = $p1.Settings.Keys | Sort-Object
    
    foreach ($key in $keys) {
        $v1 = $p1.Settings[$key]
        $v2 = $p2.Settings[$key]
        
        if ($v1 -ne $v2) {
            Write-Host " $($key.PadRight(25)): " -NoNewline
            Write-Host "$v1 " -ForegroundColor $p1.Color -NoNewline
            Write-Host "vs " -NoNewline
            Write-Host "$v2" -ForegroundColor $p2.Color
        }
    }
    
    Write-Host ""
}

# ============================================================================
# CURRENT PROFILE DETECTION
# ============================================================================

function Get-CurrentProfile {
    try {
        $configPath = "HKLM:\SOFTWARE\NeuralOptimizer"
        if (Test-Path $configPath) {
            $current = Get-ItemProperty -Path $configPath -Name "ActiveProfile" -ErrorAction SilentlyContinue
            if ($current) {
                return $current.ActiveProfile
            }
        }
    }
    catch {}
    
    return "None"
}

# ============================================================================
# MAIN MENU
# ============================================================================

function Show-ProfileMenu {
    Clear-Host
    
    Write-Host ""
    Write-Host " +========================================================+" -ForegroundColor Cyan
    Write-Host " |  PROFILE SYSTEM v5.0                                   |" -ForegroundColor Cyan
    Write-Host " +========================================================+" -ForegroundColor Cyan
    Write-Host ""
    
    $currentProfile = Get-CurrentProfile
    Write-Host " Perfil activo: " -NoNewline
    if ($currentProfile -eq "None") {
        Write-Host "Ninguno" -ForegroundColor Gray
    }
    else {
        $OptimProfile = $Script:Profiles[$currentProfile]
        Write-Host $OptimProfile.Name -ForegroundColor $OptimProfile.Color
    }
    
    Write-Host ""
    Write-Host " ╔═══════════════════════════════════════════════════════╗" -ForegroundColor Gray
    Write-Host " ║ PERFILES DISPONIBLES                                  ║" -ForegroundColor White
    Write-Host " ╠═══════════════════════════════════════════════════════╣" -ForegroundColor Gray
    
    $i = 1
    foreach ($OptimProfileKey in $Script:Profiles.Keys | Sort-Object) {
        $OptimProfile = $Script:Profiles[$OptimProfileKey]
        Write-Host " ║ $i. " -ForegroundColor Gray -NoNewline
        Write-Host "$($OptimProfile.Name.PadRight(48))" -ForegroundColor $OptimProfile.Color -NoNewline
        Write-Host " ║" -ForegroundColor Gray
        Write-Host " ║    $($OptimProfile.Description.Substring(0, [math]::Min(49, $OptimProfile.Description.Length)).PadRight(49)) ║" -ForegroundColor DarkGray
        $i++
    }
    
    Write-Host " ╠═══════════════════════════════════════════════════════╣" -ForegroundColor Gray
    Write-Host " ║ 6. Comparar dos perfiles                              ║" -ForegroundColor White
    Write-Host " ║ 7. Ver detalles de perfil                             ║" -ForegroundColor White
    Write-Host " ║ 0. Salir                                               ║" -ForegroundColor DarkGray
    Write-Host " ╚═══════════════════════════════════════════════════════╝" -ForegroundColor Gray
    Write-Host ""
}

# Main loop
while ($true) {
    Show-ProfileMenu
    
    $choice = Read-Host " >> Seleccione opción"
    
    $OptimProfileKeys = @($Script:Profiles.Keys | Sort-Object)
    
    switch ($choice) {
        { $_ -ge 1 -and $_ -le $OptimProfileKeys.Count } {
            $OptimProfileName = $OptimProfileKeys[$choice - 1]
            Invoke-ProfileApplication -ProfileName $OptimProfileName
            Wait-ForKeyPress
        }
        '6' {
            Write-Host ""
            Write-Host " Perfiles disponibles:" -ForegroundColor Cyan
            for ($i = 0; $i -lt $OptimProfileKeys.Count; $i++) {
                Write-Host "   $($i + 1). $($Script:Profiles[$OptimProfileKeys[$i]].Name)" -ForegroundColor Gray
            }
            Write-Host ""
            $p1 = Read-Host " >> Primer perfil (número)"
            $p2 = Read-Host " >> Segundo perfil (número)"
            
            if ($p1 -ge 1 -and $p1 -le $OptimProfileKeys.Count -and $p2 -ge 1 -and $p2 -le $OptimProfileKeys.Count) {
                Compare-Profiles -Profile1 $OptimProfileKeys[$p1 - 1] -Profile2 $OptimProfileKeys[$p2 - 1]
            }
            
            Wait-ForKeyPress
        }
        '7' {
            Write-Host ""
            Write-Host " Perfiles disponibles:" -ForegroundColor Cyan
            for ($i = 0; $i -lt $OptimProfileKeys.Count; $i++) {
                Write-Host "   $($i + 1). $($Script:Profiles[$OptimProfileKeys[$i]].Name)" -ForegroundColor Gray
            }
            Write-Host ""
            $p = Read-Host " >> Seleccione perfil (número)"
            
            if ($p -ge 1 -and $p -le $OptimProfileKeys.Count) {
                $OptimProfile = $Script:Profiles[$OptimProfileKeys[$p - 1]]
                Write-Host ""
                Write-Host " $($OptimProfile.Name)" -ForegroundColor $OptimProfile.Color
                Write-Host " $($OptimProfile.Description)" -ForegroundColor Gray
                Write-Host ""
                Write-Host " Configuraciones:" -ForegroundColor White
                foreach ($setting in $OptimProfile.Settings.GetEnumerator() | Sort-Object Name) {
                    Write-Host "   $($setting.Key.PadRight(30)): $($setting.Value)" -ForegroundColor Gray
                }
            }
            
            Wait-ForKeyPress
        }
        '0' {
            exit 0
        }
        default {
            Write-Host " [!] Opción no válida" -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}

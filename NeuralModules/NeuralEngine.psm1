# ==============================================================================
# MODULE: NeuralEngine.psm1
# DESCRIPTION: Core "Beast Mode" dynamic engine for applying optimizations.
# STANDARD: Shell-Scripting-Pro / Beast-Mode
# ==============================================================================

function Invoke-NeuralEngine {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RiskLevel, # Low, Medium, High

        [Parameter(Mandatory = $true)]
        [string]$OS # Windows 10, Windows 11
    )

    Write-Host "`n [NeuralEngine] Initializing Beast Mode Engine..." -ForegroundColor Cyan

    $scriptPath = Split-Path $MyInvocation.MyCommand.Path
    $libPath = Join-Path $scriptPath "NeuralTweakLibrary.psd1"

    if (-not (Test-Path $libPath)) {
        Write-Error "[CRITICAL] NeuralTweakLibrary.psd1 not found at $libPath"
        return
    }

    try {
        $data = Import-PowerShellDataFile -Path $libPath
        $tweaks = $data.TweakLibrary
        
        $stats = @{ Applied = 0; Skipped = 0; Failed = 0 }

        # Helper Context for ConditionScripts
        $TestLenovoSystem = { (Get-CimInstance Win32_ComputerSystem).Manufacturer -match "Lenovo" }

        foreach ($tweak in $tweaks) {
            # --- FILTERING LAYER ---
            
            # 1. Risk Filter
            if ($RiskLevel -eq "Low" -and $tweak.Risk -ne "Low") { $stats.Skipped++; continue }
            if ($RiskLevel -eq "Medium" -and $tweak.Risk -eq "High") { $stats.Skipped++; continue }

            # 2. OS Compatibility Filter
            if ($tweak.MinOS -and $tweak.MinOS -ne $OS) { $stats.Skipped++; continue }

            # 3. Dynamic Condition Filter
            if ($tweak.ConditionScript) {
                try {
                    $shouldRun = $false
                    if ($tweak.ConditionScript -eq "Test-LenovoSystem") {
                        $shouldRun = & $TestLenovoSystem
                    }
                    else {
                        $shouldRun = Invoke-Expression $tweak.ConditionScript
                    }

                    if (-not $shouldRun) { $stats.Skipped++; continue }
                }
                catch {
                    Write-Warning "[Engine] Condition check failed for $($tweak.Name): $_"
                    $stats.Failed++
                    continue
                }
            }

            # --- EXECUTION LAYER ---
            try {
                if ($PSCmdlet.ShouldProcess($tweak.Name, "Apply Optimization")) {
                    # Write-Host "   [+] Applying: $($tweak.Name)" -ForegroundColor DarkGray
                    
                    if ($tweak.Path) {
                        # Registry Tweak
                        # Ensure parent path exists to avoid "Ghost Keys" in random places if root is missing
                        if (-not (Test-Path $tweak.Path)) {
                            New-Item -Path $tweak.Path -Force -ErrorAction SilentlyContinue | Out-Null
                        }
                        
                        Set-ItemProperty -Path $tweak.Path -Name $tweak.Key -Value $tweak.ValueOn -Type DWord -ErrorAction Stop
                    }
                    elseif ($tweak.CommandOn) {
                        # PowerShell Command Tweak
                        Invoke-Expression $tweak.CommandOn | Out-Null
                    }
                    else {
                        Write-Warning "Tweak $($tweak.Name) has no Action!"
                    }
                    $stats.Applied++
                }
            }
            catch {
                Write-Error "[FAIL] $($tweak.Name): $_"
                $stats.Failed++
            }
        }

        Write-Host " [NeuralEngine] Cycle Complete. Applied: $($stats.Applied) | Skipped: $($stats.Skipped) | Errors: $($stats.Failed)" -ForegroundColor Green
    }
    catch {
        Write-Error "[FATAL] Engine Crash: $_"
    }
}

function Invoke-LegacyPurge {
    [CmdletBinding()]
    param()
    
    Write-Host "`n [NeuralEngine] Analizando sistema en busca de tweaks obsoletos (Snake Oil)..." -ForegroundColor Cyan
    
    $legacyKeys = @(
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name = "DisablePagingExecutive"; DefaultValue = 0; Type = "DWord" }
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name = "LargeSystemCache"; DefaultValue = 0; Type = "DWord" }
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name = "IoPageLockLimit"; DefaultValue = $null; Type = "Delete" }
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name = "TcpWindowSize"; DefaultValue = $null; Type = "Delete" }
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name = "GlobalMaxTcpWindowSize"; DefaultValue = $null; Type = "Delete" }
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name = "MaxConnectionsPerServer"; DefaultValue = $null; Type = "Delete" }
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control"; Name = "WaitToKillServiceTimeout"; DefaultValue = "5000"; Type = "String" }
        @{ Path = "HKCU:\Control Panel\Desktop"; Name = "MenuShowDelay"; DefaultValue = "400"; Type = "String" }
    )
    
    $foundCount = 0
    
    foreach ($item in $legacyKeys) {
        if (Test-Path $item.Path) {
            $currentValue = Get-ItemProperty -Path $item.Path -Name $item.Name -ErrorAction SilentlyContinue
            
            if ($currentValue) {
                $val = $currentValue.$($item.Name)
                
                # Check if value is non-default (or exists if it should be deleted)
                $isBad = $false
                if ($item.Type -eq "Delete") { $isBad = $true }
                elseif ($val -ne $item.DefaultValue) { $isBad = $true }
                
                if ($isBad) {
                    Write-Host "   [!] Tweak Obsoleto Detectado: $($item.Name) = $val" -ForegroundColor Yellow
                    $foundCount++
                    
                    if ($item.Type -eq "Delete") {
                        Remove-ItemProperty -Path $item.Path -Name $item.Name -ErrorAction SilentlyContinue
                        Write-Host "       >>> ELIMINADO (Restaurado a default)" -ForegroundColor Green
                    }
                    else {
                        Set-ItemProperty -Path $item.Path -Name $item.Name -Value $item.DefaultValue -Type $item.Type -ErrorAction SilentlyContinue
                        Write-Host "       >>> REVERTIDO A $($item.DefaultValue)" -ForegroundColor Green
                    }
                }
            }
        }
    }
    
    if ($foundCount -eq 0) {
        Write-Host "   [OK] Sistema limpio. No se detectaron tweaks obsoletos." -ForegroundColor Green
    }
    else {
        Write-Host "   [OK] Limpieza completada. $foundCount tweaks revertidos." -ForegroundColor Green
    }
}

Export-ModuleMember -Function Invoke-NeuralEngine, Invoke-LegacyPurge

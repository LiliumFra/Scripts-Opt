<#
.SYNOPSIS
    Advanced Registry Optimization v6.0
    Deep system tweaks for input lag, latency, and gaming scheduling.
    WARNING: Advanced users only. Creates Restore Point automatically.

.DESCRIPTION
    Tweaks included:
    - HAGS (Hardware-Accelerated GPU Scheduling)
    - GameDVR FSE (Full Screen Optimizations) Disabler
    - Network Throttling Index Removal
    - Power Throttling Disabler
    - Multimedia Class Scheduler Service (MMCSS) Gaming Priority
    - Win32PrioritySeparation tuning

.NOTES
    Part of Windows Neural Optimizer v6.0 ULTRA
    Credits: Jose Bustamante
#>

if (-not (Get-Command "Write-Log" -ErrorAction SilentlyContinue)) {
    $currentDir = Split-Path $MyInvocation.MyCommand.Path
    $utilsPath = Join-Path $currentDir "NeuralUtils.psm1"
    if (Test-Path $utilsPath) { Import-Module $utilsPath -Force -DisableNameChecking }
}

Invoke-AdminCheck

function Set-RegistryTweak {
    param($Path, $Name, $Value, $Type = "DWord", $Description)
    
    Write-Host " [Pending] $Description" -ForegroundColor Gray
    
    try {
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
        
        Set-RegistryKey -Path $Path -Name $Name -Value $Value -Type $Type -Desc $Description
        Write-Host " [Applied] $Description" -ForegroundColor Green
    }
    catch {
        Write-Host " [Error] Failed: $_" -ForegroundColor Red
    }
}

function Optimize-GamingRegistry {
    Write-Section "ADVANCED REGISTRY OPTIMIZATIONS"
    
    Write-Host " [i] Creating System Restore Point..." -ForegroundColor Cyan
    Checkpoint-Computer -Description "NeuralOptimizer_RegistryTweaks_$(Get-Date -Format 'yyyyMMdd')" -RestorePointType MODIFY_SETTINGS -ErrorAction SilentlyContinue
    
    Write-Host ""
    Write-Step "[1] GPU & GRAPHICS"
    
    # HAGS (Requires Reboot)
    Set-RegistryTweak -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Value 2 -Description "Enable Hardware-Accelerated GPU Scheduling"
    
    # GameDVR FSE (Disable Fullscreen Optimizations) - Mode 2 is 'Disable'
    Set-RegistryTweak -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehaviorMode" -Value 2 -Description "Disable Full-Screen Optimizations (Global)"
    Set-RegistryTweak -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_HonorUserFSEBehaviorMode" -Value 0 -Description "Enforce FSE Disable Preference"
    
    Write-Host ""
    Write-Step "[2] PROCESS & SCHEDULING"
    
    # Network Throttling (FFFFFFFF = Disabled)
    Set-RegistryTweak -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xFFFFFFFF -Description "Disable Network Throttling"
    
    # System Responsiveness (0 = max for games/multimedia)
    Set-RegistryTweak -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 0 -Description "Maximize System Responsiveness for Games"
    
    # Power Throttling (Disable for all apps)
    Set-RegistryTweak -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" -Name "PowerThrottlingOff" -Value 1 -Description "Disable Power Throttling"
    
    # Win32Priorities (26 Hex = 38 Dec - Good balance, favors foreground)
    Set-RegistryTweak -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 38 -Description "Optimize Foreground Priority (26 Hex)"
    
    Write-Host ""
    Write-Step "[3] GAMING TASK PRIORITY"
    
    $gamesPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
    Set-RegistryTweak -Path $gamesPath -Name "GPU Priority" -Value 8 -Description "Set GPU Priority High"
    Set-RegistryTweak -Path $gamesPath -Name "Priority" -Value 6 -Description "Set CPU Priority High"
    Set-RegistryTweak -Path $gamesPath -Name "Scheduling Category" -Value "High" -Type "String" -Description "Set Scheduling Category High"
    Set-RegistryTweak -Path $gamesPath -Name "SFIO Priority" -Value "High" -Type "String" -Description "Set SFIO Priority High"
    
    Write-Host ""
    Write-Host " [OK] Optimizations Applied. REBOOT REQUIRED." -ForegroundColor Green
    Write-Host " [i] A restore point was created if you need to rollback." -ForegroundColor Gray
    
    Write-Host ""
    # Wait-ForKeyPress removed (Handled by Main Menu)
}

Optimize-GamingRegistry


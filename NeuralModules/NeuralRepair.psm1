<#
.SYNOPSIS
    Neural-Repair Module
    Automated repair strategies for common post-optimization issues.

.DESCRIPTION
    Provides targeted fixes for:
    - Lenovo Fn/Hotkey failures (Service restart)
    - Audio service glitches
    - General service restoration

.NOTES
    Part of Windows Neural Optimizer
#>

$Script:RepairLog = "$PSScriptRoot\..\NeuralRepair.log"

function Write-RepairLog {
    param($Message)
    $Entry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
    Add-Content -Path $Script:RepairLog -Value $Entry
    Write-Host $Entry -ForegroundColor Cyan
}

function Repair-LenovoFnKeys {
    <#
    .SYNOPSIS
        Restores Lenovo Function Keys (Volume, Brightness, etc.)
    .DESCRIPTION
        Checks and restarts the critical services:
        - LenovoFnAndFunctionKeys
        - HidServ (Human Interface Device)
        - LenovoUtility (Appx)
    #>
    Write-RepairLog "Starting Lenovo Fn Key Repair..."

    # 1. Human Interface Device Service (Critical for generic media keys)
    $HidService = Get-Service -Name "HidServ" -ErrorAction SilentlyContinue
    if ($HidService) {
        if ($HidService.Status -ne 'Running') {
            Write-RepairLog "Starting HidServ..."
            Set-Service -Name "HidServ" -StartupType MultiInstance
            Start-Service -Name "HidServ"
        }
    }

    # 2. Lenovo Specific Services
    $LenovoSvcs = @("LenovoFnAndFunctionKeys", "LITSSVC", "LenovoUtility")
    foreach ($SvcName in $LenovoSvcs) {
        $Svc = Get-Service -Name $SvcName -ErrorAction SilentlyContinue
        if ($Svc) {
            Write-RepairLog "Found Lenovo Service: $SvcName"
            if ($Svc.Status -ne 'Running') {
                Write-RepairLog "Restoring $SvcName..."
                Set-Service -Name $SvcName -StartupType Automatic
                Start-Service -Name $SvcName
            }
            else {
                # Force restart if already running but broken
                Write-RepairLog "Restarting $SvcName to refresh hooks..."
                Restart-Service -Name $SvcName -Force
            }
        }
    }

    # 3. Scan for Lenovo Utility Appx (Modern Lenovo Apps)
    $LenovoApp = Get-AppxPackage -Name "*LenovoUtility*" -ErrorAction SilentlyContinue
    if ($LenovoApp) {
        Write-RepairLog "Registering Lenovo Utility Appx..."
        Add-AppxPackage -Register "$($LenovoApp.InstallLocation)\AppxManifest.xml" -DisableDevelopmentMode -ErrorAction SilentlyContinue
    }

    Write-RepairLog "Lenovo Fn Key Repair Sequence Completed."
}

function Repair-AudioServices {
    <#
    .SYNOPSIS
        Restores Audio Services (often linked to Vol keys)
    #>
    Write-RepairLog "Restoring Audio Services..."
    $AudioSvcs = @("Audiosrv", "AudioEndpointBuilder")
    
    foreach ($Svc in $AudioSvcs) {
        Start-Service -Name $Svc -ErrorAction SilentlyContinue
        Set-Service -Name $Svc -StartupType Automatic -ErrorAction SilentlyContinue
    }
}

function Invoke-NeuralRepair {
    <#
    .SYNOPSIS
        Main entry point for repairs
    .PARAMETER Target
        The target system to repair (e.g., "Lenovo", "Audio", "All")
    #>
    param(
        [ValidateSet("Lenovo", "Audio", "All")]
        [string]$Target = "All"
    )

    Write-RepairLog "=== Neural Repair Diagnostics Started [$Target] ==="

    if ($Target -eq "Lenovo" -or $Target -eq "All") {
        # Auto-detect Lenovo hardware
        $IsLenovo = (Get-WmiObject Win32_ComputerSystem).Manufacturer -match "Lenovo"
        if ($IsLenovo) {
            Repair-LenovoFnKeys
        }
        else {
            Write-RepairLog "Lenovo hardware not detected. Skipping Lenovo specific repairs."
        }
    }

    if ($Target -eq "Audio" -or $Target -eq "All") {
        Repair-AudioServices
    }

    Write-RepairLog "=== Repair Complete ==="
}

Export-ModuleMember -Function Invoke-NeuralRepair, Repair-LenovoFnKeys, Repair-AudioServices

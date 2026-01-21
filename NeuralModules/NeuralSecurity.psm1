<#
.SYNOPSIS
    Neural-Security Module
    Implements security hardening audits and optimizations.
.DESCRIPTION
    Provides functions to audit system security and apply hardening tweaks.
    Integrated with Neural-AI for risk assessment.
#>

$Script:SecurityTweaks = @(
    @{ Id = "SecSMB1"; Name = "Disable SMBv1"; Risk = "Low"; CommandOn = "Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart"; CommandOff = "Enable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart"; Description = "Disable vulnerable SMBv1 protocol" },
    @{ Id = "SecNetBIOS"; Name = "Disable NetBIOS over TCP/IP"; Risk = "Medium"; Path = "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces"; Key = "NetbiosOptions"; ValueOn = 2; ValueOff = 0; Description = "Disable NetBIOS (reduces attack surface)" },
    @{ Id = "SecAnonEnum"; Name = "Restrict Anonymous Enumeration"; Risk = "Medium"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"; Key = "RestrictAnonymous"; ValueOn = 1; ValueOff = 0; Description = "Prevent anonymous user enumeration" },
    @{ Id = "SecRemoteReg"; Name = "Disable Remote Registry"; Risk = "Low"; CommandOn = "sc config RemoteRegistry start= disabled & sc stop RemoteRegistry"; CommandOff = "sc config RemoteRegistry start= manual"; Description = "Prevent remote registry access" },
    @{ Id = "SecDep"; Name = "Enable DEP (Always On)"; Risk = "Medium"; CommandOn = "bcdedit /set nx alwayson"; CommandOff = "bcdedit /set nx optin"; Description = "Force Data Execution Prevention" }
)

function Get-SecurityAudit {
    $audit = @{}
    foreach ($tweak in $Script:SecurityTweaks) {
        $status = "Unknown"
        try {
            if ($tweak.Path) {
                $val = Get-ItemProperty -Path $tweak.Path -Name $tweak.Key -ErrorAction SilentlyContinue
                if ($val -and $val.($tweak.Key) -eq $tweak.ValueOn) { $status = "Secure" }
                else { $status = "Vulnerable" }
            }
            elseif ($tweak.Id -eq "SecSMB1") {
                if ((Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol).State -eq "Disabled") { $status = "Secure" } else { $status = "Vulnerable" }
            }
            # Add other command-based checks here as needed
        }
        catch {}
        $audit[$tweak.Id] = $status
    }
    return $audit
}

function Invoke-SecurityHardening {
    param([string]$TweakId, [switch]$Revert)
    
    $tweak = $Script:SecurityTweaks | Where-Object { $_.Id -eq $TweakId }
    if (-not $tweak) { return $false }
    
    try {
        if ($tweak.Path) {
            $value = if ($Revert) { $tweak.ValueOff } else { $tweak.ValueOn }
            if (-not (Test-Path $tweak.Path)) { New-Item -Path $tweak.Path -Force | Out-Null }
            Set-ItemProperty -Path $tweak.Path -Name $tweak.Key -Value $value -Force
            return $true
        }
        elseif ($tweak.CommandOn) {
            $cmd = if ($Revert) { $tweak.CommandOff } else { $tweak.CommandOn }
            Invoke-Expression $cmd | Out-Null
            return $true
        }
    }
    catch { Write-Host "Error applying $TweakId : $_" -ForegroundColor Red }
    return $false
}

Export-ModuleMember -Function Get-SecurityAudit, Invoke-SecurityHardening

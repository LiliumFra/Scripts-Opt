<#
.SYNOPSIS
    Apply-Safe-Optimization.ps1
    Reverts risky tweaks and applies safe, recommended optimizations.
    
.DESCRIPTION
    1. Reverts "Risky" memory and network tweaks to Windows Defaults.
    2. Runs Smart-Optimizer to apply safe, hardware-aware optimizations.
#>

# Ensure we are in the script directory
$Script:ScriptDir = $PSScriptRoot
$Script:ModuleDir = Join-Path -Path $Script:ScriptDir -ChildPath "NeuralModules"
$Script:UtilsPath = Join-Path -Path $Script:ModuleDir -ChildPath "NeuralUtils.psm1"

# Import Utils
if (Test-Path $Script:UtilsPath) {
    Import-Module $Script:UtilsPath -Force -DisableNameChecking
}
else {
    Write-Host "Error: NeuralUtils not found at $Script:UtilsPath" -ForegroundColor Red
    exit 1
}

# Auto-elevation logic
if (-not (Test-AdminPrivileges)) {
    Write-Host " [!] Requesting Admin Privileges..." -ForegroundColor Yellow
    $scriptPath = $MyInvocation.MyCommand.Path
    try {
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs -Wait
        exit 0
    }
    catch {
        Write-Host " [X] Failed to elevate. Please run as Administrator manually." -ForegroundColor Red
        exit 1
    }
}

Write-Section "NEURAL OPTIMIZER - SAFE RESTORATION"

# 1. REVERT RISKY TWEAKS
Write-Step "[1/2] REVERTING RISKY SETTINGS (Safety First)"

$reverts = @(
    # Memory Management Safe Defaults
    @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name = "DisablePagingExecutive"; Value = 0; Desc = "Revert: Kernel Paging (Default ON)" },
    @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name = "LargeSystemCache"; Value = 0; Desc = "Revert: Large System Cache (Default OFF)" },
    
    # System Responsiveness (20% is default for workstations)
    @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"; Name = "SystemResponsiveness"; Value = 20; Desc = "Revert: System Responsiveness (20%)" },
    
    # Network Throttling (Default is 10, not disabled)
    @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"; Name = "NetworkThrottlingIndex"; Value = 10; Desc = "Revert: Network Throttling (Default)" }
)

foreach ($r in $reverts) {
    Set-RegistryKey -Path $r.Path -Name $r.Name -Value $r.Value -Desc $r.Desc
}

Write-Host "   [OK] Risky settings reverted to safe defaults." -ForegroundColor Green
Write-Host ""

# 2. RUN SMART OPTIMIZER
Write-Step "[2/2] APPLYING RECOMMENDED OPTIMIZATIONS"
Write-Host "   Invoking Smart-Optimizer to detect hardware and apply safe profiles..." -ForegroundColor Cyan
Write-Host ""

$smartScript = Join-Path $Script:ModuleDir "Smart-Optimizer.ps1"
if (Test-Path $smartScript) {
    # Run Smart-Optimizer
    # We use '&' to run it in current scope or new process. 
    # Since it has interactive prompts, we might want to suppress them or handle them.
    # Smart-Optimizer asks for confirmation. We can try to pipe 'S' to it or modify it to accept a flag.
    # For now, let the user interact or we'll simulate input if possible.
    # Actually, the user asked to "apply recommended", implying automation. 
    # But Smart-Optimizer reads host. 
    # I will run it and the user can see the output.
    
    # To automate the "S" confirmation in Smart-Optimizer:
    # "echo S | powershell ..." approach for external call, or modify call.
    # But simpler: Just run it. The user will see the prompt in the output if I run it interactively?
    # No, run_command is non-interactive usually unless I use Send-CommandInput. 
    # BUT, I can pass input via pipeline in PowerShell?
    # "S" | & $smartScript 
    
    # Let's try piping "S" (Yes) to automatically accept the hardware profile.
    "S" | & $smartScript
}
else {
    Write-Host "   [ERROR] Smart-Optimizer.ps1 not found!" -ForegroundColor Red
}

Write-Host ""
Write-Host " +========================================================+" -ForegroundColor Green
Write-Host " |  SAFE OPTIMIZATION COMPLETE                            |" -ForegroundColor Green
Write-Host " +========================================================+" -ForegroundColor Green
Write-Host ""


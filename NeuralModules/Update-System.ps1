<#
.SYNOPSIS
    System Update Module v6.0
    Automatically updates the Neural Optimizer using Git.

.DESCRIPTION
    Wraps 'git pull' with safety checks and status reporting.
    Requires Git to be installed and the script to be in a git repo.
    
.NOTES
    Part of Windows Neural Optimizer v6.0 ULTRA
    Credits: Jose Bustamante
#>

if (-not (Get-Command "Write-Log" -ErrorAction SilentlyContinue)) {
    $currentDir = Split-Path $MyInvocation.MyCommand.Path
    $utilsPath = Join-Path $currentDir "NeuralUtils.psm1"
    if (Test-Path $utilsPath) { Import-Module $utilsPath -Force -DisableNameChecking }
}

function Update-NeuralSystem {
    Write-Section "SYSTEM UPDATE"
    
    # Check for Git
    if (-not (Get-Command "git" -ErrorAction SilentlyContinue)) {
        Write-Host " [!] Git is not installed or not in PATH." -ForegroundColor Red
        Write-Host "     Please install Git to use auto-update features." -ForegroundColor Gray
        Wait-ForKeyPress
        return
    }
    
    Write-Host " [i] Checking for updates..." -ForegroundColor Cyan
    Write-Host ""
    
    try {
        # Check remote status
        $status = git remote -v 2>&1
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($status)) {
            Write-Host " [!] Not a valid git repository or remote not configured." -ForegroundColor Red
            Write-Host "     Debug: $status" -ForegroundColor DarkGray
            Wait-ForKeyPress
            return
        }
        
        # Pull
        $output = git pull 2>&1
        
        if ($output -match "Already up to date") {
            Write-Host " [OK] System is fully up to date." -ForegroundColor Green
            Write-Host "      Version: v6.0 ULTRA" -ForegroundColor Gray
        }
        elseif ($LASTEXITCODE -eq 0) {
            Write-Host " [OK] Update Successful!" -ForegroundColor Green
            Write-Host ""
            Write-Host " Changes applied:" -ForegroundColor Gray
            $output | ForEach-Object { Write-Host "   $_" -ForegroundColor DarkGray }
            
            Write-Host ""
            Write-Host " [!] PLEASE RESTART THE OPTIMIZER TO APPLY CHANGES." -ForegroundColor Yellow
        }
        else {
            Write-Host " [!] Update Failed." -ForegroundColor Red
            Write-Host "     Git Output:" -ForegroundColor Red
            $output | ForEach-Object { Write-Host "   $_" -ForegroundColor Red }
        }
    }
    catch {
        Write-Host " [!] Critical Error: $_" -ForegroundColor Red
    }
    
    Write-Host ""
    Wait-ForKeyPress
}

Update-NeuralSystem



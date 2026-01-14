<#
.SYNOPSIS
    Update-Checker.ps1 - Git-based auto-update system

.DESCRIPTION
    Checks for updates on script startup by comparing local and remote git commits.

.NOTES
    Part of Windows Neural Optimizer v6.1
    Author: Jose Bustamante
#>

$Script:RepoPath = Split-Path $PSScriptRoot -Parent

function Test-GitInstalled {
    try {
        $null = git --version 2>$null
        return $true
    }
    catch { return $false }
}

function Test-GitRepository {
    param([string]$Path = $Script:RepoPath)
    $gitDir = Join-Path $Path ".git"
    return (Test-Path $gitDir)
}

function Get-LocalCommit {
    param([string]$Path = $Script:RepoPath)
    try {
        Push-Location $Path
        $commit = git rev-parse HEAD 2>$null
        Pop-Location
        return $commit
    }
    catch {
        Pop-Location
        return $null
    }
}

function Get-RemoteCommit {
    param([string]$Path = $Script:RepoPath)
    try {
        Push-Location $Path
        git fetch origin --quiet 2>$null
        $commit = git rev-parse origin/main 2>$null
        if (-not $commit) { $commit = git rev-parse origin/master 2>$null }
        Pop-Location
        return $commit
    }
    catch {
        Pop-Location
        return $null
    }
}

function Get-CommitsBehind {
    param([string]$Path = $Script:RepoPath)
    try {
        Push-Location $Path
        $behind = git rev-list HEAD..origin/main --count 2>$null
        if (-not $behind) { $behind = git rev-list HEAD..origin/master --count 2>$null }
        Pop-Location
        return [int]$behind
    }
    catch {
        Pop-Location
        return 0
    }
}

function Test-UpdatesAvailable {
    $result = @{
        UpdatesAvailable = $false
        CommitsBehind    = 0
        LocalCommit      = $null
        RemoteCommit     = $null
        Error            = $null
    }
    
    if (-not (Test-GitInstalled)) {
        $result.Error = "Git not installed"
        return $result
    }
    
    if (-not (Test-GitRepository)) {
        $result.Error = "Not a git repository"
        return $result
    }
    
    $result.LocalCommit = Get-LocalCommit
    $result.RemoteCommit = Get-RemoteCommit
    
    if (-not $result.LocalCommit -or -not $result.RemoteCommit) {
        $result.Error = "Could not fetch commits"
        return $result
    }
    
    if ($result.LocalCommit -ne $result.RemoteCommit) {
        $result.UpdatesAvailable = $true
        $result.CommitsBehind = Get-CommitsBehind
    }
    
    return $result
}

function Invoke-GitPull {
    param([string]$Path = $Script:RepoPath)
    try {
        Push-Location $Path
        $output = git pull origin main 2>&1
        if (-not $?) { $output = git pull origin master 2>&1 }
        Pop-Location
        return @{ Success = $true; Output = $output }
    }
    catch {
        Pop-Location
        return @{ Success = $false; Output = $_.Exception.Message }
    }
}

function Show-UpdateNotification {
    param($UpdateInfo)
    
    if (-not $UpdateInfo.UpdatesAvailable) { return $false }
    
    Write-Host ""
    Write-Host " === UPDATES AVAILABLE ===" -ForegroundColor Yellow
    Write-Host " You are $($UpdateInfo.CommitsBehind) commit(s) behind." -ForegroundColor White
    Write-Host ""
    
    $response = Read-Host " >> Update now? (Y/N)"
    
    if ($response -match "^[Yy]") {
        Write-Host " [+] Pulling latest changes..." -ForegroundColor Cyan
        $result = Invoke-GitPull
        
        if ($result.Success) {
            Write-Host " [OK] Update successful! Please restart." -ForegroundColor Green
            Read-Host " Press ENTER"
            return $true
        }
        else {
            Write-Host " [!] Update failed: $($result.Output)" -ForegroundColor Red
            return $false
        }
    }
    
    return $false
}

function Invoke-StartupUpdateCheck {
    Write-Host " [+] Checking for updates..." -ForegroundColor DarkGray
    
    $updateInfo = Test-UpdatesAvailable
    
    if ($updateInfo.Error) {
        Write-Host " [i] Update check skipped: $($updateInfo.Error)" -ForegroundColor DarkGray
        return $false
    }
    
    if ($updateInfo.UpdatesAvailable) {
        return Show-UpdateNotification -UpdateInfo $updateInfo
    }
    else {
        Write-Host " [OK] Running latest version." -ForegroundColor Green
        return $false
    }
}

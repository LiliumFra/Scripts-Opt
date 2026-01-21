<#
.SYNOPSIS
    NeuralScheduler.psm1 - Task Scheduler Integration for Neural Optimizer v7.0

.DESCRIPTION
    Manages automatic scheduled tasks for:
    - Cache cleanup (on idle)
    - Weekly optimization
    - AI learning sessions

.NOTES
    Part of Windows Neural Optimizer v7.0
    Author: Jose Bustamante
#>

$Script:ModulePath = Split-Path $MyInvocation.MyCommand.Path -Parent
$Script:ParentPath = Split-Path $Script:ModulePath -Parent
$Script:TaskPrefix = "NeuralOptimizer"

# ============================================================================
# TASK REGISTRATION
# ============================================================================

function Register-NeuralCacheTask {
    <#
    .SYNOPSIS
        Registers automatic cache cleanup task
    .DESCRIPTION
        Creates a Windows Task Scheduler job that:
        - Triggers when system is idle for 5+ minutes
        - Runs silently in background
        - Repeats daily
    #>
    param(
        [int]$IdleMinutes = 5,
        [switch]$Force
    )
    
    $taskName = "$Script:TaskPrefix-CacheCleanup"
    
    # Check if task already exists
    $existing = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existing -and -not $Force) {
        Write-Host " [i] Task '$taskName' already exists. Use -Force to recreate." -ForegroundColor Yellow
        return $false
    }
    
    if ($existing) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }
    
    try {
        $scriptPath = Join-Path $Script:ParentPath "Run-NeuralCache.bat"
        
        # Action: Run the cache cleaner in silent mode
        $action = New-ScheduledTaskAction -Execute $scriptPath -Argument "--auto --silent"
        
        # Trigger: On idle (daily check)
        $trigger = New-ScheduledTaskTrigger -Daily -At "3:00AM"
        
        # Settings
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfIdle -IdleDuration (New-TimeSpan -Minutes $IdleMinutes)
        
        # Principal: Run as SYSTEM for permissions
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        
        # Register
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Neural Optimizer - Automatic Cache Cleanup" -Force
        
        Write-Host " [OK] Task '$taskName' registered successfully." -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host " [X] Failed to register task: $_" -ForegroundColor Red
        return $false
    }
}

function Register-NeuralOptimizeTask {
    <#
    .SYNOPSIS
        Registers weekly optimization task
    #>
    param([switch]$Force)
    
    $taskName = "$Script:TaskPrefix-WeeklyOptimize"
    
    $existing = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existing -and -not $Force) {
        Write-Host " [i] Task '$taskName' already exists." -ForegroundColor Yellow
        return $false
    }
    
    if ($existing) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }
    
    try {
        $scriptPath = Join-Path $Script:ParentPath "Optimize-Windows.ps1"
        
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`" -AutoOptimize -Silent"
        $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At "4:00AM"
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Neural Optimizer - Weekly System Optimization" -Force
        
        Write-Host " [OK] Task '$taskName' registered." -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host " [X] Failed to register task: $_" -ForegroundColor Red
        return $false
    }
}

function Register-NeuralAILearningTask {
    <#
    .SYNOPSIS
        Registers AI learning session task
    #>
    param([switch]$Force)
    
    $taskName = "$Script:TaskPrefix-AILearning"
    
    $existing = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existing -and -not $Force) {
        Write-Host " [i] Task '$taskName' already exists." -ForegroundColor Yellow
        return $false
    }
    
    if ($existing) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }
    
    try {
        $aiScript = Join-Path $Script:ModulePath "AI-Recommendations.ps1"
        
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$aiScript`" -AutoLearn"
        $trigger = New-ScheduledTaskTrigger -Daily -At "2:00AM"
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfIdle -IdleDuration (New-TimeSpan -Minutes 10)
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Neural Optimizer - AI Learning Session" -Force
        
        Write-Host " [OK] Task '$taskName' registered." -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host " [X] Failed to register task: $_" -ForegroundColor Red
        return $false
    }
}

# ============================================================================
# TASK MANAGEMENT
# ============================================================================

function Get-NeuralScheduledTasks {
    <#
    .SYNOPSIS
        Lists all Neural Optimizer scheduled tasks
    #>
    $tasks = Get-ScheduledTask -TaskName "$Script:TaskPrefix*" -ErrorAction SilentlyContinue
    
    if (-not $tasks) {
        Write-Host " [i] No Neural Optimizer tasks found." -ForegroundColor Yellow
        return @()
    }
    
    $results = @()
    foreach ($task in $tasks) {
        $info = Get-ScheduledTaskInfo -TaskName $task.TaskName -ErrorAction SilentlyContinue
        $results += [PSCustomObject]@{
            Name       = $task.TaskName.Replace("$Script:TaskPrefix-", "")
            State      = $task.State
            LastRun    = if ($info) { $info.LastRunTime } else { "Never" }
            NextRun    = if ($info) { $info.NextRunTime } else { "N/A" }
            LastResult = if ($info) { $info.LastTaskResult } else { "N/A" }
        }
    }
    
    return $results
}

function Unregister-NeuralTasks {
    <#
    .SYNOPSIS
        Removes all Neural Optimizer scheduled tasks
    #>
    param([switch]$Confirm)
    
    $tasks = Get-ScheduledTask -TaskName "$Script:TaskPrefix*" -ErrorAction SilentlyContinue
    
    if (-not $tasks) {
        Write-Host " [i] No tasks to remove." -ForegroundColor Yellow
        return
    }
    
    foreach ($task in $tasks) {
        try {
            Unregister-ScheduledTask -TaskName $task.TaskName -Confirm:$Confirm
            Write-Host " [OK] Removed: $($task.TaskName)" -ForegroundColor Green
        }
        catch {
            Write-Host " [X] Failed to remove $($task.TaskName): $_" -ForegroundColor Red
        }
    }
}

function Enable-NeuralTask {
    param([string]$TaskType)
    
    $taskName = "$Script:TaskPrefix-$TaskType"
    Enable-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    Write-Host " [OK] Enabled: $taskName" -ForegroundColor Green
}

function Disable-NeuralTask {
    param([string]$TaskType)
    
    $taskName = "$Script:TaskPrefix-$TaskType"
    Disable-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    Write-Host " [OK] Disabled: $taskName" -ForegroundColor Yellow
}

function Start-NeuralTaskNow {
    <#
    .SYNOPSIS
        Manually triggers a Neural task immediately
    #>
    param([string]$TaskType)
    
    $taskName = "$Script:TaskPrefix-$TaskType"
    Start-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    Write-Host " [OK] Started: $taskName" -ForegroundColor Cyan
}

# ============================================================================
# QUICK SETUP
# ============================================================================

function Initialize-NeuralScheduler {
    <#
    .SYNOPSIS
        Sets up all recommended automatic tasks
    #>
    Write-Host ""
    Write-Host " === NEURAL SCHEDULER SETUP ===" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host " Registering automatic tasks..." -ForegroundColor Gray
    
    $results = @{
        CacheCleanup   = Register-NeuralCacheTask -Force
        WeeklyOptimize = Register-NeuralOptimizeTask -Force
        AILearning     = Register-NeuralAILearningTask -Force
    }
    
    Write-Host ""
    Write-Host " === SETUP COMPLETE ===" -ForegroundColor Green
    Write-Host ""
    
    $tasks = Get-NeuralScheduledTasks
    $tasks | Format-Table -AutoSize
    
    return $results
}

Export-ModuleMember -Function @(
    'Register-NeuralCacheTask',
    'Register-NeuralOptimizeTask',
    'Register-NeuralAILearningTask',
    'Get-NeuralScheduledTasks',
    'Unregister-NeuralTasks',
    'Enable-NeuralTask',
    'Disable-NeuralTask',
    'Start-NeuralTaskNow',
    'Initialize-NeuralScheduler'
)

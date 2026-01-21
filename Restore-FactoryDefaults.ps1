Write-Host "=== Restoring Factory Defaults for Risky Tweaks ===" -ForegroundColor Cyan

# 1. Memory Management Defaults
Write-Host "Restoring Memory Management..."
$MemPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"

# IoPageLockLimit -> 0 (Default)
Set-ItemProperty -Path $MemPath -Name "IoPageLockLimit" -Value 0 -Force -ErrorAction SilentlyContinue
Write-Host " [OK] IoPageLockLimit -> 0" -ForegroundColor Green

# LargeSystemCache -> 0 (Standard for Desktop/Laptop)
Set-ItemProperty -Path $MemPath -Name "LargeSystemCache" -Value 0 -Force -ErrorAction SilentlyContinue
Write-Host " [OK] LargeSystemCache -> 0" -ForegroundColor Green

# NonPagedPoolSize -> 0 (Auto-managed)
Set-ItemProperty -Path $MemPath -Name "NonPagedPoolSize" -Value 0 -Force -ErrorAction SilentlyContinue
Write-Host " [OK] NonPagedPoolSize -> 0" -ForegroundColor Green

# 2. Network Defaults
Write-Host "Restoring Network Settings..."
$NetPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"

# NetworkThrottlingIndex -> 10 (Default)
Set-ItemProperty -Path $NetPath -Name "NetworkThrottlingIndex" -Value 10 -Force -ErrorAction SilentlyContinue
Write-Host " [OK] NetworkThrottlingIndex -> 10" -ForegroundColor Green

# SystemResponsiveness -> 20 (Default)
Set-ItemProperty -Path $NetPath -Name "SystemResponsiveness" -Value 20 -Force -ErrorAction SilentlyContinue
Write-Host " [OK] SystemResponsiveness -> 20" -ForegroundColor Green

# 3. Scheduler/Priority
Write-Host "Restoring Scheduler..."
$PrioPath = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"

# Win32PrioritySeparation -> 2 (Default for best balance)
Set-ItemProperty -Path $PrioPath -Name "Win32PrioritySeparation" -Value 2 -Force -ErrorAction SilentlyContinue
Write-Host " [OK] Win32PrioritySeparation -> 2" -ForegroundColor Green

Write-Host "`nFactory Defaults Restored Successfully." -ForegroundColor Cyan
Start-Sleep -Seconds 2

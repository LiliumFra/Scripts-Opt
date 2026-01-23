<#
.SYNOPSIS
    Verify-BeastMode.ps1
    Verifies that the new NeuralTweakLibrary is loaded correctly and Beast Mode tweaks are accessible.
#>

$modulePath = "$PSScriptRoot\NeuralModules\NeuralTweakLibrary.psd1"

if (Test-Path $modulePath) {
    Write-Host " [OK] Library found at: $modulePath" -ForegroundColor Green
    
    try {
        $data = Import-PowerShellDataFile -Path $modulePath
        $lib = $data.TweakLibrary
        
        Write-Host " [i] Total Tweaks Loaded: $($lib.Count)" -ForegroundColor Cyan
        
        # Check specific Beast Mode categories
        $latency = ($lib | Where-Object { $_.Category -eq "Latency" }).Count
        $privacy = ($lib | Where-Object { $_.Category -eq "Privacy" }).Count
        $gaming = ($lib | Where-Object { $_.Category -eq "Gaming" }).Count
        $security = ($lib | Where-Object { $_.Category -eq "Security" }).Count
        
        Write-Host "     - Latency Tweaks: $latency" -ForegroundColor Gray
        Write-Host "     - Privacy Tweaks: $privacy" -ForegroundColor Gray
        Write-Host "     - Gaming Tweaks:  $gaming" -ForegroundColor Gray
        Write-Host "     - Security Tweaks: $security (Extreme)" -ForegroundColor Red
        
        if ($lib.Count -gt 50) {
            Write-Host " [SUCCESS] Beast Mode Library Active (Massive Injection Confirmed)" -ForegroundColor Green
        }
        else {
            Write-Host " [WARNING] Library count low. Check import." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host " [ERROR] Failed to parse library: $_" -ForegroundColor Red
    }
}
else {
    Write-Host " [!] Library file missing!" -ForegroundColor Red
}

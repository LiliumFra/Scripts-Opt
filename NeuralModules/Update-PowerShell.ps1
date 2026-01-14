function Update-PowerShell {
    Write-Host ""
    Write-Host " ==================================================" -ForegroundColor Cyan
    Write-Host "      POWERSHELL 7+ REQUIRED / ACTUALIZACION" -ForegroundColor Yellow
    Write-Host " ==================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " [!] This script works best with PowerShell 7 (Core)." -ForegroundColor Yellow
    Write-Host " [i] Current Version: $($PSVersionTable.PSVersion.ToString())" -ForegroundColor Gray
    Write-Host ""
    Write-Host " [?] Do you want to install/update PowerShell 7 now?" -ForegroundColor Cyan
    $choice = Read-Host "     (Y/N)"
    
    if ($choice -match "Y") {
        Write-Host ""
        Write-Host " [i] Attempting update via Winget..." -ForegroundColor Cyan
        try {
            # Try winget first
            winget install --id Microsoft.PowerShell --source winget --accept-package-agreements --accept-source-agreements
            if ($?) {
                Write-Host ""
                Write-Host " [OK] Installation started/completed." -ForegroundColor Green
                Write-Host " [!] Please restart the terminal and run the script again." -ForegroundColor Yellow
                Start-Sleep -Seconds 5
                exit
            }
        }
        catch {
            Write-Host " [!] Winget failed or not available." -ForegroundColor Red
        }

        Write-Host ""
        Write-Host " [i] Opening download page..." -ForegroundColor Cyan
        Start-Process "https://github.com/PowerShell/PowerShell/releases/latest"
        Write-Host " [!] Please download and install the latest .msi manually." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
        exit
    }
}

# Auto-run if executed directly
if ($MyInvocation.InvocationName -ne '.') {
    Update-PowerShell
}

# ============================================================================
# STEAM OPTIMIZATION MODULE
# Part of Neural Optimizer v7.0
# ============================================================================

function Optimize-Steam {
    param(
        [ValidateSet("Minimal", "LowSpec", "Balanced")]
        [string]$Mode = "Balanced"
    )

    $steamPath = Get-SteamPath
    if (-not $steamPath) {
        Write-Host " [!] Steam not found in standard locations." -ForegroundColor Red
        return
    }

    Write-Host " [Steam] Optimization Mode: $Mode" -ForegroundColor Cyan
    
    # Kill existing Steam processes
    Stop-Process -Name "steam", "steamwebhelper" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2

    $steamArgs = @()
    
    switch ($Mode) {
        "Minimal" {
            # Comparison to "Small Mode" but forced via arguments where possible
            # Note: -no-browser is deprecated/buggy in 2024/2025 but -vgui still creates lighter window
            # +open steam://open/minigameslist forces the small list view
            $steamArgs += "-vgui"
            $steamArgs += "-no-browser" # Still useful for some internal cef reduction
            $steamArgs += "+open steam://open/minigameslist"
            Write-Host " [!] Minimal Mode: Browser features disabled (Store/Community may not work)" -ForegroundColor Yellow
        }
        "LowSpec" {
            # Reduces GPU overhead for the UI
            $steamArgs += "-cef-disable-gpu"
            $steamArgs += "-cef-single-process" 
            $steamArgs += "-cef-disable-d3d11"
            $steamArgs += "-no-dwrite"
        }
        "Balanced" {
            # Default optimized - just smoother UI
            $steamArgs += "-cef-disable-gpu-compositing"
        }
    }

    Write-Host " [>] Launching Steam..." -ForegroundColor Green
    Start-Process -FilePath $steamPath -ArgumentList $steamArgs -WindowStyle Minimized
    
    # Post-Launch Optimization (Priority Taming)
    Start-Sleep -Seconds 10 
    Optimize-SteamPriority
}

function Optimize-SteamPriority {
    Write-Host " [>] Taming SteamWebHelper..." -ForegroundColor Cyan
    
    $helpers = Get-Process -Name "steamwebhelper" -ErrorAction SilentlyContinue
    foreach ($proc in $helpers) {
        try {
            # Set to Idle priority to prevent CPU spikes affecting games
            $proc.PriorityClass = "Idle"
            # Trim working set (RAM)
            $handle = $proc.Handle
            $null = [LocalUserMethods]::EmptyWorkingSet($handle)
        }
        catch {}
    }
    Write-Host " [OK] Web Helpers set to IDLE priority." -ForegroundColor Green
}

function Get-SteamPath {
    # Try Registry
    try {
        $reg = Get-ItemProperty "HKCU:\Software\Valve\Steam" -Name "SteamPath" -ErrorAction SilentlyContinue
        if ($reg) { 
            return "$($reg.SteamPath)\steam.exe" 
        }
    }
    catch {}

    # Try Common Paths
    $paths = @(
        "C:\Program Files (x86)\Steam\steam.exe",
        "C:\Program Files\Steam\steam.exe"
    )
    foreach ($p in $paths) {
        if (Test-Path $p) { return $p }
    }
    return $null
}

# Win32 API for RAM Trimming
Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;
    public class LocalUserMethods {
        [DllImport("psapi.dll")]
        public static extern bool EmptyWorkingSet(IntPtr hProcess);
    }
"@ -ErrorAction SilentlyContinue

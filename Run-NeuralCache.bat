@echo off
:: Neural Cache v7.0 - Auto Mode Support
:: Usage: Run-NeuralCache.bat [--auto] [--silent]

:: Handle automatic/scheduled mode
IF "%1"=="--auto" (
    IF "%2"=="--silent" (
        powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0NeuralModules\Smart-Cache-Cleaner.ps1" -Auto -Silent
    ) ELSE (
        powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0NeuralModules\Smart-Cache-Cleaner.ps1" -Auto
    )
    exit /b
)

IF "%1"=="--silent" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0NeuralModules\Smart-Cache-Cleaner.ps1" -Auto -Silent
    exit /b
)

:: Check for Admin Privileges (interactive mode only)
FSUTIL dirty query %systemdrive% >nul
IF %ERRORLEVEL% NEQ 0 (
    echo.
    echo [!] Solicitando permisos de Administrador...
    echo.
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Run PowerShell Script (Interactive Mode)
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "NeuralModules\Smart-Cache-Cleaner.ps1"
pause

@echo off
:: Check for Admin Privileges
FSUTIL dirty query %systemdrive% >nul
IF %ERRORLEVEL% NEQ 0 (
    echo.
    echo [!] Solicitando permisos de Administrador...
    echo.
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Run PowerShell Script
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "NeuralModules\Smart-Cache-Cleaner.ps1"
pause

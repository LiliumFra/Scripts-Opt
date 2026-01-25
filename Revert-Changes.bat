@echo off
:: =========================================================
:: NEURAL RESTORE LAUNCHER
:: Wrapper para Restore-FactoryDefaults.ps1
:: =========================================================

REM Request Admin privileges
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo Requesting Admin privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
    pushd "%CD%"
    CD /D "%~dp0"

echo.
echo =========================================================
echo  LAUNCHING NEURAL RESTORE (FACTORY RESET)...
echo =========================================================
echo.

REM Check for PowerShell 7 (pwsh)
where pwsh >nul 2>nul
if %errorlevel% equ 0 (
    echo [i] Using PowerShell 7...
    pwsh -ExecutionPolicy Bypass -File "%~dp0\Restore-FactoryDefaults.ps1"
) else (
    echo [i] Using PowerShell 5.1...
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0\Restore-FactoryDefaults.ps1"
)

echo.
echo [i] Process finished.
pause

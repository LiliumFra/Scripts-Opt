# =========================================================
# VERIFY-REVERTSCRIPT.PS1
# Test harness for Restore-FactoryDefaults.ps1
# =========================================================

$ScriptDir = $PSScriptRoot
$TargetScript = Join-Path $ScriptDir "Restore-FactoryDefaults.ps1"

Write-Host " [TEST] Loading components..." -ForegroundColor Cyan

# 1. Read the content of the target script
$OriginalContent = Get-Content $TargetScript -Raw

# 2. Inject Mocks to Neutralize Destructive Commands
# We allow the specific functions defined in the script (Write-Section, Reset-RegValue) to exist,
# but we shadow the native cmdlets they use.

$Mocks = @"
function Invoke-AdminCheck { Write-Host "   [MOCK] Admin Check Passed" -ForegroundColor DarkGray }

function Set-ItemProperty { 
    param(`$Path, `$Name, `$Value, `$Force, `$Type) 
    Write-Host "   [MOCK] Set-ItemProperty: Path=`$Path Name=`$Name Value=`$Value" -ForegroundColor Gray 
}

function Remove-ItemProperty { 
    param(`$Path, `$Name, `$Force) 
    Write-Host "   [MOCK] Remove-ItemProperty: Path=`$Path Name=`$Name" -ForegroundColor Gray 
}

function New-ItemProperty {
    param(`$Path, `$Name, `$Value, `$Force)
    Write-Host "   [MOCK] New-ItemProperty: Path=`$Path Name=`$Name Value=`$Value" -ForegroundColor Gray
}

function Set-Service {
    param(`$Name, `$StartupType, `$ErrorAction)
    Write-Host "   [MOCK] Set-Service: Name=`$Name Start=`$StartupType" -ForegroundColor Gray
}

function Start-Process {
    param(`$FilePath, `$ArgumentList, `$NoNewWindow, `$Wait)
    Write-Host "   [MOCK] Start-Process: `$FilePath `$ArgumentList" -ForegroundColor Gray
}

function netsh {
    param(`$a, `$b, `$c, `$d, `$e, `$f)
    Write-Host "   [MOCK] netsh command execution" -ForegroundColor Gray
}

function Set-NetTCPSetting {
    param(`$SettingName, `$CongestionProvider, `$ErrorAction)
    Write-Host "   [MOCK] Set-NetTCPSetting: `$SettingName Provider=`$CongestionProvider" -ForegroundColor Gray
}

function Clear-DnsClientCache {
    Write-Host "   [MOCK] Clear-DnsClientCache" -ForegroundColor Gray
}

function Start-Sleep {
    param(`$Seconds)
    # Skip sleep for test speed
}

# Mock Import-Module to prevent actual loading (since we defined Invoke-AdminCheck above)
function Import-Module {
    param(`$Name, `$Force, `$DisableNameChecking)
    Write-Host "   [MOCK] Import-Module: `$Name" -ForegroundColor DarkGray
}

"@

# 3. Prepend Mocks to the script content
# We skip the first few lines of the original script if they set ErrorAction
$TestContent = $Mocks + "`n" + $OriginalContent

# 4. Save to a temporary test file
$TestFile = Join-Path $ScriptDir "Test-SafeRun.ps1"
Set-Content -Path $TestFile -Value $TestContent

# 5. Execute
Write-Host " [TEST] Starting Execution simulation..." -ForegroundColor Cyan
Write-Host " --------------------------------------------------------" -ForegroundColor DarkGray

try {
    # Execute safely
    . $TestFile
    
    Write-Host " --------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host " [TEST] Execution finished successfully (Reached end of script)." -ForegroundColor Green
}
catch {
    Write-Host " [FAIL] Script crashed during execution!" -ForegroundColor Red
    Write-Host " Error: $_" -ForegroundColor Red
}
finally {
    # Cleanup
    if (Test-Path $TestFile) { Remove-Item $TestFile }
}

# Check-BraceBalance.ps1
# Checks for curly brace balance in PowerShell files

$file = ".\NeuralModules\NeuralAI.psm1"
$lines = Get-Content $file
$balance = 0
$issues = @()

for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    $lineNum = $i + 1
    
    # Count open and close braces
    $opens = ([regex]::Matches($line, '\{')).Count
    $closes = ([regex]::Matches($line, '\}')).Count
    
    $prevBalance = $balance
    $balance += $opens
    $balance -= $closes
    
    if ($balance -lt 0) {
        $issues += "Line $lineNum : More closing braces than opening (balance: $balance)"
    }
    
    # Show lines with braces
    if ($opens -gt 0 -or $closes -gt 0) {
        $status = "[$balance] Line $lineNum (+$opens -$closes)"
        if ($opens -ne $closes) {
            Write-Host $status -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "Final Balance: $balance" -ForegroundColor $(if ($balance -eq 0) { 'Green' }else { 'Red' })

if ($issues.Count -gt 0) {
    Write-Host ""
    Write-Host "ISSUES:" -ForegroundColor Red
    $issues | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
}

# Check-Dashboard.ps1

$file = "d:\josef\Documents\Scripts Opt\NeuralModules\Neural-Dashboard.ps1"
$lines = Get-Content $file
$balance = 0

for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    $lineNum = $i + 1
    $opens = ([regex]::Matches($line, '\{')).Count
    $closes = ([regex]::Matches($line, '\}')).Count
    $balance += $opens
    $balance -= $closes
    if ($opens -gt 0 -or $closes -gt 0) {
        if ($opens -ne $closes) {
            Write-Host "[$balance] Line $lineNum (+$opens -$closes): $($line.Trim().Substring(0, [Math]::Min(50, $line.Trim().Length)))" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "Final Balance: $balance" -ForegroundColor $(if ($balance -eq 0) { 'Green' }else { 'Red' })

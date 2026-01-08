$scripts = Get-ChildItem -Path $PSScriptRoot -Recurse -Include *.ps1, *.psm1
foreach ($s in $scripts) {
    if ($s.Name -eq "Test-ProjectIntegrity.ps1") { continue }
    $content = Get-Content $s.FullName -Raw
    $content | Out-File $s.FullName -Encoding UTF8
    Write-Host "Fixed encoding for: $($s.Name)" -ForegroundColor Cyan
}

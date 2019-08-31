$winpath=Get-Location
$linuxPath =(($winpath -replace "\\","/") -replace ":","").ToLower().Trim("/")
$latexPath = ($winpath -replace "\\","/").Trim("/")
Write-Host "Current Windows directory: $winpath" -ForegroundColor DarkGreen
Write-Host "LaTeX Path:  $latexPath" -ForegroundColor Magenta
Write-Host "Linux Path:  $linuxPath" -ForegroundColor Cyan
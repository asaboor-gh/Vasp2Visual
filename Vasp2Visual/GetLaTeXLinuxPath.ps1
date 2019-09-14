$winpath=Get-Location
$drive=$winpath.Drive.Name.ToLower(); $path=Split-Path $winpath -NoQualifier
$linuxPath = -Join('/mnt/',-Join($drive,(($path -replace "\\","/") -replace ":","")))
$latexPath = ($winpath -replace "\\","/").Trim("/")
Write-Host "Current directory is copied to Clipboard as: " -ForegroundColor Green -NoNewline
Write-Host "Linux Path:  $linuxPath" -ForegroundColor Cyan
Write-Host "LaTeX Path:  $latexPath " -ForegroundColor Magenta 
Set-Clipboard  "$linuxPath";
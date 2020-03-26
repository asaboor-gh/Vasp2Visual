$timer = [Diagnostics.Stopwatch]::StartNew() #Stopwatch
#$InputFile=".\vasprun.xml" #This variable is supplied via function.
$XmlObject=(Read-AsXml -VasprunFile $InputFile)
$loadtime=$timer.Elapsed.TotalSeconds
Write-Host "$([Math]::Round($($loadtime),3)) seconds elapsed while loading vasprun.xml($([Math]::Round(((Get-Item $InputFile).length/1MB),3)) MB)" -ForegroundColor Cyan
$timer.Stop();

$loc=Get-Location #Required

$weights= Get-FillingWeights -XmlObject $XmlObject
$info= Get-Summary -XmlObject $XmlObject 
$sys=$info.SYSTEM; $NION=$info.NION; $NBANDS=$info.NBANDS; $NKPTS= $info.NKPTS; $filled=$weights.Filled; $unFilled=$weights.UnFilled;
Write-Host "▲ " -ForegroundColor Red -NoNewline
Write-Host " SYSTEM: $sys, NIONS: $NION, NBANDS: $NBANDS, Filled: $filled, NKPTS: $($NKPTS-$ibzkpt) " -ForegroundColor White -BackgroundColor Red
if($NBANDS -gt 40){ #check for more bands
$inquire= @"
 $sys contains $NION ions and $NBANDS bands.          
 [To get all bands, Type $filled, $unFilled] OR  [Collect almost 30 bands around VBM]
 Seperate entries by a comma: e.g. $filled, $unFilled                         
 NBANDS_FILLED, NBANDS_EMPTY:
"@
    Write-Host $inquire  -NoNewline -ForegroundColor Green 
    [string[]] $interval=(Read-Host).Split(",")
    [int]$skipB=$($filled-$interval[0]); [int]$NBANDS=$($interval[1]-(-$interval[0])); #update indices of bands.
    }Else{$skipB=0; $NBANDS=$NBANDS;
    } #Bands selction of interval's loop ended.
$filled=$filled-$skipB #Updating filled band with selected interval.
$timer.Start()  #starts timer again
#===========Excluding Extra KPOINTS from IBZKPT, No effect on GGA Calculations========
$ibzkpt= Read-KptsToExclude -XmlObject $XmlObject
#====================================================================
Write-Host "$ibzkpt IBZKPT file's KPOINTS Excluded!" -ForegroundColor Yellow
#=============Only DOS if in DOS Folder========================
if(($loc|Split-Path -Leaf).Contains('DOS') -or ($loc|Split-Path -Leaf).Contains('dos')){#Skipe Collection of Bands in DOS folder
$ibzkpt=$ibzkpt;$NKPTS=+1;$skipB=0;$NBANDS=0;$filled=0;} #Updated minimal working values
#==============================================================
#GetBands and KPTS
$KptsObject= Get-KPTS -XmlObject $XmlObject -SkipNKPTS $ibzkpt
$BandsObject= Get-EigenVals -XmlObject $XmlObject -SkipNKPTS $ibzkpt -SkipSelectNBANDS $skipB,$NBANDS
Write-Host "Writing file [Bands.txt] ..." -ForegroundColor Red
Write-KptsBands -XmlObject $XmlObject -KptsObject $KptsObject -BandsObject $BandsObject
#=========================Getting Min Max Energies=========
$E_array=($BandsObject|Where-Object{$_ -notmatch 'B'})|ForEach-Object{
    $_.Split()|Where-Object{$_ -and $_.Trim()}}
$E_top=($E_array|Measure-Object -Maximum).Maximum
$Band_1=(Get-EigenVals -XmlObject $XmlObject -SkipNKPTS $ibzkpt -SkipSelectNBANDS 0,1|
        Where-Object{$_ -notmatch 'B'})
$E_core=($Band_1|Measure-Object -Minimum).Minimum
#=====================Main Part================================
    Write-Host "Writing Total DOS on [tDOS.txt] ..." -ForegroundColor Red
    $tdos= Get-TotalDOS -XmlObject $XmlObject -SpinSet 1  #Automatically will write Spin polarized.
    Write-TotalDOS -TotalDOS $tdos
    Write-Host "Writing Partial DOS on [pDOS.txt] ..." -ForegroundColor Red
    Write-PartialDOS -XmlObject $XmlObject -SpinSet 1  #Automatically will write Spin polarized.
    Write-Host "Writing ALL-IONS Projections on [Projection.txt] in sequence ..." -ForegroundColor Red
    Write-Projection -SpinSet 1 -XmlObject $XmlObject -SkipNKPTS $ibzkpt -SkipSelectNBANDS $skipB,$NBANDS
Write-Host @"
 Done ✔: $([Math]::Round($($timer.Elapsed.TotalSeconds),3)) seconds elapsed.
"@ -ForegroundColor Cyan
$timer.Stop() #close stopwatch
$tTotal= [Math]::Round($($timer.Elapsed.TotalSeconds+$loadtime),3); 
Write-Host "The process completed in $tTotal seconds." -ForegroundColor Cyan
if($NBANDS.Equals(0)){Remove-Item .\Bands.txt -Force -ErrorAction Ignore; 
Remove-Item .\Projection.txt -Force -ErrorAction Ignore;} # Remove unnecessary files
#Write Information of system only in Bands Folder
if($NBANDS.Equals(0)){
    Write-Host "In DOS folder, no bands are collected! E-fermi is written in header of tDOS.txt" -ForegroundColor Red
    }Else{
    $infoFile= New-Item .\SysInfo.py  -Force #Create file
    Write-Host "Writing System information on file [$($infoFile.BaseName)] ..." -ForegroundColor Yellow -NoNewline
    $ElemIndex=$info.ElemIndex -Join ', '; $ElemName=$info.ElemName -Join ', '; #Elements Names and Indices Intervals
    $infoString= @" 
SYSTEM, NKPTS, NBANDS, NFILLED, TypeION=[`'$sys`', $($NKPTS-$ibzkpt), $NBANDS, $filled, $($info.TypeION)]; 
NION, nField_Projection, E_Fermi, ISPIN=[$NION, $($info.nField_Projection), $($info.E_Fermi), $($info.ISPIN)]; 
ElemIndex=[$ElemIndex]; ElemName=[$ElemName]; E_core=$E_core; E_top=$E_top;
"@
    $infoString|Set-Content $infoFile #Here-String written on file
} #Writing of SysInfo Ends.
Write-Host " Done ✔😎😍✔"
Write-Host "▼ " -ForegroundColor Blue -NoNewline
Write-Host " SYSTEM: $sys, NIONS: $NION, NBANDS: $NBANDS, Filled: $filled, NKPTS: $($NKPTS-$ibzkpt)" -ForegroundColor White -BackgroundColor Blue

# Crsytal System Information file.
$volume=$info.V
$basis=$info.Basis;$recbasis=$info.RecBasis;
$basis=$basis -join '],['
$recbasis=$recbasis -join '],['
$LatticeString=@"
basis=[[$($basis)]];
rec_basis=[[$($recbasis)]];
volume= $($volume);
"@
$LatticeString|Add-Content $infoFile
Write-Host "Files Generated: " -ForegroundColor Green -NoNewline
$listFiles=Get-ChildItem -Name *.txt,$infoFile
Write-Host $listFiles -Separator '   ' -ForegroundColor Yellow
#Done
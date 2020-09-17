$timer = [Diagnostics.Stopwatch]::StartNew() #Stopwatch
#$InputFile="./vasprun.xml" #This variable is supplied via function.
#$SkipK,$MaxFilled, $MaxEmpty are provided from calling function Export-VR2
$XmlObject=(Read-AsXml -VasprunFile $InputFile)
$loadtime=$timer.Elapsed.TotalSeconds
Write-Host "$([Math]::Round($($loadtime),3)) seconds elapsed while loading vasprun.xml($([Math]::Round(((Get-Item $InputFile).length/1MB),3)) MB)" -ForegroundColor Cyan
$timer.Stop();

$weights= Get-FillingWeights -XmlObject $XmlObject
$info= Get-Summary -XmlObject $XmlObject 
$sys=$info.SYSTEM; $NION=$info.NION; $NBANDS=$info.NBANDS; $NKPTS= $info.NKPTS; $filled=$weights.Filled;
Write-Host "▲ " -ForegroundColor Red -NoNewline
Write-Host " SYSTEM: $sys, NIONS: $NION, NBANDS: $NBANDS, Filled: $filled, NKPTS: $($NKPTS-$ibzkpt) " -ForegroundColor White -BackgroundColor Red
# Select Bands range.
$skipB,$NBANDS=@(0,$info.NBANDS); # Collect all bands if NFilled and NEmpty not given
if(-1 -ne $MaxFilled -and -1 -eq $MaxEmpty){ #check if only NFilled given.
    [int]$skipB,[int]$NBANDS=$(Get-SkipSelectBands -XmlObject $XmlObject -MaxFilled $MaxFilled); #update indices of bands.
    }elseif (-1 -ne $MaxEmpty -and -1 -eq $MaxFilled) { #check if only NEmpty given.
    [int]$skipB,[int]$NBANDS=$(Get-SkipSelectBands -XmlObject $XmlObject -MaxEmpty $MaxEmpty); #update indices of bands.
    }elseif(-1 -ne $MaxEmpty -and -1 -ne $MaxFilled){ #check if NFilled and NEmpty given.
    [int]$skipB,[int]$NBANDS=$(Get-SkipSelectBands -XmlObject $XmlObject -MaxFilled $MaxFilled -MaxEmpty $MaxEmpty); #update indices of bands.    
} #Bands selction of interval's loop ended.
$filled=$filled-$skipB #Updating filled band with selected interval.
$timer.Start()  #starts timer again
#===========Excluding Extra KPOINTS from IBZKPT, No effect on GGA Calculations========
if($SkipK -ne -1){ #check if $SkipK provided from calling function.
        $ibzkpt=$SkipK
    }Else{
        $ibzkpt= Read-KptsToExclude -XmlObject $XmlObject
}
#====================================================================
Write-Host "$ibzkpt IBZKPT file's KPOINTS Excluded!" -ForegroundColor Yellow
#=============OnlyDOS Switch========================
if($getonlydos -eq $True){#Skipe Collection of Bands
$ibzkpt = $NKPTS-1; $skipB=0;$NBANDS=1;$filled=1;} #Updated minimal working values to be able to load files
#==============================================================
#GetBands and KPTS
$KptsObject= Get-KPTS -XmlObject $XmlObject -SkipNKPTS $ibzkpt
$BandsObject= Get-EigenVals -XmlObject $XmlObject -SkipNKPTS $ibzkpt -SkipSelectNBANDS $skipB,$NBANDS
Write-Host "Writing file [Bands.txt] ..." -ForegroundColor Red
Write-KptsBands -XmlObject $XmlObject -KptsObject $KptsObject -BandsObject $BandsObject
#=====================Main Part================================
    Write-Host "Writing Total DOS on [tDOS.txt] ..." -ForegroundColor Red
    $tdos= Get-TotalDOS -XmlObject $XmlObject -SpinSet 1  #Automatically will write Spin polarized.
    Write-TotalDOS -TotalDOS $tdos
    Write-Host "Writing Partial DOS on [pDOS.txt] ..." -ForegroundColor Red
    Write-PartialDOS -XmlObject $XmlObject -SpinSet 1  #Automatically will write Spin polarized.
    Write-Host "Writing IONS Projections on [Projection.txt] in sequence ..." -ForegroundColor Red
    Write-Projection -SpinSet 1 -XmlObject $XmlObject -SkipNKPTS $ibzkpt -SkipSelectNBANDS $skipB,$NBANDS
Write-Host @"
 Done ✔: $([Math]::Round($($timer.Elapsed.TotalSeconds),3)) seconds elapsed.
"@ -ForegroundColor Cyan
$timer.Stop() #close stopwatch
$tTotal= [Math]::Round($($timer.Elapsed.TotalSeconds+$loadtime),3); 
Write-Host "The process completed in $tTotal seconds." -ForegroundColor Cyan
#Write Information of system only in Bands Folder
if($getonlydos -eq $True){
    Write-Host "Only first band is collected for -OnlyDOS switch!" -ForegroundColor Red
    }
$infoFile= New-Item ./SysInfo.py  -Force #Create file
Write-Host "Writing System information on file [$($infoFile.BaseName)] ..." -ForegroundColor Yellow -NoNewline
$ElemIndex=$info.ElemIndex -Join ', '; $ElemName=$info.ElemName -Join ', '; #Elements Names and Indices Intervals
$infoString= @" 
SYSTEM            = `'$sys`' 
NKPTS             = $($NKPTS-$ibzkpt)
NBANDS            = $NBANDS
NFILLED           = $filled
TypeION           = $($info.TypeION)
NION              = $NION
nField_Projection = $($info.nField_Projection)
E_Fermi           = $($info.E_Fermi)
ISPIN             = $($info.ISPIN) 
ElemIndex         = [$ElemIndex]
ElemName          = [$ElemName]
fields            = $($info.fields)
INCAR             = dict(
    $($info.INCAR | ForEach-Object {"{0}{1},`n" -f $(' '*25),$_})
                    )
"@
    $infoString|Set-Content $infoFile #Here-String written on file
# Crsytal System Information file.
$volume  = $info.V
$basis   = $info.Basis
$recbasis= $info.RecBasis
$poses   = $info.Positions
$basis   = $basis -join "],`n                     ["
$recbasis= $recbasis -join "],`n                     ["
$poses   = $poses -join "],`n                     ["
$LatticeString=@"
volume            = $($volume)
basis             = [[$($basis)]]
rec_basis         = [[$($recbasis)]]
positions         = [[$($poses)]]
"@
$LatticeString|Add-Content $infoFile
 #Writing of SysInfo Ends.
Write-Host " Done ✔😎😍✔"
Write-Host "▼ " -ForegroundColor Blue -NoNewline
Write-Host " SYSTEM: $sys, NIONS: $NION, NBANDS: $NBANDS, Filled: $filled, NKPTS: $($NKPTS-$ibzkpt)" -ForegroundColor White -BackgroundColor Blue


Write-Host "Files Generated: " -ForegroundColor Green -NoNewline
$listFiles=Get-ChildItem -Name *.txt
Write-Host $listFiles -Separator '   ' -ForegroundColor Yellow
#Done
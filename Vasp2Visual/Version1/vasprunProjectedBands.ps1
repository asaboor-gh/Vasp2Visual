#ISPIN=1 and LORBIT=10,11 work only
$timer = [Diagnostics.Stopwatch]::StartNew() #Stopwatch
$xml= New-Object Xml  #To load files bigger than 0.5GB.
$xml.Load((Convert-Path ./vasprun.xml))
#$xml = [xml](get-content ./vasprun.xml) #for simple files.
Write-Host "$([Math]::Round($($timer.Elapsed.TotalSeconds),3)) seconds elapsed while loading vasprun.xml($([Math]::Round(((Get-Item ./vasprun.xml).length/1MB),3)) MB)" -ForegroundColor Cyan
$timer.Stop();
$NKPT=$xml.modeling.calculation.eigenvalues.array.set.set.set.Length
$NBANDS=$xml.modeling.calculation.eigenvalues.array.set.set.set[0].r.Length
$NION=[int]$xml.modeling.atominfo.atoms.Trim()
$TypeION=[int]$xml.modeling.atominfo.types.Trim()
$eFermi=[Math]::Round($($xml.modeling.calculation.dos.i.'#text'.Trim()),4)
$loc=Get-Location
$sys=$xml.modeling.incar.i[0].'#text'.Trim() #Returns system name.
$ISPIN=((Select-String 'ISPIN' ./vasprun.xml|Out-String).Split("<")[-2]).Split(" ")[-1].Trim()
$Global:Writers=@(); #collect all streamwriters into a global array
#+++++++++++++++++++Function to use in vasprunOrbitals.ps1+++++++++++++++++++
function Get-VaspBands($ibzkpt){  #Bands Calculations.
. $PSScriptRoot/vasprunKpts.ps1 #calling script from same level
. $PSScriptRoot/vasprunEigens.ps1
$fileB = Join-Path -Path $loc -ChildPath "Bands.txt"
$writ = New-Object System.IO.StreamWriter $fileB; $Writers+=$writ
For ($j=0; $j -le ($NKPT-$ibzkpt); $j++) { 
$kxyz=$xml.modeling.kpoints.varray.v[$j+$ibzkpt-1]
if($j.Equals(0)){$kxyz="#$sys#k_x      k_y      k_z"}
$x=(Get-Content ./Kpts.txt)[$j]
$y=(Get-Content ./Eigenvals.txt)[$j]
$writ.WriteLine("$kxyz     $x     $y")  #space fixed.
#Add-Content -Path  ./Bands.txt -Value "   $x    $y"
}
$writ.Flush(); $writ.Close();  #wtiter for Bands.txt
}
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
$unFilled=0 
for($ii=0;$ii -le $($NBANDS-1);$ii++){
$x=$xml.modeling.calculation.eigenvalues.array.set.set.set[0].r[$ii].Split(" ")|Where-Object{$_}
if($x[1].Contains('0.0000')){$unFilled++; $filled=$NBANDS-$unFilled}
}
Write-Host "▲ " -ForegroundColor Cyan -NoNewline
Write-Host " SYSTEM: $sys, NIONS: $NION, NBANDS: $NBANDS, Filled: $filled, NKPTS: $NKPT " -ForegroundColor Green -BackgroundColor DarkBlue
if($NBANDS -gt 40){ #check for more bands
Write-Host "$sys structure contains  $NION ions and $NBANDS bands. 
 Lowest Band will be included automatically.         
 [To get all bands, Type $($filled-1), $unFilled] ⇚ OR ⇛ [Collect almost ↑↓ 30 bands around VBM]
 Seperate entries by a comma: e.g. $($filled-1), $unFilled                         
 NBANDS_FILLED, NBANDS_EMPTY: " -ForegroundColor Green -NoNewline 
[string[]] $interval=(Read-Host).Split(",")
[int]$from=$($filled-$interval[0]); [int]$NBANDS=$($interval[1]-(-$filled));[int]$nTot=$($interval[1]-(-$interval[0])-(-1));  #update indices of bands.
$bandInterval=@(,0+$($from)..$($NBANDS-1)); $filled=$($filled-(-1)) #prepend lowest band and add one more to filled.
}Else{$from=0; $nTot=$NBANDS;$bandInterval=@(0..$($NBANDS-1));} #Bands selction of interval's loop ended.
$filled=$filled-$from #Updating filled band with selected interval.
$timer.Start()  #starts timer again
#===========Excluding Extra KPOINTS from IBZKPT, No effect on GGA Calculations========
$weights=$xml.modeling.kpoints.varray[1].v; $count=0
$match=$xml.modeling.kpoints.varray[1].v[-1] #Last point as match
foreach($weight in $weights){if($weight.Contains($match)){$count+=1}}
$ibzkpt=[int]($NKPT-$count)
#====================================================================
Write-Host "$ibzkpt IBZKPT file's KPOINTS Excluded!" -ForegroundColor Yellow
#=============Only DOS if in DOS Folder========================
if((Get-Location|Split-Path -Leaf).Contains('DOS') -or (Get-Location|Split-Path -Leaf).Contains('dos')){#Skipe Collection of Bands in DOS folder
$ibzkpt=0;$NKPT=+1;$from=0;$NBANDS=0;$bandInterval=@();$nTot=0;$filled=0;} #Updated minimal working values
#==============================================================
#GetBands
Get-VaspBands -ibzkpt $ibzkpt   #++++++++++++++++++++++++++++++
#=========================Getting Min Max Energies=========
$E_array=(Get-Content ./Eigenvals.txt|Where-Object{$_ -notmatch 'B'})|ForEach-Object{
    $_.Split()|Where-Object{$_ -and $_.Trim()}}
$E_core=($E_array|Measure-Object -Minimum).Minimum
$E_top=($E_array|Measure-Object -Maximum).Maximum
Remove-Item ./Kpts.txt; Remove-Item ./Eigenvals.txt; # Remove unnecessary files
#=====================================================
$fileP = Join-Path -Path $loc -ChildPath "Projection.txt"
$filepD = Join-Path -Path $loc -ChildPath "pDOS.txt"
$sw = New-Object System.IO.StreamWriter $fileP #writer for Projections.
$dsw = New-Object System.IO.StreamWriter $filepD #writer for DOS
$Writers+=$sw; $Writers+=$dsw; #Add to global writers
Write-Host "Writing ALL-IONS Projections on ONE-FILE in sequence ..." -ForegroundColor Red
$share=0; #for progress bar in vasprunOrbitals
$ElemIndex=@(); $ElemIndex+=0; $ElemName=@();
For($n=0; $n -lt $TypeION; $n++){ #projection loop
Write-Host " Calculating Contribution of ION # $($n+1) ... " -ForegroundColor Blue -BackgroundColor Yellow
if($TypeION.Equals(1)){  #check ion type
$name=$xml.modeling.atominfo.array[1].set.rc.c[1].Trim()
[int]$ionTotal=$xml.modeling.atominfo.array[1].set.rc.c[0]
}Else{  #more than 1 ions.
$name=$xml.modeling.atominfo.array[1].set.rc[$n].c[1].Trim()
[int]$ionTotal=$xml.modeling.atominfo.array[1].set.rc[$n].c[0]
}
if($n.Equals(0)){$ionstart=0} #Make sure first element starts form Zero
#Execute projection Script.+++++++++++++++++++
$ElemIndex+=$($ElemIndex[-1]+$ionTotal); $ElemName+="`'$name`'"
. $PSScriptRoot/vasprunOrbitalsPerION.ps1
 #+++++++++++++++++++++++++++++++++++++++
[int]$ionstart=$($ionstart-(-$ionTotal)) ; #Update index/ for next element.
Write-Host " Done ✔: $([Math]::Round($($timer.Elapsed.TotalMinutes),3)) minutes elapsed." -ForegroundColor Cyan
} #Projection loop ends.
$sw.Close(); #writer for projections. 
$dsw.Close(); #writer for DOS.
$timer.Stop() #close stopwatch
$tTotal= [Math]::Round($($timer.Elapsed.TotalMinutes),3); 
Write-Host "The process completed in $tTotal minutes." -ForegroundColor Cyan
if($NBANDS.Equals(0)){Remove-Item ./Bands.txt -Force -ErrorAction Ignore; 
Remove-Item ./Projection.txt -Force -ErrorAction Ignore;} # Remove unnecessary files
#Write Information of system only in Bands Folder
if($NBANDS.Equals(0)){
Write-Host "In DOS folder, no bands are collected! E-fermi is written in header of tDOS.txt" -ForegroundColor Red
}Else{
$infoFile= New-Item ./SysInfo.py  -Force #Create file
Write-Host "Writing System information on file [$($infoFile.BaseName)] ..." -ForegroundColor Yellow -NoNewline
$ElemIndex=$ElemIndex -Join ', '; $ElemName=$ElemName -Join ', '; #Elements Names and Indices Intervals
$infoString=@" 
SYSTEM, NKPTS, NBANDS, NFILLED, TypeION=[`'$sys`', $($NKPT-$ibzkpt), $nTot, $filled, $TypeION]; 
NION, nField_Projection, E_Fermi, ISPIN=[$NION, $nOrbitals, $eFermi, $ISPIN]; 
ElemIndex=[$ElemIndex]; ElemName=[$ElemName]; E_core=$E_core; E_top=$E_top;
"@ #Do Not change structure between @" ....."@. It's Here-String
$infoString|Set-Content $infoFile #Here-String written on file
} #Writing of SysInfo Ends.
Write-Host " Done ✔😎🤩" -ForegroundColor Cyan
Write-Host "▼ " -ForegroundColor Cyan -NoNewline
Write-Host " SYSTEM: $sys, NIONS: $NION, NBANDS: $nTot, Filled: $filled, NKPTS: $($NKPT-$ibzkpt) " -ForegroundColor Green -BackgroundColor DarkBlue
Foreach($stwr in $Writers){$stwr.Close()} #Closes all Stream-Writers.
# Crsytal System Information file.
$volume=$xml.modeling.structure[2].crystal.i.'#text'.Trim()
$basis=$xml.modeling.structure[2].crystal.varray.v[0..2]|ForEach-Object{$_.trim() -replace '/s+',','}
$basis=$basis -join '],['
$LatticeString=@"
basis=[[$($basis)]];
volume= $($volume);
"@
$LatticeString|Add-Content $infoFile
Write-Host "Files Generated: " -ForegroundColor Green -NoNewline
$listFiles=Get-ChildItem -Name *.txt,$infoFile
Write-Host $listFiles -Separator '   ' -ForegroundColor Yellow
#Done
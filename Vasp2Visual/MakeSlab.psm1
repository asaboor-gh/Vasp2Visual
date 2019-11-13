Function Merge-ToSlab{
[CmdletBinding()]
Param(
[Parameter(Mandatory="True", Position=0)][string]$FirstPOSCAR,
[Parameter(Mandatory="True", Position=1)][string]$SecondPOSCAR)
Write-Host "Only Cubic and Tetragonal POSCARs are supported. 
Make sure your POSCARs DO NOT have non-zero xz,yz,zx,zy elements, 
If so, first rotate POSCAR using Vesta." -ForegroundColor Yellow
$data1=(Get-Content $FirstPOSCAR)
$data2=(Get-Content $SecondPOSCAR)
$lc1=[float]$data1[1] ; $lc2=[float]$data2[1] #lattice constants
$x1=[array]($data1[2].split()|Where-Object {$_})
$y1=[array]($data1[3].split()|Where-Object {$_})
$z1=[array]($data1[4].split()|Where-Object {$_})
$x2=[array]($data2[2].split()|Where-Object {$_})
$y2=[array]($data2[3].split()|Where-Object {$_})
$z2=[array]($data2[4].split()|Where-Object {$_})
if([float]$x1[2] -ne 0 -or [float]$y1[2] -ne 0 -or [float]$z1[0] -ne 0 -or [float]$z1[1] -ne 0){
  Write-Host "First POSCAR $FirstPOSCAR has any non-zero xz,yz,zx,zy elements, Can't proceed" -ForegroundColor Red
  break}
if([float]$x2[2] -ne 0 -or [float]$y2[2] -ne 0 -or [float]$z2[0] -ne 0 -or [float]$z2[1] -ne 0){
  Write-Host "Second $SecondPOSCAR has any non-zero xz,yz,zx,zy elements, Can't proceed" -ForegroundColor Red
  break}
#getting volume and cross-sectional area to find modified (0,0,z) for second POSCAR
$V2=([Math]::Pow($lc2,3))*(([float]$x2[0])*([float]$y2[1])*([float]$z2[2]));
$Axy1=([Math]::Pow($lc1,2))*(([float]$x1[0])*([float]$y1[1]))
$z2_new=[float]$V2/$Axy1 #Make x y same, change z for second slab
$totalZ=[float](($lc1*[float]$z1[2])+$z2_new)
$factor1=($lc1*[float]$z1[2])/$totalZ
$factor2=[float]$z2_new/$totalZ
$elem_1= $data1[5].Split()|Where-Object {$_}
$total_1=[array]$data1[6].Split()|Where-Object {$_}; 
$elem_2= $data2[5].Split()|Where-Object {$_}
$total_2=[array]$data2[6].Split()|Where-Object {$_}
$max_elem_index=[int]([Math]::Max($total_1.Count,$total_2.Count)-1)
$total_slab=Foreach($i in 0..$max_elem_index){[int]$total_1[$i]+[int]$total_2[$i]}  #index_out_of_range doesnt make problem here.
$diff_elem=(Compare-Object -ReferenceObject $elem_1 -DifferenceObject $elem_2 -PassThru)
$Elements="$elem_1  $diff_elem" #creates elements in slab
$outfile=New-Item -Path .\POSCAR_New.vasp -Force
$POSACR_init=@"
$($data1[0].Trim()+'/'+$data2[0].Trim())
$("{0:n16}" -f ($lc1*$x1[0]))
$("{0,24:N16}" -f 1)  $("{0,24:N16}" -f ($x1[1]/$x1[0]))  $("{0,24:N16}" -f 0)
$("{0,24:N16}" -f ($y1[0]/$x1[0]))  $("{0,24:N16}" -f ($y1[1]/$x1[0]))  $("{0,24:N16}" -f 0)
$("{0,24:N16}" -f 0)  $("{0,24:N16}" -f 0)  $("{0,24:N16}" -f ($totalZ/($lc1*$x1[0])))
  $Elements
  $total_slab
Direct
"@  #here-string for Z-only yet.
$POSACR_init|Set-Content $outfile
#save data in array
if($data1[7].StartsWith('S') -or $data2[7].StartsWith('S')){$shift=8;$ii=9}Else{$shift=7;$ii=8} #see if slective dynamics there.
$N1=[int]((,$shift+$total_1)|Measure-Object -Sum).Sum
$N2=[int]((,$shift+$total_2)|Measure-Object -Sum).Sum
$arr1=$data1[$ii..$N1]; $arr2=$data2[$ii..$N2];
#Loops of getting data
$start1=0;$stop1=[int]$total_1[0]-1
$start2=0;$stop2=[int]$total_2[0]-1
ForEach($index in 0..$max_elem_index){
if($index -lt $total_1.Count){
ForEach($i in $start1..$stop1){ #Array1
if($i -lt $(($total_1|Measure-Object -Sum).Sum)){
[array]$value=$arr1[$i].Split()|Where-Object {$_}
$value_new=([float]$value[2])*$factor1
$line="{0,24:N16}" -f ([float]$value[0]) + "{0,24:N16}" -f ([float]$value[1]) + "{0,24:N16}" -f ($value_new)
$line|Add-Content $outfile
}}
$start1+=[int]$total_1[$index]; 
$stop1=$start1+ [int]$total_1[$index+1]-1
}
if($index -lt $total_2.Count){
ForEach($i in $start2..$stop2){ #Array2
if($i -lt $(($total_2|Measure-Object -Sum).Sum)){
[array]$value=$arr2[$i].Split()|Where-Object {$_}
$value_new=([float]$value[2])*$factor2+$factor1
$line="{0,24:N16}" -f ([float]$value[0]) + "{0,24:N16}" -f ([float]$value[1]) + "{0,24:N16}" -f ($value_new)
$line|Add-Content $outfile
}}
$start2+=[int]$total_2[$index]; 
$stop2=$start2+ [int]$total_2[[int]($index+1)]-1
}
}
Write-Host "File [POSCAR_New.vasp] created." -ForegroundColor Green
}
Function Enable-SelectiveDynamics{
[CmdletBinding()]
Param(
[Parameter(Mandatory="True", Position=0)][string]$InputPOSCAR,
[Parameter(Position=1)][array]$SelectSitesNumber=@())
$data=Get-Content $InputPOSCAR
if($data[7].StartsWith('S')){$shift=8;$ii=9}Else{$shift=7;$ii=8} #see if slective dynamics there.
$N=([array]$data[6].Split()|Where-Object {$_}|Measure-Object -Sum).Sum+$shift
$data_New=$data[$ii..$N];
$outFile=New-Item .\POSCAR_eSD.vasp -Force
$($data[0..6])|Set-Content $outFile
$POSCAR_init=@"
Selective dynamics
Direct
"@
$POSCAR_init|Add-Content $outFile
ForEach($i in 0..($data_New.Count-1)){
if ($SelectSitesNumber.Contains($($i-(-1)))){$pattern="  T   T   T";
}Else{$pattern="  F   F   F"}
$value=($data_New[$i].Replace('F','').Replace('T','').TrimEnd())
"$value $pattern"|Add-Content $outFile}
Write-Host "File [POSCAR_eSD.vasp] is created." -ForegroundColor Green
}

Function Select-SitesInLayers{
[CmdletBinding()]
Param(
[Parameter(Mandatory="True", Position=0)][string]$InputPOSCAR,
[Parameter(Mandatory="True", Position=1)][array]$Array_2Decimal=@())
$data=Get-Content $InputPOSCAR
$SelectLayersPosition=@($Array_2Decimal)
if($data[7].StartsWith('S')){$shift=8;$ii=9}Else{$shift=7;$ii=8} #see if slective dynamics there.
$N=([array]$data[6].Split()|Where-Object {$_}|Measure-Object -Sum).Sum+$shift
$data_New=$data[$ii..$N];
$X=@();$Y=@();$Z=@(); #arrays of elements in 3D
ForEach($i in 0..($data_New.Count-1)){
[array]$value=($data_New[$i].Split()|Where-Object {$_});
[string]$value2=$value[2];[string]$value1=$value[1];[string]$value0=$value[0];
[string]$nV2=(($value2.split('.')[0],$value2.split('.')[1].Substring(0,2)) -join '.')
[string]$nV1=(($value1.split('.')[0],$value1.split('.')[1].Substring(0,2)) -join '.')
[string]$nV0=(($value0.split('.')[0],$value0.split('.')[1].Substring(0,2)) -join '.')
if ($SelectLayersPosition -contains $nV0){$X+=$($i+1)}
if ($SelectLayersPosition -contains $nV1){$Y+=$($i+1)}
if ($SelectLayersPosition -contains $nV2){$Z+=$($i+1)}
}
[pscustomobject]@{XY_PlaneSites=[array]($Z|Sort-Object);YZ_PlaneSites=[array]($X|Sort-Object);ZX_PlaneSites=[array]($Y|Sort-Object)} #output custom Object
}

Function Disable-SelectiveDynamics{
[CmdletBinding()]
Param([Parameter(Mandatory="True",Position=0)][string]$InputPOSCAR)
$read1=(Get-Content $InputPOSCAR|Where-Object {$_ -notmatch 'elective'})[0..6]
$read2=(Get-Content $InputPOSCAR|Select-Object -Skip 7|Where-Object {$_ -notmatch 'elective'}).Replace('F','').Replace('T','').TrimEnd()|Where-Object {$_}
$outFile =New-Item POSCAR_dSD.vasp -Force
($read1,$read2)|Set-Content $outFile -Force
Write-Host "File [POSCAR_dSD.vasp] created."
}

Function Show-LayersInfo{
[CmdletBinding()]
Param([Parameter(Mandatory="True",Position=0)][string]$InputPOSCAR)
$data=(Get-Content $InputPOSCAR|Where-Object {$_ -notmatch 'elective'})
$nAtoms=[int]($data[6].Split(" ")|Where-Object {$_}|Measure-Object -sum).sum
$coords=$data[8..($nAtoms+7)]
$z_coord=@();$x_coord=@();$y_coord=@();
Foreach($coord in $coords){
[array]$value=$coord.split()|Where-Object {$_}
[string]$value2=$value[2];[string]$value1=$value[1];[string]$value0=$value[0];
$z_coord+=(($value2.split('.')[0],$value2.split('.')[1].Substring(0,2)) -join '.')
$y_coord+=(($value1.split('.')[0],$value1.split('.')[1].Substring(0,2)) -join '.')
$x_coord+=(($value0.split('.')[0],$value0.split('.')[1].Substring(0,2)) -join '.')
}
[pscustomobject]@{
  X_AtLayers=[array]($x_coord|Select-Object -Unique|Sort-Object); 
  Y_AtLayers=[array]($y_coord|Select-Object -Unique|Sort-Object); 
  Z_AtLayers=[array]($z_coord|Select-Object -Unique|Sort-Object)} #output custom Object
}
Export-ModuleMember -Function 'Merge-ToSlab'
Export-ModuleMember -Function 'Enable-SelectiveDynamics'
Export-ModuleMember -Function 'Select-SitesInLayers'
Export-ModuleMember -Function 'Disable-SelectiveDynamics'
Export-ModuleMember -Function 'Show-LayersInfo'


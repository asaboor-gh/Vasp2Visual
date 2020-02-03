#$xml= New-Object Xml  #To load files bigger than 0.5GB.
#$xml.Load((Convert-Path .\vasprun.xml))
#$xml = [xml](get-content .\vasprun.xml)
#$NKPT=$xml.modeling.calculation.eigenvalues.array.set.set.set.Length
#$NBANDS=$xml.modeling.calculation.eigenvalues.array.set.set.set[0].r.Length
$start=Get-Date; $loc=Get-Location
$swe = New-Object System.IO.StreamWriter "$($loc)\Eigenvals.txt"
$Writers+=$swe; 
$x=@() #for Header
Foreach($j in $bandInterval) { #Header loop
$x+="B$j"
} $x=$x -join "    ";
$swe.WriteLine("   $x")
$old1=""; 
For ($j=$ibzkpt; $j -le ($NKPT-1); $j++) {  #rows loop
$new=($xml.modeling.calculation.eigenvalues.array.set.set.set[$j].r).trim().Substring(0,7)
Foreach($i in $bandInterval) {  #columns loop
#Add-Content -Path  file.dat -Value "     $($new[$i])" -NoNewline
$Eigen= "{0:n8}" -f  $($new[$i]);
$xx=-Join($old1,"$Eigen       ")
$old1="$xx"
}
#Add-Content -Path  .\Eigenvals.dat -Value "    $xx"
$swe.WriteLine("$xx")
$old1=""
}
$swe.Close()
$end=Get-Date
Write-Output "$start, $end"

##Total Density of states.
Write-Progress "Collecting Total DOS ..."
$tsw = New-Object System.IO.StreamWriter "$loc\tDOS.txt" #writer for DOS
$Writers+=$tsw;
$extraSpin=$xml.modeling.calculation.dos.total.array.set.set.comment.EndsWith(2) #check spin block 
$tsw.WriteLine("#$sys#Energy  TotDOS   IntegDOS#E_Fermi=$eFermi")
if(-not $extraSpin){ $val=$xml.modeling.calculation.dos.total.array.set.set.r; ForEach($v in $val){ $tsw.WriteLine($v)}
}Else{$vals=$xml.modeling.calculation.dos.total.array.set.set[0].r; ForEach($vs in $vals){ $tsw.WriteLine($vs)}} 
$tsw.Flush();$tsw.Close();
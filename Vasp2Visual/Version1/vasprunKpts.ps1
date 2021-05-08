#$xml= New-Object Xml  #To load files bigger than 0.5GB.
#$xml.Load((Convert-Path ./vasprun.xml))
#$xml = [xml](get-content ./vasprun.xml)
#$NKPT=$xml.modeling.calculation.eigenvalues.array.set.set.set.Length
[float]$sum=0.00001;# To make Round
$loc=Get-Location
$filew = Join-Path -Path $loc -ChildPath "Kpts.txt"
#Add-Content -Path  ./Kpts.txt -Value "$sum"
$swk = New-Object System.IO.StreamWriter $filew
$Writers+=$swk;
$swk.WriteLine("Reference")
#Write-Host "Type 0 to Include all KPOINTS, otherwise 
#Enter Number of KPOINTS to EXCLUDE: " -ForegroundColor Red -NoNewline
#[int]$ibzkpt=Read-Host  #Reads NKPTS to exclude
$old=$xml.modeling.kpoints.varray.v[0].trim().split()|Where-Object{$_}
for ($a=$ibzkpt; $a -le ($NKPT-1); $a++){
$com=$xml.modeling.kpoints.varray.v[$a].trim().split()|Where-Object{$_}
$cr1=[Math]::pow(($com[0]-$old[0]),2); $cr2=[Math]::pow(($com[1]-$old[1]),2); $cr3=[Math]::pow(($com[2]-$old[2]),2)
$val=[Math]::Round([Math]::Sqrt($cr1+$cr2+$cr3),6)
if($a -eq $ibzkpt){$ref=$val} #set reference to zero
$old=$com; 
$sum+=$val;
$value= "{0:n4}" -f $([Math]::Round($($sum-$ref),4)) #formatting decimal places
#Add-Content -Path  ./Kpts.txt -Value "$sum"
$swk.WriteLine("$value")
}
$swk.Close()
$content = Get-Content -Path ./Kpts.txt   #Replacing fist line by a comment.
$content[0]="        [k_i-k_0]"
$content | Set-Content -Path ./Kpts.txt
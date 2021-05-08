$loc=Get-Location
$filew = Join-Path -Path $loc -ChildPath "LOCPOT"
$newstreamreader = New-Object System.IO.StreamReader($filew)
$data=While($null -ne ($eachLine=$newstreamreader.ReadLine())){
$eachLine #Saves Readline into variable $data.
}
$nAtoms=[int]($data[6].Split(" ")|Where-Object {$_}|Measure-Object -sum).sum
#Getting site coordinates
$coords=$data[8..($nAtoms+7)] 
$z_coord=@();$x_coord=@();$y_coord=@();
Foreach($coord in $coords){
[array]$value=$coord.split()|Where-Object {$_}
$z_coord+="{0:N2}" -f [float]($value[2])
$y_coord+="{0:N2}" -f [float]($value[1])
$x_coord+="{0:N2}" -f [float]($value[0])
}
$layers=@"
x_site: $(($x_coord|Select-Object -Unique|Sort-Object) -join ', ')
y_site: $(($y_coord|Select-Object -Unique|Sort-Object) -join ', ')
z_site: $(($z_coord|Select-Object -Unique|Sort-Object) -join ', ')
"@
$layers|Set-Content ./LayersInfo.txt
#Collecting potential data
$NGx,$NGy,$NGz=$data[$nAtoms+9].Split()|Where-Object {$_}
$ii=[int]$($nAtoms+10); #start index for potential
$filew1 = Join-Path -Path $loc -ChildPath "newLOCPOT.txt"
$writer = New-Object System.IO.StreamWriter $filew1;
While($null -ne $data[$ii]){$writer.Write(("$($data[$ii].Trim())    "));$ii++}
 $writer.Close();
 $System=$data[0].Trim();
 $xDir=[float]($data[2].Split()|Where-Object {$_})[0]*[float]$data[1].Trim()
  $yDir=[float]($data[3].Split()|Where-Object {$_})[1]*[float]$data[1].Trim()
  $zDir=[float]($data[4].Split()|Where-Object {$_})[2]*[float]$data[1].Trim()
 $pyFile=@"
import numpy as np
data=np.loadtxt("newLOCPOT.txt").reshape($NGz,$NGy,$NGx)
#Z-Direction
dataZ_av=np.mean(np.mean(data,axis=1),axis=1)
dataZ_min=np.min(np.min(data,axis=1),axis=1)
dataZ_max=np.max(np.max(data,axis=1),axis=1)
z=$zDir*np.linspace(0,1,$NGz)
data_to_store=np.array([z,dataZ_av,dataZ_min,dataZ_max]).T
np.savetxt('zDir_Pot.txt', data_to_store, header='#$($System+$nAtoms)_Z        V_av        V_min          V_max',delimiter='\t',comments='')
#X-Direction
dataX_av=np.mean(np.mean(data,axis=0),axis=0)
dataX_min=np.min(np.min(data,axis=0),axis=0)
dataX_max=np.max(np.max(data,axis=0),axis=0)
x=$xDir*np.linspace(0,1,$NGx)
data_to_store=np.array([x,dataX_av,dataX_min,dataX_max]).T
np.savetxt('xDir_Pot.txt', data_to_store, header='#$($System+$nAtoms)_X        V_av        V_min          V_max',delimiter='\t',comments='')
#Y-Direction
dataY_av=np.mean(np.mean(data,axis=0),axis=1)
dataY_min=np.min(np.min(data,axis=0),axis=1)
dataY_max=np.max(np.max(data,axis=0),axis=1)
y=$yDir*np.linspace(0,1,$NGy)
data_to_store=np.array([y,dataY_av,dataY_min,dataY_max]).T
np.savetxt('yDir_Pot.txt', data_to_store, header='#$($System+$nAtoms)_Y        V_av        V_min          V_max',delimiter='\t',comments='')
"@
$pyFile|Set-Content ./newLOCPOT.py
python ./newLOCPOT.py
Remove-Item ./newLOCPOT.txt
Remove-Item ./newLOCPOT.py
Remove-Item .\KPath.txt -Force -ErrorAction Ignore
[int]$N=Read-Host "Enter number of High Symmetry KPOINTS (L,M,X,..). [Integer]"
[int]$steps=Read-Host "Enter number of kpoints in a single High Symmetry Interval (L,M). [Integer]"
$steps=$($steps-1); #
[array]$kpt1=(Read-Host "Type KPOINT # 1. [like 0,0,0 1D Array]").Split(",")
for($i=1;$i -lt $N;$i++){
[array]$kpt2=(Read-Host "Type KPOINT # $($i+1). [like 0,0,0 1D Array]").Split(",")
$values=($kpt1,$kpt2)
$dx=($values[1][0]-$values[0][0])/$steps
$dy=($values[1][1]-$values[0][1])/$steps
$dz=($values[1][2]-$values[0][2])/$steps
$point= "$($values[0][0])    $($values[0][1])     $($values[0][2])     0"
$point|Add-Content .\KPath.txt
$sum=$values[0][0],$values[0][1],$values[0][2]
for($x=1; $x -le ($steps-1); $x++){
$sum[0]=[Math]::Round($dx+$sum[0],5); $sum[0]="{0:n4}" -f  $($sum[0])
$sum[1]=[Math]::Round($dy+$sum[1],5);  $sum[1]="{0:n4}" -f  $($sum[1])
$sum[2]=[Math]::Round($dz+$sum[2],5); $sum[2]="{0:n4}" -f $($sum[2])
$point= "   $($sum[0])    $($sum[1])     $($sum[2])     0"
$point|Add-Content .\KPath.txt
} $kpt1=$kpt2 #switch
$point= "$($values[1][0])    $($values[1][1])     $($values[1][2])     0"
$point|Add-Content .\KPath.txt
}
Write-Host "Opening the file KPath.txt ..." -ForegroundColor DarkCyan
Start-Process .\KPath.txt
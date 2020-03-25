
#Version 2 of Vasp2Visual that allows automatic collection of Spin Ploarized calculations as well as 
#getting individual spin sets by dedicated functions.
function Get-EigenVals {
    param (
        # Insert a powershell xml object after it is read as [xml] using Read-AsXml command.
        [Parameter()][xml]$XmlObject=(Read-AsXml),
        # Insert Number of useless KPOINTS to skip
        [Parameter()][Int]$SkipNKPTS=0,
        # Insert How many Bands to skip and then how many to select seperated by comma. By Default,
        # it collects all bands using function Get-Summary
        [Parameter()][array]$SkipSelectNBANDS=(0,$((Get-Summary -XmlObject $XmlObject).NBANDS))
    )
    Write-Progress "Collecting Bands ..."
    $skip=[int]$SkipNKPTS;$range=@($SkipSelectNBANDS);
    $XmlEig=$XmlObject.modeling.calculation.eigenvalues.array.set
    $head=$(For($i=$range[0]+1;$i -le $range[1]+$range[0];$i++){"B$i"}) -join "`t"
    if($XmlEig.ChildNodes.Count -eq 2){
        $eig1=($XmlEig.set[0].set|Select-Object -Property r)
        $eig2=($XmlEig.set[1].set|Select-Object -Property r)
        $eval=($eig1,$eig2)|ForEach-Object{$head;$_|Select-Object -Skip $skip|
            ForEach-Object{($_.r|Select-Object -Skip $range[0] -First $range[1]|
                Foreach-Object{($_.Split()|
                    where-Object{$_})[0]}) -join "`t"} }
    }Else{
        
        $eig=($XmlEig.set.set|Select-Object -Property r)
        $eval=$eig|Select-Object -Skip $skip|
        ForEach-Object{($_.r|Select-Object -Skip $range[0] -First $range[1]|
            Foreach-Object{($_.Split()|
                where-Object{$_})[0]}) -join "`t"}
        $eval=$head,$eval|ForEach-Object{$_} #expanding next object.
        }
    return $eval
}


function Get-KPTS {
    param (
        # Insert a powershell xml object after it is read as [xml] using  Read-AsXml command.
        [Parameter()][xml]$XmlObject=(Read-AsXml),
        # Insert Number of useless KPOINTS to skip
        [Parameter()][Int]$SkipNKPTS=0
    )
    Write-Progress "Collecting KPTS ..."
    [float]$sum=0.00001; $skip=[int]$SkipNKPTS;
    $old=$XmlObject.modeling.kpoints.varray.v[0].trim().split()|Where-Object{$_}
    $kpt=($XmlObject.modeling.kpoints.varray[0]|Select-Object -Property v)
    $skpt=($kpt|ForEach-Object{$_.v}|Select-Object -Skip $skip)
    $skpt|ForEach-Object{
        $com=$_.Split()|Where-Object {$_}
        $cr1=[Math]::pow(($com[0]-$old[0]),2); $cr2=[Math]::pow(($com[1]-$old[1]),2); $cr3=[Math]::pow(($com[2]-$old[2]),2)
        $val=[Math]::Round([Math]::Sqrt($cr1+$cr2+$cr3),6)
        if($skpt.IndexOf($_) -eq 0){$ref=$val}
        $old=$com; 
        $sum+=$val;
        $value= "{0:n4}" -f $([Math]::Round($($sum-$ref),4))
        $k_array=($_,$value) -join "`t"
        return $k_array
    }
    
}

function Write-KptsBands {
    param (
        # Insert a powershell xml object after it is read as [xml] using  Read-AsXml command.
        [Parameter()][xml]$XmlObject=(Read-AsXml),
        # Insert Kpts Object
        [Parameter()][array]
        $KptsObject=$(Get-KPTS -XmlObject $XmlObject -SkipNKPTS $(Read-KptsToExclude -XmlObject $XmlObject)),
        # Insert Bands Object excluding first band
        [Parameter()][array]
        $BandsObject=$(Get-EigenVals -XmlObject $XmlObject -SkipNKPTS $(Read-KptsToExclude -XmlObject $XmlObject) -SkipSelectNBANDS 0,$((Get-Summary -XmlObject $XmlObject).NBANDS))
    )
    Write-Progress "Writing bands and kpoints on [Bands.txt] ..."
    $sys=$((Get-Summary -XmlObject $XmlObject).SYSTEM) #Get System automatically
    $loc=Get-Location #location is manadatory for streamwriter.
    $bandswriter = New-Object System.IO.StreamWriter "$loc\Bands.txt"
    if($KptsObject.Count*2 -eq $BandsObject.Count-2){ #check Spin-polarized
    $new_kp=[System.Collections.ArrayList]@("#$sys#SpinUp#kx`tky`tkz`tk")
    $KptsObject|ForEach-Object{[void]$new_kp.Add($_)}
    [void]$new_kp.Add("#$sys#SpinDown#kx`tky`tkz`t`tk`t")
    $KptsObject|ForEach-Object{[void]$new_kp.Add($_)}
    Write-Host "        DataShape: (ISPIN*[NKPTS],NBANDS)"
    }Else{
        $new_kp=[System.Collections.ArrayList]@("#$sys#kx`tky`tkz`tk")
        $KptsObject|ForEach-Object{[void]$new_kp.Add($_)}  
        Write-Host "        DataShape: (NKPTS,NBANDS)"
    }
    For($i=0;$i -lt $BandsObject.Count;$i++){
        $line=($new_kp[$i],$BandsObject[$i]) -join "`t"
        $bandswriter.WriteLine($line)
    }  
    $bandswriter.Flush();
    $bandswriter.Close();
    
}



function Get-Summary {
    param (
        # Insert powershell xml object. Get it using Read-AsXml command.
        [Parameter()][xml]$XmlObject=(Read-AsXml)
    )
    Write-Progress "Extracting System Information ..."
    $EigSets=$XmlObject.modeling.calculation.eigenvalues.array.set.ChildNodes.Count
    if($EigSets -eq 2){ 
    $NBANDS=$XmlObject.modeling.calculation.eigenvalues.array.set.set[0].set[0].r.Count
    }elseif ($EigSets -eq 1) {
    $NBANDS=$XmlObject.modeling.calculation.eigenvalues.array.set.set.set[0].r.Count
    }
    $ISPIN=$EigSets
    $sys=$XmlObject.modeling.incar.i[0].'#text'.Trim()
    $NKPT=$XmlObject.modeling.kpoints.varray[0].v.Count
    $NION=[int]$XmlObject.modeling.atominfo.atoms.Trim()
    $TypeION=[int]$XmlObject.modeling.atominfo.types.Trim()
    $eFermi=[Math]::Round($($XmlObject.modeling.calculation.dos.i.'#text'.Trim()),4)
    $nOrbitals=$XmlObject.modeling.calculation.projected.array.field.Count
    $nDOS_Fields=$XmlObject.modeling.calculation.dos.partial.array.field.Count
    #Get ions range for projrction.
    $ElemIndex=@(); $ElemIndex+=0; $ElemName=@(); 
    For($n=0; $n -lt $TypeION; $n++){ 
    if($TypeION.Equals(1)){  #check if only one ion.
        $name=$XmlObject.modeling.atominfo.array[1].set.rc.c[1].Trim()
        [int]$ionTotal=$XmlObject.modeling.atominfo.array[1].set.rc.c[0]
    }Else{  #more than 1 ions.
        $name=$XmlObject.modeling.atominfo.array[1].set.rc[$n].c[1].Trim()
        [int]$ionTotal=$XmlObject.modeling.atominfo.array[1].set.rc[$n].c[0]
    }
    $ElemIndex+=$($ElemIndex[-1]+$ionTotal); $ElemName+="`'$name`'"
    }
    #Structure
    $volume=$XmlObject.GetElementsByTagName('structure')[-1].crystal.i.'#text'.Trim()
    $basis=$XmlObject.GetElementsByTagName('structure')[-1].crystal.varray.v[0..2]| ForEach-Object{
        ($_.Split()| Where-Object {$_}) -join ","}
    $rec_basis=$XmlObject.GetElementsByTagName('structure')[-1].crystal.varray.v[3..5]| ForEach-Object{
        ($_.Split()| Where-Object {$_}) -join ","}
    return [ordered]@{ISPIN=$ISPIN;NBANDS=$NBANDS;SYSTEM=$sys;NKPTS=$NKPT;
        NION=$NION;TypeION=$TypeION;E_Fermi=$eFermi;
        nField_Projection=$nOrbitals;nField_DOS=$nDOS_Fields;
        ElemIndex=$ElemIndex; ElemName=$ElemName;V=$volume;
        Basis=$basis;RecBasis=$rec_basis;}
}

function Read-AsXml {
    param (
        # Insert path or url to vasprun.xml file. By default it is current folder.
        # This is kept seperate to load xml once and use in other commands.
        [Parameter()]$VasprunFile=".\vasprun.xml"
    )
    Write-Progress "Reading $VasprunFile ..."
    if($VasprunFile.Contains('vasprun.xml')){
    $XmlObject= New-Object Xml  #To load files bigger than 0.5GB.
    $XmlObject.Load((Convert-Path $VasprunFile))
    return $XmlObject
    }Else{
        Write-Host "System can not convert given path/url.Provide a path that ends with 'vasprun.xml'" -ForegroundColor Red; 
        exit
    }
}

function Read-KptsToExclude {
    param (
        # Insert powershell xml object. Get it using Read-AsXml command.
        [Parameter()][xml]$XmlObject=(Read-AsXml)
    )
    $weights=$XmlObject.modeling.kpoints.varray[1].v; $count=0
    $match=$XmlObject.modeling.kpoints.varray[1].v[-1] #Last point as match
    foreach($weight in $weights){
        if($weight.Contains($match)){$count+=1}}
    $ibzkpt=[int]((Get-Summary -XmlObject $XmlObject).NKPTS-$count) #Points to exclude.
    return $ibzkpt
}


##Total Density of states.
function Get-TotalDOS {
    param (
        # Insert powershell xml object. Get it using Read-AsXml command.
        [Parameter()][xml]$XmlObject=(Read-AsXml),
        # Insert Index of the set of spin blocks. Default is 0.
        [Parameter()][int]$SpinSet=1
    )
    $SpinSetIndex=$SpinSet-1
Write-Progress "Collecting Total DOS ..."
$SpinSets=$XmlObject.modeling.calculation.dos.total.array.set.ChildNodes.Count #check spin block 
$info=Get-Summary -XmlObject $XmlObject
if($SpinSets -eq 1){ 
    $head="#$($info.SYSTEM)#Energy  TotDOS   IntegDOS#E_Fermi=$($info.E_Fermi)"
    $val=$XmlObject.modeling.calculation.dos.total.array.set.set.r; 
    $tdos=$head,$val
    Write-Host "        DataShape: (GridSize,Fields)"

}elseif($SpinSets -eq 2){
    $head1="#$($info.SYSTEM)#SpinUp#Energy  TotDOS   IntegDOS#E_Fermi=$($info.E_Fermi)"
    $val1=$XmlObject.modeling.calculation.dos.total.array.set.set[0].r
    $head2="#$($info.SYSTEM)#SpinDown#Energy  TotDOS   IntegDOS#E_Fermi=$($info.E_Fermi)"
    $val2=$XmlObject.modeling.calculation.dos.total.array.set.set[1].r 
    $tdos=$head1,$val1,$head2,$val2
    Write-Host "        DataShape: (ISPIN*[GridSize],Fields)"
}elseif($SpinSets -ne 2 -and $SpinSets -ne 1){
    $head="#$($info.SYSTEM)#SpinSet$($SpinSet)#Energy  TotDOS   IntegDOS#E_Fermi=$($info.E_Fermi)"
    $val=$XmlObject.modeling.calculation.dos.total.array.set.set[$SpinSetIndex].r;
    $tdos=$head,$val
    Write-Host "        DataShape: (GridSize,Fields)"
}
    return $tdos
}

function Write-TotalDOS {
    param (
      # Insert TotalDOS object from Get-TotalDOS command
      [Parameter()][array]$TotalDOS=$(Get-TotalDOS -XmlObject $(Read-AsXml) -SpinSet 1) 
    )
    Write-Progress "Writing Total DOS on [tDOS.txt] ..."
    $loc=(Get-Location) #for streamwriter.
    $tsw = New-Object System.IO.StreamWriter "$loc\tDOS.txt" #writer for DOS
    $TotalDOS|ForEach-Object{$_}|ForEach-Object{$tsw.WriteLine($_)} #expand and write.
    $tsw.Flush();$tsw.Close();
}

function Get-BandsProSet {
    param (
        # Inset Set Number of Spin Block you want.
        [Parameter()][int]$SpinSet=1,
        # Insert a powershell xml object after it is read as [xml] using Read-AsXml command.
        [Parameter()][xml]$XmlObject=(Read-AsXml),
        # Insert Number of useless KPOINTS to skip
        [Parameter()][Int]$SkipNKPTS=0,
        # Insert How many Bands to skip and then how many to select seperated by comma. By Default,
        # it collects all bands using function Get-Summary
        [Parameter()][array]$SkipSelectNBANDS=(0,$((Get-Summary -XmlObject $XmlObject).NBANDS))
    )
    $skip=[int]$SkipNKPTS;$range=@($SkipSelectNBANDS);
    $Values=Get-Summary -XmlObject $XmlObject
    [int]$NION=$Values.NION
    [int]$NBANDS=$range[1]
    [int]$NKPTS=$Values.NKPTS-$skip
    [int]$ISPIN=$Values.ISPIN
    $sys=$Values.SYSTEM
    
    Write-Progress "Collecting Bands Projection of Spin Set $SpinSet ..."
    $xmlP=$XmlObject.GetElementsByTagName('projected').array.set
    $SpinSetIndex=$SpinSet-1
    if($xmlP.ChildNodes.Count -eq 1){
        $SelectSet=$xmlP.set.set
        $set=1 #To return info when you enter wrong spin set.
    }Else{$SelectSet=$xmlP.set[$SpinSetIndex].set
        $set=$SpinSet #To return actual set
        }
        $xmlK=$SelectSet| Select-Object -Skip $skip #SkipK
        $Pros=$xmlK| ForEach-Object { #Kpoints loop
        $_.set|Select-Object -Skip $range[0] -First $range[1]| ForEach-Object{ #Bands Number Loop
            $_.r | ForEach-Object{ #Ions number loop
                        $_
                    } #ions
            } #Bands
        } #Kpoints

    #Arranges IONS set in order.
    if($null -ne $Pros){
    $N_set=For($n=0;$n -lt $NION;$n++){
        For($i=$n;$i -lt $NKPTS*$NBANDS*$NION;$i+=$NION){
            $Pros[$i]
            }
        }
    #Joins Bands and Final is (NKPTS*NION,NBANDS*nProjections) data set.
    $K_set=For($b=0;$b -lt $NBANDS*$NKPTS*$NION;$b+=$NBANDS){
            $N_set[$b..($b+$NBANDS-1)] -join "`t"
        }
    }Else{
        $K_set=@() #return empty array  
    }
    $Fields=$XmlObject.GetElementsByTagName('projected').array.field| ForEach-Object{$_.Trim()}  
    $shape="(NION*[NKPTS],NBANDS*[Fields])"    
    return [ordered]@{SYSTEM=$sys;Fields=$Fields; NBANDS=$NBANDS;NKPTS=$NKPTS;NION=$NION; 
        ISPIN=$ISPIN; SpinSet=$set; Data=$K_set; ShapeOfData=$shape;SkipSelectNBANDS=$range;}
    }

function  Get-PartialDOS {
    param (
        # Inset Set Number of Spin Block you want.
        [Parameter()][int]$SpinSet=1,
        # Insert a powershell xml object after it is read as [xml] using Read-AsXml command.
        [Parameter()][xml]$XmlObject=(Read-AsXml)
    )
    Write-Progress "Collecting Partial DOS of Spin Set $SpinSet ..."
    $ions=$XmlObject.GetElementsByTagName('partial').array.set.ChildNodes
    $info=Get-Summary -XmlObject $XmlObject
    $SpinSetIndex=$SpinSet-1
    if($info.NION -eq 1){ #One ION
        if($ions.ChildNodes.Count -eq 1){ #One Spin Set
        $Data=$ions.set.r
        $set=1 #To Identify which set you get irrespective of input set
        }Else{ #More than One Spin Sets
        $Data=$ions.set[$SpinSetIndex].r
        $set=$SpinSet #Your Input Set
        }
    }Else{ #More than one IONS
        if($ions[0].ChildNodes.Count -eq 1){ #One Spin Set
        $Data=$ions| ForEach-Object {
        $_.set.r    
        }
        $set=1 #To Identify which set you get irrespective of input set
        }Else{ #More than One Spin Sets
        $Data=$ions| ForEach-Object {
        $_.set[$SpinSetIndex].r
        }
        $set=$SpinSet #Your Input set
        }
    }
    if($null -eq $Data[0]){$Data=@()} #if out of range spin set entered, return empty data
    $dosFields=$xml.GetElementsByTagName('partial').array.field | ForEach-Object{$_.Trim()}
    $ngrid=$Data.Count/$info.NION #Energy grid size.
    $shape="(NION*[GridSize],Fields)"
    return [ordered]@{SYSTEM=$info.SYSTEM;Fields=$dosFields;NION=$info.NION; ISPIN=$info.ISPIN;
        GridSize=$ngrid;SpinSet=$set;Data=$Data; ShapeOfData=$shape;}
}
function Write-PartialDOS {
    param (
      # Inset Set Number of Spin Block you want.
      [Parameter()][int]$SpinSet=1,
      # Insert PartialDOS object from Get-PartialDOS command
      [Parameter()][xml]$XmlObject=$(Read-AsXml)
    )
    $loc=(Get-Location) #for streamwriter.
    $info=Get-Summary -XmlObject $XmlObject
    if($info.ISPIN -eq 1 -and $SpinSet -eq 1){ #Avoid writing else.
        Write-Progress "Writing Partial DOS on [pDOS.txt] ..."
        $psw = New-Object System.IO.StreamWriter "$loc\pDOS.txt" #writer for Partial DOS
        $dosUp=(Get-PartialDOS -XmlObject $XmlObject -SpinSet 1)
        $head="#$($dosUp.SYSTEM),Fields: [$($dosUp.Fields)], Shape: (NION*[GridSize],Fields) = ($($dosUp.NION)*[$($dosUp.GridSize)],$($dosUp.Fields.Count))"
        $psw.WriteLine($head)
        $dosUp.Data| ForEach-Object{$psw.WriteLine($_)}
        $psw.Flush();$psw.Close();
        Write-Host "        DataShape: (NION*[GridSize],Fields)"
    }
    if($info.ISPIN -eq 2 -and $SpinSet -eq 1){ #Avoid writing else.
        Write-Progress "Writing Partial DOS Up/Down on [pDOS.txt] ..."
        $psw = New-Object System.IO.StreamWriter "$loc\pDOS.txt" #writer for Partial DOS
        $dosUp=(Get-PartialDOS -XmlObject $XmlObject -SpinSet 1)
        $dosDown=(Get-PartialDOS -XmlObject $XmlObject -SpinSet 2)
        $head="#$($dosUp.SYSTEM),Fields: [$($dosUp.Fields)], Shape: (ISPIN*[NION*[GridSize]],Fields) = (2*$($dosUp.NION)*[$($dosUp.GridSize)],$($dosUp.Fields.Count))"
        $psw.WriteLine($head)
        $dosUp.Data| ForEach-Object{$psw.WriteLine($_)}
        $dosDown.Data| ForEach-Object{$psw.WriteLine($_)}
        $psw.Flush();$psw.Close();
        Write-Host "        DataShape: (ISPIN*[NION*[GridSize]],Fields)"
    }
    if($SpinSet -ne 1){ #Avoid writing else.
        $dos=(Get-PartialDOS -XmlObject $XmlObject -SpinSet $SpinSet)
        $head="#$($dos.SYSTEM),Fields: [$($dos.Fields)], SpinSet: $($dos.SpinSet), Shape: (NION*[GridSize],Fields) = ($($dos.NION)*[$($dos.GridSize)],$($dos.Fields.Count))"
        $file="$loc"+"\Spin"+$dos.SpinSet+"Dos.txt"
        Write-Progress "Writing Partial DOS on [$file] ..."
        $ssw = New-Object System.IO.StreamWriter $file #writer for Partial DOS
        $ssw.WriteLine($head)
        $dos.Data| ForEach-Object{$ssw.WriteLine($_)}
        $ssw.Flush();$ssw.Close();
        Write-Host "        DataShape: (NION*[GridSize],Fields)"
    }
}

function Write-Projection {
    param (
        #Insert Spin Set you want to compute.
        [Parameter()][int]$SpinSet=1,
        # Insert a powershell xml object after it is read as [xml] using  Read-AsXml command.
        [Parameter()][xml]$XmlObject=(Read-AsXml),
        [Parameter()][Int]$SkipNKPTS=0,
        # Insert How many Bands to skip and then how many to select seperated by comma. By Default,
        # it collects all bands using function Get-Summary
        [Parameter()][array]$SkipSelectNBANDS=(0,$((Get-Summary -XmlObject $XmlObject).NBANDS))
    )
    $skip=[int]$SkipNKPTS;$range=@($SkipSelectNBANDS);
    $info=(Get-Summary -XmlObject $XmlObject)
    $loc=Get-Location #location is manadatory for streamwriter.
    if($info.ISPIN -eq 1 -and $SpinSet -eq 1){ #Avoid writing else.
        Write-Progress "Writing Bands Projection on [Projection.txt] ..."
        $psw = New-Object System.IO.StreamWriter "$loc\Projection.txt" #writer for Projection
        $proUp=$(Get-BandsProSet -XmlObject $XmlObject -SkipNKPTS $skip -SkipSelectNBANDS $range[0],$range[1] -SpinSet 1)
        $head="#$($proUp.SYSTEM),Fields: [$($proUp.Fields)], Shape: (NION*[NKPTS],NBANDS*[Fields]) = ($($proUp.NION)*[$($proUp.NKPTS)],$($proUp.NBANDS)*[$($proUp.Fields.Count)])"
        $psw.WriteLine($head)
        $proUp.Data| ForEach-Object{$psw.WriteLine($_)}
        $psw.Flush();$psw.Close();
        Write-Host "        DataShape: (NION*[NKPTS],NBANDS*[Fields])"
    }
    if($info.ISPIN -eq 2 -and $SpinSet -eq 1){ #Avoid writing else.
        Write-Progress "Writing Bands Projection on [Projection.txt] ..."
        $psw = New-Object System.IO.StreamWriter "$loc\Projection.txt" #writer for Projection
        $proUp=$(Get-BandsProSet -XmlObject $XmlObject -SkipNKPTS $skip -SkipSelectNBANDS $range[0],$range[1] -SpinSet 1)
        $proDown=$(Get-BandsProSet -XmlObject $XmlObject -SkipNKPTS $skip -SkipSelectNBANDS $range[0],$range[1] -SpinSet 2)
        $head="#$($proUp.SYSTEM),Fields: [$($proUp.Fields)], Shape: (ISPIN*[NION*[NKPTS]],NBANDS*[Fields]) = ($($proUp.ISPIN)[$($proUp.NION)*[$($proUp.NKPTS)]],$($proUp.NBANDS)*[$($proUp.Fields.Count)])"
        $psw.WriteLine($head)
        $proUp.Data| ForEach-Object{$psw.WriteLine($_)}
        $proDown.Data| ForEach-Object{$psw.WriteLine($_)}
        $psw.Flush();$psw.Close();
        Write-Host "        DataShape: (ISPIN*[NION*[NKPTS]],NBANDS*[Fields])"
    }
    if($SpinSet -ne 1){ #Avoid writing else.
        $pro=$(Get-BandsProSet -XmlObject $XmlObject -SkipNKPTS $skip -SkipSelectNBANDS $range[0],$range[1] -SpinSet $SpinSet)
        $head="#$($pro.SYSTEM),Fields: [$($pro.Fields)], SpinSet: $($pro.SpinSet), Shape: (NION*[NKPTS],NBANDS*[Fields]) = ($($pro.NION)*[$($pro.NKPTS)],$($pro.NBANDS)*[$($pro.Fields.Count)])"
        $file="$loc"+"\Spin"+$pro.SpinSet+"Projection.txt"
        Write-Progress "Writing Bands Projection on [$file] ..."
        $ssw = New-Object System.IO.StreamWriter $file #writer for Bands Projection
        $ssw.WriteLine($head)
        $pro.Data| ForEach-Object{$ssw.WriteLine($_)}
        $ssw.Flush();$ssw.Close();
        Write-Host "        DataShape: (NION*[NKPTS],NBANDS*[Fields])"
    }
}

function Get-FillingWeights {
    param (
        # Insert a powershell xml object after it is read as [xml] using Read-AsXml command.
        [Parameter()][xml]$XmlObject=(Read-AsXml)
    )
    $XmlEig=$XmlObject.modeling.calculation.eigenvalues.array.set
    if($XmlEig.ChildNodes.Count -eq 2){
        $eig1=($XmlEig.set[0].set|Select-Object -Property r)
        $eval=$eig1|Select-Object -Last 1|
            ForEach-Object{($_.r|Foreach-Object{($_.Split()|
                    where-Object{$_})[1]})}
    }Else{    
        $eig=($XmlEig.set.set|Select-Object -Property r)
        $eval=$eig|Select-Object -Last 1|
        ForEach-Object{($_.r|Foreach-Object{($_.Split()|
                where-Object{$_})[1]})}
        }
    $counter=0; [float]$last=$eval[-1];
    $eval|ForEach-Object{if([float]$_ -eq $last){$counter++}}
    return [ordered]@{Filled=$eval.Count-$counter;UnFilled=$counter; Weights=$eval;}
}

function Export-VR2 {
    param (
        # Path to vasprun.xml or url.
        [Parameter()]$InputFile=".\vasprun.xml"
    )
$timer = [Diagnostics.Stopwatch]::StartNew() #Stopwatch
$XmlObject=(Read-AsXml -VasprunFile $InputFile)
$loadtime=$timer.Elapsed.TotalSeconds
Write-Host "$([Math]::Round($($loadtime),3)) seconds elapsed while loading vasprun.xml($([Math]::Round(((Get-Item $InputFile).length/1MB),3)) MB)" -ForegroundColor Cyan
$timer.Stop();

$loc=Get-Location #Required

$weights= Get-FillingWeights -XmlObject $XmlObject
$info= Get-Summary -XmlObject $XmlObject 
$sys=$info.SYSTEM; $NION=$info.NION; $NBANDS=$info.NBANDS; $NKPTS= $info.NKPTS; $filled=$weights.Filled; $unFilled=$weights.UnFilled;
Write-Host "▲ " -ForegroundColor Cyan -NoNewline
Write-Host " SYSTEM: $sys, NIONS: $NION, NBANDS: $NBANDS, Filled: $filled, NKPTS: $($NKPTS-$ibzkpt) " -ForegroundColor White -BackgroundColor Red
if($NBANDS -gt 40){ #check for more bands
Write-Host "$sys structure contains  $NION ions and $NBANDS bands.          
 [To get all bands, Type $filled, $unFilled] ⇚ OR ⇛ [Collect almost ↑↓ 30 bands around VBM]
 Seperate entries by a comma: e.g. $filled, $unFilled                         
 NBANDS_FILLED, NBANDS_EMPTY: " -ForegroundColor Green -NoNewline 
[string[]] $interval=(Read-Host).Split(",")
[int]$skipB=$($filled-$interval[0]); [int]$NBANDS=$($interval[1]-(-$interval[0])); #update indices of bands.
}Else{$skipB=0; $NBANDS=$NBANDS;} #Bands selction of interval's loop ended.
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
#=====================================================
Write-Host "Writing Total DOS on [tDOS.txt] ..." -ForegroundColor Red
$tdos= Get-TotalDOS -XmlObject $XmlObject -SpinSet 1  #Automatically will write Spin polarized.
Write-TotalDOS -TotalDOS $tdos
Write-Host "Writing Partial DOS on [pDOS.txt] ..." -ForegroundColor Red
$nOrbitals=$((Get-PartialDOS -SpinSet 1 -XmlObject $XmlObject).Fields.Count-1)
Write-PartialDOS -XmlObject $XmlObject -SpinSet 1  #Automatically will write Spin polarized.
Write-Host "Writing ALL-IONS Projections on [Projection.txt] in sequence ..." -ForegroundColor Red
Write-Projection -SpinSet 1 -XmlObject $XmlObject -SkipNKPTS $ibzkpt -SkipSelectNBANDS $skipB,$NBANDS
Write-Host " Done ✔: $([Math]::Round($($timer.Elapsed.TotalSeconds),3)) seconds elapsed." -ForegroundColor Cyan
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
$infoString=@" 
SYSTEM, NKPTS, NBANDS, NFILLED, TypeION=[`'$sys`', $($NKPTS-$ibzkpt), $NBANDS, $filled, $($info.TypeION)]; 
NION, nField_Projection, E_Fermi, ISPIN=[$NION, $nOrbitals, $($info.E_Fermi), $($info.ISPIN)]; 
ElemIndex=[$ElemIndex]; ElemName=[$ElemName]; E_core=$E_core; E_top=$E_top;
"@ #Do Not change structure between @" ....."@. It's Here-String
$infoString|Set-Content $infoFile #Here-String written on file
} #Writing of SysInfo Ends.
Write-Host " Done ✔😎🤩" -ForegroundColor Cyan
Write-Host "▼ " -ForegroundColor Cyan -NoNewline
Write-Host " SYSTEM: $sys, NIONS: $NION, NBANDS: $NBANDS, Filled: $filled, NKPTS: $($NKPTS-$ibzkpt) " -ForegroundColor White -BackgroundColor Blue

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
}

Export-ModuleMember -Function "Export-VR2"
Export-ModuleMember -Function "Get-EigenVals"
Export-ModuleMember -Function "Get-KPTS"
Export-ModuleMember -Function "Read-KptsToExclude"
Export-ModuleMember -Function "Read-AsXml"
Export-ModuleMember -Function "Write-KptsBands"
Export-ModuleMember -Function "Write-PartialDOS"
Export-ModuleMember -Function "Write-Projection"
Export-ModuleMember -Function "Write-TotalDOS"
Export-ModuleMember -Function "Get-TotalDOS"
Export-ModuleMember -Function "Get-PartialDOS"
Export-ModuleMember -Function "Get-BandsProSet"
Export-ModuleMember -Function "Get-FillingWeights"
Export-ModuleMember -Function "Get-Summary"
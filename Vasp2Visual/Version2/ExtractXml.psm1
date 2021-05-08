
#Version 2 of Vasp2Visual that allows automatic collection of Spin Ploarized calculations as well as 
#getting individual spin sets by dedicated functions.
function Get-EigenVals {
    [cmdletbinding()]
    param (
        # Insert a powershell xml object after it is read as [xml] using Read-AsXml command.
        [Parameter(ValueFromPipeline=$true)][xml]$XmlObject,
        # Insert Number of useless KPOINTS to skip
        [Parameter()][Int]$SkipNKPTS = 0,
        # Insert How many Bands to skip and then how many to select seperated by comma. By Default,
        # it collects all bands if not provided. 
        [Parameter()][array]$SkipSelectNBANDS
    )
    Process {
    if (!$XmlObject) {$XmlObject = Read-AsXml}
    if (!$SkipSelectNBANDS) {$SkipSelectNBANDS = Get-SkipSelectBands -XmlObject $XmlObject}
    Write-Progress "Collecting Bands ..."
    $skip=[int]$SkipNKPTS;$range=@($SkipSelectNBANDS);
    $XmlEig=$XmlObject.modeling.calculation.eigenvalues.array.set
    $head=$(For($i=$range[0]+1;$i -le $range[1]+$range[0];$i++){"{0,6}{1,-6}" -f "","B$i"}) -join " "
    if($XmlEig.ChildNodes.Count -eq 2){
        $eig1=($XmlEig.set[0].set|Select-Object -Property r)
        $eig2=($XmlEig.set[1].set|Select-Object -Property r)
        $eval=($eig1,$eig2)|ForEach-Object{$head;$_|Select-Object -Skip $skip|
            ForEach-Object{($_.r|Select-Object -Skip $range[0] -First $range[1]|
                Foreach-Object{
                   "{0,12:N4}" -f $(($_.Split()|where-Object{$_})[0])}) -join " "} }
    }Else{
        
        $eig=($XmlEig.set.set|Select-Object -Property r)
        $eval=$eig|Select-Object -Skip $skip|
        ForEach-Object{($_.r|Select-Object -Skip $range[0] -First $range[1]|
            Foreach-Object{
                "{0,12:N4}" -f (($_.Split()|where-Object{$_})[0])}) -join " "}
        $eval=$head,$eval|ForEach-Object{$_} #expanding next object.
        }
    return $eval
    }
}


function Get-KPTS {
    [cmdletbinding()]
    param (
        # Insert a powershell xml object after it is read as [xml] using  Read-AsXml command.
        [Parameter(ValueFromPipeline=$true)][xml]$XmlObject,
        # Insert Number of useless KPOINTS to skip
        [Parameter()][Int]$SkipNKPTS=0
    )
    Process {
    if (!$XmlObject) {$XmlObject = Read-AsXml}
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
        $value= "{0,9:n4}" -f $([Math]::Round($($sum-$ref),4))
        $k_array=($("{0,45}" -f $_.Trim()),$value) -join ""
        return $k_array
        }
    }
    
}

function Write-KptsBands {
    [cmdletbinding()]
    param (
        # Insert a powershell xml object after it is read as [xml] using  Read-AsXml command.
        [Parameter(ValueFromPipeline=$true)][xml]$XmlObject,
        # Insert Number of useless KPOINTS to skip
        [Parameter()][Int]$SkipNKPTS = 0,
        # Insert How many Bands to skip and then how many to select seperated by comma. By Default,
        # it collects all bands upto 9999 if not provided. 
        [Parameter()][array]$SkipSelectNBANDS = (0,9999)
    )
    Process{ 
    if (!$XmlObject) {$XmlObject = Read-AsXml}
    Write-Progress "Writing bands and kpoints on [Bands.txt] ..."
    $skipk = Read-KptsToExclude -XmlObject $XmlObject
    $KptsObject = Get-KPTS -XmlObject $XmlObject -SkipNKPTS $skipk
    $BandsObject = Get-EigenVals -XmlObject $XmlObject -SkipNKPTS $skipk -SkipSelectNBANDS $SkipSelectNBANDS
    $sys = $((Get-Summary -XmlObject $XmlObject).SYSTEM) #Get System automatically
    $loc = Get-Location #location is manadatory for streamwriter.
    $filew = Join-Path -Path $loc -ChildPath "Bands.txt"
    $bandswriter = New-Object System.IO.StreamWriter $filew
    if($KptsObject.Count*2 -eq $BandsObject.Count-2){ #check Spin-polarized
    $new_kp=[System.Collections.ArrayList]@($("{0,-17}{1,7}{2,17}{3,11}{4,2}" -f "#$sys#su#kx","ky","kz","k",""))
    $KptsObject|ForEach-Object{[void]$new_kp.Add($_)}
    [void]$new_kp.Add($("{0,-17}{1,7}{2,17}{3,11}{4,2}" -f "#$sys#sd#kx","ky","kz","k",""))
    $KptsObject|ForEach-Object{[void]$new_kp.Add($_)}
    Write-Host "        DataShape: (ISPIN*[NKPTS],NBANDS)"
    }Else{
        $new_kp=[System.Collections.ArrayList]@($("{0,-17}{1,7}{2,17}{3,11}{4,2}" -f "#$sys#kx","ky","kz","k",""))
        $KptsObject|ForEach-Object{[void]$new_kp.Add($_)}  
        Write-Host "        DataShape: (NKPTS,NBANDS)"
    }
    For($i=0;$i -lt $BandsObject.Count;$i++){
        $line=($new_kp[$i],$BandsObject[$i]) -join ""
        $bandswriter.WriteLine($line)
    }  
    $bandswriter.Flush();
    $bandswriter.Close();
    }
}



function Get-Summary {
    [cmdletbinding()]
    param (
        # Insert powershell xml object. Get it using Read-AsXml command.
        [Parameter(ValueFromPipeline=$true)][xml]$XmlObject
    )
    Process {
    if (!$XmlObject) {$XmlObject = Read-AsXml}
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
    # INCAR
    $incar = $XmlObject.modeling.incar.i | ForEach-Object{
        "{0,-12:n} = '{1}'" -f $_.name,$_.'#text'.Trim()}
    # Fields
    $dos_field = $XmlObject.modeling.calculation.dos.partial.array.field
    $pro_field = $dos_field| Select-Object -Skip 1 | ForEach-Object{"'{0}'" -f $_.Trim()}
    $fields = "[{0}]" -f $($pro_field -join ", ")
    #Structure
    $volume=$XmlObject.GetElementsByTagName('structure').crystal[-1].i.'#text'.Trim()
    $basis=$XmlObject.GetElementsByTagName('structure').crystal.varray[-2].v| ForEach-Object{
        ($_.Split()| Where-Object {$_}) -join ","}
    $rec_basis=$XmlObject.GetElementsByTagName('structure').crystal.varray[-1].v| ForEach-Object{
        ($_.Split()| Where-Object {$_}) -join ","}
    $pos = $XmlObject.GetElementsByTagName('structure').varray[-1].v | ForEach-Object{
        ($_.Split()| Where-Object {$_}) -join ","}
    # Nelectrons
    $NELECT = $XmlObject.modeling.parameters.separator.i| ForEach-Object{
                if($_.name.contains('NELECT')){
                    [int]$_.'#text'}}
    return [ordered]@{ISPIN=$ISPIN;NBANDS=$NBANDS;SYSTEM=$sys;NKPTS=$NKPT;
        NION=$NION;TypeION=$TypeION;E_Fermi=$eFermi;NELECT=$NELECT;
        nField_Projection=$nOrbitals;nField_DOS=$nDOS_Fields;
        ElemIndex=$ElemIndex; ElemName=$ElemName;INCAR=$incar;fields=$fields;
        V=$volume;Basis=$basis;RecBasis=$rec_basis;Positions=$pos}
    }
}

function Read-AsXml {
    [cmdletbinding()]
    param (
        # Insert path or url to vasprun.xml file. By default it is current folder.
        # This is kept seperate to load xml once and use in other commands.
        [Parameter(ValueFromPipeline=$true)]$VasprunFile = "./vasprun.xml"
    )
    Process {
    Write-Progress "Reading $VasprunFile ..."
    if($VasprunFile.ToString().Contains('vasprun.xml')){
        $XmlObject= New-Object Xml  #To load files bigger than 0.5GB.
        $XmlObject.Load((Convert-Path $VasprunFile))
        return $XmlObject
    }Else{
        Write-Host "System can not convert given path/url.Provide a path that ends with 'vasprun.xml'" -ForegroundColor Red; 
        exit
    }
    }
}

function Read-KptsToExclude {
    [cmdletbinding()]
    param (
        # Insert powershell xml object. Get it using Read-AsXml command.
        [Parameter(ValueFromPipeline=$true)][xml]$XmlObject
    )
    Process {
    if (!$XmlObject) {$XmlObject = Read-AsXml}
    $weights=$XmlObject.modeling.kpoints.varray[1].v; $count=0
    $match=$XmlObject.modeling.kpoints.varray[1].v[-1] #Last point as match
    foreach($weight in $weights){
        if($weight.Contains($match)){$count+=1}}
    $ibzkpt=[int]((Get-Summary -XmlObject $XmlObject).NKPTS-$count) #Points to exclude.
    return $ibzkpt
    }
}


##Total Density of states.
function Get-TotalDOS {
    [cmdletbinding()]
    param (
        # Insert powershell xml object. Get it using Read-AsXml command.
        [Parameter(ValueFromPipeline=$true)][xml]$XmlObject,
        # Insert Index of the set of spin blocks. Default is 0.
        [Parameter()][int]$SpinSet=1
    )
    Process {
    if (!$XmlObject) {$XmlObject = Read-AsXml}
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
}

function Write-TotalDOS {
    [cmdletbinding()]
    param (
      # Insert powershell xml object. Get it using Read-AsXml command.
      [Parameter(ValueFromPipeline=$true)][xml]$XmlObject,
      # Insert Index of the set of spin blocks. Default is 0.
      [Parameter()][int]$SpinSet = 1
    )
    Process {
    if (!$XmlObject) {$XmlObject = Read-AsXml}
    Write-Progress "Writing Total DOS on [tDOS.txt] ..."
    $loc=(Get-Location) #for streamwriter.
    $filew = Join-Path -Path $loc -ChildPath "tDOS.txt"
    $tsw = New-Object System.IO.StreamWriter $filew #writer for DOS
    Get-TotalDOS -XmlObject $XmlObject -SpinSet 1 | ForEach-Object{$_}|ForEach-Object{$tsw.WriteLine($_)} #expand and write.
    $tsw.Flush();$tsw.Close();
    }
}

function Get-BandsProSet {
    [cmdletbinding()]
    param (
        # Insert a powershell xml object after it is read as [xml] using Read-AsXml command.
        [Parameter(ValueFromPipeline=$true)][xml]$XmlObject,
        # Inset Set Number of Spin Block you want.
        [Parameter()][int]$SpinSet=1,
        # Insert Number of useless KPOINTS to skip
        [Parameter()][Int]$SkipNKPTS=0,
        # Insert How many Bands to skip and then how many to select seperated by comma. By Default,
        # it collects all bands using function Get-Summary
        [Parameter()][array]$SkipSelectNBANDS
    )
    Process {
    if (!$XmlObject) {$XmlObject = Read-AsXml}
    if (!$SkipSelectNBANDS) {$SkipSelectNBANDS = Get-SkipSelectBands -XmlObject $XmlObject}    
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
}

function Get-PartialDOS {
    [cmdletbinding()]
    param (
        # Insert a powershell xml object after it is read as [xml] using Read-AsXml command.
        [Parameter(ValueFromPipeline=$true)][xml]$XmlObject,
        # Inset Set Number of Spin Block you want.
        [Parameter()][int]$SpinSet=1
    )
    Process {
    if (!$XmlObject) {$XmlObject = Read-AsXml}
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
    if(!$Data[0]){$Data=@()} #if out of range spin set entered, return empty data
    $dosFields=$XmlObject.GetElementsByTagName('partial').array.field | ForEach-Object{$_.Trim()}
    $ngrid=$Data.Count/$info.NION #Energy grid size.
    $shape="(NION*[GridSize],Fields)"
    return [ordered]@{SYSTEM=$info.SYSTEM;Fields=$dosFields;NION=$info.NION; ISPIN=$info.ISPIN;
        GridSize=$ngrid;SpinSet=$set;Data=$Data; ShapeOfData=$shape;
        }
    }
}
function Write-PartialDOS {
    [cmdletbinding()]
    param (
        # Insert PartialDOS object from Get-PartialDOS command
        [Parameter(ValueFromPipeline=$true)][xml]$XmlObject,
        [Parameter()][int]$SpinSet=1
        # Inset Set Number of Spin Block you want.
    )
    Process {
    if (!$XmlObject) {$XmlObject = Read-AsXml}
    $loc=(Get-Location) #for streamwriter.
    $filew = Join-Path -Path $loc -ChildPath "pDOS.txt"
    $info=Get-Summary -XmlObject $XmlObject
    if($info.ISPIN -eq 1 -and $SpinSet -eq 1){ #Avoid writing else.
        Write-Progress "Writing Partial DOS on [pDOS.txt] ..."
        $psw = New-Object System.IO.StreamWriter $filew #writer for Partial DOS
        $dosUp=(Get-PartialDOS -XmlObject $XmlObject -SpinSet 1)
        $head="#$($dosUp.SYSTEM),Fields: [$($dosUp.Fields)], Shape: (NION*[GridSize],Fields) = ($($dosUp.NION)*[$($dosUp.GridSize)],$($dosUp.Fields.Count))"
        $psw.WriteLine($head)
        $dosUp.Data| ForEach-Object{$psw.WriteLine($_)}
        $psw.Flush();$psw.Close();
        Write-Host "        DataShape: (NION*[GridSize],Fields)"
    }
    if($info.ISPIN -eq 2 -and $SpinSet -eq 1){ #Avoid writing else.
        Write-Progress "Writing Partial DOS Up/Down on [pDOS.txt] ..."
        $psw = New-Object System.IO.StreamWriter $filew #writer for Partial DOS
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
        $endName="Spin"+$dos.SpinSet + "Dos.txt"
        $filew = Join-Path -Path $loc -ChildPath $endName
        Write-Progress "Writing Partial DOS on [$filew] ..."
        $ssw = New-Object System.IO.StreamWriter $filew #writer for Partial DOS
        $ssw.WriteLine($head)
        $dos.Data| ForEach-Object{$ssw.WriteLine($_)}
        $ssw.Flush();$ssw.Close();
        Write-Host "        DataShape: (NION*[GridSize],Fields)"
    }
    }
}

function Write-Projection {
    [cmdletbinding()]
    param (
        # Insert a powershell xml object after it is read as [xml] using  Read-AsXml command.
        [Parameter(ValueFromPipeline=$true)][xml]$XmlObject,
        #Insert Spin Set you want to compute.
        [Parameter()][int]$SpinSet = 1,
        [Parameter()][Int]$SkipNKPTS = 0,
        # Insert How many Bands to skip and then how many to select seperated by comma. By Default,
        # it collects all bands using upto 9999 if not given. 
        [Parameter()][array]$SkipSelectNBANDS
    )
    Process {
    if (!$XmlObject) {$XmlObject = Read-AsXml}
    if (!$SkipSelectNBANDS) {$SkipSelectNBANDS = Get-SkipSelectBands -XmlObject $XmlObject}
    
    $skip=[int]$SkipNKPTS;$range=@($SkipSelectNBANDS);
    $info=(Get-Summary -XmlObject $XmlObject)
    $loc=Get-Location #location is manadatory for streamwriter.
    $filew = Join-Path -Path $loc -ChildPath "Projection.txt"
    if($info.ISPIN -eq 1 -and $SpinSet -eq 1){ #Avoid writing else.
        Write-Progress "Writing Bands Projection on [Projection.txt] ..."
        $psw = New-Object System.IO.StreamWriter $filew #writer for Projection
        $proUp=$(Get-BandsProSet -XmlObject $XmlObject -SkipNKPTS $skip -SkipSelectNBANDS $range[0],$range[1] -SpinSet 1)
        $head="#$($proUp.SYSTEM),Fields: [$($proUp.Fields)], Shape: (NION*[NKPTS],NBANDS*[Fields]) = ($($proUp.NION)*[$($proUp.NKPTS)],$($proUp.NBANDS)*[$($proUp.Fields.Count)])"
        $psw.WriteLine($head)
        $proUp.Data| ForEach-Object{$psw.WriteLine($_)}
        $psw.Flush();$psw.Close();
        Write-Host "        DataShape: (NION*[NKPTS],NBANDS*[Fields])"
    }
    if($info.ISPIN -eq 2 -and $SpinSet -eq 1){ #Avoid writing else.
        Write-Progress "Writing Bands Projection on [Projection.txt] ..."
        $psw = New-Object System.IO.StreamWriter $filew #writer for Projection
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
        $endName="Spin"+$pro.SpinSet+"Projection.txt"
        $filew = Join-Path -Path $loc -ChildPath $endName
        Write-Progress "Writing Bands Projection on [$filew] ..."
        $ssw = New-Object System.IO.StreamWriter $filew #writer for Bands Projection
        $ssw.WriteLine($head)
        $pro.Data| ForEach-Object{$ssw.WriteLine($_)}
        $ssw.Flush();$ssw.Close();
        Write-Host "        DataShape: (NION*[NKPTS],NBANDS*[Fields])"
    }
    }
}

function Get-FillingWeights {
    [cmdletbinding()]
    param (
        # Insert a powershell xml object after it is read as [xml] using Read-AsXml command.
        [Parameter(ValueFromPipeline=$true)][xml]$XmlObject
    )
    Process {
    if (!$XmlObject) {$XmlObject = Read-AsXml}
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
}

function Export-VaspRun {
    [cmdletbinding()]
    param (
        # Path to vasprun.xml or url.
        [Parameter(ValueFromPipeline = $true)]$VasprunFile = './vasprun.xml',
        # Skip initial kpoints
        [Parameter()][int]$SkipK = -1,
        # Insert number of required filled bands.
        [Parameter()][int]$MaxFilled = -1,
        # Insert number of required empty bands.
        [Parameter()][int]$MaxEmpty = -1,
        # Calculate DOS Only
        [Parameter()][switch]$OnlyDOS
    )
    Begin {
        $CurrentLoc = Get-Location
        $ToLocation = (Get-Item $VasprunFile).Directory.FullName
        Write-Host "Going to Directory ->" $ToLocation -ForegroundColor Green
        Set-Location $ToLocation
    }
    Process {
        if((Test-Path -Path (Get-Item $VasprunFile).FullName -PathType Leaf)){
            If($OnlyDOS.IsPresent){$getonlydos=$True}Else{$getonlydos=$False}
            . $PSScriptRoot/MainVR2.ps1    
        }Else{ Write-Host "File $VasprunFile not found"}
    }
    End {
        Write-Host "Returning Back to ->" $CurrentLoc -ForegroundColor Green
        Set-Location $CurrentLoc
    }

}
function Get-SkipSelectBands {
    <#
        .SYNOPSIS
            It will retrun how many bands to skip and how many to select based on given system.
            Powershell is good at selecting objects as -Skip -First scheme basis. 
            You have to provide how many Filled and Empty Bands you want to collect.
        .EXAMPLE
             $xml=Read-AsXml -VasprunFile Path/To/vasprun.xml
            Get-SkipSelectBands -XmlObject $xml -MaxFilled 2 -MaxEmpty 2
            Returns (skipbands,NBANDS)=(268,4)
    #>
    [cmdletbinding()]
    param (
        # Put XmlObject from Read-AsXml function.
        [Parameter(ValueFromPipeline=$true)]$XmlObject,
        # Insert how many filled bands you want to collect. Default 30.
        [Parameter()][int]$MaxFilled=30,
        # Insert how many empty bands you want to collect. Default 30.
        [Parameter()][int]$MaxEmpty=30
        
    )
    Process {
    if (!$XmlObject) {$XmlObject = Read-AsXml}
    $FillEmpty = Get-FillingWeights -XmlObject $XmlObject
    $Filled=$FillEmpty.Filled
    $Empty=$FillEmpty.UnFilled
    $SkipB=$Filled-$MaxFilled #For Big systems.
    $NBANDS=$MaxFilled+$MaxEmpty #For Big systems.
    if ($Filled -le $MaxFilled) {
        $SkipB=0;$NBANDS=$Filled+$MaxEmpty    
    }
    if($Empty -le $MaxEmpty){
        $SkipB=$Filled-$MaxFilled; $NBANDS=$MaxFilled+$Empty
    }
    if($Empty -le $MaxEmpty -and $Filled -le $MaxFilled){
        $SkipB=0;$NBANDS=$Filled+$Empty
    }

    return @($SkipB,$NBANDS)
    } 
}

# For Lazy Manipulation of Large files
function Get-XmlTags {
    param (
        # Parameter help description
        [Parameter()]$VasprunFile,
        [Parameter()][array]$TagsArray = @('xml','modeling','projected'),
        [Parameter()]$OutFile = "./sets.txt"
    )
    Process {
    if (!$VasprunFile) {$VasprunFile = "./vasprun.xml"}
    $file = (get-item $VasprunFile).FullName
    $toMatch = $TagsArray
    "File: $file" | Set-Content $OutFile
    "LineIndex  Tag" | Add-Content $OutFile
    "---------  ---" | Add-Content $OutFile
    Write-Progress $("Searching Tags '{0}' in file: {1}..." -f $($toMatch -join ","),$VasprunFile)
    $x = Select-String $toMatch $file
    Write-Progress $("Writing output on file: {0}" -f $OutFile)
    $x | ForEach-Object {"{0,9} {1}" -f $($_.LineNumber-1),$_.Line } | Add-Content $OutFile
    }
}

Export-ModuleMember -Function 'Export-VaspRun'
Export-ModuleMember -Function 'Get-EigenVals'
Export-ModuleMember -Function 'Get-KPTS'
Export-ModuleMember -Function 'Read-KptsToExclude'
Export-ModuleMember -Function 'Read-AsXml'
Export-ModuleMember -Function 'Write-KptsBands'
Export-ModuleMember -Function 'Write-PartialDOS'
Export-ModuleMember -Function 'Write-Projection'
Export-ModuleMember -Function 'Write-TotalDOS'
Export-ModuleMember -Function 'Get-TotalDOS'
Export-ModuleMember -Function 'Get-PartialDOS'
Export-ModuleMember -Function 'Get-BandsProSet'
Export-ModuleMember -Function 'Get-FillingWeights'
Export-ModuleMember -Function 'Get-Summary'
Export-ModuleMember -Function 'Get-SkipSelectBands'
Export-ModuleMember -Function 'Get-XmlTags'
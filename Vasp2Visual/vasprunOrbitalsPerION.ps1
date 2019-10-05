## This script is run in vasprunProjectedBands.ps1
#$xml= New-Object Xml  #To load files bigger than 0.5GB.
#$xml.Load((Convert-Path .\vasprun.xml))
#$xml = [xml](get-content .\vasprun.xml)
#$NKPT=$xml.modeling.calculation.eigenvalues.array.set.set.set.Length
$nOrbitals=$xml.modeling.calculation.projected.array.field.Count
$nDOS_Fields=$xml.modeling.calculation.dos.partial.array.field.Count #number of fields in DOS
$loc=Get-Location
Write-Host "NAME: $name, TOTAL IONS: $ionTotal" -ForegroundColor Yellow
$head=($xml.modeling.calculation.projected.array.field -join ' ').Trim()
$arrHead=[System.Collections.ArrayList]::new() #array for header
Foreach($j in $bandInterval) {  #Header   #$NBANDS rom upper script
[void]$arrHead.Add("$j|$head|")  #[void] stops writing to terminal
} $arrHead=$arrHead -join '            ';
$headDOS=$xml.modeling.calculation.dos.partial.array.field -join '       ' #DOS Head
#============================================================
Foreach($a in $ionstart..$($ionstart-(-$ionTotal)-1)){ #ions number loop
$t_loop=[Diagnostics.Stopwatch]::StartNew() #Stopwatch
$sw.WriteLine("#$name($sys)#$($a+1)#$arrHead") #Header, $sw opens from other file.
$dsw.WriteLine("#$name($sys)#$($a+1)#$headDOS") #DOS header
$moreSpins=$xml.modeling.calculation.projected.array.set.set.comment.EndsWith(2) #logic for spin block number
if (-not $moreSpins) { #checks for number of spin blocks, runs if false, Invokes other script if true. 
   #+++++++++++++++++Normal Block++++++++++++++++
   #+++++++++++++++++Bands Projection++++++++++++++
   For($i=$ibzkpt;$i -le $($NKPT-1);$i++){ #Kpoints loop
        #For ($e=$from; $e -le ($NBANDS-1); $e++)
        Foreach($e in $bandInterval){ #Bands number loop
             if($NION.Equals(1)){$arrSPD=$xml.modeling.calculation.projected.array.set.set.set[$i].set[$e].r.Trim()
             }Else{ #more than 1 ions
                    $arrSPD=$xml.modeling.calculation.projected.array.set.set.set[$i].set[$e].r[$a].Trim()
                     }
             $sw.Write("   $arrSPD   ")   #Writes on same line.
        } #bands block ends
        $sw.WriteLine() #Enters new line.
   } #$sw.Dispose(); #KPOINTS block ends
    $share=$perc; #update share for next 
   #+++++++++++++++++DOS Projection++++++++++++++
   if($NION.Equals(1)){$nE=[int]$xml.modeling.calculation.dos.partial.array.set.set.set.r.Count
   }Else{$nE=[int]$xml.modeling.calculation.dos.partial.array.set.set[0].set.r.Count} #counts nE
   Foreach($ii in 0..$($nE-1)){ #Energy Loop
      if($NION.Equals(1)){$arrDOS=$xml.modeling.calculation.dos.partial.array.set.set.set.r[$ii].Trim()
      }Else{
       $arrDOS=$xml.modeling.calculation.dos.partial.array.set.set[$a].set.r[$ii].Trim()
       }
       $dsw.WriteLine("$arrDOS")
   }#$dsw.Dispose();
}Else{ #========Code Break===================
   #+++++++++++++++++Spin Blocks++++++++++++++++
   #+++++++++++++++++Bands Projection++++++++++++++
   For($i=$ibzkpt;$i -le $($NKPT-1);$i++){ #Kpoints loop
        Foreach($e in $bandInterval){ #Bands number loop
          if($NION.Equals(1)){$arrSPD=$xml.modeling.calculation.projected.array.set.set[0].set[$i].set[$e].r.Trim()
                }Else{ #more than 1 ions.
                        $arrSPD=$xml.modeling.calculation.projected.array.set.set[0].set[$i].set[$e].r[$a].Trim()
                }
                $sw.Write("   $arrSPD   ")   #Writes on same line.
        } #bands block ends
        $sw.WriteLine() #Enters new line.
   } #$sw.Dispose()#KPOINTS block ends
   #+++++++++++++++++DOS Projection++++++++++++++
   if($NION.Equals(1)){$nE=[int]$xml.modeling.calculation.dos.partial.array.set.set.set[0].r.Count
   }Else{$nE=[int]$xml.modeling.calculation.dos.partial.array.set.set[0].set[0].r.Count} #counts nE
   Foreach($ii in 0..$($nE-1)){ #Energy Loop
        if($NION.Equals(1)){$arrDOS=$xml.modeling.calculation.dos.partial.array.set.set.set[0].r[$ii].Trim()
        }Else{
        $arrDOS=$xml.modeling.calculation.dos.partial.array.set.set[$a].set[0].r[$ii].Trim()
        }
        $dsw.WriteLine("$arrDOS")
   }#$dsw.Dispose();
} 
$t_elapsed=$t_loop.Elapsed.TotalMinutes; $t_loop.Stop();
        $eta=[Math]::Round($($t_elapsed*($NION-$a)),2); $percent= $([Math]::Floor($(100*($a+1)/($NION))));
        Write-Progress "Calculating Projection of ION# $($a+1) ($name) ... [ETA: $eta Minutes]" -Status "$percent % Completed." -PercentComplete $percent
}#Ends
 
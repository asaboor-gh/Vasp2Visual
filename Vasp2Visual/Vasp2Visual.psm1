<#
.SYNOPSIS
  <Vasp2Visual>
.DESCRIPTION
  <Post processing of Vasp output by Powershell+Python>
.INPUTS
  <vasprun.xml>
.OUTPUTS
  <Projection.txt, Bands.txt,pDOS.txt,tDOS.txt>
.NOTES
  Version:        1.0
  Author:         Abdul Saboor
  Creation Date:  2019/09/14
  Change: Initial script development
  #>
Function Get-VaspProjection {
if(-not $(Test-Path -Path .\vasprun.xml)){
Write-Host "The file 'vasprun.xml' not found" -ForegroundColor Red; 
}Else{
. $PSScriptRoot\vasprunProjectedBands.ps1
}
}
Function Get-KPath { #creates KPOINTS path
. $PSScriptRoot\KPathGenerator.ps1
}
Function Out-Path { #cahnges paths
. $PSScriptRoot\GetLaTeXLinuxPath.ps1
}
Function Close-Writers { #closes opened writers
Foreach($stwr in $Writers){$stwr.Close()}
Write-Host "All opened StreamWriters are now closed." -ForegroundColor Green
}
Function Get-PlotArguments{ #Creates an ordered hashtable to use in plot arguments
[ordered]@{tickIndices="[0,25,50,75,100,-1]"; ticklabels="['L',r'$\Gamma$','X','W','K',r'$\Gamma$']";
E_Limit="[10,-15]"; DOS_Limit="[0.0,1.2]"; WidthToColumnRatio=1;
ProLabels="['Ga','s','p','d']"; ProIndices="[(range(0,1,1)),(0,),(1,2,3,),(4,5,6,7,8,)]";}
}
Function Get-Plot{ #Plots of different types
[CmdletBinding()]
Param([Parameter()][switch]$ProjectedBandsDOS, 
#[Parameter()][switch]$ProjectedBands, [Parameter()][switch]$ProjectedDOS,
 [Parameter()][switch]$BandsDOS,#[Parameter()][switch]$DOS, [Parameter()][switch]$Bands,
[hashtable]$PlotArguments)  #Get Hashtable from function Get-PlotArguments
#making a plot file in order
$variablesList=@();
$(Foreach($key in $PlotArguments.Keys){
$xxx="$($key) =$($PlotArguments.$key);" 
$variablesList+=$xxx}); $variablesList=$($variablesList|Sort-Object) -join "`n"
$consoleInput=@"
$variablesList
"@
. $PSScriptRoot\BDPlotFile.ps1
if($ProjectedBandsDOS.IsPresent){$FileInput=$FileString}
if($BandsDOS.IsPresent){$FileInput=$SimpleFileString}
$pythonFileContent=@"
#=================Input Variables=====================
$($consoleInput)
$($FileInput)
"@
$pythonFileContent|Set-Content .\Plot.py
python .\Plot.py #strat plotting
}
Function Export-LOCPOT{
. $PSScriptRoot\LOCPOT.ps1
}
Export-ModuleMember -Function 'Get-VaspProjection'
Export-ModuleMember -Function 'Get-KPath'
Export-ModuleMember -Function 'Out-Path'
Export-ModuleMember -Function 'Close-Writers'
Export-ModuleMember -Function 'Get-PlotArguments'
Export-ModuleMember -Function 'Get-Plot'
Export-ModuleMember -Function 'Export-LOCPOT'

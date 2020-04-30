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
Function Export-VaspRun {
if(-not $(Test-Path -Path .\vasprun.xml)){
Write-Host "The file 'vasprun.xml' not found" -ForegroundColor Red; 
}Else{
. $PSScriptRoot\vasprunProjectedBands.ps1
}
}

Function Out-Path ($Path=$(Get-Location)){ #cahnges paths
  $winpath=(Get-Item $Path) #chnage string to path
  $drive=$winpath.FullName.Split(':')[0].ToLower()
  $path=Split-Path $winpath -NoQualifier
  $linuxPath = (-Join('/mnt/',-Join($drive,(($path -replace "\\","/") -replace ":","")))).TrimEnd("/")
  $latexPath = ($winpath -replace "\\","/").Trim("/")
  Set-Clipboard  "$linuxPath";
  [ordered]@{LinuxPath=$linuxPath;LatexPath=$latexPath;OnClipboard=$linuxPath}
}
Function Close-Writers { #closes opened writers
Foreach($stwr in $Writers){$stwr.Close()}
Write-Host "All opened StreamWriters are now closed." -ForegroundColor Green
}
Function Get-PlotArguments{ 
  <#
  Creates an ordered hashtable to use in plot arguments
  in plot, interactive plot and density plot.
  Defualt return is for Get-Plot, others by switches.
  #>
  Param(
    [Parameter()][switch]$DOS, 
    [Parameter()][switch]$Plotly
  )
  if($Plotly.IsPresent){
    $args=[ordered]@{JoinPathAt="[]";tickIndices="[0,-1]"; ticklabels="[u'\u0393','M'] ";
    E_Limit="[5,-5]"; ProLabels="['Element0','s','p','d']"; ProIndices="[(range(0,1,1)),(0,),(1,2,3,),(4,5,6,7,8,)]";}
  }elseif($DOS.IsPresent){
    $args=[ordered]@{textLocation ="[0.05,0.9]"; DOS_Limit ="[0.0,0.6]"; FigureHeight =2.5;
    E_Limit="[5,-5]"; ProLabels="['Element0','s','p','d']";ProIndices="[(range(0,1,1)),(0,),(1,2,3,),(4,5,6,7,8,)]";}
  }Else{
    $args=[ordered]@{JoinPathAt="[]";tickIndices="[0,-1]"; ticklabels="['L',r'$\Gamma$']";
    E_Limit="[10,-10]"; DOS_Limit="[0.0,1.2]"; textLocation="[0.05,0.9]";FigureHeight=3;
    ProLabels="['Element0','s','p','d']"; ProIndices="[(range(0,1,1)),(0,),(1,2,3,),(4,5,6,7,8,)]";}
  }
  return $args
}
Function Get-Plot{ #Plots of different types
[CmdletBinding()]
Param([Parameter()][switch]$HalfColumnWide,
[Parameter()][switch]$ProjectedBandsDOS, 
[Parameter()][switch]$ProjectedBands, #[Parameter()][switch]$ProjectedDOS,
[Parameter()][switch]$BandsDOS,#[Parameter()][switch]$DOS, 
[Parameter()][switch]$Bands,
[hashtable]$PlotArguments)  #Get Hashtable from function Get-PlotArguments
if(-not (Test-Path .\Bands.txt)){Write-Host "Required files not found. Generating using 'Export-VaspRun' ..." -ForegroundColor Green;
    Export-VaspRun;}
    if($(Test-Path .\Bands.txt)){ #checks if file generated.
    Write-Host "Files now exist. Plotting ..." -ForegroundColor Yellow;
#making a plot file in order
$variablesList=$PlotArguments.GetEnumerator()| 
    Sort-Object -Descending|
    ForEach-Object{"{0,-12} = {1};" -f $_.key,$_.value}|Out-String
$consoleInput=@"
$variablesList
"@
. $PSScriptRoot\BDPlotFile.ps1
if($HalfColumnWide.IsPresent){$WidthToColumnRatio=0.5}Else{$WidthToColumnRatio=1.0}
if($ProjectedBandsDOS.IsPresent){$FileInput=$FileString}
if($BandsDOS.IsPresent){$FileInput=$SimpleFileString}
if($ProjectedBands.IsPresent){$FileInput=$ProjectedBandsFileString}
if($Bands.IsPresent){$FileInput=$BandsFileString}
$pythonFileContent=@"
#=================Input Variables=====================
$($consoleInput)
WidthToColumnRatio=$($WidthToColumnRatio); 
$($FileInput)
"@
$pythonFileContent|Set-Content .\Plot.py
python .\Plot.py #strat plotting
} #if block ends
}
Function Export-LOCPOT{
  if(-not $(Test-Path -Path .\LOCPOT)){
    Write-Host "'LOCPOT' not found" -ForegroundColor Red; 
    }Else{
. $PSScriptRoot\LOCPOT.ps1}
}
Export-ModuleMember -Function 'Export-VaspRun'
Export-ModuleMember -Function 'Out-Path'
Export-ModuleMember -Function 'Close-Writers'
Export-ModuleMember -Function 'Get-PlotArguments'
Export-ModuleMember -Function 'Get-Plot'
Export-ModuleMember -Function 'Export-LOCPOT'
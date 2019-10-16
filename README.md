# Vasp2Visual
A Pre/Post processing PowerShell Module for Vasp output. Scripts allow user take full control of their vasp output data. You can plot on your own by just getting data in column format through using the command **Export-VaspRun** in a folder containing **vasprun.xml**. The plot file is generated after running **Get-Plot** is editable per your choice,although the plot you get is publication ready. You are strongly recommended to download [STIX Fonts](https://www.stixfonts.org/) to make your plot fonts similar to article's fonts. The basic commands include the following.
```powershell
PS> Get-Command -Module Vasp2Visual
CommandType     Name
-----------     ----
Function        Close-Writers
Function        Disable-SelectiveDynamics
Function        Enable-SelectiveDynamics
Function        Export-LOCPOT
Function        Export-VaspRun
Function        Find-GapOfBands
Function        Format-DataInFile
Function        Get-IndexedPlot
Function        Get-KPath
Function        Get-Plot
Function        Get-PlotArguments
Function        Measure-Distance
Function        Merge-ToSlab
Function        Out-Path
Function        Select-SitesInLayers
Function        Show-BandInfo
Function        Show-LayersInfo
```
## Get-IntoYourWorkStation
- Launch your Powershell console and run **Set-ExecutionPolicy Unrestricted**. This will allow you to run scripts.
- Find the path to Powershell Module by running **$env:PSModulePath** command and then download the directory [Vasp2Visual](Vasp2Visual) in that path. There are usually three paths.
```powershell
PS> $env:PSModulePath
#C:\Users\mass_\Documents\WindowsPowerShell\Modules;
#C:\Program Files\WindowsPowerShell\Modules;
#C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules
```
- Running **Import-Module Vasp2Visual** in Powershell console will make all commands in this module available to use. If you want to make it permanent, include this import command in your powershell profile by typying **your_editor $PROFILE**.
- Now run **Get-Module** command. This will show you that Vasp2Visual is ready and you can see list of commands.
- You need vasprun.xml file to collect data. It is recommended that if you have **vasprun.xml** file from DOS calculations,put that file in a folder named **dos** or **DOS** in the root folder where vasprun.xml is present from a bandstructure calculation and *run plotting commands only in root folder* but run *Export-VaspRun* in each folder in case of BandDOS composite plots.
## Get-FunctionsWork
- Watch [Vasp2Visual.mp4](Vasp2Visual.mp4) to know how to run the commands.

To import Vasp2Visual and see if it is available in current session, run
```powershell
PS> Import-Module Vasp2Visual
PS> Get-Module  #will give all imported modules including the one you just imported
#Script     1.0.0.0    Vasp2Visual                         {Close-Writers, Get-KPath, Get-Plot, Get-PlotArguments...}
```
To permanently import it into your profile, run the following cmdlet
```powershell
PS> "Import-Module Vasp2Visual"|Add-Content $PROFILE
```
If you are working in WSL on windows, you probably encounter switching between windows and linux terminals, so here is a function that changes the current windows directory path into Linux and LaTeX path formats.
```powershell
PS> Out-Path
#Current directory is copied to Clipboard as: Linux Path:  /mnt/c/Users/mass_
#LaTeX Path:  C:/Users/mass_
```
Vasp2Visual contains a cmdlet for creating a K-Path before you run a calculation on vasp(HSE).
```powershell
PS> Get-KPath -KptsArray_nCross3 (0,0,0),(0.5,0.5,0.5),(0.25,0.25,0),(0.5,0,0) -nPerInterval 10
File [KPath.txt] created. Output copied to clipboard.
```
In case you want to join two disconnected path patches, just create an array of two arrays(of those two patches) and pipe it to a foreach loop to create a new file because *Get-KPath* creates new file each time and delete any older file, so we get content of the file in first run before the loop goes to second run and so on.
```powershell
PS> ((0,0,0),(0.5,0.5,0.5)),((0.5,0,0),(0,0.5,0))|Foreach{Get-KPath $_ 3; (Get-Content .\KPath.txt)|Add-Content .\NewFile.txt}
  File [KPath.txt] created. Output copied to clipboard
  File [KPath.txt] created. Output copied to clipboard
PS> gc NewFile.txt
  0.0000      0.0000       0.0000       0
  0.2500      0.2500       0.2500       0.0000
  0.5000      0.5000       0.5000       0
  0.5000      0.0000       0.0000       0
  0.2500      0.2500       0.0000       0.0000
  0.0000      0.5000       0.0000       0
```
For accessing any entry of a tabular data file, you can use the following command
```powershell
PS> Format-DataInFile .\Bands.txt -ExculdeComments -ViewAsExcel -CommentStartsWith '#'
```
which gives output in an Excel-like window as shown below. You can apply sorting operation in this window and much more. Theoretically you can see any file this way without opening any editor or a big program like Excel.
In case you want to access a data entry in column_5,row_7, you can view it as an indexed dataframe. 
```powershell
PS> (Format-DataInFile .\Bands.txt).Col_5[7]                                         
    -14.007
```
![ExcelView](ExcelView.jpg)
In order to collect data from **vasprun.xml**, run the command
```powershell
PS> Export-VaspRun
#For a system with NBANDS > 40, it will prompt to select a range of bands
<#[SYSTEM] structure contains  64 ions and 780 bands.           
 [To get all bands, Type 530, 250] ⇚ OR ⇛ [Collect almost ↑↓ 30 bands around VBM]
 Seperate entries by a comma: e.g. 530, 250                         
 NBANDS_FILLED, NBANDS_EMPTY: 15,10 #>
```
This will make 4 files, Bands.txt, tDOS.txt,pDOS.txt and Projection.txt. Projections are written ion-wise in same file. 

If running the above cmdlet throws an error and stops running, then you **must run** the following command
```powershell
PS> Close-Writers #This will close all opened stream writers. 
```
Now you are able to use your own plotting method to get output, but you can instead use *Get-Plot* function to let it work automatically for you. Before going forward, lets get to know how many arguments are available and then you can just edit arguments.
```powershell
PS> $x=Get-PlotArguments
PS> $x.E_Limit="[-10,15]" #sets your defined energy limit in plot
PS> $x.ticklabels  #will show up ticklabels and you can edit
PS> $x.WidthToColumnRatio #detemines plot width in units of column width of article.
#After editing all keys in $x.Key for your system, you can run the following cmdlet to get plot
PS> Get-Plot -ProjectedBandDOS -PlotArguments $x #will output a plot. You can add -HalfColumnWide switch to make small size plots.
```
Export LOCPOT file into seperate x,y,z-directed potentials using
```powershell
PS> Export-LOCPOT #Creates three plane data files consisting minimum,maximum and average potential in each direction.
```
### Get-PublicationsReadyPlots
- Seperate and composite plots can be made using switches like *-Bands*, *-BandDOS*, *-ProjectedBands*, *-ProjectedBandDOS*. Plot size could be decreased to half of an article column width by using *-HalfColumnWide* switch. You can make your own plots from data.
## Get-More
- Seperate DOS plotting scripts are under work!
## Get-Automated
- Script for converting LOCPOT into plane and plottable data formats is here now! Use **Export-LOCPOT** function.
- Make Slab in z-direction (make sure none of POSCAR have zx,zy,xz,yz non-zero i.e angle c should be 90, otherwise result will be wrong. Rotate POSCAR in pure z-direction using Vesta before inputting here and after making slab, rotate it back.
```powershell
PS> Merge-ToSlab -FirstPOSCAR .\slab.vasp -SecondPOSCAR .\slab.vasp #Merges two POSCARS in z-direction
Only Cubic and Tetragonal POSCARs are supported.
Make sure your POSCARs DO NOT have non-zero xz,yz,zx,zy elements,
If so, first rotate POSCAR using Vesta.
File [POSCAR_New.vasp] created.
```
- This will enable/disable selective dynamics at given sites.
```powershell
PS> Enable-SelectiveDynamics -InputPOSCAR .\POSCAR.vasp -SelectSitesNumber 1,2,5
File [POSCAR_eSD.vasp] is created.
PS> Disable-SelectiveDynamics -InputPOSCAR .\POSCAR_eSD.vasp
File [POSCAR_dSD.vasp] is created.
```
- This cmdlet gets sites number for a layer with given z coordinate value upto 2 decimal place. These sites could be input to *Enable-SelectiveDynamics*.
```powershell
PS> Select-SitesInLayers -InputPOSCAR .\POSCAR.vasp -Array_2Decimal 0.00,0.25

XY_PlaneSites YZ_PlaneSites ZX_PlaneSites
------------- ------------- -------------
{1, 2, 5, 6}  {1, 4, 6, 7}  {1, 3, 5, 7}
```
- This is good only for slabs with number of layers less than 100 as two decimal places are slected. For more than 100 layers in z-direction, either use *Enable-SelectiveDynamics* with explicit sites number provided or contact me to make the script flexible. The number of layers less than 100  is kept on purpose, as I can not remember third decimal place and I believe many of us can't do so as well. Also when we dope a single element in a slab, coordinates are displaced a little. But no issue here, because you will not miss your selected layer as long as you use first two decimals (without rounding).
- You can get X,Y,Z coordinates of layers in a POSCAR for input argument in *Select-SitesInLayers* cmdlet by using the command
```powershell
PS> Show-LayersInfo .\Conventional.vasp


X_AtLayers               Y_AtLayers               Z_AtLayers
----------               ----------               ----------
{0.00, 0.25, 0.50, 0.75} {0.00, 0.25, 0.50, 0.75} {0.00, 0.25, 0.50, 0.75}
```
- Automation functions are here to boost the productivity. For example, to know band gap, spin-orbit split-off, use the following functions.
```powershell
PS> Show-BandInfo 9 #returns information about band as output below.
Name                           Value                                           
----                           -----                                           
Minimum                        -0.1617                                         
Maximum                        3.3817                                          
BandNumber                     9                                               
K_min                          75                                              
K_max                          25
PS> Get-IndexedPlot 30,-20 -xTickDistance 25 #Creates the plot with bands and k-point indexed as givnen in figure below.
PS> Find-GapOfBands 10 9 #returns band gap. 
```
Above command Can return bandwidth if smaller index is first say 9 10, or of same band 9 9. This is extemely useful to find the Bandwith between VBM and Minimim value of energy on lowest band. try:
```powershell
PS> Find-GapOfBands 1 9
17.4247
BandWidth (1 → 9): 17.4247 eV is copied to clipboard.
```
![IndexedPlot](IndexedPlot.svg)
- This is extremely useful to get **Spin-Orbit split-off**. Just input a single argument consisting 2 points (k1_index,BandNumber1),(k2_index,BandNumber2) with no space.
```powershell
PS> Measure-Distance -K1B1_K2B2 (25,8),(25,7) #return distance between any two points on k-E plane. Below is return of Above command.
Name                           Value                                           
----                           -----                                           
Point_1                        {0.8660, 3.3817}                                
Point_2                        {0.8660, 3.3817}                                
Distance                       0                                               
Distance: 0 [dimensionless] is copied to clipboard.
```


# Vasp2Visual
Post processing PowerShell Module for Vasp output. Scripts allow user take full control of their vasp output data. You can plot on your own by just getting data in column format through using the command **Get-VaspProjection** in a folder containing **vasprun.xml**. The plot file is generated after running **Get-Plot** is editable per your choice,although the plot you get is publication ready. You are strongly recommended to download [STIX Fonts](https://www.stixfonts.org/) to make your plot fonts similar to article's fonts. 
## Get-IntoYourWorkStation
- Launch your Powershell console and run **Set-ExecutionPolicy Unrestricted**. This will allow you to run scripts.
- Find the path to Powershell Module by running **$env:PSModulePath** command and then download the directory [Vasp2Visual](Vasp2Visual) in that path. There are usually three paths.
```powershell
PS> $env:PSModulePath
#C:\Users\mass_\Documents\WindowsPowerShell\Modules;
#C:\Program Files\WindowsPowerShell\Modules;
#C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules
```
- Running **Import-Module Vasp2Visual** in Powershell console will make all commands in this module available to use. If you want to make it permamanent, include this import command in your powershell profile by typying **your_editor $PROFILE**.
- Now run **Get-Module** command. This will show you that Vasp2Visual is ready and you can see list of commands.
- You need vasprun.xml file to collect data. It is recommended that if you have **vasprun.xml** file from DOS calculations,put that file in a folder named **dos** or **DOS** in the root folder where vasprun.xml is present from a bandstructure calculation and *run plotting commands only in root folder* but run *Get-VaspProjection* in each folder in case of BandDOS composite plots.
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
PS> Get-KPath  #You need to enter high symmetry KPOINTS in prompts to get path.
```
In order to collect date from **vasprun.xml**, run the command
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
Now you are able to use your own plotting method to get output, but you can instead use *Get-Plot* function to let it work automatically for you. Before going forward, lets get to know how many arguments are available and then you can just edit argument.
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
- Make Slab in z-direction (make sure none of POSCAR have zx,zy,xz,yz non-zero i.e angle c should be 90, otherwise result will be wrong. Rotate POSCAR in pure z-direction using Vesta before inputting here and after making slab, rotate it back. (Given POSCAR should **NOT** contain **Selective dynamics** line.)
```powershell
Merge-ToSlab -FirstPOSCAR .\slab.vasp -SecondPOSCAR .\slab.vasp #Merges two POSCARS in z-direction
Can't give correct results for POSCARs with off-diagonal elements.
    Only Cubic and Tetragonal POSCARs are supported.
    Make sure your POSCARs DO NOT have non-zero xz,yz,zx,zy elements,
    If so, first rotate POSCAR using Vesta.
File [NewSlab.vasp] created.
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


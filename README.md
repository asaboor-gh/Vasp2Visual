# Vasp2Visual
Post processing PowerShell Module for Vasp output. Scripts allow user take full control of their vasp output data. You can plot on your own by just getting data in column format through using the command **Get-VaspProjection** in a folder containing **vasprun.xml**. The plot file is generated after running **Get-Plot** is editable per your choice,although the plot you get is publication ready. You are strongly recommended to download [STIX Fonts](https://www.stixfonts.org/) to make your plot fonts similar to article's fonts. 
## Get-IntoYourWorkStation
- Launch your Powershell console and run **Set-ExecutionPolicy Unrestricted**. This will allow you to run scripts.
- Find the path to Powershell Module by running **$env:PSModulePath** command and then download the directory [Vasp2Visual](Vasp2Visual) in that path.
- Running **Import-Module Vasp2Visual** in Powershell console will make all commands in this module available to use. If you want to make it permamanent, include this import command in your powershell profile by typying **your_editor $PROFILE**.
- Now run **Get-Module** command. This will show you that Vasp2Visual is ready and you can see list of commands.
- Currently you can only plot Bands+DOS composite plots. 
- You need vasprun.xml file to collect data. It is recommended that if you have **vasprun.xml** file from DOS calculations,put that file in a folder named **dos** or **DOS** in the root folder where vasprun.xml is present from a bandstructure calculation.
## Get-CmdletsWork
- Watch [Vasp2Visual.mp4](Vasp2Visual.mp4) to know how to run the commands.

Import Vasp2Visual and see if it is available in session,run
```powershell
Import-Module Vasp2Visual
Get-Module
```
To permanently import it into your profile, run the following cmdlet
```powershell
"Import-Module Vasp2Visual"|Add-Content $PROFILE
```
Now in a folder where *vasprun.xml* is present, run the cmdlet
```powershell
Get-VaspProjection
```
This will make 4 files, Bands.txt, tDOS.txt,pDOS.txt and Projection.txt. Projections are written ion-wise in same file. Now you are able to use your own plotting method to get output, but you can instead use *Get-Plot* cmdlet to let it work automatically for you. Before going forward, lets get to know how many arguments are available and then you can just edit argument.
```powershell
$x=Get-PlotArguments
$x.E_Limit="[-10,15]" #sets your defined energy limit in plot
$x.ticklabels  #will show up ticklabels and you can edit
$x.WidthToColumnRatio #detemines plot width in units of column width of article.
#Now you can run the following cmdlet to get plot
Get-Plot -ProjectedBandDOS -PlotArguments $x #will output a plot
```
## Get-Documentation 
- Visit [Wiki@Vasp2Visual](https://github.com/massgh/Vasp2Visual/wiki) for documentation. The page will be updated soon.

## Get-More
- Multiple flexible plotting scripts are under work!
- Script for converting LOCPOT into plane and plottable data formats is coming soon!


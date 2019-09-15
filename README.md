# Vasp2Visual
Post processing PowerShell Module for Vasp output. Scripts allow user take full control of their vasp output data. You can plot on your own by just getting data in column format through using the command **Get-VaspProjection** in a folder containing **vasprun.xml**. The plot file is generated after running **Get-Plot** is editable per your choice,although the plot you get is publication ready. You are strongly recommended to download [STIX Fonts](https://www.stixfonts.org/) to make your plot fonts similar to article. 
## Usage
- Launch your Powershell console and run **Set-ExecutionPolicy Unrestricted**. This will allow you to run scripts.
- Find the path to Powershell Module by running **$env:PSModulePath** command and then download the directory **Vasp2Visual** in that path.
- Running **Import-Module Vasp2Visual** in Powershell console will make all commands in this module available to use. If you want to make it permamanent, include this import command in your powershell profile by typying **your_editor $PROFILE**.
- Now run **Get-Module** command. This will show you that Vasp2Visual is ready and you can see list of commands.
- Currently you can only plot Bands+DOS composite plots. 
- You need vasprun.xml file to collect data. It is recommended that if you have **vasprun.xml** file from DOS calculations,put that file in a folder named **dos** or **DOS** in the root folder where vasprun.xml is present from a bandstructure calculation.
- Watch **Vasp2Visual.mp4** to know how to run the commands.
## Documentation is available at Wiki, Nevigate on top toolbar.

## Scripts for converting vasprun.xml/LOCPOT into plane and plottable data formats are on the way.


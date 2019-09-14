# Vasp2Visual
Post processing PowerShell Module for Vasp output. 
## Usage
- Launch your Powershell console and run "Set-ExecutionPolicy Unrestricted". This will allow you to run scripts.
- Find the path to Powershell Module by running "$env:PSMOdulePath" command and then download the directory "Vasp2Visual" in that path.
- Running "Import-Module Vasp2Visual" in Powershell console will make all commands in this module available to use. If you want to make it permamanent, incluse this import command in your powershell profile by typying "your_editor $PROFILE".
- Now run "Get-Module" command. This will show you that Vasp2Visual is ready and you can see list of commands.
- Currently you can only plot Bands+DOS composite plots. 
## Documentation is available at Wiki, Nevigate on top toolbar.

## Scripts for converting vasprun.xml/LOCPOT into plane and plottable data formats are on the way.

## Scripts are to allow users take full control of their vasp output data.

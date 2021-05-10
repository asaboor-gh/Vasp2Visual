<#
.NAME
  New-Figure
.DESCRIPTION
  This function plot 6 diffrent kind of figures from Pivotpy module in Python. 
.REMARKS 
  Use Powershell new line character `n in joining commnads for -AfterPlotCode, NOT \n. 
  Use ax and plt before commands, otherwise error will be thrown. Keep track of indentation too. 
.EXAMPLE
  New-Figure -sRGB -AfterCode "ax.set_ylabel('')`nax.grid(axis='x')`nplt.subplots_adjust(left=0.2)"
  This will add following lines after plot command:

    ax.set_ylabel('')
    ax.grid(axis='x')
    plt.subplots_adjust(left=0.2)
    #>

# All plots from vasprun.xml are here.
function Get-FigArgs {
    [CmdletBinding()]
        param (
            [Parameter()][switch]$sBands,
            [Parameter()][switch]$sDOS,
            [Parameter()][switch]$iRGB,
            [Parameter()][switch]$iDOS,
            [Parameter()][switch]$sColor,
            [Parameter()][switch]$sRGB
        )
    $out = $null
    if($sBands.IsPresent){
        [hashtable]$out=[ordered]@{kseg_inds = "[]";ktick_inds = "[]";ktick_vals = "[]";E_Fermi = "None";txt = "None";xytxt = "[0.05, 0.9]";ctxt = "'black'";interp_nk = "{}";}
    }
    if($sDOS.IsPresent){
        [hashtable]$out=[ordered]@{include_dos = "'both'";elements = "[[0]]";orbs = "[[0]]";labels = "['s']";colormap = "'gist_rainbow'";tdos_color = "(0.8, 0.95, 0.8)";linewidth = "0.5";fill_area = "True";vertical = "False";E_Fermi = "None";
        txt = "None";xytxt = "[0.05, 0.85]";ctxt = "'black'";spin = "'both'";interp_nk = "{}";showlegend = "True";
        legend_kwargs = "{'ncol': 4, 'anchor': (0, 1), 'handletextpad': 0.5, 'handlelength': 1, 'fontsize': 'small', 'frameon':True}";}
    }
    if($iRGB.IsPresent){
        [hashtable]$out=[ordered]@{elements = "[[],[],[]]";orbs = "[[], [], []]"; labels = "['', '', '']";mode = "'markers'"; E_Fermi = "None";kseg_inds = "[]";max_width = "5";
        title = "None";ktick_inds = "[0, -1]";ktick_vals = "['Γ', 'M']";figsize = "None";interp_nk = "{}";}
    }
    if($iDOS.IsPresent){
        [hashtable]$out=[ordered]@{elements = "[[0]]";orbs = "[[0]]";labels = "['s']";colormap = "'gist_rainbow'";tdos_color = "(0.5, 0.95, 0)";linewidth = "2";fill_area = "True";
        vertical = "False";E_Fermi = "None";figsize = "None";spin = "'both'";interp_nk = "{}";title = "None"}
    }
    if($sColor.IsPresent){
        [hashtable]$out=[ordered]@{kseg_inds = "[]"; elements = "[[0]]"; orbs = "[[0]]";     labels = "['s']";colormap = "'gist_rainbow'"; max_width = "2.5";  
        ktick_inds = "[0, -1]"; ktick_vals = "['$\\Gamma$', 'M']"; E_Fermi = "None"; showlegend = "True"; txt = "None"; xytxt = "[0.05, 0.85]"; 
        ctxt = "'black'"; spin = "'both'"; interp_nk = "{}";
        legend_kwargs = "{'ncol': 4, 'anchor': (0, 0.85), 'handletextpad': 0.5, 'handlelength': 1, 'fontsize': 'small', 'frameon': True}";
        }
    }
    if($sRGB.IsPresent){
        [hashtable]$out=[ordered]@{kseg_inds = "[]";elements = "[[], [], []]";   orbs = "[[], [], []]"; labels = "['', '', '']"; max_width = "2.5"; ktick_inds = "[0, -1]"; ktick_vals = "['$\\Gamma$', 'M']";
        E_Fermi = "None";txt = "None";xytxt = "[0.05, 0.9]";ctxt = "'black'";uni_width = "False";interp_nk = "{}";spin = "'both'";scale_color = "True"; colorbar="True" ;
        }
    }
    $out
}

function New-Figure {
    [CmdletBinding(DefaultParameterSetName='MPL')]
    param (
       # Input Vasprun.xml
       [Parameter(ValueFromPipeline = $true)]$VasprunFile="./vasprun.xml",
       # Switches for Plots
       [Parameter(Position=1,ParameterSetName='MPL')][switch]$sBands,
       [Parameter(Position=1,ParameterSetName='MPL')][switch]$sDOS,
       [Parameter(Position=1,ParameterSetName='Plotly')][switch]$iRGB,
       [Parameter(Position=1,ParameterSetName='Plotly')][switch]$iDOS,
       [Parameter(Position=1,ParameterSetName='MPL')][switch]$sColor,
       [Parameter(Position=1,ParameterSetName='MPL')][switch]$sRGB,
       # FigArgs from Get-FigArgs
       [Parameter()][hashtable]$FigArgs,
       [Parameter()]$SkipNKPTS = "None",
       [Parameter()][array]$EnergyRange,
       # Code lines separated by `n and with namespaces ax and plt
       [Parameter()][string]$AfterPlotCode="",
       # Save HTML
       [Parameter(ParameterSetName='Plotly')]$SaveHTML,
       # Save HTML-Connected
       [Parameter(ParameterSetName='Plotly')]$SaveMinHTML, 
       # Save PDF
       [Parameter(ParameterSetName='MPL')]$SavePDF,
       # Save PNG
       [Parameter(ParameterSetName='MPL')]$SavePNG,
       # Save Python File
       [Parameter()]$SavePyFile

    )
    Process {
    $VasprunFile = Convert-Path $VasprunFile #Make full
    $parentDir = Split-Path -Path $VasprunFile

    if($PSBoundParameters.ContainsKey('FigArgs')){
        $kwargs = $FigArgs.GetEnumerator()|ForEach-Object{"{0} = {1}" -f $_.key,$_.Value}
        $kwargs = "dict(`n" + "{0}" -f $($kwargs -join ",`n") + "`n)"
    }else{$kwargs='dict()'}

    # Process
    $command = 'sbands' # Default Command if No switch given.
    if($sBands.IsPresent){$command = 'sbands'}
    if($sDOS.IsPresent){$command   = 'sdos'}
    if($iRGB.IsPresent){$command   = 'irgb'}
    if($iDOS.IsPresent){$command   = 'idos'}
    if($sColor.IsPresent){$command = 'scolor'}
    if($sRGB.IsPresent){$command   = 'srgb'}
    # Parameters Usage
    $save_htm = Join-Path -Path $parentDir -ChildPath $SaveHTML
    $save_pdf = Join-Path -Path $parentDir -ChildPath $SavePDF 
    $save_png = Join-Path -Path $parentDir -ChildPath $SavePNG
    if($PSBoundParameters.ContainsKey('SaveHTML')){$save= "fig.write_html(r'{0}')" -f $save_htm}
    if($PSBoundParameters.ContainsKey('SaveMinHTML')){$save= "pp.plotly2html(fig, filename=r'{0}')" -f $save_htm}
    if($PSBoundParameters.ContainsKey('SavePDF')){$save= "pp._savefig(r'{0}',transparent=True)" -f $save_pdf}
    if($PSBoundParameters.ContainsKey('SavePNG')){$save= "pp._savefig(r'{0}',transparent=True,dpi =600)" -f $save_png}
    if($PSCmdlet.ParameterSetName -eq 'MPL'){$show = 'pp._show()'}Else{$show = 'fig.show()'} # Keep above save_options to work.
    $save_options = @('SaveHTML','SaveMinHTML','SavePDF','SavePNG')
    $save_options | ForEach-Object {if($PSBoundParameters.ContainsKey($_)){$show = '#' + $show}}

    if($PSBoundParameters.ContainsKey('EnergyRange')){
                $elim = "elim = [float(i) for i in {0}]" -f (ConvertTo-Json $EnergyRange -Compress)
            }Else{$elim="elim = []"}
    
    $load = "pp.Vasprun(path = r'{0}',skipk={1},{2})" -f $VasprunFile, $SkipNKPTS, $elim

    $init = "import pivotpy as pp, matplotlib.pyplot as plt`nvr = {0}`nax = vr.{1}(**kwargs)`nfig=ax #for plotly" -f $load, $command
    $init = "{0}`n{1}`n{2}`n{3}" -f $init, $AfterPlotCode,$save, $show
    $init = "kwargs = {0}`n{1}" -f $kwargs,$init
    if($PSBoundParameters.ContainsKey('SavePyFile')){$init | Set-Content $SavePyFile}
    Write-Host "Running Following Code`n--------------------------`n" $init "`n" -ForegroundColor Cyan
    # Run it finally Using Default python on System preferably.
    if($null -ne (Get-Command python3* -ErrorAction SilentlyContinue)){
        Write-Host ("Running using {0}" -f (python3 -V)) -ForegroundColor Green
        $init | python3
    }elseif($null -ne (Get-Command python -ErrorAction SilentlyContinue)){
        Write-Host ("Running using {0}" -f (python -V)) -ForegroundColor Green
        $init | python
    }elseif($null -ne (Get-Command pytnon2* -ErrorAction SilentlyContinue)){
        Write-Host ("Required Python >= 3.6, but {0} found, try upgrading Python." -f (python2 -V)) -ForegroundColor Red
    }else{
        Write-Host "Python Installation not found. Copy code below and run yourself or use '-SavePyFile'." -ForegroundColor Red
        Write-Host $init -ForegroundColor Yellow
    }
    }
}
Export-ModuleMember -Function 'Get-FigArgs'
Export-ModuleMember -Function 'New-Figure'

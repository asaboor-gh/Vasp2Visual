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
        [hashtable]$out=[ordered]@{command='quick_bplot'; skipk='None'; joinPathAt='[]'; elim='[]'; xt_indices='[]'; xt_labels='[]'; E_Fermi='None'; figsize='(3.4, 2.6)'; txt='None'; xytxt='[0.05,0.9]'; ctxt='black';}
    }
    if($sDOS.IsPresent){
        [hashtable]$out=[ordered]@{command='quick_dos_lines';elim="[]"; include_dos='both'; elements="[[0]]"; orbs="[[0]]"; orblabels="['s']"; 
        colors="['red']"; tdos_color="(0.8, 0.95, 0.8)"; linewidth=0.5; fill_area='True'; vertical='False'; E_Fermi='None'; figsize='(3.4, 2.6)';
        txt='None'; xytxt="[0.05, 0.85]"; ctxt='black'; spin='both'; interpolate='False'; n=5; k=3; showlegend='True'; 
        legend_kwargs="{'ncol': 4, 'anchor': (0, 1), 'handletextpad': 0.5, 'handlelength': 1, 'fontsize': 'small', 'frameon': True}"}
    }
    if($iRGB.IsPresent){

    }
    if($iDOS.IsPresent){

    }
    if($sColor.IsPresent){

    }
    if($sRGB.IsPresent){

    }
    $out
}

function New-Figure {
    param (
       # Input Vasprun.xml
       [Parameter()]$VasprunFile = './vasprun.xml',
       # Switches for Plots
       [Parameter(Position=1,ParameterSetName='MPL')][switch]$sBands,
       [Parameter(Position=1,ParameterSetName='MPL')][switch]$sDOS,
       [Parameter(Position=1,ParameterSetName='Plotly')][switch]$iRGB,
       [Parameter(Position=1,ParameterSetName='Plotly')][switch]$iDOS,
       [Parameter(Position=1,ParameterSetName='MPL')][switch]$sColor,
       [Parameter(Position=1,ParameterSetName='MPL')][switch]$sRGB,
       # FigArgs from Get-FigArgs
       [Parameter()][hashtable]$FigArgs,
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
    $VasprunFile = $VasprunFile.replace('\','/').replace('\\','/')
    

    # Process
    if($sBands.IsPresent){$command = 'quick_bplot'}
    if($sDOS.IsPresent){$command = 'quick_dos_lines'}
    if($iRGB.IsPresent){$command = 'plotly_rgb_lines'}
    if($iDOS.IsPresent){$command = 'plotly_dos_lines'}
    if($sColor.IsPresent){$command = 'quick_color_lines'}
    if($sRGB.IsPresent){$command = 'quick_rgb_lines'}
    # Parameters Usage
    if($PSBoundParameters.ContainsKey('SaveHTML')){$save= "fig.write_html('{0}')" -f $SaveHTML}
    if($PSBoundParameters.ContainsKey('SaveMinHTML')){$save= "pp.plotly_to_html(fig, filename='{0}')" -f $SaveHTML}
    if($PSBoundParameters.ContainsKey('SavePDF')){$save= "pp.savefig('{0}',transparent=True)" -f $SavePDF}
    if($PSBoundParameters.ContainsKey('SavePNG')){$save= "pp.savefig('{0}',transparent=True,dpi =600)" -f $SavePNG}
    if($PSCmdlet.ParameterSetName -eq 'MPL'){$show = 'pp.show()'}Else{$show = 'fig.show()'} # Keep above save_options to work.
    $save_options = @('SaveHTML','SaveMinHTML','SavePDF','SavePNG')
    $save_options | ForEach-Object {if($PSBoundParameters.ContainsKey($_)){$show = '#' + $show}}
    
    $init = "import pivotpy as pp`nfig = pp.{0}()`n{1}`n{2}" -f $command,$save,$show

    if($PSBoundParameters.ContainsKey('SavePyFile')){$init | Set-Content $SavePyFile}
    # Run it finally
    $init|python
}
Export-ModuleMember -Function 'Get-FigArgs'
Export-ModuleMember -Function 'New-Figure'

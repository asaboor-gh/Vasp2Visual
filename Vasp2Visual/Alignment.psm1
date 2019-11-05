Function Get-ConvolvedPotential{
[CmdletBinding()]
Param(
[Parameter(Position=0)][switch]$X_Dir,
[Parameter(Position=0)][switch]$Y_Dir,
[Parameter(Position=0)][switch]$Z_Dir,
[Parameter(Position=1)][switch]$V_av,
[Parameter(Position=1)][switch]$V_min,
[Parameter(Position=1)][switch]$V_max,
[Parameter(Mandatory="True",Position=2)][array]$Interval=(1,30)
)
if($X_Dir.IsPresent){[string]$InputFile='xDir_Pot.txt'}
if($Y_Dir.IsPresent){[string]$InputFile='yDir_Pot.txt'}
if($Z_Dir.IsPresent){[string]$InputFile='zDir_Pot.txt'}
if($V_av.IsPresent){$col=1;$ylabel='V<sub>av</sub>'}
if($V_min.IsPresent){$col=2;$ylabel='V<sub>min</sub>'}
if($V_max.IsPresent){$col=3;$ylabel='V<sub>max</sub>'}
$sys=(Get-Content $InputFile)[0].Split('_')[0].Trim('#')
$Interval=@($Interval)
if($($Interval[1]-$Interval[0]) -gt 1){$shift='div'}Else{$shift=0}
$fileString=@"
import numpy as np
import plotly.graph_objects as go
filename='$($InputFile)'
data=np.loadtxt(filename)
data2=data[:,$($col)]
fig = go.Figure()
fig.add_trace(go.Scatter(x=data[:,0],y=data[:,$($col)],mode='lines',name='$($ylabel)'))
for div in range($($Interval[0]),$($Interval[1])):
    array=$($shift)+data2[:]
    y=np.convolve(array, np.ones((div,))/div, mode='valid')
    x=np.max(data[:,0])*np.linspace(0,1,np.shape(y)[0])
    fig.add_trace(go.Scatter(x=x,y=y,hovertext=np.where(y)[0],mode='lines',name='V<sub>con</sub> '+str(div)))
    
title=(r"Band Alignment in [%s]"%('$($sys)'))
fig.update_layout(title=title,autosize=False, width=400,height=320,
            margin=go.layout.Margin(l=60,r=50,b=40,t=75,pad=0),paper_bgcolor="whitesmoke",
            yaxis=go.layout.YAxis(title_text='$($ylabel)'),
            xaxis=go.layout.XAxis(title_text=filename.split('Dir')[0]+'('+u'\u212B'+')'),font=dict(family="stix, serif",size=14))
fig.update_xaxes(showgrid=True, zeroline=False,showline=True, linewidth=0.1, linecolor='gray', mirror=True)
fig.update_yaxes(showgrid=False, zeroline=True,showline=True, linewidth=0.1, linecolor='gray', mirror=True)
fig.write_html(filename.split('.')[0]+".html")
"@
$fileString|Set-Content .\ConvolvedPlotly.py
python .\ConvolvedPlotly.py
& .\"$($InputFile.Split('.')[0]).html"
}
Export-ModuleMember -Function "Get-ConvolvedPotential"
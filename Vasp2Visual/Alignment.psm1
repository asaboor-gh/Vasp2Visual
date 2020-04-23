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
$Interval=@($Interval)
if($($Interval[1]-$Interval[0]) -gt 1){$shift='div'}Else{$shift=0}
if(-not $(Test-Path $InputFile)){
    Write-Host "$InputFile not found. It may take a while generating it ..." -ForegroundColor Green;
    Export-LOCPOT;}
    if($(Test-Path $InputFile)){ #checks if file generated.
    Write-Host "$InputFile exists. Plotting convolved potential ..." -ForegroundColor Yellow;
    $sys=(Get-Content $InputFile)[0].Split('_')[0].Trim('#')
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
    h_text=['Position << '+str(np.round(fraction,3)) for fraction in np.linspace(0,1,np.shape(y)[0])] #fraction will appaer in text
    fig.add_trace(go.Scatter(x=x,y=y,hovertext=h_text,mode='lines',name='V<sub>con</sub> '+str(div)))
    
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
} #This block executed only if file found.
}

Function Get-AlignedPotential{
[CmdletBinding()]
Param(
[Parameter(Position=0)][switch]$X_Dir,
[Parameter(Position=0)][switch]$Y_Dir,
[Parameter(Position=0)][switch]$Z_Dir,
[Parameter(Position=1)][switch]$V_av,
[Parameter(Position=1)][switch]$V_min,
[Parameter(Position=1)][switch]$V_max,
[Parameter(Mandatory="True",Position=2)][array]$LeftRightPositions=(0.25,0.75),
[Parameter(Mandatory="True",Position=3)][int]$Periodicity=28,
[Parameter(Position=4)][array]$LeftRightNames=('GaAs','GaAsBi')
)
if($X_Dir.IsPresent){[string]$InputFile='xDir_Pot.txt'}
if($Y_Dir.IsPresent){[string]$InputFile='yDir_Pot.txt'}
if($Z_Dir.IsPresent){[string]$InputFile='zDir_Pot.txt'}
if($V_av.IsPresent){$col=1;$ylabel='$V_{av}$(eV)'}
if($V_min.IsPresent){$col=2;$ylabel='$V_{min}$(eV)'}
if($V_max.IsPresent){$col=3;$ylabel='$V_{max}$(eV)'}
$LeftRightPositions=@($LeftRightPositions)
$LeftRightNames=@($LeftRightNames)
if(-not $(Test-Path $InputFile)){
Write-Host "$InputFile not found. It may take a while generating it ..." -ForegroundColor Green;
Export-LOCPOT;}
if($(Test-Path $InputFile)){ #checks if file generated.
Write-Host "$InputFile exists. Plotting aligned potential ..." -ForegroundColor Yellow;
$fileString=@"
import numpy as np
import matplotlib.pyplot as plt 
import matplotlib as mpl
mpl.rcParams['axes.linewidth'] = 0.4 #set the value globally
mpl.rcParams['font.serif'] = "STIXGeneral"
mpl.rcParams['font.family'] = "serif"
mpl.rcParams['mathtext.fontset'] = "stix"
data=np.loadtxt('$($InputFile)')
plt.figure(figsize=(3.8,2.5))
data2=data[:,$($col)]
x_data=data[-1,0]*np.linspace(0,1,np.shape(data2)[0])
plt.plot(x_data,data2[:],lw=0.7)
left=np.max(data[:,0])*$($LeftRightPositions[0]);right=np.max(data[:,0])*$($LeftRightPositions[1]);
div=$($Periodicity) #periodicity of original potential
new_half_div=int((np.shape(data2)[0]-div+1)/(np.shape(data2)[0]/div)/2) #periodicity of convolved potential
arr_con=np.convolve(data2[:], np.ones((div,))/div, mode='valid')
x_con=np.max(data[:,0])*np.linspace(0,1,np.shape(arr_con)[0])
x1=np.where(x_con <= left);x2=np.where(x_con >= right);
index_1=np.max(x1[:]);index_2=np.min(x2[:]);
v1=np.mean(arr_con[index_1-new_half_div:index_1+new_half_div+1])
v2=np.mean(arr_con[index_2-new_half_div:index_2+new_half_div+1])
print(v2-v1)
plt.plot(x_con,arr_con,linestyle='dashed',lw=0.7,color=((0.9,0,0)))
middle=int((index_1+index_2)/2)
plt.plot([x_con[index_1],x_con[middle],x_con[middle], x_con[index_2]],[v1,v1,v2,v2],'m',lw=0.4)
plt.plot([x_con[index_1-new_half_div],x_con[index_1+new_half_div]],[v1,v1],'m')
plt.plot([x_con[index_2-new_half_div],x_con[index_2+new_half_div]],[v2,v2],'m')
plt.annotate(r'$\Delta V = %9.6f$'%(np.round(v2-v1,6)),ha="center", va="center", 
                            bbox=dict(edgecolor='white',facecolor='white', alpha=0.7),
                            xy=(x_con[middle],(v2+v1)/2), xycoords="data",xytext=(0.3, 0.1), 
                            textcoords="axes fraction",arrowprops=dict(arrowstyle="simple,tail_width=0.05,head_width=0.2",
                            fc=(0.2, 0.2, 0.2), ec="none",connectionstyle="arc3,rad=0.5"))
plt.tick_params(direction='in', top=True,bottom=True,left=True,right=True,length=4, width=0.3, colors='k', grid_color='k', grid_alpha=0.8)
plt.title('$($LeftRightNames[0]) --- $($LeftRightNames[1])')
xlabel= `'$([string]$InputFile.Split('Dir')[0]) `'+'('+u'\u212B'+')'
plt.xlabel(xlabel); plt.ylabel(r'$($ylabel)'); plt.xlim([data[0,0],data[-1,0]])
plt.subplots_adjust(left=0.17,bottom=0.16)
filename=`'$([string]$InputFile.Trim('Dir')[0])`'+'Pot.pdf'
plt.savefig(filename,transparent=True)
"@
$fileString|Set-Content .\Pot_av.py
python .\Pot_av.py
& .\"$($InputFile.Split('Dir')[0])Pot.pdf"
} #This block executed only if file found.
}
Export-ModuleMember -Function "Get-ConvolvedPotential"
Export-ModuleMember -Function "Get-AlignedPotential"
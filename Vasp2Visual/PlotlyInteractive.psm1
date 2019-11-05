Function Get-PlotlyHashTable{ #Creates an ordered hashtable to use in plot arguments
[ordered]@{tickIndices="[0,30,60,90,-1]"; ticklabels="[u'\u0393','M','K',u'\u0393','A'] ";
E_Limit="[5,-5]"; ProLabels="['Ga','s','p','d']"; ProIndices="[(range(0,1,1)),(0,),(1,2,3,),(4,5,6,7,8,)]";}
}
#Plot file content.
$FileInput=@"
#====No Edit Below Except Last Few Lines of Legend and File Paths in np.loadtxt('Path/To/File')=====
#====================Loading Packages==============================
import numpy as np
import copy
import plotly.graph_objects as go
#====================Loading Files===================================
data=np.loadtxt('./Projection.txt')
KE=np.loadtxt('./Bands.txt')
K=KE[:,3]; E=KE[:,4:]-E_Fermi; #Seperate KPOINTS and Eigenvalues in memory
yh=max(E_Limit);yl=min(E_Limit);  
#============Calculation of ION(s)-Contribution=======
holder=np.zeros((NKPTS,NBANDS*nField_Projection))
for i in ProIndices[0]: #Indices for ion to claculate contribution of.
    new_mat=data[i*NKPTS:(i+1)*NKPTS,:]
    tot_pro=np.add(new_mat,holder)
    holder=new_mat
#=========Seperating Orbital Projection for Bands ==========
get_pro=np.zeros((NKPTS,nField_Projection)); #Defined matrix to pick Bands
def get_rgbProjection(NKPTS_by_nField_Matrix):
    mat_copy=copy.deepcopy(NKPTS_by_nField_Matrix) #copy matrix
    projection=np.zeros((np.shape(E))) #making a matrix to collect projections of one type
    for i in range(0,NBANDS*nField_Projection,nField_Projection):
        projection[:,int(i/nField_Projection)]=(tot_pro[:,i:i+nField_Projection]*mat_copy).sum(axis=1)         
    return projection          
#==================================================================
#Get (R,G.B) values from projection and Normlalize in plot range
maxEnergy=np.min(E,axis=0); minEnergy=np.max(E,axis=0); #Gets bands in visible energy limits.
max_E=np.max(np.where(maxEnergy <=yh)); min_E=np.min(np.where(minEnergy >=yl))
for i in ProIndices[1]: #projection in red color
    get_pro[:,i]=1;
    red=get_rgbProjection(get_pro)
    get_pro[:,:]=0; #Return back to zero
for j in ProIndices[2]: #projection in green color
    get_pro[:,j]=1;
    green=get_rgbProjection(get_pro)
    get_pro[:,:]=0; #Return back to zero
for k in ProIndices[3]: #projection in blue color
    get_pro[:,k]=1;
    blue=get_rgbProjection(get_pro)
    get_pro[:,:]=0; #Return back to zero
max_con=max(max(map(max,red[:,min_E:max_E])),max(map(max,green[:,min_E:max_E])),max(map(max,blue[:,min_E:max_E])))
red=red[:,min_E:max_E+1]/max_con;green=green[:,min_E:max_E+1]/max_con;blue=blue[:,min_E:max_E+1]/max_con #Values are ready in E_Limit
E=E[:,min_E:max_E+1]; #Updated energy in E_limit 
#===============Make Collections======================
text_plotly=[[str(ProLabels[1:])+'<<'+'RGB'+str((int(100*red[i,j]),int(100*green[i,j]),int(100*blue[i,j]))) for i in range(NKPTS)] for j in range (np.shape(E)[1])];
rgb_plotly=[['rgb'+str((int(255*red[i,j]),int(255*green[i,j]),int(255*blue[i,j]))) for i in range(NKPTS)] for j in range (np.shape(E)[1])];
lw_plotly=[[np.round(1+50*(red[i,j]+green[i,j]+blue[i,j])/3,4) for i in range(NKPTS)] for j in range (np.shape(E)[1])]; # 1 as residual width
tick_plotly=[K[tickIndices[i]] for i in range(len(tickIndices))]; tlab_plotly=ticklabels;
#=================Plotting============================
fig = go.Figure()
for i in range(np.shape(E)[1]):
    fig.add_trace(go.Scatter(x=K,y=E[:,i],mode='lines', line=dict(color='rgb(20,24,222)',width=2),name='Band '+str(i+1)))
for i in range(np.shape(E)[1]):
    fig.add_trace(go.Scatter(x=K,y=E[:,i],mode='markers+lines', visible=False,hovertext=text_plotly[:][i],
                marker=dict(size=lw_plotly[:][i], color=rgb_plotly[:][i]) ,
                line=dict(color='rgba(100,100,20,0)',width=0.1),name='Band '+str(i+1)))
#====Title Name======
if(ProIndices[0][-1]< ElemIndex[-1]):
    title=SYSTEM+'['+ProLabels[0]+': '+str(ProIndices[0][0]+1)+'-'+str(ProIndices[0][-1]+1)+']'
if(ProIndices[0][-1]== 0):
    title=SYSTEM+'['+ProLabels[0]+': '+str(ProIndices[0][0]+1)+']'
if(np.shape(ProIndices[0])[0]==1):
    title=SYSTEM+'['+ProLabels[0]+': '+str(ProIndices[0][0]+1)+']'
if(ProIndices[0][-1]+1== ElemIndex[-1]):
    title=SYSTEM+'[All Sites]'
fig.update_layout(title=title,autosize=False, width=400,height=320,
            margin=go.layout.Margin(l=60,r=50,b=40,t=90,pad=0),paper_bgcolor="whitesmoke",
            yaxis=go.layout.YAxis(title_text='E-E<sub>F</sub>',range=[yl,yh]), 
            xaxis=go.layout.XAxis(ticktext=ticklabels, tickvals=tick_plotly,
            tickmode="array",range=[K[0],K[-1]]),font=dict(family="stix, serif",size=14))
#========Update Buttons==============
simple,projected=[],[];
for j in range(2*np.shape(E)[1]):
    if(j>=np.shape(E)[1]):
        simple.append(False)
        projected.append(True)
    if(j<np.shape(E)[1]):
        simple.append(True)
        projected.append(False)

fig.update_layout(updatemenus=[go.layout.Updatemenu(
            type="buttons",direction="right", active=0,x=1,y=1.2,
            buttons=list([
                dict(label="Simple", method="update", args=[{"visible": simple}]),
                dict(label="Projected", method="update", args=[{"visible": projected}])
            ]),) ])
fig.update_xaxes(showgrid=True, zeroline=False,showline=True, linewidth=0.1, linecolor='gray', mirror=True)
fig.update_yaxes(showgrid=False, zeroline=True,showline=True, linewidth=0.1, linecolor='gray', mirror=True)
fig.write_html("Interactive.html")
"@
Function Get-InteractivePlot{ #Plots of different types
[CmdletBinding()]
Param([hashtable]$PlotlyHashTable)  #Get Hashtable from function Get-PlotArguments
#making a plot file in order
$variablesList=@();
$(Foreach($key in $PlotlyHashTable.Keys){
$xxx="$($key) =$($PlotlyHashTable.$key);" 
$variablesList+=$xxx}); $variablesList=$($variablesList|Sort-Object) -join "`n"
$consoleInput=@"
$variablesList
"@
if(-not $(Test-Path ./Bands.txt)){
    Write-Host "Generating Files ..." -ForegroundColor Green
    Export-VaspRun
}
$pythonFileContent=@"
#=================Input Variables=====================
$($consoleInput)
$(Get-Content .\SysInfo.txt)
$($FileInput)
"@
$pythonFileContent|Set-Content .\Interactive.py
python .\Interactive.py #strat plotting
Invoke-Expression .\Interactive.html
}

Export-ModuleMember -Function "Get-PlotlyHashTable"
Export-ModuleMember -Function "Get-InteractivePlot"
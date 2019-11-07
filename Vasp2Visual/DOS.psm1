﻿Function Get-DensityHashTable{ #Creates an ordered hashtable to use in plot arguments
[ordered]@{textLocation ="[0.05,0.9]"; DOS_Limit ="[0.0,0.6]"; FigureHeight =2.5;
E_Limit="[5,-5]"; ProLabels="['Ga','s','p','d']"; ProIndices="[(range(0,1,1)),(0,),(1,2,3,),(4,5,6,7,8,)]";}
}

$startFile=@'
#====No Edit Below Except Last Few Lines of Legend and File Paths in np.loadtxt('Path/To/File')=====
#====================Loading Packages==============================
import numpy as np
import copy
import matplotlib as mpl
import matplotlib.pyplot as plt
from matplotlib import rc
import matplotlib.pyplot as plt
from matplotlib.gridspec import GridSpec
mpl.rcParams['axes.linewidth'] = 0.4 #set the value globally
mpl.rcParams['font.serif'] = "STIXGeneral"
mpl.rcParams['font.family'] = "serif"
mpl.rcParams['mathtext.fontset'] = "stix"
left,bottom,top,leg_col=0.15,0.15,0.85,4
text_x,text_y=textLocation;
if(FigureWidth <=2):
    mpl.rc('font', size=8)
    left,bottom,top,leg_col=0.3,0.2,0.8,2
#====================Loading Files===================================
pdos=np.loadtxt('./pDOS.txt')
data_dos=np.loadtxt('./tDOS.txt')
D=pdos[:,0]-E_Fermi;TDOS=data_dos[:,1]; eGrid_DOS=int(np.shape(TDOS)[0]); #Energy grid mesh
yh=max(E_Limit);yl=min(E_Limit); nField_DOS=int(np.shape(pdos)[1]-1); #Fields in DOS projection
#============Calculation of ION(s)-Contribution=======
holder_dos=np.zeros((eGrid_DOS,nField_DOS))
for i in ProIndices[0]: #Indices for ion to claculate contribution of.
    new_dos=pdos[i*eGrid_DOS:(i+1)*eGrid_DOS,1:]
    tot_dos=np.add(new_dos,holder_dos)
    holder_dos=new_dos
#=========Seperating Orbital Projection for  DOS==========   
get_dos=np.zeros((eGrid_DOS,nField_DOS)) #Defined matrix to pick DOS
def get_rgbDOS(nGrid_by_nField_Matrix): 
    mat_copy=copy.deepcopy(nGrid_by_nField_Matrix)
    dos_orb=(tot_dos*mat_copy).sum(axis=1)
    return dos_orb        
#==================================================================
#Get (R,G.B) values from projection and Normlalize in plot range
max_index=np.max(np.where(D[:eGrid_DOS] <=yh)); min_index=np.min(np.where(D[:eGrid_DOS] >=yl))
for i in ProIndices[1]: #projection in red color
    get_dos[:,i]=1;
    red_dos=get_rgbDOS(get_dos)
    get_dos[:,:]=0 #Return back to zero
for j in ProIndices[2]: #projection in green color
    get_dos[:,j]=1;
    green_dos=get_rgbDOS(get_dos)
    get_dos[:,:]=0 #Return back to zero
for k in ProIndices[3]: #projection in blue color
    get_dos[:,k]=1;
    blue_dos=get_rgbDOS(get_dos)
    get_dos[:,:]=0 #Return back to zero
#=================================================================
red_dos=red_dos[min_index:max_index+1];green_dos=green_dos[min_index:max_index+1]; blue_dos=blue_dos[min_index:max_index+1]; #DOS in E_Limit
Elem_dos=red_dos+blue_dos+green_dos; #ION DOS in E_Limit
D=D[min_index:max_index+1]  #Update partial in E_limit (max_index+1 is to include last band as well,python does not read last point in slices.)
TDOS=TDOS[min_index:max_index+1]; #Updated total DOS
#=================Plotting============================
plt.figure(figsize=(FigureWidth,FigureHeight))
gs = GridSpec(1,1)
ax1 = plt.subplot(gs[0])
def ax_settings(ax, x_coord,y_coord,Element):
        ax.tick_params(direction='in', top=True,bottom=True,left=True,right=True,length=4, width=0.3, colors='k', grid_color='k', grid_alpha=0.8)
        ax.set_ylim([DOS_Limit[0],DOS_Limit[1]])
        ax.set_xlim(yl,yh)
        ax.set_ylabel('Density of States'); 
        ax.set_xlabel(r'$E-E_F$'); 
        ax.text(x_coord,y_coord,r"$\mathrm{%s}^{\mathrm{%s}}$" % (SYSTEM, Element),bbox=dict(edgecolor='white',facecolor='white', alpha=0.6),transform=ax.transAxes,color='red') 
        return None
'@
$stack=@'
#================StackPlots for DOS====================================
ax1.fill_between(D,TDOS,color=(167/300, 216/300, 222/300),facecolor=(1,1,1),linewidth=0,label='Total');
ax1.fill_between(D,blue_dos+green_dos+red_dos,color=(0,0,1),linewidth=0 ,label=ProLabels[3]); 
ax1.fill_between(D,green_dos+red_dos,color=(0,1,0),linewidth=0,label=ProLabels[2]);
ax1.fill_between(D,red_dos,color=(1,0,0),linewidth=0,label=ProLabels[1]);
'@
$area=@'
#================AreaPlots for DOS====================================
ax1.fill_between(D,TDOS,color=(167/300, 216/300, 222/300),linewidth=0,label='Total');
ax1.fill_between(D,red_dos,color=(1,0,0,0.4),linewidth=0,label=ProLabels[1]); ax1.plot(D,red_dos, 'r',linewidth=0.3)
ax1.fill_between(D,green_dos,color=(0,1,0,0.4),linewidth=0,label=ProLabels[2]); ax1.plot(D,green_dos, 'g',linewidth=0.3)
ax1.fill_between(D,blue_dos,color=(0,0,1,0.4),linewidth=0 ,label=ProLabels[3]); ax1.plot(D,blue_dos, 'b',linewidth=0.3)
'@
$line=@'
#================LinePlots for DOS====================================
ax1.plot(D,TDOS,'k',linewidth=0.5,linestyle='dashed',label='Total');
ax1.plot(D,red_dos, 'r',linewidth=0.6,label=ProLabels[1])
ax1.plot(D,green_dos, 'g',linewidth=0.6,label=ProLabels[2])
ax1.plot(D,blue_dos, 'b',linewidth=0.6,label=ProLabels[3])
'@
$endFile=@'
#==========Adjust Settings========================================
ax_settings(ax1,textLocation[0],textLocation[1],ProLabels[0])
gs.update(left=left,bottom=bottom,top=top,wspace=0.0, hspace=0.0) # set the spacing between axes.
leg=ax1.legend(fontsize='small',frameon=False,handletextpad=0.5,handlelength=1.5,columnspacing=1,ncol=leg_col, bbox_to_anchor=(0, 1), loc='lower left');
#===================Name it & Save===============================
ProLabels=[prolabel.replace("$","").replace("_","").replace("^","") for prolabel in ProLabels]; #Remove $ and _ characters in path
atom_index_range=','.join(str(ProIndices[0][i]+1) for i in range(np.shape(ProIndices[0])[0])); #creates a list of projected atoms
if(ProLabels[0]=='' or ProLabels[0]==' '): #check if this projection of whole composite.
    atom_index_range='All'
name=str('Ions'+'_'+ProLabels[0]+'['+atom_index_range+']'+'('+str(ProLabels[1])+')('+str(ProLabels[2])+')('+str(ProLabels[3])+')'+'_D'); #A for All,B for Bnads, D for DOS.
plt.savefig(str(name+'.pdf'),transparent=True)
'@

Function Get-DensityPlot{ #Plots of different types
[CmdletBinding()]
Param([Parameter()][switch]$HalfColumnWide,
[Parameter()][switch]$AreaPlot, 
[Parameter()][switch]$LinePlot, #[Parameter()][switch]$ProjectedDOS,
[Parameter()][switch]$StackPlot,#[Parameter()][switch]$DOS, 
[hashtable]$PlotArguments)  #Get Hashtable from function Get-PlotArguments
if(-not (Test-Path .\tDOS.txt)){Write-Host "Required files not found. Generating using 'Export-VaspRun' ..." -ForegroundColor Green;
    Export-VaspRun;}
    if($(Test-Path .\tDOS.txt)){ #checks if file generated.
    Write-Host "Files now exist. Plotting ..." -ForegroundColor Yellow;
#making a plot file in order
$variablesList=@();
$(Foreach($key in $PlotArguments.Keys){
$xxx="$($key) =$($PlotArguments.$key);" 
$variablesList+=$xxx}); $variablesList=$($variablesList|Sort-Object) -join "`n"
$consoleInput=@"
$variablesList
"@
if($HalfColumnWide.IsPresent){$Width=1.7}Else{$Width=3.4}
$PlotInput=$line # Default plot if no selection made.
if($AreaPlot.IsPresent){$PlotInput=$area}
if($LinePlot.IsPresent){$PlotInput=$line}
if($StackPlot.IsPresent){$PlotInput=$stack}
$head=(Get-Content .\tDOS.txt)[0].Split('#')
$pythonFileContent=@"
#=================Input Variables=====================
$($consoleInput)
FigureWidth=$($Width); SYSTEM='$($head[-3])'; $($head[-1]);
$($startFile)
$($PlotInput)
$($endFile)
"@
$pythonFileContent|Set-Content .\DOS.py
python .\DOS.py #strat plotting
} #if block ends
}

Export-ModuleMember -Function "Get-DensityHashTable"
Export-ModuleMember -Function "Get-DensityPlot"
#=================Input Variables=====================
DOS_Limit =[0.0,1.2];
E_Limit =[5,-8];
ProIndices =[(range(0,5,1)),(0,),(1,2,3,),(4,5,6,7,8,)];
ProLabels =['','s','p','d'] ;
textLocation =[0.05,0.2];
tickIndices =[0,30,60,90,-1];
ticklabels =[r'$\Gamma$','M','K',r'$\Gamma$','A'] ;
WidthToColumnRatio=0.5;
#=================System Variables====================

#====No Edit Below Except Last Few Lines of Legend and File Paths in np.loadtxt('Path/To/File')=====
#====================Loading Packages==============================
import numpy as np
import copy
import matplotlib as mpl
import matplotlib.pyplot as plt
from matplotlib.collections import LineCollection
from matplotlib import colors as mcolors
from matplotlib import rc
import matplotlib.pyplot as plt
from matplotlib.gridspec import GridSpec
from matplotlib import collections  as mc
mpl.rcParams['axes.linewidth'] = 0.4 #set the value globally
mpl.rcParams['font.serif'] = "STIXGeneral"
mpl.rcParams['font.family'] = "serif"
mpl.rcParams['mathtext.fontset'] = "stix"
left,bottom,top,leg_x=0.15,0.15,0.85,0
text_x,text_y=textLocation;
if(WidthToColumnRatio <=0.7):
    mpl.rc('font', size=8)
    left,bottom,top,leg_x=0.3,0.2,0.8,-0.15
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
#=================================================================
#=========Seperating Orbital Projection for Bands and DOS==========
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
E_List=[[[(K[i],E[i,j]),(K[i+1],E[i+1,j])]for i in range(NKPTS-1)]for j in range(np.shape(E)[1])];
rgb_List=[[(red[i:(i+2),j].sum()/2,green[i:(i+2),j].sum()/2,blue[i:(i+2),j].sum()/2,1) for i in range(NKPTS-1)] for j in range (np.shape(E)[1])];
lw_List=[[0.3+8*(red[i,j]+red[i+1,j]+green[i,j]+green[i+1,j]+blue[i,j]+blue[i+1,j])/6 \
 for i in range(NKPTS-1)] for j in range (np.shape(E)[1])]; # 0.3 as residual width
#=================Plotting============================
wd=WidthToColumnRatio; #sets width w.r.t atricle's column width
plt.figure(figsize=(wd*3.4,wd*10))
gs = GridSpec(1,1)
ax1 = plt.subplot(gs[0])
def ax_settings(ax, x_ticks, x_labels, x_coord,y_coord,Element):
        ax.tick_params(direction='in', top=True,bottom=True,left=True,right=True,length=4, width=0.3, colors='k', grid_color='k', grid_alpha=0.8)
        ax.set_xticks(x_ticks)
        ax.set_xticklabels(x_labels)
        ax.set_xlim(K[0],K[-1])
        ax.set_ylim(yl,yh)
        ax.text(x_coord,y_coord,r"$\mathrm{%s}^{\mathrm{%s}}$" % (SYSTEM, Element),bbox=dict(edgecolor='white',facecolor='white', alpha=0.7),transform=ax.transAxes,color='red') 
        return None
#Lines at KPOINTS
kpts1=[[(K[ii],yl),(K[ii],yh)] for ii in tickIndices[1:-1]];
k_segments= LineCollection(kpts1,colors='k', linestyle='dashed',linewidths=(0.3),alpha=(0.6))
ax1.add_collection(k_segments)
ax1.plot([K[0],K[-1]],[0,0],'k',linewidth=0.3,linestyle='dashed',alpha=0.6) #Horizontal Line
#Full Data Plot
for i in range(np.shape(E)[1]):
    line_segments = LineCollection(E_List[i],colors=rgb_List[i], linestyle='solid',linewidths=lw_List[i])
    ax1.add_collection(line_segments)
ax1.autoscale_view()
ax1.set_ylabel(r'$E-E_F$(eV)')
ticks=[K[ii] for ii in tickIndices];
ax_settings(ax1,ticks,ticklabels,text_x,text_y,ProLabels[0])
#=============Dummy Plots for Legend====================================
ax1.plot([],[],color=((1,0,0)),linewidth=2,label=ProLabels[1]);
ax1.plot([],[],color=((0,1,0)),linewidth=2,label=ProLabels[2]);
ax1.plot([],[],color=((0,0,1)),linewidth=2,label=ProLabels[3]);
gs.update(left=left,bottom=bottom,top=top,wspace=0.0, hspace=0.0) # set the spacing between axes.
leg=ax1.legend(fontsize='small',frameon=False,handletextpad=0.5,handlelength=1.5,columnspacing=1,ncol=5, bbox_to_anchor=(leg_x, 1), loc='lower left');
#===================Name it & Save===============================
ProLabels=[prolabel.replace("$","").replace("_","").replace("^","") for prolabel in ProLabels]; #Remove $ and _ characters in path
SYSTEM=SYSTEM.replace("$","").replace("_","").replace("^","");
atom_index_range=','.join(str(ProIndices[0][i]+1) for i in range(np.shape(ProIndices[0])[0])); #creates a list of projected atoms
if(ProLabels[0]=='' or ProLabels[0]==' '): #check if this projection of whole composite.
    atom_index_range='All'
name=str('Ions'+'_'+ProLabels[0]+'['+atom_index_range+']'+'('+str(ProLabels[1])+')('+str(ProLabels[2])+')('+str(ProLabels[3])+')'+'_B'); #A for All,B for Bnads, D for DOS.
#plt.savefig(str(name+'.png'),transparent=True,dpi=300)
plt.savefig(str(name+'.pdf'),transparent=True)
plt.show(block=False)

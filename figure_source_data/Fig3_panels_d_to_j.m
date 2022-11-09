load fig3_panels_d_to_h_data;
cmap=[lines(7);fliplr(lines(7))];

%Fig 3 - panel d -top
F0=figure('Units','centimeters','position',[5,5,10,3]);
ax1=axes;
plot(tVVLong/1000,squeeze(MVVLong),'k');hold on;
[hSBVLong]=addScaleBar(ax1,'XUnitStr','s','scaleFacY',3,'fontColor','k','fontSize',8,'unitsInScaleBar',0,'yShift',0.45,'xShift',-1.05,'equalXTWidths',0);
axis(ax1,'off');
yl=ylim;
hPatch=patch([0 60000 60000 0]/1000,[yl(1) yl(1) yl(2) yl(2)],cmap(3,:),'FaceAlpha',0.2,'LineStyle','none');

%Fig 3 - panel d - middle
F1=figure('Units','centimeters','position',[5,5,10,3]);ax1=axes;
plot(tVLong/1000,squeeze(MVLong),'k');
[hSBVLong]=addScaleBar(ax1,'XUnitStr','s','scaleFacY',3,'fontColor','k','fontSize',8,'unitsInScaleBar',0,'yShift',0.45,'xShift',-1.05,'equalXTWidths',0);
axis(ax1,'off');
yl=ylim;
hPatchSWS=patch([tSWS tSWS+win tSWS+win tSWS]/1000,[yl(1) yl(1) yl(2) yl(2)],cmap(1,:),'FaceAlpha',0.2,'LineStyle','none');
hPatchREM=patch([tREM tREM+win tREM+win tREM]/1000,[yl(1) yl(1) yl(2) yl(2)],cmap(2,:),'FaceAlpha',0.2,'LineStyle','none');

%Fig 3 - panel d - bottom - left
F2=figure('Units','centimeters','position',[5,5,4,3]);ax2=axes;
plot(tVLong(pSWS)/1000,squeeze(MVLong(pSWS)),'k');
axis(ax2,'off');
[hSBVLong]=addScaleBar(ax2,'XUnitStr','s','scaleFacY',3,'fontColor','k','fontSize',8,'unitsInScaleBar',0,'yShift',-0.1,'xShift',-1.05,'equalXTWidths',0);

%Fig 3 - panel d - bottom - right
F3=figure('Units','centimeters','position',[5,5,4,3]);ax3=axes;
plot(tVLong(pREM)/1000,squeeze(MVLong(pREM)),'k');
axis(ax3,'off');
[hSBVLong]=addScaleBar(ax3,'XUnitStr','s','scaleFacY',3,'fontColor','k','fontSize',8,'unitsInScaleBar',0,'yShift',-0.1,'xShift',-1.05,'equalXTWidths',0);

%Fig 3 - panel e
[DC,order,clusters,h,Z]=DendrogramMatrix(corrMat,'linkMetric','euclidean','linkMethod','ward','maxClusters',2,...
    'toPlotBinaryTree',1,'cLim',[],'hDendro',[],'plotOrderLabels',0);

%Fig 3 - panel f
fDB=figure('Position',[100 100 900 500]);
h(1)=axes;
imagesc((1:size(chunks,1))*timeBin/1000/60,tLong,chunks',[0 estimateColorMapMax]);
xlabel('Time [min]');ylabel('Time [hour]');
h(2)=colorbar;
set(h(2),'position',[0.9115    0.7040    0.0129    0.2220]);
ylabel(h(2),'\delta/\beta');

%Fig 3 - panel g
fTmp=figure('position',[680   100   658   420]);
hTmp=axes;
for i=1:2
    PS=mean(normsPxx(:,clusters==i),2);
    plot(freqHz,PS,'lineWidth',2);hold on;
end
xlabel('Frequency (Hz)');
ylabel('nPSD');
xlim([0 30]);

%Fig 3 - panel h
F4=figure('Units','centimeters','position',[5,5,4,5]);ax4=axes;hold on;
line([[-300 300];[0 0]]',[[0, 0];[1 -1]]','color','k','linewidth',1);
plot(AC_xcf_lags/1000,AC_xcf,'r','linewidth',1);
xlabel('Lag [s]');ylabel('Autocorr.');
xlim([-300 300]);ylim([-0.6 1]);

%Fig 3 - panel i
F5=figure('Units','centimeters','position',[5,5,3,3]);
ax5=axes;
edges=[0:0.2:2];edgedCenters=(edges(1:end-1)+edges(2:end))/2;
H=histc(peak2Vally,edges);
bar(edgedCenters,H(1:end-1)/sum(H(1:end-1))*100,1,'facecolor',[0.7 0.7 0.7]);
ylim([0 50]);
xlim([-0.1,1.5]);
set(ax5,'XTick',[0,0.5,1])
xlabel('Peak to vally (P2V)');
ylabel('% recordings');

%Fig 3 - panel j
F6=figure('Units','centimeters','position',[5,5,8,3],'Colormap',cmap);
ax6=axes;
hS=scatter(animalNumberRand,period,50,recordingAnimalColor,'filled','MarkerEdgeColor','k','MarkerFaceAlpha',0.7,'MarkerEdgeAlpha',0.7);hold on;
hE=errorbar(pogonaNumber,mean(mPogona),std(mPogona),'sr','MarkerSize',5,'MarkerFaceColor','r');
ylim([00 120]);
set(gca,'XTick',1:pogonaNumber)
text(pogonaNumber,mean(mPogona)+std(mPogona)+6,'Pogona','color','r','rotation',-90);
ax6.XTick(end)=[];



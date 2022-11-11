load fig4_data;

fontName='Myriad Pro';

%Fig 4 - panel a
f=figure;
h(1)=subplot(4,2,1:2);
yyaxis left;
[hYY1]=plot((DB_t_ms-tStart)/1000/60,DB_bufferedDelta2BetaRatio,'k');hold on;
ylabel('\delta/\beta','fontname',fontName) % left y-axis
yyaxis right;

[hYY2]=plot((binA/2:binA:win)/1000/60,M1C,'--');
ylabel('Spk. rate','fontname',fontName)

hL=legend('\delta/\beta','Spk. rate','fontname',fontName);
hL.Position=[0.7363    0.9290    0.1696    0.0679];
hL.Box='off';

%Fig 4 - panel b
h(2)=subplot(4,2,3:4);
imagesc((bin/2:bin:win)/1000/60,1:nNeu,squeeze(M1(:,pPos,:)));
colormap(flipud(gray(8)));
h(2).CLim=[0 10];
xlabel('Time [min]');
ylabel('Neuron');
cb=colorbar;
cl=cb;
cb.Position=[0.9096    0.6019    0.0129    0.1019];
cb.YTick=cb.YTick([1,end]);cb.YTickLabel={'0',num2str(cb.YTick(2)/bin*1000)};
ylabel(cb,'spk/s');

%Fig 4 - panels c-f
xl1=[tStartSWS-tStart,tStartSWS-tStart+winSWSREM]/1000/60;
xl2=[tStartREM-tStart,tStartREM-tStart+winSWSREM]/1000/60;
yl=ylim;
hPat1=patch('XData',[xl1(1) xl1(1) xl1(2) xl1(2)],'YData',[yl(1) yl(2) yl(2) yl(1)],'faceColor','b','FaceAlpha',0.2,'edgeColor','none');
hPat2=patch('XData',[xl2(1) xl2(1) xl2(2) xl2(2)],'YData',[yl(1) yl(2) yl(2) yl(1)],'faceColor','r','FaceAlpha',0.2,'edgeColor','none');

%convert to binary
MSWS(MSWS>0)=1;MREM(MREM>0)=1;
h(3)=subplot(4,2,5);
imagesc((binSWSREM/2:binSWSREM:winSWSREM)/1000,1:nNeu,squeeze(MSWS(:,pPos,:)));
h(4)=subplot(4,2,6);
imagesc((binSWSREM/2:binSWSREM:winSWSREM)/1000,1:nNeu,squeeze(MREM(:,pPos,:)));

h(5)=subplot(4,2,7);
plot(t_ms/1000,MSWS_V,'k');
xlabel('Time [s]');
ylim([-500 500]);
h(6)=subplot(4,2,8);
plot(t_ms/1000,MREM_V,'k');
xlabel('Time [s]');
ylim([-500 500]);

%Fig 4 - panel h
F2=figure('Units','centimeters','position',[10,10,27,7]);
h21=subplot(1,4,1:2);hold on;
h21.Position=[0.178395061728395         0.200505952380952          0.30182098765432          0.61610119047619];
hP=plot(D.binCentersAng,normZeroOne(D.mResampledTemplateDB(pSA7,:)),'color',cmap(1,:));
hP2=plot(D.binCentersAng,normZeroOne(D.mResampledTemplateSpk(pSA7,:)),'color',cmap(2,:));
xlabel(h21,'Phase[rad]');
ylabel(h21,'norm. amp.');
h21.XTick=[0,pi,2*pi];h21.XTickLabel={'0','\pi','2\pi'};
xlim(h21,[0,2*pi]);
l=legend({'norm. \delta/\beta','norm. spk. rate'},'box','off','location','northeastoutside');
l.Position=[0.152489088721851         0.810072488090893          0.17163289300165         0.122641506285038];
box on;

%Fig 4 - panel i
plottingOrder=[find(strcmp(Animals,'SA07'))',find(strcmp(Animals,'SA10'))',find(strcmp(Animals,'SA15'))', find(strcmp(Animals,'SA03'))'];plottingOrder=[plottingOrder setdiff(plottingOrder,1:numel(D.mPhaseDB))];
h22=subplot(1,4,3,polaraxes);hold on;
for i=plottingOrder
    polarplot([D.mPhaseDB(i),D.mPhaseDB(i)],[0 1],'color',cmap(1,:));
    polarscatter(D.mPhaseDB(i),1,[],recordingAnimalColor(i,:),'linewidth',2);
    polarplot([D.mPhaseSpk(i),D.mPhaseSpk(i)],[0 1],'color',cmap(2,:));
    polarscatter(D.mPhaseSpk(i),1,[],recordingAnimalColor(i,:),'linewidth',2);
end
title('Mean phase');
h22.RTickLabel=[];

%Fig 4 - panel j
h23=subplot(1,4,4,polaraxes);hold on;
randPh=randn(1,numel(D.mPhaseDB))*0.1;
for i=numel(D.mPhaseDB):-1:1
    polarplot([D.mPhasePeakDB(i)+randPh(i),D.mPhasePeakDB(i)+randPh(i)],[0 1],'color',cmap(1,:));
    polarscatter(D.mPhasePeakDB(i)+randPh(i),1,[],recordingAnimalColor(i,:),'linewidth',2);
    polarplot([D.mPhasePeakSpk(i)+randPh(i),D.mPhasePeakSpk(i)+randPh(i)],[0 1],'color',cmap(2,:));
    polarscatter(D.mPhasePeakSpk(i)+randPh(i),1,[],recordingAnimalColor(i,:),'linewidth',2);
end
h23.RTickLabel=[];
title('Peak phase');

%Fig 4 - panel g
F3=figure('Units','centimeters','position',[10,10,12,8]);
h31=subplot(1,3,1:2);
semilogy(SA3.centers',SA3.histSWS(1:end-1),'linewidth',2);hold on;plot(SA3.centers,SA3.histREM(1:end-1),'linewidth',2);
l=legend('SWS','REM','box','off');
xlabel('Spk. rate [1/s]');
ylabel('Prob.');
xlim([0 3.2]);

%Fig 4 - panel k
h31=subplot(1,3,3,'box','on');hold on;
[hE,hB]=myErrorBar([1 2],[mean(D.kurtREM) mean(D.kurtSWS)],[std(D.kurtREM)./sqrt(numel(D.kurtREM)) std(D.kurtSWS)./sqrt(numel(D.kurtREM))],[],'Bfacecolor',[0.9 0.9 0.9],'BLinewidth',2,'Ecolor','k');hold on;
for i=1:numel(D.kurtREM)
    line([1 2]',[D.kurtREM(i)',D.kurtSWS(i)']','color',recordingAnimalColor(i,:));
end
ylim([0 27]);
xlim([0.3 2.7]);
set(h31,'XTickLabel',{'REM','SWS'});
ylabel('Kurtosis');

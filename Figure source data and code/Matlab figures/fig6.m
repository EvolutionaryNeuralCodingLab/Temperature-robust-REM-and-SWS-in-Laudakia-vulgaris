load fig6_e_f_p_k;

%Fig 6 - panel e
F1=figure('Units','centimeters','position',[5,5,4,4]);
ax1=axes;
edges=[0:0.2:2];edgedCenters=(edges(1:end-1)+edges(2:end))/2;
H=histc(peak2Vally-2*xcf_bounds,edges);
bar(edgedCenters,H(1:end-1)/sum(H(1:end-1))*100,1,'facecolor',[0.7 0.7 0.7]);
ylim([0 40]);xlim([-0.1,1.4]);
set(ax1,'XTick',[0,0.5,1])
xlabel('Peak to vally');
ylabel('% recordings');
line([0 0],ylim,'color','r');
text(0.1,21.5,'95% Confidence bound','Fontsize',6,'color','r');

%Fig 6 - panel f
timeMultiplier=60;%for minutes rather than seconds
Trange=17:36;
T0=Trange(1);
F0=0.005435*timeMultiplier;
Q0=2;
x0=[Q0, F0];
fun = @(x,T) x(2).*x(1).^((T - T0)/10);
[xf,~,residual] = lsqcurvefit(fun,x0,T,OscilFreq*timeMultiplier);

F2_5=figure('Units','centimeters','position',[5,5,7,10], 'Renderer', 'painters','PaperPositionMode','auto');
ax2_5=axes;
fun = @(x,T) x(2).*x(1).^((T - T0)/10);
hP=plot(Trange,fun(xf,Trange),'k','linewidth',2);hold on;
for i=1:numel(animalNames)
    pAnimal=find(strcmp(Animals,animalNames{i})' & pValid);
    hS(i)=scatter(T(pAnimal),OscilFreq(pAnimal)*timeMultiplier,[],animalColor(i,:),'filled','MarkerEdgeColor','k','MarkerFaceAlpha',0.7,'MarkerEdgeAlpha',0.7);
end
xlabel('Temperature [C]');
ylabel('Oscil. freq. [1/min]');
%hT=text(T,OscilFreq*timeMultiplier,recordings);
hL=legend([['Fit: Q_{10}=' num2str(xf(1))];animalNames'],'location','northwest');
box(hL,'off')
xlim([17 35]);

%Fig 6 - panel p
f=figure('Position',[681   548   320   420]);
xl=[16 36];
[~,pTmp]=sort(xfit);
plot(xfit(pTmp),yfit(pTmp),'r-','linewidth',2);hold on;
plot(xfit(pTmp),yfit(pTmp)-delta,'r--',xfit(pTmp),yfit(pTmp)+delta,'r--');
scatter(x,y,100,recordingAnimalColor(pValid2,:),'filled','markeredgecolor','k','MarkerFaceAlpha',0.7,'MarkerEdgeAlpha',0.7);hold off;
xlabel('Temperature [C]');
ylabel('CV');
xlim(xl);
%text(x,y,recordings(pValid));
l=legend('Data','95% Prediction Intervals','box','off','location','northoutside');

%Fig 6 - panel k
F5=figure('Units','centimeters','position',[5,5,8,8]);
line(xl,xl*dp(1)+dp(2),'color','k','linewidth',2);hold on;
scatter(x1,y1,100,recordingAnimalColor(pValid2,:),'filled','markeredgecolor','k','MarkerFaceAlpha',0.7,'MarkerEdgeAlpha',0.7);hold on;
%text(x,y,recordings(pValid));
xlabel('Temperature [C]');
ylabel('SWS/REM');
xlim(xl);
box on;


%%
load fig6_g_i_h_j;
xl=[16 36];

%figure 6 - panel g
f=figure('Position',[200   200   678   274]);
colormap(f,redblue);
h(1)=subplot(1,2,1);
for j=1:numel(pSA07)
    semilogy(freq , msFreq(:,pSA07(j)),'color',cmap(floor(1+Tnorm(pSA07(j))*nMap),:) );hold on;
end
xlabel('Freq. [Hz]');ylabel('PSD');
ylim([10^0 10^4]);
h(2)=axes('Position',[0.31 0.6 0.14 0.28]);
line(xl,xl*fitLin{ppSA07}.p1+fitLin{ppSA07}.p2,'color',lines(1));hold on;
scatter(T(pSA07),sum(msFreq(:,pSA07),1),9,'k','filled');
xlabel('Temp. [C]');ylabel('Power');

%figure 6 - panel i
h(2)=subplot(1,2,2);
for j=1:numel(pSA07)
    semilogy(freq , mnFreq(:,pSA07(j)),'color',cmap(floor(1+Tnorm(pSA07(j))*nMap),:) );hold on;
end
xlabel('Freq. [Hz]');ylabel('norm. PSD');
xlim([0 6]);
ylim([10^-2.8,10^-0.4]);
COM=sum(bsxfun(@times,msFreq(:,pSA07),freq),1)./sum(msFreq(:,pSA07),1);
h(2)=axes('Position',[0.75 0.6 0.14 0.28]);
line(xl,xl*fitLin2{ppSA07}.p1+fitLin2{ppSA07}.p2,'color',lines(1));hold on;
scatter(T(pSA07),COM,9,'k','filled');
xlabel('Temp. [C]');ylabel('COM [Hz]');
h(2).CLim=minmaxT;
cb=colorbar('Position',[0.9179    0.7117    0.0084    0.2117]);
ylabel(cb,'Temp. [C]');

%figure 6 - panel h
f=figure('Position',[200   200   500   220]);
h(1)=subplot(1,2,1);
plot(xl,xl*fitLinPow.p1+fitLinPow.p2,'k','linewidth',2);hold on;
scatter(T_All,nPow_All,50,recordingAnimalColor(pValid,:),'filled','markeredgecolor','k','MarkerFaceAlpha',0.7,'MarkerEdgeAlpha',0.7);hold off;
text(17,0,['C=' num2str(CPow) ' ,PV=' num2str(CPowPV)]);
xlabel('Temperature [C]');
ylabel('norm Power');
ylim([0 3.6]);
xlim(xl);

%figure 6 - panel j
h(2)=subplot(1,2,2);
plot(xl,xl*fitLinCOM.p1+fitLinCOM.p2,'k','linewidth',2);hold on;
scatter(T_All,COM_All,50,recordingAnimalColor(pValid,:),'filled','markeredgecolor','k','MarkerFaceAlpha',0.7,'MarkerEdgeAlpha',0.7);hold off;
%text(T_All,COM_All,recordings(pValid));
text(17,0,['C=' num2str(CCOM) ' ,PV=' num2str(CCOMPV)]);
xlabel('Temperature [C]');
ylabel('PSD COM [Hz]');
xlim(xl);
ylim([0.9 5.4]);

%%
%Fig 6 - panel a
load fig6_panel_a;
fDB=figure('Position',[100 100 900 500]);
h(1)=axes;
imagesc((1:size(chunks,1))*timeBin/1000/60,tLong,chunks',[0 estimateColorMapMax]);
xlabel('Time [min]');ylabel('Time [hour]');
h(2)=colorbar;
set(h(2),'position',[0.9115    0.7040    0.0129    0.2220]);
ylabel(h(2),'\delta/\beta');

%Fig 6 - panel b
load fig6_panel_b;
fDB=figure('Position',[100 100 900 500]);
h(1)=axes;
imagesc((1:size(chunks,1))*timeBin/1000/60,tLong,chunks',[0 estimateColorMapMax]);
xlabel('Time [min]');ylabel('Time [hour]');
h(2)=colorbar;
set(h(2),'position',[0.9115    0.7040    0.0129    0.2220]);
ylabel(h(2),'\delta/\beta');

%Fig 6 - panel c
load fig6_panel_c;
F4=figure('Units','centimeters','position',[5,5,4,5]);ax4=axes;hold on;
line([[-300 300];[0 0]]',[[0, 0];[1 -1]]','color','k','linewidth',1);
plot(xcf_lags/1000,xcf,'r','linewidth',1);
plot(period/1000,real(xcf(pPeriod)),'o','MarkerSize',5,'color','k');
text(period/1000,0.05+real(xcf(pPeriod)),num2str(period/1000));
xlabel('Lag [s]');ylabel('Autocorr.');
xlim([-300 300]);ylim([-0.6 1]);

%Fig 6 - panel d
load fig6_panel_d;
F4=figure('Units','centimeters','position',[5,5,4,5]);ax4=axes;hold on;
line([[-300 300];[0 0]]',[[0, 0];[1 -1]]','color','k','linewidth',1);
plot(xcf_lags/1000,xcf,'r','linewidth',1);
plot(period/1000,real(xcf(pPeriod)),'o','MarkerSize',5,'color','k');
text(period/1000,0.05+real(xcf(pPeriod)),num2str(period/1000));
xlabel('Lag [s]');ylabel('Autocorr.');
xlim([-300 300]);ylim([-0.6 1]);


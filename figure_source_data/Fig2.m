%save fig2_data binnedTime binnedMov pRec edges avgMov avgMov stdErrMov cmap centers;
load fig2_data;

%Fig 2a
F1=figure('Units','centimeters','position',[10,10,8,10]);
h11=subplot(2,1,1);
plot(binnedTime{pRec},binnedMov{pRec},'linewidth',2);
yl=ylim;
hP1=patch([0 12 12 0],[yl(1) yl(1) yl(2) yl(2)],'k','facealpha',0.1,'lineStyle','none');
xlim([edges(1)+0.5 edges(end)-0.5]);
set(gca,'XTickLabel',[]);
ylabel('Movement [AU]');

%Fig 2b
h12=subplot(2,1,2);
plot(centers,avgMov,'k','linewidth',2);
hP21=patch([centers,fliplr(centers)],[avgMov-stdErrMov,fliplr(avgMov+stdErrMov)],cmap(2,:),'facealpha',0.5,'facecolor',cmap(1,:),'lineStyle','none');
yl=ylim;
hP21=patch([0 12 12 0],[yl(1) yl(1) yl(2) yl(2)],'k','facealpha',0.1,'lineStyle','none');
xlim([edges(1)+0.5 edges(end)-0.5]);
ylabel('Movement [AU]');
xlabel('Time [h]');
ylim([0 4e7]);
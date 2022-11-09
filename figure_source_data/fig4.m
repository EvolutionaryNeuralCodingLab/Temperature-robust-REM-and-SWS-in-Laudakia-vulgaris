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
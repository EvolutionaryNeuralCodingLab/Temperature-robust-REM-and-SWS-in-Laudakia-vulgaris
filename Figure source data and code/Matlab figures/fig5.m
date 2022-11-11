load fig_5_panel_a_b_data;
cmap=[lines(7);fliplr(lines(7))];

%Fig 5 - panel a
figure;
histColor=[0.9 0.078 0.184];
hOut.hRose=polarhistogram(phaseMov*2*pi-mPhaseDB,18);
hOut.hRose.FaceColor=histColor;
hOut.hRose.FaceAlpha=0.9;
hOut.hAxes=gca;
hOut.hAxes.ThetaTick=[0:90:330];
hold on;

hOut.hRoseAvg=polarplot([mPhaseMov-mPhaseDB mPhaseMov-mPhaseDB],[0 hOut.hAxes.RLim(2)],'k');
hOut.hRoseAvg.Color=histColor;

maxSamplesInBin=hOut.hAxes.RLim(2);

%plot db relative to mean db
hOut.hPolar=polarplot([0 (1:18)/18]*pi*2-mPhaseDB,[mResampledTemplate(end) mResampledTemplate]/(max(mResampledTemplate/maxSamplesInBin)));
hOut.hPolar.LineWidth=2;
hOut.hPolar.Color=cMap(1,:,:);
%plot mean db
hOut.hPolarAvg=polarplot([0 0],[0 hOut.hAxes.RLim(2)],'k');
hOut.hPolarAvg.Color=cMap(1,:,:);

%legend and random hist
hOut.hRose2=polarhistogram(phaseRand*2*pi-mPhaseDB,18);
hOut.hRose2.FaceColor=[0.5 0.5 0.5];
hOut.hRose2.FaceAlpha=0.4;
hOut.l=legend([hOut.hRose hOut.hRose2 hOut.hPolar hOut.hRoseAvg],'SWC','Shuff','OF','Avg. SWC');

hOut.l.Color=[1 1 1];
hOut.l.Box='off';
hOut.l.Position=[0.0232    0.6950    0.1946    0.1119];
set(hOut.hAxes,'RLim',[0 140]);

%Fig 5 - panel b
%rearrange so that recordings with a few nights will be ploted on top
[~,order]=sort(nRecsPerAnimal,'descend');

f=figure;
h2=subplot(1,1,1,polaraxes);hold on;
Rlim=0.4;

hP={};
for i=1:numel(uniqueAnimals)
    p=find(pVal' & strcmp(Animals,uniqueAnimals(order(i))));
    hP{i}=polarplot([relativePhase(p);relativePhase(p)],[zeros(1,numel(p));Rlim*ones(1,numel(p))],'color',animalColor(order(i),:),'LineWidth',1);
end
hold on;hP3=polarplot([0 0],[0 Rlim],'color','k','linewidth',3);

hRose=polarhistogram(h2,relativePhase(pVal),10,'Normalization','probability');
hRose.FaceColor=[0.7 0.7 0.7];
hRose.FaceAlpha=0.5;

text(0.2, Rlim/2, '\delta/\beta');
h2.ThetaTick=[0:90:330];
h2.RTick=[0.1:0.1:0.4];
%h2.ThetaTickLabels([2 3 5 6 8 9 11 12])=cell(size([2 3 5 6 8 9 11 12]));

l2=legend([hP{1}(1),hP3,hRose],{'singleNight','\delta/\beta','Prob.'},'box','off');
l2.Position=[0.7386    0.8238    0.2125    0.1190];

%%
load fig_5_panel_c_d_data;
cmap=[lines(7);fliplr(lines(7))];

%{
    save fig_5_panel_c_d_data mResampledTemplateDB mResampledTemplateBRAC mResampledTemplateAmp recordingAnimalColor...
        BRAC_REM BRAC_SWS BAmp_SWS BAmp_REM angles;
%}

% fig 5 - panel c
f=figure('Units','centimeters','Position',[10 10 24 8]);
h1=subplot(1,4,1:2);
plot(angles,normZeroOne(mResampledTemplateDB),'lineWidth',3);hold on;
plot(angles,normZeroOne(mResampledTemplateAmp),'lineWidth',3);
plot(angles,normZeroOne(mResampledTemplateBRAC),'lineWidth',3);

hL=legend({'\delta/\beta','Norm. Breath. Amp.','Norm. Breath. rate'});
set(h1,'XTick',[-pi -pi/2 0 pi/2 pi],'XTickLabel',{'-\pi','-\pi/2','0','\pi/2','\pi'});
xlim([-pi pi]);
xlabel('Phase');ylabel('norm. intensity');xlabel('Phase');

% fig 5 - panel d
h2=subplot(1,4,3);hold on;
[hE2,hB2]=myErrorBar([1 2],[mean(BRAC_SWS);mean(BRAC_REM)],[std(BRAC_SWS)./sqrt(numel(BRAC_SWS)-1);std(BRAC_REM)./sqrt(numel(BRAC_SWS)-1)],[],'Bfacecolor',[0.9 0.9 0.9],'BLinewidth',2,'Ecolor','k');
[~,pV2] = ttest(BRAC_SWS,BRAC_REM);

xlim([0.3 2.7]);
h2.XTickLabel={'SWS','REM'};
for i=1:numel(BRAC_SWS)
    plot([1,2],[BRAC_SWS(i),BRAC_REM(i)],'color',recordingAnimalColor(i,:));
end
ylim([0 1]);xlim([0.5,2.5]);
ylabel('Norm. breat. rate AC');
line([1,2],[0.9 0.9],'color','k','linewidth',2);
text(1.5,0.95,['P=',num2str(pV2,3)],'horizontalAlignment','center');

h3=subplot(1,4,4);
[hE3,hB3]=myErrorBar([1 2],[mean(BAmp_SWS);mean(BAmp_REM)],[std(BAmp_SWS)./sqrt(numel(BAmp_SWS)-1);std(BAmp_REM)./sqrt(numel(BAmp_REM)-1)],[],'Bfacecolor',[0.9 0.9 0.9],'BLinewidth',2,'Ecolor','k');
[~,pV3] = ttest(BAmp_SWS,BAmp_REM);

for i=1:numel(BAmp_SWS)
    plot([1,2],[BAmp_SWS(i),BAmp_REM(i)],'color',recordingAnimalColor(i,:));
end
ylim([0 1]);xlim([0.5,2.5]);
ylabel('Norm. breath. Amp.');
h3.XTickLabel={'SWS','REM'};
line([1,2],[0.9 0.9],'color','k','linewidth',2);
text(1.5,0.95,['P=',num2str(pV3,3)],'horizontalAlignment','center');

%%
load fig5_e_f_data;

% fig 5 - panel e
cMap=[lines(7);fliplr(lines(7))];

fH=figure;
h=subplot(1,2,1,polaraxes);hold on;

hOut.hRose=polarhistogram(phaseMov*2*pi-mPhaseDB,nBins,'FaceColor',[0.9 0.078 0.184],'FaceAlpha',0.7);
h.ThetaTick=[0:30:330];
h.ThetaTickLabels([2 3 5 6 8 9 11 12])=cell(size([2 3 5 6 8 9 11 12]));

%set(h,'color','k');
maxSamplesInBin=h.RLim*0.9;

hOut.hPolar=polarplot([0 (1:nBins)/nBins]*pi*2-mPhaseDB,[mResampledTemplate(end) mResampledTemplate]/(max(mResampledTemplate/maxSamplesInBin(2)))...
    ,'LineWidth',2,'Color',cMap(1,:,:));

hOut.hRose2=polarhistogram(phaseRand*2*pi-mPhaseDB,nBins,'FaceColor',[0.5 0.5 0.5],'FaceAlpha',0.2);hold on;

hOut.hPolarAvg=polarplot([0 0],h.RLim,'LineWidth',2,'Color','k');

hOut.l=legend([hOut.hRose hOut.hPolar hOut.hRose2 hOut.hPolarAvg],'Movement','\delta/\beta','shuffled','mean');
hOut.l.Color=[1 1 1];
hOut.l.Box='off';
hOut.l.Location='northoutside';
hOut.l.Position=[0.0420 0.7248 0.1946 0.1464];

% fig 5 - panel f
%rearrange so that recordings with a few nights will be ploted on top
[~,order]=sort(nRecsPerAnimal,'descend');

%to invert the overlay of the arrows and better show SA06
h2=subplot(1,2,2,polaraxes);hold on;
Rlim=20;

hP={};
for i=1:numel(uniqueAnimals)
    p=find(pVal' & strcmp(Animals,uniqueAnimals(order(i))));
    hP{i}=polarplot([relativePhase(p);relativePhase(p)],[zeros(1,numel(p));Rlim*ones(1,numel(p))],'color',animalColor(order(i),:),'LineWidth',1);
end
hP3=polarplot([0 0],[0 Rlim],'color','k','linewidth',3);

text(0.2, Rlim/2, '\delta/\beta');
h2.ThetaTick=[0:30:330];
h2.ThetaTickLabels([2 3 5 6 8 9 11 12])=cell(size([2 3 5 6 8 9 11 12]));

pPH=polarhistogram(relativePhase(pVal),22,'facecolor','k','facealpha',0.7);
h2.RTick=[5 10 15 Rlim];
h2.RLim=[0 Rlim];

delete(pPH);
pPH=polarhistogram(relativePhase(pVal),22,'facecolor','k','facealpha',0.7);
l2=legend([hP{1}(1),pPH],{'singleNight','# nights'},'box','off');
l2.Position=[0.4556    0.7351    0.2000    0.0774];



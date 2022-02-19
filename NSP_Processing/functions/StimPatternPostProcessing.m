% This script splits BR_stim NSx files into trials
%
% Continuous data is sampled at 30 ks/s via NSP analog input ports for
% Stim channel (PCC, analog #1), response channel (hippocampus, analog #2),
% and sync channel (sync pulses, analog #3).
%
% Digital data is sampled at 1 ks/s via NSP digital input ports for 128-
% channel EEG
%
% Current BR_stim paradigm has 20s-long stim event and 20s-long no-stim 
% events. Stimulation sequences(pattern) are saved during the paradigm.
% This script returns EEG_stim and EEG_nostim (channel * events* time
% samples), BN_stim(stim envolope in the form of events* time sampels), and
% PCC channel(actual stim sequences in the form of events* time samples).

% David Wang
% April 2021


clc;close all;clear 

addpath(genpath('/project/TIBIR/Lega_lab/shared/lega_ansir/DavidWang_code/BlackRock/'))

Subject = 'UT247';
session = '2';

Fs = 1000;
StimEvent = struct('StimAmp',[],'StimFreq',[]);

savepath = sprintf('/project/TIBIR/Lega_lab/shared/lega_ansir/DavidWang_code/BlackRock/BR_stim_DataTrials/%s/',Subject);
% if ~exist(savepath, 'dir')
%    mkdir(savepath)
% end

rawdatapath  = sprintf('/project/TIBIR/Lega_lab/shared/lega_ansir/DavidWang_code/BlackRock/BR_stim_DataRaw/%s/session_%s/',Subject,session);

a = dir(fullfile(rawdatapath,'*.mat'))
BNsequence = [BNsequence(1:20000);BNsequence(20001:end)];



ConEEG = openNSx([rawdatapath,sprintf('session_%s.ns5',session)],'uv');
digiEEG = openNSx([rawdatapath,sprintf('session_%s.ns2',session)],'uv');

Condata = ConEEG.Data;
EEGchannels = digiEEG.Data;



% Condata = bandstop(Condata',[59 61],Fs1,'steepness',0.6)';
% digiEEG = bandstop(digiEEG',[59 61],Fs2,'steepness',0.6)';


stimChannel = Condata(end,:);
respChannel = Condata(end,:);
syncChannel = Condata(end,:);
plot(syncChannel)

datadur = ConEEG.MetaTags.DataDurationSec;
timevec = linspace(0,datadur,length(Condata));


Stimduration = 20;



baseline = linspace(0,Stimduration,Stimduration*Fs1);
stimdur = linspace(0,Stimduration,Stimduration*Fs1);
eventlen = length(baseline)+length(stimdur);
%length(find(syncChannel>4000))
%[PKS,LOCS] = findpeaks(syncChannel,'MinPeakHeight',1700);
LOCS = [674900 1883000 3101000 4313000 5523000 6739000];

Offset = LOCS;
NostimOffset = LOCS - length(baseline);



example = EEGchannels(75,1:12000);
plot(example)

PCC = [];
HIPPO = [];
for i = 1:length(LOCS)
    stim = stimChannel(LOCS(i):LOCS(i)+length(stimdur)-1);
    resp =  respChannel(LOCS(i):LOCS(i)+length(stimdur)-1);
    
    load([rawdatapath,sprintf('BN_StimPattern_%03d',1)])   
    PCC(i,:) = stim;
    HIPPO(i,:) = resp;
end



DigiLOCS = floor(LOCS/(Fs1/Fs2));

EEG_stim = [];
EEG_nostim = [];
stimdurDigi = linspace(0,Stimduration,Stimduration*Fs2);
BN_stim = [];
for i = 1:length(LOCS)
    eeg_stim = EEGchannels(:,DigiLOCS(i):DigiLOCS(i)+length(stimdurDigi)-1); 
    eeg_nostim = EEGchannels(:,DigiLOCS(i)-length(stimdurDigi)+1:DigiLOCS(i)); 
    EEG_stim(:,i,:) = resample(eeg_stim',resamplerate,Fs2)';
    EEG_nostim(:,i,:) = resample(eeg_nostim',resamplerate,Fs2)';
    load([rawdatapath,sprintf('BN_StimPattern_%03d.mat',1)])  
    BN_stim(i,:) = BNsequence(1:Fs2/resamplerate:20000);
end
figure
eg = squeeze(EEG_stim(89,2,:));
eg2 = squeeze(EEG_nostim(89,2,:));
t = linspace(0,20,20*500);
plot(t,eg);
hold on 
plot(t,eg2);
legend('Stim','No-stim')
ylabel('Amplitude (uV)')
xlabel('Time (s)')

figure
% y1 = hampel(eg,15,1.4826);
% y2 = hampel(eg2,15,1.4826);
plot(t,eg);
hold on 
plot(t,eg2);
legend('Stim','No-stim')
ylabel('Amplitude (uV)')
xlabel('Time (s)')

figure
y_filtered1 = lowpass(eg,90,500);
y_filtered1 = bandstop(y_filtered1,[59 61],500);
y_filtered2 = lowpass(eg2,90,500);
y_filtered2 = bandstop(y_filtered2,[59 61],500);


plot(t,y_filtered1,'linewidth',2);
hold on 
plot(t,y_filtered2,'linewidth',2);
legend('Stim','No-stim')
ylabel('Amplitude (uV)')
xlabel('Time (s)')
title('Right Hippocampus EEG')
grid on
xlim([0 2])

figure
pwelch(y_filtered1,[],[],[],500)
xlim([0 100])
title('Right Hippocampus PSD during stim')
hold on 
pwelch(y_filtered2,[],[],[],500)


t = linspace(0,length(EEGchannels)/500,length(EEGchannels));
plot(t,eg(1,:));
hold on 
plot(t,eg2(1,:));



eg2 = eg2(1,:);

eg = eg(1,:);
plot(example)


y_filtered = bandstop(y_filtered,[59 61],1000);


hold on; plot(y_filtered);


no_filtered = lowpass(eg2,100,1000);




% figure
% eg = squeeze(EEG_nostim(:,1,:));
% pwelch(eg(2,:)-eg(1,:),[],[],[],1000)

% filename = [savepath,sprintf('/session_%s.mat',session)];
% save(filename,'EEG_stim','EEG_nostim','BN_stim','PCC')


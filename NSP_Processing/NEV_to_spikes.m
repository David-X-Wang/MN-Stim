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
% David Wang April 2021


clc;close all;clear 

addpath(genpath('/project/TIBIR/Lega_lab/shared/lega_ansir/DavidWang_code/BlackRock/'))

Subject = 'UT253';
session = '0';


Fs = 1000;
resamplerate = 500;
Fs1 = 30000;
Fs2 = 1000;
savepath = sprintf('/project/TIBIR/Lega_lab/shared/lega_ansir/DavidWang_code/BlackRock/BR_stim_Spikes/%s/',Subject);
if ~exist(savepath, 'dir')
   mkdir(savepath)
end

rawdatapath  = sprintf('/project/TIBIR/Lega_lab/shared/lega_ansir/DavidWang_code/BlackRock/BR_stim_DataRaw/%s/session_%s/',Subject,session);


ConEEG = openNSx([rawdatapath,sprintf('session_%s.ns5',session)],'uv');
digiEEG = openNSx([rawdatapath,sprintf('session_%s.ns2',session)],'uv');

Condata = ConEEG.Data;
EEGchannels = digiEEG.Data;

syncChannel = Condata(end,:);
sync = lowpass(syncChannel,5,Fs1,'steepness',0.95);
[PKS,LOCS] = findpeaks(sync,'MinPeakProminence',20,'MinPeakHeight',150);
datadur = ConEEG.MetaTags.DataDurationSec;
timevec = linspace(0,datadur,length(Condata));

Stimduration = 5;


baseline = linspace(0,Stimduration,Stimduration*Fs1);
stimdur = linspace(0,Stimduration,Stimduration*Fs1);
eventlen = length(baseline)+length(stimdur);


Offset = LOCS;
NostimOffset = LOCS - length(baseline);

DigiLOCS = floor(LOCS/(Fs1/Fs2));
Spike_stim = [];
Spike_nostim = [];
stimdurDigi = linspace(0,Stimduration,Stimduration*Fs2);
BN_stim = [];

for i = 1:length(LOCS)
    eeg_stim = EEGchannels(:,DigiLOCS(i):DigiLOCS(i)+length(stimdurDigi)-1); 
    eeg_nostim = EEGchannels(:,DigiLOCS(i)-length(stimdurDigi)+1:DigiLOCS(i)); 
    Spike_stim(:,i,:) = eeg_stim;
    Spike_nostim(:,i,:) = eeg_nostim;
end

microEle = 97:105;
Spike_stim = Spike_stim(microEle,:,:);
Spike_nostim = Spike_nostim(microEle,:,:);

Spike_nostim_filtered = [];
for i = 1:size(Spike_stim,1)
    Spike_nostim_filtered(i,:,:) = bandstop(squeeze(Spike_nostim(i,:,:))',[59 61], Fs,'steepness',0.95)';
end

Spike_stim_filtered = [];
for i = 1:size(Spike_stim,1)
    Spike_stim_filtered(i,:,:) = highpass(squeeze(Spike_stim(i,:,:))',250, Fs,'steepness',0.95)';
    Spike_stim_filtered(i,:,:) = BNstim_deArt(squeeze(Spike_stim(i,:,:)),Fs);
end


%Spike_stim = Spike_sitm_filtered;

filename = [savepath,sprintf('/session_%s.mat',session)];
save(filename,'Spike_stim_filtered','Spike_nostim_filtered')
%%
eg1 = squeeze(Spike_nostim_filtered(1,:,:));
eg2 = squeeze(Spike_stim_filtered(1,:,:));
eg3 = squeeze(Spike_stim(1,:,:));
t = linspace(0, 5,5000);
plot(t,eg1');
title('micro LFP durig no stim')
ylabel('Amplitude (uV)');
xlabel('Time(s)')

figure
plot(t,eg3')
title('micro LFP durig stim')
ylabel('Amplitude (uV)');
xlabel('Time(s)')

figure
plot(t,eg2')
title('micro LFP durig stim filtered')
ylabel('Amplitude (uV)');
xlabel('Time(s)')
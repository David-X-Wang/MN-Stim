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

StimPattern = 'QN'; %'BN'


if strcmp(StimPattern, 'BN')    
    subjects={'UT253','UT257','UT256','UT261','UT263','UT265','UT264','UT269','UT271','UT277','UT283','UT284'};
    sessions = {'0','0','0','0','0','0','0','0','0','1','0','0'};
    HippoNum = {[1,2,31],[2,3],[91,92],[1,2,41,42],[1,2,41],[1,2,31,32],[1,2,55,56],[1,2,12],[1,12],[1,2,31,32],[2,3],[1,31]};
else
    subjects={'UT283'};
    sessions = {'0'};
    HippoNum = {[2]};
end

% subjects={'UT283','UT284'};
% sessions = {'3','2'};
% HippoNum = {[2,3],[1,31]};

% QN



TrailOffset = 0;
Fs1 = 30000;
Fs2 = 1000;
resamplerate = 500;
Fs = 500;
acc = 1;
Stimduration = 2;
method = 'hilbert'; % wavelet or hilbert
band = 'gamma';

if strcmp(band,'gamma')
    FreqOI = [30 50];
elseif strcmp(band,'theta')
    FreqOI = [5 9];
end


savepath = sprintf('/project/TIBIR/Lega_lab/shared/lega_ansir/DavidWang_code/BlackRock/Hippo_%sStim_%s_%ssec_%soffset/',StimPattern,band,num2str(Stimduration),num2str(TrailOffset));
if ~exist(savepath, 'dir')
    mkdir(savepath)
end



for Sind = 1:length(subjects)
    Subject = subjects{Sind};
    session = sessions{Sind};
    HippoChans = HippoNum{Sind};
    
%     if strcmp(session,'0') || strcmp(session,'1')
%         Stimduration = 5;
%     else
%         Stimduration = 3;
%     end

    rawdatapath  = sprintf('/project/TIBIR/Lega_lab/shared/lega_ansir/DavidWang_code/BlackRock/BNstim_DataRaw/%s/session_%s/',Subject,session);
    
    ConEEG = openNSx([rawdatapath,sprintf('session_%s.ns5',session)],'uv');
    digiEEG = openNSx([rawdatapath,sprintf('session_%s.ns2',session)],'uv');
    Condata = ConEEG.Data;
    EEGchannels = digiEEG.Data;
    
    if iscell(Condata)
        Condata = cell2mat(Condata);
        EEGchannels = cell2mat(EEGchannels);
    end
    
    
    
    
    syncChannel = Condata(end,:);
    sync = lowpass(syncChannel,5,Fs1,'steepness',0.95);
    
    MinPeakHeight = max(sync)*0.7;
    Filesnames = dir([rawdatapath,'BN_StimPattern_*.mat']) ;
    NPeaks = length(Filesnames);
    
    [PKS,LOCS] = findpeaks(sync,'MinPeakProminence',20,'MinPeakHeight',MinPeakHeight,'MinPeakDistance',5*Fs1,'NPeaks',NPeaks);
    display(length(LOCS))
    findpeaks(sync,'MinPeakProminence',20,'MinPeakHeight',MinPeakHeight,'MinPeakDistance',5*Fs1,'NPeaks',NPeaks);
    % datadur = ConEEG.MetaTags.DataDurationSec;
    % timevec = linspace(0,datadur,length(Condata));
    
    baseline = linspace(0,Stimduration,Stimduration*Fs1);
    stimdur = linspace(0,Stimduration,Stimduration*Fs1);
    eventlen = length(baseline)+length(stimdur);
    
    %[PKS,LOCS] = findpeaks(sync,'MinPeakHeight',3000);
    
    
    Offset = LOCS;
    NostimOffset = LOCS - length(baseline);
    
    
    DigiLOCS = floor(LOCS/(Fs1/Fs2));
    
    EEG_stim = [];
    EEG_nostim = [];
    stimdurDigi = linspace(0,Stimduration,Stimduration*Fs2);
    BN_stim = [];
    
    for i = 1:length(LOCS)
        eeg_stim = EEGchannels(:,DigiLOCS(i)-TrailOffset:DigiLOCS(i)+TrailOffset+length(stimdurDigi)-1);
        eeg_nostim = EEGchannels(:,DigiLOCS(i)-TrailOffset-length(stimdurDigi)+1:DigiLOCS(i)+TrailOffset);
        EEG_stim(:,i,:) = resample(eeg_stim',resamplerate,Fs2)';
        EEG_nostim(:,i,:) = resample(eeg_nostim',resamplerate,Fs2)';
        load([rawdatapath,sprintf('BN_StimPattern_%03d.mat',i)])
        BN_stim(i,:,:) = BNsequence(:,1:Fs2/resamplerate:end);
    end
    BN_stim = BN_stim(:,:,1:Stimduration*Fs);
    % empChan = zeros(128-size(EEG_stim,1),size(EEG_stim,2),size(EEG_stim,3));
    % EEG_stim = [EEG_stim; empChan];
    % EEG_nostim = [EEG_nostim; empChan];
    %squeeze(eeg_stim(:,1,:))'
    
    
    for EleInd = 1:length(HippoChans)
        HippoChan = HippoChans(EleInd);
        hippoS = squeeze(EEG_stim(HippoChan,:,:));
        hippoNS = squeeze(EEG_nostim(HippoChan,:,:));
        BN = BN_stim;
        k = 30;
       % BN = cat(3,zeros(size(BN_stim,1),2,TrailOffset),BN);
        
   
        

        
        
        y1 = hampel(hippoS',k,1.4826)';  
        y1_notch = bandstop(y1',[59 61],Fs,'Steepness',0.98)';
        EEG_S= y1_notch;
        %EEG_S= y1_notch(:,TrailOffset/2+1:end-TrailOffset/2);
        
        
        y1 = hampel(hippoNS',k,1.4826)'; 
        y1_notch = bandstop(y1',[59 61],Fs,'Steepness',0.98)';
        EEG_NS = y1_notch;
        %EEG_NS = y1_notch(:,TrailOffset/2+1:end-TrailOffset/2);        
        
        EEG_S = bandpass(EEG_S',FreqOI, Fs,'Steepness',0.98)';
        EEG_NS = bandpass(EEG_NS',FreqOI, Fs,'Steepness',0.98)';
        
        
%         [~,tf1] = rmoutliers(EEG_S,'gesd');
%         [~,tf2] = rmoutliers(EEG_NS,'gesd');               
%         outs = union(find(tf1==1),find(tf2==1));
%         
%         EEG_S(outs,:) = [];
%         EEG_NS(outs,:) = [];
%         BN(outs,:,:) = [];
        


%         %if strcmp(method,'wavelet')
%             fb = cwtfilterbank('signallength',length(EEG_S), 'wavelet','Morse','VoicesperOctave',8,'SamplingFrequency',Fs,'FrequencyLimit',FreqOI);
%             PWR_S = zeros(size(EEG_S));     
%             for i = 1:size(EEG_S,1)
%                 PWR_S(i,:) = sum(abs(cwt(EEG_S(i,:),'filterbank',fb)));
%             end
%             PWR_NS = zeros(size(EEG_NS));
%             for i = 1:size(EEG_S,1)
%                 PWR_NS(i,:) = sum(abs(cwt(EEG_NS(i,:),'filterbank',fb)));
%             end
%             
%         else
        
           
%         EEG_S = bandpass(EEG_S',FreqOI, Fs,'Steepness',0.98)';
%         EEG_NS = bandpass(EEG_NS',FreqOI, Fs,'Steepness',0.98)';   
        PWR_S = abs(hilbert(EEG_S'))';
        PWR_NS = abs(hilbert(EEG_NS'))';
            
  %      end
        
        EEG_S = EEG_S(:,TrailOffset+1:end);
        EEG_NS = EEG_NS(:,TrailOffset+1:end); 
        PWR_S = PWR_S(:,TrailOffset+1:end);
        PWR_NS = PWR_NS(:,TrailOffset+1:end);
             
        [~,P,~,STATS] = ttest2(mean(PWR_S,2),mean(PWR_NS,2),'tail','right');     
        Report(acc,:) = [mean(mean(PWR_S)),mean(mean(PWR_NS)),(mean(mean(PWR_S))-mean(mean(PWR_NS)))/ mean(mean(PWR_S)),STATS.tstat];
        
        filename = [savepath,sprintf('%s_session_%s_ele_%s.mat',Subject,session,num2str(HippoChan))];
        save(filename,'EEG_S','EEG_NS','PWR_S','PWR_NS','BN')
        
        acc = acc+1;
    end
    
    
end





% filename = [savepath,sprintf('/session_%s.mat',session)];
% save(filename,'EEG_stim','EEG_nostim','BN_stim')


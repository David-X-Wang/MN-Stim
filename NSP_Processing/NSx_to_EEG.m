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

% David Wang Feb. 2022


clc;close all;clear

% working directory, make sure the script is running on the directory of
% the package. 
%cd('/project/TIBIR/Lega_lab/shared/lega_ansir/DavidWang_code/BlackRock/');
cd ..
addpath(genpath('./'))

StimPattern = 'BN'; %'BN'       % stimulation patterns to choose from, binary-noise(BN) or quaternary-noise(QN)

if strcmp(StimPattern, 'BN')    
    subjects={'UT253','UT257','UT256','UT261','UT263','UT265','UT264','UT269','UT271','UT277','UT283','UT284'};
    sessions = {'0','0','0','0','0','0','0','0','0','1','0','0'};
    HippoNum = {[1,2,31],[2,3],[91,92],[1,2,41,42],[1,2,41],[1,2,31,32],[1,2,55,56],[1,2,12],[1,12],[1,2,31,32],[2,3],[1,31]};
else
    subjects={'UT283'};
    sessions = {'0'};
    HippoNum = {[2,3]};
end

% subjects={'UT283','UT284'};
% sessions = {'3','2'};
% HippoNum = {[2,3],[1,31]};

% QN



TrailOffset = 300;          % trial/event splitting offset in samples, for removing distortions by bandpass filtering. 
Fs1 = 30000;                % sampling rate for sync pulses, which are recorded via analog/continous port #1 on the NSP, in the format of "XXX.ns5"
Fs2 = 1000;                 % sampling rate for digital iEEG, which is recorded via NSP digital ports #1-128, sampled at 1 Ks/sample, in the format of "XXX.ns2"  
resamplerate = 500;         % resampling rate for digital iEEG, which has been band pass filtered during recording. 
Fs = 500;


Stimduration = 2;           % trial length in seconds, check stimulation paradigm before making changes 
method = 'hilbert';         % Method for extracting EEG oscillatory power by Wavelet filterbank or Hilbert transform
band = 'gamma';             % Frequency band the EEG oscillatory power

if strcmp(band,'gamma')
    FreqOI = [30 50];
elseif strcmp(band,'theta')
    FreqOI = [5 9];
end

% file save path for processed EEG
savepath = sprintf('../Data_Processed/Hippo_%sStim_%s_%ssec_%soffset/',...
    StimPattern,band,num2str(Stimduration),num2str(TrailOffset));
if ~exist(savepath, 'dir')
    mkdir(savepath)
end

% report and log save
Report = struct('Subject',[],'Electrode',[],'Power_stim',[],'Power_nostim',[],'Power_diff',[],'Power_tstats',[],'EventsNumber',[]);
logName = [savepath,'processing_log.log'];
diary(logName)

acc = 1;
for Sind = 1:length(subjects)
    Subject = subjects{Sind};
    session = sessions{Sind};
    HippoChans = HippoNum{Sind};
    
    %
    rawdatapath  = sprintf('./Data_Raw/%s/session_%s/',Subject,session);
    
    ConEEG = openNSx([rawdatapath,sprintf('session_%s.ns5',session)],'uv');     %read .ns5 files, dependency: BlackrockNeurotech NPMK
    digiEEG = openNSx([rawdatapath,sprintf('session_%s.ns2',session)],'uv');    %read .ns5 files, dependency: BlackrockNeurotech NPMK
    Condata = ConEEG.Data;
    EEGchannels = digiEEG.Data;
    
    if iscell(Condata)
        Condata = cell2mat(Condata);
        EEGchannels = cell2mat(EEGchannels);
    end
    
    
    % Sync pulses processing and track trial/event time-stamp
    syncChannel = Condata(end,:);
    sync = lowpass(syncChannel,5,Fs1,'steepness',0.95);                     % low-pass filtering in case sync channel is distroted by wiring/connections
    MinPeakHeight = max(sync)*0.7;                                           
    Filesnames = dir([rawdatapath,'BN_StimPattern_*.mat']) ;
    NPeaks = length(Filesnames);  
    [PKS,LOCS] = findpeaks(sync,'MinPeakProminence',20,'MinPeakHeight',MinPeakHeight,'MinPeakDistance',5*Fs1,'NPeaks',NPeaks);  
    %findpeaks(sync,'MinPeakProminence',20,'MinPeakHeight',MinPeakHeight,'MinPeakDistance',5*Fs1,'NPeaks',NPeaks);  
    disp([num2str(length(LOCS)),' events are found for subject ',Subject])
    
 
    
    baseline = linspace(0,Stimduration,Stimduration*Fs1);
    stimdur = linspace(0,Stimduration,Stimduration*Fs1);
    eventlen = length(baseline)+length(stimdur);
    
    Offset = LOCS;                                           % time-stamp when stimulation is on          
    NostimOffset = LOCS - length(baseline);                  % time-stamp for the baseline (no-stim)     
    DigiLOCS = floor(LOCS/(Fs1/Fs2));                        % convert time-stamp from high sampling (30 Ks/s) to low sampling rate (1Ks/s)
    
    
    EEG_stim = [];
    EEG_nostim = [];
    BN_stim = [];
    stimdurDigi = linspace(0,Stimduration,Stimduration*Fs2);
   
    for i = 1:length(LOCS)
        eeg_stim = EEGchannels(:,DigiLOCS(i)-TrailOffset:DigiLOCS(i)+TrailOffset+length(stimdurDigi)-1);
        eeg_nostim = EEGchannels(:,DigiLOCS(i)-TrailOffset-length(stimdurDigi)+1:DigiLOCS(i)+TrailOffset);
        EEG_stim(:,i,:) = eeg_stim;
        EEG_nostim(:,i,:) = eeg_nostim;
        load([rawdatapath,sprintf('BN_StimPattern_%03d.mat',i)])
        BN_stim(i,:,:) = BNsequence(:,1:Fs2/resamplerate:end);
    end
    BN_stim = BN_stim(:,:,1:Stimduration*Fs2);
    % empChan = zeros(128-size(EEG_stim,1),size(EEG_stim,2),size(EEG_stim,3));
    % EEG_stim = [EEG_stim; empChan];
    % EEG_nostim = [EEG_nostim; empChan];
    %squeeze(eeg_stim(:,1,:))'
    
    
    % EEG processing, including bandpass filtering for the frequency bands
    % in interests, feature extraction (oscillatory power), and outlier
    % removal.
    
    for EleInd = 1:length(HippoChans)
        HippoChan = HippoChans(EleInd);
        hippoS = squeeze(EEG_stim(HippoChan,:,:));
        hippoNS = squeeze(EEG_nostim(HippoChan,:,:));
        BN = BN_stim;
        k = 30;
       % BN = cat(3,zeros(size(BN_stim,1),2,TrailOffset),BN);     
        
       
        temp = hampel(hippoS',k,1.4826)';                             % initial outlier removal via hampel filters (for extremly distorted siganls)
        EEG_S = bandstop(temp',[59 61],Fs2,'Steepness',0.98)';        % notch fitlering for line noise removal
        %EEG_S= y1_notch(:,TrailOffset/2+1:end-TrailOffset/2);
        
        
        temp = hampel(hippoNS',k,1.4826)';                            % initial outlier removal via hampel filters (for extremly distorted siganls)
        EEG_NS = bandstop(temp',[59 61],Fs2,'Steepness',0.98)';       % notch fitlering for line noise removal
        %EEG_NS = y1_notch(:,TrailOffset/2+1:end-TrailOffset/2);        
        
        
        % bandpass fitlering for the frequency band in interests 
        EEG_S = bandpass(EEG_S',FreqOI, Fs2,'Steepness',0.98)';
        EEG_NS = bandpass(EEG_NS',FreqOI, Fs2,'Steepness',0.98)';
        
        
        % down sample EEG to 500 Hz
        EEG_S = resample(EEG_S',resamplerate,Fs2)';
        EEG_NS = resample(EEG_NS',resamplerate,Fs2)'; 
        
        % extract oscillatory power
        PWR_S = abs(hilbert(EEG_S'))';
        PWR_NS = abs(hilbert(EEG_NS'))';


        if strcmp(method,'wavelet')
            fb = cwtfilterbank('signallength',length(EEG_S), 'wavelet','Morse','VoicesperOctave',8,'SamplingFrequency',Fs,'FrequencyLimit',FreqOI);
            PWR_S = zeros(size(EEG_S));     
            for i = 1:size(EEG_S,1)
                PWR_S(i,:) = sum(abs(cwt(EEG_S(i,:),'filterbank',fb)));
            end
            PWR_NS = zeros(size(EEG_NS));
            for i = 1:size(EEG_S,1)
                PWR_NS(i,:) = sum(abs(cwt(EEG_NS(i,:),'filterbank',fb)));
            end
            
        end
        

        % remove offset and make EEG and power trials true to the duration
        EEG_S = EEG_S(:,TrailOffset/(Fs2/resamplerate)+1:end-TrailOffset/(Fs2/resamplerate));
        EEG_NS = EEG_NS(:,TrailOffset/(Fs2/resamplerate)+1:end-TrailOffset/(Fs2/resamplerate));
        PWR_S = PWR_S(:,TrailOffset/(Fs2/resamplerate)+1:end-TrailOffset/(Fs2/resamplerate));
        PWR_NS = PWR_NS(:,TrailOffset/(Fs2/resamplerate)+1:end-TrailOffset/(Fs2/resamplerate));
             
        
        % remove outlier trials via mean euclidean distance
        [ind1, ind2] = EucOutRemove(EEG_S,EEG_NS, 0.7);        
        EEG_S(union(ind1,ind2),:) = [];
        EEG_NS(union(ind1,ind2),:) = [];
        PWR_S(union(ind1,ind2),:) = [];
        PWR_NS(union(ind1,ind2),:) = [];
        
        
        disp(['   ....',num2str(length(LOCS)-length(union(ind1,ind2))),...
            ' events are left for Ele #',num2str(HippoChan),' after outlier removal'])
        
        
        [~,P,~,STATS] = ttest2(mean(PWR_S,2),mean(PWR_NS,2),'tail','right');     
        
        
        
     
                

        Report(acc).Subject = Subject;
        Report(acc).Electrode =  HippoChan;      
        Report(acc).Power_stim  = mean(mean(PWR_S));
        Report(acc).Power_nostim =  mean(mean(PWR_NS));
        Report(acc).Power_diff  = (mean(mean(PWR_S))-mean(mean(PWR_NS)));
        Report(acc).Power_tstats =  STATS.tstat;
        Report(acc).EventsNumber =  length(LOCS)-length(union(ind1,ind2));
   
        
        filename = [savepath,sprintf('%s_session_%s_ele_%s.mat',Subject,session,num2str(HippoChan))];
        save(filename,'EEG_S','EEG_NS','PWR_S','PWR_NS','BN')
        
        acc = acc+1;
    end
    
    
end
writetable(struct2table(Report), [savepath,'processing_report.csv'])




% filename = [savepath,sprintf('/session_%s.mat',session)];
% save(filename,'EEG_stim','EEG_nostim','BN_stim')


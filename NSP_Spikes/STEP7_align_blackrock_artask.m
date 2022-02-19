function [events, spikeData] =align_blackrock_artask(behDir,brDirs,baseSaveDir,lfpExt)
%% This new alignment script is designed to only do 1 subject/session at a time within the greater AR_Align.m script, i.e.: you will only have 1 brDirs


% path to event file
eventFile = fullfile(behDir,'events.mat');
brDirs = cell2mat(brDirs); % needed to do this for the dir2 calls
baseSaveDir = cell2mat(baseSaveDir);
% path to either eeg.eeglog.up or pulses.txt, which are the alignment
% pulses from the behavioral computer
if ~exist(fullfile(behDir, 'eeg.eeglog.up'),'file')
    beh_ms_file = fullfile(behDir,'pulses.txt');
else
    beh_ms_file = fullfile(behDir,'eeg.eeglog.up');
end

cd(pwd);

% start the downsampling of the clean NS6 blackrock files - these have gone
% through Srini's coherence subtraction and will yield the LFP files, saved
% in a folder labeled lfp.reref
saveDir = fullfile(baseSaveDir,'lfp.reref');
if ~exist(saveDir,'dir');mkdir(saveDir);end

% pre-allocate
pulses_matched = {}; beh_matched = {}; sr = {}; eegFiles = {}; dsRate = {};
spikeData = [];

% probably can delete fileExt, not needed
[dsRate,firstChanNum] = downsampleBlackrock_local(brDirs,saveDir,lfpExt); % PK deleted fileExt from output argument 3/11/21
%eegFiles = fullfile(saveDir,[lfpExt]);
eegFiles = dir2(fullfile(saveDir,'*mat'));

% pulse matching
fprintf('Finding matching blackrock and behavioral pulses.\n')
[pulses, sr] = extractBlackrockPulses_local(brDirs); % pulses is NS6.129.mat
behPulse_ms  = textread(beh_ms_file,'%n%*[^\n]','delimiter','\t'); % behPulse_ms is eeg.eeglog.up
[beh_matched,pulses_matched] = pulsealign2(behPulse_ms,pulses');

sr_microClock=sr; %samp rate of blackrock clock: use to convert spike times from this clock to behavioral clock with sampling rate on next line
sr= round((pulses_matched(end)-pulses_matched(1))/(beh_matched(end)-beh_matched(1))*1000); %29998; %MT added: calc sample rate from pulses and tot time

% load spike times (i.e.: times_ files)

tFiles = dir2(fullfile(pwd,'spike_times_neg'));
spikeData.spikeDir = tFiles.folder;
spikeData.spikeTimes = {};
spikeData.spikeNames = {};
fprintf('Loading sorted spike data for %s.\n', pwd)

for time_files = tFiles'
    time_info = load(fullfile(time_files(1).folder,time_files(1).name));
    
    clusters = unique(time_info.cluster_class(:,1));
    for cluster = clusters'
        if cluster > 0
            clustInds = time_info.cluster_class(:,1) == cluster;
            spikeData.spikeTimes{end+1} = (time_info.cluster_class(clustInds,2))*(sr_microClock/sr); %convert back to samples, then times in time of beh clock
            %spikeData(rawNum).spikeNames{end+1} = sprintf('NS6%03d_%d',f(tFile{1}),cluster);     %MT added 03 to pad so matches nc5 file names
            spikeData.spikeNames{end+1} = sprintf('NS6_%s_cluster%d',time_files.name(11:13),cluster);
        end
    end
end

events = blackRockAlign_local(beh_matched,pulses_matched,eventFile,sr,dsRate,eegFiles,brDirs,firstChanNum);

end



function [dsRate,firstChanNum] = downsampleBlackrock_local(dataDir,saveDir,lfpExt) % PK deleted fileExt from output variable 3/11/21

% get all NS6 files
chanFiles = dir2([dataDir,'/NS6_*_clean.mat']);
chanFiles = {chanFiles.name};

% exclude 129 (sync channel) and NS6_TimeStamps - should not have this
% regardless in UT Southwestern AR Data with how the file structure is
% setup
chanFiles = chanFiles(~strcmp(chanFiles,'NS6.129.mat')); chanFiles = chanFiles(~strcmp(chanFiles,'NS6_129.mat'));
chanFiles = chanFiles(~strcmp(chanFiles,'NS6_TimeStamps.mat')); % PK added 11/16/2020

%random channel number to input into gete (line 157) - firstChanNum=str2num(split_chan{1}(4:end)) - PK changed 11/16/2020 to what it is now
firstChan=chanFiles{1}; split_chan=strsplit(firstChan,'_'); firstChanNum=str2num(split_chan{2});

%create file to prevent from downsampling again if already done
startFile=fullfile(saveDir,['LOCKED_',lfpExt]);
if ~exist(startFile,'file')
    system(['touch ' startFile]);
    
    info = load('NS6_TimeStamps.mat'); %PK added
    
    for chanFile = chanFiles
        fprintf('Downsampling %s.\n',chanFile{1});
        
        % Load clean NS6 file
        try % probably can change dataDir{1,1} to dataDir - but will leave for now 3/11/21
            data = load(fullfile(dataDir{1,1},chanFile{1})); % PK added
        catch
            data = load(fullfile(dataDir,chanFile{1}));
        end
        % based on John Burke's code. First low pass filter then downsample
        dTS                           = diff(info.TimeStamps);
        timeInSecBetweenActualSamples = (dTS(1)./1e6);
        decimateFactor                = floor(1./(2000*timeInSecBetweenActualSamples));
        timeInSecBetweenDownsamples   = decimateFactor*timeInSecBetweenActualSamples;
        dsRate                        = 1./timeInSecBetweenDownsamples;
        
        % low-pass filter the data to prevent aliasing
        lowPassFreq = floor(.4*dsRate);
        
        % convert data to doubles before filtering....
        fprintf('Converting data to doubles for filtering....')
        data = double(data.data);
        fprintf('done\n')
        
        % filter the data
        fprintf('Filtering above %d Hz....',lowPassFreq)
        data_LP = buttfilt(data,lowPassFreq,info.sr,'low',4);
        fprintf('done\n')
        
        % Perform the decimation
        fprintf('Decimating every %d samples.\n',decimateFactor)
        indToKeep                        = false(1,length(data_LP));
        indToKeep(1:decimateFactor:end)  = true;
        downSampledData                  = data_LP(indToKeep);
        fprintf('New downsampling rate is %0.1f Hz\n',dsRate);
        
        % convert the downsampled data to int16's (the original data format)
        fprintf('Converting filtered data back to int16....')
        downSampledData_int16 = int16(downSampledData);
        fprintf('done\n')
        
        % finally write the file
        %         [~,fileExt] = fileparts(dataDir); - delete
        %       newChanFile = fullfile(saveDir,[lfpExt '_' fileExt,'_',chanFile{1}(5:7),'.mat']); - delete
        newChanFile = fullfile(saveDir,[lfpExt '_',chanFile{1}(5:7) '_', 'clean','.mat']);
        fprintf('writing to %s.....',newChanFile);
        outfid=fopen(newChanFile,'w','l');
        c=fwrite(outfid,downSampledData_int16,'int16');
        fclose(outfid);
        fprintf('done\n')
        
        % write params.txt file - could move out of loop
        fid = fopen(fullfile(saveDir,'params.txt'),'w','l');
        fprintf(fid,'samplerate %.2f\ndataformat ''%s''\ngain %g\n', dsRate, 'int16', 1);
        fclose(fid);
        
        % write params.txt file with the same fileExt as channel - could
        % move out of loop
        fid = fopen(fullfile(saveDir,['NS3', '.params.txt']),'w','l');
        fprintf(fid,'samplerate %.2f\ndataformat ''%s''\ngain %g\n', dsRate, 'int16', 1);
        fclose(fid);
        
        clear data data_LP
        fprintf('\n\n\n')
    end
else
    fprintf('locked\n\n',lfpExt);
    %[~,fileExt] = fileparts(dataDir); PK commented out 3/11/21
    % load NC5 for first channel only to get info
    chanFile=firstChan;
    %[data,info] = load_nc5_new(fullfile(dataDir,chanFile));
    
    [data] = load(fullfile(dataDir,chanFile));
    info = load('NS6_TimeStamps.mat');
    
    % based on John Burke's code. First low pass filter then downsample
    dTS                           = diff(info.TimeStamps);
    timeInSecBetweenActualSamples = (dTS(1)./1e6);
    decimateFactor                = floor(1./(2000*timeInSecBetweenActualSamples));
    timeInSecBetweenDownsamples   = decimateFactor*timeInSecBetweenActualSamples;
    dsRate                        = 1./timeInSecBetweenDownsamples;
end
end
function [pulses,sr] = extractBlackrockPulses_local(dataDir)
try
    [data] = load(fullfile(dataDir,'NS6.129.mat'));
    
catch
    
    [data] = load(fullfile(dataDir,'NS6_129.mat'));
end

data.data(data.data<0) = 0;
normalizedpulse = data.data/max(data.data);
dPulse = [0 diff(normalizedpulse)];
ddPulseShift = [diff(dPulse) 0];
dPulse(ddPulseShift==-2) = 0;
triggerThresh = 0.5;

% detect rising edge
pulses = find(dPulse>triggerThresh);
sr = data.sr;
end

function events = blackRockAlign_local(beh_ms,br_ms,evFile,samplerate,lfp_samplerate,eeg_files,brDirs,firstChanNum) %br_ms actually in samples, not ms

% to fix later
beh_ms = num2cell(beh_ms,1);
br_ms = num2cell(br_ms,1);

% allocate
num_br = length(br_ms);
b = zeros(2,num_br);
eeg_start_ms = zeros(num_br,1);
eeg_stop_ms = zeros(num_br,1);

% load events
events = load(evFile);
events = events.events;

% add blank fields
[events.lfpfile] = deal('');
[events.lfpoffset] = deal(NaN);
[events.timesoffset] = deal(NaN);

% behavioral times
behEvents_times = [events.mstime]';

% loop over each black rock directory
for fNum = 1:num_br
    
    % get slope and offset for each eeg file
    bfix = beh_ms{fNum}(1);
    [b(:,fNum),bint,r,rin,stats] = regress(br_ms{fNum},[ones(length(beh_ms{fNum}),1) beh_ms{fNum}-bfix]);
    b(1,fNum) = b(1,fNum) - bfix*b(2,fNum);
    
    % calc max deviation
    act=[ones(length(beh_ms{fNum}),1) beh_ms{fNum}]*b(:,fNum);
    maxdev = max(abs(act - br_ms{fNum}));
    meddev = median(abs(act - br_ms{fNum}));
    rawDevs=act - br_ms{fNum};
    
    % report stats
    fid = fopen('Alignment_Report_Stats.txt','wt','n'); %Pranish added to create a report for batching these out
    fprintf(fid,'\tMax. Dev. = %f ms\n', maxdev / samplerate(fNum) * 1000);
    fprintf(fid,'\tMedian. Dev. = %f ms\n', meddev / samplerate(fNum) * 1000);
    fprintf(fid,'\t95th pctile. = %f ms\n', prctile(rawDevs,95) / samplerate(fNum) * 1000);
    fprintf(fid,'\t99th pctile. = %f ms\n', prctile(rawDevs,99) / samplerate(fNum) * 1000);
    fprintf(fid,'\tR^2 = %f\n', stats(1));
    fprintf(fid,'\tSlope = %f\n', b(2,fNum));
    fprintf(fid,'\tPulse range = %.3f minutes\n',range(beh_ms{fNum})/1000/60);
    
    % calc the start and end for that file
    % make a fake event to load data from gete
    %[path,efile,ext] = fileparts(eeg_files(fNum));
    %fileroot = fullfile(eeg_files(1).folder,eeg_files(1).name);
    fileroot = fullfile(eeg_files(1).folder,'NS3');
    event = struct('eegfile',fileroot);
    eeg = gete(firstChanNum,event,0);
    %eeg = gete(1,event,0);
    duration = length(eeg{1});
    
    % get start and stop in ms of the lfp file
    eeg_start_ms(fNum) = round((1 - b(1,fNum))/b(2,fNum));
    eeg_stop_ms(fNum)  = round((duration*(samplerate(fNum)/lfp_samplerate(fNum)) - b(1,fNum))/b(2,fNum));
    
    % convert blackrock sample to ms (for spikes) and to samplenum for
    % lfpoffset. brEvents_times is really the sample number in the original
    % (not downsampled) black rock file
    brEvents_times = double([ones(length(behEvents_times),1) behEvents_times])*b(:,fNum);
    
    % convert to ms since start of recording (timesoffset)
    brEvents_ms = brEvents_times / (samplerate(fNum)/1e3);
    
    % convert to samples at 2000 hz (lfpoffset)
    brEvents_samps = round(brEvents_times / (samplerate(fNum)/lfp_samplerate(fNum)));
    
    % loop over each events
    for e = 1:length(events)
        
        % check if this event is with the calculated bounds of the current
        % lfp file. Only add the timing info if it is.
        if events(e).mstime < eeg_start_ms(fNum) || events(e).mstime > eeg_stop_ms(fNum)
            fprintf('Event %d not in %s.\n',e,eeg_files(fNum).name)
        else
            events(e).NS3_lfpfile = fullfile(eeg_files(fNum).folder,eeg_files(fNum).name);
            % in downsampled lfp samples
            events(e).NS3_lfpoffset_samples = brEvents_samps(e);
            events(e).timesfile = fullfile(brDirs(fNum),'times_NS6');
            % in ms
            events(e).timesoffset_ms = brEvents_ms(e);
            %events(e).timesoffsetSamp=brEvents_times(e); %MT just to debug
            
            % also add an extra field to pathInfo, if it exists
            if isfield(events(e),'pathInfo') && ~isempty(events(e).pathInfo)
                path_mstime = events(e).pathInfo.mstime;
                path_brTimes = [ones(length(path_mstime),1) path_mstime]*b(:,fNum);
                path_brEvents_ms = path_brTimes / (samplerate{fNum}/1e3);
                path_brEvents_samps = round(path_brTimes / (samplerate{fNum}/lfp_samplerate{fNum}));
                events(e).pathInfo.lfpfile = eeg_files{fNum};
                events(e).pathInfo.lfpoffset = path_brEvents_samps;
                events(e).pathInfo.timesoffset = path_brEvents_ms;
            end
        end
        
    end
end
end

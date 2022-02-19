function events = micro_align(subj,raw_name,sessnum,sync_ch)
%
% FUNCTION:
%   events = micro_align(subj,raw_name,sessnum,sync_ch)
%
% DESCRIPTION:
%   Align event structure to micro LFP timeseries
%    
% INPUTS:
%   subj:       subject ID string
%   raw_name:   session raw folder name
%   sessnum:    session number integer
%   sync_ch:    sync pulse file name
%
%   examaple: events = micro_align('UT084','2_2_2018 FR1_micro',0,'NS3.129.mat');
%
% OUTPUTS:
%   events:  	resulting event structure with added fields. Automatically
%               saved in appropriate behavioral folder. 
%
% Last Updated: 05-08-2018
% Author: Jui-Jui Lin 
% 

basedir = '/Users/JL/ExperimentalData/subjFiles';

rawdir = sprintf('%s/%s/raw/%s',basedir,subj,raw_name);

load(fullfile(rawdir,sync_ch))
data_down = downsample(data,2);

behdir = sprintf('%s/%s/behavioral/FR1_micro/session_%d',basedir,subj,sessnum);
up_sync = importdata([behdir '/eeg.eeglog.up']);

load([behdir '/events.mat'])
ev_mstime = getStructField(events,'mstime')';

eegfile = [rawdir '/NS3'];

for n=1:length(up_sync)
    unix_time(n) = str2num(up_sync{n}(1:13));
end

unix_time_diff = diff(unix_time);

ind = find(data_down>0);
ind_ind = find(diff(ind)>1);
ind_ind = [1 ind_ind+1];

for n=1:length(ind_ind)
    if n==length(ind_ind)
        ind_range = ind(ind_ind(n):end); 
    else
        ind_range = ind(ind_ind(n):ind_ind(n+1)-1);
    end
    [y,i] = max(data_down(ind_range));
    peaks(n)= ind_range(i);
end

peaks = peaks';
peaks_diff = diff(peaks);

peaks_diff_ind = 1;
% peaks_diff_lead = peaks_diff(1);

for n = 1:length(unix_time_diff);
    this_calc= unix_time_diff(n)-peaks_diff(peaks_diff_ind);
    if this_calc >=2 | this_calc <=-2
        
    else
        peaks_diff_ind = peaks_diff_ind+1;
        temp_calc1= unix_time_diff(n+1)-peaks_diff(peaks_diff_ind);
        if temp_calc1 <=2 & temp_calc1 >=-2
            temp_calc2= unix_time_diff(n+2)-peaks_diff(peaks_diff_ind+1);
            if temp_calc2 <=2 & temp_calc2 >=-2
                align_ind =n:n+length(peaks_diff);
                break
            else
            end    
        else
        end
    end
    
end

unix_time_align = unix_time(align_ind);
a = diff(unix_time_align');
b = peaks_diff;

fprintf('Difference Avg: %.3f\n',mean(a-b))
fprintf('If this number is not well below 1, abort and double check recording file\nOtherwise continue to save out event.\n')
keyboard

% unix_time_align(1)-session_log(1)

offset_zero = unix_time_align(1)-peaks(1);
eegoffset = ev_mstime - offset_zero;
eegoffset(eegoffset<0)=0;

for n=1:length(events)
    
    if eegoffset(n)==0
        events(n).eegfile = [];
    else
        events(n).eegfile = eegfile;
    end
    events(n).eegoffset = eegoffset(n);
end

save(fullfile(behdir,'events_LFP.mat'),'events') 
fprintf('Done.\n')
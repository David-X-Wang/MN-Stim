%% Fix data for event alignment - Pranish Kantak - Last Updated: 11/18/2018

% Run this script if the blackrock recording was started before the
% behavioral computer session.  You must be in the directory that is the
% subjects raw blackrock folder (e.g.: 10_10_2018_FR1_Micro)

%% Begin - MUST BEGIN WITH NS3.129 and NS6.129 (i.e.: the sync channels)
tic
ccc
subject = 'UT113';
session = '8_29_18_FR1_Micro';
fix_dir = sprintf('/Volumes/Pranish/FR1_Local_Data/%s/Raw/%s/fixed_for_alignment',subject,session);
raw_dir = sprintf('/Volumes/Pranish/FR1_Local_Data/%s/Raw/%s',subject,session);

align_fol = 'fixed_for_alignment';
NS3 = 'NS3';
NS6 = 'NS6';
mkdir ([raw_dir,'/',align_fol]);


cd (raw_dir);
% this section gets the sync pulses in order

load(sprintf('%s/NS3.129.mat',raw_dir));
% x is a variable that represents the first sample of the LFP or Spike
% timeseries that is above an absolute value of 15. This script is
% necessary only if the blackrock recording was started before the
% behavioral laptop. You must run this script before alignment
x_lfp = find(abs(data) > 11);

% first_sample corresponds to the sample number of the first value over 15,
% this corresponds roughly to when the behavioral computer starts sending
% pulses to the blackrock.
first_sample_lfp = x_lfp(1);
data(:,[1:first_sample_lfp]) = [];

mkdir([fix_dir,'/',NS3]);
savename = sprintf('%s/NS3/NS3_fix.129.mat',fix_dir);
save(savename,'data', 'sr');

%data_to_remove corresponds to the extraneous data that must be removed
%from every LFP and spike channel.  NB: you must run this script separately
%for the NS3 (LFP) channel and NS6 (spike) channels, because of the
%different sampling rates
data_to_remove_lfp = 1:first_sample_lfp;

clearvars -except data_to_remove_lfp NS3 NS6 raw_dir fix_dir x_lfp subject session

% start on the spike sync channel (same steps as above)
load(sprintf('%s/NS6.129.mat',raw_dir));

% since spikes are detected at the same time as LFPs, just multiply by 15
% to get the sameples to delete. Spikes are sampled at 30kHz, LFPs sampled
% at 2kHz
first_sample_spikes = x_lfp(1) * 15;
data(:,[1:first_sample_spikes]) = [];
data_to_remove_spikes = 1:first_sample_spikes;

mkdir([fix_dir,'/',NS6]);
savename = sprintf('%s/NS6/NS6_fix.129.mat',fix_dir);
save(savename,'data', 'sr');

clearvars -except data_to_remove_lfp data_to_remove_spikes NS3 NS6 raw_dir fix_dir subject session

%% set up for subtracting the "data_to_remove_*" variables from all the NS3 and NS6 files per subject

lfp_files = dir2(sprintf('%s/NS3.0*.mat',raw_dir));

% the reason its a joinspikedir is if you haven't changed the "." after NS6
% to an "_" as required by combinato yet

jointspikedir = [dir2(sprintf('%s/NS6_0*.mat',raw_dir));dir2(sprintf('%s/NS6.0*.mat',raw_dir))];

for lfps = lfp_files'
   
    load([lfps.folder filesep lfps.name])
    
    data(:,data_to_remove_lfp) = [];
    
    savename = sprintf('%s/NS3/%s',fix_dir,lfps.name);
    
    save(savename,'data', 'sr');
    
    clearvars -except data_to_remove_lfp data_to_remove_spikes spike_files lfp_files raw_dir fix_dir lfps subject session jointspikedir
    
end

disp('Keep cool asshole, the lfps are done')

for spikes = jointspikedir'
   
    load([spikes.folder filesep spikes.name])
    
    data(:,data_to_remove_spikes) = [];
    
    savename = sprintf('%s/NS6/%s',fix_dir,spikes.name);
    
    save(savename,'data', 'sr');
    
    clearvars -except data_to_remove_lfp data_to_remove_spikes spike_files lfp_files raw_dir fix_dir spikes subject session jointspikedir
    
end
disp('All Done');

% just align the events in this script since it's done already
events = micro_align_fixed(subject,session,0,'NS3_fix.129.mat');

toc

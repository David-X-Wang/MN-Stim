clear all
close all
clc

% Get all NS6 files in the current folder
basedir = '/Users/brad/Desktop/Pranish_Micro_AR/';
subj = 'UT171';
sess = '9_25_19_AR_Micro';
%current = 'Current';
raw = 'raw';
% fix = 'fixed_for_alignment';
% fix_spike_dir = sprintf('%s/%s/%s/raw/%s/%s/NS6',basedir,current,subj,sess,fix);

spike_dir = sprintf('%s/%s/%s/%s',basedir,subj,raw,sess);

% cd(fix_spike_dir)

cd(spike_dir)

% files = dir(sprintf('%s/*.mat',fix_spike_dir));
files = dir(sprintf('%s/*.mat',spike_dir));
idx = ismember({files.name},{'NS6_TimeStamps.mat'});
files = files(~idx);
% Loop through each
for id = 1:length(files)
    % Get the file name (minus the extension)
    [~, f] = fileparts(files(id).name);
    
    f = strrep(f,'.0','_0');
    fcat = strcat(f,'.mat');
   
    if contains(f,'129') == 1
        f_129 = strrep(f,'.1','_1');
        f_129_cat = strcat(f_129,'.mat');
        movefile(files(id).name, f_129_cat);
    
    else
        movefile(files(id).name, fcat);
   
    end
    
end



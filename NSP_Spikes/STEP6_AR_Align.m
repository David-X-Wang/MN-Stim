%% % Inputs:
%
%         subj - string. subject code, should match the name in behavioral log file
%      session - int. session number to use when creating events
%       behDir - string. full path to directory containing behavioral data
%       brDirs - cell array of strings. Full paths to directories containing the NC5 files
%  baseSaveDir - string. full path to directory in which to create the lfp.noreref dir
%       lfpExt - string to use when saving the lfp data in lfp.noref
ccc

addpath(genpath('/Users/Pranish/Documents/MATLAB'));
addpath(genpath('/Volumes/Pranish/AR'));

subj_dir = dir2('/Volumes/Pranish/AR/subjects/UT*');

for subj = subj_dir'
    
    cd([subj.folder '/' subj.name '/' 'sorted'])
    test_date_dir = dir2(pwd);
    testing_date = {test_date_dir.name};
    lfpExt = 'NS3';
    
    for sess_num = 1:numel(test_date_dir)
        % have to do this for the stupid python way of coding session numbers
        python_session = sess_num - 1;
        behDir = sprintf('/Volumes/Pranish/AR/subjects/%s/behavioral/ar/session_%d',subj.name,python_session);
        spikeDir = ([test_date_dir(sess_num).folder '/' test_date_dir(sess_num).name]);
        cd(spikeDir)
        
        if isempty(dir2('spike_times_neg')) || ~exist('spike_times_neg','dir')
            mkdir('spike_times_neg')
            GetSpikesH5_Neg_Align(subj.name,testing_date{sess_num}); % if the spike times haven't been extracted, do it
            cd ..
        end
        
        if ~isfile('RawDir/NS6_TimeStamps.mat')
            RunSplit_CSS_JL_Align(subj.name,spikeDir) % this just runs the split for creating the timestamps file if you forgot to split it
        end
        
        if ~isfile([behDir '/' 'events_aligned.mat'])
            % align the events if they don't already exist
            %can i make brDirs not a cell array and then get rid of line 7 in the
            %align_blackrock_artask?
            brDirs{sess_num} = {sprintf('/Volumes/Pranish/AR/subjects/%s/sorted/%s/RawDir',subj.name,testing_date{sess_num})};
            baseSaveDir{sess_num} = {sprintf('/Volumes/Pranish/AR/subjects/%s/sorted/%s',subj.name,testing_date{sess_num})};
            [events, spikeData] = align_blackrock_artask(behDir,brDirs{sess_num},baseSaveDir{sess_num},lfpExt);
            savename_events = [behDir '/' 'events_aligned']
            save(savename_events,'events','spikeData');
            
        end
        
        if numel(test_date_dir) == 1
            clearvars -except subj subj_dir
        elseif numel(test_date_dir) > 1
            clear events spikeData
        end
        
    end
    
end
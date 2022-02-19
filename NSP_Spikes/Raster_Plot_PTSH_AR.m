
%% Peristimulus Time Histograms - AR - Firing Rate also - Pranish Kantak - 5/10/2021
ccc
%% Set up analysis input directories, note - analysis files must be of the format in the README file
addpath(genpath('Volumes/Pranish/AR'));
% Inputs - Change per subject or if the directory location changes
root_dir = dir2('/Volumes/Pranish/AR/subjects/UT*');

for subj = [root_dir]'
    % set up the folders, load the events
    subj_ID = subj.name
    
    beh_dir = dir2(sprintf('%s/%s/behavioral/ar',subj.folder,subj.name));
    
    spike_dir = dir2(sprintf('%s/%s/sorted/',subj.folder,subj.name));
    
    time_files = dir2(sprintf('%s/%s/spike_times_neg/times_*',spike_dir.folder,spike_dir.name));
    
    if length(beh_dir) == 2
        
        if ~exist(sprintf('%s/%s/analysis',subj.folder,subj.name))
            mkdir(sprintf('%s/%s/analysis/spike_char/session_0',subj.folder,subj.name));
            mkdir(sprintf('%s/%s/analysis/spike_char/session_1',subj.folder,subj.name));
        end
    else
        
        if ~exist(sprintf('%s/%s/analysis',subj.folder,subj.name))
            mkdir(sprintf('%s/%s/analysis/spike_char/session_0',subj.folder,subj.name));
        end
    end
    
    %% Start the analysis
    
    for i = 1:length(beh_dir)
        
        x = i-1;
        
        events = load(sprintf('%s/session_%d/events_aligned.mat',beh_dir.folder,x));
        for n=1:length(events)
            events(n).timeoffset_sec=events(n).timeoffset_ms/1000 ;
        end
        
        % identify trials with a valid eegfile
        events = filterStruct(events.events,'~strcmp(NS3_lfpfile,'''')');
        
        % identify encoding trials & convert from ms to s
        encevents = filterStruct(events, 'strcmp(event,''ENCODING'')');
        
        
        % intact intacct
        events_successful = filterStruct(encevents,'correct_opp_1==1 & (correct_opp_2==1 |correct_opp_2==-999)');
        
        
        events_intact_intact_subj = filterStruct(events_successful,'retrieval_ans_1==1 & retrieval_ans_2==-999');
        
        
        % intact rearranged
        events_unsuccessful = filterStruct(encevents,'correct_opp_1==0  & (correct_opp_2==0 |correct_opp_2==-999)  & retrieval_ans_1~=3 & retrieval_ans_2~=3');
        
        
        events_intact_rearranged_subj = filterStruct(events_unsuccessful,'retrieval_ans_1==2  & retrieval_ans_2==-999');
        
        
        
        % identify retrieval trials
        retevents = filterStruct(events, 'strcmp(event,''RETRIEVAL'')');
        num_retr(subj,:) = length(retevents);
        events_intact = filterStruct( retevents,' strcmp(correct_ans,''1'')');
        events_rearr = filterStruct(retevents,' strcmp(correct_ans,''2'') ');
        events_new = filterStruct( retevents,' strcmp(correct_ans,''3'')');
        
        % identify correct trails : intact-intact, rearr-rearr, new-new
        events_successful = filterStruct(retevents,'correct==1');
        events_intact_intact = filterStruct( events_successful,' strcmp(correct_ans,''1'') & response == 1');
        events_rearr_rearr = filterStruct( events_successful,' strcmp(correct_ans,''2'') & response == 2');
        events_new_new = filterStruct( events_successful,' strcmp(correct_ans,''3'') & response == 3');
        
        events_unsuccessful  = filterStruct(retevents,'correct==0');% & response ~=3 & ~strcmp(correct_ans,''3'')');
        events_intact_rearr = filterStruct( events_unsuccessful,' strcmp(correct_ans,''1'') & response == 2');
        events_intact_new = filterStruct( events_unsuccessful,' strcmp(correct_ans,''1'') & response == 3');
        events_rearr_intact = filterStruct( events_unsuccessful,' strcmp(correct_ans,''2'') & response == 1');
        events_rearr_new = filterStruct( events_unsuccessful,' strcmp(correct_ans,''2'') & response == 3');
        events_new_intact = filterStruct( events_unsuccessful,' strcmp(correct_ans,''3'') & response == 1');
        events_new_rearr = filterStruct( events_unsuccessful,' strcmp(correct_ans,''3'') & response == 2');
        
    end
    
end

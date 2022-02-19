%% Common Average Referencing - Pranish Kantak - Last Updated: 10/30/18
ccc

% move subject folder into "Current" if doing a single or specific patient(s), otherwise,
% you can do across all patients
root_dir = dir2 ('/Volumes/Pranish/FR1_Local_Data/Current'); % have to use the custom function dir2 because of the presence of '.','..','.DS_Store'; make sure to check the output in case there is more #s
addpath(genpath('/Users/Pranish/Desktop/FR1_Local_Data')); % set this to the main data directory
sess = ["11_28_2018_FR1_Micro"]; % set this to the session date for however many patients you are CAR-ing
mkdir('/Volumes/Pranish/FR1_Local_Data/Current/UT128/Raw/11_28_2018_FR1_Micro/CAR');
% Begin Processing


common_avg_ref_folder = 'CAR';

for subjdir = root_dir([root_dir.isdir])'
    
    disp('you must change the variable n to the next session date (unless this is the first iteration)');
    keyboard
    
    raw_NS6_AH = {};
    mean_NS6_AH = [];
    raw_NS6_PH = {};
    mean_NS6_PH = [];
    
    current_dir = [subjdir.folder filesep subjdir.name];
    
    current_subj = subjdir.name;
    
    cd(current_dir)
    
    % added this section in case some patients have recordings that started
    % with the blackrock instead of the behavioral computer - 7 is for a
    % folder
    if exist('Raw/fixed_for_alignment','dir') == 7
        current_subj_sess = sprintf('Raw/%s/fixed_for_alignment/NS6',n);
        
    else
        current_subj_sess = sprintf('Raw/%s',n);
        
    end
    
    % Get a list of all files in the folder with the desired file name pattern.
    filePattern = fullfile(current_subj_sess, 'NS6_0*.mat');
    NS6_files_currentsubj = dir(filePattern);
    
    if length(NS6_files_currentsubj) == 16
        
        NS6_files_currentsubj_AH = NS6_files_currentsubj([1:8]);
        NS6_files_currentsubj_PH = NS6_files_currentsubj([9:16]);
        
        for i = 1: length(NS6_files_currentsubj_AH) % do CAR for AH channels (i.e.: 1-8)
            baseFileName = NS6_files_currentsubj_AH(i).name;
            fullFileName = fullfile(current_subj_sess, baseFileName);
            fprintf(1, 'Now reading (anterior) %s\n', fullFileName);
            
            load(fullFileName)
            
            raw_NS6_AH{i,1} = data;
            
        end
        
        raw_NS6_AH = cell2mat(raw_NS6_AH);
        
        mean_NS6_AH = mean(raw_NS6_AH);
        
        for i = 1: length(NS6_files_currentsubj_AH)
            
            baseFileName = NS6_files_currentsubj_AH(i).name;
            fullFileName = fullfile(current_subj_sess, baseFileName);
            fprintf(1, 'Now reading (anterior) %s\n', fullFileName);
            
            load(fullFileName)
            
            data = double(data) - mean_NS6_AH;
            
            current_chan = NS6_files_currentsubj_AH(i).name;
            
            savename = fullfile(current_subj_sess,common_avg_ref_folder,current_chan);
            
            save(savename,'data','sr');
            
            fprintf(1, 'Now finished with (anterior) %s\n', fullFileName);
            
        end
        
        fprintf(1, 'Finished with subj (anterior) %s\n', current_subj);
        
        for i = 1: length(NS6_files_currentsubj_PH) % do CAR for PH channels (i.e.: 1-8)
            baseFileName = NS6_files_currentsubj_PH(i).name;
            fullFileName = fullfile(current_subj_sess, baseFileName);
            fprintf(1, ' Now reading (posterior) %s\n', fullFileName);
            
            load(fullFileName)
            
            raw_NS6_PH{i,1} = data;
            
        end
        
        raw_NS6_PH = cell2mat(raw_NS6_PH);
        
        mean_NS6_PH = mean(raw_NS6_PH);
        
        for i = 1: length(NS6_files_currentsubj_PH)
            
            baseFileName = NS6_files_currentsubj_PH(i).name;
            fullFileName = fullfile(current_subj_sess, baseFileName);
            fprintf(1, ' Now reading (posterior) %s\n', fullFileName);
            
            load(fullFileName)
            
            data = double(data) - mean_NS6_PH;
            
            current_chan = NS6_files_currentsubj_PH(i).name;
            
            savename = fullfile(current_subj_sess,common_avg_ref_folder,current_chan);
            
            save(savename,'data','sr');
            
            fprintf(1, ' Now finished with (posterior) %s\n', fullFileName);
            
        end
        
    else
        
        for i = 1: length(NS6_files_currentsubj) % do CAR for patients with just 8 electrodes
            baseFileName = NS6_files_currentsubj(i).name;
            fullFileName = fullfile(current_subj_sess, baseFileName);
            fprintf(1, 'Now reading %s\n', fullFileName);
            
            load(fullFileName)
            
            raw_NS6{i,1} = data;
            
        end
        
        raw_NS6 = cell2mat(raw_NS6);
        
        mean_NS6 = mean(raw_NS6);
        
        for i = 1: length(NS6_files_currentsubj)
            
            baseFileName = NS6_files_currentsubj(i).name;
            fullFileName = fullfile(current_subj_sess, baseFileName);
            fprintf(1, 'Now reading %s\n', fullFileName);
            
            load(fullFileName)
            
            data = double(data) - mean_NS6;
            
            current_chan = NS6_files_currentsubj(i).name;
            
            savename = fullfile(current_subj_sess,common_avg_ref_folder,current_chan);
            
            save(savename,'data','sr');
            
            fprintf(1, 'Now finished with %s\n', fullFileName);
            
        end
        
        
        clearvars -except root_dir sess common_avg_ref_folder
        
        
    end
end

clearvars; close all; clc;
warning off 

subj = 'UT247';
sessDir = '5_26_21_SR_Micro';
spikeDir = sprintf('/project/TIBIR/Lega_lab/shared/lega_ansir/Pranish_Micro_AR/test/%s/sorted/%s/RawDir',subj,sessDir);
file_ext = {'.ns6'};


files_in_here = dir2(spikeDir);
[~,j] = max([files_in_here.bytes]); % get the index of the largest file
NSXfilename = files_in_here(j).name; 

NSXfilename = files_in_here(j).name(1:end-4);

%% Prepare Paths

cd(spikeDir) % PK added this so the output files get dumped in the spike directory

for n=1:length(file_ext)
    fprintf('Processing %s\n',file_ext{n})
    rawDir   = spikeDir;
    datafile = fullfile(rawDir, sprintf([NSXfilename file_ext{n}]));
  
    
    % Split the data file
    
    NSx_simple_split_EF(datafile, {}, rawDir, subj); % this SHOULD be normal simple split....
    root= sprintf('/NS%s_*',datafile(end));
    NCXfiles = dir(sprintf([rawDir root]));
    timeStampIdx = find(contains({NCXfiles(:).name},'TimeStamps'));
    NCXfiles(timeStampIdx) = [];
    num_chl = length(NCXfiles);
     
    %% Turn the NCX file into a mat file compatible with Combinato
    % Get the actual channels in the directory
    for c = 1:num_chl
        [data, info]= load_nsx_EF(spikeDir,NCXfiles(c).name);
        sr = info.sr; % Get it from the struct
        savename = sprintf([NCXfiles(c).name(1:end) '.mat']);
        
        save(fullfile(spikeDir,savename),'data','sr')
    end
    
    
end

fprintf('All Done.\n')






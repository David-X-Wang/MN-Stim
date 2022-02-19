ccc
addpath(genpath('/Users/Pranish/Documents/MATLAB'));
addpath(genpath('/Volumes/Pranish/FR1_Local_Data'));


subj = 'UT128';
sessDir = '';
sessNum = 0;
spikeDir = '/Volumes/Pranish/FR1_Local_Data/UT128/Raw/11_28_2018_FR1_Micro';
file_ext = {'.ns3','.ns6'};


files_in_here = dir2(spikeDir);
[~,j] = max([files_in_here.bytes]); % get the index of the largest file
NSXfilename = files_in_here(j).name; 

NSXfilename = files_in_here(j).name(1:end-4);

%% Prepare Paths {for data on rhino}

cd(spikeDir) % PK added this so the output files get dumped in the spike directory

for n=1:length(file_ext)
    fprintf('Processing %s\n',file_ext{n})
    rawDir   = spikeDir;
    datafile = fullfile(rawDir, sprintf([NSXfilename file_ext{n}]));
  
    
    % Split the data file
    
    NSx_simple_split_JL(datafile, {}, rawDir, subj); % this SHOULD be normal simple split....
    root= sprintf('/NS%s.*',datafile(end));
    NCXfiles = dir(sprintf([rawDir root]));
        
    num_chl = length(NCXfiles);
     
    %% Turn the NCX file into a mat file compatible with Combinato
    %Get the actual channels in the directory
    for c = 1:num_chl
        [data info]= load_nsx(spikeDir,NCXfiles(c).name);
        sr = info.sr; % Get it from the struct
        savename = sprintf([NCXfiles(c).name(1:end) '.mat']);
        save(fullfile(spikeDir,savename),'data','sr')
    end
    
    
end

fprintf('All Done.\n')






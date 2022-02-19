%% Modal - FR1 Whole Session
ccc
tic
% set up params
params.srate = 2000; % set this to the sampling rate of the LFPs e.g.: 2000 Hz
params.wavefreqs = 1:0.5:50;

lfp_dir = '/Volumes/Pranish/FR1_Local_Data/UT113/Raw/8_29_18_FR1_Micro/fixed_for_alignment/NS3';
modal_dir = '/Volumes/Pranish/FR1_Local_Data/UT113/Modal_fix';
filePattern = fullfile(lfp_dir, 'NS3.0*.mat');
NS3_files = dir2(filePattern);

for lfps = NS3_files'
    
    load([lfps.folder filesep lfps.name])
    
    if any(data) == 0
        continue
    end
    
    [frequency_sliding,bands,bandpow,bandphase] = MODAL(data,params);
    
    lfpfile = strrep(lfps.name,'3.0','3_0');
    
    savename = sprintf('%s/Modal_%s',modal_dir,lfpfile);
    
    save(savename,'frequency_sliding','bands','bandpow','bandphase');
    
    clearvars -except params lfp_dir modal_dir filePattern NS3_files lfps
    
end

toc
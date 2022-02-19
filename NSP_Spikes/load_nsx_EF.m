function [data,info] = load_nsx_EF(spikeDir,filename)
%
% FUNCTION:
%   [data,info]=load_nc5(filename)
%
% DESCRIPTION:
%   Extract data from binary EEG file
%    
% INPUTS:
%   filename: path to the nc5 file
%
% OUTPUTS:
%   data:  LFP data in microvolts 
%   info:  the info in NSX_TimeStamps.mat
%          TimesStamps     - timestamps of each sample
%          lts             - number of samples
%          nchan           - number of channels recorded during the session
%          position_start  -
%          position_end    
%
% Last Updated: 05-08-2018
% Author: Jui-Jui Lin 
% 

f=fopen(fullfile(spikeDir,filename),'r','l');
%Read TimeStamps
info = load([spikeDir '/' fullfile(fileparts(filename),sprintf('NS%s_TimeStamps',filename(3)))]);

% Preallocate
data  = zeros(1,info.lts,'int16');

segments=ceil(info.lts/(5  * info.sr * 60));
segmentLength = floor (info.lts/segments);
tsmin = 1 : segmentLength :info.lts;
tsmin = tsmin(1:segments);
tsmax = tsmin - 1;
tsmax = tsmax (2:end);
tsmax = [tsmax, info.lts];
recmin = tsmin; %in samples
recmax = tsmax; %in samples
for j=1:length(tsmin)
    % LOAD NC5 DATA
    Samples=fread(f,(recmax(j)-recmin(j)+1),'int16');
    data(1,recmin(j):recmax(j)) = Samples;
    clear Samples
    fprintf('%.2f  ',j/length(tsmin)*100)   
end
fprintf('\n')


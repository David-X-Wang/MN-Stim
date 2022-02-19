function [num_chl ] = NSx_simple_split_EF(raw, badTags, outputDir, baseName, jackDir, dataFormat, gain)
%NSX_SPLIT split an NSx (Blackrock format) file into separate channels 
%
% Arguments:
%   raw         -       The directory containing the raw .nsX file, OR the
%                       full path to the file itself. Will not function if
%                       it is a directory and more than one .nsX file
%                       reside within
%
%   badTags     -       A cell array of all of the labels that are
%                       non-neural channels. These channels will not be
%                       split or included in the jacksheet
%
%   outputDir   -       The directory where the split (*.001, *.002) files
%                       (and the session specific jacksheet and params
%                       files) will be placed
%
%   baseName    -       The prefix for the file (usually the subject)
%
%   jackDir     -       Path to the directory that contains the jacksheet
%                       (usually 'docs')
%
%   dataFormat   -       (optional) Defaults to 'int16', determines the
%                       output data format
%   
%   gain        -       (optional) written to params.txt for backwards
%                       compatibility

default_dataFormat = 'int16';
default_gain = 1;

if ~exist('dataFormat','var') || isempty(dataFormat)
    dataFormat = default_dataFormat;
end
if ~exist('gain','var') || isempty(gain)
    gain = default_gain;
end

% Find the NSx files 
if exist(raw,'file')
    NSxFiles = {raw};
else
%     NSxFiles = getNSx_eeg_files(raw);
end
assert(length(NSxFiles)==1, 'Expected 1 .NSx file, found %d',length(NSxFiles));


% Read the NSx file into a data structure 
% eeg = openNSx(NSxFiles{1});  % if the file is small
% read the nsx files by channels  

eeg = openNSx(NSxFiles{1});
num_chl= size(eeg.Data,1);  % Need a better way to know how many channels 


% Get info about date for labeling
cellDate = num2cell(eeg.MetaTags.DateTimeRaw([1:3,5,6]));
filestem = fullfile(outputDir, sprintf('%s_%02d-%02d-%02d_%02d-%02d_%s',baseName, cellDate{:},raw(end-2:end)));
if ~exist(outputDir,'dir')
    mkdir(outputDir);
end
if iscell(eeg.Data) % this means there are multiple NSPs 
    Data1 = eeg.Data{1};
    Data2 = eeg.Data{2};
    NSP = 1;
else 
    NSP = 0;  
end 

% Exclude bad labels       
tagLabels = {eeg.ElectrodesInfo.Label};

isBad = ismember(tagLabels, badTags);
goodIndices = find(~isBad);

% Check to make sure jacksheets will match
if exist('jackDir')
jackFile = jackDir;
oldJackExists = exist(jackFile,'file');
if oldJackExists
    [names, nums] = readJacksheet(jackFile);
    foundMask = isBad;
    for i=1:length(names)
        thisElecMask = [eeg.ElectrodesInfo.ElectrodeID] == nums(i);
        assert(~(nnz(thisElecMask)>1),...
            'Found multiple electrodes with the same ID: %s', nums(i));
        assert(~(nnz(thisElecMask)==0),...
            'Could not find jacksheet electrode %d in data', nums(i));
        oldLabel = trim(eeg.ElectrodesInfo(thisElecMask).Label);
        assert(strcmp(oldLabel, names{i}),...
            'Jacksheet labels do not match for electrode %d: %s vs %s',...
            nums(i), names{i}, oldLabel);
        foundMask(thisElecMask) = true;
    end
    badJackLabels = trim(tagLabels(~foundMask));
    assert(isempty(badJackLabels),...
        'Found electrode %s in jacksheet, not in EEG data\n',...
        badJackLabels{:})
end
end
    
% Print to file 
%i need permssion to write in this directory or test and move it to a
%folder i have permission to wrie to. 
for i = goodIndices
    chanfile = sprintf('NS%s_%03i',raw(end), eeg.ElectrodesInfo(i).ElectrodeID);
    fout = fopen([raw(1:strfind(raw, 'micro/')+5) chanfile], 'w','l');
    if NSP == 0
        fwrite(fout, eeg.Data(i,:), dataFormat);
    elseif NSP ==1 
        fwrite(fout, Data1, dataFormat);
        fwrite(fout, Data2, dataFormat); 
    end
            
    fclose(fout);
end



% write timestamps does not change per channel 
lts = eeg.MetaTags.DataPoints;
sr = eeg.MetaTags.SamplingFreq;
try 
   TimeStamps=linspace(0,(lts-1)*1e6/sr,lts);
   size(TimeStamps,2);
catch
    TimeStamps=linspace(single(0),single((lts-1)*1e6/sr),single(lts));
end

fname = fullfile(outputDir,sprintf('NS%s_TimeStamps.mat',raw(end)));
save(fname,'TimeStamps','lts','sr');

% write params.txt
% TODO: WHY ARE WE WRITING THIS TWICE. DOES IT DO ANYTHING?
% printParams(eeg, fullfile(outputDir, 'params.txt'), dataFormat, gain);
printParams(eeg, [filestem '.params.txt'], dataFormat, gain);

% write the jacksheet files
% TODO: AGAIN, WHY DO WE HAVE SO MANY COPIES?
printJacksheet(eeg, goodIndices, [filestem '.jacksheet.txt']);
% printJacksheet(eeg, goodIndices, fullfile(outputDir, 'jacksheet.txt'));
if exist('jackDir')
    printJacksheet(eeg, goodIndices, fullfile(jackDir, 'jacksheet.txt'));
end

function printParams(eeg, paramFile, dataFormat, gain)
% Prints parameters to file
fout = fopen(paramFile,'w','l');
fprintf(fout,'samplerate %.2f\ndataformat ''%s''\ngain %g\n', eeg.MetaTags.SamplingFreq, dataFormat, gain);
fclose(fout);

function printJacksheet(eeg, goodIndices, jackFile)
% Prints the jacksheet to a file
fout = fopen(jackFile,'w');
for i=goodIndices
    name = eeg.ElectrodesInfo(i).Label;
    num = eeg.ElectrodesInfo(i).ElectrodeID;
    % regular strtrim didn't work - weird characters on the end of the name
    fprintf(fout,'%d %s\n',num,trim(name));
end
fclose(fout);

function [names, nums] = readJacksheet(jackFile)
% read in electrode names and nums from file
fid = fopen(jackFile,'r');
output = textscan(fid,'%d %s\n');
nums = output{1};
names = output{2};

function newStr = trim(oldStr)
newStr = regexprep(oldStr, '[^a-zA-Z0-9]','');